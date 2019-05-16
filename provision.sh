#!/bin/bash

#Create symlinks
echo "Creating symlinks..."

while IFS= read -r var
do
  IFS=':' read -r  -a results <<< "$var"
  eval src="${results[0]}"
  eval dst="${results[1]}"
  DSTDIR=$(dirname "$dst")
  #Create dst dir if not present
  [ -d $DSTDIR ] || mkdir -p $DSTDIR 
  cmp --silent "$src" "$dst" || ln -s "$src" "$dst"
done < "symlinks"
echo "done!"

echo ""
#Add Albert repo
echo "Adding albert repo..."
DIST_VERSION=$(lsb_release -a 2> /dev/null | grep Release | grep -Po "[0-9\.]+$")
#sudo apt install apt-transport-https -y
wget -qO - https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$DIST_VERSION/ /' > /etc/apt/sources.list.d/home:manuelschneid3r.list"
echo "done!"

echo ""
#Add Sublime repo
echo "Adding Sublime repo..."
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
echo "done!"

echo ""
#Run apt installs
echo "Running apt installs and removes..."
sudo apt update -y
while IFS= read -r APT_LINE
do
  IFS=':' read -r  -a APT <<< "$APT_LINE"
  eval ACTION="${APT[0]}"
  eval PKG="${APT[1]}"
  PKG_INSTALLED=$(dpkg -s $PKG 2> /dev/null | grep "install ok installed")
  if [ "" == "$PKG_INSTALLED" ]; then
    if [ "i" == "$ACTION" ]; then
      echo "Installing $PKG..."
      sudo apt install "$PKG" -y
      echo "done!"
    else
      echo "Removing $PKG..."
      sudo apt purge "$PKG" -y
      echo "done!"
    fi
  else
    if [ "i" == "$ACTION" ]; then
      echo "$PKG already installed"
    else
      echo "$PKG already removed"
    fi
  fi
done < "apt_packages"
echo "done!"

echo ""
#NVM and node
echo "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
echo "done!"

echo ""
#Chrome
CHROME_INSTALLED=$(dpkg -s "google-chrome-stable" 2> /dev/null | grep "install ok installed")
if [ "" == "$CHROME_INSTALLED" ]; then
  echo "Installing Chrome..."
  curl -L -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  sudo dpkg --install google-chrome-stable_current_amd64.deb -y
  rm google-chrome-stable_current_amd64.deb
else 
  echo "Chrome already installed"
fi
echo "done!"

echo ""
#Monaco font
if [ -f ~/.local/share/fonts/Monaco_Linux.ttf ]; then
  echo "Monaco (font) already installed"
else
  echo "Installing Monaco (font)..."
  curl -L -O "http://www.gringod.com/wp-upload/software/Fonts/Monaco_Linux.ttf"
  [ -d ~/.local/share/fonts ] || mkdir -p ~/.local/share/fonts
  mv Monaco_Linux.ttf ~/.local/share/fonts/Monaco_Linux.ttf
  fc-cache -f
fi
echo "done!"

echo ""
#Use numix circle and monaco font
echo "Setting icon theme and font..."
dconf write /org/gnome/desktop/interface/icon-theme "'Numix-Circle'"
dconf write /org/gnome/desktop/interface/monospace-font-name= "'Monaco 13'"
echo "done!"

echo ""
#Extension settings
echo "Setting extension settings..."
dconf write /org/gnome/shell/extensions/desktop-icons/show-home false
dconf write /org/gnome/shell/extensions/desktop-icons/show-trash false
echo "done!"


echo ""
#Keyboard shortcuts
echo "Setting keyboard shortcuts..."
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < ~/dotfiles/keys.conf
echo "done!"

echo ""
#Terminal profile
dlist_append() {
    local key="$1"; shift
    local val="$1"; shift

    local entries="$(
        {
            dconf read "$key" | tr -d '[]' | tr , "\n" | fgrep -v "$val"
            echo "'$val'"
        } | head -c-1 | tr "\n" ,
    )"

    dconf write "$key" "[$entries]"
}

TERMINAL_PATH=/org/gnome/terminal/legacy/profiles:
PROFILE_SLUG=3d15fe59-69d5-40c3-be2a-6da1ed714a55

echo "Setting terminal profile"
dconf load $TERMINAL_PATH/ < ~/dotfiles/terminal.conf
dlist_append $TERMINAL_PATH/list "$PROFILE_SLUG"
echo "done!"

#Update all packages and clean up 
sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt autoremove -y
