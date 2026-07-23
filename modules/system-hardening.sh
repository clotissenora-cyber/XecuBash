#!/bin/bash

################################################################################
# Módulo de Hardening del Sistema - XecuBash
# Endurecimiento de la configuración del sistema
################################################################################

harden_main() {
    log_info "Iniciando hardening del sistema..."
    
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
    echo "                      HARDENING DEL SISTEMA"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # 1. Hardening de Kernel
    harden_kernel $dry_run $apply

    # 2. Hardening de permisos
    harden_permissions $dry_run $apply

    # 3. Hardening de servicios
    harden_services $dry_run $apply

    # 4. Hardening de bash
    harden_shell $dry_run $apply

    # 5. Configurar auditd
    setup_audit_daemon $dry_run $apply

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    log_success "Hardening del sistema completado"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Hardening del kernel
harden_kernel() {
    local dry_run=$1
    local apply=$2
    
    log_info "Configurando parámetros del kernel..."
    echo ""
    echo "[*] PARÁMETROS DEL KERNEL:"

    # Crear archivo de configuración sysctl
    local sysctl_file="/etc/sysctl.d/99-hardening.conf"
    
    cat > "${sysctl_file}.new" << 'EOF'
# XecuBash - Hardening del Kernel

# Deshabilitar SysRq
kernel.sysrq = 0

# Protección contra IP Spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Deshabilitar ICMP redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Protección contra SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096

# Deshabilitar ICMP ping
net.ipv4.icmp_echo_ignore_all = 0

# Protección contra bad error messages
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Logs de paquetes sospechosos
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Deshabilitar IPv6 si no se usa
# net.ipv6.conf.all.disable_ipv6 = 1

# Aumentar límites de files descriptors
fs.file-max = 2097152

# Protección contra core dumps
kernel.core_uses_pid = 1
fs.suid_dumpable = 0

# Restricción de ptrace
kernel.yama.ptrace_scope = 2

# ASLR (Address Space Layout Randomization)
kernel.randomize_va_space = 2
EOF

    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY-RUN] Se aplicarían los siguientes parámetros:"
        cat "${sysctl_file}.new" | grep -v '^#' | grep -v '^$'
        rm "${sysctl_file}.new"
    elif [[ "$apply" == "true" ]]; then
        if [[ -f "$sysctl_file" ]]; then
            cp "$sysctl_file" "${sysctl_file}.backup"
        fi
        mv "${sysctl_file}.new" "$sysctl_file"
        sysctl -p "$sysctl_file" > /dev/null 2>&1
        log_success "Parámetros del kernel aplicados"
    else
        echo "[*] Cambios listos para aplicar con --apply"
        rm "${sysctl_file}.new"
    fi
}

# Hardening de permisos de archivos
harden_permissions() {
    local dry_run=$1
    local apply=$2
    
    log_info "Ajustando permisos de archivos críticos..."
    echo ""
    echo "[*] PERMISOS DE ARCHIVOS CRÍTICOS:"

    local perms_checks=(
        "/etc/passwd:644"
        "/etc/shadow:600"
        "/etc/group:644"
        "/etc/gshadow:600"
        "/etc/sudoers:440"
        "/root:700"
        "/boot:755"
        "/var/log:755"
    )

    for check in "${perms_checks[@]}"; do
        local file="${check%:*}"
        local expected="${check#*:}"
        
        if [[ -e "$file" ]]; then
            local current=$(stat -c '%a' "$file" 2>/dev/null)
            
            if [[ "$current" != "$expected" ]]; then
                if [[ "$dry_run" == "true" ]]; then
                    echo "[DRY-RUN] $file: $current -> $expected"
                elif [[ "$apply" == "true" ]]; then
                    chmod "$expected" "$file"
                    log_success "Permisos actualizados: $file -> $expected"
                else
                    echo "[*] $file: cambiar de $current a $expected"
                fi
            fi
        fi
    done
}

# Hardening de servicios
harden_services() {
    local dry_run=$1
    local apply=$2
    
    log_info "Deshabilitando servicios innecesarios..."
    echo ""
    echo "[*] SERVICIOS A DESHABILITAR:"

    local risky_services=(
        "avahi-daemon"
        "cups"
        "isc-dhcp-server"
        "bind9"
        "vsftpd"
        "snmpd"
        "rsync"
    )

    for service in "${risky_services[@]}"; do
        if systemctl list-unit-files 2>/dev/null | grep -q "^${service}.service"; then
            if [[ "$dry_run" == "true" ]]; then
                echo "[DRY-RUN] Deshabilitar: $service"
            elif [[ "$apply" == "true" ]]; then
                systemctl disable "$service" 2>/dev/null || true
                systemctl stop "$service" 2>/dev/null || true
                log_success "Servicio deshabilitado: $service"
            else
                echo "[*] Deshabilitar: $service"
            fi
        fi
    done
}

# Hardening de shell
harden_shell() {
    local dry_run=$1
    local apply=$2
    
    log_info "Configurando hardening de bash..."
    echo ""
    echo "[*] CONFIGURACIÓN DE BASH:"

    local bashrc_file="/etc/bash.bashrc"
    local hardening_additions="
# XecuBash - Hardening de bash
set +H                          # Deshabilitar expansión de historia
shopt -s extglob               # Habilitar globs extendidos
shopt -s lastpipe              # Usar último pipe en subshell
shopt -s failglob              # Fallar si no hay coincidencias de glob

# Exportar PROMPT_COMMAND para auditoría
export PROMPT_COMMAND='history -a'
export HISTFILE=/var/log/bash_history
export HISTFILESIZE=5000
export HISTSIZE=5000
export HISTTIMEFORMAT='%F %T '

# Protección de umask
umask 0077

# Deshabilitar core dumps
ulimit -c 0

# Limitar procesos
ulimit -u 100
"

    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY-RUN] Se agregarían configuraciones de bash"
    elif [[ "$apply" == "true" ]]; then
        if ! grep -q "XecuBash - Hardening de bash" "$bashrc_file"; then
            echo "$hardening_additions" >> "$bashrc_file"
            log_success "Hardening de bash aplicado"
        fi
    else
        echo "[*] Cambios listos para aplicar con --apply"
    fi
}

# Configurar daemon de auditoría
setup_audit_daemon() {
    local dry_run=$1
    local apply=$2
    
    log_info "Configurando daemon de auditoría..."
    echo ""
    echo "[*] AUDITORÍA DEL SISTEMA:"

    if [[ "$dry_run" == "true" ]]; then
        echo "[DRY-RUN] Instalar y configurar auditd"
    elif [[ "$apply" == "true" ]]; then
        if ! command_exists auditd; then
            apt-get update > /dev/null
            apt-get install -y auditd audispd-plugins > /dev/null 2>&1
            log_success "auditd instalado"
        fi
        
        # Crear reglas de auditoría
        local audit_rules_file="/etc/audit/rules.d/xecubash.rules"
        cat > "$audit_rules_file" << 'EOF'
# XecuBash - Reglas de Auditoría

# Auditar cambios en /etc
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/ssh/sshd_config -p wa -k ssh_config_changes
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes

# Auditar ejecuciones de comandos importantes
-a always,exit -F path=/usr/bin/passwd -F perm=x -F auid>=1000 -F auid!=-1 -k passwd_execution
-a always,exit -F path=/usr/bin/sudo -F perm=x -F auid>=1000 -F auid!=-1 -k sudo_execution
-a always,exit -F path=/usr/sbin/usermod -F perm=x -F auid>=1000 -F auid!=-1 -k user_modification
EOF
        
        systemctl restart auditd 2>/dev/null || true
        log_success "Auditoría configurada"
    else
        echo "[*] Auditoría lista para configurar con --apply"
    fi
}
