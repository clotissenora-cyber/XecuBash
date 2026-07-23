#!/bin/bash

################################################################################
# XecuBash - Suite de Pruebas Principal
# Framework de testing para todos los módulos
################################################################################

set -euo pipefail

# Variables globales
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
TEST_RESULTS_DIR="${TEST_DIR}/results"
TEST_LOG="${TEST_RESULTS_DIR}/test-run-$(date +%Y%m%d_%H%M%S).log"

# Contadores
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

# Crear directorio de resultados
mkdir -p "$TEST_RESULTS_DIR"

# Importar funciones de prueba
source "${TEST_DIR}/test-utils.sh"

# Banner
echo ""
echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║                    XecuBash - Suite de Pruebas Unitarias                       ║"
echo "║                           Versión 1.0.0                                       ║"
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
echo ""

# Verificar permisos
if [[ $EUID -ne 0 ]]; then
    echo "⚠ Advertencia: Algunos tests requieren permisos de root"
fi

# Ejecutar suites de pruebas
run_test_suites() {
    echo ""
    echo "▶ Iniciando ejecución de suites de pruebas..."
    echo ""

    echo "[1/9] Ejecutando tests de validadores..."
    if [[ -f "${TEST_DIR}/test-validators.sh" ]]; then
        source "${TEST_DIR}/test-validators.sh"
        test_validators 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[2/9] Ejecutando tests de auditoría..."
    if [[ -f "${TEST_DIR}/test-audit.sh" ]]; then
        source "${TEST_DIR}/test-audit.sh"
        test_audit 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[3/9] Ejecutando tests de hardening..."
    if [[ -f "${TEST_DIR}/test-hardening.sh" ]]; then
        source "${TEST_DIR}/test-hardening.sh"
        test_hardening 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[4/9] Ejecutando tests de seguridad de red..."
    if [[ -f "${TEST_DIR}/test-network.sh" ]]; then
        source "${TEST_DIR}/test-network.sh"
        test_network 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[5/9] Ejecutando tests de DNSCrypt..."
    if [[ -f "${TEST_DIR}/test-dnscrypt.sh" ]]; then
        source "${TEST_DIR}/test-dnscrypt.sh"
        test_dnscrypt 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[6/9] Ejecutando tests de firewall..."
    if [[ -f "${TEST_DIR}/test-firewall.sh" ]]; then
        source "${TEST_DIR}/test-firewall.sh"
        test_firewall 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[7/9] Ejecutando tests de anonimato..."
    if [[ -f "${TEST_DIR}/test-anonymity.sh" ]]; then
        source "${TEST_DIR}/test-anonymity.sh"
        test_anonymity 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[8/9] Ejecutando tests de identificadores..."
    if [[ -f "${TEST_DIR}/test-identifiers.sh" ]]; then
        source "${TEST_DIR}/test-identifiers.sh"
        test_identifiers 2>&1 | tee -a "$TEST_LOG"
    fi

    echo ""
    echo "[9/9] Ejecutando tests de reporting..."
    if [[ -f "${TEST_DIR}/test-reporting.sh" ]]; then
        source "${TEST_DIR}/test-reporting.sh"
        test_reporting 2>&1 | tee -a "$TEST_LOG"
    fi
}

# Mostrar resumen de pruebas
show_test_summary() {
    echo ""
    echo "═════════════════════════════════════════════════════════════════════════════════"
    echo "                              RESUMEN DE PRUEBAS"
    echo "═════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Total de pruebas ejecutadas: $TESTS_RUN"
    echo -e "  ${GREEN}✓ Pruebas exitosas: $TESTS_PASSED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "  ${RED}✗ Pruebas fallidas: $TESTS_FAILED${NC}"
    else
        echo -e "  ${RED}✗ Pruebas fallidas: $TESTS_FAILED${NC}"
    fi
    
    if [[ $TESTS_SKIPPED -gt 0 ]]; then
        echo -e "  ${YELLOW}⊘ Pruebas omitidas: $TESTS_SKIPPED${NC}"
    fi
    echo ""
    
    # Calcular porcentaje
    if [[ $TESTS_RUN -gt 0 ]]; then
        local success_rate=$(( (TESTS_PASSED * 100) / TESTS_RUN ))
        echo "  Tasa de éxito: ${success_rate}%"
        echo ""
        
        if [[ $success_rate -ge 90 ]]; then
            echo -e "  ${GREEN}✓ Resultado: APROBADO${NC}"
        elif [[ $success_rate -ge 70 ]]; then
            echo -e "  ${YELLOW}⚠ Resultado: PARCIAL${NC}"
        else
            echo -e "  ${RED}✗ Resultado: FALLIDO${NC}"
        fi
    fi
    echo ""
    echo "═════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Log completo: $TEST_LOG"
    echo ""
}

# Punto de entrada
main() {
    # Crear encabezado de log
    {
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo "XecuBash - Test Suite"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Sistema: $(uname -a)"
        echo "════════════════════════════════════════════════════════════════════════════════"
        echo ""
    } > "$TEST_LOG"
    
    # Ejecutar pruebas
    run_test_suites
    
    # Mostrar resumen
    show_test_summary
    
    # Retornar código de salida
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Ejecutar
main "$@"