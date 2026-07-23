# Prompt: Herramienta Integral de Ciberseguridad para Debian 13 Trixie

---

## Descripción General

**Desarrolla una herramienta de línea de comandos integral de ciberseguridad diseñada específicamente para Debian 13 Trixie**. Esta herramienta debe funcionar como un asistente automatizado que audit, securiza y endurezca un sistema Linux desde múltiples vectores de ataque. La herramienta debe ser modular, permitiendo que los usuarios ejecuten componentes individuales o secuencias completas de securización.

---

## Componentes Principales Requeridos

### Seguridad del Sistema Base
- **Auditoría de permisos de archivos y directorios críticos** (SUID, SGID, sticky bits).
- **Análisis de binarios del sistema**: verificar integridad de ejecutables en directorios sensibles (`/bin`, `/sbin`, `/usr/bin`, `/usr/sbin`).
- **Validación de scripts de inicio y servicios systemd**: detectar servicios no autorizados o vulnerables.
- **Hardening de bash y shell**: deshabilitar comandos peligrosos, restringir permisos de lectura en scripts, securizar variables de entorno.
- **Análisis de permisos de sudo y configuración de sudoers**.
- **Detección de rootkits y malware** mediante análisis heurístico y firmas.
- **Chroot y contenedor de seguridad**: opciones para aislar procesos críticos.

### Securización de Configuraciones del Entorno
- **Hardening de parámetros del kernel** (sysctl): deshabilitar forwarding de IP innecesario, activar protecciones contra SYN flood, configurar limits de archivos abiertos.
- **Configuración de AppArmor y SELinux** (si está disponible): crear y validar perfiles restrictivos.
- **Auditoría de ficheros de configuración**: verificar permisos en `/etc`, detectar archivos con propietario inesperado.
- **Gestión de secretos**: detectar credenciales expuestas en archivos de configuración.
- **Asegurar variables PATH**: validar que no contengan directorios escribibles por otros usuarios.
- **Timeout de sesión**: configurar bloqueo automático e inactividad.
- **Auditoría de logs del sistema** (rsyslog, journalctl): habilitar logging detallado, comprimir y archivar logs antiguos.

### Securización de Red
- **Auditoría de puertos abiertos**: listar servicios escuchando, detectar puertos sospechosos.
- **Configuración de firewall (ufw/iptables)**: crear reglas restrictivas por defecto, bloquear trafico no autorizado.
- **Securización de SSH**: cambiar puerto, deshabilitar root login, configurar autenticación por clave pública, deshabilitar contraseñas débiles.
- **Detección de conexiones establecidas**: listar conexiones activas, identificar procesos sospechosos.
- **Control de acceso de red**: crear listas blancas/negras de IPs.
- **Validación de certificados SSL/TLS**: verificar fechas de expiración y validez.

### Anonimato y Privacidad
- **Integración con Tor**: instalación simplificada, configuración de rutas tor, validación de anonimato.
- **Proxy SOCKS5**: configuración y validación de proxys.
- **VPN**: integración con herramientas populares, validación de leaks de DNS/IPv6.
- **Validación de leak de IP**: verificar que no se exponga la IP real mediante pruebas de DNS/WebRTC.
- **Limpieza de metadata**: remover metadata de archivos (exiftool integration).
- **Gestión de cookies y caché del navegador**.

### DNSCrypt - Implementación Completa
- **Instalación automatizada de dnscrypt-proxy**.
- **Configuración de resolvers de DNS seguros y auditados** (Cloudflare, Quad9, OpenNIC, etc.).
- **Validación de resolución DNS cifrada**: verificar que las consultas se cumplen sin intercepción.
- **Estandarización en el sistema**: configurar como servidor DNS por defecto.
- **Redundancia de resolvers**: fallback automático si un resolver falla.
- **Logging de consultas DNS**: auditoría y análisis de patrones de consulta.
- **Bloqueo de dominios maliciosos**: integración con listas negras de phishing/malware.
- **DNSSEC validation**: habilitar validación de firmas DNSSEC.

### Identificadores de Red (MAC, IP, IPv6, etc.)
- **Auditoría de direcciones MAC**: listar interfaces y MACs actuales.
- **Spoofing de MAC**: randomización de MAC, spoofing selectivo, restore de MAC original.
- **Gestión de direcciones IPv4**: cambio dinámico, asignación estática, validación de unicast/multicast.
- **Hardening de IPv6**: deshabilitar si no es necesario, configurar privacy extensions, detectar DHCPv6 sospechoso.
- **Detección de DHCP spoofing**: alertar sobre cambios sospechosos en servidor DHCP.
- **Gestión de identificadores únicos**: hostname, machine-id, UUID de volúmenes.

### Proxys y Enrutamiento
- **Configuración de HTTP/HTTPS proxys**: autenticación, validación de certificados.
- **Cadenas de proxys**: múltiples capas de anonimato.
- **Proxy SOCKS**: configuración automática para navegadores y aplicaciones.
- **Validación de proxy**: pruebas de leak, latencia, disponibilidad.
- **Fallback automático**: si un proxy no responde, cambiar a alternativo.

### Elementos Adicionales de Ciberseguridad
- **Gestión de claves SSH**: generación, validación, cifrado de claves privadas.
- **Auditoría de archivos .bashrc, .profile y otros dotfiles** de inicialización.
- **Control de permisos de entrada/salida (IPC)**: validar acceso a sockets y pipes.
- **Detección de procesos zombies y procesos orfandos**.
- **Validación de integridad de archivos** (AIDE, tripwire).
- **Análisis de comportamiento de procesos**: detectar procesos con comportamiento anómalo.
- **Backup encriptado y validado**: plan de recuperación ante desastres.
- **Generador de reportes de seguridad**: reporte completo en HTML, JSON o texto.
- **Scheduler de auditorías automáticas**: ejecutar verificaciones periódicamente.

---

## Características Técnicas Requeridas

| Característica | Descripción |
|---|---|
| **Interfaz** | Menú interactivo en terminal (ncurses o similar), también modo no-interactivo para scripts. |
| **Modo de Operación** | Dry-run (mostrar cambios sin aplicar), apply (aplicar cambios), revert (revertir cambios). |
| **Permisos** | Requerir root/sudo para operaciones sensibles. |
| **Compatibilidad** | Debian 13 Trixie específicamente; validar dependencias. |
| **Logging** | Registrar todas las acciones en `/var/log/security-tool.log` con timestamp. |
| **Recuperación** | Crear snapshots de configuración antes de cambios; permitir rollback. |
| **Validación** | Verificar que cada acción se completó correctamente; alertar sobre fallos. |
| **Documentación** | Help integrado (`--help`), man pages, ejemplos de uso. |

---

## Estructura Esperada

```
SecurityTool/
├── bin/
│   └── security-tool (punto de entrada principal)
├── modules/
│   ├── system_hardening.sh
│   ├── network_security.sh
│   ├── dnscrypt_setup.sh
│   ├── anonymity.sh
│   ├── firewall.sh
│   ├── audit.sh
│   └── ...
├── config/
│   ├── dnscrypt_resolvers.conf
│   ├── firewall_rules.conf
│   ├── hardening_defaults.conf
│   └── ...
├── logs/
├── backups/
├── tests/
└── docs/
```

---

## Salida y Reportes

La herramienta debe generar reportes que incluyan:
- **Estado actual de seguridad**: puntuación de 0-100.
- **Vulnerabilidades detectadas**: listado con severidad (crítica, alta, media, baja).
- **Acciones recomendadas**: paso a paso para remediar problemas.
- **Cambios aplicados**: historial completo con timestamps.
- **Próximas acciones**: cronograma de auditorías sugeridas.

---

Este prompt puede servir como base para desarrollar la herramienta o para solicitar su implementación a un equipo de desarrollo o a un modelo de IA generativo.
