import CryptoKit
import Foundation
import NetworkingKit
import UIKit

/// Two-level image cache: decoded images in memory (`NSCache`), original bytes on disk (Caches/).
///
/// - Memory hits are synchronous (`cachedImage(for:)`) so cells that scroll back on screen don't flash.
/// - Concurrent requests for one URL share a single download.
/// - Disk reads, downloads and decoding run off the main thread (`@concurrent`).
/// - `trimDiskCache()` evicts least-recently-used files above `maxDiskBytes`.
actor ImagePipeline {
    static let shared = ImagePipeline()

    enum PipelineError: Error {
        case badStatus(Int)
        case undecodableData
    }

    /// `NSCache` is documented as thread-safe, so it can be read without hopping onto the actor.
    private nonisolated(unsafe) let memory = NSCache<NSURL, UIImage>()
    private let directory: URL
    private let transport: any HTTPTransport
    private let maxDiskBytes: Int
    private var inFlight: [URL: Task<UIImage, any Error>] = [:]

    init(
        directory: URL = URL.cachesDirectory.appending(path: "Images", directoryHint: .isDirectory),
        transport: any HTTPTransport = URLSession(configuration: .ephemeral),
        memoryLimitBytes: Int = 80 * 1024 * 1024,
        maxDiskBytes: Int = 200 * 1024 * 1024
    ) {
        self.directory = directory
        self.transport = transport
        self.maxDiskBytes = maxDiskBytes
        memory.totalCostLimit = memoryLimitBytes
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    nonisolated func cachedImage(for url: URL) -> UIImage? {
        memory.object(forKey: url as NSURL)
    }

    func image(for url: URL) async throws -> UIImage {
        if let image = cachedImage(for: url) {
            return image
        }
        if let task = inFlight[url] {
            return try await task.value
        }

        let task = Task { try await Self.load(url, directory: directory, transport: transport) }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        memory.setObject(image, forKey: url as NSURL, cost: image.memoryCost)
        return image
    }

    // MARK: - Disk cache maintenance

    func diskUsageBytes() -> Int {
        cachedFiles().reduce(0) { $0 + $1.size }
    }

    func trimDiskCache() {
        var files = cachedFiles()
        var total = files.reduce(0) { $0 + $1.size }
        guard total > maxDiskBytes else { return }

        files.sort { $0.lastUsed < $1.lastUsed }
        for file in files where total > maxDiskBytes {
            try? FileManager.default.removeItem(at: file.url)
            total -= file.size
        }
    }

    func removeAll() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - Private

    @concurrent
    private static func load(_ url: URL, directory: URL, transport: any HTTPTransport) async throws -> UIImage {
        let file = fileURL(for: url, in: directory)

        if let data = try? Data(contentsOf: file), let image = await decode(data) {
            // Bump the modification date so trimming treats this file as recently used.
            try? FileManager.default.setAttributes([.modificationDate: Date.now], ofItemAtPath: file.path)
            return image
        }

        let (data, response) = try await transport.send(URLRequest(url: url))
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw PipelineError.badStatus(http.statusCode)
        }
        guard let image = await decode(data) else {
            throw PipelineError.undecodableData
        }
        try? data.write(to: file, options: .atomic)
        return image
    }

    /// Decodes and pre-renders the bitmap so the first frame on screen doesn't pay for it.
    @concurrent
    private static func decode(_ data: Data) async -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        return await image.byPreparingForDisplay() ?? image
    }

    private static func fileURL(for url: URL, in directory: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: name)
    }

    private func cachedFiles() -> [(url: URL, size: Int, lastUsed: Date)] {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: keys)) ?? []
        return urls.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: Set(keys)) else { return nil }
            return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
        }
    }
}

private extension UIImage {
    nonisolated var memoryCost: Int {
        guard let cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
