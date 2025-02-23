#!/bin/sh

# Función para verificar si el comando se ejecutó correctamente
check_status() {
    if [ $? -ne 0 ]; then
        echo -e "\033[31m- Ha ocurrido un error\033[0m"
        exit 1
    fi
}

# Actualizar la lista de paquetes
opkg update
check_status
echo -e "\033[32m- La lista de paquetes ha sido actualizada correctamente.\033[0m"

# Instalar OpenVPN, herramientas necesarias y nano
opkg install openvpn-easy-rsa openvpn-openssl luci-app-openvpn nano
check_status
echo -e "\033[32m- OpenVPN, herramientas necesarias y nano han sido instalados correctamente.\033[0m"

# Crear el archivo /etc/openvpn/client.ovpn
echo "PEGA AQUÍ EL CONTENIDO DE client.ovpn DE TU SERVIDOR" > /etc/openvpn/client.ovpn
check_status
echo -e "\033[32m- El archivo /etc/openvpn/client.ovpn ha sido creado correctamente.\033[0m"

# Crear el archivo /etc/config/openvpn
cat <<EOF > /etc/config/openvpn
config openvpn 'VPN_Tap_Client'
    option config '/etc/openvpn/client.ovpn'
    option enabled '1'
EOF
check_status
echo -e "\033[32m- El archivo /etc/config/openvpn ha sido creado correctamente.\033[0m"

# Eliminar la interfaz WAN (IPv4)
uci delete network.wan
check_status
echo -e "\033[32m- La interfaz WAN (IPv4) ha sido eliminada correctamente.\033[0m"

# Eliminar la interfaz WAN6 (IPv6)
uci delete network.wan6
check_status
echo -e "\033[32m- La interfaz WAN6 (IPv6) ha sido eliminada correctamente.\033[0m"

# Aplicar los cambios de eliminación con uci commit
uci commit network
check_status
echo -e "\033[32m- Los cambios de red han sido aplicados correctamente.\033[0m"

# Añadir la configuración del bridge y la interfaz vpn directamente al final del archivo /etc/config/network
echo -e "\nconfig device\n    option type 'bridge'\n    option name 'br-vpn'\n    list ports 'wan'\n    list ports 'tap0'\n    option ipv6 '0'\n    option igmp_snooping '1'\n" >> /etc/config/network

echo -e "config interface 'vpn'\n    option proto 'none'\n    option device 'br-vpn'\n" >> /etc/config/network
check_status
echo -e "\033[32m- El bridge br-vpn y la interfaz vpn han sido configurados correctamente.\033[0m"

# Añadir option igmp_snooping '1' debajo de option name 'br-lan' en /etc/config/network
sed -i "/option name 'br-lan'/a \    option igmp_snooping '1'" /etc/config/network
check_status
echo -e "\033[32m- La opción igmp_snooping '1' ha sido añadida correctamente a la configuración de br-lan.\033[0m"

# Aplicar los cambios de red
/etc/init.d/network restart
check_status
echo -e "\033[32m- Los cambios de red se han reiniciado correctamente.\033[0m"
