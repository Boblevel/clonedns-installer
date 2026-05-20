cat > /usr/local/bin/install-cldns << 'EOF'
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

# ── Détection automatique universelle de sldns-server ──
SLDNS=""
KEY=""
PUB=""

SEARCH_PATHS=(
  "/etc/slowdns/sldns-server"
  "/usr/local/bin/sldns-server"
  "/usr/bin/sldns-server"
  "/opt/slowdns/sldns-server"
  "/root/sldns-server"
)

for PATH_TRY in "${SEARCH_PATHS[@]}"; do
  if [ -f "$PATH_TRY" ]; then
    SLDNS="$PATH_TRY"
    DIR=$(dirname "$PATH_TRY")
    break
  fi
done

# Recherche étendue si pas trouvé
if [ -z "$SLDNS" ]; then
  FOUND=$(find / -name "sldns-server" -type f 2>/dev/null | head -1)
  if [ -n "$FOUND" ]; then
    SLDNS="$FOUND"
    DIR=$(dirname "$FOUND")
  fi
fi

# Chercher server.key et server.pub
if [ -n "$SLDNS" ]; then
  if [ -f "$DIR/server.key" ]; then
    KEY="$DIR/server.key"
    PUB="$DIR/server.pub"
  elif [ -f "/etc/slowdns/server.key" ]; then
    KEY="/etc/slowdns/server.key"
    PUB="/etc/slowdns/server.pub"
  elif [ -f "/usr/local/etc/server.key" ]; then
    KEY="/usr/local/etc/server.key"
    PUB="/usr/local/etc/server.pub"
  else
    KEY=$(find / -name "server.key" -type f 2>/dev/null | head -1)
    PUB=$(find / -name "server.pub" -type f 2>/dev/null | head -1)
  fi
fi

# Afficher résultat détection
if [ -n "$SLDNS" ] && [ -n "$KEY" ]; then
  echo -e "${GREEN}  ✅ SlowDNS détecté automatiquement !${NC}"
  echo -e "${CYAN}  sldns-server : ${YELLOW}${SLDNS}${NC}"
  echo -e "${CYAN}  server.key   : ${YELLOW}${KEY}${NC}"
  echo ""
else
  echo -e "${RED}  ❌ SlowDNS introuvable automatiquement.${NC}"
  echo -e "${YELLOW}  Saisissez les chemins manuellement :${NC}"
  echo ""
  read -p "  Chemin sldns-server : " SLDNS
  read -p "  Chemin server.key   : " KEY
  read -p "  Chemin server.pub   : " PUB

  if [ ! -f "$SLDNS" ]; then
    echo -e "${RED}  ❌ Fichier sldns-server introuvable : ${SLDNS}${NC}"
    echo -e "${RED}  Vérifiez que SlowDNS est bien installé sur ce serveur.${NC}"
    exit 1
  fi
fi

echo ""
echo -e "${BOLD}  ── Configuration CloneDNS ──${NC}"
echo -e "${CYAN}  (Appuyez sur Entrée pour garder la valeur par défaut)${NC}"
echo ""

# ── Port DNS ──────────────────────────────────────
read -p "  Port DNS UDP [défaut: 5301] : " DNS_PORT
DNS_PORT=${DNS_PORT:-5301}

# ── Port SSH backend ──────────────────────────────
echo ""
echo -e "${YELLOW}  Ports SSH disponibles sur ce serveur :${NC}"
ss -tulnp | grep tcp | grep -v '127.0.0' | grep -v '\[::1\]' | awk '{print "  →", $5}' | sort -u 2>/dev/null
echo ""
read -p "  Port SSH backend [défaut: 2253] : " SSH_PORT
SSH_PORT=${SSH_PORT:-2253}

# ── Nameserver ────────────────────────────────────
echo ""
DETECTED_NS=$(grep -oP '(?<=\s)(ns[\w.-]+\.[a-z]{2,})' /etc/systemd/system/server-sldns.service 2>/dev/null | head -1)
if [ -n "$DETECTED_NS" ]; then
  echo -e "${YELLOW}  Nameserver détecté :${NC} ${GREEN}${DETECTED_NS}${NC}"
  echo ""
fi

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

# ── Résumé ────────────────────────────────────────
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

# ── Nettoyage anciens services ────────────────────
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
  # Supprimer aussi les fichiers résiduels
  rm -f /etc/systemd/system/server-cldns*.service
  systemctl daemon-reload
  echo -e "${GREEN}  ✅ Anciens services supprimés.${NC}"
else
  echo -e "${CYAN}  Aucun service existant trouvé.${NC}"
fi
echo ""

# ── Création du service ───────────────────────────
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

# ── Activation ────────────────────────────────────
systemctl daemon-reload
systemctl enable server-cldns-${DNS_PORT} &>/dev/null
systemctl restart server-cldns-${DNS_PORT}

sleep 2

# ── Vérification ──────────────────────────────────
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
EOF
chmod +x /usr/local/bin/install-cldns
echo ""
echo -e "\033[0;32m  ✅ Script prêt ! Lance avec : install-cldns\033[0m"
echo ""
