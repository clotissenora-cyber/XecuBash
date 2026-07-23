#!/bin/bash

################################################################################
# Módulo de Anonimato - XecuBash
# Configuración de Tor, VPN y proxys
################################################################################

anonymity_main() {
    log_info "Iniciando configuración de anonimato..."
    
    local option="$1"

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                     CONFIGURACIÓN DE ANONIMATO"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    case "$option" in
        --tor)
            setup_tor
            ;;
        --vpn)
            setup_vpn
            ;;
        --proxy)
            setup_proxy
            ;;
        *)
            show_anonymity_menu
            ;;
    esac
}

# Menú de anonimato
show_anonymity_menu() {
    clear
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│                 MENÚ HERRAMIENTAS DE ANONIMATO                              │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                             │"
    echo "│ 1. Configurar Tor                                                          │"
    echo "│ 2. Configurar VPN                                                          │"
    echo "│ 3. Configurar Proxy SOCKS5                                                 │"
    echo "│ 4. MAC Spoofing                                                            │"
    echo "│ 5. Validar Anonimato                                                       │"
    echo "│ 6. Limpiar Metadata                                                        │"
    echo "│ 7. Salir                                                                   │"
    echo "│                                                                             │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "Selecciona opción (1-7): " choice

    case $choice in
        1) setup_tor ;;
        2) setup_vpn ;;
        3) setup_proxy ;;
        4) setup_mac_spoofing ;;
        5) validate_anonymity ;;
        6) cleanup_metadata ;;
        7) return 0 ;;
        *) log_error "Opción inválida" ;;
    esac
}

# Configurar Tor
setup_tor() {
    log_info "Configurando Tor..."
    echo ""
    echo "[*] INSTALACIÓN DE TOR:"

    if ! command_exists tor; then
        apt-get update > /dev/null
        apt-get install -y tor torbrowser-launcher > /dev/null 2>&1
        log_success "Tor instalado"
    else
        log_success "Tor ya está instalado"
    fi

    # Crear configuración personalizada de Tor
    local tor_config="/etc/tor/torrc"
    
    if [[ -f "$tor_config" ]]; then
        cp "$tor_config" "${tor_config}.backup.$(date +%s)"
    fi

    cat >> "$tor_config" << 'EOF'
# XecuBash - Configuración Tor
SocksPort 127.0.0.1:9050
SocksPort 127.0.0.1:9051
ControlPort 127.0.0.1:9052
CookieAuthentication 1
ExitPolicy reject *:*
Log notice file /var/log/tor/notices.log
DataDirectory /var/lib/tor
EOF

    systemctl enable tor > /dev/null 2>&1
    systemctl restart tor > /dev/null 2>&1

    if systemctl is-active tor &>/dev/null; then
        log_success "Tor configurado y activo"
        echo ""
        echo "[*] INFORMACIÓN TOR:"
        echo "    SOCKS5: 127.0.0.1:9050"
        echo "    Control: 127.0.0.1:9052"
        echo ""
        echo "Para usar Tor en aplicaciones:"
        echo "  export http_proxy=socks5://127.0.0.1:9050"
        echo "  export https_proxy=socks5://127.0.0.1:9050"
    else
        log_error "Error configurando Tor"
    fi
}

# Configurar VPN
setup_vpn() {
    log_info "Configurando VPN..."
    echo ""
    echo "[*] CONFIGURACIÓN VPN:"
    echo ""
    echo "Proveedores soportados:"
    echo "  1. OpenVPN"
    echo "  2. WireGuard"
    echo "  3. Personalizado"
    echo ""
    
    read -p "Selecciona proveedor (1-3): " vpn_choice

    case $vpn_choice in
        1)
            apt-get install -y openvpn > /dev/null 2>&1
            log_success "OpenVPN instalado"
            echo "Próximos pasos:"
            echo "  1. Descargar configuración .ovpn del proveedor"
            echo "  2. Copiar a /etc/openvpn/client/"
            echo "  3. sudo systemctl start openvpn@client"
            ;;
        2)
            apt-get install -y wireguard wireguard-tools > /dev/null 2>&1
            log_success "WireGuard instalado"
            echo "Próximos pasos:"
            echo "  1. Generar claves: wg genkey | tee privatekey | wg pubkey > publickey"
            echo "  2. Crear configuración en /etc/wireguard/wg0.conf"
            echo "  3. sudo wg-quick up wg0"
            ;;
        3)
            read -p "Ingresa configuración VPN: " vpn_config
            echo "$vpn_config"
            ;;
    esac
}

# Configurar Proxy SOCKS5
setup_proxy() {
    log_info "Configurando Proxy SOCKS5..."
    echo ""
    echo "[*] CONFIGURACIÓN PROXY SOCKS5:"
    echo ""
    
    read -p "Dirección IP del proxy: " proxy_ip
    read -p "Puerto: " proxy_port
    read -p "Requiere autenticación (s/n): " auth_required

    if [[ "$auth_required" == "s" ]]; then
        read -p "Usuario: " proxy_user
        read -sp "Contraseña: " proxy_pass
        echo ""
        
        # Crear archivo de credenciales
        cat > /etc/proxy-credentials << EOF
user=$proxy_user
pass=$proxy_pass
EOF
        chmod 600 /etc/proxy-credentials
    fi

    # Crear script de configuración
    cat > /etc/profile.d/proxy.sh << EOF
export http_proxy=socks5://$proxy_ip:$proxy_port
export https_proxy=socks5://$proxy_ip:$proxy_port
export ftp_proxy=socks5://$proxy_ip:$proxy_port
EOF

    log_success "Proxy SOCKS5 configurado"
    echo ""
    echo "Credenciales guardadas en: /etc/proxy-credentials"
}

# MAC Spoofing
setup_mac_spoofing() {
    log_info "Configurando MAC spoofing..."
    echo ""
    echo "[*] DISPONIBLES PARA SPOOFING:"
    echo ""

    ip link show | grep '^[0-9]' | awk '{print $2}' | cut -d: -f1 | while read -r iface; do
        local mac=$(ip link show "$iface" | grep link/ether | awk '{print $2}')
        echo "  $iface: $mac"
    done

    echo ""
    read -p "Interfaz a modificar (ej: eth0): " iface

    if [[ -z "$iface" ]]; then
        log_error "Interfaz no especificada"
        return 1
    fi

    # Generar MAC aleatoria
    local new_mac=$(printf '%02x' $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)) $((RANDOM % 256)))
    new_mac="${new_mac:0:2}:${new_mac:2:2}:${new_mac:4:2}:${new_mac:6:2}:${new_mac:8:2}:${new_mac:10:2}"

    echo ""
    echo "Cambiar MAC de $iface a $new_mac?"
    read -p "Confirmar (s/n): " confirm

    if [[ "$confirm" == "s" ]]; then
        ip link set dev "$iface" down
        ip link set dev "$iface" address "$new_mac"
        ip link set dev "$iface" up
        
        log_success "MAC spoofed: $new_mac"
    fi
}

# Validar anonimato
validate_anonymity() {
    log_info "Validando anonimato..."
    echo ""
    echo "[*] VALIDACIÓN DE ANONIMATO:"
    echo ""

    # Verificar IP
    echo "Obteniendo IP pública..."
    local ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "No disponible")
    echo "  IP Pública: $ip"

    # Verificar Tor
    if curl -s --socks5 127.0.0.1:9050 https://check.torproject.org 2>/dev/null | grep -q "Congratulations"; then
        echo "  ✓ Tor conectado"
    else
        echo "  ✗ Tor no disponible"
    fi

    # Verificar DNS leak
    echo ""
    echo "Comprobando DNS leak..."
    echo "Ejecutar en navegador: https://www.dnsleaktest.com"
}

# Limpiar metadata
cleanup_metadata() {
    log_info "Limpiando metadata..."
    echo ""
    echo "[*] LIMPIEZA DE METADATA:"
    echo ""

    if ! command_exists exiftool; then
        apt-get install -y libimage-exiftool > /dev/null 2>&1
        log_success "exiftool instalado"
    fi

    read -p "Ruta de archivo/directorio: " target_path

    if [[ ! -e "$target_path" ]]; then
        log_error "Ruta no existe"
        return 1
    fi

    if [[ -d "$target_path" ]]; then
        exiftool -r -all= "$target_path"
        log_success "Metadata removida de directorio"
    else
        exiftool -all= "$target_path"
        log_success "Metadata removida del archivo"
    fi
}
