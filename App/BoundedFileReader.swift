import Darwin
import Foundation

/// Reads only an opened regular file. Callers retain responsibility for any
/// security scope or file-provider coordination surrounding this operation.
enum BoundedFileReader {
    enum ReadError: Error, Equatable {
        case notRegularFile, unreadable, tooLarge
    }

    /// A pathname metadata check cannot prove what a later open will read.
    /// O_NOFOLLOW rejects a final symbolic link and O_NONBLOCK prevents a FIFO
    /// from blocking before fstat validates the actual opened descriptor.
    /// The additional checkpoint may throw to cancel caller-specific work;
    /// it cannot suppress cancellation of the current Swift task.
    static func read(from url: URL, maximumBytes: Int,
                     checkCancellation: () throws -> Void = {}) throws -> Data {
        func checkpoint() throws {
            try Task.checkCancellation()
            try checkCancellation()
        }
        try checkpoint()
        guard url.isFileURL, maximumBytes >= 0, maximumBytes < Int.max else {
            throw ReadError.unreadable
        }
        let descriptor = url.withUnsafeFileSystemRepresentation { path -> Int32 in
            guard let path else { errno = EINVAL; return -1 }
            return Darwin.open(path, O_RDONLY | O_NOFOLLOW | O_NONBLOCK | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            if errno == ELOOP { throw ReadError.notRegularFile }
            throw ReadError.unreadable
        }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }
        var info = stat()
        guard Darwin.fstat(descriptor, &info) == 0, info.st_size >= 0 else {
            throw ReadError.unreadable
        }
        guard info.st_mode & mode_t(S_IFMT) == mode_t(S_IFREG) else {
            throw ReadError.notRegularFile
        }
        guard info.st_size <= maximumBytes else { throw ReadError.tooLarge }
        var contents = Data()
        contents.reserveCapacity(Int(info.st_size))
        while true {
            try checkpoint()
            // Read at most one extra byte even if the file grows after fstat.
            let remaining = maximumBytes + 1 - contents.count
            guard remaining > 0 else { throw ReadError.tooLarge }
            let chunk: Data?
            do { chunk = try handle.read(upToCount: min(64 * 1024, remaining)) }
            catch { throw ReadError.unreadable }
            guard let chunk, !chunk.isEmpty else { break }
            contents.append(chunk)
            guard contents.count <= maximumBytes else { throw ReadError.tooLarge }
        }
        try checkpoint()
        return contents
    }
}
