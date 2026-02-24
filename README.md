# MemoryBook ✨

A beautiful web interface for browsing, searching, and editing your [OpenClaw](https://github.com/openclaw/openclaw) agent's memory files.

![Memory Book](https://img.shields.io/badge/OpenClaw-MemoryBook-8B5CF6?style=flat-square) ![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=flat-square) ![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

![MemoryBook](https://zight.io/s/75977413226884678564763331400625450548827539.png?x=ESCKBFD)

## What is this?

OpenClaw agents store memories as markdown files — daily notes in `memory/YYYY-MM-DD.md` and long-term memory in `MEMORY.md`. MemoryBook gives you a gorgeous dark UI to browse, search, and edit these files.

### Features

- 🔍 **Smart Search** — Word-level AND matching across all files. Line-level matches ranked first, section-level matches catch words spread across nearby lines. Each word highlighted individually.
- 📍 **Jump to Result** — Click a search result to navigate directly to the matching section with a highlighted glow that fades after 3 seconds.
- 📁 **Monthly Sidebar** — Daily files grouped by month (current month expanded, older months collapsed). Core files in their own collapsible section. State persisted to localStorage.
- 📖 **Section View** — Each `##` header rendered as its own card with table of contents
- ✏️ **Live Editing** — Auto-saves as you type (1s debounce)
- ⌨️ **Keyboard Shortcuts** — `Ctrl+E` toggle edit, `Ctrl+S` force save, `/` to focus search
- 🎨 **Beautiful UI** — Dark glass aesthetic with Bricolage Grotesque headings

## Install

One command:

```bash
curl -fsSL https://memorybook.md/install.sh | sudo bash
```

The interactive installer walks you through everything — clones the repo, installs dependencies in a venv, creates a systemd service, and starts it up.

### Non-Interactive

```bash
curl -fsSL https://memorybook.md/install.sh | sudo bash -s -- \
  --non-interactive \
  --memory-dir /path/to/memory \
  --port 10001
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--non-interactive`, `-y` | Skip all prompts | off |
| `--memory-dir PATH` | Directory containing your `.md` files | auto-detected |
| `--port PORT` | Port to serve on | `10001` |
| `--user USER` | System user to run as | current user |
| `--install-dir PATH` | Where to install | `/opt/memorybook` |

### Manual Install

```bash
git clone https://github.com/dotcomdudee/memorybook.git
cd memorybook
pip install flask markupsafe
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

## File Structure

```
memorybook/
├── app.py              # Flask application
├── README.md
├── LICENSE
├── static/
│   └── favicon.svg       # Favicon
└── templates/
    └── view.html       # Combined home + viewer template
```

## How It Works

MemoryBook reads markdown files from your OpenClaw workspace:

| File | Type | Description |
|------|------|-------------|
| `MEMORY.md` | Core | Agent's long-term curated memory |
| `memory/YYYY-MM-DD.md` | Daily | Daily notes and logs |

### Sidebar

Files are organized into collapsible sections with SVG chevrons:
- **Core** — Long-term memory files (MEMORY.md and any extras configured in `CORE_FILES`)
- **Monthly groups** — Daily files grouped by month. Current month shows just the name (e.g. "February"), older months include the year (e.g. "January 2026"). Collapse state persists to localStorage.

### Search

Uses **word-level AND matching** with two tiers:
1. **Line-level** (ranked first) — all query words appear in a single line
2. **Section-level** — all query words appear somewhere within the same `##` section

This means searching "server install" will find sections where both words appear, even if they're on different lines. Section-level matches display a `§ Section Title` tag for context.

Click any result to jump directly to the matching section — it scrolls into view with an accent highlight that fades after 3 seconds.

### Editor

Click any file to view it — markdown is parsed by `##` headers into visual section cards. Toggle the editor with the Edit button or `Ctrl+E`. Auto-saves after 1 second of inactivity. Your agent picks up changes on its next read.

## Security

- **LAN only by default** — binds to `0.0.0.0` but intended for local network use
- **No authentication** — add a reverse proxy with auth if exposing beyond LAN
- **Write safety** — only allows editing files in the memory directory and configured core files
- **No external dependencies** beyond Flask

## Requirements

- Python 3.8+
- Flask
- MarkupSafe
- An [OpenClaw](https://github.com/openclaw/openclaw) workspace with memory files

## License

MIT — do whatever you want with it.

## Changelog

**v1.1** — 2026-02-24
- Sidebar grouped by month (collapsible with persistent state)
- Smart search: word-level AND matching with line + section tiers
- Click search results to jump directly to matching section with highlight
- Per-word highlighting in search results

**v1.0** — 2026-02-18
- Initial release
- Dark glass UI with section cards, live search, inline editor
- Keyboard shortcuts, mobile responsive, auto-save

---

Built with ✨ for OpenClaw users.
