# Antigravity Telegram Suite

通过 Telegram 远程控制 Antigravity AI Agent。支持 Windows、macOS 和 Linux 下的 Antigravity Standalone App 与 Antigravity IDE。

---

## 功能特性

| 功能 | 说明 |
|---|---|
| 远程对话 | 在 Telegram 中直接向 Agent 发送 Prompt 并接收流式回复 |
| 文件与图片上传 | 支持向 Agent 转发本地文件与图片 |
| 屏幕截图 | 远程截取正在运行的 Antigravity 界面画面 |
| 模型切换 | 快捷切换模型及思考深度（Thinking Effort） |
| 工作区与窗口路由 | 远程切换项目工作区及多窗口定向路由 |
| 历史会话管理 | 浏览、搜索并精准切换历史会话线程（`/agents`） |
| 自动确认 | 自动点击授权执行提示（Run、Accept、Allow、Continue） |
| 任务监控 | 实时监听后台子 Agent 与定时任务的消息推送 |
| 双应用支持 | 支持在 Standalone App 与 IDE 之间平滑切换 |

---

## 快速上手

### 环境要求

- Node.js >= 18
- 已安装 Antigravity Standalone App 或 Antigravity IDE
- Telegram Bot Token（可从 [@BotFather](https://t.me/BotFather) 获取）

### 1. 安装

```bash
git clone https://github.com/Entermage/antigravity-telegram-suite.git
cd antigravity-telegram-suite
npm install
```

### 2. 配置

复制配置文件：

```bash
cp .env.example .env
```

配置 `.env` 参数：

```ini
# Telegram 配置
BOT_TOKEN=your_telegram_bot_token
ALLOWED_CHAT_ID=your_telegram_chat_id

# 调试端口（需与启动参数 --remote-debugging-port 一致）
AGENT_CDP_PORT=9333    # Standalone Antigravity App
IDE_CDP_PORT=9334      # Antigravity IDE

# 默认设置
LANGUAGE=zh
DEFAULT_MODEL=Gemini 3.5 Flash (Medium)
ANTIGRAVITY_PREFERRED_APP=agent
AUTOACCEPT_DEFAULT=false
```

### 3. 启动 Antigravity 调试端口

启动时附加远程调试端口参数（仅监听本地回环）：

```bash
# Standalone App（端口 9333）
Antigravity.exe --remote-debugging-port=9333 --remote-debugging-address=127.0.0.1

# IDE（端口 9334）
"Antigravity IDE.exe" --remote-debugging-port=9334 --remote-debugging-address=127.0.0.1
```

### 4. 启动 Bot

使用守护进程后台静默运行（崩溃自动重启与心跳监控）：

```bash
npm run watchdog
```

或直接前台启动：

```bash
npm start
```

---

## 常用命令

### 基础控制

| 命令 | 说明 |
|---|---|
| `<文字内容>` | 直接发送 Prompt 给当前 Agent |
| `/status` | 查询系统、应用与 CDP 实时连接状态 |
| `/new` | 新建对话会话 |
| `/latest` | 获取 Agent 最新一轮的完整回复内容 |
| `/screenshot` | 截取当前界面并发送到手机端 |
| `/stop` | 中断当前正在执行的任务 |

### 线程与 Agent 管理

| 命令 | 说明 |
|---|---|
| `/agents` | 交互式历史对话管理器（浏览、搜索与切换） |
| `/workspace` | 查看与切换项目工作区 |
| `/app` | 在 Standalone App 与 IDE 之间切换控制焦点 |
| `/model` | 切换 AI 模型及思考深度 |
| `/quota` | 查询各模型额度与配额使用情况 |
| `/autoaccept` | 切换自动确认模式（on / off / status） |
| `/artifacts` | 查看并调阅生成的成果物（计划、任务卡、总结报告） |

---

## 架构与原理

```
Telegram 客户端 <---> Telegram Bot (Node.js) <--- CDP (WebSocket) ---> Antigravity 本机客户端
```

1. Telegram 消息通过 Chrome DevTools Protocol (CDP) 发送至本地 Antigravity。
2. Bot 监听 DOM 变化与日志流状态，判断 Agent 思考与执行进度。
3. 执行完成后，提取最终回复与生成的文件并回传至 Telegram。

---

## 开源协议

本项目采用 MIT 许可证，详见 [LICENSE](LICENSE) 文件。
