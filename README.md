# Antigravity Telegram Suite

Control Antigravity AI agent remotely via Telegram. Supports both Antigravity Standalone App and Antigravity IDE on Windows, macOS, and Linux.

---

## Features

| Feature | Description |
|---|---|
| Remote Chat | Send prompts and receive agent responses directly in Telegram |
| File & Image Upload | Forward local files and images directly to the agent |
| Screenshots | Capture remote IDE and Standalone agent screen |
| Model Selection | Switch models and thinking effort tiers |
| Workspace & Window Routing | Manage workspaces and switch active windows remotely |
| Interactive Thread Manager | List, search, and switch historical conversation threads (`/agents`) |
| Auto-Accept | Automatically accept execution prompts (Run, Accept, Allow, Continue) |
| Task Watcher | Proactive notification forwarding for background tasks |
| Dual App Support | Seamless switching between Antigravity Standalone App and IDE |

---

## Quick Start

### Prerequisites

- Node.js >= 18
- Antigravity Standalone App or Antigravity IDE
- Telegram Bot Token (from [@BotFather](https://t.me/BotFather))

### 1. Installation

```bash
git clone https://github.com/Entermage/antigravity-telegram-suite.git
cd antigravity-telegram-suite
npm install
```

### 2. Configuration

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Configure your `.env`:

```ini
# Telegram Configuration
BOT_TOKEN=your_telegram_bot_token
ALLOWED_CHAT_ID=your_telegram_chat_id

# Debugging Ports (must match --remote-debugging-port launch arg)
AGENT_CDP_PORT=9333    # Standalone Antigravity App
IDE_CDP_PORT=9334      # Antigravity IDE

# Defaults
LANGUAGE=en
DEFAULT_MODEL=Gemini 3.5 Flash (Medium)
ANTIGRAVITY_PREFERRED_APP=agent
AUTOACCEPT_DEFAULT=false
```

### 3. Launch Antigravity with CDP

Launch Antigravity with debugging enabled:

```bash
# Standalone App (Port 9333)
Antigravity.exe --remote-debugging-port=9333 --remote-debugging-address=127.0.0.1

# IDE (Port 9334)
"Antigravity IDE.exe" --remote-debugging-port=9334 --remote-debugging-address=127.0.0.1
```

### 4. Start the Bot

Run in background with automatic watchdog restart:

```bash
npm run watchdog
```

Or start directly:

```bash
npm start
```

---

## Commands

### Core Commands

| Command | Description |
|---|---|
| `<text>` | Send message directly to the active AI agent |
| `/status` | Check system status (App, CDP connection, Bot) |
| `/new` | Start a new chat session |
| `/latest` | Get the latest agent response text |
| `/screenshot` | Capture screenshot of the active agent window |
| `/stop` | Stop the currently executing task |

### Agent & Thread Management

| Command | Description |
|---|---|
| `/agents` | Interactive conversation thread browser and switcher |
| `/workspace` | View and switch project workspace |
| `/app` | Switch active app target between Standalone App and IDE |
| `/model` | Switch active AI model and thinking effort |
| `/quota` | Check AI model usage and credits |
| `/autoaccept` | Toggle auto-accept mode (on / off / status) |
| `/artifacts` | List and download generated artifacts (plans, tasks, walkthroughs) |

---

## Architecture

```
Telegram Client <---> Telegram Bot (Node.js) <--- CDP (WebSocket) ---> Antigravity App
```

1. Messages sent via Telegram are forwarded to Antigravity through Chrome DevTools Protocol (CDP).
2. The bot monitors agent execution state via DOM events and log streams.
3. Once the agent finishes processing, outputs and artifacts are formatted and sent back to Telegram.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
