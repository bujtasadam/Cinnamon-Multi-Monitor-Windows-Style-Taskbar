#!/bin/bash

echo "=================================================================="
echo "   Cinnamon Multi-Monitor Windows-Style Taskbar Setup"
echo "=================================================================="

echo "=== STEP 0: Checking Environment & Prerequisites ==="
echo " -> OS: $(lsb_release -ds 2>/dev/null || head -n1 /etc/issue)"
echo " -> Desktop Environment: $(cinnamon --version) ($XDG_CURRENT_DESKTOP)"
echo " -> Python3: $(command -v python3 || echo 'MISSING!')"

MONITOR_COUNT=$(xrandr --listmonitors 2>/dev/null | awk 'NR==1{print $2}')
if [ -z "$MONITOR_COUNT" ] || [ "$MONITOR_COUNT" -lt 1 ]; then
  MONITOR_COUNT=1
fi
echo " -> Active Monitors Detected: $MONITOR_COUNT"
xrandr --listmonitors 2>/dev/null | tail -n +2 | sed 's/^/    /'
echo "------------------------------------------------------------------"

echo "=== STEP 1: Clearing Stale dconf Processes ==="
killall -9 dconf-service 2>/dev/null
echo " -> Done."

echo "=== STEP 2: Creating Configuration Backup ==="
BACKUP_FILE=~/cinnamon_panel_backup_$(date +%Y%m%d_%H%M%S).dconf
dconf dump /org/cinnamon/ > "$BACKUP_FILE"
echo " -> Backup saved to: $BACKUP_FILE"

echo "=== STEP 3: Enabling Multi-Instance Support for System Applets ==="
SYS_APPLET_DIR="/usr/share/cinnamon/applets"
LOCAL_APPLET_DIR="$HOME/.local/share/cinnamon/applets"
mkdir -p "$LOCAL_APPLET_DIR"

MULTI_APPLETS=("systray@cinnamon.org" "xapp-status@cinnamon.org" "network@cinnamon.org" "sound@cinnamon.org" "power@cinnamon.org")

for APPLET in "${MULTI_APPLETS[@]}"; do
  if [ -d "$SYS_APPLET_DIR/$APPLET" ]; then
    rm -rf "$LOCAL_APPLET_DIR/$APPLET"
    cp -r "$SYS_APPLET_DIR/$APPLET" "$LOCAL_APPLET_DIR/"
    python3 -c "
import json
meta_file = '$LOCAL_APPLET_DIR/$APPLET/metadata.json'
with open(meta_file, 'r', encoding='utf-8') as f:
    data = json.load(f)
data['max-instances'] = -1
with open(meta_file, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4)
"
    echo " -> Multi-instance enabled for: $APPLET"
  fi
done

echo "=== STEP 4 & 5: Configuring Panels & Applets Across All Monitors ==="
python3 - << EOF
import json
import os
import subprocess

monitor_count = int("$MONITOR_COUNT")
spices_base = os.path.expanduser("~/.config/cinnamon/spices")

panels_enabled = []
panels_height = []
enabled_applets = []

window_list_ids = []
calendar_ids = []

instance_id = 0

for m in range(monitor_count):
    panel_num = m + 1
    panel_name = f"panel{panel_num}"
    
    panels_enabled.append(f"{panel_num}:{m}:bottom")
    panels_height.append(f"{panel_num}:36")
    
    # Left zone: Menu, Launchers, Classic Window List
    enabled_applets.append(f"{panel_name}:left:0:menu@cinnamon.org:{instance_id}")
    instance_id += 1
    
    enabled_applets.append(f"{panel_name}:left:1:panel-launchers@cinnamon.org:{instance_id}")
    instance_id += 1
    
    enabled_applets.append(f"{panel_name}:left:2:window-list@cinnamon.org:{instance_id}")
    window_list_ids.append(instance_id)
    instance_id += 1
    
    # Right zone: System Tray, XApp Status, Network, Sound, Power, Clock
    right_applets = [
        "systray@cinnamon.org",
        "xapp-status@cinnamon.org",
        "network@cinnamon.org",
        "sound@cinnamon.org",
        "power@cinnamon.org",
        "calendar@cinnamon.org"
    ]
    
    for pos, app in enumerate(right_applets):
        enabled_applets.append(f"{panel_name}:right:{pos}:{app}:{instance_id}")
        if app == "calendar@cinnamon.org":
            calendar_ids.append(instance_id)
        instance_id += 1

# Apply gsettings
subprocess.run(["gsettings", "set", "org.cinnamon", "panels-enabled", str(panels_enabled)], check=True)
subprocess.run(["gsettings", "set", "org.cinnamon", "panels-height", str(panels_height)], check=True)
subprocess.run(["gsettings", "set", "org.cinnamon", "enabled-applets", str(enabled_applets)], check=True)
print(f" -> Configured {monitor_count} bottom panels and assigned all applets.")

# Helper to update Spice JSON configs
def update_spice_json(applet_name, applet_ids, settings_dict):
    applet_dir = os.path.join(spices_base, applet_name)
    os.makedirs(applet_dir, exist_ok=True)
    for aid in applet_ids:
        filepath = os.path.join(applet_dir, f"{aid}.json")
        data = {}
        if os.path.exists(filepath):
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception:
                data = {}
        
        for key, val in settings_dict.items():
            if key not in data or not isinstance(data[key], dict):
                data[key] = {}
            data[key]["value"] = val
            
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4)
        print(f" -> Updated Spice JSON: {applet_name}/{aid}.json")

# Configure classic ungrouped window-list per monitor
update_spice_json("window-list@cinnamon.org", window_list_ids, {
    "enable-grouping": False,
    "show-all-workspaces": False,
    "show-windows-from-current-monitor": True
})

# Configure clocks with full date and seconds
update_spice_json("calendar@cinnamon.org", calendar_ids, {
    "use-custom-format": True,
    "custom-format": "%Y. %m. %d. %H:%M:%S"
})
EOF

echo "=== STEP 6: Reloading Cinnamon Desktop Safely ==="
dbus-send --session --dest=org.Cinnamon --type=method_call /org/Cinnamon org.Cinnamon.Eval string:'global.reexec_self()'
echo " -> Reload signal sent!"

echo "=================================================================="
echo "   SETUP COMPLETE! All taskbars are now active."
echo "=================================================================="

