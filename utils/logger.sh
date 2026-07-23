#!/bin/bash

################################################################################
# Sistema de Logging para XecuBash
################################################################################

# Colores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Niveles de logging
LOG_LEVEL="${LOG_LEVEL:-INFO}"
LOG_FILE="${LOGS_DIR}/security-tool.log"

# Mapeo de niveles
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)

# Función de logging interno
_log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"

    # Verificar si el nivel debe ser mostrado
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        # Escribir al archivo de log
        echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true

        # Mostrar en pantalla con color
        case $level in
            DEBUG)
                echo -e "${BLUE}[DEBUG]${NC} $message" >&2
                ;;
            INFO)
                echo -e "${GREEN}[INFO]${NC} $message"
                ;;
            WARN)
                echo -e "${YELLOW}[WARN]${NC} $message" >&2
                ;;
            ERROR)
                echo -e "${RED}[ERROR]${NC} $message" >&2
                ;;
        esac
    fi
}

# Funciones de logging públicas
log_debug() {
    _log "DEBUG" "$1"
}

log_info() {
    _log "INFO" "$1"
}

log_warn() {
    _log "WARN" "$1"
}

log_error() {
    _log "ERROR" "$1"
}

# Log de éxito
log_success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Log de fallo
log_fail() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FAIL] $message" >> "$LOG_FILE" 2>/dev/null || true
}

# Inicializar archivo de log
init_log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    log_info "====== XecuBash iniciado ======"
    log_info "Versión: $VERSION"
    log_info "Hostname: $(hostname)"
    log_info "Usuario: $(whoami)"
    log_info "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
}

# Función para mostrar tabla de resultados
log_table() {
    local title="$1"
    local columns="$2"
    
    echo ""
    echo "┌─────────────────────────────────────────┐"
    echo "│ $title"
    echo "├─────────────────────────────────────────┤"
    echo "│ $columns"
    echo "└─────────────────────────────────────────┘"
}

# Inicializar log si no existe
if [[ ! -f "$LOG_FILE" ]]; then
    init_log
fi
