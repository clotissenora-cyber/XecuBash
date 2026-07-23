#!/bin/bash

################################################################################
# Gestión de snapshots y recuperación
################################################################################

SNAPSHOT_DIR="${BACKUPS_DIR}/snapshots"

# Crear snapshot del sistema
create_snapshot() {
    local description="${1:-Manual snapshot}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local snapshot_name="snapshot_${timestamp}"
    local snapshot_path="${SNAPSHOT_DIR}/${snapshot_name}"

    mkdir -p "$SNAPSHOT_DIR"

    log_info "Creando snapshot: $snapshot_name"
    log_info "Descripción: $description"

    # Crear directorio del snapshot
    mkdir -p "$snapshot_path"

    # Backup de archivos de configuración críticos
    local critical_files=(
        "/etc/ssh/sshd_config"
        "/etc/sudoers"
        "/etc/hosts"
        "/etc/fstab"
        "/etc/sysctl.conf"
        "/etc/ufw/ufw.conf"
        "/etc/resolv.conf"
    )

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            mkdir -p "$snapshot_path/$(dirname "$file")"
            cp -p "$file" "$snapshot_path/$file" 2>/dev/null || true
            log_debug "Backup: $file"
        fi
    done

    # Guardar información del snapshot
    cat > "${snapshot_path}/.metadata" << EOF
Snapshot Name: $snapshot_name
Creation Time: $(date '+%Y-%m-%d %H:%M:%S')
Description: $description
Hostname: $(hostname)
Kernel: $(uname -r)
EOF

    log_success "Snapshot creado: $snapshot_name"
    echo "$snapshot_path"
}

# Listar snapshots disponibles
list_snapshots() {
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        log_error "No hay snapshots disponibles"
        return 1
    fi

    log_info "Snapshots disponibles:"
    echo ""

    local count=0
    for snapshot in "$SNAPSHOT_DIR"/snapshot_*; do
        if [[ -d "$snapshot" ]]; then
            count=$((count + 1))
            local name=$(basename "$snapshot")
            local metadata_file="${snapshot}/.metadata"

            if [[ -f "$metadata_file" ]]; then
                local description=$(grep "Description:" "$metadata_file" | cut -d':' -f2- | xargs)
                local creation_time=$(grep "Creation Time:" "$metadata_file" | cut -d':' -f2- | xargs)
                echo "[$count] $name"
                echo "    Descripción: $description"
                echo "    Creado: $creation_time"
            fi
        fi
    done

    if [[ $count -eq 0 ]]; then
        log_warn "No hay snapshots disponibles"
        return 1
    fi

    return 0
}

# Restaurar desde snapshot
restore_snapshot() {
    local snapshot_name="${1:-}"

    if [[ -z "$snapshot_name" ]]; then
        list_snapshots
        read -p "Selecciona el número del snapshot a restaurar: " selection
        
        local count=0
        for snapshot in "$SNAPSHOT_DIR"/snapshot_*; do
            if [[ -d "$snapshot" ]]; then
                count=$((count + 1))
                if [[ $count -eq $selection ]]; then
                    snapshot_name=$(basename "$snapshot")
                    break
                fi
            fi
        done
    fi

    local snapshot_path="${SNAPSHOT_DIR}/${snapshot_name}"

    if [[ ! -d "$snapshot_path" ]]; then
        log_error "Snapshot no encontrado: $snapshot_name"
        return 1
    fi

    log_warn "Restaurando snapshot: $snapshot_name"
    read -p "¿Estás seguro? (s/n): " confirm

    if [[ "$confirm" != "s" ]]; then
        log_info "Restauración cancelada"
        return 0
    fi

    # Crear backup antes de restaurar
    local pre_restore="${SNAPSHOT_DIR}/pre_restore_$(date +%s)"
    mkdir -p "$pre_restore"
    
    # Restaurar archivos
    find "$snapshot_path" -type f ! -name ".metadata" | while read -r file; do
        local target_file="${file#$snapshot_path}"
        local target_dir=$(dirname "$target_file")
        
        # Crear backup del archivo actual
        if [[ -f "$target_file" ]]; then
            mkdir -p "$pre_restore/$target_dir"
            cp -p "$target_file" "$pre_restore/$target_file"
        fi
        
        # Restaurar archivo
        mkdir -p "$target_dir"
        cp -p "$file" "$target_file"
        log_debug "Restaurado: $target_file"
    done

    log_success "Snapshot restaurado: $snapshot_name"
    log_info "Backup de pre-restauración en: $pre_restore"

    return 0
}

# Eliminar snapshot
delete_snapshot() {
    local snapshot_name="$1"
    local snapshot_path="${SNAPSHOT_DIR}/${snapshot_name}"

    if [[ ! -d "$snapshot_path" ]]; then
        log_error "Snapshot no encontrado: $snapshot_name"
        return 1
    fi

    log_warn "Eliminando snapshot: $snapshot_name"
    read -p "¿Estás seguro? (s/n): " confirm

    if [[ "$confirm" != "s" ]]; then
        log_info "Eliminación cancelada"
        return 0
    fi

    rm -rf "$snapshot_path"
    log_success "Snapshot eliminado: $snapshot_name"

    return 0
}

# Función para revertir cambios
revert_changes() {
    list_snapshots
    restore_snapshot
}
