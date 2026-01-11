//
//  WhiskyWineInstaller.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import SemanticVersion

public final class WhiskyWineInstaller {

    // MARK: - Paths

    /// Root folder where bundled libraries live inside the app bundle
    /// MyBourbon.app/Contents/Resources/Libraries
    public static let libraryFolder: URL = {
        guard let resourceURL = Bundle.main.resourceURL else {
            fatalError("Unable to locate app Resources directory")
        }
        return resourceURL.appendingPathComponent("Libraries", isDirectory: true)
    }()

    /// Wine bin folder inside the bundled Wine directory
    public static let binFolder: URL = {
        libraryFolder
            .appendingPathComponent("Wine", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
    }()

    // MARK: - Status

    /// Returns true if Wine is present inside the app bundle
    public static func isWhiskyWineInstalled() -> Bool {
        FileManager.default.fileExists(atPath: binFolder.path)
    }

    // MARK: - Install (Bundled Wine)

    /// Bundled Wine cannot be installed at runtime
    /// This method only ensures the quarantine attribute is removed
    public static func install(from _: URL) {
        removeQuarantineAttribute()
    }

    // MARK: - Quarantine

    /// Removes the quarantine attribute from the bundled Libraries directory
    private static func removeQuarantineAttribute() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        process.arguments = [
            "-dr",
            "com.apple.quarantine",
            libraryFolder.path
        ]

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                print("Successfully removed quarantine attribute from bundled Wine")
            } else {
                print("xattr exited with code \(process.terminationStatus)")
            }
        } catch {
            print("Failed to remove quarantine attribute: \(error)")
        }
    }

    // MARK: - Uninstall (Disabled)

    /// Bundled Wine cannot be removed at runtime
    public static func uninstall() {
        print("Bundled Wine cannot be uninstalled")
    }

    // MARK: - Updates (Disabled)

    /// Runtime Wine updates are disabled for bundled Wine
    public static func shouldUpdateWhiskyWine() async -> (Bool, SemanticVersion) {
        let version = whiskyWineVersion() ?? SemanticVersion(0, 0, 0)
        return (false, version)
    }

    // MARK: - Version

    public static func whiskyWineVersion() -> SemanticVersion? {
        let versionPlistURL = libraryFolder
            .appendingPathComponent("WhiskyWineVersion")
            .appendingPathExtension("plist")

        guard FileManager.default.fileExists(atPath: versionPlistURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: versionPlistURL)
            let decoder = PropertyListDecoder()
            let info = try decoder.decode(WhiskyWineVersion.self, from: data)
            return info.version
        } catch {
            print("Failed to read WhiskyWineVersion plist: \(error)")
            return nil
        }
    }
}

// MARK: - Model

struct WhiskyWineVersion: Codable {
    let version: SemanticVersion
}
