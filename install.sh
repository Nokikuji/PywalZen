#!/usr/bin/env bash
# PywalZen Installer
# https://github.com/Axenide/PywalZen

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info()    { echo -e "${BLUE}→${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

# ─── Uninstall mode ──────────────────────────────────────────────────────────

if [[ "${1:-}" == "--uninstall" ]]; then
    header "Uninstalling PywalZen..."

    ZEN_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zen"
    [[ "$OSTYPE" == "darwin"* ]] && ZEN_CONFIG_DIR="$HOME/Library/Application Support/Zen Browser"

    python3 - "$ZEN_CONFIG_DIR" <<'PYEOF'
import sys, os, json, shutil

config_dir = sys.argv[1]

# Find profile
profile = None
for ini_file in ["installs.ini", "profiles.ini"]:
    ini_path = os.path.join(config_dir, ini_file)
    if not os.path.exists(ini_path):
        continue
    import configparser
    cfg = configparser.ConfigParser()
    cfg.read(ini_path)
    for section in cfg.sections():
        if cfg.has_option(section, "Default"):
            candidate = os.path.join(config_dir, cfg.get(section, "Default").rstrip("/"))
            if os.path.isdir(candidate):
                profile = candidate
                break
    if profile:
        break

if not profile:
    print("Could not find Zen profile.", file=sys.stderr)
    sys.exit(1)

mod_dir = os.path.join(profile, "chrome", "zen-themes", "pywalzen")
themes_json = os.path.join(profile, "zen-themes.json")

if os.path.isdir(mod_dir):
    shutil.rmtree(mod_dir)
    print(f"Removed mod directory: {mod_dir}")
else:
    print("Mod directory not found, nothing to remove.")

if os.path.exists(themes_json):
    with open(themes_json) as f:
        data = json.load(f)
    if "pywalzen" in data:
        del data["pywalzen"]
        with open(themes_json, "w") as f:
            json.dump(data, f, indent=2)
            f.write("\n")
        print("Removed pywalzen entry from zen-themes.json")
PYEOF

    success "PywalZen uninstalled. Restart Zen Browser to apply."
    exit 0
fi

# ─── Prerequisites ────────────────────────────────────────────────────────────

header "Checking prerequisites..."

if ! command -v python3 &>/dev/null; then
    error "python3 is required but not found."
    exit 1
fi

if ! command -v pywalfox &>/dev/null; then
    error "PywalFox is not installed."
    echo ""
    echo "  Install it with:"
    echo "    pip install pywalfox"
    echo "    pywalfox install"
    echo ""
    echo "  Then install the PywalFox extension in Zen Browser:"
    echo "    https://addons.mozilla.org/en-US/firefox/addon/pywalfox/"
    echo ""
    exit 1
fi

success "PywalFox found"

# ─── Find Zen profile ─────────────────────────────────────────────────────────

header "Finding Zen Browser profile..."

ZEN_PROFILE=$(python3 - <<'PYEOF'
import sys, os, configparser

if sys.platform == "darwin":
    config_dir = os.path.expanduser("~/Library/Application Support/Zen Browser")
else:
    config_dir = os.path.join(
        os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config")), "zen"
    )

if not os.path.isdir(config_dir):
    print(f"ERR:Zen config dir not found: {config_dir}", file=sys.stderr)
    sys.exit(1)

def find_profile(ini_path, config_dir):
    if not os.path.exists(ini_path):
        return None
    cfg = configparser.ConfigParser()
    cfg.read(ini_path)
    for section in cfg.sections():
        if cfg.has_option(section, "Default"):
            raw = cfg.get(section, "Default").rstrip("/")
            candidate = os.path.join(config_dir, raw)
            if os.path.isdir(candidate):
                return candidate
    return None

# 1. installs.ini is most reliable (matches the actual browser binary)
profile = find_profile(os.path.join(config_dir, "installs.ini"), config_dir)

# 2. Fall back to profiles.ini Default=1 marker
if not profile:
    ini_path = os.path.join(config_dir, "profiles.ini")
    if os.path.exists(ini_path):
        cfg = configparser.ConfigParser()
        cfg.read(ini_path)
        for section in cfg.sections():
            if cfg.has_option(section, "Default") and cfg.get(section, "Default") == "1":
                raw = cfg.get(section, "Path", fallback="")
                if cfg.get(section, "IsRelative", fallback="0") == "1":
                    candidate = os.path.join(config_dir, raw)
                else:
                    candidate = raw
                if os.path.isdir(candidate):
                    profile = candidate
                    break

# 3. Fall back to Profile0
if not profile:
    ini_path = os.path.join(config_dir, "profiles.ini")
    if os.path.exists(ini_path):
        cfg = configparser.ConfigParser()
        cfg.read(ini_path)
        if cfg.has_section("Profile0"):
            raw = cfg.get("Profile0", "Path", fallback="")
            if cfg.get("Profile0", "IsRelative", fallback="0") == "1":
                candidate = os.path.join(config_dir, raw)
            else:
                candidate = raw
            if os.path.isdir(candidate):
                profile = candidate

if not profile:
    print("ERR:Could not determine Zen profile directory.", file=sys.stderr)
    sys.exit(1)

print(profile)
PYEOF
)

if [[ -z "$ZEN_PROFILE" ]]; then
    error "Could not find Zen Browser profile. Is Zen installed?"
    exit 1
fi

success "Zen profile: $ZEN_PROFILE"

# ─── Install mod files ────────────────────────────────────────────────────────

header "Installing PywalZen mod..."

MOD_DIR="$ZEN_PROFILE/chrome/zen-themes/pywalzen"

if [[ -d "$MOD_DIR" ]]; then
    info "Updating existing installation..."
else
    info "Creating mod directory..."
    mkdir -p "$MOD_DIR"
fi

cp "$SCRIPT_DIR/chrome.css"       "$MOD_DIR/chrome.css"
cp "$SCRIPT_DIR/preferences.json" "$MOD_DIR/preferences.json"
success "Copied mod files"

# ─── Update zen-themes.json ───────────────────────────────────────────────────

THEMES_JSON="$ZEN_PROFILE/zen-themes.json"

python3 - "$THEMES_JSON" <<'PYEOF'
import sys, json, os

path = sys.argv[1]

try:
    with open(path) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        data = {}
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

data["pywalzen"] = {
    "id": "pywalzen",
    "name": "PywalZen",
    "description": "Applies Pywal/Matugen colors to Zen Browser via PywalFox",
    "author": "Axenide",
    "enabled": True,
    "preferences": True,
    "version": "1.0.0"
}

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

success "Registered mod in zen-themes.json"

# ─── Verify userChrome.css support ───────────────────────────────────────────

PREFS_JS="$ZEN_PROFILE/prefs.js"

if grep -q 'legacyUserProfileCustomizations.stylesheets.*true' "$PREFS_JS" 2>/dev/null; then
    success "userChrome.css support is enabled"
else
    warn "Could not confirm userChrome.css support."
    warn "In Zen, open about:config and enable:"
    warn "  toolkit.legacyUserProfileCustomizations.stylesheets = true"
fi

# ─── Set up PywalFox native messaging for Zen ─────────────────────────────────

header "Checking PywalFox native messaging..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    ZEN_CONFIG_DIR="$HOME/Library/Application Support/Zen Browser"
    MOZ_NMH="$HOME/Library/Application Support/Mozilla/NativeMessagingHosts/pywalfox.json"
else
    ZEN_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zen"
    MOZ_NMH="$HOME/.mozilla/native-messaging-hosts/pywalfox.json"
fi

ZEN_NMH_DIR="$ZEN_CONFIG_DIR/native-messaging-hosts"

if [[ -f "$MOZ_NMH" ]]; then
    mkdir -p "$ZEN_NMH_DIR"
    ln -sf "$MOZ_NMH" "$ZEN_NMH_DIR/pywalfox.json"
    success "Linked native messaging host"
else
    warn "PywalFox native messaging host not found."
    warn "Run: pywalfox install"
    warn "Then re-run this script."
fi

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${GREEN}${BOLD}✓ PywalZen installed!${NC}"
echo ""
echo "  Next steps:"
echo "   1. Restart Zen Browser"
echo "   2. Open the PywalFox extension and click 'Fetch Pywal colors'"
echo "   3. Adjust darkness: Zen Settings → Mods → PywalZen"
echo ""
echo "  To uninstall: bash install.sh --uninstall"
