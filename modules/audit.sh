#!/bin/bash

################################################################################
# Módulo de Auditoría - XecuBash
# Auditoría completa de seguridad del sistema
################################################################################

audit_main() {
    log_info "Iniciando auditoría de seguridad completa..."
    
    local dry_run=false
    
    for arg in "$@"; do
        case $arg in
            --dry-run) dry_run=true ;;
        esac
    done

    # Array para almacenar vulnerabilidades
    declare -ga VULNERABILITIES
    declare -gi VULN_COUNT=0
    declare -gi CRITICAL_COUNT=0
    declare -gi HIGH_COUNT=0
    declare -gi MEDIUM_COUNT=0
    declare -gi LOW_COUNT=0

    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    AUDITORÍA DE SEGURIDAD"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""

    # 1. Auditoría de permisos SUID/SGID
    audit_suid_sgid

    # 2. Auditoría de permisos de archivos críticos
    audit_critical_files

    # 3. Auditoría de servicios
    audit_services

    # 4. Auditoría de puertos abiertos
    audit_open_ports

    # 5. Auditoría de SSH
    audit_ssh_config

    # 6. Auditoría de sudoers
    audit_sudoers

    # 7. Auditoría de firewall
    audit_firewall

    # 8. Auditoría de logs
    audit_logs

    # Mostrar resumen
    show_audit_summary
}

# Auditar permisos SUID/SGID
audit_suid_sgid() {
    log_info "Auditando permisos SUID/SGID..."
    echo ""
    echo "[*] BINARIOS CON SUID/SGID:"
    
    local suid_files=$(find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | grep -v "/proc\|/sys\|/dev" | head -20)
    
    if [[ -z "$suid_files" ]]; then
        echo "    ✓ No se encontraron binarios SUID/SGID sospechosos"
    else
        echo "$suid_files" | while read -r file; do
            local owner=$(stat -c '%U:%G' "$file" 2>/dev/null)
            echo "    ⚠ $file ($owner)"
            VULNERABILITIES+=("MEDIUM: Binario SUID/SGID encontrado: $file")
            ((MEDIUM_COUNT++))
        done
    fi
}

# Auditar permisos de archivos críticos
audit_critical_files() {
    log_info "Auditando permisos de archivos críticos..."
    echo ""
    echo "[*] PERMISOS DE ARCHIVOS CRÍTICOS:"

    local critical_checks=(
        "/etc/passwd:644"
        "/etc/shadow:600"
        "/etc/group:644"
        "/etc/gshadow:600"
        "/etc/sudoers:440"
        "/root:700"
        "/boot:755"
    )

    for check in "${critical_checks[@]}"; do
        local file="${check%:*}"
        local expected_perms="${check#*:}"
        
        if [[ -e "$file" ]]; then
            local actual_perms=$(stat -c '%a' "$file" 2>/dev/null)
            
            if [[ "$actual_perms" != "$expected_perms" ]]; then
                echo "    ✗ $file: $actual_perms (debe ser $expected_perms)"
                VULNERABILITIES+=("HIGH: Permisos incorrectos en $file")
                ((HIGH_COUNT++))
            else
                echo "    ✓ $file: $actual_perms"
            fi
        fi
    done
}

# Auditar servicios activos
audit_services() {
    log_info "Auditando servicios en ejecución..."
    echo ""
    echo "[*] SERVICIOS DE RIESGO POTENCIAL:"

    local risky_services=("telnet" "ftp" "rsh" "rlogin" "nis" "tftp" "talk")
    
    for service in "${risky_services[@]}"; do
        if systemctl is-enabled "$service" 2>/dev/null | grep -q "enabled"; then
            echo "    ✗ $service está habilitado"
            VULNERABILITIES+=("HIGH: Servicio de riesgo habilitado: $service")
            ((HIGH_COUNT++))
        fi
    done

    echo "    ✓ Servicios de riesgo auditados"
}

# Auditar puertos abiertos
audit_open_ports() {
    log_info "Auditando puertos abiertos..."
    echo ""
    echo "[*] PUERTOS ESCUCHANDO:"

    if command_exists "ss"; then
        ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $4, $7}' | while read -r addr service; do
            echo "    $addr -> $service"
        done
    else
        netstat -tulpn 2>/dev/null | grep LISTEN | head -10
    fi
}

# Auditar configuración SSH
audit_ssh_config() {
    log_info "Auditando configuración SSH..."
    echo ""
    echo "[*] CONFIGURACIÓN SSH:"

    local ssh_config="/etc/ssh/sshd_config"
    
    if [[ -f "$ssh_config" ]]; then
        # Verificar PermitRootLogin
        if grep -q "^PermitRootLogin yes" "$ssh_config"; then
            echo "    ✗ PermitRootLogin está habilitado"
            VULNERABILITIES+=("HIGH: PermitRootLogin habilitado en SSH")
            ((HIGH_COUNT++))
        else
            echo "    ✓ PermitRootLogin deshabilitado"
        fi

        # Verificar PasswordAuthentication
        if grep -q "^PasswordAuthentication yes" "$ssh_config"; then
            echo "    ⚠ PasswordAuthentication habilitada (usar claves SSH)"
            VULNERABILITIES+=("MEDIUM: Autenticación por contraseña en SSH")
            ((MEDIUM_COUNT++))
        else
            echo "    ✓ PasswordAuthentication deshabilitada"
        fi

        # Verificar puerto SSH
        local ssh_port=$(grep "^Port" "$ssh_config" | awk '{print $2}')
        if [[ -z "$ssh_port" ]]; then
            ssh_port="22"
        fi
        echo "    Puerto SSH: $ssh_port"
    fi
}

# Auditar sudoers
audit_sudoers() {
    log_info "Auditando configuración de sudoers..."
    echo ""
    echo "[*] CONFIGURACIÓN SUDOERS:"

    # Verificar NOPASSWD
    if grep -q "NOPASSWD" /etc/sudoers 2>/dev/null; then
        echo "    ⚠ Existe configuración NOPASSWD en sudoers"
        VULNERABILITIES+=("HIGH: Sudoers sin contraseña (NOPASSWD)")
        ((HIGH_COUNT++))
    else
        echo "    ✓ No hay configuración NOPASSWD"
    fi

    # Listar usuarios con privs sudo
    echo "    Usuarios con acceso sudo:"
    getent group sudo | cut -d: -f4 | tr ',' '\n' | while read -r user; do
        [[ -n "$user" ]] && echo "      - $user"
    done
}

# Auditar firewall
audit_firewall() {
    log_info "Auditando firewall..."
    echo ""
    echo "[*] ESTADO DEL FIREWALL:"

    if command_exists "ufw"; then
        local ufw_status=$(ufw status 2>/dev/null)
        if echo "$ufw_status" | grep -q "inactive"; then
            echo "    ✗ UFW está deshabilitado"
            VULNERABILITIES+=("HIGH: Firewall deshabilitado")
            ((HIGH_COUNT++))
        else
            echo "    ✓ UFW está activo"
        fi
    elif command_exists "iptables"; then
        echo "    ✓ iptables detectado"
    else
        echo "    ✗ No se detectó firewall activo"
        VULNERABILITIES+=("CRITICAL: Sin firewall habilitado")
        ((CRITICAL_COUNT++))
    fi
}

# Auditar logs
audit_logs() {
    log_info "Auditando configuración de logs..."
    echo ""
    echo "[*] CONFIGURACIÓN DE LOGS:"

    if systemctl is-active rsyslog &>/dev/null; then
        echo "    ✓ rsyslog activo"
    else
        echo "    ⚠ rsyslog no está activo"
        VULNERABILITIES+=("MEDIUM: rsyslog no activo")
        ((MEDIUM_COUNT++))
    fi

    # Verificar logs del sistema
    local log_files=("/var/log/auth.log" "/var/log/syslog")
    for log_file in "${log_files[@]}"; do
        if [[ -f "$log_file" ]]; then
            local size=$(stat -c%s "$log_file" 2>/dev/null)
            echo "    ✓ $log_file ($(numfmt --to=iec $size 2>/dev/null || echo $size bytes))"
        fi
    done
}

# Mostrar resumen de auditoría
show_audit_summary() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "                    RESUMEN DE AUDITORÍA"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    
    VULN_COUNT=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))
    
    echo "Vulnerabilidades detectadas: $VULN_COUNT"
    echo "  - Críticas: $CRITICAL_COUNT"
    echo "  - Altas: $HIGH_COUNT"
    echo "  - Medias: $MEDIUM_COUNT"
    echo "  - Bajas: $LOW_COUNT"
    echo ""
    
    if [[ $CRITICAL_COUNT -gt 0 ]]; then
        echo -e "${RED}⚠ Se detectaron vulnerabilidades CRÍTICAS${NC}"
    elif [[ $HIGH_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Se detectaron vulnerabilidades ALTAS${NC}"
    else
        echo -e "${GREEN}✓ Sistema relativamente seguro${NC}"
    fi
    
    echo ""
    log_success "Auditoría completada"
}
