#!/bin/bash

################################################################################
# Módulo de Seguridad de Red - XecuBash
# Configuración de seguridad de red
################################################################################

network_security_main() {
    log_info "Iniciando configuración de seguridad de red..."
    
    local apply=false
    local dry_run=false
    
    for arg in "$@"; do
        case $arg in
            --apply) apply=true ;;
            --dry-run) dry_run=true ;;
        esac
    done

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                    SEGURIDAD DE RED"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # 1. Auditoría de puertos
    audit_network_ports

    # 2. Configuración de SSH
    configure_ssh_security $dry_run $apply

    # 3. Validación de SSL/TLS
    audit_ssl_certificates

    # 4. Auditoría de conexiones
    audit_network_connections

    echo ""
    log_success "Auditoría de seguridad de red completada"
    echo ""
}

# Auditar puertos abiertos
audit_network_ports() {
    log_info "Auditando puertos abiertos..."
    echo ""
    echo "[*] PUERTOS ESCUCHANDO:"
    echo ""

    if command_exists ss; then
        echo "Local Address           Foreign Address         State       PID/Program"
        echo "────────────────────────────────────────────────────────────────────────────────"
        ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $4, $6, $7}' | while read -r addr state prog; do
            printf "%-23s %-23s %-11s %s\n" "$addr" "0.0.0.0:*" "$state" "$prog"
        done
    else
        netstat -tulpn 2>/dev/null | grep LISTEN | tail -n +3
    fi
}

# Configurar seguridad SSH
configure_ssh_security() {
    local dry_run=$1
    local apply=$2
    
    log_info "Configurando SSH..."
    echo ""
    echo "[*] CONFIGURACIÓN SSH:"

    local ssh_config="/etc/ssh/sshd_config"
    
    if [[ ! -f "$ssh_config" ]]; then
        log_error "Configuración SSH no encontrada"
        return 1
    fi

    # Crear archivo de configuración mejorada
    cat > "${ssh_config}.new" << 'EOF'
# XecuBash - Configuración SSH Endurecida

# Puerto (cambiar a puerto no estándar)
Port 2222

# Escuchar solo en interfaz específica (opcional)
# ListenAddress 0.0.0.0

# Versión del protocolo
Protocol 2

# HostKeys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Seguridad de login
PermitRootLogin no
PermitUserEnvironment no
StrictModes yes
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30

# Autenticación
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

# Compresión (desabilitar para evitar ataques de timing)
Compression delayed
ClientAliveInterval 300
ClientAliveCountMax 2

# Seguridad adicional
X11Forwarding no
AllowTcpForwarding no
PermitTunnel no
UseDNS no
IgnoreUserKnownHosts yes

# Algoritmos criptográficos seguros
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
KEXAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO
EOF

    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY-RUN] Se aplicaría la configuración SSH segura"
        echo "Cambios principales:"
        echo "  - Puerto: 2222"
        echo "  - PermitRootLogin: no"
        echo "  - PasswordAuthentication: no"
        echo "  - X11Forwarding: no"
    elif [[ "$apply" == "true" ]]; then
        cp "$ssh_config" "${ssh_config}.backup.$(date +%s)"
        
        # Aplicar configuración, mantener líneas existentes que no están en la nueva
        grep -v "^#" "${ssh_config}.new" > "${ssh_config}.tmp"
        cat "${ssh_config}.tmp" > "$ssh_config"
        rm "${ssh_config}.tmp" "${ssh_config}.new"
        
        # Validar sintaxis SSH
        if sshd -t 2>/dev/null; then
            systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
            log_success "SSH configurado y reiniciado"
        else
            log_error "Error en configuración SSH - revertiendo"
            cp "${ssh_config}.backup"* "$ssh_config"
            return 1
        fi
    else
        echo "[*] Configuración SSH lista para aplicar con --apply"
        rm "${ssh_config}.new"
    fi
}

# Auditar certificados SSL/TLS
audit_ssl_certificates() {
    log_info "Auditando certificados SSL/TLS..."
    echo ""
    echo "[*] CERTIFICADOS SSL/TLS:"

    # Buscar certificados .crt
    local cert_files=$(find /etc/ssl /etc/letsencrypt -name "*.crt" 2>/dev/null)
    
    if [[ -z "$cert_files" ]]; then
        echo "    No se encontraron certificados"
        return 0
    fi

    echo "$cert_files" | while read -r cert; do
        local subject=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | cut -d'=' -f2-)
        local expiry=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | cut -d'=' -f2-)
        local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        local now=$(date +%s)
        local days_left=$(( (expiry_epoch - now) / 86400 ))

        if [[ $days_left -lt 30 ]]; then
            echo "    ⚠ $cert ($days_left días hasta expiración)"
        else
            echo "    ✓ $cert ($days_left días hasta expiración)"
        fi
    done
}

# Auditar conexiones de red
audit_network_connections() {
    log_info "Auditando conexiones de red..."
    echo ""
    echo "[*] CONEXIONES ESTABLECIDAS:"

    if command_exists ss; then
        echo "Local Address           Remote Address          State       Process"
        echo "────────────────────────────────────────────────────────────────────────────────"
        ss -tupen 2>/dev/null | grep ESTAB | head -10 | awk '{printf "%-23s %-23s %-11s %s\n", $4, $5, $6, $7}'
    else
        echo "Conexiones TCP:"
        netstat -tupn 2>/dev/null | grep ESTABLISHED | head -10
    fi
    
    local connection_count=$(ss -tu 2>/dev/null | wc -l)
    echo ""
    echo "Total de conexiones activas: $connection_count"
}
