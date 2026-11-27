/// A bounded, least-recently-used cache for completed Study frames. The owner
/// supplies payload costs; keys and other value storage are bounded by the
/// entry limit and must be kept small independently. Synchronization and render
/// cancellation remain the owner's responsibility.
public struct StudyFrameCache<Key: Equatable & Sendable, Value: Sendable>: Sendable {
    public let maximumCount: Int
    public let maximumPixelBytes: Int
    public let maximumMaskBytes: Int

    public var count: Int { entries.count }
    public private(set) var pixelBytes = 0
    public private(set) var maskBytes = 0

    private struct Entry: Sendable {
        let key: Key
        let value: Value
        let pixelBytes: Int
        let maskBytes: Int
    }

    // Least recently used first. No capacity reservation: a large configured
    // limit does not allocate storage until valid entries are actually added.
    private var entries: [Entry] = []

    /// Limits are immutable and must be positive. Payload costs may be zero;
    /// the entry limit still bounds zero-cost entries.
    public init(maximumCount: Int, maximumPixelBytes: Int, maximumMaskBytes: Int) {
        precondition(maximumCount > 0 && maximumPixelBytes > 0 && maximumMaskBytes > 0,
                     "Study frame cache limits must be positive")
        self.maximumCount = maximumCount
        self.maximumPixelBytes = maximumPixelBytes
        self.maximumMaskBytes = maximumMaskBytes
    }

    /// A hit becomes most recently used. A miss leaves order and costs intact.
    public mutating func value(for key: Key) -> Value? {
        guard let index = entries.firstIndex(where: { $0.key == key }) else { return nil }
        let entry = entries.remove(at: index)
        entries.append(entry)
        return entry.value
    }

    /// Returns false for negative or individually oversized costs, leaving
    /// every existing entry and its recency unchanged. An admitted replacement
    /// removes the old value before evicting other entries and becomes newest.
    /// Eviction precedes append, so neither byte budget nor the entry limit is
    /// transiently exceeded. Separate subtraction checks avoid overflow even
    /// when a configured byte limit is Int.max.
    @discardableResult
    public mutating func insert(_ value: Value, for key: Key,
                                pixelBytes: Int, maskBytes: Int) -> Bool {
        guard pixelBytes >= 0, pixelBytes <= maximumPixelBytes,
              maskBytes >= 0, maskBytes <= maximumMaskBytes else { return false }

        if let index = entries.firstIndex(where: { $0.key == key }) {
            remove(at: index)
        }
        while !entries.isEmpty &&
                (entries.count >= maximumCount ||
                 self.pixelBytes > maximumPixelBytes - pixelBytes ||
                 self.maskBytes > maximumMaskBytes - maskBytes) {
            remove(at: 0)
        }

        entries.append(Entry(key: key, value: value, pixelBytes: pixelBytes, maskBytes: maskBytes))
        self.pixelBytes += pixelBytes
        self.maskBytes += maskBytes
        return true
    }

    /// Selective invalidation, for example after a rendering backend fails.
    /// Surviving entries retain their relative least-recently-used order.
    public mutating func removeAll(where shouldBeRemoved: (Value) -> Bool) {
        for index in entries.indices.reversed() where shouldBeRemoved(entries[index].value) {
            remove(at: index)
        }
    }

    private mutating func remove(at index: Int) {
        let entry = entries.remove(at: index)
        pixelBytes -= entry.pixelBytes
        maskBytes -= entry.maskBytes
    }
}
