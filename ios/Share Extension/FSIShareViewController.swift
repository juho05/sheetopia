// FSIShareViewController.swift
// Merged, optimized controller: uses RSI architecture with all FSI features preserved
// Uses model name `SharingFile` (same fields as SharedMediaFile) where `value` = path

import AVFoundation
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

public let kSchemePrefix = "SharingMedia"
public let kUserDefaultsKey = "SharingKey"
public let kUserDefaultsMessageKey = "SharingMessageKey"
public let kAppGroupIdKey = "AppGroupId"
public let kAppChannel = "flutter_sharing_intent"

/// Subdirectory of the app group container the attachments are copied into.
///
/// Each share gets its own directory below it (`ShareInbox/<uuid>/`), so
/// original file names survive without two shares of the same name colliding,
/// and the host app can delete the whole share in one go once it has imported
/// it. Keep in sync with `lib/data/services/sharing/share_inbox.dart`.
public let kShareInboxDirectory = "ShareInbox"

// @objc(FSIShareViewController)
@available(swift, introduced: 5.0)
open class FSIShareViewController: UIViewController {
    // MARK: - Config
    private(set) var hostAppBundleIdentifier: String = ""
    private(set) var appGroupId: String = ""

    // Identifies this share's directory inside the inbox.
    private let shareId = UUID().uuidString

    // Results
    private var sharedMedia: [SharingFile] = []

    // Debug
    private let debugLogs = false

    // Spinner, shown only if the attachments take long enough to load that the
    // otherwise empty screen would look like a hang.
    private let spinnerDelay: TimeInterval = 0.35
    private var spinnerContainer: UIVisualEffectView?
    private var spinnerWorkItem: DispatchWorkItem?

    // MARK: - Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadIds()
        purgeStaleShares()
        setupSpinner()
        processAttachments()
    }

    // MARK: - Spinner
    private func setupSpinner() {
        let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        container.translatesAutoresizingMaskIntoConstraints = false
        container.layer.cornerRadius = 14
        container.layer.cornerCurve = .continuous
        container.clipsToBounds = true
        container.alpha = 0

        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        container.contentView.addSubview(indicator)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            container.widthAnchor.constraint(equalToConstant: 80),
            container.heightAnchor.constraint(equalToConstant: 80),
            indicator.centerXAnchor.constraint(equalTo: container.contentView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: container.contentView.centerYAnchor),
        ])
        spinnerContainer = container

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            UIView.animate(withDuration: 0.2) { self.spinnerContainer?.alpha = 1 }
        }
        spinnerWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + spinnerDelay, execute: work)
    }

    private func hideSpinner() {
        spinnerWorkItem?.cancel()
        spinnerWorkItem = nil
        spinnerContainer?.alpha = 0
    }

    // MARK: - Load Ids
    private func loadIds() {
        let shareExtId = Bundle.main.bundleIdentifier ?? ""
        if let idx = shareExtId.lastIndex(of: ".") {
            hostAppBundleIdentifier = String(shareExtId[..<idx])
        } else {
            hostAppBundleIdentifier = shareExtId
        }
        let custom = Bundle.main.object(forInfoDictionaryKey: kAppGroupIdKey) as? String
        appGroupId = custom ?? "group.\(hostAppBundleIdentifier)"
        log("loaded host=\(hostAppBundleIdentifier) group=\(appGroupId)")
    }
    
    // MARK: - Attachment processing (clean RSI style, preserve FSI features)
    private func processAttachments() {
        guard let content = extensionContext?.inputItems.first as? NSExtensionItem else {
            completeAndExit()
            return
        }
        
        guard let attachments = content.attachments, !attachments.isEmpty else {
            completeAndExit()
            return
        }
        
        // Use DispatchGroup to wait for async loads
        let group = DispatchGroup()
        for (index, provider) in attachments.enumerated() {
            group.enter()
            // Try all SharedMediaType options similar to RSI but preserve explicit FSI order
            if provider.isImage {
                provider.loadItem(forTypeIdentifier: UType.image, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleImageItem(data: data, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isMovie {
                provider.loadItem(forTypeIdentifier: UType.movie, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleVideoItem(data: data, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isFile {
                provider.loadItem(forTypeIdentifier: UType.fileURL, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleFileItem(data: data, provider: provider, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isURL {
                provider.loadItem(forTypeIdentifier: UType.url, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleUrlItem(data: data, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isText {
                let id = provider.hasItemConformingToTypeIdentifier(UType.plainText)
                ? UType.plainText
                : UType.text
                provider.loadItem(forTypeIdentifier: id, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleTextItem(data: data, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isData {
                provider.loadItem(forTypeIdentifier: UType.data, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleFileItem(data: data, provider: provider, index: index, total: attachments.count)
                }
                continue
            }
            
            if provider.isItem {
                provider.loadItem(forTypeIdentifier: UType.item, options: nil) { [weak self] data, error in
                    defer { group.leave() }
                    guard let self = self, error == nil else { self?.dismissWithError(); return }
                    self.handleFileItem(data: data, provider: provider, index: index, total: attachments.count)
                }
                continue
            }
                    
            log("Unknown provider type: \(provider.registeredTypeIdentifiers)")

            // Unknown type: just leave
            group.leave()
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // if we have media -> media, else fallback to complete
            if !self.sharedMedia.isEmpty {
                self.saveAndRedirect()
            } else {
                print("FSIShare: No shared media → stopping.")
                self.completeAndExit()
            }
        }
    }
    
    // MARK: - Individual handlers (preserve FSI behavior)
    private func handleTextItem(data: NSSecureCoding?, index: Int, total: Int) {
        if let s = data as? String {
            sharedMedia.append(SharingFile(value: s, thumbnail: nil, duration: nil, type: .text))
        } else if let url = data as? URL {
            sharedMedia.append(SharingFile(value: url.absoluteString, thumbnail: nil, duration: nil, type: .url))
        }
        
    }
    
    private func handleUrlItem(data: NSSecureCoding?, index: Int, total: Int) {
        if let url = data as? URL {
            sharedMedia.append(SharingFile(value: url.absoluteString, thumbnail: nil, duration: nil, type: .url))
        } else if let s = data as? String {
            sharedMedia.append(SharingFile(value: s, thumbnail: nil, duration: nil, type: .text))
        }
        
    }
    
    private func handleImageItem(data: NSSecureCoding?, index: Int, total: Int) {
        // data can be URL, UIImage, or Data
        if let url = data as? URL {
            let filename = getFileName(from: url, type: .image)
            if let dst = shareURL()?.appendingPathComponent(filename) {
                if copyFile(at: url, to: dst) {
                    sharedMedia.append(SharingFile(value: sharedValue(for: dst), mimeType: url.mimeType(), thumbnail: nil, duration: nil, type: .image))
                }
            }
        } else if let img = data as? UIImage {
            if let saved = writeTempImage(img) {
                sharedMedia.append(saved)
            }
        } else if let raw = data as? Data, let img = UIImage(data: raw) {
            if let saved = writeTempImage(img) {
                sharedMedia.append(saved)
            }
        }
        
    }
    
    private func handleVideoItem(data: NSSecureCoding?, index: Int, total: Int) {
        if let url = data as? URL {
            let filename = getFileName(from: url, type: .video)
            if let dst = shareURL()?.appendingPathComponent(filename) {
                if copyFile(at: url, to: dst) {
                    if let m = getSharedMediaFile(forVideo: dst) {
                        sharedMedia.append(m)
                    }
                }
            }
        }
        
    }
    
    private func handleFileItem(data: NSSecureCoding?, provider: NSItemProvider?, index: Int, total: Int) {
        if let url = data as? URL {
            let filename = getFileName(from: url, type: .file)
            if let dst = shareURL()?.appendingPathComponent(filename) {
                if copyFile(at: url, to: dst) {
                    sharedMedia.append(SharingFile(value: sharedValue(for: dst), mimeType: url.mimeType(), thumbnail: nil, duration: nil, type: .file))
                }
            }
        }
        else if let raw = data as? Data {
            // Items shared as a data representation (rather than a file URL) carry
            // no name, so we derive a filename with the correct extension from the
            // provider's suggested name / registered type. Without this the file is
            // written with no extension and the host app can't detect its type.
            let filename = fallbackFileName(for: provider)
            if let dst = shareURL()?.appendingPathComponent(filename) {
                do {
                    try raw.write(to: dst)
                    sharedMedia.append(SharingFile(value: sharedValue(for: dst), mimeType: dst.mimeType(), thumbnail: nil, duration: nil, type: .file))
                } catch {}
            }
        }


    }

    // Builds a filename (with extension) for data-representation items, using the
    // provider's suggested name when available and otherwise the preferred
    // extension of its registered UTType.
    private func fallbackFileName(for provider: NSItemProvider?) -> String {
        if let suggested = provider?.suggestedName,
           !suggested.isEmpty,
           !(suggested as NSString).pathExtension.isEmpty {
            return suggested
        }
        let base = provider?.suggestedName?.isEmpty == false
            ? provider!.suggestedName!
            : "File_\(UUID().uuidString)"
        if let ext = preferredExtension(for: provider) {
            return "\(base).\(ext)"
        }
        return base
    }

    private func preferredExtension(for provider: NSItemProvider?) -> String? {
        guard let provider = provider else { return nil }
        if #available(iOS 14.0, *) {
            for id in provider.registeredTypeIdentifiers {
                if let ext = UTType(id)?.preferredFilenameExtension {
                    return ext
                }
            }
        } else {
            for id in provider.registeredTypeIdentifiers {
                if let uti = UTTypeCopyPreferredTagWithClass(id as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
                    return uti as String
                }
            }
        }
        return nil
    }
    
    // MARK: - Helpers: write temp image
    private func writeTempImage(_ image: UIImage) -> SharingFile? {
        guard let dir = shareURL() else { return nil }
        let tempName = "TempImage_\(UUID().uuidString).png"
        let dst = dir.appendingPathComponent(tempName)
        do {
            if let d = image.pngData() {
                try d.write(to: dst)
                return SharingFile(value: sharedValue(for: dst), mimeType: "image/png", thumbnail: nil, duration: nil, type: .image)
            }
        } catch {
            log("writeTempImage error: \(error)")
        }
        return nil
    }
    
    
    private func saveAndRedirect(message: String? = nil) {
        let ud = UserDefaults(suiteName: appGroupId)
        if !sharedMedia.isEmpty {
            if let data = try? JSONEncoder().encode(sharedMedia) {
                ud?.set(data, forKey: kUserDefaultsKey)
            }
        }
        ud?.set(message, forKey: kUserDefaultsMessageKey)
        ud?.synchronize()
        redirectToHostApp()
    }
    
    
    private func redirectToHostApp() {
        // kept for compatibility (RSI style)
        loadIds()
        hideSpinner()
        //        let raw = "\(kSchemePrefix)-\(hostAppBundleIdentifier):share"
        let raw = "\(kSchemePrefix)-\(hostAppBundleIdentifier)://dataUrl=\(kUserDefaultsKey)"
        guard let url = URL(string: raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? raw) else { completeAndExit(); return }
        
        var responder: UIResponder? = self
        if #available(iOS 18.0, *) {
            while responder != nil {
                if let app = responder as? UIApplication { app.open(url, options: [:], completionHandler: nil) }
                responder = responder?.next
            }
        } else {
            let sel = sel_registerName("openURL:")
            while responder != nil {
                if responder?.responds(to: sel) ?? false { _ = responder?.perform(sel, with: url) }
                responder = responder?.next
            }
        }
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    // MARK: - File / thumbnail / metadata helpers

    // The value we hand to the host app ends up being used as a plain
    // filesystem path: the plugin only strips the `file://` prefix, it never
    // percent-decodes. Using `absoluteString` therefore breaks every file whose
    // name contains a space or another character that gets percent-encoded
    // (e.g. "score 1.pdf" arrives as ".../score%201.pdf" and can't be
    // opened). `path` is already decoded; the prefix is kept so the host app
    // recognises the value as a file path regardless of where the app group
    // container resolves to.
    private func sharedValue(for url: URL) -> String {
        return "file://" + url.path
    }

    func getExtension(from url: URL, type: SharingFileType) -> String {
        let parts = url.lastPathComponent.components(separatedBy: ".")
        var ex: String? = nil
        if parts.count > 1 { ex = parts.last }
        if ex == nil {
            switch type {
            case .image: ex = "png"
            case .video: ex = "mp4"
            case .file: ex = "txt"
            case .text: ex = "txt"
            case .url: ex = "txt"
            }
        }
        return ex ?? "bin"
    }
    
    func getFileName(from url: URL, type: SharingFileType) -> String {
        var name = url.lastPathComponent
        if name.isEmpty { name = UUID().uuidString + "." + getExtension(from: url, type: type) }
        return name
    }
    
    func copyFile(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) { try FileManager.default.removeItem(at: dstURL) }
            try FileManager.default.copyItem(at: srcURL, to: dstURL)
            return true
        } catch {
            log("copyFile error: \(error)")
            return false
        }
    }
    
    private func getSharedMediaFile(forVideo: URL) -> SharingFile? {
        let asset = AVAsset(url: forVideo)
        let duration = (CMTimeGetSeconds(asset.duration) * 1000).rounded()
        let thumbnailPath = getThumbnailPath(for: forVideo)
        
        if FileManager.default.fileExists(atPath: thumbnailPath.path) {
            return SharingFile(value: sharedValue(for: forVideo), mimeType: forVideo.mimeType(), thumbnail: sharedValue(for: thumbnailPath), duration: Int(duration), type: .video)
        }
        
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        gen.maximumSize = CGSize(width: 360, height: 360)
        
        // Use first second or zero
        let time = CMTime(seconds: min(1.0, CMTimeGetSeconds(asset.duration)), preferredTimescale: 600)
        do {
            let cg = try gen.copyCGImage(at: time, actualTime: nil)
            if let data = UIImage(cgImage: cg).jpegData(compressionQuality: 0.8) {
                try data.write(to: thumbnailPath)
                return SharingFile(value: sharedValue(for: forVideo), mimeType: forVideo.mimeType(), thumbnail: sharedValue(for: thumbnailPath), duration: Int(duration), type: .video)
            }
        } catch {
            log("getSharedMediaFile thumbnail error: \(error)")
        }
        
        // fallback
        return SharingFile(value: sharedValue(for: forVideo), mimeType: forVideo.mimeType(), thumbnail: nil, duration: Int(duration), type: .video)
    }
    
    private func getThumbnailPath(for url: URL) -> URL {
        guard let dir = shareURL() else { fatalError("App group not configured or missing") }
        let fileName = Data(url.lastPathComponent.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
        return dir.appendingPathComponent("\(fileName).jpg")
    }

    private func containerURL() -> URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private func inboxURL() -> URL? {
        containerURL()?.appendingPathComponent(kShareInboxDirectory, isDirectory: true)
    }

    /// Destination directory for this share's attachments, created on demand.
    ///
    /// The inbox is excluded from backups: everything in it is a temporary copy
    /// that the host app re-saves into its own (backed up) storage, so backing
    /// the copies up as well would only duplicate the user's library.
    private func shareURL() -> URL? {
        guard let inbox = inboxURL() else { return nil }
        var dir = inbox.appendingPathComponent(shareId, isDirectory: true)
        if FileManager.default.fileExists(atPath: dir.path) { return dir }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try dir.setResourceValues(values)
        } catch {
            log("shareURL error: \(error)")
            return FileManager.default.fileExists(atPath: dir.path) ? dir : nil
        }
        return dir
    }

    /// Deletes leftovers from earlier shares.
    ///
    /// The host app removes each share directory once it has imported it, so
    /// anything still here belongs to a share the app never got to process
    /// (it was killed on the way, or the import failed). Without this the
    /// copies would stay in the container forever, invisible to the app.
    private func purgeStaleShares() {
        guard let inbox = inboxURL(),
              let entries = try? FileManager.default.contentsOfDirectory(
                at: inbox, includingPropertiesForKeys: nil) else { return }
        for entry in entries where entry.lastPathComponent != shareId {
            do {
                try FileManager.default.removeItem(at: entry)
            } catch {
                log("purgeStaleShares error: \(error)")
            }
        }
    }
    
    private func completeAndExit() {
        hideSpinner()
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    // Reached from the attachment loading callbacks, which run on arbitrary
    // queues, so hop to main before touching the view hierarchy.
    private func dismissWithError() {
        log("[ERROR] Error loading data!")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.hideSpinner()
            let alert = UIAlertController(title: "Error", message: "Error loading data", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in self.dismiss(animated: true, completion: nil) })
            self.present(alert, animated: true, completion: nil)
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func writeTempFile(_ image: UIImage, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) { try FileManager.default.removeItem(at: dstURL) }
            let pngData = image.pngData()
            try pngData?.write(to: dstURL)
            return true
        } catch (let error) {
            log("writeTempFile error: \(error)")
            return false
        }
    }
    
    private func saveToUserDefaults(data: [SharingFile]) {
        let ud = UserDefaults(suiteName: appGroupId)
        if let enc = try? JSONEncoder().encode(data) { ud?.set(enc, forKey: kUserDefaultsKey); ud?.synchronize() }
    }
    
    // MARK: - Logging
    private func log(_ s: String) { if debugLogs { print("[FSIShareVC] \(s)") } }
    
}

// MARK: - Extensions
extension URL {
    func mimeType() -> String {
        if #available(iOS 14.0, *) {
            if let ut = UTType(filenameExtension: self.pathExtension), let m = ut.preferredMIMEType { return m }
        } else {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, self.pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() { return mimetype as String }
            }
        }
        return "application/octet-stream"
    }
}

extension NSItemProvider {
    var isImage: Bool { return hasItemConformingToTypeIdentifier(UType.image) }
    var isMovie: Bool { return hasItemConformingToTypeIdentifier(UType.movie) }
    // var isText: Bool { return hasItemConformingToTypeIdentifier(UType.text) }
    var isText: Bool {
        hasItemConformingToTypeIdentifier(UType.plainText) || hasItemConformingToTypeIdentifier(UType.text)
    }
    var isURL: Bool { return hasItemConformingToTypeIdentifier(UType.url) }
    var isFile: Bool { return hasItemConformingToTypeIdentifier(UType.fileURL) }
    var isData:Bool { return hasItemConformingToTypeIdentifier(UType.data) }
    var isItem: Bool { hasItemConformingToTypeIdentifier(UType.item) }

}

extension Array {
    subscript(safe index: UInt) -> Element? { return Int(index) < count ? self[Int(index)] : nil }
}


class SharingFile: Codable {
    var value: String
    var mimeType: String?
    var thumbnail: String?; // video thumbnail
    var duration: Int?; // video duration in milliseconds
    var type: SharingFileType;
    var message: String? // post message
    
    enum CodingKeys: String, CodingKey {
        case value
        case mimeType
        case thumbnail
        case duration
        case type
        case message
    }
    
    init(value: String, mimeType: String? = nil, thumbnail: String?, duration: Int?,
         type: SharingFileType, message: String?=nil) {
        self.value = value
        self.mimeType = mimeType
        self.thumbnail = thumbnail
        self.duration = duration
        self.type = type
        self.message = message
    }
    
    // Debug method to print out SharedMediaFile details in the console
    func toString() {
        print("[SharingFile] \n\tvalue: \(self.value)\n\tthumbnail: \(self.thumbnail ?? "--" )\n\tduration: \(self.duration ?? 0)\n\ttype: \(self.type)\n\tmimeType: \(String(describing: self.mimeType))\n\tmessage: \(String(describing: self.message))")
    }
}


enum SharingFileType: Int, Codable {
    case text
    case url
    case image
    case video
    case file
    
//    public var toUTTypeIdentifier: String {
//        if #available(iOS 14.0, *) {
//            switch self {
//            case .image:
//                return UTType.image.identifier
//            case .video:
//                return UTType.movie.identifier
//            case .text:
//                return UTType.text.identifier
//                //         case .audio:
//                //             return UTType.audio.identifier
//            case .file:
//                return UTType.fileURL.identifier
//            case .url:
//                return UTType.url.identifier
//            }
//        }
//        switch self {
//        case .image:
//            return "public.image"
//        case .video:
//            return "public.movie"
//        case .text:
//            return "public.text"
//            //         case .audio:
//            //             return "public.audio"
//        case .file:
//            return "public.file-url"
//        case .url:
//            return "public.url"
//        }
//    }
}

// Unified UTType → works on iOS 11–18
enum UType {
    static var image: String {
        if #available(iOS 14.0, *) {
            return UTType.image.identifier
        } else {
            return kUTTypeImage as String   // old API
        }
    }
    
    static var movie: String {
        if #available(iOS 14.0, *) {
            return UTType.movie.identifier
        } else {
            return kUTTypeMovie as String
        }
    }
    
    
    static var url: String {
        if #available(iOS 14.0, *) {
            return UTType.url.identifier
        } else {
            return kUTTypeURL as String
        }
    }
    
    static var fileURL: String {
        if #available(iOS 14.0, *) {
            return UTType.fileURL.identifier
        } else {
            return kUTTypeFileURL as String
        }
    }
    
    static var text: String {
        if #available(iOS 14.0, *) {
            return UTType.text.identifier
        } else {
            return kUTTypeText as String
        }
    }
    
    static var plainText: String {
        if #available(iOS 14.0, *) {
            return UTType.plainText.identifier
        } else {
            return kUTTypePlainText as String
        }
    }
    
    static var data: String {
        if #available(iOS 14.0, *) {
            return UTType.data.identifier
        } else {
            return kUTTypeData as String
        }
    }
    
    static var item: String {
        if #available(iOS 14.0, *) {
            return UTType.item.identifier
        } else {
            return kUTTypeItem as String
        }
    }
}

