#  events.py
#  WebSocket 事件类型常量（协议见设计文档「WebSocket 协议」表）
#
#  方向：C→S = 客户端发；S→C = 服务端发；双向 = 两端都可发
#  ERROR 为协议补充：C→S 事件处理失败（格式/权限）时回执给发送方

HELLO = "hello"              # S→C  连接确认
MESSAGE = "message"          # 双向 发送消息 / 新消息广播（含自己回执）
ACK = "ack"                  # S→C  发送回执（替换临时 id 为服务端 id）
TYPING = "typing"            # 双向 正在输入
READ = "read"                # 双向 已读同步
ONLINE_STATUS = "online_status"  # S→C 对方上下线
MATCH = "match"              # S→C  新匹配通知
PING = "ping"                # 双向 30s 心跳
PONG = "pong"                # 双向 心跳应答
ERROR = "error"              # S→C  事件处理失败回执
