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
echo "  ║       CloneDNS Installer v2.0            ║"
echo "  ║         by Mr RHAFF DIGITAL              ║"
echo "  ║         Telegram : t.me/bigrhaff         ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ════════════════════════════════════════════════
# DÉTECTION UNIVERSELLE AUTOMATIQUE
# ════════════════════════════════════════════════

echo -e "${YELLOW}  🔍 Détection automatique du système...${NC}"

SLDNS=""
KEY=""
PUB=""
DETECTED_NS=""
DETECTED_SSH_PORT=""

# ── Chercher le binaire DNS server ───────────────
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

# Si pas trouvé dans les chemins connus → find global
if [ -z "$SLDNS" ]; then
  for BIN in "${BINARY_NAMES[@]}"; do
    FOUND=$(find / -name "$BIN" -type f -executable 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
      SLDNS="$FOUND"
      break
    fi
  done
fi

# ── Chercher server.key ───────────────────────────
KEY_SEARCH_PATHS=(
  "/etc/slowdns/server.key"
  "/usr/local/etc/server.key"
  "/etc/adm-lite/slow/dnsi/server.key"
  "/opt/slowdns/server.key"
  "/root/server.key"
  "$(dirname $SLDNS 2>/dev/null)/server.key"
)

for K in "${KEY_SEARCH_PATHS[@]}"; do
  if [ -f "$K" ]; then
    KEY="$K"
    break
  fi
done

# Si pas trouvé → find global
if [ -z "$KEY" ]; then
  KEY=$(find / -name "server.key" -type f 2>/dev/null | grep -i "slow\|dns\|adm" | head -1)
  if [ -z "$KEY" ]; then
    KEY=$(find / -name "server.key" -type f 2>/dev/null | head -1)
  fi
fi

# ── Chercher server.pub ───────────────────────────
PUB_SEARCH_PATHS=(
  "/etc/slowdns/server.pub"
  "/usr/local/etc/server.pub"
  "/etc/adm-lite/slow/dnsi/server.pub"
  "/opt/slowdns/server.pub"
  "/root/server.pub"
  "$(dirname $KEY 2>/dev/null)/server.pub"
)

for P in "${PUB_SEARCH_PATHS[@]}"; do
  if [ -f "$P" ]; then
    PUB="$P"
    break
  fi
done

if [ -z "$PUB" ]; then
  PUB=$(find / -name "server.pub" -type f 2>/dev/null | grep -i "slow\|dns\|adm" | head -1)
  if [ -z "$PUB" ]; then
    PUB=$(find / -name "server.pub" -type f 2>/dev/null | head -1)
  fi
fi

# ── Détecter le Nameserver automatiquement ────────
NS_FILE_PATHS=(
  "/etc/adm-lite/slow/dnsi/domain_ns"
  "/etc/slowdns/domain_ns"
  "/opt/slowdns/domain_ns"
)

for NSF in "${NS_FILE_PATHS[@]}"; do
  if [ -f "$NSF" ]; then
    DETECTED_NS=$(cat "$NSF" 2>/dev/null | tr -d '[:space:]')
    [ -n "$DETECTED_NS" ] && break
  fi
done

# Chercher NS dans les services systemd
if [ -z "$DETECTED_NS" ]; then
  for SVC_FILE in /etc/systemd/system/server-sldns*.service /etc/systemd/system/*slow*.service /etc/systemd/system/*dns*.service; do
    if [ -f "$SVC_FILE" ]; then
      DETECTED_NS=$(grep -oP 'ns[\w.-]+\.[a-z]{2,}' "$SVC_FILE" 2>/dev/null | head -1)
      [ -n "$DETECTED_NS" ] && break
    fi
  done
fi

# Chercher NS dans les process en cours
if [ -z "$DETECTED_NS" ]; then
  DETECTED_NS=$(ps aux 2>/dev/null | grep -oP 'ns[\w.-]+\.[a-z]{2,}' | grep -v grep | head -1)
fi

# ── Détecter le Port SSH utilisé par SlowDNS ──────
# Depuis les fichiers de config
SSH_PORT_FILE_PATHS=(
  "/etc/adm-lite/slow/dnsi/puerto"
  "/etc/slowdns/puerto"
)

for SPF in "${SSH_PORT_FILE_PATHS[@]}"; do
  if [ -f "$SPF" ]; then
    DETECTED_SSH_PORT=$(cat "$SPF" 2>/dev/null | tr -d '[:space:]')
    [ -n "$DETECTED_SSH_PORT" ] && break
  fi
done

# Depuis les services systemd
if [ -z "$DETECTED_SSH_PORT" ]; then
  for SVC_FILE in /etc/systemd/system/server-sldns*.service /etc/systemd/system/*slow*.service; do
    if [ -f "$SVC_FILE" ]; then
      DETECTED_SSH_PORT=$(grep -oP '127\.0\.0\.1:\K[0-9]+' "$SVC_FILE" 2>/dev/null | head -1)
      [ -n "$DETECTED_SSH_PORT" ] && break
    fi
  done
fi

# Depuis les process en cours
if [ -z "$DETECTED_SSH_PORT" ]; then
  DETECTED_SSH_PORT=$(ps aux 2>/dev/null | grep -oP '127\.0\.0\.1:\K[0-9]+' | grep -v grep | head -1)
fi

# ════════════════════════════════════════════════
# AFFICHER RÉSULTAT DÉTECTION
# ════════════════════════════════════════════════

echo ""
if [ -n "$SLDNS" ]; then
  echo -e "${GREEN}  ✅ Binaire DNS     : ${YELLOW}${SLDNS}${NC}"
else
  echo -e "${RED}  ❌ Binaire DNS     : Introuvable${NC}"
fi

if [ -n "$KEY" ]; then
  echo -e "${GREEN}  ✅ Clé privée      : ${YELLOW}${KEY}${NC}"
else
  echo -e "${RED}  ❌ Clé privée      : Introuvable${NC}"
fi

if [ -n "$DETECTED_NS" ]; then
  echo -e "${GREEN}  ✅ Nameserver      : ${YELLOW}${DETECTED_NS}${NC}"
else
  echo -e "${YELLOW}  ⚠  Nameserver      : Non détecté${NC}"
fi

if [ -n "$DETECTED_SSH_PORT" ]; then
  echo -e "${GREEN}  ✅ Port SSH détecté: ${YELLOW}${DETECTED_SSH_PORT}${NC}"
else
  echo -e "${YELLOW}  ⚠  Port SSH        : Non détecté${NC}"
fi

# Vérifier que le binaire est trouvé — sinon arrêt
if [ -z "$SLDNS" ] || [ -z "$KEY" ]; then
  echo ""
  echo -e "${RED}  ❌ ERREUR : SlowDNS introuvable sur ce serveur.${NC}"
  echo -e "${RED}  Assurez-vous que SlowDNS est installé avant de lancer CloneDNS.${NC}"
  exit 1
fi

# ════════════════════════════════════════════════
# CONFIGURATION — SEULEMENT 3 QUESTIONS
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
ss -tulnp | grep tcp | grep -v '127.0.0' | grep -v '\[::1\]' | awk '{print "  →", $5}' | sort -u 2>/dev/null
echo ""
DEFAULT_SSH=${DETECTED_SSH_PORT:-2253}
read -p "  Port SSH backend [défaut: ${DEFAULT_SSH}] : " SSH_PORT
SSH_PORT=${SSH_PORT:-$DEFAULT_SSH}

# ── Nameserver ────────────────────────────────────
echo ""
DEFAULT_NS=${DETECTED_NS:-""}

if [ -n "$DEFAULT_NS" ]; then
  echo -e "${CYAN}  Nameserver détecté : ${GREEN}${DEFAULT_NS}${NC}"
  read -p "  Nameserver NS [Entrée pour confirmer ou saisissez le vôtre] : " NS_INPUT
  NS_INPUT=$(echo "$NS_INPUT" | tr -d '[:space:]')
  NS_DOMAIN=${NS_INPUT:-$DEFAULT_NS}
else
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
fi

# ════════════════════════════════════════════════
# RÉSUMÉ ET CONFIRMATION
# ════════════════════════════════════════════════

echo ""
echo -e "${CYAN}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}  ║           RÉSUMÉ CONFIGURATION           ║${NC}"
echo -e "${CYAN}  ╠══════════════════════════════════════════╣${NC}"
echo -e "${CYAN}  ║${NC}  Binaire     : ${YELLOW}${SLDNS}${NC}"
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
EXISTING=$(systemctl list-units --full --all 2>/dev/null | grep 'server-cldns' | awk '{print $1}')
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
