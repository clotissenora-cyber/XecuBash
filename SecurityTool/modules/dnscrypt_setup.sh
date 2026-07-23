#!/bin/bash
#===============================================================================
# Módulo: DNSCrypt - Configuración Completa
# Descripción: Instalación y configuración de dnscrypt-proxy para Debian 13
#===============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

DNSCRYPT_VERSION="2.1.5"
DNSCRYPT_DIR="/opt/dnscrypt-proxy"
DNSCRYPT_BIN="$DNSCRYPT_DIR/dnscrypt-proxy"

#===============================================================================
# Funciones de Instalación
#===============================================================================

check_dnscrypt_installed() {
    if command -v dnscrypt-proxy &> /dev/null; then
        return 0
    elif [[ -f "$DNSCRYPT_BIN" ]]; then
        return 0
    else
        return 1
    fi
}

install_dnscrypt_proxy() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}INSTALACIÓN DE DNSCRYPT-PROXY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Verificar si ya está instalado
    if check_dnscrypt_installed; then
        echo -e "${GREEN}✓ dnscrypt-proxy ya está instalado${NC}"
        local version=$(dnscrypt-proxy -version 2>&1 | head -1 || echo "desconocida")
        echo "  Versión: $version"
        echo ""
        read -p "¿Desea reinstalar? (y/N): " reinstall
        if [[ "$reinstall" != "y" && "$reinstall" != "Y" ]]; then
            return 0
        fi
    fi
    
    echo -e "${YELLOW}[1/5] Descargando dnscrypt-proxy...${NC}"
    
    mkdir -p "$DNSCRYPT_DIR"
    cd /tmp
    
    # Determinir arquitectura
    local arch=$(uname -m)
    local download_url=""
    
    case "$arch" in
        x86_64)
            download_url="https://download.dnscrypt.info/dnscrypt-proxy/linux_x86_64/dnscrypt-proxy-linux_x86_64-${DNSCRYPT_VERSION}.tar.gz"
            ;;
        aarch64|arm64)
            download_url="https://download.dnscrypt.info/dnscrypt-proxy/linux_aarch64/dnscrypt-proxy-linux_aarch64-${DNSCRYPT_VERSION}.tar.gz"
            ;;
        armv7l)
            download_url="https://download.dnscrypt.info/dnscrypt-proxy/linux_armv7/dnscrypt-proxy-linux_armv7-${DNSCRYPT_VERSION}.tar.gz"
            ;;
        *)
            echo -e "${RED}✗ Arquitectura no soportada: $arch${NC}"
            return 1
            ;;
    esac
    
    echo "  URL: $download_url"
    
    if ! wget -q "$download_url" -O dnscrypt-proxy.tar.gz; then
        echo -e "${RED}✗ Error descargando dnscrypt-proxy${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✓ Descarga completada${NC}"
    
    echo ""
    echo -e "${YELLOW}[2/5] Extrayendo archivos...${NC}"
    tar -xzf dnscrypt-proxy.tar.gz -C "$DNSCRYPT_DIR" --strip-components=1
    chmod +x "$DNSCRYPT_BIN"
    echo -e "${GREEN}✓ Extracción completada${NC}"
    
    echo ""
    echo -e "${YELLOW}[3/5] Creando configuración inicial...${NC}"
    setup_dnscrypt_config
    
    echo ""
    echo -e "${YELLOW}[4/5] Configurando como servicio systemd...${NC}"
    setup_dnscrypt_service
    
    echo ""
    echo -e "${YELLOW}[5/5] Configurando DNS del sistema...${NC}"
    configure_system_dns
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ INSTALACIÓN DE DNSCRYPT-PROXY COMPLETADA${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
}

setup_dnscrypt_config() {
    # Crear directorio de configuración
    mkdir -p "$DNSCRYPT_DIR"
    
    # Configurar archivo principal
    cat > "$DNSCRYPT_DIR/dnscrypt-proxy.toml" << 'CONFIGEOF'
##############################################
# Configuración de DNSCrypt-Proxy
# Generada por SecurityTool para Debian 13
##############################################

# Servidores DNS recomendados (seguros y auditados)
server_names = ['cloudflare', 'quad9', 'google']

# Puertos locales
listen_addresses = ['127.0.0.1:53', '[::1]:53']

# Carga balanceada entre servidores
lb_strategy = 'ph'

# Timeout para consultas
timeout = 5000

# Cache de consultas
cache = true
cache_size = 51200
cache_min_ttl = 60
cache_max_ttl = 604800
cache_neg_min_ttl = 60
cache_neg_max_ttl = 604800

# DNSSEC validation
require_dnssec = true

# Bloqueo de dominios maliciosos
block_name = 'malware'
block_name_logfile = '/var/log/dnscrypt-blocked.log'

# Listas de bloqueo (phishing, malware, etc.)
[blocked_names]
blocked_names_file = '/opt/dnscrypt-proxy/blocked-names.txt'

[whitelist_names]
whitelist_names_file = '/opt/dnscrypt-proxy/whitelist-names.txt'

# Logging
log_level = 2
logfile = '/var/log/dnscrypt-proxy.log'
logformat = 'tsv'
logformat_lgf = 'lgtf'

# Protección contra ataques
max_clients = 250
reject_timeout = 200
refused_code_in_responses = false

# Fallback resolver
fallback_resolver = '9.9.9.9:53'
ignore_system_dns = true

# IPv6
ipv6_servers = true

# Protocolos soportados
dnssec = true
filtering = true

# Resolvers específicos
[sources]

  [sources.'public-resolvers']
  urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md', 'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md']
  cache_file = '/opt/dnscrypt-proxy/public-resolvers.md'
  minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLnJRIY7S3'
  refresh_delay = 72
  prefix = ''

  [sources.'relays']
  urls = ['https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/relays.md', 'https://download.dnscrypt.info/resolvers-list/v3/relays.md']
  cache_file = '/opt/dnscrypt-proxy/relays.md'
  minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLnJRIY7S3'
  refresh_delay = 72
  prefix = ''
CONFIGEOF

    # Crear lista de dominios bloqueados
    cat > "$DNSCRYPT_DIR/blocked-names.txt" << 'BLOCKEDEOF'
# Dominios maliciosos bloqueados
# Malware domains
*.malware.com
*.phishing.com
*.ransomware.com
*.trojan.com
*.botnet.com

# Tracking domains (opcional)
*.doubleclick.net
*.google-analytics.com
*.facebook.com/tr

# Ads domains (opcional)
*.ads.yahoo.com
*.adnxs.com
BLOCKEDEOF

    # Crear lista blanca
    cat > "$DNSCRYPT_DIR/whitelist-names.txt" << 'WHITELISTEOF'
# Dominios en lista blanca (nunca bloquear)
localhost
*.localhost
WHITELISTEOF

    echo -e "${GREEN}✓ Configuración creada en $DNSCRYPT_DIR${NC}"
}

setup_dnscrypt_service() {
    cat > /etc/systemd/system/dnscrypt-proxy.service << 'SERVICEEOF'
[Unit]
Description=DNSCrypt Proxy - DNS Encryption
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy/wiki
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
Type=simple
PIDFile=/var/run/dnscrypt-proxy.pid
ExecStart=/opt/dnscrypt-proxy/dnscrypt-proxy -config /opt/dnscrypt-proxy/dnscrypt-proxy.toml
Restart=on-failure
RestartSec=5s
User=root
Group=root
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
SERVICEEOF

    # Recargar systemd e iniciar servicio
    systemctl daemon-reload
    systemctl enable dnscrypt-proxy
    systemctl start dnscrypt-proxy
    
    echo -e "${GREEN}✓ Servicio systemd configurado e iniciado${NC}"
}

configure_system_dns() {
    # Backup del resolv.conf original
    cp /etc/resolv.conf /etc/resolv.conf.backup.dnscrypt 2>/dev/null || true
    
    # Configurar para usar dnscrypt-proxy local
    cat > /etc/resolv.conf << 'RESOLVEOF'
# DNS configurado por SecurityTool - DNSCrypt Proxy
nameserver 127.0.0.1
nameserver ::1
options edns0 single-request-reuse
RESOLVEOF

    # Hacer el archivo inmutable (opcional, requiere intervención manual después)
    # chattr +i /etc/resolv.conf
    
    echo -e "${GREEN}✓ Sistema configurado para usar DNSCrypt${NC}"
}

#===============================================================================
# Funciones de Verificación
#===============================================================================

verify_dnscrypt_status() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}ESTADO DE DNSCRYPT-PROXY${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Verificar servicio
    echo -e "${YELLOW}[1/4] Estado del servicio:${NC}"
    if systemctl is-active --quiet dnscrypt-proxy 2>/dev/null; then
        echo -e "  ${GREEN}✓ Servicio activo y corriendo${NC}"
        systemctl status dnscrypt-proxy 2>/dev/null | grep -E "Active|Main PID" | sed 's/^/    /'
    else
        echo -e "  ${RED}✗ Servicio inactivo${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}[2/4] Verificando resolución DNS cifrada:${NC}"
    
    # Prueba de resolución
    if command -v dig &> /dev/null; then
        local resolve_time=$(dig @127.0.0.1 google.com +time=2 2>/dev/null | grep "Query time" || echo "Query time: N/A")
        echo "  $resolve_time"
    elif command -v nslookup &> /dev/null; then
        nslookup google.com 127.0.0.1 2>/dev/null | grep -A2 "Server:" | head -3 | sed 's/^/    /'
    else
        echo "  Herramientas de diagnóstico DNS no disponibles"
    fi
    
    echo ""
    echo -e "${YELLOW}[3/4] Servidores DNS activos:${NC}"
    if [[ -f "$DNSCRYPT_DIR/dnscrypt-proxy.toml" ]]; then
        grep "^server_names" "$DNSCRYPT_DIR/dnscrypt-proxy.toml" | sed 's/^/    /'
    fi
    
    echo ""
    echo -e "${YELLOW}[4/4] DNS actuales del sistema:${NC}"
    grep "^nameserver" /etc/resolv.conf 2>/dev/null | sed 's/^/    - /'
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    
    # Prueba de leak DNS
    echo ""
    echo -e "${YELLOW}PRUEBA DE LEAK DNS:${NC}"
    echo "  Para verificar que no hay leaks, visite:"
    echo "    - https://www.dnsleaktest.com/"
    echo "    - https://ipleak.net/"
    echo ""
}

test_dns_resolution() {
    echo -e "${CYAN}Probando resolución DNS...${NC}"
    echo ""
    
    local test_domains=("google.com" "cloudflare.com" "github.com" "debian.org")
    
    for domain in "${test_domains[@]}"; do
        echo -n "  $domain: "
        if command -v dig &> /dev/null; then
            local result=$(dig @127.0.0.1 +short "$domain" 2>/dev/null | head -1)
            if [[ -n "$result" ]]; then
                echo -e "${GREEN}✓ $result${NC}"
            else
                echo -e "${RED}✗ Sin respuesta${NC}"
            fi
        else
            local result=$(getent hosts "$domain" 2>/dev/null | awk '{print $1}')
            if [[ -n "$result" ]]; then
                echo -e "${GREEN}✓ $result${NC}"
            else
                echo -e "${RED}✗ Sin respuesta${NC}"
            fi
        fi
    done
    
    echo ""
}

list_available_resolvers() {
    echo -e "${CYAN}Resolvers DNS públicos disponibles:${NC}"
    echo ""
    echo "┌─────────────────┬─────────────────────────────┬──────────────────┐"
    echo "│ Proveedor       │ Dirección                   │ Características  │"
    echo "├─────────────────┼─────────────────────────────┼──────────────────┤"
    echo "│ Cloudflare      │ 1.1.1.1, 1.0.0.1           │ Rápido, Privacy  │"
    echo "│ Quad9           │ 9.9.9.9                    │ Seguridad, DNSSEC│"
    echo "│ Google          │ 8.8.8.8, 8.8.4.4           │ Rápido, Global   │"
    echo "│ OpenDNS         │ 208.67.222.222             │ Filtrado         │"
    echo "│ AdGuard DNS     │ 94.140.14.14               │ Bloqueo de ads   │"
    echo "│ CleanBrowsing   │ 185.228.168.9              │ Filtrado familiar│"
    echo "└─────────────────┴─────────────────────────────┴──────────────────┘"
    echo ""
}

change_resolvers() {
    echo -e "${YELLOW}Seleccione resolver(es) preferidos:${NC}"
    echo ""
    echo "  1. Cloudflare (1.1.1.1)"
    echo "  2. Quad9 (9.9.9.9)"
    echo "  3. Google (8.8.8.8)"
    echo "  4. Múltiple (Cloudflare + Quad9)"
    echo "  5. Personalizado"
    echo ""
    
    read -p "Opción: " option
    
    local servers=""
    
    case "$option" in
        1)
            servers="['cloudflare']"
            ;;
        2)
            servers="['quad9']"
            ;;
        3)
            servers="['google']"
            ;;
        4)
            servers="['cloudflare', 'quad9']"
            ;;
        5)
            read -p "Ingrese nombres de servidores (separados por coma): " custom
            servers="[$(echo "$custom" | sed "s/,/', '/g" | sed "s/^/'/" | sed "s/$/'/")]"
            ;;
        *)
            echo -e "${RED}Opción no válida${NC}"
            return 1
            ;;
    esac
    
    # Actualizar configuración
    if [[ -f "$DNSCRYPT_DIR/dnscrypt-proxy.toml" ]]; then
        sed -i "s/^server_names.*/server_names = $servers/" "$DNSCRYPT_DIR/dnscrypt-proxy.toml"
        systemctl restart dnscrypt-proxy
        echo -e "${GREEN}✓ Resolvers actualizados${NC}"
    else
        echo -e "${RED}✗ Archivo de configuración no encontrado${NC}"
    fi
}

#===============================================================================
# Menú del módulo
#===============================================================================

run_module_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     Módulo: DNSCrypt - DNS Cifrado                           ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} Instalar/Actualizar DNSCrypt-Proxy"
        echo -e "  ${GREEN}2.${NC} Verificar estado de DNSCrypt"
        echo -e "  ${GREEN}3.${NC} Probar resolución DNS"
        echo -e "  ${GREEN}4.${NC} Listar resolvers disponibles"
        echo -e "  ${GREEN}5.${NC} Cambiar resolvers DNS"
        echo -e "  ${GREEN}6.${NC} Ver logs de DNSCrypt"
        echo -e "  ${GREEN}7.${NC} Reiniciar servicio DNSCrypt"
        echo ""
        echo -e "  ${RED}0.${NC} Volver al menú principal"
        echo ""
        
        read -p "Seleccione una opción: " choice
        
        case "$choice" in
            1)
                install_dnscrypt_proxy
                read -p "Presione Enter para continuar..."
                ;;
            2)
                verify_dnscrypt_status
                read -p "Presione Enter para continuar..."
                ;;
            3)
                test_dns_resolution
                read -p "Presione Enter para continuar..."
                ;;
            4)
                list_available_resolvers
                read -p "Presione Enter para continuar..."
                ;;
            5)
                change_resolvers
                read -p "Presione Enter para continuar..."
                ;;
            6)
                echo -e "${CYAN}Últimas 20 líneas del log:${NC}"
                tail -20 /var/log/dnscrypt-proxy.log 2>/dev/null || echo "Log no disponible"
                read -p "Presione Enter para continuar..."
                ;;
            7)
                systemctl restart dnscrypt-proxy 2>/dev/null && echo -e "${GREEN}✓ Servicio reiniciado${NC}" || echo -e "${RED}✗ Error al reiniciar${NC}"
                read -p "Presione Enter para continuar..."
                ;;
            0)
                return 0
                ;;
            *)
                echo -e "${RED}Opción no válida${NC}"
                sleep 1
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root"
        exit 1
    fi
    run_module_menu
fi
