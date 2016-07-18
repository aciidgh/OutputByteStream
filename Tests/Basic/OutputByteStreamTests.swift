import XCTest
@testable import Basic 

class OutputByteStreamTests: XCTestCase {
    
    func testSecond() {
        var str = ""
        let stream = StringOutputByteStream(&str)
        for i in 0..<10000 {
            stream.write("hello \(i)")
        }
    }
    
    func testBasics() {
        let stream = OutputByteStream()
        
        stream.write("Hello")
        stream.write(Character(","))
        stream.write(Character(" "))
        stream.write([UInt8]("wor".utf8))
        stream.write([UInt8]("world".utf8)[3..<5])
        
        let streamable: Streamable = Character("!")
        stream.write(streamable)

        stream.flush()
        
        XCTAssertEqual(stream.position, "Hello, world!".utf8.count)
        XCTAssertEqual(stream.bytes, "Hello, world!")
    }
    
    func testStreamOperator() {
        let stream = OutputByteStream()

        let streamable: Streamable = Character("!")
        stream <<< "Hello" <<< Character(",") <<< Character(" ") <<< [UInt8]("wor".utf8) <<< [UInt8]("world".utf8)[3..<5] <<< streamable
        
        XCTAssertEqual(stream.position, "Hello, world!".utf8.count)
        XCTAssertEqual(stream.bytes, "Hello, world!")

        let stream2 = OutputByteStream()
        stream2 <<< (0..<5)
        XCTAssertEqual(stream2.bytes, [0, 1, 2, 3, 4])
    }
    
    func testJSONEncoding() {
        // Test string encoding.
        func asJSON(_ value: String) -> ByteString {
            let stream = OutputByteStream()
            stream.writeJSONEscaped(value)
            return stream.bytes
        }
        XCTAssertEqual(asJSON("a'\"\\"), "a'\\\"\\\\")
        XCTAssertEqual(asJSON("\u{0008}"), "\\b")
        XCTAssertEqual(asJSON("\u{000C}"), "\\f")
        XCTAssertEqual(asJSON("\n"), "\\n")
        XCTAssertEqual(asJSON("\r"), "\\r")
        XCTAssertEqual(asJSON("\t"), "\\t")
        XCTAssertEqual(asJSON("\u{0001}"), "\\u0001")

        // Test other random types.
        XCTAssertEqual((OutputByteStream() <<< Format.asJSON(false)).bytes, "false")
        XCTAssertEqual((OutputByteStream() <<< Format.asJSON(1 as Int)).bytes, "1")
        XCTAssertEqual((OutputByteStream() <<< Format.asJSON(1.2 as Double)).bytes, "1.2")
    }
    
    func testFormattedOutput() {
        do {
            let stream = OutputByteStream()
            stream <<< Format.asJSON("\n")
            XCTAssertEqual(stream.bytes, "\"\\n\"")
        }
        
        do {
            let stream = OutputByteStream()
            stream <<< Format.asJSON(["hello", "world\n"])
            XCTAssertEqual(stream.bytes, "[\"hello\",\"world\\n\"]")
        }
        
        do {
            let stream = OutputByteStream()
            stream <<< Format.asJSON(["hello": "world\n"])
            XCTAssertEqual(stream.bytes, "{\"hello\":\"world\\n\"}")
        }

        do {
            struct MyThing {
                let value: String
                init(_ value: String) { self.value = value }
            }
            let stream = OutputByteStream()
            stream <<< Format.asJSON([MyThing("hello"), MyThing("world\n")], transform: { $0.value })
            XCTAssertEqual(stream.bytes, "[\"hello\",\"world\\n\"]")
        }

        do {
            let stream = OutputByteStream()
            stream <<< Format.asSeparatedList(["hello", "world"], separator: ", ")
            XCTAssertEqual(stream.bytes, "hello, world")
        }
        
        do {
            struct MyThing {
                let value: String
                init(_ value: String) { self.value = value }
            }
            let stream = OutputByteStream()
            stream <<< Format.asSeparatedList([MyThing("hello"), MyThing("world")], transform: { $0.value }, separator: ", ")
            XCTAssertEqual(stream.bytes, "hello, world")
        }
    }
}
