import Cocoa

let app = MoplugApplication.shared as! MoplugApplication
let appDelegate = MoplugAppDelegate()

// Ensure the application is activated
app.setActivationPolicy(.regular)

// Set up the application delegate
app.delegate = appDelegate

// Activate the app
app.activate(ignoringOtherApps: true)

// Run the application
app.run()
