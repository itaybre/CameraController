//  Created by Dave DeLong on 9/22/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

//
//  Created by Jeff Barnes on 1/4/15.
//  Copyright (c) 2015 Sonarr. All rights reserved.
//
//  Heavily modified from https://github.com/potionfactory/LetsMove (public domain)

//

// Delete Item
//
// [[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation]
//    This is deprecated, as of OS X 10.11, so no point in using it.
//
//    [[NSWorkspace sharedWorkspace] recycleURLs:]
//    This is probably the one you want. It's asynchronous, so your application can continue
//    to operate while the files are being moved to the trash.
//
//    FileManager.default.trashItem(AtURL:)
//    This is similar to option 2, but it's synchronous, and only handles one file at a time.
//
//    FileManager.default.removeItem(AtPath:)
//    This doesn't trash the file, it deletes it permanently, and immediately.
//
//    FileManager.default.removeItemAtURL:]
//  This is just like option 4, except using a file:// URL instead of a path. More-convenient when
//  you already have a URL rathe than a path.

import AppKit
import Security

class LetsMove: NSObject {
    struct MoveStrings {
        let couldNotMove = NSLocalizedString("Could not move to Applications folder",
                                             tableName: "MoveApplication", comment: "")
        let questionTitle = NSLocalizedString("Move to Applications folder?",
                                              tableName: "MoveApplication", comment: "")
        let questionTitleHome = NSLocalizedString("Move to Applications folder in your Home folder?",
                                                  tableName: "MoveApplication", comment: "")
        let questionMessage = NSLocalizedString("I can move myself to the Applications folder if you'd like.",
                                                tableName: "MoveApplication", comment: "")
        let buttonMove = NSLocalizedString("Move to Applications Folder",
                                           tableName: "MoveApplication", comment: "")
        let buttonStay = NSLocalizedString("Do Not Move",
                                           tableName: "MoveApplication", comment: "")
        let infoNeedsPassword = NSLocalizedString("Note that this will require an administrator password.",
                                                  tableName: "MoveApplication", comment: "")
        let infoInDownloads = NSLocalizedString("This will keep your Downloads folder uncluttered.",
                                                tableName: "MoveApplication", comment: "")
    }
    static let shared = LetsMove()

    let useSmallAlertSuppressCheckbox = true
    let alertSuppressKey = "moveToApplicationsFolderAlertSuppress"

    let fileManager = FileManager.default
    lazy var moveStrings = MoveStrings()

    // Main worker function
    func moveToApplicationsFolderIfNecessary() {
        // Skip if user suppressed the alert before
        guard !UserDefaults.standard.bool(forKey: alertSuppressKey) else { return }

        // Path of the bundle
        let bundlePath = Bundle.main.bundlePath
        let bundleNameURL = URL(fileURLWithPath: bundlePath)

        // Skip if the application is already in some Applications folder
        guard !isInApplicationsFolder(bundleNameURL) else { return }

        // Since we are good to go, get the preferred installation directory.
        let (applicationsDirectory, installToUserApplications) = preferredInstallLocation()
        let bundleName = bundleNameURL.lastPathComponent
        let destinationURL = applicationsDirectory!.appendingPathComponent(bundleName)

        // Check if we need admin password to write to the Applications directory
        // Check if the destination bundle is already there but not writable
        let isWritableFileSrc = fileManager.isWritableFile(atPath: applicationsDirectory!.path)
        let isFileExists =  fileManager.fileExists(atPath: destinationURL.path)
        let isWritableFileDst = fileManager.isWritableFile(atPath: destinationURL.path)

        let isNeedAuthorization = !isWritableFileSrc || (isFileExists && !isWritableFileDst)

        // Setup the alert
        let alert = createAlert(bundleNameURL, installToUserApplications, isNeedAuthorization)

        // Activate app -- work-around for focus issues related to "scary file from internet" OS dialog.
        if !NSApp.isActive {
            NSApp.activate(ignoringOtherApps: true)
        }

        if alert.runModal() == .alertFirstButtonReturn {
            print("INFO -- Moving myself to the Applications folder")

            if isNeedAuthorization {
                if !authorizedInstall(srcPath: bundlePath, dstPath: destinationURL.path) {
                    print("ERROR -- Could not copy myself to /Applications with authorization")
                    return
                }
            } else if !moveBundle(bundlePath, destinationURL, applicationsDirectory, bundleName, moveStrings) {
                return
            }
            // Trash the original app. It's okay if this fails.
            // NOTE: This final delete does not work if the source bundle is in a network mounted volume.
            //       Calling rm or file manager's delete method doesn't work either. It's unlikely to happen
            //       but it'd be great if someone could fix this.
            if !deleteOrTrash(path: bundlePath) {
                print("WARNING -- Could not delete application after moving it to Applications folder")
            }

            // Relaunch.
            print("relaunch")
            relaunch(destinationPath: destinationURL.path)
            exit(0)
        } else if alert.suppressionButton!.state == .on {
            // Save the alert suppress preference if checked
            UserDefaults.standard.set(true, forKey: alertSuppressKey)
        }
    }

    private func createAlert(_ bundleNameURL: URL?,
                             _ installToUserApplications: Bool,
                             _ isNeedAuthorization: Bool) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = installToUserApplications ? moveStrings.questionTitleHome : moveStrings.questionTitle
        var informativeText = moveStrings.questionMessage

        if isNeedAuthorization {
            informativeText += " " + moveStrings.infoNeedsPassword
        } else if isInDownloadsFolder(bundleNameURL!) {
            // Don't mention this stuff if we need authentication. The informative text is
            // long enough as it is in that case.
            informativeText += " " + moveStrings.infoInDownloads
        }

        alert.informativeText = informativeText

        // Add accept button
        alert.addButton(withTitle: moveStrings.questionTitle)

        // Add deny button
        let cancelButton = alert.addButton(withTitle: moveStrings.buttonStay)
        cancelButton.keyEquivalent = "\u{1B}"

        // Setup suppression button
        alert.showsSuppressionButton = true

        if useSmallAlertSuppressCheckbox,
           let cell = alert.suppressionButton?.cell {
            cell.font = NSFont(name: "HelveticaNeue", size: 10)
        }

        return alert
    }

    private func moveBundle(_ bundlePath: String,
                            _ destinationURL: URL,
                            _ applicationsDirectory: URL?,
                            _ bundleName: String,
                            _ moveStrings: LetsMove.MoveStrings) -> Bool {
        // If a copy already exists in the Applications folder, put it in the Trash
        if fileManager.fileExists(atPath: destinationURL.path) {

            // But first, make sure that it's not running
            if isApplicationAtPathRunning(path: destinationURL.path) {
                // Give the running app focus and terminate myself
                print("INFO -- Switching to an already running version")
                Process.launchedProcess(launchPath: "/usr/bin/open", arguments:
                                            [destinationURL.path]).waitUntilExit()
                exit(0)
            } else {
                let path = applicationsDirectory!.appendingPathComponent(bundleName).path
                if !trash(path: path) {
                    let alert = NSAlert()
                    alert.messageText = moveStrings.couldNotMove
                    alert.runModal()
                    return false
                }
            }
        }

        if !copyBundle(srcPath: bundlePath, dstPath: destinationURL.path) {
            print("Could not copy myself to \(destinationURL.path)")
            return false
        }

        return true
    }

    // Return the preferred install location.
    // Assume that if the user has a ~/Applications folder, they'd prefer their
    // applications to go there.
    fileprivate func preferredInstallLocation() -> (URL?, Bool) {

        var appDir: URL?
        var isUserDir = false

        let userAppDirs = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true)
        if let userDir = userAppDirs.first {
            var directory: ObjCBool = ObjCBool(true)

            if fileManager.fileExists(atPath: userDir, isDirectory: &directory ) {
                let contents = (try? fileManager.contentsOfDirectory(atPath: userDir)) ?? []
                if contents.contains(where: { $0.hasSuffix(".app") }) {
                    appDir = URL(fileURLWithPath: userDir)
                    isUserDir = true
                }
            }
        }

        if appDir == nil {
            let localLocations = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true)
            if let last = localLocations.last {
                appDir = URL(fileURLWithPath: last)
            }
        }
        return (appDir, isUserDir)
    }

    func isInFolder(_ path: URL, _ folder: FileManager.SearchPathDirectory, _ alternativeName: String? = nil) -> Bool {
        let allFolders = NSSearchPathForDirectoriesInDomains(folder, .allDomainsMask, true)
        let pathstr = path.path
        for folder in allFolders where pathstr.hasPrefix(folder) {
            return true
        }

        if let alt = alternativeName {
            let components = (path.path as NSString).pathComponents
            return components.contains(alt)
        }
        return false
    }

    func isInApplicationsFolder(_ current: URL) -> Bool {
        return isInFolder(current, .applicationDirectory, "Applications")
    }

    func isInDownloadsFolder(_ current: URL) -> Bool {
        return isInFolder(current, .downloadsDirectory)
    }

//    func IsInDownloadsFolder(path: String?) -> Bool {
//        let downloadDirs = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .allDomainsMask, true)
//        for downloadsDirPath in downloadDirs {
//            if path?.hasPrefix(downloadsDirPath) ?? false {
//                return true
//            }
//        }
//        return false
//    }

    func isApplicationAtPathRunning(path: String) -> Bool {
        // Use the new API on 10.6 or higher to determine if the app is already running
        for runningApplication in NSWorkspace.shared.runningApplications {
            let executablePath = runningApplication.executableURL!.path
            if executablePath.hasPrefix(path) {
                return true
            }
        }
        return false
    }

    func trash(path: String) -> Bool {
        let pathURL = URL(fileURLWithPath: path)

        do {
            try fileManager.trashItem(at: pathURL, resultingItemURL: nil )
        } catch let error as NSError {
            print("Ooops! Something went wrong: \(error)")
            print("ERROR -- Could not trash \(path)")
            return false

        }
        return true
    }

    func deleteOrTrash(path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("WARNING -- Could not delete '\(path)': \(error.localizedDescription)",
                  path, error.localizedDescription)
            NSAlert(error: error).runModal()
            return trash(path: path)
        }
    }

    func authorizedInstall(srcPath: String, dstPath: String) -> Bool {
        // Make sure that the destination path is an app bundle. We're essentially running 'sudo rm -rf'
        // so we really don't want to mess this up.
        guard dstPath.hasSuffix(".app") else { return false }

        // Do some more checks
        if dstPath.trimmingCharacters(in: CharacterSet.whitespaces) == "" { return false }
        if srcPath.trimmingCharacters(in: CharacterSet.whitespaces) == "" { return false }

        // Delete the destination
        if sudoShellCmd(cmd: "/bin/rm", args: "-rf", dstPath) == nil {
            return false
        }

        // Copy
        if sudoShellCmd(cmd: "/bin/cp", args: "-pR", srcPath, dstPath) == nil {
            return false
        }
        return true
    }

    func copyBundle(srcPath: String, dstPath: String) -> Bool {
        do {
            try fileManager.copyItem(atPath: srcPath, toPath: dstPath)
            return true
        } catch {
            print("ERROR -- Could not copy '\(srcPath)' to '\(dstPath)' (\(error.localizedDescription))")
            NSAlert(error: error).runModal()
            return false
        }
    }

    func relaunch(destinationPath: String) {
        // The shell script waits until the original app process terminates.
        // This is done so that the relaunched app opens as the front-most app.
        let pid = ProcessInfo.processInfo.processIdentifier

        // Command run just before running open /final/path
        let quotedDestinationPath = shellQuotedString(string: destinationPath)

        // OS X >=10.5:
        // Before we launch the new app, clear xattr:com.apple.quarantine to avoid
        // duplicate "scary file from the internet" dialog.
        // Add the -r flag on 10.6
        let preOpenCmd = String(format: "/usr/bin/xattr -d -r com.apple.quarantine %@", quotedDestinationPath)
        let cmd = "(while /bin/kill -0 %d >&/dev/null; do /bin/sleep 0.1; done; %@; /usr/bin/open %@) &"
        let script = String(format: cmd, pid, preOpenCmd, quotedDestinationPath)
        Process.launchedProcess(launchPath: "/bin/sh", arguments: ["-c", script])
    }

    func sudoShellCmd(cmd: String, args: String...) -> String? {
        let fullScript = String(format: "'%@' %@", cmd, args.joined(separator: " "))
        let script = String(format: "do shell script \"%@\" with administrator privileges", fullScript)

        var errorInfo: NSDictionary?

        if let result = NSAppleScript(source: script)?.executeAndReturnError(&errorInfo).stringValue {
            return result
        }

        if let errorStr = errorInfo?[NSAppleScript.errorMessage] {
            print("Error running process as administrator: \(errorStr)")
        } else {

            print("Error running process as administrator.")
        }
        return nil
    }

    func shellQuotedString(string: String) -> String {
        return String(format: "'%@'", string.replacingOccurrences(of: "'", with: "'\\''"))
    }
}

extension String {
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
}
