#!/bin/bash

################################################################################
# XecuBash - Tests de Seguridad de Red
################################################################################

test_network() {
    suite_title "PRUEBAS DE SEGURIDAD DE RED"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/modules/network-security.sh" "Módulo de seguridad de red existe"
    
    # Test: Función de auditoría de puertos
    test "Función audit_network_ports existe" "declare -f audit_network_ports"
    
    # Test: Función de configuración SSH
    test "Función configure_ssh_security existe" "declare -f configure_ssh_security"
    
    # Test: Función de auditoría SSL/TLS
    test "Función audit_ssl_certificates existe" "declare -f audit_ssl_certificates"
    
    # Test: Función de auditoría de conexiones
    test "Función audit_network_connections existe" "declare -f audit_network_connections"
    
    # Test: netstat disponible
    test "netstat disponible" "command -v netstat"
    
    # Test: ss disponible
    test "ss disponible" "command -v ss"
    
    # Test: SSH está instalado
    assert_command_exists "sshd" "SSH server instalado"
    
    # Test: Verificar archivo SSH config
    assert_file_exists "/etc/ssh/sshd_config" "Configuración SSH existe"
    
    # Test: curl disponible
    test "curl disponible" "command -v curl"
    
    echo ""
    echo "✓ Tests de seguridad de red completados"
}