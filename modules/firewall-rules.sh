#!/bin/bash

################################################################################
# Módulo de Reglas de Firewall - XecuBash
# Configuración de UFW e iptables
################################################################################

firewall_main() {
    log_info "Iniciando configuración de firewall..."
    
    local action="$1"

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                     CONFIGURACIÓN DE FIREWALL"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    case "$action" in
        --enable) enable_firewall ;;
        --disable) disable_firewall ;;
        --status) check_firewall_status ;;
        --add-rule) add_firewall_rule ;;
        *) show_firewall_menu ;;
    esac
}

# Mostrar menú de firewall
show_firewall_menu() {
    clear
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│                     MENÚ FIREWALL                                           │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                             │"
    echo "│ 1. Ver estado del firewall                                                 │"
    echo "│ 2. Habilitar firewall                                                      │"
    echo "│ 3. Deshabilitar firewall                                                   │"
    echo "│ 4. Agregar regla                                                           │"
    echo "│ 5. Ver reglas actuales                                                     │"
    echo "│ 6. Resetear firewall                                                       │"
    echo "│ 7. Salir                                                                   │"
    echo "│                                                                             │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "Selecciona opción (1-7): " choice

    case $choice in
        1) check_firewall_status ;;
        2) enable_firewall ;;
        3) disable_firewall ;;
        4) add_firewall_rule ;;
        5) show_firewall_rules ;;
        6) reset_firewall ;;
        7) return 0 ;;
        *) log_error "Opción inválida" ;;
    esac
}

# Verificar estado del firewall
check_firewall_status() {
    log_info "Verificando estado del firewall..."
    echo ""
    echo "[*] ESTADO DEL FIREWALL:"
    echo ""

    if command_exists ufw; then
        ufw status
    elif command_exists iptables; then
        iptables -L -v -n | head -20
    else
        log_error "No se detectó firewall"
    fi
}

# Habilitar firewall
enable_firewall() {
    log_info "Habilitando firewall..."
    echo ""
    echo "[*] HABILITANDO UFW:"

    if ! command_exists ufw; then
        apt-get install -y ufw > /dev/null 2>&1
        log_success "UFW instalado"
    fi

    # Configuración por defecto
    ufw default deny incoming > /dev/null 2>&1
    ufw default allow outgoing > /dev/null 2>&1
    ufw default deny routed > /dev/null 2>&1

    # Permitir SSH
    ufw allow 22/tcp > /dev/null 2>&1

    # Habilitar UFW
    echo "y" | ufw enable > /dev/null 2>&1

    if ufw status | grep -q "Status: active"; then
        log_success "Firewall habilitado"
        echo ""
        echo "Configuración por defecto:"
        echo "  - Entrada: DENEGAR"
        echo "  - Salida: PERMITIR"
        echo "  - SSH: PERMITIR (puerto 22)"
    else
        log_error "Error habilitando firewall"
    fi
}

# Deshabilitar firewall
disable_firewall() {
    log_warn "¿Desabilitar firewall? Esto reducirá la seguridad del sistema."
    read -p "Confirmar (s/n): " confirm

    if [[ "$confirm" != "s" ]]; then
        log_info "Operación cancelada"
        return 0
    fi

    if command_exists ufw; then
        echo "y" | ufw disable > /dev/null 2>&1
        log_success "Firewall deshabilitado"
    fi
}

# Agregar regla de firewall
add_firewall_rule() {
    log_info "Agregando regla de firewall..."
    echo ""
    echo "[*] NUEVA REGLA:"
    echo ""
    echo "Tipos de reglas:"
    echo "  1. Puerto TCP"
    echo "  2. Puerto UDP"
    echo "  3. Rango de puertos"
    echo "  4. Dirección IP"
    echo ""
    
    read -p "Tipo de regla (1-4): " rule_type
    read -p "Acción (allow/deny/reject): " action

    case $rule_type in
        1)
            read -p "Puerto TCP: " port
            ufw $action $port/tcp
            log_success "Regla agregada: $action $port/tcp"
            ;;
        2)
            read -p "Puerto UDP: " port
            ufw $action $port/udp
            log_success "Regla agregada: $action $port/udp"
            ;;
        3)
            read -p "Rango (ej: 20000:20100): " range
            ufw $action $range/tcp
            log_success "Regla agregada: $action $range/tcp"
            ;;
        4)
            read -p "Dirección IP: " ip
            ufw $action from $ip
            log_success "Regla agregada: $action from $ip"
            ;;
    esac
}

# Mostrar reglas actuales
show_firewall_rules() {
    log_info "Mostrando reglas del firewall..."
    echo ""
    echo "[*] REGLAS ACTUALES:"
    echo ""
    
    if command_exists ufw; then
        ufw show added
    else
        iptables -L -v -n
    fi
}

# Resetear firewall
reset_firewall() {
    log_warn "¿Resetear firewall a configuración por defecto?"
    read -p "Confirmar (s/n): " confirm

    if [[ "$confirm" != "s" ]]; then
        log_info "Operación cancelada"
        return 0
    fi

    if command_exists ufw; then
        echo "y" | ufw reset > /dev/null 2>&1
        log_success "Firewall resetado"
        # Re-habilitar
        enable_firewall
    fi
}
