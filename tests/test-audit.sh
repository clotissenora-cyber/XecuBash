#!/bin/bash

################################################################################
# XecuBash - Tests del Módulo de Auditoría
################################################################################

test_audit() {
    suite_title "PRUEBAS DE AUDITORÍA"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/modules/audit.sh" "Módulo de auditoría existe"
    
    # Test: Función de auditoría de SUID/SGID
    test "Función audit_suid_sgid existe" "declare -f audit_suid_sgid"
    
    # Test: Función de auditoría de archivos críticos
    test "Función audit_critical_files existe" "declare -f audit_critical_files"
    
    # Test: Función de auditoría de servicios
    test "Función audit_services existe" "declare -f audit_services"
    
    # Test: Función de auditoría de puertos
    test "Función audit_open_ports existe" "declare -f audit_open_ports"
    
    # Test: Función de auditoría SSH
    test "Función audit_ssh_config existe" "declare -f audit_ssh_config"
    
    # Test: Función de auditoría sudoers
    test "Función audit_sudoers existe" "declare -f audit_sudoers"
    
    # Test: Verificar que SSH está instalado
    assert_command_exists "sshd" "SSH server instalado"
    
    # Test: Verificar que sudoers existe
    assert_file_exists "/etc/sudoers" "Archivo sudoers existe"
    
    # Test: Verificar que passwd existe
    assert_file_exists "/etc/passwd" "Archivo passwd existe"
    
    echo ""
    echo "✓ Tests de auditoría completados"
}