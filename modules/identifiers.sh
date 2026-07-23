#!/bin/bash

################################################################################
# Módulo de Gestión de Identificadores - XecuBash
# MAC spoofing, IPv6, hostname, machine-id
################################################################################

identifiers_main() {
    log_info "Iniciando gestión de identificadores..."
    
    local option="$1"

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                 GESTIÓN DE IDENTIFICADORES DE RED"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    case "$option" in
        --mac) manage_mac_address ;;
        --ipv6) manage_ipv6 ;;
        --hostname) manage_hostname ;;
        *) show_identifiers_menu ;;
    esac
}

# Menú de identificadores
show_identifiers_menu() {
    clear
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│              MENÚ GESTIÓN DE IDENTIFICADORES                                │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                             │"
    echo "│ 1. Gestionar direcciones MAC                                               │"
    echo "│ 2. Gestionar IPv6                                                          │"
    echo "│ 3. Gestionar hostname                                                      │"
    echo "│ 4. Gestionar Machine-ID                                                    │"
    echo "│ 5. Ver identificadores actuales                                            │"
    echo "│ 6. Salir                                                                   │"
    echo "│                                                                             │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "Selecciona opción (1-6): " choice

    case $choice in
        1) manage_mac_address ;;
        2) manage_ipv6 ;;
        3) manage_hostname ;;
        4) manage_machine_id ;;
        5) show_current_identifiers ;;
        6) return 0 ;;
        *) log_error "Opción inválida" ;;
    esac
}

# Ver identificadores actuales
show_current_identifiers() {
    log_info "Mostrando identificadores del sistema..."
    echo ""
    echo "[*] IDENTIFICADORES ACTUALES:"
    echo ""
    
    echo "Hostname:"
    echo "  $(hostname)"
    echo ""
    
    echo "Direcciones MAC:"
    ip link show | grep link/ether | awk '{print "  " $2 " (" $1 ":")' | sed 's/:$/)/'
    echo ""
    
    echo "Direcciones IPv4:"
    ip -4 addr show | grep "inet " | awk '{print "  " $2 " (" $NF ")"}'
    echo ""
    
    echo "Direcciones IPv6:"
    ip -6 addr show | grep "inet6 " | awk '{print "  " $2 " (" $NF ")"}' | head -5
    echo ""
    
    echo "Machine-ID:"
    echo "  $(cat /etc/machine-id 2>/dev/null || echo 'No disponible')"
    echo ""
}

# Gestionar direcciones MAC
manage_mac_address() {
    log_info "Gestión de direcciones MAC..."
    echo ""
    echo "[*] INTERFASES DE RED:"
    echo ""

    local interfaces=()
    ip link show | grep '^[0-9]' | while read -r line; do
        local iface=$(echo "$line" | awk '{print $2}' | cut -d: -f1)
        local mac=$(ip link show "$iface" | grep link/ether | awk '{print $2}')
        echo "  $iface: $mac"
        interfaces+=("$iface")
    done

    echo ""
    read -p "Interfaz a modificar: " selected_iface

    if [[ -z "$selected_iface" ]]; then
        log_error "Interfaz no especificada"
        return 1
    fi

    echo ""
    echo "Opciones:"
    echo "  1. Generar MAC aleatoria"
    echo "  2. Establecer MAC específica"
    echo "  3. Resetear a MAC original"
    echo ""
    
    read -p "Opción: " mac_option

    case $mac_option in
        1)
            # Generar MAC aleatoria
            local new_mac=$(xxd -p -l 6 /dev/urandom | sed 's/\(.\{2\}\)/\1:/g; s/:$//')
            apply_mac_change "$selected_iface" "$new_mac"
            ;;
        2)
            read -p "Ingresa nueva MAC: " new_mac
            if validate_mac "$new_mac"; then
                apply_mac_change "$selected_iface" "$new_mac"
            fi
            ;;
        3)
            log_info "Resetear MAC requiere reinicio de interfaz"
            read -p "Continuar (s/n): " confirm
            if [[ "$confirm" == "s" ]]; then
                ip link set dev "$selected_iface" down
                sleep 1
                ip link set dev "$selected_iface" up
                log_success "Interfaz reiniciada"
            fi
            ;;
    esac
}

# Aplicar cambio de MAC
apply_mac_change() {
    local iface="$1"
    local new_mac="$2"

    ip link set dev "$iface" down 2>/dev/null || return 1
    sleep 1
    ip link set dev "$iface" address "$new_mac" 2>/dev/null || return 1
    ip link set dev "$iface" up 2>/dev/null || return 1

    log_success "MAC modificada: $new_mac"
    echo "  Interfaz: $iface"
    echo "  Nueva MAC: $new_mac"
}

# Gestionar IPv6
manage_ipv6() {
    log_info "Gestión de IPv6..."
    echo ""
    echo "[*] OPCIONES IPv6:"
    echo ""
    echo "  1. Habilitar IPv6"
    echo "  2. Deshabilitar IPv6"
    echo "  3. Generar nueva dirección IPv6"
    echo ""
    
    read -p "Opción: " ipv6_option

    case $ipv6_option in
        1)
            # Habilitar IPv6
            sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null
            sysctl -w net.ipv6.conf.default.disable_ipv6=0 > /dev/null
            log_success "IPv6 habilitado"
            ;;
        2)
            # Deshabilitar IPv6
            sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null
            sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null
            log_success "IPv6 deshabilitado"
            ;;
        3)
            log_info "IPv6 Privacy Extensions"
            sysctl -w net.ipv6.conf.all.use_tempaddr=2 > /dev/null
            log_success "IPv6 Privacy Extensions habilitado"
            ;;
    esac
}

# Gestionar hostname
manage_hostname() {
    log_info "Gestión de hostname..."
    echo ""
    echo "[*] HOSTNAME ACTUAL:"
    echo "  $(hostname)"
    echo ""
    
    read -p "Nuevo hostname: " new_hostname

    if [[ -z "$new_hostname" ]]; then
        log_error "Hostname no puede estar vacío"
        return 1
    fi

    # Cambiar hostname
    hostnamectl set-hostname "$new_hostname" 2>/dev/null || \
        echo "$new_hostname" > /etc/hostname

    # Actualizar /etc/hosts
    sed -i "s/.*127.0.1.1.*/127.0.1.1\t$new_hostname/" /etc/hosts 2>/dev/null || \
        echo "127.0.1.1\t$new_hostname" >> /etc/hosts

    log_success "Hostname actualizado: $new_hostname"
    echo "Los cambios se aplicarán después de reiniciar la sesión"
}

# Gestionar Machine-ID
manage_machine_id() {
    log_info "Gestión de Machine-ID..."
    echo ""
    echo "[*] MACHINE-ID ACTUAL:"
    echo "  $(cat /etc/machine-id)"
    echo ""
    
    echo "Opciones:"
    echo "  1. Ver Machine-ID"
    echo "  2. Regenerar Machine-ID (requiere reboot)"
    echo ""
    
    read -p "Opción: " mid_option

    case $mid_option in
        1)
            cat /etc/machine-id
            ;;
        2)
            log_warn "Regenerar Machine-ID requiere reinicio del sistema"
            read -p "Continuar (s/n): " confirm
            
            if [[ "$confirm" == "s" ]]; then
                # Backup actual
                cp /etc/machine-id /etc/machine-id.backup
                
                # Regenerar
                systemd-machine-id-setup --print 2>/dev/null || \
                    dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 -v | tr -d ' ' > /etc/machine-id
                
                log_success "Machine-ID regenerado"
                log_warn "Sistema requiere reinicio para aplicar cambios"
            fi
            ;;
    esac
}
