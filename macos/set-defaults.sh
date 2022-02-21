#!/usr/bin/env bash
# Sets reasonable macOS defaults.
#
# Or, in other words, set shit how I like in macOS.
#
# The original idea (and a couple settings) were grabbed from:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.macos
#
# Run ./set-defaults.sh and you'll be good to go.

export DOTFILES=$HOME/.dotfiles
if [ ! -f "$DOTFILES/macos/os-setting.env.sh" ]; then
  echo "os-setting.env.sh not found"
  echo ' - What is your your computer name?'
  read -e ComputerName
  echo "export ComputerName=$ComputerName" >>$DOTFILES/macos/os-setting.env.sh
  echo "save to $DOTFILES/macos/os-setting.env.sh"
fi
source "$DOTFILES/macos/os-setting.env.sh"
# Set computer name (as done via System Preferences → Sharing)
if [ "$(scutil --get ComputerName)" != "${ComputerName:?"ComputerName is not set"}" ]; then
  sudo scutil --set ComputerName "${ComputerName:?"ComputerName is not set"}"
  sudo scutil --set HostName "${ComputerName:?"ComputerName is not set"}"
  sudo scutil --set LocalHostName "${ComputerName:?"ComputerName is not set"}"
  sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${ComputerName:?"ComputerName is not set"}"
else
  echo "ComputerName=$(scutil --get ComputerName)"
fi

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Use dark menu bar and Dock
defaults write "Apple Global Domain" AppleInterfaceStyle Dark

#### Menu bar

# Menu bar: show secondary time
# Don't work on macOS 12.3
# defaults write com.apple.menuextra.clock ShowSeconds -bool true
# defaults write com.apple.menuextra.clock DateFormat -string "M\\U6708d\\U65e5 EEE  H:mm"

# Menu bar: hide the spotlight icon
# Don't work on macOS 12.3
# defaults write com.apple.systemuiserver dontAutoLoad -array \
# "/System/Library/CoreServices/Menu Extras/Spotlight.menu"

# Menu bar: show the VPN, Volume icon
defaults write com.apple.systemuiserver menuExtras -array \
  "/System/Library/CoreServices/Menu Extras/VPN.menu"
# Don't work on macOS 12.3
# "/System/Library/CoreServices/Menu Extras/Volume.menu"

#### Hot corners
# Possible values:
#  0: no-op
#  2: Mission Control
#  3: Show application windows
#  4: Desktop
#  5: Start screen saver
#  6: Disable screen saver
#  7: Dashboard
# 10: Put display to sleep
# 11: Launchpad
# 12: Notification Center
# Top left screen corner
defaults write com.apple.dock wvous-tl-corner -int 5
defaults write com.apple.dock wvous-tl-modifier -int 0
# Top right screen corner
defaults write com.apple.dock wvous-tr-corner -int 10
defaults write com.apple.dock wvous-tr-modifier -int 0
# Bottom left screen corner
defaults write com.apple.dock wvous-bl-corner -int 2
defaults write com.apple.dock wvous-bl-modifier -int 0
# Bottom right screen corner
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 1048576

#### Dock

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Set the size of the Dock
defaults write com.apple.dock tilesize -int 80

# Enable Dock zoom animation
defaults write com.apple.dock magnification -bool true

# Max zoom scale
defaults write com.apple.dock largesize -int 128

#### Other

# Add US English keyboard layout
defaults write ".GlobalPreferences_m" AppleLanguages -array "zh-Hans-JP" "ja-JP" "en-US"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

###############################################################################
# Power                                                                       #
###############################################################################

# Set battery and power standby delay to 24 hours (default is 1 hour)
sudo pmset -b displaysleep 15
sudo pmset -c displaysleep 180

# Enable/Disable battery and power sleep mode
sudo pmset -c sleep 0

# Enable the battery low power mode
sudo pmset -b lowpowermode 1

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Trackpad: speed up
defaults write com.apple.trackpad.scaling -int 3

# Trackpad: enable tap
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Trackpad: enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# keyboard: fnState
defaults write com.apple.keyboard.fnState -bool true

defaults write com.apple.dock showAppExposeGestureEnabled -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write "Apple Global Domain" AppleShowAllExtensions -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show the ~/Library folder.
chflags nohidden ~/Library

# Set the Finder prefs for not showing a few different volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Finder: Open iCloud Drive in new window
defaults write com.apple.finder NSNavLastRootDirectory -string "~/Library/Mobile\ Documents/com~apple~CloudDocs"
defaults write com.apple.finder NewWindowTarget -string "PfID"
defaults write com.apple.finder NewWindowTargetPath -string "file:///${HOME}/Library/Mobile%20Documents/com~apple~CloudDocs/"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

# Hide Safari's bookmark bar.
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Show the full URL in the address bar (note: this still hides the scheme)
# Don't work on macOS 12.3. May from big sur?
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Prevent Safari from opening ‘safe’ files automatically after downloading
# Don't work on macOS 12.3. May from big sur?
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Set up Safari for development.
# defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
# defaults write com.apple.Safari IncludeDevelopMenu -bool true
# defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
# defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
# defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

echo "Done. Note that some of these changes require a logout/restart to take effect."
