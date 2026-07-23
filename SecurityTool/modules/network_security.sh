#!/bin/bash
#===============================================================================
# Módulo: Seguridad de Red
# Descripción: Auditoría y hardening de configuración de red para Debian 13
#===============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#===============================================================================
# Funciones de Auditoría de Red
#===============================================================================

audit_network() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}AUDITORÍA DE SEGURIDAD DE RED${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local issues=0
    
    # 1. Puertos abiertos
    echo -e "${YELLOW}[1/6] Escaneando puertos abiertos...${NC}"
    local open_ports=$(ss -tlnp 2>/dev/null | grep LISTEN | wc -l)
    echo "  Puertos TCP escuchando: $open_ports"
    
    ss -tlnp 2>/dev/null | grep LISTEN | head -10 | while read line; do
        echo "    $line"
    done
    
    # Verificar puertos peligrosos comunes
    local dangerous_ports=("21" "23" "25" "110" "143" "445" "3389")
    for port in "${dangerous_ports[@]}"; do
        if ss -tlnp 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${RED}⚠ PELIGRO:${NC} Puerto $port abierto (servicio potencialmente inseguro)"
            ((issues++))
        fi
    done
    
    # 2. Conexiones establecidas
    echo ""
    echo -e "${YELLOW}[2/6] Analizando conexiones establecidas...${NC}"
    local established=$(ss -tnp state established 2>/dev/null | wc -l)
    echo "  Conexiones establecidas: $established"
    
    ss -tnp state established 2>/dev/null | head -5 | while read line; do
        echo "    $line"
    done
    
    # 3. Configuración IP forwarding
    echo ""
    echo -e "${YELLOW}[3/6] Verificando IP forwarding...${NC}"
    local ipv4_forward=$(sysctl net.ipv4.ip_forward 2>/dev/null | cut -d' ' -f3)
    local ipv6_forward=$(sysctl net.ipv6.conf.all.forwarding 2>/dev/null | cut -d' ' -f3)
    
    if [[ "$ipv4_forward" == "1" ]]; then
        echo -e "  ${YELLOW}⚠ WARN:${NC} IPv4 forwarding está ACTIVADO ($ipv4_forward)"
        ((issues++))
    else
        echo -e "  ${GREEN}✓ OK:${NC} IPv4 forwarding desactivado"
    fi
    
    if [[ "$ipv6_forward" == "1" ]]; then
        echo -e "  ${YELLOW}⚠ WARN:${NC} IPv6 forwarding está ACTIVADO ($ipv6_forward)"
        ((issues++))
    else
        echo -e "  ${GREEN}✓ OK:${NC} IPv6 forwarding desactivado"
    fi
    
    # 4. Estado del firewall
    echo ""
    echo -e "${YELLOW}[4/6] Verificando estado del firewall...${NC}"
    
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status 2>/dev/null | head -1)
        if echo "$ufw_status" | grep -q "active"; then
            echo -e "  ${GREEN}✓ OK:${NC} UFW está activo"
            ufw status 2>/dev/null | tail -n +2 | head -5 | sed 's/^/    /'
        else
            echo -e "  ${RED}⚠ CRÍTICO:${NC} UFW está INACTIVO"
            ((issues++))
        fi
    elif command -v iptables &> /dev/null; then
        local iptables_rules=$(iptables -L -n 2>/dev/null | wc -l)
        if [[ $iptables_rules -gt 10 ]]; then
            echo -e "  ${GREEN}✓ OK:${NC} iptables tiene $iptables_rules reglas configuradas"
        else
            echo -e "  ${YELLOW}⚠ WARN:${NC} iptables tiene pocas reglas ($iptables_rules)"
            ((issues++))
        fi
    else
        echo -e "  ${RED}⚠ CRÍTICO:${NC} No hay firewall disponible"
        ((issues++))
    fi
    
    # 5. Configuración de interfaces de red
    echo ""
    echo -e "${YELLOW}[5/6] Auditando interfaces de red...${NC}"
    
    ip addr show 2>/dev/null | grep -E "^[0-9]+:|inet " | head -20 | while read line; do
        echo "    $line"
    done
    
    # Verificar interfaces en modo promiscuo
    local promisc_interfaces=$(ip link show 2>/dev/null | grep -c "PROMISC")
    if [[ $promisc_interfaces -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ WARN:${NC} $promisc_interfaces interface(s) en modo promiscuo"
        ((issues++))
    else
        echo -e "  ${GREEN}✓ OK:${NC} No hay interfaces en modo promiscuo"
    fi
    
    # 6. DNS configurado
    echo ""
    echo -e "${YELLOW}[6/6] Verificando configuración DNS...${NC}"
    
    if [[ -f /etc/resolv.conf ]]; then
        echo "  Servidores DNS configurados:"
        grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | sed 's/^/    - /'
        
        # Verificar si usa DNS seguros
        if grep -q "1.1.1.1\|1.0.0.1\|9.9.9.9\|8.8.8.8" /etc/resolv.conf 2>/dev/null; then
            echo -e "  ${GREEN}✓ OK:${NC} Usa DNS públicos conocidos"
        else
            echo -e "  ${BLUE}ℹ INFO:${NC} Considera usar DNS seguros (1.1.1.1, 9.9.9.9)"
        fi
    else
        echo -e "  ${RED}⚠ ERROR:${NC} /etc/resolv.conf no encontrado"
        ((issues++))
    fi
    
    echo ""
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    if [[ $issues -eq 0 ]]; then
        echo -e "${GREEN}✓ AUDITORÍA DE RED COMPLETADA: Sin problemas críticos${NC}"
    else
        echo -e "${RED}⚠ AUDITORÍA DE RED COMPLETADA: $issues problema(s) detectado(s)${NC}"
    fi
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
    
    return $issues
}

#===============================================================================
# Funciones de Hardening de Red
#===============================================================================

disable_ip_forwarding() {
    echo -e "${YELLOW}Desactivando IP forwarding...${NC}"
    
    # IPv4
    sysctl -w net.ipv4.ip_forward=0 2>/dev/null || true
    echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
    
    # IPv6
    sysctl -w net.ipv6.conf.all.forwarding=0 2>/dev/null || true
    echo "net.ipv6.conf.all.forwarding = 0" >> /etc/sysctl.conf
    
    echo -e "${GREEN}✓ IP forwarding desactivado${NC}"
}

harden_kernel_network_params() {
    echo -e "${YELLOW}Endureciendo parámetros de red del kernel...${NC}"
    
    # Protección contra SYN flood
    sysctl -w net.ipv4.tcp_syncookies=1 2>/dev/null || true
    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
    
    # Ignorar broadcasts ICMP
    sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1 2>/dev/null || true
    echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
    
    # Proteger contra spoofing
    sysctl -w net.ipv4.conf.all.rp_filter=1 2>/dev/null || true
    sysctl -w net.ipv4.conf.default.rp_filter=1 2>/dev/null || true
    echo "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf
    
    # Ignorar redirecciones ICMP
    sysctl -w net.ipv4.conf.all.accept_redirects=0 2>/dev/null || true
    sysctl -w net.ipv4.conf.default.accept_redirects=0 2>/dev/null || true
    echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
    
    # Deshabilitar source routing
    sysctl -w net.ipv4.conf.all.accept_source_route=0 2>/dev/null || true
    sysctl -w net.ipv4.conf.default.accept_source_route=0 2>/dev/null || true
    echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
    echo "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
    
    # Log martian packets
    sysctl -w net.ipv4.conf.all.log_martians=1 2>/dev/null || true
    echo "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf
    
    echo -e "${GREEN}✓ Parámetros de red endurecidos${NC}"
}

setup_basic_firewall() {
    echo -e "${YELLOW}Configurando firewall básico...${NC}"
    
    if command -v ufw &> /dev/null; then
        # Resetear UFW
        ufw --force reset 2>/dev/null || true
        
        # Políticas por defecto
        ufw default deny incoming 2>/dev/null || true
        ufw default allow outgoing 2>/dev/null || true
        
        # Permitir SSH (puerto 22)
        ufw allow 22/tcp 2>/dev/null || true
        
        # Permitir HTTP/HTTPS si es servidor web
        # ufw allow 80/tcp
        # ufw allow 443/tcp
        
        # Habilitar UFW
        echo "y" | ufw enable 2>/dev/null || true
        
        echo -e "${GREEN}✓ Firewall UFW configurado${NC}"
    else
        echo -e "${YELLOW}⚠ UFW no instalado. Instalando...${NC}"
        apt-get update -qq && apt-get install -y ufw 2>/dev/null || true
        
        if command -v ufw &> /dev/null; then
            setup_basic_firewall
        else
            echo -e "${RED}✗ No se pudo instalar UFW${NC}"
        fi
    fi
}

disable_ipv6_if_not_needed() {
    echo -e "${YELLOW}Evaluando IPv6...${NC}"
    
    read -p "¿Desea deshabilitar IPv6? (y/N): " confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
        sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true
        
        echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
        
        echo -e "${GREEN}✓ IPv6 deshabilitado${NC}"
    else
        echo -e "${BLUE}ℹ IPv6 mantenido habilitado${NC}"
    fi
}

list_network_connections() {
    echo -e "${CYAN}Conexiones de red activas:${NC}"
    echo ""
    
    echo "TCP Establecidas:"
    ss -tnp state established 2>/dev/null | head -15
    
    echo ""
    echo "Puertos Escuchando:"
    ss -tlnp 2>/dev/null | grep LISTEN | head -15
    
    echo ""
    echo "Conexiones UDP:"
    ss -unlp 2>/dev/null | head -10
}

#===============================================================================
# Menú del módulo
#===============================================================================

run_module_menu() {
    while true; do
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║     Módulo: Seguridad de Red                                 ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1.${NC} Ejecutar auditoría de red"
        echo -e "  ${GREEN}2.${NC} Listar conexiones activas"
        echo -e "  ${GREEN}3.${NC} Desactivar IP forwarding"
        echo -e "  ${GREEN}4.${NC} Endurecer parámetros de red del kernel"
        echo -e "  ${GREEN}5.${NC} Configurar firewall básico (UFW)"
        echo -e "  ${GREEN}6.${NC} Evaluar IPv6"
        echo -e "  ${GREEN}7.${NC} Aplicar todo el hardening de red"
        echo ""
        echo -e "  ${RED}0.${NC} Volver al menú principal"
        echo ""
        
        read -p "Seleccione una opción: " choice
        
        case "$choice" in
            1)
                audit_network
                read -p "Presione Enter para continuar..."
                ;;
            2)
                list_network_connections
                read -p "Presione Enter para continuar..."
                ;;
            3)
                disable_ip_forwarding
                read -p "Presione Enter para continuar..."
                ;;
            4)
                harden_kernel_network_params
                read -p "Presione Enter para continuar..."
                ;;
            5)
                setup_basic_firewall
                read -p "Presione Enter para continuar..."
                ;;
            6)
                disable_ipv6_if_not_needed
                read -p "Presione Enter para continuar..."
                ;;
            7)
                echo -e "${YELLOW}Aplicando todo el hardening de red...${NC}"
                disable_ip_forwarding
                harden_kernel_network_params
                setup_basic_firewall
                echo -e "${GREEN}✓ Hardening de red completado${NC}"
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
