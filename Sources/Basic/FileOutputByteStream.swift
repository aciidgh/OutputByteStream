public class OutputByteStream2: OutputStream {
    private var buffer: [UInt8]

    public enum BufferMode {
        case unbuffered
        case buffered
    }

    public var bufferMode: BufferMode

    public var bufferSize: Int {
        return prefferedBufferSize
    }
    
    init(bufferMode: BufferMode = .buffered) {
        self.bufferMode = bufferMode
        buffer = []
    }

    deinit {
        flush()
    }
    
    public func write(_ bytes: [UInt8]) {
        // We're not using the buffer.
        if bufferMode == .unbuffered {
            writeImpl(bytes)
            return
        }
        
        let availableBufferSize = bufferSize - buffer.count
        // If we have to insert more than the available space in buffer.
        if bytes.count > availableBufferSize {
            // If buffer is empty start writing and keep the last chunk in buffer.
            if buffer.isEmpty {
               let bytesToWrite = bytes.count - (bytes.count % availableBufferSize)
               writeImpl(Array(bytes[0..<bytesToWrite]))

               // If remaining bytes is more than buffer size write everything.
               let bytesRemaining = bytes.count - bytesToWrite
               if bytesRemaining > bufferSize - buffer.count {
                    writeImpl(Array(bytes[bytesToWrite..<bytes.endIndex]))
                    return
               }
               // Otherwise keep remaining in buffer.
               buffer += bytes[bytesToWrite..<bytes.endIndex]
               return
            }

            // We don't have enough space in buffer.
            buffer += bytes[bytes.startIndex..<availableBufferSize]
            flush()
            write(Array(bytes[availableBufferSize..<bytes.endIndex]))
            return
        }

        buffer += bytes
    }

    public func flush() {
        writeImpl(buffer)
        buffer.removeAll(keepingCapacity: true)
    }

    public func write(_ string: String) {
        write([UInt8](string.utf8))
    }

    public func writeImpl(_ bytes: [UInt8]) {
        // Do nothing.
    }

    public var prefferedBufferSize: Int {
        return 1024
    }

    public var currentBuffer: ByteString {
        return ByteString(self.buffer)
    }
}

public final class StringOutputByteStream: OutputByteStream2 {
    private var string: UnsafeMutablePointer<String>

    public init(_ str: UnsafeMutablePointer<String>, bufferMode: BufferMode = .buffered) {
        string = str
        super.init(bufferMode: bufferMode)
    }

    override public func writeImpl(_ bytes: [UInt8]) {
        let tmp = bytes + [UInt8(0)]
        tmp.withUnsafeBufferPointer { ptr in
            string.pointee += String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
        }
    }
}

public final class FileOutputByteStream: OutputByteStream2 {
}
