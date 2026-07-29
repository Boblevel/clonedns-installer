#!/bin/bash
clear

# ================================================
#        CloneDNS Installer - By Mr RHAFF DIGITAL
#        Telegram : t.me/bigrhaff
# ================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║       CloneDNS Installer v3.0            ║"
echo "  ║         by Mr RHAFF DIGITAL              ║"
echo "  ║         Telegram : t.me/bigrhaff         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ════════════════════════════════════════════════
# AUTO-INSTALLATION COMMANDE GLOBALE
# ════════════════════════════════════════════════

CMD_NAME="cldns"
CMD_PATH="/usr/local/bin/${CMD_NAME}"
SCRIPT_URL="https://raw.githubusercontent.com/Boblevel/clonedns-installer/main/install-cldns.sh"
if [ -z "$CLDNS_UPDATED" ]; then
  curl -fsSL "$SCRIPT_URL" -o "${CMD_PATH}.tmp" 2>/dev/null && mv "${CMD_PATH}.tmp" "$CMD_PATH" 2>/dev/null && chmod +x "$CMD_PATH" 2>/dev/null
  if [ -x "$CMD_PATH" ]; then
    CLDNS_UPDATED=1 exec "$CMD_PATH" "$@"
  fi
fi

# ════════════════════════════════════════════════
# MENU PRINCIPAL
# ════════════════════════════════════════════════

show_menu() {
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║               MENU CloneDNS                ║${NC}"
  echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}  ║${NC}  1) Accueil (état de l'installation)"
  echo -e "${CYAN}  ║${NC}  2) Installer / Configurer un clone SlowDNS"
  echo -e "${CYAN}  ║${NC}  3) Désinstaller CloneDNS (SlowDNS)"
  echo -e "${CYAN}  ║${NC}  4) Rotation automatique tous protocoles (on/off)"
  echo -e "${CYAN}  ║${NC}  5) Installer / Configurer un clone Xray"
  echo -e "${CYAN}  ║${NC}  6) Désinstaller le clone Xray"
  echo -e "${CYAN}  ║${NC}  7) Installer / Configurer un clone WireGuard"
  echo -e "${CYAN}  ║${NC}  8) Désinstaller le(s) clone(s) WireGuard"
  echo -e "${CYAN}  ║${NC}  9) Quitter"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
  echo ""
  read -p "  Choix [1-9] : " MENU_CHOICE
  case "$MENU_CHOICE" in
    1) do_status ;;
    2) do_install ;;
    3) do_uninstall ;;
    4) do_toggle_rotation ;;
    5) do_install_xray ;;
    6) do_uninstall_xray ;;
    7) do_install_wireguard ;;
    8) do_uninstall_wireguard ;;
    9) echo -e "${CYAN}  À bientôt.${NC}"; exit 0 ;;
    *) echo -e "${RED}  Choix invalide.${NC}"; show_menu ;;
  esac
}

do_status() {
  echo ""
  echo -e "${CYAN}  ── Accueil : état de l'installation ──${NC}"
  echo ""
  EXISTING=$(systemctl list-units --full --all 2>/dev/null \
    | grep 'server-cldns' | awk '{print $1}')
  if [ -z "$EXISTING" ]; then
    echo -e "${YELLOW}  Aucune installation CloneDNS détectée sur ce serveur.${NC}"
    echo ""
    echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
    echo ""
    return
  fi
  for SVC in $EXISTING; do
    UNIT_FILE="/etc/systemd/system/${SVC}"
    SVC_STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
    EXEC_LINE=$(grep '^ExecStart=' "$UNIT_FILE" 2>/dev/null)
    SVC_PORT=$(echo "$SVC" | grep -oP '(?<=server-cldns-)[0-9]+')
    SVC_NS=$(echo "$EXEC_LINE" | grep -oP 'ns[\w.-]+\.[a-z]{2,}' | head -1)
    SVC_SSH=$(echo "$EXEC_LINE" | grep -oP '(?<=127\.0\.0\.1:)[0-9]+')
    if [ "$SVC_STATUS" = "active" ]; then
      SVC_COLOR="${GREEN}"; SVC_LABEL="ACTIF"
    else
      SVC_COLOR="${RED}"; SVC_LABEL="INACTIF"
    fi
    echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}  ║${NC}  Service      : ${SVC}"
    echo -e "${CYAN}  ║${NC}  Statut       : ${SVC_COLOR}${SVC_LABEL}${NC}"
    echo -e "${CYAN}  ║${NC}  Port DNS     : ${SVC_PORT}"
    echo -e "${CYAN}  ║${NC}  Nameserver   : ${SVC_NS}"
    echo -e "${CYAN}  ║${NC}  Port SSH     : ${SVC_SSH}"
    echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
    echo ""
  done
  echo -e "${CYAN}  ── Xray ──${NC}"
  XRAY_CONF="/usr/local/etc/xray/config.json"
  if systemctl is-active --quiet xray.service 2>/dev/null; then
    echo -e "  Service xray.service : ${GREEN}ACTIF${NC}"
    if command -v jq >/dev/null 2>&1 && [ -f "$XRAY_CONF" ]; then
      XCLONE_COUNT=$(jq '[.inbounds[] | select(.tag | endswith("-clone"))] | length' "$XRAY_CONF" 2>/dev/null)
      if [ -n "$XCLONE_COUNT" ] && [ "$XCLONE_COUNT" -gt 0 ] 2>/dev/null; then
        echo -e "  Clone Xray : ${GREEN}installé${NC} (${XCLONE_COUNT} inbounds)"
      else
        echo -e "  Clone Xray : ${YELLOW}non installé${NC}"
      fi
    fi
  else
    echo -e "  Service xray.service : ${RED}introuvable ou inactif${NC}"
  fi
  echo ""
  echo -e "${CYAN}  ── WireGuard ──${NC}"
  WG_CLONE_COUNT=0
  for WGCONF in /etc/wireguard/wg*.conf; do
    [ -f "$WGCONF" ] || continue
    WGIFACE=$(basename "$WGCONF" .conf)
    [ "$WGIFACE" = "wg0" ] && continue
    WG_CLONE_COUNT=$((WG_CLONE_COUNT+1))
  done
  if [ -f /etc/wireguard/wg0.conf ]; then
    if [ "$WG_CLONE_COUNT" -gt 0 ]; then
      echo -e "  wg0 (original) présent, ${GREEN}${WG_CLONE_COUNT} clone(s)${NC} installé(s)"
    else
      echo -e "  wg0 (original) présent, ${YELLOW}aucun clone${NC}"
    fi
  else
    echo -e "  ${RED}WireGuard non installé${NC}"
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

do_install_xray() {
  echo ""
  echo -e "${CYAN}  ── Configuration clone Xray ──${NC}"
  echo -e "${CYAN}  (Appuyez sur Entrée pour garder la valeur par défaut)${NC}"
  echo ""

  XRAY_CONF="/usr/local/etc/xray/config.json"
  if [ ! -f "$XRAY_CONF" ]; then
    echo -e "${RED}  ✗ Config Xray introuvable (${XRAY_CONF}). Installation annulée.${NC}"
    echo ""
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${YELLOW}  jq requis, installation...${NC}"
    apt install -y jq >/dev/null 2>&1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${RED}  ✗ Impossible d'installer jq. Installation annulée.${NC}"
    echo ""
    return
  fi

  read -p "  Port de départ pour le clone [défaut: 9080] : " XBASE
  XBASE=${XBASE:-9080}
  XVMESS_PORT=$XBASE
  XVLESS_PORT=$((XBASE+1))
  XTROJAN_PORT=$((XBASE+2))
  XSS_PORT=$((XBASE+3))

  XVMESS_UUID=$(/usr/local/bin/xray uuid)
  XVLESS_UUID=$(/usr/local/bin/xray uuid)
  XSS_PASS=$(openssl rand -base64 32)

  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║           RÉSUMÉ CLONE XRAY              ║${NC}"
  echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}  ║${NC}  VMess   : port ${XVMESS_PORT}"
  echo -e "${CYAN}  ║${NC}  VLess   : port ${XVLESS_PORT}"
  echo -e "${CYAN}  ║${NC}  Trojan  : port ${XTROJAN_PORT}"
  echo -e "${CYAN}  ║${NC}  SS      : port ${XSS_PORT}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
  echo ""
  read -p "  Confirmer l'installation ? (o/n) [défaut: o] : " XCONFIRM
  XCONFIRM=${XCONFIRM:-o}
  if [ "$XCONFIRM" != "o" ] && [ "$XCONFIRM" != "O" ]; then
    echo -e "${YELLOW}  Installation annulée.${NC}"
    echo ""
    return
  fi

  XBACKUP="${XRAY_CONF}.bak-$(date +%Y%m%d%H%M%S)"
  cp "$XRAY_CONF" "$XBACKUP"

  NEW_INBOUNDS=$(cat <<EOF
[
  {
    "tag": "vmess-in-clone",
    "port": ${XVMESS_PORT},
    "protocol": "vmess",
    "settings": { "clients": [ { "id": "${XVMESS_UUID}", "alterId": 0, "email": "clone" } ] },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } }
  },
  {
    "tag": "vless-in-clone",
    "port": ${XVLESS_PORT},
    "protocol": "vless",
    "settings": { "clients": [ { "id": "${XVLESS_UUID}", "email": "clone" } ], "decryption": "none" },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } }
  },
  {
    "tag": "trojan-in-clone",
    "port": ${XTROJAN_PORT},
    "protocol": "trojan",
    "settings": { "clients": [ { "password": "${XSS_PASS}", "email": "clone" } ] },
    "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } }
  },
  {
    "tag": "ss-in-clone",
    "port": ${XSS_PORT},
    "protocol": "shadowsocks",
    "settings": { "method": "2022-blake3-aes-256-gcm", "password": "${XSS_PASS}", "clients": [], "network": "tcp,udp" }
  }
]
EOF
)

  XRAY_TMP="${XRAY_CONF%.json}.tmp.json"
  jq --argjson new "$NEW_INBOUNDS" '.inbounds |= (map(select((.tag | endswith("-clone")) | not)) + $new)' "$XRAY_CONF" > "$XRAY_TMP" 2>/dev/null

  if [ ! -s "$XRAY_TMP" ]; then
    echo -e "${RED}  ✗ Échec de la fusion JSON. Aucune modification appliquée.${NC}"
    rm -f "$XRAY_TMP"
    echo ""
    return
  fi

  XTEST_OUTPUT=$(/usr/local/bin/xray run -test -c "$XRAY_TMP" 2>&1)
  XTEST_STATUS=$?
  if [ "$XTEST_STATUS" -ne 0 ]; then
    echo -e "${RED}  ✗ Config invalide selon Xray. Aucune modification appliquée (sauvegarde intacte : ${XBACKUP}).${NC}"
    echo -e "${YELLOW}  Détail retourné par Xray :${NC}"
    echo "$XTEST_OUTPUT"
    rm -f "$XRAY_TMP"
    echo ""
    return
  fi

  mv "$XRAY_TMP" "$XRAY_CONF"
  systemctl restart xray.service
  sleep 1

  if systemctl is-active --quiet xray.service; then
    echo ""
    echo -e "${GREEN}  ✅ Clone Xray activé.${NC}"
    echo -e "${CYAN}  Sauvegarde de l'ancienne config : ${XBACKUP}${NC}"
    echo ""
    echo -e "${CYAN}  ── Identifiants clone ──${NC}"
    echo -e "  VMess  UUID : ${XVMESS_UUID}  (port ${XVMESS_PORT}, ws /vmess)"
    echo -e "  VLess  UUID : ${XVLESS_UUID}  (port ${XVLESS_PORT}, ws /vless)"
    echo -e "  Trojan mot de passe : ${XSS_PASS}  (port ${XTROJAN_PORT}, ws /trojan)"
    echo -e "  Shadowsocks mot de passe : ${XSS_PASS}  (port ${XSS_PORT}, méthode 2022-blake3-aes-256-gcm)"
  else
    echo -e "${RED}  ✗ xray.service ne démarre pas avec la nouvelle config. Restauration...${NC}"
    cp "$XBACKUP" "$XRAY_CONF"
    systemctl restart xray.service
    echo -e "${YELLOW}  Config restaurée, aucun changement conservé.${NC}"
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

do_uninstall_xray() {
  echo ""
  XRAY_CONF="/usr/local/etc/xray/config.json"
  if [ ! -f "$XRAY_CONF" ]; then
    echo -e "${CYAN}  Config Xray introuvable.${NC}"
    echo ""
    return
  fi
  if ! command -v jq >/dev/null 2>&1; then
    apt install -y jq >/dev/null 2>&1
  fi
  HAS_CLONE=$(jq '[.inbounds[] | select(.tag | endswith("-clone"))] | length' "$XRAY_CONF" 2>/dev/null)
  if [ -z "$HAS_CLONE" ] || [ "$HAS_CLONE" = "0" ]; then
    echo -e "${CYAN}  Aucun clone Xray installé.${NC}"
    echo ""
    echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
    echo ""
    return
  fi
  XBACKUP="${XRAY_CONF}.bak-$(date +%Y%m%d%H%M%S)"
  cp "$XRAY_CONF" "$XBACKUP"
  XRAY_TMP="${XRAY_CONF%.json}.tmp.json"
  jq '.inbounds |= map(select((.tag | endswith("-clone")) | not))' "$XRAY_CONF" > "$XRAY_TMP" 2>/dev/null
  if [ ! -s "$XRAY_TMP" ]; then
    echo -e "${RED}  ✗ Échec de la suppression. Aucune modification appliquée.${NC}"
    rm -f "$XRAY_TMP"
    echo ""
    return
  fi
  mv "$XRAY_TMP" "$XRAY_CONF"
  systemctl restart xray.service
  sleep 1
  if systemctl is-active --quiet xray.service; then
    echo -e "${GREEN}  ✅ Clone Xray désinstallé.${NC}"
  else
    echo -e "${RED}  ✗ xray.service ne redémarre pas. Restauration de la sauvegarde...${NC}"
    cp "$XBACKUP" "$XRAY_CONF"
    systemctl restart xray.service
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

do_install_wireguard() {
  echo ""
  echo -e "${CYAN}  ── Configuration clone WireGuard ──${NC}"
  echo -e "${CYAN}  (Appuyez sur Entrée pour garder la valeur par défaut)${NC}"
  echo ""

  WG_BASE_CONF="/etc/wireguard/wg0.conf"
  if [ ! -f "$WG_BASE_CONF" ]; then
    echo -e "${RED}  ✗ Config WireGuard de base introuvable (${WG_BASE_CONF}). Installation annulée.${NC}"
    echo ""
    return
  fi
  if ! command -v wg >/dev/null 2>&1; then
    echo -e "${RED}  ✗ wg introuvable. Installation annulée.${NC}"
    echo ""
    return
  fi

  WG_OUT_IF=$(grep -oP '(?<=-o )[a-zA-Z0-9]+' "$WG_BASE_CONF" | head -1)
  WG_OUT_IF=${WG_OUT_IF:-eth0}

  WG_NUM=1
  while [ -f "/etc/wireguard/wg${WG_NUM}.conf" ]; do
    WG_NUM=$((WG_NUM+1))
  done
  WG_IFACE="wg${WG_NUM}"

  read -p "  Port WireGuard pour le clone [défaut: 51821] : " WG_PORT
  WG_PORT=${WG_PORT:-51821}

  read -p "  Sous-réseau du clone [défaut: 10.66.$((66+WG_NUM)).1/24] : " WG_SUBNET
  WG_SUBNET=${WG_SUBNET:-10.66.$((66+WG_NUM)).1/24}

  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║          RÉSUMÉ CLONE WIREGUARD          ║${NC}"
  echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}  ║${NC}  Interface   : ${WG_IFACE}"
  echo -e "${CYAN}  ║${NC}  Port        : ${WG_PORT}"
  echo -e "${CYAN}  ║${NC}  Sous-réseau : ${WG_SUBNET}"
  echo -e "${CYAN}  ║${NC}  Sortie      : ${WG_OUT_IF}"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
  echo ""
  read -p "  Confirmer l'installation ? (o/n) [défaut: o] : " WG_CONFIRM
  WG_CONFIRM=${WG_CONFIRM:-o}
  if [ "$WG_CONFIRM" != "o" ] && [ "$WG_CONFIRM" != "O" ]; then
    echo -e "${YELLOW}  Installation annulée.${NC}"
    echo ""
    return
  fi

  WG_PRIV=$(wg genkey)
  WG_PUB=$(echo "$WG_PRIV" | wg pubkey)

  cat > "/etc/wireguard/${WG_IFACE}.conf" << UNIT
[Interface]
Address = ${WG_SUBNET}
ListenPort = ${WG_PORT}
PrivateKey = ${WG_PRIV}
PostUp = iptables -A FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WG_OUT_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${WG_IFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WG_OUT_IF} -j MASQUERADE
UNIT
  chmod 600 "/etc/wireguard/${WG_IFACE}.conf"

  systemctl enable --now "wg-quick@${WG_IFACE}" >/dev/null 2>&1
  sleep 1

  if systemctl is-active --quiet "wg-quick@${WG_IFACE}"; then
    echo ""
    echo -e "${GREEN}  ✅ Clone WireGuard activé : ${WG_IFACE}${NC}"
    echo ""
    echo -e "${CYAN}  ── Infos serveur (à mettre dans la config client) ──${NC}"
    echo -e "  Clé publique serveur : ${WG_PUB}"
    echo -e "  Port                 : ${WG_PORT}"
    echo -e "  Sous-réseau          : ${WG_SUBNET}"
  else
    echo -e "${RED}  ✗ ${WG_IFACE} ne démarre pas. Suppression du fichier de config.${NC}"
    rm -f "/etc/wireguard/${WG_IFACE}.conf"
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

do_uninstall_wireguard() {
  echo ""
  echo -e "${YELLOW}  Recherche des clones WireGuard...${NC}"
  WG_FOUND=0
  for WGCONF in /etc/wireguard/wg*.conf; do
    [ -f "$WGCONF" ] || continue
    WGIFACE=$(basename "$WGCONF" .conf)
    [ "$WGIFACE" = "wg0" ] && continue
    WG_FOUND=1
    systemctl disable --now "wg-quick@${WGIFACE}" >/dev/null 2>&1
    rm -f "$WGCONF"
    echo -e "${RED}  ✗ Supprimé : ${WGIFACE}${NC}"
  done
  if [ "$WG_FOUND" = "0" ]; then
    echo -e "${CYAN}  Aucun clone WireGuard installé (wg0 n'est jamais touché).${NC}"
  else
    echo -e "${GREEN}  ✅ Clones WireGuard désinstallés.${NC}"
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

do_uninstall() {
  echo ""
  echo -e "${YELLOW}  Recherche des services CloneDNS actifs...${NC}"
  EXISTING=$(systemctl list-units --full --all 2>/dev/null \
    | grep 'server-cldns' | awk '{print $1}')
  if [ -z "$EXISTING" ]; then
    echo -e "${CYAN}  Aucun service CloneDNS installé.${NC}"
    echo ""
    echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
    echo ""
    return
  fi
  for SVC in $EXISTING; do
    systemctl stop "$SVC" &>/dev/null
    systemctl disable "$SVC" &>/dev/null
    rm -f "/etc/systemd/system/${SVC}"
    echo -e "${RED}  ✗ Supprimé : ${SVC}${NC}"
  done
  rm -f /etc/systemd/system/server-cldns*.service
  systemctl daemon-reload
  echo -e "${GREEN}  ✅ CloneDNS désinstallé (tous les services supprimés).${NC}"
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

rotate_cldns() {
  LOG="/var/log/cldns-rotate.log"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotation démarrée" >> "$LOG"

  LAST_SVC=$(systemctl list-units --full --all 2>/dev/null \
    | grep 'server-cldns' | awk '{print $1}' | sort | tail -1)
  if [ -z "$LAST_SVC" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aucun clone existant, rotation annulée." >> "$LOG"
    return
  fi

  LAST_EXEC=$(grep '^ExecStart=' "/etc/systemd/system/${LAST_SVC}" 2>/dev/null)
  R_NS=$(echo "$LAST_EXEC" | grep -oP 'ns[\w.-]+\.[a-z]{2,}' | head -1)
  R_SSH=$(echo "$LAST_EXEC" | grep -oP '(?<=127\.0\.0\.1:)[0-9]+')

  R_SLDNS=""
  for BIN in sldns-server dns-server slowdns sldns; do
    for DIR in /usr/local/bin /usr/bin /root /opt /etc/slowdns /usr/local/sbin; do
      [ -f "${DIR}/${BIN}" ] && R_SLDNS="${DIR}/${BIN}" && break 2
    done
  done
  [ -z "$R_SLDNS" ] && R_SLDNS=$(find / -maxdepth 4 -type f \( -iname "sldns-server" -o -iname "dns-server" -o -iname "slowdns" -o -iname "sldns" \) 2>/dev/null | head -1)

  R_KEY=""
  for DIR in /etc/slowdns /root /usr/local/etc/slowdns "$(dirname "$R_SLDNS" 2>/dev/null)"; do
    [ -f "${DIR}/server.key" ] && R_KEY="${DIR}/server.key" && break
  done
  [ -z "$R_KEY" ] && R_KEY=$(find / -maxdepth 5 -iname "server.key" 2>/dev/null | grep -i slowdns | head -1)

  if [ -z "$R_SLDNS" ] || [ -z "$R_KEY" ] || [ -z "$R_NS" ] || [ -z "$R_SSH" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Infos manquantes (binaire/clé/ns/ssh), rotation annulée." >> "$LOG"
    return
  fi

  R_PORT=""
  for TRY in $(shuf -i 5300-5399 -n 20); do
    if ! ss -tulnp 2>/dev/null | grep -q ":${TRY} "; then
      R_PORT=$TRY
      break
    fi
  done
  if [ -z "$R_PORT" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Aucun port libre trouvé, rotation annulée." >> "$LOG"
    return
  fi

  cat > /etc/systemd/system/server-cldns-${R_PORT}.service << UNIT
[Unit]
Description=CloneDNS by Mr RHAFF DIGITAL (Port ${R_PORT})
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${R_SLDNS} -udp :${R_PORT} -privkey-file ${R_KEY} ${R_NS} 127.0.0.1:${R_SSH}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

  systemctl daemon-reload
  systemctl enable server-cldns-${R_PORT} &>/dev/null
  systemctl restart server-cldns-${R_PORT}

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Nouveau clone créé : port ${R_PORT} (NS: ${R_NS}, SSH: ${R_SSH})" >> "$LOG"

  GRACE_DAYS=5
  NOW=$(date +%s)
  for SVC in $(systemctl list-units --full --all 2>/dev/null | grep 'server-cldns' | awk '{print $1}'); do
    [ "$SVC" = "server-cldns-${R_PORT}.service" ] && continue
    UNIT_FILE="/etc/systemd/system/${SVC}"
    [ -f "$UNIT_FILE" ] || continue
    MTIME=$(stat -c %Y "$UNIT_FILE" 2>/dev/null)
    AGE_DAYS=$(( (NOW - MTIME) / 86400 ))
    if [ "$AGE_DAYS" -ge "$GRACE_DAYS" ]; then
      systemctl stop "$SVC" >/dev/null 2>&1
      systemctl disable "$SVC" >/dev/null 2>&1
      rm -f "$UNIT_FILE"
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ancien clone supprimé (>${GRACE_DAYS}j) : ${SVC}" >> "$LOG"
    fi
  done
  systemctl daemon-reload

  XRAY_CONF="/usr/local/etc/xray/config.json"
  if systemctl is-active --quiet xray.service 2>/dev/null && [ -f "$XRAY_CONF" ] && command -v jq >/dev/null 2>&1; then
    HAS_XCLONE=$(jq '[.inbounds[] | select(.tag | endswith("-clone"))] | length' "$XRAY_CONF" 2>/dev/null)
    if [ -n "$HAS_XCLONE" ] && [ "$HAS_XCLONE" -gt 0 ] 2>/dev/null; then
      RX_VMESS=""
      for TRY in $(shuf -i 9000-9999 -n 30); do
        if ! ss -tulnp 2>/dev/null | grep -q ":${TRY} "; then RX_VMESS=$TRY; break; fi
      done
      if [ -z "$RX_VMESS" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Xray: aucun port libre, rotation annulée." >> "$LOG"
      else
        RX_VLESS=$((RX_VMESS+1))
        RX_TROJAN=$((RX_VMESS+2))
        RX_SS=$((RX_VMESS+3))
        RX_VMESS_UUID=$(/usr/local/bin/xray uuid)
        RX_VLESS_UUID=$(/usr/local/bin/xray uuid)
        RX_SS_PASS=$(openssl rand -base64 32)
        RX_BACKUP="${XRAY_CONF}.bak-$(date +%Y%m%d%H%M%S)"
        cp "$XRAY_CONF" "$RX_BACKUP"
        RX_NEW=$(cat <<EOF
[
  { "tag": "vmess-in-clone", "port": ${RX_VMESS}, "protocol": "vmess", "settings": { "clients": [ { "id": "${RX_VMESS_UUID}", "alterId": 0, "email": "clone" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess" } } },
  { "tag": "vless-in-clone", "port": ${RX_VLESS}, "protocol": "vless", "settings": { "clients": [ { "id": "${RX_VLESS_UUID}", "email": "clone" } ], "decryption": "none" }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/vless" } } },
  { "tag": "trojan-in-clone", "port": ${RX_TROJAN}, "protocol": "trojan", "settings": { "clients": [ { "password": "${RX_SS_PASS}", "email": "clone" } ] }, "streamSettings": { "network": "ws", "wsSettings": { "path": "/trojan" } } },
  { "tag": "ss-in-clone", "port": ${RX_SS}, "protocol": "shadowsocks", "settings": { "method": "2022-blake3-aes-256-gcm", "password": "${RX_SS_PASS}", "clients": [], "network": "tcp,udp" } }
]
EOF
)
        RX_TMP="${XRAY_CONF%.json}.tmp.json"
        jq --argjson new "$RX_NEW" '.inbounds |= (map(select((.tag | endswith("-clone")) | not)) + $new)' "$XRAY_CONF" > "$RX_TMP" 2>/dev/null
        if [ -s "$RX_TMP" ] && /usr/local/bin/xray run -test -c "$RX_TMP" >/dev/null 2>&1; then
          mv "$RX_TMP" "$XRAY_CONF"
          systemctl restart xray.service
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Xray: clone régénéré (ports ${RX_VMESS}-${RX_SS})" >> "$LOG"
        else
          rm -f "$RX_TMP"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Xray: échec de la rotation, config inchangée." >> "$LOG"
        fi
      fi
    fi
  fi

  if [ -f /etc/wireguard/wg0.conf ] && command -v wg >/dev/null 2>&1; then
    HAS_WGCLONE=0
    for WGCONF in /etc/wireguard/wg*.conf; do
      [ -f "$WGCONF" ] || continue
      [ "$(basename "$WGCONF" .conf)" = "wg0" ] && continue
      HAS_WGCLONE=1
    done
    if [ "$HAS_WGCLONE" = "1" ]; then
      RW_OUT_IF=$(grep -oP '(?<=-o )[a-zA-Z0-9]+' /etc/wireguard/wg0.conf | head -1)
      RW_OUT_IF=${RW_OUT_IF:-eth0}
      RW_NUM=1
      while [ -f "/etc/wireguard/wg${RW_NUM}.conf" ]; do RW_NUM=$((RW_NUM+1)); done
      RW_IFACE="wg${RW_NUM}"
      RW_PORT=""
      for TRY in $(shuf -i 51900-51999 -n 30); do
        if ! ss -tulnp 2>/dev/null | grep -q ":${TRY} "; then RW_PORT=$TRY; break; fi
      done
      if [ -n "$RW_PORT" ]; then
        RW_PRIV=$(wg genkey)
        cat > "/etc/wireguard/${RW_IFACE}.conf" << UNIT
[Interface]
Address = 10.66.$((66+RW_NUM)).1/24
ListenPort = ${RW_PORT}
PrivateKey = ${RW_PRIV}
PostUp = iptables -A FORWARD -i ${RW_IFACE} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${RW_OUT_IF} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${RW_IFACE} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${RW_OUT_IF} -j MASQUERADE
UNIT
        chmod 600 "/etc/wireguard/${RW_IFACE}.conf"
        systemctl enable --now "wg-quick@${RW_IFACE}" >/dev/null 2>&1
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] WireGuard: nouveau clone ${RW_IFACE} (port ${RW_PORT})" >> "$LOG"

        RW_GRACE=5
        RW_NOW=$(date +%s)
        for WGCONF in /etc/wireguard/wg*.conf; do
          [ -f "$WGCONF" ] || continue
          WGIFACE=$(basename "$WGCONF" .conf)
          [ "$WGIFACE" = "wg0" ] && continue
          [ "$WGIFACE" = "$RW_IFACE" ] && continue
          WGMTIME=$(stat -c %Y "$WGCONF" 2>/dev/null)
          WGAGE=$(( (RW_NOW - WGMTIME) / 86400 ))
          if [ "$WGAGE" -ge "$RW_GRACE" ]; then
            systemctl disable --now "wg-quick@${WGIFACE}" >/dev/null 2>&1
            rm -f "$WGCONF"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WireGuard: ancien clone supprimé (>${RW_GRACE}j) : ${WGIFACE}" >> "$LOG"
          fi
        done
      fi
    fi
  fi

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rotation terminée" >> "$LOG"
}

do_toggle_rotation() {
  echo ""
  TIMER_FILE="/etc/systemd/system/cldns-rotate.timer"
  SERVICE_FILE="/etc/systemd/system/cldns-rotate.service"
  if systemctl is-enabled cldns-rotate.timer >/dev/null 2>&1; then
    systemctl disable --now cldns-rotate.timer >/dev/null 2>&1
    rm -f "$TIMER_FILE" "$SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${YELLOW}  Rotation automatique désactivée.${NC}"
  else
    cat > "$SERVICE_FILE" << UNIT
[Unit]
Description=Rotation automatique CloneDNS

[Service]
Type=oneshot
ExecStart=${CMD_PATH} --rotate
UNIT
    cat > "$TIMER_FILE" << UNIT
[Unit]
Description=Timer rotation CloneDNS (tous les 15 jours)

[Timer]
OnBootSec=10min
OnUnitActiveSec=15d
Persistent=true

[Install]
WantedBy=timers.target
UNIT
    systemctl daemon-reload
    systemctl enable --now cldns-rotate.timer >/dev/null 2>&1
    echo -e "${GREEN}  ✅ Rotation automatique activée : SlowDNS, Xray et WireGuard régénérés tous les 15 jours (uniquement ceux déjà installés).${NC}"
    echo -e "${CYAN}  SlowDNS et WireGuard gardent l'ancien clone 5 jours en transition. Xray est remplacé immédiatement (pas de période de transition sur ce protocole).${NC}"
    echo -e "${CYAN}  Log : /var/log/cldns-rotate.log${NC}"
  fi
  echo ""
  echo -e "${CYAN}  Tape ${YELLOW}${CMD_NAME}${CYAN} pour revenir au menu.${NC}"
  echo ""
}

# ════════════════════════════════════════════════
# SCAN UNIVERSEL SILENCIEUX
# ════════════════════════════════════════════════

do_install() {

SLDNS=""
KEY=""
PUB=""
DETECTED_NS=""
DETECTED_SSH_PORT=""

# ── 1. Chercher le binaire DNS ────────────────────
BINARY_NAMES=("sldns-server" "dns-server" "slowdns" "sldns")
BINARY_PATHS=(
  "/etc/slowdns"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/opt/slowdns"
  "/root"
  "/usr/local/sbin"
  "/usr/sbin"
  "/sbin"
)

for BIN in "${BINARY_NAMES[@]}"; do
  for DIR in "${BINARY_PATHS[@]}"; do
    if [ -f "${DIR}/${BIN}" ] && [ -x "${DIR}/${BIN}" ]; then
      SLDNS="${DIR}/${BIN}"
      break 2
    fi
  done
done

# Recherche globale si pas trouvé
if [ -z "$SLDNS" ]; then
  for BIN in "${BINARY_NAMES[@]}"; do
    FOUND=$(find / -name "$BIN" -type f -executable 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
      SLDNS="$FOUND"
      break
    fi
  done
fi

# ── 2. Chercher server.key ────────────────────────
KEY_PATHS=(
  "/etc/slowdns/server.key"
  "/usr/local/etc/server.key"
  "/etc/adm-lite/slow/dnsi/server.key"
  "/opt/slowdns/server.key"
  "/root/server.key"
  "$(dirname $SLDNS 2>/dev/null)/server.key"
)

for K in "${KEY_PATHS[@]}"; do
  if [ -f "$K" ]; then
    KEY="$K"
    break
  fi
done

if [ -z "$KEY" ]; then
  KEY=$(find / -name "server.key" -type f 2>/dev/null | grep -i "slow\|dns\|adm" | head -1)
  [ -z "$KEY" ] && KEY=$(find / -name "server.key" -type f 2>/dev/null | head -1)
fi

# ── 3. Chercher server.pub ────────────────────────
PUB_PATHS=(
  "/etc/slowdns/server.pub"
  "/usr/local/etc/server.pub"
  "/etc/adm-lite/slow/dnsi/server.pub"
  "/opt/slowdns/server.pub"
  "/root/server.pub"
  "$(dirname $KEY 2>/dev/null)/server.pub"
)

for P in "${PUB_PATHS[@]}"; do
  if [ -f "$P" ]; then
    PUB="$P"
    break
  fi
done

if [ -z "$PUB" ]; then
  PUB=$(find / -name "server.pub" -type f 2>/dev/null | grep -i "slow\|dns\|adm" | head -1)
  [ -z "$PUB" ] && PUB=$(find / -name "server.pub" -type f 2>/dev/null | head -1)
fi

# ── 4. Détecter Nameserver ────────────────────────

# Depuis fichiers dédiés
NS_FILES=(
  "/etc/adm-lite/slow/dnsi/domain_ns"
  "/etc/slowdns/domain_ns"
  "/opt/slowdns/domain_ns"
)
for NSF in "${NS_FILES[@]}"; do
  if [ -f "$NSF" ]; then
    NS_TRY=$(cat "$NSF" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$NS_TRY" ] && echo "$NS_TRY" | grep -qP '^ns[\w.-]+\.[a-z]{2,}$'; then
      DETECTED_NS="$NS_TRY"
      break
    fi
  fi
done

# Depuis fichiers service systemd
if [ -z "$DETECTED_NS" ]; then
  for SVC_FILE in /etc/systemd/system/server-sldns*.service \
                  /etc/systemd/system/*slow*.service \
                  /etc/systemd/system/*dns*.service; do
    if [ -f "$SVC_FILE" ]; then
      NS_TRY=$(grep -oP 'ns[\w.-]+\.[a-z]{2,}' "$SVC_FILE" 2>/dev/null \
               | grep -v 'nss-lookup' \
               | grep -v 'nss-' \
               | head -1)
      if [ -n "$NS_TRY" ]; then
        DETECTED_NS="$NS_TRY"
        break
      fi
    fi
  done
fi

# Depuis les process actifs en mémoire
if [ -z "$DETECTED_NS" ]; then
  DETECTED_NS=$(ps aux 2>/dev/null \
    | grep -oP 'ns[\w.-]+\.[a-z]{2,}' \
    | grep -v 'nss-lookup' \
    | grep -v 'nss-' \
    | grep -v grep \
    | head -1)
fi

# Depuis ExecStart des services systemd (méthode directe)
if [ -z "$DETECTED_NS" ]; then
  DETECTED_NS=$(grep -rh "ExecStart" /etc/systemd/system/ 2>/dev/null \
    | grep -i "dns\|slow\|sldns" \
    | grep -oP 'ns[\w.-]+\.[a-z]{2,}' \
    | grep -v 'nss-lookup' \
    | grep -v 'nss-' \
    | head -1)
fi

# ── 5. Détecter Port SSH SlowDNS ──────────────────

# Depuis fichiers dédiés
SSH_PORT_FILES=(
  "/etc/adm-lite/slow/dnsi/puerto"
  "/etc/slowdns/puerto"
  "/opt/slowdns/puerto"
)
for SPF in "${SSH_PORT_FILES[@]}"; do
  if [ -f "$SPF" ]; then
    SP_TRY=$(cat "$SPF" 2>/dev/null | tr -d '[:space:]')
    if echo "$SP_TRY" | grep -qP '^\d+$'; then
      DETECTED_SSH_PORT="$SP_TRY"
      break
    fi
  fi
done

# Depuis fichiers service systemd
if [ -z "$DETECTED_SSH_PORT" ]; then
  for SVC_FILE in /etc/systemd/system/server-sldns*.service \
                  /etc/systemd/system/*slow*.service; do
    if [ -f "$SVC_FILE" ]; then
      SP_TRY=$(grep -oP '127\.0\.0\.1:\K[0-9]+' "$SVC_FILE" 2>/dev/null | head -1)
      if [ -n "$SP_TRY" ]; then
        DETECTED_SSH_PORT="$SP_TRY"
        break
      fi
    fi
  done
fi

# Depuis les process actifs
if [ -z "$DETECTED_SSH_PORT" ]; then
  DETECTED_SSH_PORT=$(ps aux 2>/dev/null \
    | grep -i "dns\|slow\|sldns" \
    | grep -oP '127\.0\.0\.1:\K[0-9]+' \
    | grep -v grep \
    | head -1)
fi

# Depuis ExecStart global
if [ -z "$DETECTED_SSH_PORT" ]; then
  DETECTED_SSH_PORT=$(grep -rh "ExecStart" /etc/systemd/system/ 2>/dev/null \
    | grep -i "dns\|slow\|sldns" \
    | grep -oP '127\.0\.0\.1:\K[0-9]+' \
    | head -1)
fi

# ── Vérification binaire obligatoire ─────────────
if [ -z "$SLDNS" ] || [ -z "$KEY" ]; then
  echo -e "${RED}  ❌ ERREUR : SlowDNS introuvable sur ce serveur.${NC}"
  echo -e "${RED}  Assurez-vous que SlowDNS est installé avant CloneDNS.${NC}"
  exit 1
fi

# ════════════════════════════════════════════════
# CONFIGURATION
# ════════════════════════════════════════════════

echo ""
echo -e "${BOLD}  ── Configuration CloneDNS ──${NC}"
echo -e "${CYAN}  (Appuyez sur Entrée pour garder la valeur par défaut)${NC}"
echo ""

# ── Port DNS ──────────────────────────────────────
read -p "  Port DNS UDP [défaut: 5301] : " DNS_PORT
DNS_PORT=${DNS_PORT:-5301}

# ── Port SSH ──────────────────────────────────────
echo ""
echo -e "${YELLOW}  Ports SSH disponibles sur ce serveur :${NC}"
ss -tulnp | grep tcp | grep -v '127.0.0' | grep -v '\[::1\]' \
  | awk '{print "  →", $5}' | sort -u 2>/dev/null
echo ""
DEFAULT_SSH=${DETECTED_SSH_PORT:-2253}
read -p "  Port SSH backend [défaut: ${DEFAULT_SSH}] : " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_SSH}

# ── Nameserver ────────────────────────────────────
echo ""
if [ -n "$DETECTED_NS" ]; then
  echo -e "${YELLOW}  Nameserver détecté sur ce serveur :${NC} ${GREEN}${DETECTED_NS}${NC}"
else
  echo -e "${YELLOW}  Aucun Nameserver détecté automatiquement.${NC}"
fi

echo ""
echo -e "${RED}  ⚠  Le Nameserver est OBLIGATOIRE — saisissez le vôtre.${NC}"
echo -e "${CYAN}  ex: ns-mr.rhaffservixxxxx${NC}"
echo ""

NS_DOMAIN=""
while [ -z "$NS_DOMAIN" ]; do
  IFS= read -r -p "  Nameserver NS (obligatoire) : " NS_DOMAIN
  NS_DOMAIN=$(echo "$NS_DOMAIN" | tr -d '[:space:]')
  if [ -z "$NS_DOMAIN" ]; then
    echo -e "${RED}  ❌ Le Nameserver ne peut pas être vide !${NC}"
    echo -e "${CYAN}  ex: ns-mr.rhaffservixxxxx${NC}"
  fi
done

# ════════════════════════════════════════════════
# RÉSUMÉ ET CONFIRMATION
# ════════════════════════════════════════════════

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║           RÉSUMÉ CONFIGURATION           ║${NC}"
echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
echo -e "${CYAN}  ║${NC}  Port DNS    : ${YELLOW}${DNS_PORT}${NC}"
echo -e "${CYAN}  ║${NC}  Port SSH    : ${YELLOW}${SSH_PORT}${NC}"
echo -e "${CYAN}  ║${NC}  Nameserver  : ${YELLOW}${NS_DOMAIN}${NC}"
echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
echo ""
read -p "  Confirmer l'installation ? (o/n) [défaut: o] : " CONFIRM
CONFIRM=${CONFIRM:-o}

if [[ "$CONFIRM" != "o" && "$CONFIRM" != "O" ]]; then
  echo -e "${RED}  Installation annulée.${NC}"
  exit 0
fi

# ════════════════════════════════════════════════
# NETTOYAGE ANCIENS SERVICES
# ════════════════════════════════════════════════

echo ""
echo -e "${YELLOW}  Nettoyage des anciens services CloneDNS...${NC}"
EXISTING=$(systemctl list-units --full --all 2>/dev/null \
  | grep 'server-cldns' | awk '{print $1}')
if [ -n "$EXISTING" ]; then
  for SVC in $EXISTING; do
    systemctl stop "$SVC" &>/dev/null
    systemctl disable "$SVC" &>/dev/null
    rm -f "/etc/systemd/system/${SVC}"
    echo -e "${RED}  ✗ Supprimé : ${SVC}${NC}"
  done
  rm -f /etc/systemd/system/server-cldns*.service
  systemctl daemon-reload
  echo -e "${GREEN}  ✅ Anciens services supprimés.${NC}"
else
  echo -e "${CYAN}  Aucun service existant trouvé.${NC}"
fi
echo ""

# ════════════════════════════════════════════════
# CRÉATION ET ACTIVATION DU SERVICE
# ════════════════════════════════════════════════

cat > /etc/systemd/system/server-cldns-${DNS_PORT}.service << UNIT
[Unit]
Description=CloneDNS by Mr RHAFF DIGITAL (Port ${DNS_PORT})
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${SLDNS} -udp :${DNS_PORT} -privkey-file ${KEY} ${NS_DOMAIN} 127.0.0.1:${SSH_PORT}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable server-cldns-${DNS_PORT} &>/dev/null
systemctl restart server-cldns-${DNS_PORT}

sleep 2

# ════════════════════════════════════════════════
# VÉRIFICATION FINALE
# ════════════════════════════════════════════════

STATUS=$(systemctl is-active server-cldns-${DNS_PORT})
PUBKEY=$(cat ${PUB} 2>/dev/null || echo "Introuvable")

echo ""
if [ "$STATUS" = "active" ]; then
  echo -e "${GREEN}"
  echo "  ╔══════════════════════════════════════════╗"
  echo "  ║    ✅ CloneDNS ACTIVÉ AVEC SUCCÈS !      ║"
  echo "  ╠══════════════════════════════════════════╣"
  echo -e "  ║${NC}  Port DNS    : ${YELLOW}${DNS_PORT}${GREEN}"
  echo -e "  ║${NC}  Port SSH    : ${YELLOW}${SSH_PORT}${GREEN}"
  echo -e "  ║${NC}  Nameserver  : ${YELLOW}${NS_DOMAIN}${GREEN}"
  echo -e "  ║${NC}  Pubkey      : ${YELLOW}${PUBKEY}${GREEN}"
  echo "  ╠══════════════════════════════════════════╣"
  echo "  ║    by Mr RHAFF DIGITAL                   ║"
  echo "  ║    Telegram : t.me/bigrhaff              ║"
  echo -e "  ╚══════════════════════════════════════════╝${NC}"
else
  echo -e "${RED}  ❌ Erreur : CloneDNS ne s'est pas démarré.${NC}"
  echo -e "${YELLOW}  Consultez les logs :${NC}"
  echo "  journalctl -u server-cldns-${DNS_PORT} -n 20 --no-pager"
fi

echo ""
echo -e "${CYAN}  ── Commandes utiles ──${NC}"
echo ""
echo -e "  ${YELLOW}▶ Voir si le service est actif ou en erreur :${NC}"
echo "    systemctl status server-cldns-${DNS_PORT} --no-pager"
echo ""
echo -e "  ${YELLOW}▶ Lire les logs pour diagnostiquer un problème :${NC}"
echo "    journalctl -u server-cldns-${DNS_PORT} -n 20 --no-pager"
echo ""
echo -e "  ${YELLOW}▶ Confirmer que le port écoute bien sur le réseau :${NC}"
echo "    ss -tulnp | grep ${DNS_PORT}"
echo ""
echo -e "  ${YELLOW}▶ Redémarrer après une modification de config :${NC}"
echo "    systemctl restart server-cldns-${DNS_PORT}"
echo ""
echo -e "  ${YELLOW}▶ Arrêter temporairement CloneDNS :${NC}"
echo "    systemctl stop server-cldns-${DNS_PORT}"
echo ""
echo -e "  ${YELLOW}▶ Empêcher le démarrage automatique au boot :${NC}"
echo "    systemctl disable server-cldns-${DNS_PORT}"
echo ""
echo -e "  ${YELLOW}▶ Mettre à jour le système du serveur :${NC}"
echo "    apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y && apt clean"
echo ""
echo -e "  ${YELLOW}▶ Revenir à ce menu :${NC}"
echo "    ${CMD_NAME}"
echo ""

}

# ════════════════════════════════════════════════
# LANCEMENT
# ════════════════════════════════════════════════

if [ "$1" = "--rotate" ]; then
  rotate_cldns
else
  show_menu
fi
