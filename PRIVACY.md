# Privacy Policy

Last updated: 2026-08-18

Sheetopia is a local-first app. It has no analytics, no crash reporting and no advertising. Your data stays on your
device unless you turn on sync, in which case it goes to the server you configure. The developer, Julian Hofmann,
operates no server for this app and receives no data from it in either case.

## Data stored on your device

Your scores (PDF files), their metadata, annotations, setlists, tags and app settings are stored on your device, and are
uploaded only if you enable sync. Diagnostic logs are stored locally, are never synced, and are deleted automatically
after 7 days. Logs leave your device only if you export or share them yourself.

## Sync (optional)

Sync is off by default. If you enable it, you sign in to a [sync server](https://github.com/juho05/sheetopia-sync) that
you or someone you trust runs. Your account exists only on that server, not with the developer. Sheetopia then uploads
your scores, metadata, annotations, setlists and tags to that server so your devices stay in sync. Only that server
receives the data, never the developer. How the data is handled there is up to whoever operates it. Use an HTTPS address
so the transfer is encrypted.

Your server address, username and login token are stored in the operating system's secure credential store.

## Update checks

Builds distributed outside of app stores check GitHub for new releases and can download them. GitHub receives your IP
address and the usual request metadata when this happens. You can turn this off under Settings > Version checking.
Builds distributed via app stores have this feature removed and never contact GitHub.

## Permissions

- Camera: scanning sheet music into the app. Scans become scores in your library.
- Bluetooth and local network: discovering MIDI devices and foot switches for page turning. No data is sent to them
  beyond MIDI handshakes.
- Files: importing and exporting scores and backups that you select.
- Install packages (Android): installing app updates you confirm. Not applicable for Play Store releases.

## Contact

Julian Hofmann, sheetopia@julianh.de or
https://github.com/juho05/sheetopia/issues
