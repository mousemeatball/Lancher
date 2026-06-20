import Foundation

/// A minimal HTTP/1.1 request, parsed just enough for the loopback Debug Bridge. Not a general
/// HTTP implementation — it handles the method, target (path + query), headers, and body.
struct HTTPRequest {
    let method: String
    let path: String
    let query: [String: String]
    let headers: [String: String]
    let body: Data

    var contentLength: Int { Int(headers["content-length"] ?? "") ?? 0 }

    /// Parse a (possibly partial) buffer. Returns `nil` until the header block is complete; callers
    /// check `body.count >= contentLength` to know the whole request has arrived.
    static func parse(_ data: Data) -> HTTPRequest? {
        let separator = Data("\r\n\r\n".utf8)
        guard let headerEnd = data.range(of: separator) else { return nil }
        let headerData = data.subdata(in: data.startIndex..<headerEnd.lowerBound)
        guard let headerText = String(data: headerData, encoding: .utf8) else { return nil }

        var lines = headerText.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0])
        let (path, query) = splitTarget(String(parts[1]))
        lines.removeFirst()

        var headers: [String: String] = [:]
        for line in lines where !line.isEmpty {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            headers[key] = value
        }

        let body = data.subdata(in: headerEnd.upperBound..<data.endIndex)
        return HTTPRequest(method: method, path: path, query: query, headers: headers, body: body)
    }

    private static func splitTarget(_ target: String) -> (path: String, query: [String: String]) {
        guard let mark = target.firstIndex(of: "?") else { return (target, [:]) }
        let path = String(target[..<mark])
        let queryString = String(target[target.index(after: mark)...])
        var query: [String: String] = [:]
        for pair in queryString.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            let key = kv[0].removingPercentEncoding ?? String(kv[0])
            let value = kv.count > 1 ? (kv[1].removingPercentEncoding ?? String(kv[1])) : ""
            query[key] = value
        }
        return (path, query)
    }
}

/// A minimal HTTP/1.1 response serializer.
struct HTTPResponse {
    let status: Int
    let contentType: String
    let body: Data

    var data: Data {
        var head = "HTTP/1.1 \(status) \(Self.reason(status))\r\n"
        head += "Content-Type: \(contentType)\r\n"
        head += "Content-Length: \(body.count)\r\n"
        head += "Connection: close\r\n\r\n"
        var out = Data(head.utf8)
        out.append(body)
        return out
    }

    static func json(_ status: Int, _ body: Data) -> HTTPResponse {
        HTTPResponse(status: status, contentType: "application/json", body: body)
    }

    static func text(_ status: Int, _ message: String) -> HTTPResponse {
        HTTPResponse(status: status, contentType: "text/plain; charset=utf-8", body: Data(message.utf8))
    }

    private static func reason(_ status: Int) -> String {
        switch status {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 404: return "Not Found"
        default: return "Error"
        }
    }
}
