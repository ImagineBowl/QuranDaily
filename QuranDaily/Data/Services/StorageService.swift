import Foundation

final class StorageService: StorageServiceProtocol, @unchecked Sendable {
    private let fileManager: FileManager
    private let rootDirectory: URL

    init(
        fileManager: FileManager = .default,
        rootDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        if let rootDirectory {
            self.rootDirectory = rootDirectory
        } else if let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            self.rootDirectory = documents
        } else {
            self.rootDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    func save<T: Encodable>(_ value: T, to filename: String) async throws {
        let url = rootDirectory.appendingPathComponent(filename)
        try fileManager.createDirectory(
            at: rootDirectory,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(value)
        try data.write(to: url, options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, from filename: String) async throws -> T? {
        let url = rootDirectory.appendingPathComponent(filename)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }

    func fileExists(_ filename: String) async -> Bool {
        let url = rootDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: url.path)
    }

    func deleteFile(_ filename: String) async throws {
        let url = rootDirectory.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    func directorySize(at relativePath: String) async -> Int64 {
        let url = rootDirectory.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return 0 }
        return Self.calculateDirectorySize(at: url, fileManager: fileManager)
    }

    private static func calculateDirectorySize(at url: URL, fileManager: FileManager) -> Int64 {
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            let attributes = try? fileManager.attributesOfItem(atPath: url.path)
            return attributes?[.size] as? Int64 ?? 0
        }

        guard let contents = try? fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        return contents.reduce(0) { partial, itemURL in
            let values = try? itemURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if values?.isDirectory == true {
                return partial + calculateDirectorySize(at: itemURL, fileManager: fileManager)
            }
            return partial + Int64(values?.fileSize ?? 0)
        }
    }

    func ensureDirectory(_ relativePath: String) async throws {
        let url = rootDirectory.appendingPathComponent(relativePath)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func documentsURL(for relativePath: String) async -> URL {
        rootDirectory.appendingPathComponent(relativePath)
    }
}
