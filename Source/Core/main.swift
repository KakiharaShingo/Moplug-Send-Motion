import Cocoa

// Ensure the application is activated
NSApplication.shared.setActivationPolicy(.regular)

// Set up the application
let app = NSApplication.shared
let delegate = MoplugAppDelegate()
app.delegate = delegate

// Activate the app
app.activate(ignoringOtherApps: true)

// Run the application
app.run()
