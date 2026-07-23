#!/bin/bash

################################################################################
# XecuBash - Utilidades de Pruebas
# Funciones auxiliares para el framework de testing
################################################################################

# Contador global de pruebas
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para definir un test
test() {
    local description="$1"
    local command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if eval "$command" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test con valor esperado
assert_equal() {
    local actual="$1"
    local expected="$2"
    local description="$3"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description (esperado: $expected, obtenido: $actual)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que comando existe
assert_command_exists() {
    local cmd="$1"
    local description="${2:-Comando $cmd existe}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que archivo existe
assert_file_exists() {
    local file="$1"
    local description="${2:-Archivo $file existe}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que archivo no existe
assert_file_not_exists() {
    local file="$1"
    local description="${2:-Archivo $file no existe}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ ! -f "$file" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que servicio está activo
assert_service_active() {
    local service="$1"
    local description="${2:-Servicio $service está activo}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if systemctl is-active "$service" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que puerto está abierto
assert_port_open() {
    local port="$1"
    local description="${2:-Puerto $port está abierto}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que parámetro kernel está configurado
assert_kernel_param() {
    local param="$1"
    local expected="$2"
    local description="${3:-Parámetro kernel $param = $expected}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local actual=$(sysctl -n "$param" 2>/dev/null)
    if [[ "$actual" == "$expected" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description (obtenido: $actual)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test que archivo tiene permisos correctos
assert_file_permissions() {
    local file="$1"
    local expected_perms="$2"
    local description="${3:-$file tiene permisos $expected_perms}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    local actual_perms=$(stat -c '%a' "$file" 2>/dev/null)
    if [[ "$actual_perms" == "$expected_perms" ]]; then
        echo -e "  ${GREEN}✓${NC} $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "  ${RED}✗${NC} $description (obtenido: $actual_perms)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Saltar test
skip_test() {
    local description="$1"
    local reason="${2:-Sin especificar}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    
    echo -e "  ${YELLOW}⊘${NC} $description (omitido: $reason)"
}

# Título de suite de pruebas
suite_title() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════════════════════${NC}"
}

# Benchmark de función
benchmark() {
    local description="$1"
    local command="$2"
    
    echo ""
    echo "⏱ $description"
    
    local start=$(date +%s%N)
    eval "$command" &>/dev/null
    local end=$(date +%s%N)
    
    local elapsed=$(( (end - start) / 1000000 ))
    echo "  Tiempo: ${elapsed}ms"
}

export TEST_DIR TESTS_RUN TESTS_PASSED TESTS_FAILED TESTS_SKIPPED