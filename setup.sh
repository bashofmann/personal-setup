#!/usr/bin/env bash
# set -eu

cd "$(dirname "$0")"

[ "$1" = "--debug" ] && SETUP_DEBUG="1"
SETUP_SUCCESS=""

cleanup() {
  set +e
  if [ -n "$STRAP_SUDO_WAIT_PID" ]; then
    sudo kill "$STRAP_SUDO_WAIT_PID"
  fi
  sudo -k
  rm -f "$CLT_PLACEHOLDER"
  if [ -z "$SETUP_SUCCESS" ]; then
    if [ -n "$SETUP_STEP" ]; then
      echo "!!! $SETUP_STEP FAILED" >&2
    else
      echo "!!! FAILED" >&2
    fi
    if [ -z "$SETUP_DEBUG" ]; then
      echo "!!! Run '$0 --debug' for debugging output." >&2
    fi
  fi
}

trap "cleanup" EXIT

if [ -n "$SETUP_DEBUG" ]; then
  set -x
else
  STRAP_QUIET_FLAG="-q"
  Q="$STRAP_QUIET_FLAG"
fi


SETUP_NAME="Bastian Hofmann"
SETUP_EMAIL="bashofmann@gmail.com"

# We want to always prompt for sudo password at least once rather than doing
# root stuff unexpectedly.
sudo -k

# Initialise (or reinitialise) sudo to save unhelpful prompts later.
sudo_init() {
  if ! sudo -vn &>/dev/null; then
    if [ -n "$STRAP_SUDOED_ONCE" ]; then
      echo "--> Re-enter your password (for sudo access; sudo has timed out):"
    else
      echo "--> Enter your password (for sudo access):"
    fi
    sudo /usr/bin/true
    STRAP_SUDOED_ONCE="1"
  fi
}

abort() { SETUP_STEP="";   echo "!!! $*" >&2; exit 1; }
log()   { SETUP_STEP="$*"; sudo_init; echo "--> $*"; }
logn()  { SETUP_STEP="$*"; sudo_init; printf -- "--> %s " "$*"; }
logk()  { SETUP_STEP="";   echo "OK"; }

[ "$USER" = "root" ] && abort "Run script as yourself, not root."
groups | grep $Q admin || abort "Add $USER to the admin group."

# Set some system security settings.
logn "Configuring system settings:"
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled \
  -bool false
defaults write com.apple.Safari \
  com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles \
  -bool false
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist 2>/dev/null
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport prefs DisconnectOnLogout=NO

# click on tap
sudo defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
sudo defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
sudo defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# natural scrolling disabled
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool FALSE

# dock
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 30
killall Dock

# key repeat
defaults write -g InitialKeyRepeat -int 15 # normal minimum is 15 (225 ms)
defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

# language popup
defaults write -g ApplePressAndHoldEnabled -bool true

if [ -n "$SETUP_NAME" ] && [ -n "$SETUP_EMAIL" ]; then
  sudo defaults write /Library/Preferences/com.apple.loginwindow \
    LoginwindowText \
    "Found this computer? Please contact $SETUP_NAME at $SETUP_EMAIL."
fi
logk

# Install the Xcode Command Line Tools.
if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/git" ] || \
   ! [ -f "/usr/include/iconv.h" ]
then
  log "Installing the Xcode Command Line Tools:"
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  sudo touch "$CLT_PLACEHOLDER"
  CLT_PACKAGE=$(softwareupdate -l | \
                grep -B 1 -E "Command Line (Developer|Tools)" | \
                awk -F"*" '/^ +\*/ {print $2}' | sed 's/^ *//' | head -n1)
  sudo softwareupdate -i "$CLT_PACKAGE"
  sudo rm -f "$CLT_PLACEHOLDER"
  if ! [ -f "/usr/include/iconv.h" ]; then
      echo
      logn "Requesting user install of Xcode Command Line Tools:"
      xcode-select --install
  fi
  logk
fi

# Check if the Xcode license is agreed to and agree if not.
xcode_license() {
  if /usr/bin/xcrun clang 2>&1 | grep $Q license; then
      logn "Asking for Xcode license confirmation:"
      sudo xcodebuild -license
      logk
  fi
}
xcode_license

# install homebrew
if ! [ -x "$(command -v brew)" ]; then
  logn "Installing homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  logk
fi

# Check and install any remaining software updates.
logn "Checking for software updates:"
if softwareupdate -l 2>&1 | grep $Q "No new software available."; then
  logk
else
  echo
  log "Installing software updates:"
  sudo softwareupdate --install --all
  xcode_license
  logk
fi

logn "Copy environment files"
cp .vimrc ~/.vimrc
cp .zshrc ~/.zshrc
cp .gitconfig ~/.gitconfig
cp .gitignore_global ~/.gitignore_global
cp .profile ~/.profile
cp .zprofile ~/.zprofile
cp topgrade.toml ~/Library/Preferences/topgrade.toml
logk

# source env
. ~/.profile

# update homebrew
logn "Updating homebrew"
brew update
logk

logn "Installing homebrew bundle"
brew bundle
logk

logn "Installing pecl extensions"
pecl install --soft xdebug || true
logk

logn "Installing global npm modules"
npm install -g npm
logk

logn "Installing php/composer stuff"
curl -sS https://get.symfony.com/cli/installer | bash
logk

logn "Installing krew plugins"
(
 set -x; cd "$(mktemp -d)" &&
 curl -fsSLO "https://storage.googleapis.com/krew/v0.2.1/krew.{tar.gz,yaml}" &&
 tar zxvf krew.tar.gz &&
 ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install --manifest=krew.yaml --archive=krew.tar.gz
)
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew update
kubectl krew upgrade
kubectl krew install access-matrix
kubectl krew install debug-shell
kubectl krew install get-all
kubectl krew install ingress-nginx
kubectl krew install oidc-login
kubectl krew install open-svc
kubectl krew install rbac-lookup
kubectl krew install rbac-view
kubectl krew install resource-capacity
kubectl krew install sniff
kubectl krew install tree
kubectl krew install view-secret
kubectl krew install view-utilization
kubectl krew install whoami
logk

logn "Creating source code folders"
mkdir -p ~/go
mkdir -p ~/bin
logk

logn "Installing go modules"
go get -u golang.org/x/lint/golint
go get github.com/brancz/gojsontoyaml
go get github.com/mikefarah/yq
go get github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb
go get golang.org/x/tools/cmd/goimports
logk

logn "Setup shell"
if grep -Fxq "$(which zsh)" /etc/shells
then
    echo "Already in /etc/shells"
else
    sudo bash -c "echo "$(which zsh)" >> /etc/shells"
fi
if [ "$SHELL" != "$(which zsh)" ]
then
    chsh -s $(which zsh)
fi
logk

SETUP_SUCCESS="1"
log "Finished!"
