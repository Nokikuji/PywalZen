<h1 align="center">🎨 PywalZen</h1>

<p align="center"><sup><i>A <a href="https://zen-browser.app/">Zen Browser</a> mod that applies your <a href="https://github.com/dylanaraps/pywal">Pywal</a> or <a href="https://github.com/InioX/matugen">Matugen</a> colors using <a href="https://github.com/Frewacom/pywalfox">PywalFox</a>.</i></sup></p>

<p align="center">
  <img src="./screenshots/pywalzen.png" alt="PywalZen preview" />
</p>

![](./screenshots/1.png)
![](./screenshots/2.png)
![](./screenshots/3.png)

> [!NOTE]
> Compatible with Zen Browser's grain effect. Overrides custom gradients.

> [!CAUTION]
> Requires PywalFox to be active. Without it, text may become unreadable.

---

## How it works

[PywalFox](https://github.com/Frewacom/pywalfox) applies your Pywal/Matugen color palette as a Firefox lightweight theme, which sets the `--lwt-accent-color` CSS variable. This mod reads that variable and propagates it to Zen Browser's background and UI color tokens. A darkness level preference lets you darken the accent color for a more subdued look.

---

## Prerequisites

### 1. A color source

You need either **pywal** or **Matugen** generating colors from your wallpaper.

**pywal** (classic, generates 16 colors from any wallpaper):
```bash
# Arch / CachyOS
sudo pacman -S python-pywal

# pip
pip install pywal

# Generate colors from your wallpaper
wal -i /path/to/your/wallpaper.jpg
```

**Matugen** (Material You palette generator, used in many Hyprland rices):
```bash
# Arch / CachyOS
yay -S matugen-bin

# Generate colors
matugen image /path/to/your/wallpaper.jpg
```
If you use a rice that already runs Matugen (e.g. Dusk's Hyprland setup), colors are already being generated — you just need to make sure the PywalFox template is configured (see the Matugen section below).

---

### 2. PywalFox daemon

PywalFox is the bridge between your color palette and the browser.

```bash
# Install
pip install pywalfox

# Register the native messaging host (do this once)
pywalfox install
```

---

### 3. PywalFox browser extension

Install the extension in Zen Browser:
👉 **[PywalFox on Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/pywalfox/)**

Once installed, open the extension popup and click **"Fetch Pywal colors"** to load your palette.

---

## Installation

### Automatic (recommended)

```bash
git clone https://github.com/Axenide/PywalZen
cd PywalZen
bash install.sh
```

Then **restart Zen Browser**. The mod will appear under **Zen Settings → Mods** where you can adjust the darkness level.

To uninstall:
```bash
bash install.sh --uninstall
```

---

### Manual

1. Copy `chrome.css` and `preferences.json` to your Zen profile's mod folder:
   ```
   ~/.config/zen/<your-profile>/chrome/zen-themes/pywalzen/
   ```
2. Add the following to `~/.config/zen/<your-profile>/zen-themes.json`:
   ```json
   {
     "pywalzen": {
       "id": "pywalzen",
       "name": "PywalZen",
       "description": "Applies Pywal/Matugen colors to Zen Browser via PywalFox",
       "author": "Axenide",
       "enabled": true,
       "preferences": true,
       "version": "1.0.0"
     }
   }
   ```
3. Restart Zen Browser.

---

## Matugen integration

If you use Matugen, add this template and post-hook to your `~/.config/matugen/config.toml` to auto-update Zen whenever your wallpaper changes:

**`~/.config/matugen/templates/pywalfox-colors.json`:**
```json
{
  "wallpaper": "{{image}}",
  "alpha": "100",
  "colors": {
    "color0":  "{{colors.background.default.hex}}",
    "color1":  "",
    "color2":  "",
    "color3":  "",
    "color4":  "",
    "color5":  "",
    "color6":  "",
    "color7":  "",
    "color8":  "",
    "color9":  "",
    "color10": "{{colors.primary.default.hex}}",
    "color11": "",
    "color12": "",
    "color13": "{{colors.surface_bright.default.hex}}",
    "color14": "",
    "color15": "{{colors.on_surface.default.hex}}"
  }
}
```

**`~/.config/matugen/config.toml`** (add this block):
```toml
[templates.pywalfox]
input_path  = "~/.config/matugen/templates/pywalfox-colors.json"
output_path = "~/.config/matugen/generated/pywalfox-colors.json"
post_hook   = '''
bash -c '
{
  if command -v pywalfox >/dev/null 2>&1; then
    mkdir -p "$HOME/.cache/wal"
    ln -nfs "$HOME/.config/matugen/generated/pywalfox-colors.json" "$HOME/.cache/wal/colors.json"
    pywalfox update
  fi
} >/dev/null 2>&1 </dev/null & disown
'
'''
```

---

## Darkness levels

Adjust in **Zen Settings → Mods → PywalZen**:

| Level | Effect |
|-------|--------|
| `default` | Accent color as-is |
| `dark` | 25% darker |
| `darker` | 50% darker |
| `yet-darker` | 75% darker |
| `pitch-black` | Pure black |

---

<p align="center">
<samp><sup><b><i>Please consider giving me a tip. :)</i><br>
<a href="https://cafecito.app/axenide">☕ Cafecito</a> |
<a href="https://ko-fi.com/axenide">❤️ Ko-Fi</a> |
<a href="https://paypal.me/Axenide">💸 PayPal</a>
</i></b></sup></samp>
</p>
