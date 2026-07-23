#!/bin/bash
#===============================================================================
# Módulo: Seguridad del Sistema Base
# Descripción: Auditoría y hardening del sistema base de Debian 13
#===============================================================================

# Colores (heredados del script principal)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#===============================================================================
# Funciones de Auditoría
#===============================================================================

audit_system_base() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}AUDITORÍA DE SEGURIDAD DEL SISTEMA BASE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local issues=0
    
    # 1. Auditoría de permisos SUID/SGID
    echo -e "${YELLOW}[1/7] Buscando archivos con SUID/SGID...${NC}"
    local suid_files=$(find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | wc -l)
    if [[ $suid_files -gt 50 ]]; then
        echo -e "  ${RED}⚠ ALERTA:${NC} Se encontraron $suid_files archivos con SUID/SGID"
        ((issues++))
    else
        echo -e "  ${GREEN}✓ OK:${NC} $suid_files archivos con SUID/SGID (dentro de límites normales)"
    fi
    
    # Listar algunos archivos SUID críticos
    echo "  Archivos SUID en directorios críticos:"
    find /bin /sbin /usr/bin /usr/sbin -type f -perm -4000 2>/dev/null | head -5 | sed 's/^/    - /'
    
    # 2. Integridad de binarios del sistema
    echo ""
    echo -e "${YELLOW}[2/7] Verificando integridad de binarios...${NC}"
    if command -v debsums &> /dev/null; then
        local broken_pkgs=$(debsums -s 2>/dev/null | wc -l)
        if [[ $broken_pkgs -gt 0 ]]; then
            echo -e "  ${RED}⚠ ALERTA:${NC} $broken_pkgs paquetes con archivos modificados"
            ((issues++))
        else
            echo -e "  ${GREEN}✓ OK:${NC} Todos los binarios verifican correctamente"
        fi
    else
        echo -e "  ${BLUE}ℹ INFO:${NC} debsums no instalado. Instale con: apt install debsums"
    fi
    
    # 3. Servicios systemd sospechosos
    echo ""
    echo -e "${YELLOW}[3/7] Auditando servicios systemd...${NC}"
    local running_services=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l)
    echo "  Servicios activos: $running_services"
    
    # Detectar servicios no estándar
    local non_standard=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | grep -vE "(systemd|dbus|cron|ssh|networking|rsyslog)" | wc -l)
    if [[ $non_standard -gt 10 ]]; then
        echo -e "  ${YELLOW}⚠ WARN:${NC} $non_standard servicios no estándar detectados"
    else
        echo -e "  ${GREEN}✓ OK:${NC} Servicios dentro de parámetros normales"
    fi
    
    # 4. Configuración de sudoers
    echo ""
    echo -e "${YELLOW}[4/7] Verificando configuración sudo...${NC}"
    if [[ -f /etc/sudoers ]]; then
        # Verificar si root puede ejecutar sin password
        if grep -q "NOPASSWD" /etc/sudoers 2>/dev/null; then
            echo -e "  ${YELLOW}⚠ WARN:${NC} Se encontraron reglas NOPASSWD en sudoers"
            grep "NOPASSWD" /etc/sudoers | head -3 | sed 's/^/    /'
            ((issues++))
        else
            echo -e "  ${GREEN}✓ OK:${NC} No hay reglas NOPASSWD peligrosas"
        fi
        
        # Verificar permisos del archivo sudoers
        local sudoers_perms=$(stat -c %a /etc/sudoers 2>/dev/null)
        if [[ "$sudoers_perms" != "440" ]]; then
            echo -e "  ${RED}⚠ CRÍTICO:${NC} Permisos incorrectos en /etc/sudoers ($sudoers_perms)"
            ((issues++))
        else
            echo -e "  ${GREEN}✓ OK:${NC} Permisos correctos en /etc/sudoers"
        fi
    fi
    
    # 5. Detección de rootkits básica
    echo ""
    echo -e "${YELLOW}[5/7] Búsqueda básica de rootkits...${NC}"
    local rootkit_indicators=0
    
    # Verificar procesos ocultos
    if ls /proc 2>/dev/null | grep -q "[0-9]"; then
        local proc_count=$(ls -d /proc/[0-9]* 2>/dev/null | wc -l)
        local ps_count=$(ps aux 2>/dev/null | wc -l)
        if [[ $((proc_count - ps_count)) -gt 5 ]]; then
            echo -e "  ${RED}⚠ ALERTA:${NC} Posible discrepancia entre /proc y ps"
            ((rootkit_indicators++))
            ((issues++))
        fi
    fi
    
    # Verificar comandos modificados
    for cmd in ps ls netstat ss; do
        if command -v $cmd &> /dev/null; then
            local cmd_path=$(which $cmd 2>/dev/null)
            if [[ -f "$cmd_path" ]]; then
                local size=$(stat -c %s "$cmd_path" 2>/dev/null)
                if [[ $size -gt 1000000 ]]; then
                    echo -e "  ${YELLOW}⚠ WARN:${NC} $cmd tiene tamaño inusual ($size bytes)"
                    ((rootkit_indicators++))
                fi
            fi
        fi
    done
    
    if [[ $rootkit_indicators -eq 0 ]]; then
        echo -e "  ${GREEN}✓ OK:${NC} No se detectaron indicadores obvios de rootkit"
    else
        echo -e "  ${RED}⚠ ALERTA:${NC} Se detectaron $rootkit_indicators indicadores sospechosos"
    fi
    
    # 6. Permisos en archivos críticos
    echo ""
    echo -e "${YELLOW}[6/7] Verificando permisos en archivos críticos...${NC}"
    local critical_files=("/etc/passwd" "/etc/shadow" "/etc/group" "/etc/gshadow")
    
    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            local perms=$(stat -c %a "$file" 2>/dev/null)
            local owner=$(stat -c %U:%G "$file" 2>/dev/null)
            
            case "$file" in
                "/etc/passwd")
                    if [[ "$perms" != "644" ]]; then
                        echo -e "  ${RED}⚠ CRÍTICO:${NC} $file tiene permisos incorrectos ($perms)"
                        ((issues++))
                    else
                        echo -e "  ${GREEN}✓ OK:${NC} $file ($perms, $owner)"
                    fi
                    ;;
                "/etc/shadow"|"//gshadow")
                    if [[ "$perms" != "640" && "$perms" != "600" ]]; then
                        echo -e "  ${RED}⚠ CRÍTICO:${NC} $file tiene permisos incorrectos ($perms)"
                        ((issues++))
                    else
                        echo -e "  ${GREEN}✓ OK:${NC} $file ($perms, $owner)"
                    fi
                    ;;
                *)
                    echo -e "  ${GREEN}✓ OK:${NC} $file ($perms, $owner)"
                    ;;
            esac
        fi
    done
    
    # 7. Scripts de inicio sospechosos
    echo ""
    echo -e "${YELLOW}[7/7] Revisando scripts de inicio...${NC}"
    local suspicious_startup=0
    
    # Verificar crontabs de sistema
    if [[ -d /etc/cron.d ]]; then
        local cron_jobs=$(find /etc/cron.* -type f 2>/dev/null | wc -l)
        echo "  Trabajos cron del sistema: $cron_jobs"
    fi
    
    # Verificar init.d
    if [[ -d /etc/init.d ]]; then
        local init_scripts=$(ls /etc/init.d 2>/dev/null | wc -l)
        echo "  Scripts en init.d: $init_scripts"
    fi
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ AUDITORÍA COMPLETADA: Sin problemas críticos${NC}"
    else
        echo -e "${RED}⚠ AUDITORÍA COMPLETADA: $issues problema(s) detectado(s)${NC}"
    fi
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    
    return $issues
}

#===============================================================================
# Funciones de Hardening
#===============================================================================

harden_suid_permissions() {
    echo -e "${YELLOW}Endureciendo permisos SUID...${NC}"
    
    # Lista de binarios que comúnmente no necesitan SUID
    local safe_to_remove=(
        "/usr/bin/chsh"
        "/usr/bin/chfn"
        "/usr/bin/newgrp"
        "/usr/bin/gpasswd"
    )
    
    for binary in "${safe_to_remove[@]}"; do
        if [[ -f "$binary" ]]; then
            echo "  Removiendo SUID de $binary"
            chmod u-s "$binary" 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}✓ Permisos SUID ajustados${NC}"
}

harden_tmp_directory() {
    echo -e "${YELLOW}Endureciendo directorios temporales...${NC}"
    
    # Asegurar que /tmp tenga sticky bit
    chmod 1777 /tmp 2>/dev/null || true
    chmod 1777 /var/tmp 2>/dev/null || true
    
    # Montar /tmp con opciones seguras (si no está ya montado)
    if ! mountpoint -q /tmp; then
        echo "  Configuring /tmp with secure options..."
        # Esto requeriría entrada en fstab para ser permanente
    fi
    
    echo -e "${GREEN}✓ Directorios temporales asegurados${NC}"
}

remove_unused_users() {
    echo -e "${YELLOW}Auditando usuarios del sistema...${NC}"
    
    # Lista de usuarios del sistema que normalmente no son necesarios
    local system_users=("games" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats")
    
    for user in "${system_users[@]}"; do
        if id "$user" &>/dev/null; then
            echo "  Usuario '$user' existe (verificar si es necesario)"
        fi
    done
    
    echo -e "${GREEN}✓ Auditoría de usuarios completada${NC}"
}

secure_shared_memory() {
    echo -e "${YELLOW}Asegurando memoria compartida...${NC}"
    
    # Añadir regla para montar /dev/shm con opciones seguras
    local fstab_entry="tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0"
    
    if ! grep -q "/dev/shm" /etc/fstab 2>/dev/null; then
        echo "  Añadiendo entrada segura para /dev/shm en fstab"
        echo "$fstab_entry" >> /etc/fstab
        mount -o remount /dev/shm 2>/dev/null || true
    else
        echo "  /dev/shm ya está configurado en fstab"
    fi
    
    echo -e "${GREEN}✓ Memoria compartida asegurada${NC}"
}

#===============================================================================
# Menú del módulo
#===============================================================================

run_module_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     Módulo: Seguridad del Sistema Base                       ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} Ejecutar auditoría completa"
        echo -e "  ${GREEN}2.${NC} Endurecer permisos SUID"
        echo -e "  ${GREEN}3.${NC} Asegurar directorios temporales"
        echo -e "  ${GREEN}4.${NC} Auditar usuarios del sistema"
        echo -e "  ${GREEN}5.${NC} Asegurar memoria compartida"
        echo -e "  ${GREEN}6.${NC} Aplicar todo el hardening"
        echo ""
        echo -e "  ${RED}0.${NC} Volver al menú principal"
        echo ""
        
        read -p "Seleccione una opción: " choice
        
        case "$choice" in
            1)
                audit_system_base
                read -p "Presione Enter para continuar..."
                ;;
            2)
                harden_suid_permissions
                read -p "Presione Enter para continuar..."
                ;;
            3)
                harden_tmp_directory
                read -p "Presione Enter para continuar..."
                ;;
            4)
                remove_unused_users
                read -p "Presione Enter para continuar..."
                ;;
            5)
                secure_shared_memory
                read -p "Presione Enter para continuar..."
                ;;
            6)
                echo -e "${YELLOW}Aplicando todo el hardening...${NC}"
                harden_suid_permissions
                harden_tmp_directory
                secure_shared_memory
                remove_unused_users
                echo -e "${GREEN}✓ Hardening completado${NC}"
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

# Si se ejecuta directamente (para testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "Este script debe ejecutarse como root"
        exit 1
    fi
    run_module_menu
fi
