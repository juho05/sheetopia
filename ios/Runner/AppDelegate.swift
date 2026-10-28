import Flutter
import UIKit
import flutter_sharing_intent

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SheetopiaFileExport") {
      FileExportHandler.shared.register(messenger: registrar.messenger())
    }
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

   let sharingIntent = SwiftFlutterSharingIntentPlugin.instance
   /// if the url is made from SwiftFlutterSharingIntentPlugin then handle it with plugin [SwiftFlutterSharingIntentPlugin]
   if sharingIntent.hasSameSchemePrefix(url: url) {
     return sharingIntent.application(app, open: url, options: options)
   }

   // Proceed url handling for other Flutter libraries like uni_links
   return super.application(app, open: url, options:options)
  }
}

class FileExportHandler: NSObject, UIDocumentPickerDelegate, UIAdaptivePresentationControllerDelegate {
  static let shared = FileExportHandler()

  private var pendingResult: FlutterResult?
  private var stagingDir: URL?

  func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "sheetopia/file_export", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "exportFile" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.exportFile(arguments: call.arguments as? [String: Any], result: result)
    }
  }

  private func exportFile(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "already_active", message: "another export is already in progress", details: nil))
      return
    }
    guard let path = arguments?["path"] as? String, let presenter = topViewController() else {
      result(FlutterError(code: "export_failed", message: "missing path or view controller", details: nil))
      return
    }
    let source = URL(fileURLWithPath: path)
    let exportURL: URL
    do {
      exportURL = try staged(source: source, fileName: arguments?["fileName"] as? String)
    } catch {
      result(FlutterError(code: "export_failed", message: error.localizedDescription, details: nil))
      return
    }
    pendingResult = result
    let picker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
    picker.delegate = self
    picker.presentationController?.delegate = self
    presenter.present(picker, animated: true)
  }

  private func staged(source: URL, fileName: String?) throws -> URL {
    guard let fileName, !fileName.isEmpty, fileName != source.lastPathComponent else {
      return source
    }
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent("sheetopia_export")
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    stagingDir = dir
    let target = dir.appendingPathComponent(fileName)
    do {
      try FileManager.default.copyItem(at: source, to: target)
    } catch {
      finish(nil)
      throw error
    }
    return target
  }

  private func finish(_ value: Any?) {
    if let stagingDir {
      try? FileManager.default.removeItem(at: stagingDir)
    }
    stagingDir = nil
    pendingResult?(value)
    pendingResult = nil
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    finish(urls.first?.absoluteString)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finish(nil)
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finish(nil)
  }
}
