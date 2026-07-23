#!/bin/bash

################################################################################
# XecuBash - Tests del Módulo de Hardening
################################################################################

test_hardening() {
    suite_title "PRUEBAS DE HARDENING"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/modules/system-hardening.sh" "Módulo de hardening existe"
    
    # Test: Función de hardening de kernel
    test "Función harden_kernel existe" "declare -f harden_kernel"
    
    # Test: Función de hardening de permisos
    test "Función harden_permissions existe" "declare -f harden_permissions"
    
    # Test: Función de hardening de servicios
    test "Función harden_services existe" "declare -f harden_services"
    
    # Test: Función de hardening de shell
    test "Función harden_shell existe" "declare -f harden_shell"
    
    # Test: Función de auditoría
    test "Función setup_audit_daemon existe" "declare -f setup_audit_daemon"
    
    # Test: Verificar permisos de /etc/passwd
    assert_file_permissions "/etc/passwd" "644" "Permisos de /etc/passwd correctos"
    
    # Test: Verificar permisos de /etc/shadow
    assert_file_permissions "/etc/shadow" "600" "Permisos de /etc/shadow correctos"
    
    # Test: Verificar permisos de /etc/sudoers
    assert_file_permissions "/etc/sudoers" "440" "Permisos de /etc/sudoers correctos"
    
    # Test: sysctl está disponible
    assert_command_exists "sysctl" "Comando sysctl disponible"
    
    echo ""
    echo "✓ Tests de hardening completados"
}