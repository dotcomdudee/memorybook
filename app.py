#!/usr/bin/env python3
"""
Memory Book — A beautiful web interface for OpenClaw memory files.
https://github.com/dotcomdudee/memorybook

Browse, search, and edit your agent's memory markdown files
with a clean dark glass UI.
"""

import os
import re
import sys
from datetime import datetime
from flask import Flask, render_template, request, jsonify, redirect, url_for
from markupsafe import Markup
from pathlib import Path

app = Flask(__name__)

# ─── Configuration ────────────────────────────────────────────
# Auto-detect OpenClaw workspace, or set manually via env var
WORKSPACE = Path(os.environ.get(
    "MEMORYBOOK_WORKSPACE",
    os.path.expanduser("~/.openclaw/workspace")
))

MEMORY_DIR = WORKSPACE / "memory"
PORT = int(os.environ.get("MEMORYBOOK_PORT", 5577))
HOST = os.environ.get("MEMORYBOOK_HOST", "0.0.0.0")

# Core files to include alongside daily memory notes
CORE_FILES = ["MEMORY.md"]


# ─── Markdown Renderer ───────────────────────────────────────
def render_markdown(text):
    """Simple markdown to HTML — handles bold, italic, code, links, lists."""
    text = re.sub(r'```[\s\S]*?```', lambda m: f'<pre><code>{m.group()[3:-3].strip()}</code></pre>', text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)

    lines = text.split('\n')
    html = []
    in_list = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('- '):
            if not in_list:
                html.append('<ul>')
                in_list = True
            html.append(f'<li>{stripped[2:]}</li>')
        else:
            if in_list:
                html.append('</ul>')
                in_list = False
            if stripped:
                html.append(f'<p>{stripped}</p>')
    if in_list:
        html.append('</ul>')

    return Markup('\n'.join(html))

app.jinja_env.filters['render_markdown'] = render_markdown


# ─── Helpers ──────────────────────────────────────────────────
def get_allowed_paths():
    """Return list of allowed file paths for safety."""
    allowed = []
    for name in CORE_FILES:
        f = WORKSPACE / name
        if f.exists():
            allowed.append(str(f))
    if MEMORY_DIR.exists():
        allowed.extend(str(f) for f in MEMORY_DIR.glob("*.md"))
    return allowed


MONTH_NAMES = {
    1: "January", 2: "February", 3: "March", 4: "April",
    5: "May", 6: "June", 7: "July", 8: "August",
    9: "September", 10: "October", 11: "November", 12: "December",
}


def get_all_files():
    """Get all memory files, sorted newest first, with month grouping for daily files."""
    files = []
    now = datetime.now()
    current_year = now.year
    current_month = now.month

    # Daily memory files from memory/ directory
    if MEMORY_DIR.exists():
        for f in sorted(MEMORY_DIR.glob("*.md"), reverse=True):
            stat = f.stat()
            # Parse year-month from filename like 2026-02-24.md
            match = re.match(r'(\d{4})-(\d{2})-(\d{2})', f.stem)
            if match:
                year, month = int(match.group(1)), int(match.group(2))
                month_key = f"{year}-{month:02d}"
                if year == current_year and month == current_month:
                    month_label = MONTH_NAMES[month]
                else:
                    month_label = f"{MONTH_NAMES[month]} {year}"
            else:
                month_key = "other"
                month_label = "Other"

            files.append({
                "path": str(f),
                "name": f.name,
                "display": f.stem,
                "type": "daily",
                "month_key": month_key,
                "month_label": month_label,
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime),
                "lines": len(f.read_text(errors='replace').splitlines()),
            })

    # Core workspace files (e.g. MEMORY.md)
    for name in CORE_FILES:
        f = WORKSPACE / name
        if f.exists():
            stat = f.stat()
            files.append({
                "path": str(f),
                "name": f.name,
                "display": f.stem,
                "type": "core",
                "size": stat.st_size,
                "modified": datetime.fromtimestamp(stat.st_mtime),
                "lines": len(f.read_text(errors='replace').splitlines()),
            })

    return files


def parse_sections(content):
    """Parse markdown into sections by ## headers."""
    sections = []
    current = {"title": "Preamble", "content": "", "line": 1, "end_line": 1}

    for i, line in enumerate(content.splitlines(), 1):
        if line.startswith("## "):
            current["end_line"] = i - 1
            if current["content"].strip():
                sections.append(current)
            current = {"title": line[3:].strip(), "content": "", "line": i, "end_line": i}
        else:
            current["content"] += line + "\n"
            current["end_line"] = i

    if current["content"].strip():
        sections.append(current)

    return sections


def search_files(query):
    """Search across all memory files. Uses word-level AND matching:
    1. Line-level: all query words appear in a single line (ranked first)
    2. Section-level: all query words appear somewhere in the same ## section
    """
    line_results = []
    section_results = []
    words = [w.lower() for w in query.strip().split() if w]
    if not words:
        return []

    for f in get_all_files():
        content = Path(f["path"]).read_text(errors='replace')
        lines = content.splitlines()
        sections = parse_sections(content)

        # Track which sections already matched at line-level
        line_matched_sections = set()

        # 1. Line-level AND matching
        for i, line in enumerate(lines):
            line_lower = line.lower()
            if all(w in line_lower for w in words):
                line_results.append({
                    "file": f["name"],
                    "file_display": f["display"],
                    "path": f["path"],
                    "line": i + 1,
                    "match": line.strip(),
                })
                for s in sections:
                    if s["line"] <= i + 1 <= s["end_line"]:
                        line_matched_sections.add((f["name"], s["line"]))
                        break

        # 2. Section-level AND matching
        for s in sections:
            if (f["name"], s["line"]) in line_matched_sections:
                continue
            section_text = (s["title"] + "\n" + s["content"]).lower()
            if all(w in section_text for w in words):
                best_line = s["line"]
                best_match = s["title"]
                for i in range(s["line"] - 1, min(s["end_line"], len(lines))):
                    if any(w in lines[i].lower() for w in words):
                        best_line = i + 1
                        best_match = lines[i].strip()
                        break
                section_results.append({
                    "file": f["name"],
                    "file_display": f["display"],
                    "path": f["path"],
                    "line": best_line,
                    "match": best_match,
                    "section_title": s["title"],
                })

    return line_results + section_results


# ─── Routes ───────────────────────────────────────────────────
@app.route("/")
def index():
    files = get_all_files()
    return render_template("view.html", files=files, filename=None, display=None, content=None, sections=None)


@app.route("/view/<path:filename>")
def view_file(filename):
    filepath = None
    for f in get_all_files():
        if f["name"] == filename:
            filepath = Path(f["path"])
            break

    if not filepath or not filepath.exists():
        return redirect(url_for("index"))

    content = filepath.read_text(errors='replace')
    sections = parse_sections(content)

    return render_template("view.html",
        filename=filename,
        display=filepath.stem,
        content=content,
        sections=sections,
        files=get_all_files(),
    )


@app.route("/api/save", methods=["POST"])
def save_file():
    data = request.json
    filepath = Path(data.get("path", ""))
    content = data.get("content", "")

    if str(filepath) not in get_allowed_paths():
        return jsonify({"error": "Not allowed"}), 403

    filepath.write_text(content)
    return jsonify({"success": True, "size": len(content)})


@app.route("/api/search")
def api_search():
    query = request.args.get("q", "").strip()
    if not query or len(query) < 2:
        return jsonify({"results": []})

    results = search_files(query)
    return jsonify({"results": results[:50]})


# ─── Entry Point ──────────────────────────────────────────────
if __name__ == "__main__":
    if not WORKSPACE.exists():
        print(f"Error: OpenClaw workspace not found at {WORKSPACE}")
        print("Set MEMORYBOOK_WORKSPACE env var to your workspace path.")
        sys.exit(1)

    print(f"Memory Book ✨")
    print(f"Workspace: {WORKSPACE}")
    print(f"Memory dir: {MEMORY_DIR}")
    print(f"Files found: {len(get_all_files())}")
    print()
    app.run(host=HOST, port=PORT, debug=False)
