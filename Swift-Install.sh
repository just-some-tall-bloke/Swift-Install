#!/bin/bash
# Swift-Install - Enhanced UI
# MIT License

# Modified by just-some-tall-bloke 2025. Based on the original script by roto31

# Copyright (c) 2022 roto31
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

LC_CTYPE=en_US.utf8
shopt -s extglob

# Variables
dialogApp="/usr/local/bin/dialog"
installomator="/usr/local/Installomator/Installomator.sh"
dialog_command_file="/var/tmp/dialog.log"

title="Install Applications"
message="Select the applications you want to install. Click Install to proceed."
icon="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"

# Predefined icons for display before installation (stored locally)
declare -A apps
apps=(
    ["Firefox"]="/usr/local/share/icons/firefox.icns"
    ["Atom"]="/usr/local/share/icons/atom.icns"
    ["Brave"]="/usr/local/share/icons/brave.icns"
    ["Keka"]="/usr/local/share/icons/keka.icns"
    ["Microsoft Edge"]="/usr/local/share/icons/edge.icns"
    ["Opera"]="/usr/local/share/icons/opera.icns"
    ["Google Chrome"]="/usr/local/share/icons/chrome.icns"
    ["Slack"]="/usr/local/share/icons/slack.icns"
    ["Universal Type Client"]="/usr/local/share/icons/universal_type_client.icns"
)

# Ensure script runs as root
if [[ $(id -u) -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Check if Installomator exists
if [[ ! -x "$installomator" ]]; then
    echo "Installomator not found at $installomator. Exiting."
    exit 1
fi

# Construct Application List for Grid Selection
listitems=""
for app in "${!apps[@]}"; do
    icon_path="${apps[$app]}"
    [[ ! -e "$icon_path" ]] && icon_path="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
    listitems+=" --listitem '${app}' icon '${icon_path}' status 'Not Installed' "
done

# Show App Selection Grid
dialogCMD="$dialogApp -p --title \"$title\" --message \"$message\" \
    --icon \"$icon\" --button1text \"Install\" --moveable --small $listitems"

eval "$dialogCMD" &
sleep 2  # Allow UI to initialize

# Read user selection
selected_apps=($(grep "listitem:" "$dialog_command_file" | awk -F" : " '{print $2}'))

# Install selected applications
progress_index=0
for app in "${selected_apps[@]}"; do
    step_progress=$((30 * progress_index))
    dialog_command "progress: $step_progress"
    dialog_command "listitem: $app: Installing"
    
    # Run Installomator
    installomator "$app"
    
    # Update the icon after installation
    new_icon="/Applications/$app.app/Contents/Resources/AppIcon.icns"
    [[ -e "$new_icon" ]] && dialog_command "listitem: $app icon '$new_icon'"
    
    dialog_command "listitem: $app: ✅ Installed"
    progress_index=$((progress_index + 1))
done

# Finalize installation
dialog_command "progresstext: Installation complete."
dialog_command "progress: complete"
dialog_command "button1text: Done"
dialog_command "button1: enable"
exit 0
