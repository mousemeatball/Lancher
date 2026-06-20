import Testing
import Foundation
@testable import LauncherKit

@Suite struct HTTPMessageTests {
    @Test func parsesGetWithQueryAndHeaders() {
        let raw = Data("GET /state?token=abc123 HTTP/1.1\r\nHost: 127.0.0.1\r\nX-Lancher-Token: abc123\r\n\r\n".utf8)
        let request = HTTPRequest.parse(raw)
        #expect(request?.method == "GET")
        #expect(request?.path == "/state")
        #expect(request?.query["token"] == "abc123")
        #expect(request?.headers["x-lancher-token"] == "abc123")
        #expect(request?.contentLength == 0)
    }

    @Test func parsesPostBodyAndContentLength() {
        let body = #"{"cmd":"search","q":"safari"}"#
        let raw = Data("POST /command HTTP/1.1\r\nContent-Length: \(body.utf8.count)\r\n\r\n\(body)".utf8)
        let request = HTTPRequest.parse(raw)
        #expect(request?.method == "POST")
        #expect(request?.path == "/command")
        #expect(request?.contentLength == body.utf8.count)
        #expect(request.map { $0.body.count >= $0.contentLength } == true)

        let decoded = request.flatMap { try? JSONDecoder().decode(DebugCommand.self, from: $0.body) }
        #expect(decoded?.cmd == "search")
        #expect(decoded?.q == "safari")
    }

    @Test func returnsNilUntilHeaderBlockComplete() {
        let partial = Data("GET /state HTTP/1.1\r\nHost: x".utf8) // no terminating CRLFCRLF yet
        #expect(HTTPRequest.parse(partial) == nil)
    }

    @Test func responseSerializesStatusLineAndHeaders() {
        let response = HTTPResponse.json(200, Data(#"{"ok":true}"#.utf8))
        let text = String(data: response.data, encoding: .utf8) ?? ""
        #expect(text.hasPrefix("HTTP/1.1 200 OK\r\n"))
        #expect(text.contains("Content-Type: application/json\r\n"))
        #expect(text.contains("Content-Length: 11\r\n"))
        #expect(text.hasSuffix("{\"ok\":true}"))
    }
}
