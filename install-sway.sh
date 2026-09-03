#!/usr/bin/env bash
#
# Debian 13 (Trixie) Sway Setup Script — machine-aware, idempotent
# Detects existing DE/WM + display manager:
#   - Desktop machine (DM present) → adds Sway as extra session, DM untouched
#   - Fresh/minimal machine       → optionally installs SDDM + full stack
# Skips what already exists: docker, omz, flatpak apps, existing links.
# by Carens — 2026
#
set -e

# --- Colors ---
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RESET="\033[0m"

DOTDIR="$HOME/Documents/dotfiles"

# ============================================================
# HELPERS — safe, idempotent linking
# ============================================================
link_item() {  # link_item <repo-src> <dest>
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then
    echo -e "    ${YELLOW}skip (not in repo): $(basename "$dst")${RESET}"
    return
  fi
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    echo -e "    ok (already linked): $(basename "$dst")"
    return
  fi
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    local bak="${dst}.bak.$(date +%Y%m%d-%H%M%S)"
    mv "$dst" "$bak"
    echo -e "    ${YELLOW}backed up existing dir: $(basename "$dst") → ${bak}${RESET}"
  fi
  # replaces a stale symlink (e.g. pointing to old dotfiles) silently
  ln -sfn "$src" "$dst"
  echo -e "    linked: $(basename "$dst")"
}

# ============================================================
# 1. DETECT MACHINE STATE
# ============================================================
echo -e "${CYAN}>>> Detecting machine state...${RESET}"

CURRENT_DM=""
DM_FILE="/etc/X11/default-display-manager"
if [ -f "$DM_FILE" ] && [ -s "$DM_FILE" ]; then
  CURRENT_DM=$(basename "$(cat "$DM_FILE")" 2>/dev/null || true)
fi
if [ -z "$CURRENT_DM" ]; then
  for dm in sddm gdm3 lightdm lxdm; do
    if systemctl is-enabled "$dm" &>/dev/null; then CURRENT_DM="$dm"; break; fi
  done
fi

SESSIONS=$(find /usr/share/xsessions /usr/share/wayland-sessions -name '*.desktop' 2>/dev/null \
  | xargs -n1 basename 2>/dev/null | sed 's/\.desktop//' | sort -u | tr '\n' ' ')

NVIDIA=false
lspci 2>/dev/null | grep -iE 'vga|3d' | grep -qi nvidia && NVIDIA=true

SWAY_PRESENT=false
dpkg -s sway &>/dev/null && SWAY_PRESENT=true

DOCKER_PRESENT=false
dpkg -s docker-ce &>/dev/null && DOCKER_PRESENT=true

OMZ_PRESENT=false
[ -d "$HOME/.oh-my-zsh" ] && OMZ_PRESENT=true

DOT_PRESENT=false
[ -d "$DOTDIR" ] && DOT_PRESENT=true

echo -e "  Display manager : ${GREEN}${CURRENT_DM:-none}${RESET}"
echo -e "  Sessions        : ${GREEN}${SESSIONS:-none}${RESET}"
echo -e "  Sway installed  : ${GREEN}${SWAY_PRESENT}${RESET}"
echo -e "  Docker (docker-ce): ${GREEN}${DOCKER_PRESENT}${RESET}"
echo -e "  Oh My Zsh       : ${GREEN}${OMZ_PRESENT}${RESET}"
echo -e "  Dotfiles found  : ${GREEN}${DOT_PRESENT} ($DOTDIR)${RESET}"
$NVIDIA && echo -e "  ${YELLOW}WARNING: NVIDIA GPU detected — sway works best on Intel/AMD.${RESET}"

# ============================================================
# 2. SYSTEM UPDATE
# ============================================================
echo -e "${CYAN}>>> Updating base system...${RESET}"
sudo apt update && sudo apt full-upgrade -y

# ============================================================
# 3. DISPLAY MANAGER DECISION
# ============================================================
INSTALL_DM=false
if [ -n "$CURRENT_DM" ]; then
  echo -e "${CYAN}>>> Existing desktop detected ($CURRENT_DM) — Sway will be ADDED as extra session. DM untouched.${RESET}"
else
  echo -e "${YELLOW}>>> No display manager found (fresh/minimal system).${RESET}"
  read -rp "    Install SDDM as login manager? [Y/n] " yn
  case "$yn" in
    [nN]*) echo -e "${YELLOW}    Skipping DM — start sway manually from TTY: 'sway'${RESET}" ;;
    *)     INSTALL_DM=true ;;
  esac
fi

# ============================================================
# 4. INSTALL PACKAGES
# ============================================================
echo -e "${CYAN}>>> Installing Sway + Wayland stack...${RESET}"
sudo apt install -y \
  sway swaybg swaylock swayidle xdg-desktop-portal xdg-desktop-portal-wlr \
  xdg-desktop-portal-gtk waybar fuzzel grim slurp wl-clipboard swappy wlogout \
  lxpolkit pamixer brightnessctl rofi

echo -e "${CYAN}>>> Installing shared essentials...${RESET}"
sudo apt install -y \
  build-essential curl wget git fastfetch htop rsync vim fzf zsh \
  alacritty dunst network-manager pavucontrol pipewire pulseaudio-utils \
  thunar thunar-archive-plugin xarchiver mousepad ristretto lxappearance \
  ffmpeg mpv python3 python3-pip cargo make gcc pkg-config \
  libx11-dev libxcomposite-dev libxdamage-dev libxfixes-dev libxrender-dev \
  unrar p7zip-full ntfs-3g ufw remmina x11vnc wayvnc \
  fonts-font-awesome fonts-firacode fonts-jetbrains-mono fonts-croscore \
  fonts-crosextra-carlito fonts-crosextra-caladea fonts-noto fonts-noto-cjk \
  fonts-noto-mono fonts-dejavu fonts-dejavu-extra fonts-liberation \
  fonts-freefont-ttf fonts-opensymbol gnome-themes-extra gtk2-engines-murrine \
  virt-manager qemu-system libvirt-daemon-system libvirt-clients bridge-utils \
  gnome-keyring udisks2 gvfs-backends gvfs-fuse fonts-noto-color-emoji \
  flatpak ca-certificates playerctl libnotify-bin cava

# ============================================================
# 5. SERVICES + VIRT CONFIG (idempotent)
# ============================================================
echo -e "${CYAN}>>> Enabling essential services...${RESET}"
sudo systemctl enable NetworkManager
sudo systemctl enable libvirtd
sudo systemctl start NetworkManager
sudo systemctl start libvirtd

echo -e "${CYAN}>>> Configuring virtualization (libvirt)...${RESET}"
sudo usermod -aG libvirt "$USER"
sudo usermod -aG kvm "$USER"
sudo virsh net-start default || true
sudo virsh net-autostart default || true

# ============================================================
# 6. DOCKER — skip if docker-ce already present
# ============================================================
if $DOCKER_PRESENT; then
  echo -e "${YELLOW}>>> Docker already installed — skipping repo setup & install.${RESET}"
else
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
fi
sudo groupadd docker || true
sudo usermod -aG docker "$USER"

# ============================================================
# 7. OH MY ZSH — idempotent
# ============================================================
echo -e "${CYAN}>>> Setting Zsh as default shell and installing Oh My Zsh...${RESET}"
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi
if $OMZ_PRESENT; then
  echo -e "${YELLOW}Oh My Zsh already installed, skipping.${RESET}"
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ============================================================
# 8. FLATPAK — remote idempotent, per-app check
# ============================================================
echo -e "${CYAN}>>> Setting up Flatpak + Flathub...${RESET}"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# NOTE: Flatpak apps NOT auto-installed — run ./install-apps.sh manually when wanted.

# ============================================================
# 9. DOTFILES LINKING — sway-aware, switch-safe, idempotent
#    (handles: fresh link / re-run / moved dotfiles / stale real dirs)
# ============================================================
if [ -d "$DOTDIR" ]; then
  echo -e "${CYAN}>>> Linking dotfiles from $DOTDIR...${RESET}"
  mkdir -p ~/.config

  for d in alacritty cava dunst fastfetch fuzzel gtk-3.0 rofi sway waybar wlogout; do
    link_item "$DOTDIR/.config/$d" "$HOME/.config/$d"
  done

  for f in .fonts .themes .icons .zshrc .p10k.zsh .tmux.conf; do
    link_item "$DOTDIR/$f" "$HOME/$f"
  done
  # NOTE: .Xresources intentionally NOT linked (X11-only)
else
  echo -e "${YELLOW}Dotfiles not found at $DOTDIR — skipping link.${RESET}"
fi

# ============================================================
# 10. FINISHING UP
# ============================================================
sudo apt autoremove -y
echo -e "\n${GREEN}>>> Setup complete!${RESET}"
if [ -n "$CURRENT_DM" ]; then
  echo -e "You can now log out and pick ${YELLOW}sway${RESET} at the $CURRENT_DM login screen."
else
  $INSTALL_DM && echo -e "Reboot → SDDM → pick ${YELLOW}sway${RESET}." \
              || echo -e "Run ${YELLOW}sway${RESET} from a TTY to start."
fi
echo -e "Docker, Flatpak, libvirt, and Oh My Zsh are all configured."
echo -e "If using dotfiles, verify: ${CYAN}$DOTDIR${RESET}"
echo -e "\n→ After re-login, Docker/libvirt groups take effect."
echo -e "→ First sway login: 'swaymsg -t get_outputs' → fix monitor names in ~/.config/sway/config\n"
