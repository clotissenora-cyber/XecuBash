#!/bin/bash

################################################################################
# XecuBash - Tests de Firewall
################################################################################

test_firewall() {
    suite_title "PRUEBAS DE FIREWALL"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/modules/firewall-rules.sh" "Módulo de firewall existe"
    
    # Test: Función de verificación de estado
    test "Función check_firewall_status existe" "declare -f check_firewall_status"
    
    # Test: Función de habilitación
    test "Función enable_firewall existe" "declare -f enable_firewall"
    
    # Test: Función de deshabilitación
    test "Función disable_firewall existe" "declare -f disable_firewall"
    
    # Test: Función de agregar regla
    test "Función add_firewall_rule existe" "declare -f add_firewall_rule"
    
    # Test: Función de mostrar reglas
    test "Función show_firewall_rules existe" "declare -f show_firewall_rules"
    
    # Test: Función de reseteo
    test "Función reset_firewall existe" "declare -f reset_firewall"
    
    # Test: Archivo de configuración existe
    assert_file_exists "${PROJECT_ROOT}/config/firewall-rules.conf" "Archivo de configuración firewall existe"
    
    # Test: UFW o iptables disponible
    test "UFW o iptables disponible" "command -v ufw || command -v iptables"
    
    # Test: iptables disponible
    test "iptables disponible" "command -v iptables"
    
    echo ""
    echo "✓ Tests de firewall completados"
}