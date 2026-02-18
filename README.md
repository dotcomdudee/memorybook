# Memory Book ✨

A beautiful web interface for browsing, searching, and editing your [OpenClaw](https://github.com/openclaw/openclaw) agent's memory files.

![Memory Book](https://img.shields.io/badge/OpenClaw-Memory%20Book-8B5CF6?style=flat-square) ![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square) ![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

![Memory Book](https://zight.io/s/056809076816481890544550503799168.png?x=2M687EU)

## What is this?

OpenClaw agents store memories as markdown files — daily notes in `memory/YYYY-MM-DD.md` and long-term memory in `MEMORY.md`. Memory Book gives you a gorgeous dark UI to browse, search, and edit these files.

### Features

- 📚 **File Grid** — All memory files as cards, split into Core and Daily
- 🔍 **Live Search** — Instant search across all files with highlighted matches
- 📖 **Section View** — Each `##` header rendered as its own glass card
- ✏️ **Live Editing** — Auto-saves as you type (1s debounce)
- 📁 **Sidebar Navigation** — Quick jump between files
- ⌨️ **Keyboard Shortcuts** — `Ctrl+E` toggle edit, `Ctrl+S` force save
- 🎨 **Beautiful UI** — Dark glass aesthetic with cascading animations

## Quick Start

```bash
# Clone
git clone https://github.com/dotcomdudee/memorybook.git
cd memorybook

# Install dependencies
pip install flask markupsafe

# Run (auto-detects ~/.openclaw/workspace)
python3 app.py
```

Open **http://localhost:5577** and you're in.

## Configuration

Memory Book auto-detects your OpenClaw workspace at `~/.openclaw/workspace`. Override with environment variables:

```bash
# Custom workspace path
MEMORYBOOK_WORKSPACE=/path/to/workspace python3 app.py

# Custom port
MEMORYBOOK_PORT=8080 python3 app.py

# Bind to localhost only (more secure)
MEMORYBOOK_HOST=127.0.0.1 python3 app.py
```

## Run as a Service

For always-on access, create a systemd service:

```bash
sudo tee /etc/systemd/system/memorybook.service > /dev/null << 'EOF'
[Unit]
Description=Memory Book — OpenClaw memory viewer
After=network.target

[Service]
Type=simple
User=YOUR_USER
WorkingDirectory=/path/to/memorybook
ExecStart=/usr/bin/python3 app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now memorybook
```

## File Structure

```
memorybook/
├── app.py              # Flask application
├── README.md           # This file
├── LICENSE             # MIT License
└── templates/
    ├── index.html      # Home — file grid + search
    └── view.html       # Viewer — sections + editor + sidebar
```

## How It Works

Memory Book reads markdown files from your OpenClaw workspace:

| File | Type | Description |
|------|------|-------------|
| `MEMORY.md` | Core | Agent's long-term curated memory |
| `memory/YYYY-MM-DD.md` | Daily | Daily notes and logs |

Files are parsed by `##` headers into visual sections. The editor writes directly to the files — your agent picks up changes on its next read.

## Security

- **LAN only by default** — binds to `0.0.0.0` but intended for local network use
- **No authentication** — add a reverse proxy with auth if exposing beyond LAN
- **Write safety** — only allows editing files in the memory directory and `MEMORY.md`
- **No external dependencies** beyond Flask

## Requirements

- Python 3.8+
- Flask
- MarkupSafe
- An [OpenClaw](https://github.com/openclaw/openclaw) workspace with memory files

## License

MIT — do whatever you want with it.

---

Built with ✨ for OpenClaw users.
