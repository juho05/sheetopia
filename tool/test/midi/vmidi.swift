// vmidi <name> <command file>: a virtual MIDI device for the E2E tests, a
// source and a destination with the same name like most virtual devices
// (ios_sim.sh midi, macos_vm.sh midi).
//
// Unlike `sendmidi virt`, which removes its source when it exits after
// sending, the device stays until the process is killed, and every message
// comes from that one source, so a connection the app made keeps receiving.
//
// iOS simulator: it has its own MIDI server, a source created on the host
// never shows up in it. A process spawned in the simulator shares the app's
// server, but iOS only allows creating endpoints with the "audio" background
// mode, which vmidi-ios-Info.plist linked into the binary grants.
//
// Sends every line appended to the command file (channel 1):
//   on <note> <velocity> | off <note> <velocity> | cc <number> <value>
import CoreMIDI
import Foundation

setvbuf(stdout, nil, _IOLBF, 0)
let args = CommandLine.arguments
guard args.count == 3 else { print("usage: vmidi <name> <command file>"); exit(64) }
let name = args[1], path = args[2]

var client = MIDIClientRef(), source = MIDIEndpointRef(), destination = MIDIEndpointRef()
var status = MIDIClientCreateWithBlock("sheetopia-e2e" as CFString, &client) { _ in }
// The destination first: an app listing the device while only the source
// exists would see a source-only device.
if status == noErr {
  status = MIDIDestinationCreateWithProtocol(client, name as CFString, ._1_0, &destination) { list, _ in
    print("received \(list.pointee.numPackets) packet(s)")
  }
}
if status == noErr { status = MIDISourceCreateWithProtocol(client, name as CFString, ._1_0, &source) }
guard status == noErr else { print("error: creating the MIDI endpoints failed (\(status))"); exit(1) }
FileManager.default.createFile(atPath: path, contents: nil)
guard let file = FileHandle(forReadingAtPath: path) else { print("error: can't read \(path)"); exit(1) }
file.seekToEndOfFile()
print("ready: \(name)")

func send(_ line: String) {
  let f = line.split(separator: " ").map(String.init)
  let kinds: [String: UInt32] = ["on": 0x90, "off": 0x80, "cc": 0xB0]
  guard f.count == 3, let kind = kinds[f[0]], let a = UInt32(f[1]), let b = UInt32(f[2]), a < 128, b < 128 else {
    print("ignored: \(line)")
    return
  }
  // A MIDI 1.0 channel voice message as a universal MIDI packet (type 2).
  var list = MIDIEventList()
  let packet = MIDIEventListInit(&list, ._1_0)
  _ = MIDIEventListAdd(&list, MemoryLayout<MIDIEventList>.size, packet, 0, 1, [0x2000_0000 | kind << 16 | a << 8 | b])
  print(MIDIReceivedEventList(source, &list) == noErr ? "sent: \(line)" : "error: \(line)")
}

var pending = ""
while true {
  let data = file.readDataToEndOfFile()
  if data.isEmpty {
    Thread.sleep(forTimeInterval: 0.05)
    continue
  }
  pending += String(decoding: data, as: UTF8.self)
  while let nl = pending.firstIndex(of: "\n") {
    let line = pending[..<nl].trimmingCharacters(in: .whitespaces)
    pending = String(pending[pending.index(after: nl)...])
    if !line.isEmpty { send(line) }
  }
}
