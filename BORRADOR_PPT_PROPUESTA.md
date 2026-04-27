# Borrador PPT — Federación de Identidades: Oracle Database → Active Directory

> Guía slide-por-slide para armar la presentación al cliente.
> Cada sección = 1 slide (o grupo de slides si se indica).

---

## SLIDE 1 — Portada

**Título:** Federación de Identidades — Migración de Usuarios Locales Oracle a Active Directory

**Subtítulo:** Propuesta técnica de centralización de autenticación con Kerberos

**Datos:**
- Nombre del proyecto / cliente
- Fecha
- Equipo responsable
- Clasificación: Confidencial

---

## SLIDE 2 — Agenda

1. Contexto y problemática actual
2. Objetivo de la migración
3. Alcance (versiones, bases de datos, usuarios)
4. Arquitectura propuesta
5. Estrategia por versión (12c vs 19c)
6. Fases del proyecto
7. Periodo de coexistencia y rollback
8. Prerequisitos del cliente
9. Riesgos y mitigaciones
10. Cronograma estimado
11. Próximos pasos

---

## SLIDE 3 — Contexto y problemática actual

**Título:** ¿Por qué migrar?

**Puntos clave (bullets):**
- Los usuarios de las bases de datos Oracle se gestionan localmente (password en cada BD)
- Cada BD mantiene sus propias credenciales → gestión descentralizada
- No hay visibilidad centralizada de quién accede a qué
- Los cambios de password requieren intervención en cada BD
- Las cuentas de usuarios que dejan la organización pueden quedar activas
- No hay Single Sign-On (SSO) para los usuarios de BD

**Visual sugerido:** Diagrama mostrando N bases de datos, cada una con su propia lista de usuarios, sin conexión entre ellas. Flechas rojas indicando los problemas.

---

## SLIDE 4 — Objetivo

**Título:** Objetivo de la migración

**Texto principal:**
> Centralizar la autenticación de usuarios de bases de datos Oracle Enterprise Edition en Active Directory, utilizando Kerberos como protocolo de autenticación, manteniendo intactos los privilegios, roles y permisos existentes.

**Beneficios (bullets con íconos):**
- ✅ Gestión centralizada de identidades en AD
- ✅ Single Sign-On vía Kerberos (sin passwords en la BD)
- ✅ Políticas de password y bloqueo de cuenta centralizadas
- ✅ Desvinculación inmediata al deshabilitar cuenta en AD
- ✅ Auditoría unificada de accesos
- ✅ Cumplimiento normativo (segregación de funciones, trazabilidad)

---

## SLIDE 5 — Alcance

**Título:** Alcance del proyecto

**Tabla:**

| Elemento | Detalle |
|---|---|
| Versiones Oracle | Enterprise Edition 12.1, 12.2 y 19c |
| Sistema operativo | RHEL 8.10 |
| Active Directory | Windows Server 2016 (on-premise) |
| Protocolo de autenticación | Kerberos v5 (AES256) |
| Método 19c | Kerberos + CMU (Centrally Managed Users) |
| Método 12c | Kerberos puro (IDENTIFIED EXTERNALLY) |
| Usuarios en alcance | Usuarios locales no-sistema, no-aplicación |
| Fuera de alcance | Cuentas de servicio, schemas de aplicación, usuarios SYS/SYSTEM |

**Nota al pie:** Los usuarios fuera de alcance (cuentas de servicio) serán igualmente descubiertos y reportados, pero no se migrarán.

---

## SLIDE 6 — Arquitectura actual vs propuesta (2 slides)

### SLIDE 6a — Estado actual

**Visual:** Diagrama con:
- Múltiples servidores RHEL con BDs Oracle
- Cada BD con su propia tabla de usuarios/passwords
- Usuarios conectándose con user/password directo a cada BD
- Sin conexión al AD

### SLIDE 6b — Estado propuesto

**Visual:** Diagrama con:
- Active Directory (Domain Controller) en el centro
- Kerberos KDC (el mismo DC) emitiendo tickets
- Servidores Oracle con keytab + sqlnet.ora configurado
- Usuarios obtienen ticket Kerberos (kinit) y se conectan sin password
- Para 19c: línea adicional Oracle → AD (LDAPS) para CMU
- Para 12c: sin línea a AD (solo valida ticket)

**Componentes a mostrar:**
- DC / KDC (Windows Server 2016)
- SPN registrado por servidor Oracle
- Keytab en cada servidor (/etc/oracle/keytab/v5srvtab)
- krb5.conf en cada servidor
- sqlnet.ora con parámetros Kerberos
- Solo 19c: dsi.ora + wallet CMU + LDAPS

---

## SLIDE 7 — Estrategia por versión

**Título:** Dos estrategias según la versión de Oracle

**Tabla comparativa:**

| Aspecto | Oracle 12.1 / 12.2 | Oracle 19c |
|---|---|---|
| Feature | Kerberos puro (ASO) | Kerberos + CMU |
| Comando SQL | `ALTER USER x IDENTIFIED EXTERNALLY AS 'user@REALM'` | `ALTER USER x IDENTIFIED GLOBALLY AS '<DN>'` |
| Oracle consulta AD | No | Sí (LDAPS) |
| Requiere wallet CMU | No | Sí |
| Requiere dsi.ora | No | Sí |
| Parámetros LDAP en BD | No | LDAP_DIRECTORY_ACCESS, LDAP_DIRECTORY_SYSAUTH |
| Auth type resultante | EXTERNAL | GLOBAL |
| Privilegios SYSDBA vía AD | No soportado | Sí (con LDAP_DIRECTORY_SYSAUTH=YES) |

**Nota clave:** En ambos casos, los privilegios, roles, quotas y objetos del schema NO se modifican. Solo cambia el método de autenticación.

---

## SLIDE 8 — Fases del proyecto (slide principal)

**Título:** Fases de ejecución

**Visual:** Diagrama de fases tipo roadmap horizontal con 6 fases:

```
┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
│  Fase 0  │→ │  Fase 1  │→ │  Fase 2  │→ │  Fase 3  │→ │  Fase 4  │→ │  Fase 5  │
│Preparación│  │Descubri- │  │Infraes-  │  │Migración │  │Coexis-   │  │Cierre    │
│    AD     │  │miento    │  │tructura  │  │          │  │tencia    │  │          │
└──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └──────────┘
   Manual       Playbooks    Playbooks     Playbooks     Monitoreo     Desactivar
   en AD        1, 2         3-8           9-11          2-4 semanas   fallback
```

---

## SLIDES 9-14 — Detalle de cada fase (1 slide por fase)

### SLIDE 9 — Fase 0: Preparación en AD (responsabilidad del cliente)

**Checklist:**
- [ ] Crear cuenta de servicio Kerberos en AD (AES256 habilitado, password que no expire)
- [ ] Solo 19c: Crear cuenta de servicio Oracle para bind CMU (Read Properties)
- [ ] Exportar certificado CA raíz del AD (formato PEM)
- [ ] Habilitar cifrado AES256 en las cuentas de usuario a migrar
- [ ] Crear en AD los usuarios que aún no existan (identificados en Fase 1)
- [ ] Verificar resolución DNS bidireccional (DC ↔ servidores Oracle)
- [ ] Habilitar WinRM en el Domain Controller (para automatización)

**Responsable:** Equipo de AD / Infraestructura Windows del cliente

---

### SLIDE 10 — Fase 1: Descubrimiento y clasificación

**Playbooks:** 1 (descubrimiento) y 2 (cruce con AD)

**Entregables:**
- Inventario completo de usuarios por BD (nombre, estado, profile, tablespace)
- Privilegios de sistema, roles y privilegios sobre objetos por usuario
- Clasificación: listos para migrar / pendientes crear en AD / no migrar / solo en AD
- Reporte de usuarios que NO se migran (cuentas de servicio) con sus privilegios

**Visual sugerido:** Ejemplo del reporte de cruce (tabla con las 4 categorías)

---

### SLIDE 11 — Fase 2: Infraestructura Kerberos

**Playbooks:** 3 (SPN), 4 (keytab), 5 (check sqlnet), 6 (sqlnet.ora), 7 (krb5.conf), 8 (OS_AUTHENT_PREFIX / parámetros CMU)

**Acciones:**
- Registrar SPN (`oracle/<fqdn>@REALM`) en AD por cada servidor
- Generar keytab (AES256) y distribuir a cada servidor Oracle
- Configurar sqlnet.ora con parámetros Kerberos + FALLBACK_AUTHENTICATION=TRUE
- Configurar /etc/krb5.conf con realm, KDC y cifrado AES
- Solo 19c: Instalar CA del AD, crear wallet CMU, configurar dsi.ora, parámetros LDAP
- Configurar OS_AUTHENT_PREFIX='' (estático, requiere restart)

**⚠️ Ventana de mantenimiento requerida:** Restart de instancias Oracle (OS_AUTHENT_PREFIX y LDAP_DIRECTORY_SYSAUTH son estáticos)

---

### SLIDE 12 — Fase 3: Migración

**Playbooks:** 9 (backup hashes), 10 (migración), 11 (validación)

**Proceso:**
1. Respaldar password hashes de SYS.USER$ (punto de restauración)
2. Ejecutar migración por lotes:
   - 12c: `ALTER USER <user> IDENTIFIED EXTERNALLY AS '<user@REALM>'`
   - 19c: `ALTER USER <user> IDENTIFIED GLOBALLY AS '<DN_en_AD>'`
3. Validar post-migración:
   - Tipo de autenticación correcto (EXTERNAL / GLOBAL)
   - Privilegios de sistema intactos
   - Roles intactos
   - Privilegios sobre objetos intactos

**Nota:** Los privilegios NO se modifican. Solo cambia el método de autenticación.

---

### SLIDE 13 — Fase 4: Periodo de coexistencia

**Duración recomendada:** 2 a 4 semanas

**Cómo funciona:**
- `SQLNET.FALLBACK_AUTHENTICATION=TRUE` permite que si Kerberos falla, se intente autenticación por password
- Los usuarios migrados se autentican vía Kerberos (kinit + sqlplus /@service)
- Si hay problemas, el rollback es inmediato (restaurar hash del password)

**Monitoreo durante coexistencia:**
- Alert logs de Oracle
- Logs de autenticación Kerberos
- Validar que aplicaciones funcionan correctamente
- Verificar que no hay degradación de performance

**Criterios de éxito para cerrar coexistencia:**
- 100% de usuarios migrados conectándose vía Kerberos sin incidentes
- 0 privilegios perdidos (validado por playbook 11)
- Aplicaciones funcionando sin errores de autenticación

---

### SLIDE 14 — Fase 5: Cierre

**Acciones:**
- Desactivar FALLBACK_AUTHENTICATION (forzar solo Kerberos)
- Documentar usuarios migrados y no migrados
- Entregar reportes finales al cliente
- Transferencia de conocimiento

---

## SLIDE 15 — Estrategia de rollback

**Título:** Plan de rollback — Reversión garantizada

**Visual:** Diagrama de capas de rollback:

```
┌─────────────────────────────────────────────┐
│  Capa 1: Usuarios                           │
│  ALTER USER IDENTIFIED BY VALUES '<hash>'   │
│  (inmediato, sin restart)                   │
├─────────────────────────────────────────────┤  ← Solo 19c
│  Capa 2: Parámetros CMU                     │
│  LDAP_DIRECTORY_ACCESS=NONE                 │
│  (requiere restart para SYSAUTH)            │
├─────────────────────────────────────────────┤
│  Capa 3: Config RHEL                        │
│  Restaurar sqlnet.ora y krb5.conf           │
│  Revertir OS_AUTHENT_PREFIX                 │
│  (requiere restart)                         │
└─────────────────────────────────────────────┘
```

**Opciones de rollback:**
- Completo (todas las capas)
- Solo usuarios (mantiene infraestructura Kerberos para re-intentar)
- Un usuario específico

**Punto clave:** Los password hashes se respaldan ANTES de migrar. El rollback restaura el hash original, no asigna un password nuevo.

---

## SLIDE 16 — Prerequisitos del cliente

**Título:** ¿Qué necesitamos del cliente?

| # | Prerequisito | Responsable | Cuándo |
|---|---|---|---|
| 1 | Cuenta de servicio Kerberos en AD (AES256) | Equipo AD | Antes de Fase 2 |
| 2 | Solo 19c: Cuenta de bind Oracle en AD (Read Properties) | Equipo AD | Antes de Fase 2 |
| 3 | Certificado CA raíz del AD (PEM) | Equipo AD | Antes de Fase 2 |
| 4 | AES256 habilitado en cuentas de usuario | Equipo AD | Antes de Fase 3 |
| 5 | Usuarios creados en la OU del AD | Equipo AD | Antes de Fase 3 |
| 6 | DNS bidireccional (DC ↔ Oracle servers) | Equipo Redes | Antes de Fase 2 |
| 7 | WinRM habilitado en DC | Equipo AD | Antes de Fase 2 |
| 8 | Acceso SSH a servidores Oracle (usuario oracle) | Equipo DBA | Antes de Fase 1 |
| 9 | Credenciales Oracle con permisos DBA | Equipo DBA | Antes de Fase 1 |
| 10 | Ventana de mantenimiento para restart | Equipo DBA | Fase 2 y Fase 3 |
| 11 | Lista de usuarios/schemas que NO deben migrarse | Equipo DBA / Aplicaciones | Antes de Fase 1 |

---

## SLIDE 17 — Riesgos y mitigaciones

**Título:** Análisis de riesgos

| Riesgo | Impacto | Probabilidad | Mitigación |
|---|---|---|---|
| Usuarios no pueden conectarse post-migración | Alto | Baja | FALLBACK_AUTHENTICATION=TRUE + rollback inmediato |
| Pérdida de privilegios durante migración | Alto | Muy baja | ALTER USER solo cambia auth, no privilegios. Validación automática post-migración |
| DNS no resuelve correctamente | Alto | Media | Validar DNS antes de iniciar. Playbook 3 detecta FQDN |
| Keytab con cifrado incorrecto | Medio | Baja | Se genera con AES256-SHA1 exclusivamente |
| Aplicaciones con connection strings hardcodeadas | Medio | Media | Identificar en Fase 1. FALLBACK permite coexistencia |
| Restart de instancia causa downtime | Alto | Cierta | Coordinar ventana de mantenimiento. Solo 1 restart necesario |
| Cuenta de servicio Kerberos no creada a tiempo | Medio | Media | Solicitar en Fase 0 con anticipación |

---

## SLIDE 18 — Cronograma estimado

**Título:** Cronograma de alto nivel

**Visual:** Diagrama de Gantt simplificado:

```
Semana        1    2    3    4    5    6    7    8    9   10
              ├────┼────┼────┼────┼────┼────┼────┼────┼────┤
Fase 0 (AD)   ████
Fase 1 (Desc)      ██
Fase 2 (Infra)       ████
  Restart               ▲
Fase 3 (Migr)              ██
Fase 4 (Coex)                ████████████
Fase 5 (Cierre)                              ██
```

**Notas:**
- Fase 0 puede ejecutarse en paralelo con la preparación del entorno
- El cronograma asume disponibilidad de prerequisitos del cliente
- La Fase 4 (coexistencia) es la más larga: 2-4 semanas de monitoreo
- Si hay múltiples entornos (dev/qa/prod), se ejecuta primero en dev como piloto

---

## SLIDE 19 — Automatización

**Título:** Ejecución 100% automatizada con Ansible

**Puntos:**
- Toda la ejecución se realiza mediante playbooks de Ansible
- Cada paso genera reportes en JSON y texto plano
- Los playbooks son idempotentes (se pueden re-ejecutar sin riesgo)
- Dos proyectos separados por versión:
  - `playbook-federacion-identidades-dba` → Oracle 19c (Kerberos + CMU)
  - `playbook-federacion-identidades-dba-12` → Oracle 12.1/12.2 (Kerberos puro)
- Credenciales cifradas con Ansible Vault
- Sin intervención manual excepto: restart de instancia y prerequisitos AD

**Visual sugerido:** Tabla con los 12-14 playbooks y su función (resumen de 1 línea cada uno)

---

## SLIDE 20 — Entregables

**Título:** Entregables del proyecto

| Entregable | Descripción |
|---|---|
| Reporte de descubrimiento | Usuarios, privilegios, roles por BD (JSON + texto) |
| Reporte de cruce Oracle vs AD | Clasificación de usuarios en 4 categorías |
| Reporte de SPN | SPNs registrados por servidor |
| Backup de password hashes | Hashes + script SQL de restauración (protegido) |
| Reporte de migración | Detalle de usuarios migrados con método y DN/UPN |
| Reporte de validación | PASS/FAIL + comparación de privilegios vs baseline |
| Playbooks Ansible | Código fuente de toda la automatización |
| Documentación de operación | Guía para el equipo DBA del cliente |

---

## SLIDE 21 — Próximos pasos

**Título:** Próximos pasos

1. Aprobación de la propuesta por parte del cliente
2. Definir ventanas de mantenimiento para restart
3. Solicitar prerequisitos al equipo de AD (Fase 0)
4. Entregar lista de usuarios/schemas que no deben migrarse
5. Agendar kickoff del proyecto
6. Ejecutar piloto en entorno de desarrollo

---

## SLIDE 22 — Cierre / Q&A

**Título:** ¿Preguntas?

**Datos de contacto del equipo**

---

## Notas para el presentador

### Estructura recomendada de la PPT
- Usar un diseño limpio con poco texto por slide
- Los diagramas de arquitectura son los slides más importantes — invertir tiempo en hacerlos claros
- La tabla comparativa 12c vs 19c (slide 7) es clave para que el cliente entienda por qué hay dos estrategias
- El slide de rollback (15) genera confianza — enfatizar que la reversión es inmediata
- El slide de prerequisitos (16) es el más importante para el cliente — es lo que ellos deben hacer

### Tips de presentación
- Empezar con el problema (slide 3), no con la solución
- Usar el reporte de descubrimiento real como ejemplo si ya se ejecutó el playbook 1
- Mostrar un demo del playbook 1 si es posible (es solo lectura, no modifica nada)
- Enfatizar que los privilegios NO se tocan — esto es la preocupación #1 de los DBA
- El periodo de coexistencia es el argumento más fuerte: "no es un cambio de un día para otro"

### Referencias oficiales para respaldar la propuesta
- Oracle 19c CMU: https://docs.oracle.com/en/database/oracle/oracle-database/19/dbseg/integrating_mads_with_oracle_database.html
- Oracle 12.1 Kerberos: https://docs.oracle.com/database/121/DBSEG/asokerb.htm
- Oracle 19c Blog oficial: https://blogs.oracle.com/database/post/make-someone-else-do-the-work-managing-oracle-database-19c-users-in-active-directory-part-1-kerberos
- Microsoft migration phases: https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/migration-resources
