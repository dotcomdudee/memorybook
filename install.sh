#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────
# MemoryBook Installer
# https://memorybook.md
# ─────────────────────────────────────────────────

VERSION="1.0.0"
REPO="https://github.com/dotcomdudee/memorybook.git"
INSTALL_DIR="/opt/memorybook"
SERVICE_NAME="memorybook"
DEFAULT_PORT=10001
INTERACTIVE=true

# ─── Colors & Formatting ─────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Parse Args ──────────────────────────────────
MEMORY_DIR=""
MB_PORT="$DEFAULT_PORT"
MB_USER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --non-interactive|-y) INTERACTIVE=false; shift ;;
    --memory-dir) MEMORY_DIR="$2"; shift 2 ;;
    --port) MB_PORT="$2"; shift 2 ;;
    --user) MB_USER="$2"; shift 2 ;;
    --install-dir) INSTALL_DIR="$2"; shift 2 ;;
    --help|-h)
      echo "MemoryBook Installer v${VERSION}"
      echo ""
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --non-interactive, -y   Skip all prompts (yes to all)"
      echo "  --memory-dir PATH       Path to memory directory (contains .md files)"
      echo "  --port PORT             Port to run on (default: $DEFAULT_PORT)"
      echo "  --user USER             System user to run as (default: current user)"
      echo "  --install-dir PATH      Installation directory (default: $INSTALL_DIR)"
      echo "  --help, -h              Show this help"
      exit 0
      ;;
    *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
  esac
done

# ─── Helpers ─────────────────────────────────────

print_header() {
  clear
  echo ""
  echo -e "${BOLD}  ┌─────────────────────────────────────┐${NC}"
  echo -e "${BOLD}  │         ${CYAN}📖 MemoryBook${NC}${BOLD}               │${NC}"
  echo -e "${BOLD}  │         ${DIM}v${VERSION}${NC}${BOLD}                      │${NC}"
  echo -e "${BOLD}  └─────────────────────────────────────┘${NC}"
  echo ""
}

step() {
  echo ""
  echo -e "  ${BLUE}→${NC} ${BOLD}$1${NC}"
}

info() {
  echo -e "    ${DIM}$1${NC}"
}

success() {
  echo -e "    ${GREEN}✓${NC} $1"
}

warn() {
  echo -e "    ${YELLOW}⚠${NC} $1"
}

fail() {
  echo -e "    ${RED}✗${NC} $1"
  exit 1
}

confirm() {
  if [ "$INTERACTIVE" = false ]; then
    return 0
  fi
  local prompt="$1"
  echo ""
  echo -ne "  ${YELLOW}?${NC} ${prompt} ${DIM}[Y/n]${NC} "
  read -r response
  case "$response" in
    [nN][oO]|[nN]) return 1 ;;
    *) return 0 ;;
  esac
}

prompt_value() {
  local prompt="$1"
  local default="$2"
  local varname="$3"
  if [ "$INTERACTIVE" = false ]; then
    eval "$varname=\"$default\""
    return
  fi
  echo -ne "  ${YELLOW}?${NC} ${prompt} ${DIM}[${default}]${NC} "
  read -r response
  if [ -z "$response" ]; then
    eval "$varname=\"$default\""
  else
    eval "$varname=\"$response\""
  fi
}

# ─── Preflight ───────────────────────────────────

print_header

step "Checking prerequisites"

# Must be root or sudo
if [ "$EUID" -ne 0 ]; then
  fail "Please run as root or with sudo"
fi

# Check for required tools
for cmd in git python3 pip3; do
  if command -v "$cmd" &>/dev/null; then
    success "$cmd found"
  else
    fail "$cmd is required but not installed. Install it and try again."
  fi
done

# Check python version
PYVER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PYMAJOR=$(echo "$PYVER" | cut -d. -f1)
PYMINOR=$(echo "$PYVER" | cut -d. -f2)
if [ "$PYMAJOR" -ge 3 ] && [ "$PYMINOR" -ge 8 ]; then
  success "Python $PYVER"
else
  fail "Python 3.8+ required (found $PYVER)"
fi

# Check if systemd is available
if command -v systemctl &>/dev/null; then
  HAS_SYSTEMD=true
  success "systemd available"
else
  HAS_SYSTEMD=false
  warn "systemd not found — will skip service creation"
fi

# ─── Configuration ───────────────────────────────

step "Configuration"

# Detect user
if [ -z "$MB_USER" ]; then
  # Try to figure out the real user (not root)
  if [ -n "${SUDO_USER:-}" ]; then
    MB_USER="$SUDO_USER"
  else
    MB_USER="$(whoami)"
  fi
fi
prompt_value "Run as user" "$MB_USER" MB_USER
info "Service will run as: $MB_USER"

# Get home dir for that user
MB_HOME=$(eval echo "~$MB_USER")

# Memory directory
if [ -z "$MEMORY_DIR" ]; then
  # Try common locations
  if [ -d "$MB_HOME/.openclaw/workspace/memory" ]; then
    MEMORY_DIR="$MB_HOME/.openclaw/workspace/memory"
  elif [ -d "$MB_HOME/memory" ]; then
    MEMORY_DIR="$MB_HOME/memory"
  else
    MEMORY_DIR="$MB_HOME/memory"
  fi
fi
prompt_value "Memory directory (where your .md files live)" "$MEMORY_DIR" MEMORY_DIR

# Workspace (parent of memory dir, or same)
WORKSPACE_DIR="$(dirname "$MEMORY_DIR")"
prompt_value "Workspace directory (parent dir with MEMORY.md etc.)" "$WORKSPACE_DIR" WORKSPACE_DIR

# Port
prompt_value "Port" "$MB_PORT" MB_PORT

# Install dir
prompt_value "Install directory" "$INSTALL_DIR" INSTALL_DIR

echo ""
echo -e "  ${DIM}────────────────────────────────────────${NC}"
echo -e "    User:        ${BOLD}$MB_USER${NC}"
echo -e "    Memory dir:  ${BOLD}$MEMORY_DIR${NC}"
echo -e "    Workspace:   ${BOLD}$WORKSPACE_DIR${NC}"
echo -e "    Port:        ${BOLD}$MB_PORT${NC}"
echo -e "    Install dir: ${BOLD}$INSTALL_DIR${NC}"
echo -e "  ${DIM}────────────────────────────────────────${NC}"

# ─── Clone Repository ────────────────────────────

if confirm "Clone MemoryBook repository?"; then
  step "Cloning repository"

  if [ -d "$INSTALL_DIR/.git" ]; then
    info "Existing installation found, pulling latest..."
    cd "$INSTALL_DIR"
    git pull --quiet
    success "Updated to latest"
  else
    if [ -d "$INSTALL_DIR" ]; then
      warn "Directory exists but isn't a git repo — backing up"
      mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
    fi
    git clone --quiet "$REPO" "$INSTALL_DIR"
    success "Cloned to $INSTALL_DIR"
  fi
else
  if [ ! -d "$INSTALL_DIR" ]; then
    fail "Install directory doesn't exist and clone was skipped"
  fi
fi

# ─── Install Dependencies ────────────────────────

if confirm "Install Python dependencies?"; then
  step "Installing dependencies"

  # Create venv
  if [ ! -d "$INSTALL_DIR/venv" ]; then
    python3 -m venv "$INSTALL_DIR/venv"
    success "Virtual environment created"
  else
    success "Virtual environment exists"
  fi

  # Install deps
  if [ -f "$INSTALL_DIR/requirements.txt" ]; then
    "$INSTALL_DIR/venv/bin/pip" install -q -r "$INSTALL_DIR/requirements.txt"
    success "Requirements installed from requirements.txt"
  else
    "$INSTALL_DIR/venv/bin/pip" install -q flask markupsafe
    success "Installed flask, markupsafe"
  fi
else
  warn "Skipping dependency installation"
fi

# ─── Configure Paths ─────────────────────────────

step "Configuring paths"

# Write an env file for the service
cat > "$INSTALL_DIR/.env" <<ENVEOF
MEMORY_DIR=$MEMORY_DIR
WORKSPACE_DIR=$WORKSPACE_DIR
MB_PORT=$MB_PORT
ENVEOF
success "Environment config written to $INSTALL_DIR/.env"

# Create memory directory if it doesn't exist
if [ ! -d "$MEMORY_DIR" ]; then
  mkdir -p "$MEMORY_DIR"
  chown "$MB_USER:$MB_USER" "$MEMORY_DIR"
  success "Created memory directory: $MEMORY_DIR"
else
  success "Memory directory exists: $MEMORY_DIR"
fi

# Set ownership
chown -R "$MB_USER:$MB_USER" "$INSTALL_DIR"
success "Ownership set to $MB_USER"

# ─── Create Systemd Service ─────────────────────

if [ "$HAS_SYSTEMD" = true ]; then
  if confirm "Create and enable systemd service?"; then
    step "Setting up systemd service"

    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<SVCEOF
[Unit]
Description=MemoryBook — Memory File Viewer
After=network.target

[Service]
Type=simple
User=$MB_USER
WorkingDirectory=$INSTALL_DIR
Environment=MEMORY_DIR=$MEMORY_DIR
Environment=WORKSPACE_DIR=$WORKSPACE_DIR
Environment=MB_PORT=$MB_PORT
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/app.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF
    success "Service file created"

    systemctl daemon-reload
    success "Systemd reloaded"

    systemctl enable "$SERVICE_NAME" --quiet
    success "Service enabled (starts on boot)"

    if confirm "Start MemoryBook now?"; then
      systemctl restart "$SERVICE_NAME"
      sleep 2
      if systemctl is-active --quiet "$SERVICE_NAME"; then
        success "MemoryBook is running!"
      else
        warn "Service started but may have issues — check: journalctl -u $SERVICE_NAME"
      fi
    fi
  fi
else
  step "Skipping service setup (no systemd)"
  info "Start manually: cd $INSTALL_DIR && venv/bin/python3 app.py"
fi

# ─── Done ────────────────────────────────────────

echo ""
echo -e "  ${DIM}────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GREEN}${BOLD}  ✓ MemoryBook installed successfully!${NC}"
echo ""
echo -e "    ${BOLD}Open:${NC}     http://localhost:${MB_PORT}"
echo -e "    ${BOLD}Service:${NC}  sudo systemctl status $SERVICE_NAME"
echo -e "    ${BOLD}Logs:${NC}     sudo journalctl -u $SERVICE_NAME -f"
echo -e "    ${BOLD}Config:${NC}   $INSTALL_DIR/.env"
echo ""
echo -e "  ${DIM}────────────────────────────────────────${NC}"
echo ""
