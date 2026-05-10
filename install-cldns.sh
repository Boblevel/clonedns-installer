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

if [ -f /etc/slowdns/sldns-server ]; then
  SLDNS=/etc/slowdns/sldns-server
  KEY=/etc/slowdns/server.key
  PUB=/etc/slowdns/server.pub
elif [ -f /usr/local/bin/sldns-server ]; then
  SLDNS=/usr/local/bin/sldns-server
  KEY=/usr/local/etc/server.key
  PUB=/usr/local/etc/server.pub
else
  echo -e "${YELLOW}  Chemin SlowDNS non détecté automatiquement.${NC}"
  read -p "  Chemin sldns-server : " SLDNS
  read -p "  Chemin server.key   : " KEY
  read -p "  Chemin server.pub   : " PUB
fi

echo ""
echo -e "${BOLD}  ── Configuration CloneDNS ──${NC}"
echo -e "${CYAN}  (Appuyez sur Entrée pour garder la valeur par défaut)${NC}"
echo ""

read -p "  Port DNS UDP [défaut: 2253] : " DNS_PORT
DNS_PORT=${DNS_PORT:-2253}

echo ""
echo -e "${YELLOW}  Ports SSH disponibles sur ce serveur :${NC}"
ss -tulnp | grep tcp | grep -v '127.0.0.1' | awk '{print "  →", $5}' 2>/dev/null
echo ""
read -p "  Port SSH backend [défaut: 143] : " SSH_PORT
SSH_PORT=${SSH_PORT:-143}

echo ""
DETECTED_NS=$(grep -oP '(?<=\s)(ns[\w.-]+)' /etc/systemd/system/server-sldns.service 2>/dev/null | head -1)
if [ -n "$DETECTED_NS" ]; then
  echo -e "${YELLOW}  Nameserver détecté sur ce serveur :${NC} ${GREEN}${DETECTED_NS}${NC}"
else
  echo -e "${YELLOW}  Aucun Nameserver détecté automatiquement.${NC}"
fi

echo ""
echo -e "${RED}  ⚠  Le Nameserver est OBLIGATOIRE — saisissez le vôtre.${NC}"
echo -e "${CYAN}  ex: ns-mr.rhaffservixxxxx${NC}"
echo ""
read -p "  Nameserver NS (obligatoire) : " NS_DOMAIN

while [ -z "$NS_DOMAIN" ]; do
  echo -e "${RED}  ❌ Le Nameserver ne peut pas être vide !${NC}"
  echo -e "${CYAN}  ex: ns-mr.rhaffservixxxxx${NC}"
  read -p "  Nameserver NS (obligatoire) : " NS_DOMAIN
done

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

echo ""
echo -e "${YELLOW}  Nettoyage des anciens services CloneDNS...${NC}"
EXISTING=$(systemctl list-units --full --all 2>/dev/null | grep 'server-cldns-' | awk '{print $1}')
if [ -n "$EXISTING" ]; then
  for SVC in $EXISTING; do
    systemctl stop "$SVC" &>/dev/null
    systemctl disable "$SVC" &>/dev/null
    rm -f "/etc/systemd/system/${SVC}"
    echo -e "${RED}  ✗ Supprimé : ${SVC}${NC}"
  done
  systemctl daemon-reload
  echo -e "${GREEN}  ✅ Anciens services supprimés.${NC}"
else
  echo -e "${CYAN}  Aucun service existant trouvé.${NC}"
fi
echo ""

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
