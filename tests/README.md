# XecuBash - Documentación de Tests Unitarios

## 📋 Visión General

Esta carpeta contiene la suite completa de pruebas unitarias para XecuBash. Los tests están organizados por módulos y proporcionan cobertura exhaustiva de todas las características principales.

## 🏗️ Estructura

```
tests/
├── test-suite.sh          # Suite principal de pruebas
├── test-utils.sh          # Utilidades y helpers
├── test-audit.sh          # Tests del módulo de auditoría
├── test-hardening.sh      # Tests del módulo de hardening
├── test-network.sh        # Tests de seguridad de red
├── test-dnscrypt.sh       # Tests de DNSCrypt
├── test-firewall.sh       # Tests de firewall
├── test-anonymity.sh      # Tests de anonimato
├── test-validators.sh     # Tests de validadores
├── results/               # Resultados de pruebas
└── README.md              # Este archivo
```

## 🚀 Ejecución de Tests

### Ejecutar suite completa

```bash
sudo ./tests/test-suite.sh
```

### Ejecutar tests específicos

```bash
cd tests && source test-utils.sh && source test-audit.sh && test_audit
```

## 📊 Funciones de Prueba

### Assertions Básicas

```bash
# Test simple
test "descripción" "comando"

# Verificar igualdad
assert_equal "$valor" "esperado" "descripción"

# Verificar que comando existe
assert_command_exists "cmd" "descripción"

# Verificar que archivo existe
assert_file_exists "/path/file" "descripción"
```

## 📈 Resultados

Los resultados se generan automáticamente en:
- `results/test-run-TIMESTAMP.log` - Log completo
- Reporte HTML automático

## 📄 Licencia

Apache License 2.0 - Ver LICENSE en el directorio raíz.
