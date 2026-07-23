#!/bin/bash

################################################################################
# Validación de cambios y verificación de integridad
################################################################################

# Validar que el comando existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Validar que es Debian 13
validate_debian_13() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "No se puede determinar la distribución"
        return 1
    fi

    source /etc/os-release
    
    if [[ "$ID" != "debian" ]]; then
        log_error "Este script está diseñado para Debian. Sistema detectado: $ID"
        return 1
    fi

    if [[ "$VERSION_ID" != "13" ]]; then
        log_warn "Se recomienda Debian 13. Versión detectada: $VERSION_ID"
    fi

    log_success "Sistema validado: $NAME $VERSION_ID"
    return 0
}

# Validar dependencias
validate_dependencies() {
    local deps=("bash" "systemctl" "curl" "wget" "grep" "sed" "awk")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Dependencias faltantes: ${missing[*]}"
        return 1
    fi

    log_success "Todas las dependencias están instaladas"
    return 0
}

# Validar permisos de archivo
validate_file_permissions() {
    local file="$1"
    local expected_mode="$2"

    if [[ ! -e "$file" ]]; then
        log_error "Archivo no existe: $file"
        return 1
    fi

    local actual_mode=$(stat -c '%a' "$file")
    
    if [[ "$actual_mode" != "$expected_mode" ]]; then
        log_warn "Permisos incorrectos en $file: $actual_mode (esperado: $expected_mode)"
        return 1
    fi

    log_debug "Permisos validados para $file: $actual_mode"
    return 0
}

# Validar que el servicio existe
validate_service_exists() {
    local service="$1"
    
    if ! systemctl list-unit-files | grep -q "^${service}.service"; then
        log_error "Servicio no encontrado: $service"
        return 1
    fi

    log_debug "Servicio validado: $service"
    return 0
}

# Validar puerto abierto
validate_port_open() {
    local port="$1"
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        log_debug "Puerto $port está en uso"
        return 0
    fi

    log_debug "Puerto $port está cerrado"
    return 1
}

# Validar dirección IP
validate_ip() {
    local ip="$1"
    
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi

    log_error "Dirección IP inválida: $ip"
    return 1
}

# Validar IPv6
validate_ipv6() {
    local ipv6="$1"
    
    # Validación simplificada para IPv6
    if [[ $ipv6 =~ ^[0-9a-fA-F:]+$ ]]; then
        return 0
    fi

    log_error "Dirección IPv6 inválida: $ipv6"
    return 1
}

# Validar MAC address
validate_mac() {
    local mac="$1"
    
    if [[ $mac =~ ^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$ ]]; then
        return 0
    fi

    log_error "Dirección MAC inválida: $mac"
    return 1
}

# Validar cambio de configuración
validate_config_change() {
    local config_file="$1"
    local backup_file="${config_file}.backup.$(date +%s)"

    if [[ ! -f "$config_file" ]]; then
        log_error "Archivo de configuración no encontrado: $config_file"
        return 1
    fi

    # Crear backup
    cp "$config_file" "$backup_file"
    log_debug "Backup creado: $backup_file"

    return 0
}

# Comparar archivos
compare_files() {
    local file1="$1"
    local file2="$2"

    if diff -q "$file1" "$file2" > /dev/null 2>&1; then
        log_debug "Archivos idénticos"
        return 0
    fi

    log_debug "Archivos diferentes"
    return 1
}

# Validación de integridad (checksum)
validate_checksum() {
    local file="$1"
    local expected_checksum="$2"

    if [[ ! -f "$file" ]]; then
        log_error "Archivo no encontrado: $file"
        return 1
    fi

    local actual_checksum=$(sha256sum "$file" | awk '{print $1}')

    if [[ "$actual_checksum" != "$expected_checksum" ]]; then
        log_error "Checksum no coincide para $file"
        return 1
    fi

    log_success "Checksum validado para $file"
    return 0
}
