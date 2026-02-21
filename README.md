# MemoryBook ✨

A beautiful web interface for browsing, searching, and editing Poetry's memory files.

## Overview

MemoryBook provides a clean, dark glass UI to interact with the markdown files that make up Poetry's memory system — daily notes, long-term memory, and workspace files.

## Architecture

- **Backend:** Python Flask (`app.py`)
- **Frontend:** Vanilla HTML/CSS/JS (single unified template)
- **Fonts:** Bricolage Grotesque (headings), DM Sans (body), Fragment Mono (code) — all from Google Fonts
- **Port:** 10001
- **Service:** `memorybook.service` (systemd)
- **Host:** Poetry (10.10.1.21), LAN only
- **Favicon:** `PoetrySVG.svg` (coral `#fe6f5e`)

## Routes

| Route | Description |
|-------|-------------|
| `/` | Landing page — sidebar with all files, centered "Select a memory to read" prompt, search bar |
| `/view/<filename>` | View a specific file — sidebar, sections as glass cards, inline editor |
| `/api/search?q=` | JSON search API — returns matches with context across all files |
| `/api/save` | POST — save file content (restricted to allowed paths) |

## How It Works

**Single unified template (`view.html`)** handles both states:
- **Landing state** (`/`): No file loaded. Shows sidebar with file list, centered prompt text, search bar. `filename`, `display`, `content`, `sections` are all `None`.
- **Viewing state** (`/view/<filename>`): File loaded. Shows sidebar, section cards with table of contents, inline editor toggle.

The old `index.html` (grid homepage) is still on disk but **unused** — can be safely removed.

**Search** is live/inline — results appear as you type, highlights matches across all memory files. Works in both landing and viewing states. `/` key focuses search from anywhere.

**Editor** — toggle with button or `Ctrl+E`. Auto-saves after 1 second of inactivity via `/api/save`. `Ctrl+S` force-saves.

**Memory paths scanned:**
- Daily notes: `/home/username/.openclaw/workspace/memory/*.md`
- Core memory: `/home/username/.openclaw/workspace/MEMORY.md`
- Configurable via `EXTRA_FILES` list in `app.py`

## File Structure

```
memorybook/
├── app.py              # Flask application (routes, markdown rendering, search, save)
├── README.md           # This file
├── static/
│   ├── PoetrySVG.svg   # Favicon (coral #fe6f5e)
│   ├── brain.png       # Alt favicon (brain emoji)
│   └── favicon.jpg     # Legacy favicon
└── templates/
    ├── view.html       # Unified template (landing + file viewer + search + editor)
    └── index.html      # OLD grid homepage — unused, safe to remove
```

## Installation

### Quick Install

```bash
curl -fsSL https://memorybook.md/install.sh | sudo bash
```

The interactive installer will walk you through each step:

1. **Preflight checks** — verifies Python 3.8+, git, pip3, systemd
2. **Configuration** — prompts for memory directory, port, user, install path
3. **Clone repository** — pulls from GitHub (or updates existing install)
4. **Install dependencies** — creates a venv, installs Flask + markupsafe
5. **Create systemd service** — sets up, enables, and starts the service

### Non-Interactive Install

Skip all prompts with `--non-interactive` (or `-y`):

```bash
curl -fsSL https://memorybook.md/install.sh | sudo bash -s -- \
  --non-interactive \
  --memory-dir /path/to/memory \
  --port 10001 \
  --user username
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `--non-interactive`, `-y` | Yes to all prompts | off |
| `--memory-dir PATH` | Directory containing your `.md` files | auto-detected |
| `--port PORT` | Port to serve on | `10001` |
| `--user USER` | System user to run as | current user |
| `--install-dir PATH` | Where to install MemoryBook | `/opt/memorybook` |

### What Gets Installed

```
/opt/memorybook/          # App files (cloned from GitHub)
/opt/memorybook/venv/     # Python virtual environment
/opt/memorybook/.env      # Configuration (memory dir, port, etc.)
/etc/systemd/system/memorybook.service  # Systemd service
```

### Auto-Detection

The installer automatically detects OpenClaw workspace paths:
- `~/.openclaw/workspace/memory` → memory directory
- `~/.openclaw/workspace` → workspace directory

Works with any directory of `.md` files — OpenClaw is not required.

### Updating

Re-run the installer — it detects the existing installation and pulls the latest:

```bash
curl -fsSL https://memorybook.md/install.sh | sudo bash
```

Or manually:

```bash
cd /opt/memorybook && git pull && sudo systemctl restart memorybook
```

## Running

```bash
# Status / restart / stop / logs
sudo systemctl status memorybook
sudo systemctl restart memorybook
sudo systemctl stop memorybook
journalctl -u memorybook -f
```

⚠️ **Flask caches templates** — restart the service after any HTML/template changes.

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `/` | Focus search bar |
| `Ctrl+E` | Toggle edit mode |
| `Ctrl+S` | Force save |

## Design Notes

- Dark glass aesthetic with cascading animations
- Logo: "MemoryBook" (no space), 22px Bricolage Grotesque, letter-spacing -0.02em
- Logo click unloads current note → returns to landing/search state
- "Select a memory to read" prompt: 18px, hides when typing in search
- Section cards use `##` headers as boundaries

---

Built by Poetry ✨ for Ash.
