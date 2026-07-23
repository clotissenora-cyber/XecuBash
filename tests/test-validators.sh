#!/bin/bash

################################################################################
# XecuBash - Tests de Validadores
################################################################################

test_validators() {
    suite_title "PRUEBAS DE VALIDADORES"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/utils/validator.sh" "Módulo de validadores existe"
    
    # Test: Función de validación de Debian 13
    test "Función validate_debian_13 existe" "declare -f validate_debian_13"
    
    # Test: Función de validación de dependencias
    test "Función validate_dependencies existe" "declare -f validate_dependencies"
    
    # Test: Función de validación de permisos
    test "Función validate_file_permissions existe" "declare -f validate_file_permissions"
    
    # Test: Función de validación de servicio
    test "Función validate_service_exists existe" "declare -f validate_service_exists"
    
    # Test: Función de validación de puerto
    test "Función validate_port_open existe" "declare -f validate_port_open"
    
    # Test: Función de validación de IP
    test "Función validate_ip existe" "declare -f validate_ip"
    
    # Test: Función de validación de IPv6
    test "Función validate_ipv6 existe" "declare -f validate_ipv6"
    
    # Test: Función de validación de MAC
    test "Función validate_mac existe" "declare -f validate_mac"
    
    # Test: Bash 4.0+
    test "Bash versión 4.0+" "[[ ${BASH_VERSINFO[0]} -ge 4 ]]"
    
    # Test: Systemd disponible
    assert_command_exists "systemctl" "systemctl disponible"
    
    # Test: grep disponible
    assert_command_exists "grep" "grep disponible"
    
    echo ""
    echo "✓ Tests de validadores completados"
}