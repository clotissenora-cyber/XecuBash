#!/bin/bash

################################################################################
# XecuBash - Tests de DNSCrypt
################################################################################

test_dnscrypt() {
    suite_title "PRUEBAS DE DNSCRYPT"
    
    # Verificar que el módulo existe
    assert_file_exists "${PROJECT_ROOT}/modules/dnscrypt-setup.sh" "Módulo DNSCrypt existe"
    
    # Test: Función de verificación de estado
    test "Función check_dnscrypt_status existe" "declare -f check_dnscrypt_status"
    
    # Test: Función de instalación
    test "Función install_dnscrypt existe" "declare -f install_dnscrypt"
    
    # Test: Función de configuración
    test "Función configure_dnscrypt_resolvers existe" "declare -f configure_dnscrypt_resolvers"
    
    # Test: Función de inicio de servicio
    test "Función start_dnscrypt_service existe" "declare -f start_dnscrypt_service"
    
    # Test: Función de menú
    test "Función show_dnscrypt_menu existe" "declare -f show_dnscrypt_menu"
    
    # Test: Archivo de configuración existe
    assert_file_exists "${PROJECT_ROOT}/config/dnscrypt-resolvers.conf" "Archivo de configuración DNSCrypt existe"
    
    # Test: resolv.conf existe
    assert_file_exists "/etc/resolv.conf" "Archivo resolv.conf existe"
    
    # Test: dig disponible
    test "dig disponible" "command -v dig"
    
    echo ""
    echo "✓ Tests de DNSCrypt completados"
}