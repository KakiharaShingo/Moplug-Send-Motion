import Foundation
import Cocoa
import os.log

// MARK: - Application Class

@objc(MoplugApplication)
class MoplugApplication: NSApplication {

    @objc var assets = [MoplugAsset]()

    override init() {
        super.init()
        os_log("Moplug Send Motion: Application initialized", log: OSLog.default, type: .info)
        print("Moplug Send Motion: Application initialized")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - App Delegate

@objc class MoplugAppDelegate: NSObject, NSApplicationDelegate {

    var pendingFiles: [String] = []
    var isReady = false
    var mainWindow: NSWindow?
    var currentFileURL: URL?

    func applicationWillFinishLaunching(_ notification: Notification) {
        os_log("Moplug Send Motion: Application will finish launching", log: OSLog.default, type: .info)
        NSLog("DEBUG: applicationWillFinishLaunching called")

        // Register for Apple Events EARLY
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleOpenDocumentEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kCoreEventClass),
            andEventID: AEEventID(kAEOpenDocuments)
        )
        NSLog("DEBUG: Apple Event handler registered")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        os_log("Moplug Send Motion: Application finished launching", log: OSLog.default, type: .info)
        NSLog("DEBUG: applicationDidFinishLaunching called")

        isReady = true

        // Process any pending files
        if !pendingFiles.isEmpty {
            NSLog("DEBUG: Processing \(pendingFiles.count) pending files")
            for filename in pendingFiles {
                NSLog("DEBUG: About to call handleFCPXMLFile for \(filename)")
                _ = handleFCPXMLFile(at: URL(fileURLWithPath: filename))
                NSLog("DEBUG: Called handleFCPXMLFile")
            }
            pendingFiles.removeAll()
        } else {
            // No files provided
            NSLog("DEBUG: No pending files - waiting for Apple Event")
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func showMainWindow(with fileURL: URL) {
        NSLog("DEBUG: showMainWindow called with file: \(fileURL.path)")
        currentFileURL = fileURL

        // Create main window
        NSLog("DEBUG: Creating window...")
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Moplug Send Motion"
        window.center()

        // Create view with info and continue button
        let contentView = NSView(frame: window.contentView!.bounds)

        // Title label
        let titleLabel = NSTextField(labelWithString: "Ready to Send to Motion")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.frame = NSRect(x: 50, y: 200, width: 400, height: 30)
        titleLabel.alignment = .center
        contentView.addSubview(titleLabel)

        // File info label
        let fileLabel = NSTextField(labelWithString: "File: \(fileURL.lastPathComponent)")
        fileLabel.frame = NSRect(x: 50, y: 150, width: 400, height: 20)
        fileLabel.alignment = .center
        contentView.addSubview(fileLabel)

        // Continue button
        let continueButton = NSButton(frame: NSRect(x: 175, y: 80, width: 150, height: 40))
        continueButton.title = "Continue"
        continueButton.bezelStyle = .rounded
        continueButton.target = self
        continueButton.action = #selector(continueButtonClicked)
        contentView.addSubview(continueButton)

        // Cancel button
        let cancelButton = NSButton(frame: NSRect(x: 175, y: 40, width: 150, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelButtonClicked)
        contentView.addSubview(cancelButton)

        window.contentView = contentView
        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func continueButtonClicked() {
        guard let fileURL = currentFileURL else { return }
        mainWindow?.close()
        mainWindow = nil

        // Process the file
        processAndOpenInMotion(fileURL: fileURL)
    }

    @objc func cancelButtonClicked() {
        mainWindow?.close()
        mainWindow = nil
        NSApp.terminate(nil)
    }

    // Handle Apple Event directly
    @objc func handleOpenDocumentEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        os_log("Moplug Send Motion: Received Apple Event", log: OSLog.default, type: .info)
        NSLog("DEBUG: Received Apple Event")

        guard let fileListDescriptor = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject)) else {
            NSLog("DEBUG: No file list in event")
            return
        }

        NSLog("DEBUG: File list has \(fileListDescriptor.numberOfItems) items")

        for i in 1...fileListDescriptor.numberOfItems {
            if let fileDescriptor = fileListDescriptor.atIndex(i),
               let fileURLString = fileDescriptor.stringValue {
                NSLog("DEBUG: Processing file from Apple Event: \(fileURLString)")

                // Convert file:// URL to path
                if let url = URL(string: fileURLString) {
                    let path = url.path
                    NSLog("DEBUG: Converted to path: \(path)")
                    if isReady {
                        NSLog("DEBUG: App is ready, calling handleFCPXMLFile")
                        _ = handleFCPXMLFile(at: URL(fileURLWithPath: path))
                    } else {
                        NSLog("DEBUG: App not ready, adding to pending files")
                        pendingFiles.append(path)
                    }
                }
            }
        }
    }

    // Handle "open" Apple Event (from Final Cut Pro) - backup method
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        os_log("Moplug Send Motion: Received open file request: %{public}@", log: OSLog.default, type: .info, filename)
        print("Moplug Send Motion: Received open file request: \(filename)")

        if isReady {
            return handleFCPXMLFile(at: URL(fileURLWithPath: filename))
        } else {
            pendingFiles.append(filename)
            return true
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        os_log("Moplug Send Motion: Received open files request", log: OSLog.default, type: .info)
        print("Moplug Send Motion: Received open files request: \(filenames)")

        if isReady {
            for filename in filenames {
                _ = handleFCPXMLFile(at: URL(fileURLWithPath: filename))
            }
        } else {
            pendingFiles.append(contentsOf: filenames)
        }
    }

    // MARK: - FCPXML Processing

    private func handleFCPXMLFile(at fileURL: URL) -> Bool {
        NSLog("Moplug Send Motion: Processing file: \(fileURL.path)")
        NSLog("DEBUG: handleFCPXMLFile called")

        // Show main window with file info on main thread after a slight delay
        NSLog("DEBUG: About to call showMainWindow")
        DispatchQueue.main.async {
            NSLog("DEBUG: Async block executing")
            self.showMainWindow(with: fileURL)
        }
        NSLog("DEBUG: Scheduled showMainWindow")

        return true
    }

    private func processAndOpenInMotion(fileURL: URL) {
        NSLog("Moplug Send Motion: Processing and opening in Motion: \(fileURL.path)")

        // Check if this is a MOV file or FCPXML file
        let fileExtension = fileURL.pathExtension.lowercased()

        if fileExtension == "mov" {
            NSLog("Moplug Send Motion: Received MOV file, looking for FCPXML")
            // Try to find FCPXML in the same directory
            let fcpxmlURL = fileURL.deletingPathExtension().appendingPathExtension("fcpxml")
            if FileManager.default.fileExists(atPath: fcpxmlURL.path) {
                NSLog("Moplug Send Motion: Found FCPXML at \(fcpxmlURL.path)")
                processAndOpenInMotion(fileURL: fcpxmlURL)
                return
            } else {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "FCPXML Not Found"
                    alert.informativeText = "Please use 'File > Export XML' in Final Cut Pro to get FCPXML, then drag and drop it to Moplug Send Motion."
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    NSApp.terminate(nil)
                }
                return
            }
        }

        do {
            // Read FCPXML file
            let xmlString = try String(contentsOf: fileURL, encoding: .utf8)
            NSLog("Moplug Send Motion: Read FCPXML, length: \(xmlString.count)")

            // Parse FCPXML
            let parser = FCPXMLParser()
            let timeline = try parser.parse(xmlString: xmlString)

            // Generate Motion project
            let generator = MotionProjectGenerator()
            let motionProject = try generator.generateMotionProject(from: timeline)

            // Generate Motion XML
            let xmlGenerator = MotionXMLGenerator()
            let motionXML = try xmlGenerator.generateMotionXML(from: motionProject)

            guard let xmlData = motionXML.data(using: .utf8) else {
                throw NSError(domain: "com.moplug.sendmotion", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to encode XML"])
            }

            // Save to temporary location and open in Motion
            let tempDir = FileManager.default.temporaryDirectory
            let motionFileName = fileURL.deletingPathExtension().lastPathComponent + ".motn"
            let saveURL = tempDir.appendingPathComponent(motionFileName)

            try xmlData.write(to: saveURL)
            NSLog("Moplug Send Motion: Successfully wrote Motion project to \(saveURL.path)")

            // Open in Motion
            DispatchQueue.main.async {
                self.openMotion(withFile: saveURL)
                // Terminate app after opening Motion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NSApp.terminate(nil)
                }
            }

        } catch {
            NSLog("Moplug Send Motion: Error processing FCPXML: \(error)")
            DispatchQueue.main.async {
                self.showError("Failed to process FCPXML: \(error.localizedDescription)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func openMotion(withFile fileURL: URL) {
        let workspace = NSWorkspace.shared

        if let motionURL = workspace.urlForApplication(withBundleIdentifier: "com.apple.motionapp") {
            let configuration = NSWorkspace.OpenConfiguration()
            workspace.open([fileURL], withApplicationAt: motionURL, configuration: configuration) { _, error in
                if let error = error {
                    NSLog("Moplug Send Motion: Failed to open Motion: \(error)")
                }
            }
        } else {
            NSLog("Moplug Send Motion: Motion not found")
            showError("Motion app not found. Please install Motion.")
        }
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Moplug Send Motion"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Asset Class

@objc(MoplugAsset)
class MoplugAsset: NSObject {
    @objc var uniqueID: String = UUID().uuidString
    @objc var name: String = ""
    @objc var locationInfo: [String: Any] = [:]
    @objc var metadata: [String: Any] = [:]
    @objc var dataOptions: [String: Any] = [:]

    override init() {
        super.init()
    }
}

// MARK: - Make Command

@objc(MoplugMakeCommand)
class MoplugMakeCommand: NSCreateCommand {
    override func performDefaultImplementation() -> Any? {
        NSLog("Moplug Send Motion: Make command received")
        return super.performDefaultImplementation()
    }
}
