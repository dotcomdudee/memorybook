# MemoryBook ✨

A beautiful web interface for browsing, searching, and editing your [OpenClaw](https://github.com/openclaw/openclaw) agent's memory files.

![Memory Book](https://img.shields.io/badge/OpenClaw-MemoryBook-8B5CF6?style=flat-square) ![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square) ![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

![MemoryBook](https://zight.io/s/75977413226884678564763331400625450548827539.png?x=ESCKBFD)

## What is this?

OpenClaw agents store memories as markdown files — daily notes in `memory/YYYY-MM-DD.md` and long-term memory in `MEMORY.md`. MemoryBook gives you a gorgeous dark UI to browse, search, and edit these files.

### Features

- 🔍 **Live Search** — Instant search across all files with highlighted matches
- 📖 **Section View** — Each `##` header rendered as its own glass card
- ✏️ **Live Editing** — Auto-saves as you type (1s debounce)
- 📁 **Sidebar Navigation** — Quick jump between files with file size & line counts
- ⌨️ **Keyboard Shortcuts** — `Ctrl+E` toggle edit, `Ctrl+S` force save, `/` to focus search
- 🎨 **Beautiful UI** — Dark glass aesthetic with Bricolage Grotesque headings

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

MemoryBook auto-detects your OpenClaw workspace at `~/.openclaw/workspace`. Override with environment variables:

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
Description=MemoryBook — OpenClaw memory viewer
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
├── README.md
├── LICENSE
├── static/
│   └── brain.png       # Favicon
└── templates/
    └── view.html       # Combined home + viewer template
```

## How It Works

MemoryBook reads markdown files from your OpenClaw workspace:

| File | Type | Description |
|------|------|-------------|
| `MEMORY.md` | Core | Agent's long-term curated memory |
| `memory/YYYY-MM-DD.md` | Daily | Daily notes and logs |

The homepage shows a sidebar of all files with a central search bar. Click any file to view it — markdown is parsed by `##` headers into visual section cards. The editor writes directly to the files — your agent picks up changes on its next read.

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
