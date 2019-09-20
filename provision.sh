#!/bin/bash

#Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#Create symlinks
echo -e "${BLUE}Creating symlinks...${NC}"

while IFS= read -r var
do
  IFS=':' read -r  -a results <<< "$var"
  eval SRC="${results[0]}"
  eval DST="${results[1]}"
  if [ -f "$DST" ]; then
    if [ -L "$DST" ]; then
      echo -e "${GREEN}${DST} is already linked${NC}"
    else
      echo -e "${RED}${DST} already exists, but isn't linked..${NC}"
      read -r -p "Delete it? [y/N]" RESPONSE </dev/tty
      if [[ $RESPONSE =~ ^[Yy]$ ]]
      then
        rm -f "$DST"
        cmp --silent "$SRC" "$DST" || ln -s "$SRC" "$DST"
        echo -e "${GREEN}${DST} linked${NC}"
      fi
    fi
  else 
    DSTDIR=$(dirname "$DST")
    #Create DST dir if not present
    [ -d $DSTDIR ] || mkdir -p $DSTDIR 
    cmp --silent "$SRC" "$DST" || ln -s "$SRC" "$DST"
    echo -e "${GREEN}${DST} linked${NC}"
  fi
done < "symlinks"
echo -e "${GREEN}done!${NC}"

echo ""
#Add Albert repo
FILE=/etc/apt/sources.list.d/home:manuelschneid3r.list
if [ -e "$FILE" ]; then
    echo -e "${GREEN}Albert repo already added${NC}"
else 
    echo -e "${BLUE}Adding albert repo...${NC}"
    DIST_VERSION=$(lsb_release -a 2> /dev/null | grep Release | grep -Po "[0-9\.]+$")
    #sudo apt install apt-transport-https -y
    wget -qO - https://build.opensuse.org/projects/home:manuelschneid3r/public_key | sudo apt-key add -
    sudo sh -c "echo 'deb http://download.opensuse.org/repositories/home:/manuelschneid3r/xUbuntu_$DIST_VERSION/ /' > /etc/apt/sources.list.d/home:manuelschneid3r.list"
    echo -e "${GREEN}done!${NC}"
fi


echo ""
#Add Sublime repo
FILE=/etc/apt/sources.list.d/sublime-text.list
if [ -e "$FILE" ]; then
    echo -e "${GREEN}Sublime repo already added ${NC}"
else
    echo -e "${BLUE}Adding Sublime repo...${NC}"
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
    echo -e "${GREEN}done!${NC}"
fi

echo ""
#Run apt installs
echo -e "${BLUE}Running apt installs and removes...${NC}"
sudo apt -qq update -y
while IFS= read -r APT_LINE
do
  IFS=':' read -r  -a APT <<< "$APT_LINE"
  eval ACTION="${APT[0]}"
  eval PKG="${APT[1]}"
  PKG_INSTALLED=$(dpkg -s $PKG 2> /dev/null | grep "install ok installed")
  if [ "" == "$PKG_INSTALLED" ]; then
    if [ "i" == "$ACTION" ]; then
      echo -e "${BLUE}Installing $PKG...${NC}"
      sudo apt -qq install "$PKG" -y
      echo -e "${GREEN}done!${NC}"
    else
      echo -e "${GREEN}$PKG already removed${NC}"
    fi
  else
    if [ "i" == "$ACTION" ]; then
      echo -e "${GREEN}$PKG already installed${NC}"
    else
      echo -e "${RED}Removing $PKG...${NC}"
      sudo apt -qq purge "$PKG" -y
      echo -e "${GREEN}done!${NC}"
    fi
  fi
done < "apt_packages"
echo -e "${GREEN}done!${NC}"

echo ""
#NVM and node
NVM_INSTALLED=$(command -v nvm 2> /dev/null | grep "nvm")
if [ "" == "$NVM_INSTALLED" ]; then
    echo -e "${GREEN}NVM is already installed${NC}"
else
    echo -e "${BLUE}Installing NVM...${NC}"
    mkdir ~/.nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    echo -e "${GREEN}done!${NC}"
fi


echo ""
#Chrome
CHROME_INSTALLED=$(dpkg -s "google-chrome-stable" 2> /dev/null | grep "install ok installed")
if [ "" == "$CHROME_INSTALLED" ]; then
  echo -e "${BLUE}Installing Chrome...${NC}"
  curl -L -O "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  sudo dpkg --install google-chrome-stable_current_amd64.deb -y
  rm google-chrome-stable_current_amd64.deb
else 
  echo -e "${GREEN}Chrome already installed${NC}"
fi
echo -e "${GREEN}done!${NC}"

echo ""
#Monaco font
if [ -f ~/.local/share/fonts/Monaco_Linux.ttf ]; then
  echo -e "${GREEN}Monaco (font) already installed${NC}"
else
  echo -e "${BLUE}Installing Monaco (font)...${NC}"
  curl -L -O "http://www.gringod.com/wp-upload/software/Fonts/Monaco_Linux.ttf"
  [ -d ~/.local/share/fonts ] || mkdir -p ~/.local/share/fonts
  mv Monaco_Linux.ttf ~/.local/share/fonts/Monaco_Linux.ttf
  fc-cache -f
fi
echo -e "${GREEN}done!${NC}"

echo ""
#Use numix circle and monaco font
echo -e "${BLUE}Setting icon theme and font...${NC}"
dconf write /org/gnome/desktop/interface/icon-theme "'Numix-Circle'"
dconf write /org/gnome/desktop/interface/monospace-font-name= "'Monaco 13'"
echo -e "${GREEN}done!${NC}"

echo ""
#Extension settings
echo -e "${BLUE}Setting extension settings...${NC}"
dconf write /org/gnome/shell/extensions/desktop-icons/show-home false
dconf write /org/gnome/shell/extensions/desktop-icons/show-trash false
echo -e "${GREEN}done!${NC}"


echo ""
#Keyboard shortcuts
echo -e "${BLUE}Setting keyboard shortcuts...${NC}"
dconf load /org/gnome/settings-daemon/plugins/media-keys/ < ~/dotfiles/keys.conf
echo -e "${GREEN}done!${NC}"

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

echo -e "${BLUE}Setting terminal profile${NC}"
dconf load $TERMINAL_PATH/ < ~/dotfiles/terminal.conf
dlist_append $TERMINAL_PATH/list "$PROFILE_SLUG"
echo -e "${GREEN}done!${NC}"

echo ""
#Update all packages and clean up 
echo -e "${BLUE}Updating all packages${NC}"
sudo apt -qq update -y && sudo apt upgrade -y
sudo apt autoremove -y
echo -e "${GREEN}done!${NC}"
