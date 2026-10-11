//
//  WebSocketClient.swift
//  BanBan · WebSocket 客户端
//
//  URLSessionWebSocketTask 封装：
//  - receive 循环解析事件（JSONSerialization，事件字段动态）→ MainActor 回调
//  - 30s sendPing 心跳；失败视为断开
//  - 指数退避自动重连（1s 起，封顶 30s；显式 disconnect() 不重连）
//  - JWT sub 解析（不验签：token 来自 Keychain 本地信任链，仅用于身份识别）
//

import Foundation

/// 服务端下发的 WebSocket 事件（type + 动态载荷）
struct WSEvent {
    let type: String
    let payload: [String: Any]
}

@MainActor
final class WebSocketClient: NSObject, ObservableObject {
    typealias EventHandler = (WSEvent) -> Void

    /// 连接状态（视图层可订阅展示）
    enum ConnectionState: Equatable {
        case idle
        case connecting
        case connected
        case disconnected
    }

    @Published private(set) var state: ConnectionState = .idle {
        didSet {
            if state != oldValue {
                onStateChange?(state)
            }
        }
    }

    var onEvent: EventHandler?
    var onStateChange: ((ConnectionState) -> Void)?

    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private var url: URL?
    private var reconnectAttempt = 0
    private var heartbeatTask: Task<Void, Never>?
    /// 显式断开（登出）后不再自动重连
    private var shouldReconnect = false

    /// 心跳间隔（服务端 presence TTL 60s，间隔必须显著小于它）
    private static let heartbeatInterval: TimeInterval = 30
    private static let maxReconnectDelay: TimeInterval = 30

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - 连接管理

    func connect(url: URL) {
        disconnectTask()
        self.url = url
        shouldReconnect = true
        state = .connecting
        openTask(url: url)
    }

    /// 显式断开：不再重连（登出时调用）
    func disconnect() {
        shouldReconnect = false
        url = nil
        disconnectTask()
        state = .idle
    }

    /// 收到服务端 hello 后由调用方确认连接就绪
    func markConnected() {
        reconnectAttempt = 0
        state = .connected
    }

    private func openTask(url: URL) {
        let task = session.webSocketTask(with: url)
        self.task = task
        task.resume()
        startHeartbeat()
        receiveLoop(task)
    }

    /// 关闭当前连接（重连时复用）：心跳停止，receive 循环随任务取消而结束
    private func disconnectTask() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    // MARK: - 接收循环

    private func receiveLoop(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                Task { @MainActor in
                    // 已被新连接替换的旧任务忽略
                    guard self.task === task else { return }
                    if let event = self.parse(message) {
                        self.onEvent?(event)
                    }
                    self.receiveLoop(task)
                }
            case .failure:
                Task { @MainActor in
                    guard self.task === task else { return }
                    self.scheduleReconnect()
                }
            }
        }
    }

    private func parse(_ message: URLSessionWebSocketTask.Message) -> WSEvent? {
        let data: Data?
        switch message {
        case .string(let text): data = text.data(using: .utf8)
        case .data(let raw): data = raw
        @unknown default: data = nil
        }
        guard let data,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = object["type"] as? String
        else { return nil }
        return WSEvent(type: type, payload: object)
    }

    // MARK: - 心跳与重连

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.heartbeatInterval))
                guard !Task.isCancelled else { return }
                self?.task?.sendPing { error in
                    Task { @MainActor in
                        guard let self, self.heartbeatTask?.isCancelled == false else { return }
                        if error != nil {
                            self.scheduleReconnect()
                        }
                    }
                }
            }
        }
    }

    private func scheduleReconnect() {
        guard shouldReconnect, let url else {
            state = .disconnected
            return
        }
        disconnectTask()
        state = .disconnected
        reconnectAttempt += 1
        let delay = min(pow(2.0, Double(reconnectAttempt - 1)), Self.maxReconnectDelay)
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.shouldReconnect else { return }
            self.state = .connecting
            self.openTask(url: url)
        }
    }

    // MARK: - 发送

    /// 发送 C→S 事件；返回 false 表示未连接（调用方走 HTTP 兜底）
    @discardableResult
    func send(_ payload: [String: Any]) -> Bool {
        guard let task else { return false }
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8)
        else { return false }
        // 回调内取错误仅记日志；发送失败交给心跳/下次 receive 兜底重连
        task.send(.string(text)) { _ in }
        return true
    }
}

// MARK: - JWT 辅助

enum JWT {
    /// 解析 access token payload 的 sub（user id）。
    /// 不验签：token 存于 Keychain 本地信任链，此处仅做身份识别
    static func sub(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }
        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return object["sub"] as? String
    }
}
