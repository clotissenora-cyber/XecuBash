#!/bin/bash

################################################################################
# Módulo de Configuración DNSCrypt - XecuBash
# Resolución DNS encriptada y segura
################################################################################

dnscrypt_main() {
    log_info "Iniciando configuración de DNSCrypt..."
    
    local setup=false
    local status=false
    local resolver=""
    
    for arg in "$@"; do
        case $arg in
            --setup) setup=true ;;
            --status) status=true ;;
            --resolver) resolver="${arg#*=}" ;;
        esac
    done

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                     CONFIGURACIÓN DNSCRYPT"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    if [[ "$status" == "true" ]]; then
        check_dnscrypt_status
    elif [[ "$setup" == "true" ]]; then
        install_dnscrypt
        configure_dnscrypt_resolvers
        start_dnscrypt_service
    else
        show_dnscrypt_menu
    fi
}

# Comprobar estado de DNSCrypt
check_dnscrypt_status() {
    log_info "Comprobando estado de DNSCrypt..."
    echo ""
    echo "[*] ESTADO DE DNSCRYPT:"

    if command_exists dnscrypt-proxy; then
        echo "    ✓ dnscrypt-proxy instalado"
        local version=$(dnscrypt-proxy -version 2>/dev/null | head -1)
        echo "      Versión: $version"
    else
        echo "    ✗ dnscrypt-proxy NO instalado"
    fi

    # Comprobar servicio
    if systemctl is-active dnscrypt-proxy &>/dev/null; then
        echo "    ✓ Servicio activo"
        echo "    ✓ DNS resolviendo a través de DNSCrypt"
    else
        echo "    ✗ Servicio inactivo"
    fi

    # Mostrar resolver actual
    if [[ -f /etc/dnscrypt-proxy/dnscrypt-proxy.toml ]]; then
        echo ""
        echo "[*] RESOLVER CONFIGURADO:"
        grep -A 5 "\[\[static\]\]" /etc/dnscrypt-proxy/dnscrypt-proxy.toml | head -6
    fi
}

# Instalar DNSCrypt
install_dnscrypt() {
    log_info "Instalando DNSCrypt..."
    echo ""
    echo "[*] INSTALACIÓN DE DNSCRYPT:"

    if command_exists dnscrypt-proxy; then
        log_success "DNSCrypt ya está instalado"
        return 0
    fi

    # Actualizar lista de paquetes
    apt-get update > /dev/null 2>&1
    
    # Instalar dnscrypt-proxy
    apt-get install -y dnscrypt-proxy > /dev/null 2>&1
    
    if command_exists dnscrypt-proxy; then
        log_success "DNSCrypt instalado exitosamente"
        return 0
    else
        log_error "Error instalando DNSCrypt"
        return 1
    fi
}

# Configurar resolvers DNSCrypt
configure_dnscrypt_resolvers() {
    log_info "Configurando resolvers DNSCrypt..."
    echo ""
    echo "[*] RESOLVERS DISPONIBLES:"
    echo ""
    echo "1. Cloudflare (1.1.1.1) - Rápido y confiable"
    echo "2. Quad9 (9.9.9.9) - Con bloqueo de malware"
    echo "3. OpenNIC (195.154.0.0) - Alternativa"
    echo "4. Personalizado"
    echo ""

    read -p "Selecciona resolver (1-4): " resolver_choice

    local resolver_config=""
    
    case $resolver_choice in
        1)
            resolver_config="cloudflare"
            ;;
        2)
            resolver_config="quad9"
            ;;
        3)
            resolver_config="opennic"
            ;;
        4)
            read -p "Ingresa dirección del resolver: " resolver_config
            ;;
        *)
            log_warn "Opción inválida, usando Cloudflare"
            resolver_config="cloudflare"
            ;;
    esac

    create_dnscrypt_config "$resolver_config"
}

# Crear configuración DNSCrypt
create_dnscrypt_config() {
    local resolver="$1"
    local config_file="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"

    # Backup
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "${config_file}.backup.$(date +%s)"
    fi

    cat > "$config_file" << 'EOF'
# XecuBash - Configuración DNSCrypt

listen_addresses = ['127.0.0.1:53', '[::1]:53']

# Modo UDP
max_clients = 250
ipv4_servers = true
ipv6_servers = false
ddns_servers = false
dnssec_servers = false

# Timeouts
stamping_delay = 10
keep_alive = 30

# Fallback resolver para initial queries
fallback_resolvers = ['9.9.9.10:53', '149.112.112.10:53']
fallback_resolver_delay = 1

# Registros de logs
log_level = 2
log_file = '/var/log/dnscrypt-proxy/dnscrypt-proxy.log'
use_syslog = false

# Archivos de lista negra
blacklist_file = '/etc/dnscrypt-proxy/blacklist.txt'
whitelist_file = '/etc/dnscrypt-proxy/whitelist.txt'

# Caché
cache = true
cache_size = 4096
cache_min_ttl = 2400
cache_max_ttl = 86400
cache_neg_min_ttl = 60
cache_neg_max_ttl = 600

# IP anonymization
anonymize_ip = false

# Rotación de resolvers
retry_timeout = 30
server_names = ['2.dnscrypt-cert.cloudflare.com']
EOF

    log_success "Configuración DNSCrypt creada"
}

# Iniciar servicio DNSCrypt
start_dnscrypt_service() {
    log_info "Iniciando servicio DNSCrypt..."
    echo ""
    echo "[*] ACTIVANDO SERVICIO:"

    systemctl enable dnscrypt-proxy 2>/dev/null
    systemctl restart dnscrypt-proxy 2>/dev/null

    sleep 2

    if systemctl is-active dnscrypt-proxy &>/dev/null; then
        log_success "DNSCrypt activo y funcionando"
        
        # Configurar resolvconf
        configure_system_dns
    else
        log_error "Error iniciando servicio DNSCrypt"
        return 1
    fi
}

# Configurar DNS del sistema
configure_system_dns() {
    log_info "Configurando DNS del sistema..."
    echo ""
    echo "[*] CONFIGURACIÓN DNS SISTEMA:"

    local resolv_file="/etc/resolv.conf"

    # Backup
    cp "$resolv_file" "${resolv_file}.backup.$(date +%s)"

    # Configurar localhost como resolver
    cat > "$resolv_file" << 'EOF'
# XecuBash - DNS Configuration
# Resolviendo a través de DNSCrypt
nameserver 127.0.0.1
nameserver ::1

# Fallbacks
nameserver 9.9.9.10
nameserver 149.112.112.10
EOF

    # Hacer archivo inmutable
    chattr +i "$resolv_file" 2>/dev/null || true

    log_success "DNS del sistema configurado"
}

# Menú de DNSCrypt
show_dnscrypt_menu() {
    clear
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│                    MENÚ DNSCRYPT                                            │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                             │"
    echo "│ 1. Ver estado de DNSCrypt                                                  │"
    echo "│ 2. Instalar DNSCrypt                                                       │"
    echo "│ 3. Configurar resolvers                                                    │"
    echo "│ 4. Reiniciar servicio                                                      │"
    echo "│ 5. Ver logs                                                                │"
    echo "│ 6. Salir                                                                   │"
    echo "│                                                                             │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "Selecciona opción (1-6): " choice

    case $choice in
        1) check_dnscrypt_status ;;
        2) install_dnscrypt && configure_dnscrypt_resolvers ;;
        3) configure_dnscrypt_resolvers ;;
        4) systemctl restart dnscrypt-proxy && log_success "DNSCrypt reiniciado" ;;
        5) tail -50 /var/log/dnscrypt-proxy/dnscrypt-proxy.log 2>/dev/null || log_error "Logs no disponibles" ;;
        6) return 0 ;;
        *) log_error "Opción inválida" ;;
    esac
}
