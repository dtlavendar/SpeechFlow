import Foundation

public enum ApplicationPaths {
    public static func defaultVaultDirectory() throws -> URL {
        let manager = FileManager.default
        let base =
            manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? manager.temporaryDirectory
        let bundleID = Bundle.main.bundleIdentifier ?? "dev.speechflow.SpeechFlow"
        let folder = base
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("Vault", isDirectory: true)
        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
