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
if ! command -v "$CMD_NAME" >/dev/null 2>&1; then
  curl -fsSL "$SCRIPT_URL" -o "${CMD_PATH}.tmp" 2>/dev/null && mv "${CMD_PATH}.tmp" "$CMD_PATH" 2>/dev/null && chmod +x "$CMD_PATH" 2>/dev/null
fi

# ════════════════════════════════════════════════
# MENU PRINCIPAL
# ════════════════════════════════════════════════

show_menu() {
  echo ""
  echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}  ║               MENU CloneDNS                ║${NC}"
  echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}  ║${NC}  1) Installer / Configurer un clone"
  echo -e "${CYAN}  ║${NC}  2) Désinstaller CloneDNS"
  echo -e "${CYAN}  ║${NC}  3) Quitter"
  echo -e "${CYAN}  ╚══════════════════════════════════════════╝${NC}"
  echo ""
  read -p "  Choix [1-3] : " MENU_CHOICE
  case "$MENU_CHOICE" in
    1) do_install ;;
    2) do_uninstall ;;
    3) echo -e "${CYAN}  À bientôt.${NC}"; exit 0 ;;
    *) echo -e "${RED}  Choix invalide.${NC}"; show_menu ;;
  esac
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

show_menu
