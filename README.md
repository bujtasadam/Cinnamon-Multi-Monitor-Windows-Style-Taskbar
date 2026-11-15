![Downloads](https://img.shields.io/github/downloads/bujtasadam/Cinnamon-Multi-Monitor-Windows-Style-Taskbar/total) ![License](https://img.shields.io/github/license/bujtasadam/Cinnamon-Multi-Monitor-Windows-Style-Taskbar)

# Cinnamon Multi-Monitor Windows-Style Taskbar (`cinnamon-win-taskbar`)

A simple, automated Bash & Python utility for **Linux Mint (Cinnamon Desktop)** that brings a classic **Windows-style multi-monitor taskbar experience** to all connected displays.

By default, Cinnamon only displays a single panel on the primary monitor and restricts system tray applets to a single instance. Configuring multiple panels with full window titles, per-monitor task filtering, and full system indicators manually through the GUI can be tedious. This script automates the entire setup in seconds.

## ✨ Features

* **Automatic Multi-Monitor Detection:** Automatically detects all active monitors via `xrandr` and creates a bottom panel (`36px` height) on each display.
* **Classic Windows-Style Window List:** Replaces grouped icons with full text labels (`window-list@cinnamon.org`), displaying full window titles, active browser tabs, and current folder names without grouping.
* **Per-Monitor Window Filtering:** Each taskbar only shows windows open on that specific monitor.
* **Full System Tray & Indicators on Every Screen:** Overrides the single-instance restriction (`max-instances: -1`) for core system applets (`network`, `sound`, `power`, `systray`, `xapp-status`) by cloning their metadata to `~/.local/share/cinnamon/applets/`.
* **Seconds & Full Date on Every Clock:** Configures all panel clocks to display the full date and time with seconds (`%Y. %m. %d. %H:%M:%S`).
* **Automatic Backup:** Creates a full `dconf` backup of your existing Cinnamon configuration in your home directory (`~/cinnamon_panel_backup_YYYYMMDD_HHMMSS.dconf`) before making any changes.

## 🚀 Usage

1. Clone the repository or download `setup_panels.sh`:
   ```bash
   git clone https://github.com
   cd cinnamon-win-taskbar
   ```

2. Make the script executable:
   ```bash
   chmod +x setup_panels.sh
   ```

3. Run the script:
   ```bash
   ./setup_panels.sh
   ```

The script will automatically apply the settings and safely reload the Cinnamon desktop environment via D-Bus without closing your open applications.

## 🔄 Restoring Your Previous Setup

If you want to revert to your original panel layout, restore the backup file created by the script:

```bash
dconf load /org/cinnamon/ < ~/cinnamon_panel_backup_YYYYMMDD_HHMMSS.dconf
dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.Eval string:'global.reexec_self()'
```

*(Replace `YYYYMMDD_HHMMSS` with your actual backup file timestamp.)*

## 🛠️ Tested Environment

* **OS:** Linux Mint 22.3
* **Desktop Environment:** Cinnamon 6.6.9
* **Dependencies:** `bash`, `python3`, `xrandr`, `dconf`, `dbus-send` (all pre-installed on Linux Mint)

## 📝 Notes on X11 System Tray Icons

While native Cinnamon applets (Menu, Launchers, Window List, Network, Sound, Power, Clock) will appear identically on all monitors, third-party X11/XApp tray icons (such as Bluetooth, Update Manager, or NVIDIA PRIME) are registered by their host applications and may only render on one tray due to X11 protocol limitations.

