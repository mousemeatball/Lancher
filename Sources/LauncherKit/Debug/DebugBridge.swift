#if canImport(Network)
import Foundation
import Network

/// A tiny HTTP control server bound to **127.0.0.1 only**, enabled solely when the app is launched
/// with `--debug` or `LANCHER_DEBUG=1`. It lets you (and tooling) drive and inspect the launcher:
///
///   GET  /state        → JSON snapshot
///   POST /command      → { "cmd": "summon" | "dismiss" | "toggle" | "search" | "launch", ... }
///   GET  /screenshot   → PNG of the current launcher window
///
/// Every request must carry the access token (header `x-lancher-token` or `?token=`). The port +
/// token are written to ~/Library/Application Support/Lancher/debug-bridge.json and logged on start.
///
/// The host wiring is provided as `@MainActor @Sendable` closures so this class stays free of any
/// actor isolation while still touching UI state safely on the main actor.
public final class DebugBridge: Sendable {
    /// Whether the bridge should run for this launch.
    public static func isEnabled() -> Bool {
        CommandLine.arguments.contains("--debug")
            || ProcessInfo.processInfo.environment["LANCHER_DEBUG"] == "1"
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "\(Config.loggingSubsystem).debug-bridge")
    private let token: String
    private let stateProvider: @MainActor @Sendable () -> DebugState
    private let commandHandler: @MainActor @Sendable (DebugCommand) -> DebugResult
    private let screenshotProvider: @MainActor @Sendable () -> Data?

    public init?(
        port: UInt16 = Config.debugBridgePort,
        stateProvider: @escaping @MainActor @Sendable () -> DebugState,
        commandHandler: @escaping @MainActor @Sendable (DebugCommand) -> DebugResult,
        screenshotProvider: @escaping @MainActor @Sendable () -> Data?
    ) {
        self.stateProvider = stateProvider
        self.commandHandler = commandHandler
        self.screenshotProvider = screenshotProvider
        self.token = Self.makeToken()

        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback        // never leaves this machine
        parameters.allowLocalEndpointReuse = true
        guard let nwPort = NWEndpoint.Port(rawValue: port),
              let listener = try? NWListener(using: parameters, on: nwPort)
        else { return nil }
        self.listener = listener

        start(port: port)
    }

    private func start(port: UInt16) {
        listener.newConnectionHandler = { [self] connection in
            connection.start(queue: queue)
            receive(connection, buffer: Data())
        }
        listener.stateUpdateHandler = { [self] state in
            if case .ready = state { announce(port: port) }
        }
        listener.start(queue: queue)
    }

    // MARK: - Connection handling

    private func receive(_ connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [self] data, _, isComplete, error in
            var accumulated = buffer
            if let data { accumulated.append(data) }

            if let request = HTTPRequest.parse(accumulated), request.body.count >= request.contentLength {
                respond(to: request, on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                receive(connection, buffer: accumulated)
            }
        }
    }

    private func respond(to request: HTTPRequest, on connection: NWConnection) {
        guard authorized(request) else {
            send(.text(401, "unauthorized — provide the token"), on: connection)
            return
        }

        switch (request.method, request.path) {
        case ("GET", "/state"):
            Task { @MainActor in
                let body = (try? JSONEncoder().encode(stateProvider())) ?? Data("{}".utf8)
                send(.json(200, body), on: connection)
            }

        case ("POST", "/command"):
            guard let command = try? JSONDecoder().decode(DebugCommand.self, from: request.body) else {
                send(.text(400, "invalid command JSON"), on: connection)
                return
            }
            Task { @MainActor in
                let result = commandHandler(command)
                let body = (try? JSONEncoder().encode(result)) ?? Data()
                send(.json(result.ok ? 200 : 400, body), on: connection)
            }

        case ("GET", "/screenshot"):
            Task { @MainActor in
                if let png = screenshotProvider() {
                    send(HTTPResponse(status: 200, contentType: "image/png", body: png), on: connection)
                } else {
                    send(.text(404, "no window to capture"), on: connection)
                }
            }

        default:
            send(.text(404, "not found"), on: connection)
        }
    }

    private func send(_ response: HTTPResponse, on connection: NWConnection) {
        connection.send(content: response.data, completion: .contentProcessed { _ in connection.cancel() })
    }

    private func authorized(_ request: HTTPRequest) -> Bool {
        let provided = request.headers[Config.debugTokenHeader] ?? request.query["token"]
        return provided == token
    }

    // MARK: - Announce

    private func announce(port: UInt16) {
        let base = "http://127.0.0.1:\(port)"
        writeInfoFile(port: port)
        Log.event(Log.bridge, "Debug Bridge ready at \(base) (token \(token))")
        // Also print to stdout so `./scripts/run.sh --debug` shows it inline.
        print("""
        ── Lancher Debug Bridge ──────────────────────────────────────────────
          base:  \(base)
          token: \(token)
          curl -s \(base)/state -H '\(Config.debugTokenHeader): \(token)'
          curl -s -XPOST \(base)/command -H '\(Config.debugTokenHeader): \(token)' -d '{"cmd":"summon"}'
        ──────────────────────────────────────────────────────────────────────
        """)
    }

    private func writeInfoFile(port: UInt16) {
        guard let dir = try? Config.appSupportDirectory() else { return }
        let info = ["base": "http://127.0.0.1:\(port)", "port": "\(port)", "token": token]
        guard let data = try? JSONSerialization.data(withJSONObject: info, options: [.prettyPrinted]) else { return }
        try? data.write(to: dir.appending(path: Config.debugBridgeInfoFileName))
    }

    private static func makeToken() -> String {
        UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
}
#endif
