#!/bin/bash

################################################################################
# Módulo de Reportes - XecuBash
# Generación de reportes de seguridad
################################################################################

reporting_main() {
    log_info "Iniciando generación de reportes..."
    
    local format="text"
    local output_file=""
    
    for arg in "$@"; do
        case $arg in
            --format) format="${arg#*=}" ;;
            --output) output_file="${arg#*=}" ;;
        esac
    done

    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "                    GENERACIÓN DE REPORTES"
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo ""

    # Si no hay parámetros, mostrar menú
    if [[ -z "$format" || "$format" == "main" ]]; then
        show_report_menu
    else
        generate_report "$format" "$output_file"
    fi
}

# Menú de reportes
show_report_menu() {
    clear
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│                      MENÚ GENERACIÓN DE REPORTES                            │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│                                                                             │"
    echo "│ 1. Reporte en texto (TXT)                                                  │"
    echo "│ 2. Reporte en HTML                                                         │"
    echo "│ 3. Reporte en JSON                                                         │"
    echo "│ 4. Reporte de auditoría rápida                                             │"
    echo "│ 5. Reporte de seguridad completa                                           │"
    echo "│ 6. Ver reportes anteriores                                                 │"
    echo "│ 7. Salir                                                                   │"
    echo "│                                                                             │"
    echo "└─────────────────────────────────────────────────────────────────────────────┘"
    echo ""
    
    read -p "Selecciona opción (1-7): " choice

    case $choice in
        1) generate_report "text" ;;
        2) generate_report "html" ;;
        3) generate_report "json" ;;
        4) generate_quick_audit_report ;;
        5) generate_full_security_report ;;
        6) view_previous_reports ;;
        7) return 0 ;;
        *) log_error "Opción inválida" ;;
    esac
}

# Generar reporte
generate_report() {
    local format="$1"
    local output_file="$2"

    if [[ -z "$output_file" ]]; then
        output_file="${PROJECT_ROOT}/reports/security_report_$(date +%Y%m%d_%H%M%S).$format"
    fi

    mkdir -p "$(dirname "$output_file")"

    log_info "Generando reporte en formato $format..."
    echo ""

    case $format in
        text|txt)
            generate_text_report "$output_file"
            ;;
        html)
            generate_html_report "$output_file"
            ;;
        json)
            generate_json_report "$output_file"
            ;;
        *)
            log_error "Formato desconocido: $format"
            return 1
            ;;
    esac

    log_success "Reporte generado: $output_file"
    echo ""
    echo "Ubicación: $output_file"
}

# Generar reporte en texto
generate_text_report() {
    local output_file="$1"

    cat > "$output_file" << EOF
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        REPORTE DE SEGURIDAD XECUBASH                          ║
║                         $(date '+%Y-%m-%d %H:%M:%S')                             ║
╚═══════════════════════════════════════════════════════════════════════════════╝

1. INFORMACIÓN DEL SISTEMA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hostname: $(hostname)
Sistema Operativo: $(lsb_release -d | cut -f2)
Kernel: $(uname -r)
Arquitectura: $(uname -m)
Usuario: $(whoami)
Uptime: $(uptime -p)

2. AUDITORÍA DE SEGURIDAD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Firewall: $(systemctl is-active ufw 2>/dev/null || echo "Inactivo")
SSH: $(systemctl is-active ssh 2>/dev/null || echo "Inactivo")
Auditd: $(systemctl is-active auditd 2>/dev/null || echo "Inactivo")

3. USUARIOS Y PERMISOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usuarios activos:
EOF
    getent passwd | awk -F: '$3 >= 1000 {print "  - " $1}' >> "$output_file"
    
    cat >> "$output_file" << EOF

Grupo sudo:
EOF
    getent group sudo | cut -d: -f4 | tr ',' '\n' | while read user; do 
        [[ -n "$user" ]] && echo "  - $user" >> "$output_file"
    done

    cat >> "$output_file" << EOF

4. PUERTOS Y SERVICIOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Puertos escuchando:
EOF
    if command_exists ss; then
        ss -tulpn 2>/dev/null | grep LISTEN | awk '{print "  " $4 " - " $7}' >> "$output_file"
    fi

    cat >> "$output_file" << EOF

5. VULNERABILIDADES DETECTADAS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Se necesita ejecutar auditoría detallada]

6. RECOMENDACIONES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Ejecutar auditoría completa regularmente
  2. Mantener el sistema actualizado
  3. Configurar SSH con claves públicas
  4. Habilitar firewall
  5. Revisar logs regularmente

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Fin del Reporte
EOF
}

# Generar reporte HTML
generate_html_report() {
    local output_file="$1"

    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>XecuBash - Reporte de Seguridad</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #007bff; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: green; }
        .warning { color: orange; }
        .danger { color: red; }
    </style>
</head>
<body>
    <h1>🔐 XecuBash - Reporte de Seguridad</h1>
    <p>Generado: <strong>EOF
    date '+%Y-%m-%d %H:%M:%S' >> "$output_file"
    cat >> "$output_file" << 'EOF'
</strong></p>

    <h2>Información del Sistema</h2>
    <table>
        <tr><th>Parámetro</th><th>Valor</th></tr>
EOF
    
    echo "<tr><td>Hostname</td><td>$(hostname)</td></tr>" >> "$output_file"
    echo "<tr><td>Sistema Operativo</td><td>$(lsb_release -d | cut -f2)</td></tr>" >> "$output_file"
    echo "<tr><td>Kernel</td><td>$(uname -r)</td></tr>" >> "$output_file"
    
    cat >> "$output_file" << 'EOF'
    </table>

    <h2>Estado de Servicios</h2>
    <table>
        <tr><th>Servicio</th><th>Estado</th></tr>
EOF
    
    local ufw_status=$(systemctl is-active ufw 2>/dev/null || echo "Inactivo")
    echo "<tr><td>Firewall (UFW)</td><td class='$([ "$ufw_status" = "active" ] && echo success || echo danger)'>$ufw_status</td></tr>" >> "$output_file"
    
    cat >> "$output_file" << 'EOF'
    </table>

</body>
</html>
EOF
}

# Generar reporte JSON
generate_json_report() {
    local output_file="$1"

    cat > "$output_file" << EOF
{
  "report": {
    "title": "XecuBash Security Report",
    "timestamp": "$(date -Iseconds)",
    "system": {
      "hostname": "$(hostname)",
      "os": "$(lsb_release -d | cut -f2)",
      "kernel": "$(uname -r)",
      "architecture": "$(uname -m)"
    },
    "services": {
      "firewall": "$(systemctl is-active ufw 2>/dev/null || echo 'inactive')",
      "ssh": "$(systemctl is-active ssh 2>/dev/null || echo 'inactive')",
      "auditd": "$(systemctl is-active auditd 2>/dev/null || echo 'inactive')"
    }
  }
}
EOF
}

# Generar reporte de auditoría rápida
generate_quick_audit_report() {
    log_info "Generando reporte de auditoría rápida..."
    echo ""
    echo "[*] AUDITORÍA RÁPIDA:"
    echo ""
    
    local score=100
    
    # Verificar firewall
    if ! systemctl is-active ufw &>/dev/null; then
        echo "✗ Firewall deshabilitado (-10 pts)"
        score=$((score - 10))
    else
        echo "✓ Firewall habilitado"
    fi
    
    # Verificar SSH
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config 2>/dev/null; then
        echo "✗ PermitRootLogin habilitado (-15 pts)"
        score=$((score - 15))
    else
        echo "✓ PermitRootLogin deshabilitado"
    fi
    
    # Verificar permisos sudo
    if grep -q "NOPASSWD" /etc/sudoers 2>/dev/null; then
        echo "✗ Sudoers sin contraseña (-20 pts)"
        score=$((score - 20))
    else
        echo "✓ Sudoers protegido"
    fi
    
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════════"
    echo "Puntuación de seguridad: $score/100"
    echo "═══════════════════════════════════════════════════════════════════════════════"
}

# Generar reporte de seguridad completa
generate_full_security_report() {
    log_info "Generando reporte de seguridad completa..."
    source "${MODULES_DIR}/audit.sh"
    audit_main
}

# Ver reportes anteriores
view_previous_reports() {
    local reports_dir="${PROJECT_ROOT}/reports"
    
    if [[ ! -d "$reports_dir" ]]; then
        log_error "No hay reportes disponibles"
        return 1
    fi

    log_info "Reportes disponibles:"
    echo ""
    ls -lh "$reports_dir" | tail -n +2 | awk '{print $NF}'
}
