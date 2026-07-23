# SecurityTool - Herramienta Integral de Ciberseguridad para Debian 13 Trixie

## Descripción

SecurityTool es una herramienta de línea de comandos integral diseñada específicamente para **Debian 13 Trixie** que proporciona auditoría, securización y endurecimiento de sistemas Linux desde múltiples vectores de ataque.

## Características Principales

### 🔒 Seguridad del Sistema Base
- Auditoría de permisos SUID/SGID
- Verificación de integridad de binarios
- Detección básica de rootkits
- Hardening de directorios temporales
- Aseguramiento de memoria compartida
- Auditoría de usuarios del sistema

### 🌐 Seguridad de Red
- Escaneo de puertos abiertos
- Análisis de conexiones establecidas
- Configuración de firewall (UFW/iptables)
- Endurecimiento de parámetros de red del kernel
- Protección contra SYN flood y spoofing
- Gestión de IPv6

### 🔐 DNSCrypt - DNS Cifrado
- Instalación automatizada de dnscrypt-proxy
- Configuración de resolvers seguros (Cloudflare, Quad9, Google)
- Validación DNSSEC
- Bloqueo de dominios maliciosos
- Logging de consultas DNS
- Prevención de DNS leaks

### 🎯 Módulos Adicionales (Planificados)
- Anonimato y Privacidad (Tor, proxies, VPN)
- Gestión de identificadores de red (MAC, IP)
- Hardening de SSH
- Auditoría de servicios
- Gestión de logs
- Backup encriptado

## Estructura del Proyecto

```
SecurityTool/
├── bin/
│   └── security-tool          # Script principal
├── modules/
│   ├── system_hardening.sh    # Seguridad del sistema base
│   ├── network_security.sh    # Seguridad de red
│   ├── dnscrypt_setup.sh      # Configuración DNSCrypt
│   ├── firewall.sh            # (pendiente)
│   ├── ssh_security.sh        # (pendiente)
│   ├── anonymity.sh           # (pendiente)
│   └── ...
├── config/
│   └── (archivos de configuración)
├── logs/
│   └── (logs generados)
├── backups/
│   └── (backups de configuración)
├── tests/
│   └── (tests unitarios)
└── docs/
    └── (documentación)
```

## Requisitos

- **Sistema Operativo**: Debian 13 Trixie
- **Privilegios**: Root/sudo requerido para la mayoría de operaciones
- **Dependencias básicas**:
  - bash, grep, sed, awk, find
  - systemctl, iptables, ss, ip
  - openssl, curl, wget
  - tar, gzip

## Instalación

### 1. Clonar o descargar el proyecto

```bash
cd /workspace/SecurityTool
```

### 2. Asegurar permisos de ejecución

```bash
chmod +x bin/security-tool
chmod +x modules/*.sh
```

### 3. Ejecutar la herramienta

```bash
sudo ./bin/security-tool
```

## Uso

### Modo Interactivo (Menú)

```bash
sudo ./bin/security-tool
```

Esto abrirá el menú principal con todas las opciones disponibles.

### Modo Línea de Comandos

```bash
# Ejecutar auditoría completa
sudo ./bin/security-tool --audit

# Ejecutar módulo específico
sudo ./bin/security-tool --module system_hardening

# Generar reporte
sudo ./bin/security-tool --report

# Crear backup
sudo ./bin/security-tool --backup

# Modo dry-run (sin aplicar cambios)
sudo ./bin/security-tool --dry-run --audit

# Ver ayuda
sudo ./bin/security-tool --help
```

## Opciones de Línea de Comandos

| Opción | Descripción |
|--------|-------------|
| `-n, --dry-run` | Modo de prueba (no aplica cambios) |
| `-v, --verbose` | Mostrar salida detallada |
| `-m, --module` | Ejecutar módulo específico |
| `-a, --audit` | Ejecutar auditoría completa |
| `-r, --report` | Generar reporte de seguridad |
| `-b, --backup` | Crear backup de configuraciones |
| `--restore` | Restaurar desde backup |
| `-h, --help` | Mostrar ayuda |

## Módulos Disponibles

### 1. Seguridad del Sistema Base (`system_hardening.sh`)
- Auditoría de permisos SUID/SGID
- Verificación de integridad de binarios
- Detección de rootkits básica
- Hardening de /tmp y /var/tmp
- Aseguramiento de memoria compartida (/dev/shm)

### 2. Seguridad de Red (`network_security.sh`)
- Escaneo de puertos abiertos
- Análisis de conexiones activas
- Configuración de IP forwarding
- Endurecimiento de parámetros kernel
- Configuración de firewall UFW
- Evaluación de IPv6

### 3. DNSCrypt (`dnscrypt_setup.sh`)
- Instalación automática de dnscrypt-proxy
- Configuración de resolvers seguros
- Validación de DNS cifrado
- Bloqueo de dominios maliciosos
- Pruebas de leak DNS

## Reportes

La herramienta genera reportes en tres formatos:

### Formato Texto
```bash
sudo ./bin/security-tool --report
```

### Formato HTML
```bash
# Desde el menú interactivo, opción C
```

### Formato JSON
```bash
# Para integración con otras herramientas
```

## Backups

Antes de aplicar cualquier cambio, la herramienta crea automáticamente un backup de:
- Configuración SSH (`/etc/ssh/`)
- Reglas de firewall
- Configuración del kernel (`/etc/sysctl.conf`)
- Configuración sudoers
- Perfiles AppArmor

Los backups se almacenan en `/workspace/SecurityTool/backups/`

## Logs

Todas las acciones se registran en:
- `/var/log/security-tool.log` (acciones de la herramienta)
- `/workspace/SecurityTool/logs/` (reportes generados)

## Consideraciones de Seguridad

⚠️ **Advertencias importantes**:

1. **Siempre ejecute en modo dry-run primero** para revisar los cambios propuestos
2. **Cree backups antes de aplicar hardening** en producción
3. **Revise los cambios** antes de aplicarlos en sistemas críticos
4. **Algunos cambios requieren reinicio** para tomar efecto completo
5. **El hardening agresivo puede romper funcionalidades** - pruebe en entorno de desarrollo primero

## Solución de Problemas

### La herramienta no se ejecuta
```bash
# Verificar permisos
ls -la bin/security-tool

# Verificar dependencias
./bin/security-tool --help
```

### Error de permisos
```bash
# Siempre ejecutar con sudo
sudo ./bin/security-tool
```

### Módulo no encontrado
```bash
# Verificar que el módulo existe
ls -la modules/
```

## Contribución

Este proyecto está diseñado para ser extendido. Para añadir nuevos módulos:

1. Cree un nuevo archivo en `modules/nombre_modulo.sh`
2. Implemente las funciones `audit_*`, `harden_*`, y `run_module_menu`
3. Registre el módulo en el menú principal

## Licencia

Herramienta desarrollada con fines educativos y de seguridad informática.

## Soporte

Para reportar problemas o sugerencias, revise la documentación en `docs/`.

---

**Versión**: 1.0.0  
**Compatible con**: Debian 13 Trixie  
**Última actualización**: 2024
