# XecuBash 🔐

**Herramienta integral de ciberseguridad para Debian 13 Trixie**

XecuBash es una herramienta de línea de comandos que automatiza la auditoría, securización y endurecimiento de sistemas Linux (Debian 13 Trixie). Proporciona análisis detallados de vulnerabilidades y aplica hardening en múltiples vectores de ataque.

## 🎯 Características Principales

- ✅ **Auditoría del Sistema**: Permisos, binarios, servicios y rootkits
- ✅ **Hardening de Kernel**: Configuración de sysctl y AppArmor
- ✅ **Seguridad de Red**: Firewall, SSH, puertos abiertos, validación SSL/TLS
- ✅ **Privacidad & Anonimato**: Tor, VPN, proxy SOCKS5, limpieza de metadata
- ✅ **DNSCrypt Integrado**: Resolución DNS cifrada y segura
- ✅ **Gestión de Identificadores**: MAC spoofing, IPv6 hardening, hostname management
- ✅ **Reportes Detallados**: HTML, JSON y formato texto
- ✅ **Recuperación**: Snapshots y rollback automático

## 📋 Requisitos

- **Sistema Operativo**: Debian 13 Trixie
- **Permisos**: Root o sudo
- **Dependencias**: bash 4.0+, systemd, curl, wget

## 🚀 Instalación

```bash
git clone https://github.com/clotissenora-cyber/XecuBash.git
cd XecuBash
chmod +x bin/security-tool
sudo ./bin/security-tool --help
```

## 📖 Uso Rápido

```bash
# Menú interactivo
sudo ./bin/security-tool

# Auditoría completa (dry-run)
sudo ./bin/security-tool audit --dry-run

# Aplicar hardening del sistema
sudo ./bin/security-tool harden --apply

# Generar reporte
sudo ./bin/security-tool report --format html --output report.html

# Configurar DNSCrypt
sudo ./bin/security-tool dnscrypt --setup
```

## 📁 Estructura del Proyecto

```
XecuBash/
├── bin/
│   └── security-tool              # Punto de entrada principal
├── modules/
│   ├── system-hardening.sh        # Seguridad del sistema base
│   ├── network-security.sh        # Seguridad de red
│   ├── dnscrypt-setup.sh          # Configuración DNSCrypt
│   ├── anonymity.sh               # Tor, VPN, proxys
│   ├── firewall-rules.sh          # Configuración de firewall
│   ├── audit.sh                   # Auditoría de seguridad
│   ├── identifiers.sh             # Gestión de MAC, IP, IPv6
│   └── reporting.sh               # Generación de reportes
├── config/
│   ├── dnscrypt-resolvers.conf    # Resolvers DNS seguros
│   ├── firewall-rules.conf        # Reglas de firewall
│   ├── hardening-defaults.conf    # Valores por defecto
│   └── app-armor-profiles.conf    # Perfiles AppArmor
├── utils/
│   ├── logger.sh                  # Sistema de logging
│   ├── validator.sh               # Validación de cambios
│   └── snapshots.sh               # Gestión de snapshots
├── logs/
├── backups/
├── tests/
└── docs/
    ├── USAGE.md
    ├── MODULES.md
    └── TROUBLESHOOTING.md
```

## 📚 Módulos Disponibles

| Módulo | Descripción |
|--------|-----------|
| **system-hardening** | Auditoría de permisos, binarios, servicios, kernel |
| **network-security** | Puertos, SSH, SSL/TLS, validación de conexiones |
| **dnscrypt-setup** | Resolución DNS cifrada y auditada |
| **anonymity** | Tor, VPN, proxys, validación de leak |
| **firewall-rules** | Configuración ufw/iptables |
| **audit** | Auditoría completa del sistema |
| **identifiers** | MAC spoofing, IPv6, hostname management |
| **reporting** | Generación de reportes (HTML, JSON, TXT) |

## 🔧 Operaciones Principales

### Modos de Operación
- **--dry-run**: Mostrar cambios sin aplicar
- **--apply**: Aplicar cambios de seguridad
- **--revert**: Revertir últimos cambios

### Opciones Comunes
```bash
--help              # Mostrar ayuda
--version           # Versión del tool
--log-level DEBUG   # Nivel de logging
--config FILE       # Usar archivo de configuración personalizado
--no-backup         # Omitir backup automático
```

## 📊 Ejemplo de Reporte

La herramienta genera reportes como:
- **Puntuación de Seguridad**: 0-100
- **Vulnerabilidades Detectadas**: Crítica, Alta, Media, Baja
- **Acciones Recomendadas**: Paso a paso
- **Historial de Cambios**: Con timestamps
- **Próximas Auditorías**: Cronograma sugerido

## 🛠️ Desarrollo

Contribuciones son bienvenidas. Para contribuir:

1. Fork el repositorio
2. Crea una rama feature (`git checkout -b feature/nueva-feature`)
3. Commit tus cambios (`git commit -am 'Agregar nueva feature'`)
4. Push a la rama (`git push origin feature/nueva-feature`)
5. Abre un Pull Request

## 📝 Licencia

Este proyecto está bajo la licencia [Apache License 2.0](LICENSE).

## ⚠️ Disclaimer

Esta herramienta está diseñada para hardening legítimo de sistemas. El uso indebido es responsabilidad del usuario. Siempre realiza backup antes de cambios críticos.

## 📞 Soporte

Para reportar bugs o sugerir features, abre un [Issue](https://github.com/clotissenora-cyber/XecuBash/issues).

---

**Última actualización**: 2026-07-23
