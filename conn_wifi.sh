#!/bin/bash

# Verifica se as ferramentas necessárias estão instaladas
REQUIRED_TOOLS=(iw wpa_supplicant dhclient grep awk sed)
for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$TOOL" &> /dev/null; then
        echo "Erro: $TOOL não está instalado."
        exit 1
    fi
done

# Obtém a interface de rede Wi-Fi usando o comando iw dev
WIFI_INTERFACE=$(sudo iw dev | awk '$1=="Interface"{print $2}')

if [ -z "$WIFI_INTERFACE" ]; then
    echo "Nenhuma interface de rede Wi-Fi encontrada."
    exit 1
else
    echo "Interface de rede Wi-Fi encontrada: $WIFI_INTERFACE"
fi

# Verifica se a interface de rede Wi-Fi está ativa
if ! ip link show "$WIFI_INTERFACE" | grep -q "state UP"; then
    echo "A interface $WIFI_INTERFACE não está ativa."
    exit 1
fi

# Escaneia as redes Wi-Fi disponíveis
echo "Escaneando redes Wi-Fi disponíveis..."
sudo iwlist "$WIFI_INTERFACE" scan | grep -oP 'ESSID:"\K[^"]+'

# Solicita o nome da rede Wi-Fi (SSID)
read -p "Digite o nome da rede (SSID): " SSID

# Solicita a senha da rede Wi-Fi
read -sp "Digite a senha da rede: " PASSWD
echo

# Gera o arquivo de configuração para o wpa_supplicant
{
    echo "network={"
    echo "    ssid=\"$SSID\""
    echo "    psk=\"$PASSWD\""
    echo "}"
} | sudo tee /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null

# Verifica se o arquivo de configuração foi criado corretamente
if [ ! -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
    echo "Erro ao criar o arquivo de configuração do wpa_supplicant."
    exit 1
fi

# Conecta à rede Wi-Fi usando a interface identificada
echo "Conectando à rede Wi-Fi $SSID..."
sudo wpa_supplicant -B -i "$WIFI_INTERFACE" -c /etc/wpa_supplicant/wpa_supplicant.conf

# Obtém um endereço IP via DHCP
echo "Solicitando um endereço IP..."
sudo dhclient -v "$WIFI_INTERFACE"

echo "Conectado à rede Wi-Fi $SSID."

