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
sudo scutil --set ComputerName "${ComputerName:?"ComputerName is not set"}"

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Use dark menu bar and Dock
defaults write "Apple Global Domain" AppleInterfaceStyle Dark

# Menu bar: show the VPN icon
defaults write com.apple.systemuiserver menuExtras -array \
  "/System/Library/CoreServices/Menu Extras/VPN.menu"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Hot corners
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

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Set the size of the Dock
defaults write com.apple.dock tilesize -int 80

# Enable Dock zoom animation
defaults write com.apple.dock magnification -bool true

# Max zoom scale
defaults write com.apple.dock largesize -int 128

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
# Screen                                                                      #
###############################################################################

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

# Trackpad: enable tap
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Trackpad: enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

# Always open everything in Finder's list view. This is important.
defaults write com.apple.Finder FXPreferredViewStyle Nlsv

# Show all files in Finder.
defaults write com.apple.finder AppleShowAllFiles -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Show the ~/Library folder.
chflags nohidden ~/Library

# Set the Finder prefs for not showing a few different volumes on the Desktop.
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Finder: show all filename extensions
defaults write "Apple Global Domain" AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Finder: show path bar
defaults write com.apple.finder ShowPathbar -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

# Hide Safari's bookmark bar.
defaults write com.apple.Safari ShowFavoritesBar -bool false

# Set up Safari for development.
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

for app in "Dock" "Finder"; do
  killall "${app}" >/dev/null 2>&1
done
echo "Done. Note that some of these changes require a logout/restart to take effect."
