#!/usr/bin/env bash
#
# Debian 13 (Trixie) Minimal + i3 Setup Script
# Includes i3, virtualization, Docker, Flatpak, dotfiles, and essentials
# by Carens — 2025
#

set -e

# --- Colors ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

APP_DIR="$HOME/Apps"
FASTCOMP_DIR="$APP_DIR/fastcompmgr"

echo -e "${CYAN}>>> Updating base system...${RESET}"
sudo apt update && sudo apt full-upgrade -y

# --- Base Packages ---
echo -e "${CYAN}>>> Installing system packages...${RESET}"
sudo apt install -y \
  build-essential curl wget git fastfetch htop rsync vim fzf zsh \
  xorg i3 i3lock-fancy polybar feh rofi dunst flameshot \
  lightdm mate-polkit network-manager pavucontrol pulseaudio alsa-utils \
  thunar thunar-archive-plugin xarchiver mousepad ristretto lxappearance \
  alacritty ffmpeg mpv python3 python3-pip cargo make gcc \
  libx11-dev libxcomposite-dev libxdamage-dev libxfixes-dev libxrender-dev pkg-config \
  unrar p7zip-full ntfs-3g ufw remmina x11vnc \
  fonts-font-awesome fonts-firacode fonts-jetbrains-mono fonts-croscore \
  fonts-crosextra-carlito fonts-crosextra-caladea fonts-noto fonts-noto-cjk \
  fonts-noto-mono fonts-dejavu fonts-dejavu-extra fonts-liberation fonts-droid-fallback \
  fonts-freefont-ttf fonts-opensymbol gnome-themes-extra gtk2-engines-murrine \
  virt-manager qemu-system libvirt-daemon-system libvirt-clients bridge-utils \
  gnome-keyring udisks2 gvfs-backends gvfs-fuse fonts-noto-color-emoji \
  flatpak ca-certificates playerctl libnotify-bin cava

# --- Enable system services ---
echo -e "${CYAN}>>> Enabling essential services...${RESET}"
sudo systemctl enable lightdm
sudo systemctl enable NetworkManager
sudo systemctl enable libvirtd
sudo systemctl start NetworkManager
sudo systemctl start libvirtd

# --- Virtualization config ---
echo -e "${CYAN}>>> Configuring virtualization (libvirt)...${RESET}"
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"
sudo virsh net-start default || true
sudo virsh net-autostart default || true

# --- Docker installation ---
echo -e "${CYAN}>>> Installing Docker...${RESET}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

source /etc/os-release
echo "Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${VERSION_CODENAME}
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc" | sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo groupadd docker || true
sudo usermod -aG docker "$USER"

# --- Fastcompmgr Setup ---
echo -e "${CYAN}>>> Installing Fastcompmgr...${RESET}"
mkdir -p "$APP_DIR"
if [ ! -d "$FASTCOMP_DIR" ]; then
  git clone https://github.com/tycho-kirchner/fastcompmgr.git "$FASTCOMP_DIR"
else
  echo -e "${YELLOW}>>> Fastcompmgr already exists, pulling latest changes...${RESET}"
  git -C "$FASTCOMP_DIR" pull
fi

cd "$FASTCOMP_DIR"
make
sudo make install
cd -

# --- Oh My Zsh setup ---
echo -e "${CYAN}>>> Setting Zsh as default shell and installing Oh My Zsh...${RESET}"
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo -e "${YELLOW}Oh My Zsh already installed, skipping.${RESET}"
fi

# --- Flatpak setup ---
echo -e "${CYAN}>>> Setting up Flatpak + Flathub...${RESET}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo -e "${CYAN}>>> Installing Flatpak applications...${RESET}"
flatpak install -y flathub org.telegram.desktop
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub org.mozilla.Thunderbird

# --- Dotfiles linking ---
DOTDIR="$HOME/Documents/dotfiles"

if [ -d "$DOTDIR" ]; then
  echo -e "${CYAN}>>> Linking dotfiles from $DOTDIR...${RESET}"

  mkdir -p ~/.config

  rm -rf ~/.config/alacritty ~/.config/cava ~/.config/dunst ~/.config/fastfetch ~/.config/gtk-3.0 \
         ~/.config/i3 ~/.config/polybar ~/.config/rofi

  ln -s "$DOTDIR/.config/alacritty" ~/.config/alacritty
  ln -s "$DOTDIR/.config/cava" ~/.config/cava
  ln -s "$DOTDIR/.config/dunst" ~/.config/dunst
  ln -s "$DOTDIR/.config/fastfetch" ~/.config/fastfetch
  ln -s "$DOTDIR/.config/gtk-3.0" ~/.config/gtk-3.0
  ln -s "$DOTDIR/.config/i3" ~/.config/i3
  ln -s "$DOTDIR/.config/polybar" ~/.config/polybar
  ln -s "$DOTDIR/.config/rofi" ~/.config/rofi

  ln -sf "$DOTDIR/.fonts" ~/.fonts
  ln -sf "$DOTDIR/.themes" ~/.themes
  ln -sf "$DOTDIR/.icons" ~/.icons
  ln -sf "$DOTDIR/.Xresources" ~/.Xresources
  ln -sf "$DOTDIR/.zshrc" ~/.zshrc
  ln -sf "$DOTDIR/.p10k.zsh" ~/.p10k.zsh
  ln -sf "$DOTDIR/.tmux.conf" ~/.tmux.conf
else
  echo -e "${YELLOW}Dotfiles not found at $DOTDIR — skipping link.${RESET}"
fi

# --- Finishing up ---
sudo apt autoremove -y
echo -e "\n${GREEN}>>> Setup complete!${RESET}"
echo -e "You can now reboot and log into the ${YELLOW}i3${RESET} session."
echo -e "Docker, Flatpak, libvirt, and Oh My Zsh are all configured."
echo -e "If using dotfiles, verify: ${CYAN}$DOTDIR${RESET}\n"
echo -e "→ After reboot, Docker group will take effect."
