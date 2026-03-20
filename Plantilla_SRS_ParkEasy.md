# Software Requirements Specification (SRS)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** 18 de marzo de 2026  
**Cliente:** ParkEasy S.A.S.
**Grupo:** Grupo 4  
**Integrantes:**
- Harold Alejandro Vargas Martínez - 	
00020526190
- Juan Martin Trejos - 00020513089
- Wilson David Sanchez Prieto - 00020438180
- Juan Sebastian Forero Moreno - [Código]

---

## 1. INTRODUCCIÓN

### 1.1 Propósito
Este documento especifica los requisitos funcionales y no funcionales del Sistema de Gestión de Parqueaderos "ParkEasy" para la empresa homónima con operación en Bogotá, Colombia.

### 1.2 Alcance
ParkEasy permitirá digitalizar la operación de 3 parqueaderos en Bogotá (Zona T, Unicentro y Andino) con 450 espacios en total. El sistema gestionará disponibilidad en tiempo real, reservas anticipadas, ingreso automático por reconocimiento de placa (LPR), pagos digitales, facturación electrónica y reportes administrativos.

### 1.3 Definiciones, Acrónimos y Abreviaciones

| Término | Definición |
|---------|------------|
| LPR | License Plate Recognition — Reconocimiento automático de placas vehiculares |
| MVP | Minimum Viable Product — Primera versión funcional del sistema |
| DIAN | Dirección de Impuestos y Aduanas Nacionales de Colombia |
| PCI-DSS | Payment Card Industry Data Security Standard |
| VB6 | Visual Basic 6 — Lenguaje del sistema de cobro legacy |
| P95 | Percentil 95 — El 95% de las transacciones deben cumplir el tiempo indicado |
| COP | Peso Colombiano |
| Nequi / Daviplata | Billeteras digitales colombianas para pagos móviles |
| Rush hour | Hora pico operacional: 7am–10am y 5pm–8pm |
| ADR | Architectural Decision Record |
| SRS | Software Requirements Specification |
| SAD | Software Architecture Document |


### 1.4 Referencias
- Enunciado del taller
- [Otras referencias si las hay]

---

## 2. DESCRIPCIÓN GENERAL DEL SISTEMA

### 2.1 Perspectiva del Producto
Sistema web que se integrará con:
- Cámaras LPR existentes en las 3 sedes (API REST)
- Sistema de cobro legacy VB6 (API SOAP, poco documentada)
- Pasarela de pagos Wompi (Colombia)
- Servicio de notificaciones Email/SMS (SendGrid + Twilio)
- DIAN para facturación electrónica

### 2.2 Funciones del Producto
1. Gestión de disponibilidad de espacios en tiempo real
2. Reservas anticipadas de espacios (hasta 2 horas antes)
3. Ingreso automático sin contacto mediante reconocimiento de placa (LPR)
4. Procesamiento de pagos digitales al salir (tarjeta, Nequi, Daviplata)
5. Generación y envío de factura electrónica (DIAN)
6. Panel de gestión para operadores de caseta
7. Dashboard y reportes para administradores
8. Configuración de tarifas por sede

### 2.3 Características de Usuarios

 
| Tipo de Usuario | Descripción | Nivel de Expertise |
|-----------------|-------------|--------------------|
| **Conductor** | Persona que busca parquear su vehículo en una sede de ParkEasy | Básico — no técnico, familiar con apps móviles |
| **Operador** | Personal de caseta en entrada/salida de cada parqueadero | Básico — educación media, sin formación técnica |
| **Administrador** | Gerente o encargado de sede que monitorea la operación y consulta reportes | Medio — manejo de herramientas de reporte, sin conocimientos técnicos |

### 2.4 Restricciones del Sistema

**Restricciones técnicas:**
- Debe integrarse con cámaras LPR existentes (API REST)
- Sistema de cobro legacy VB6 no puede reemplazarse en el MVP (integración SOAP)
- API SOAP del legacy está escasamente documentada
 
**Restricciones de negocio:**
- Presupuesto máximo de infraestructura: $2.000 USD/mes
- Equipo: 4 desarrolladores, 8 meses para MVP
- Sin downtime durante horas pico: 7am–10am y 5pm–8pm
 
**Restricciones regulatorias:**
- Ley 1581 de 2012 (protección de datos personales — Colombia)
- Facturación electrónica con retención mínima de 5 años (DIAN)
- Cumplimiento PCI-DSS para procesamiento de pagos con tarjeta
 
---

## 3. REQUISITOS FUNCIONALES

### RF-01: Consulta de Disponibilidad en Tiempo Real
**Prioridad:** Alta  
**Descripción:** Cualquier usuario puede consultar los espacios disponibles y ocupados por sede sin necesidad de autenticación.
 
**Criterios de aceptación:**
- La disponibilidad por sede se muestra con retraso máximo de 10 segundos respecto al estado real
- Accesible desde la app web/móvil sin autenticación
- Cuando la ocupación supera el 90%, se muestra advertencia visual de "casi lleno"
- Si una sede está completamente ocupada, el sistema bloquea nuevas reservas y lo indica claramente
 
---
 
### RF-02: Reserva Anticipada de Espacio
**Prioridad:** Alta  
**Descripción:** Conductores autenticados pueden reservar un espacio con un máximo de 2 horas de anticipación, asociado a su placa y sede elegida.
 
**Criterios de aceptación:**
- Se puede crear reserva indicando sede, placa y hora estimada de llegada
- Solo se permiten reservas con máximo 2 horas de antelación
- Si el conductor no llega en 15 minutos tras la hora reservada, la reserva se cancela automáticamente
- El conductor recibe confirmación por email o SMS en menos de 30 segundos
- El sistema rechaza reservas si no hay espacios disponibles en la sede
 
---
 
### RF-03: Ingreso Automático por Reconocimiento de Placa (LPR)
**Prioridad:** Alta  
**Descripción:** Al llegar a la entrada, el sistema detecta la placa mediante cámaras LPR, registra el ingreso y abre la barrera automáticamente sin intervención del conductor.
 
**Criterios de aceptación:**
- El sistema obtiene la placa reconocida por la cámara LPR en ≤ 3 segundos
- Si hay reserva activa o espacios disponibles, la barrera se abre automáticamente
- El tiempo total de entrada (detección → apertura de barrera) es ≤ 5 segundos P95
- Si la confianza de reconocimiento es < 85%, el sistema notifica al operador para registro manual sin detener el flujo
 
---
 
### RF-04: Procesamiento de Pago Digital al Salir
**Prioridad:** Alta  
**Descripción:** Al momento de salida, el sistema calcula el monto según el tiempo de permanencia y permite el pago con tarjeta, Nequi o Daviplata a través de Wompi.
 
**Criterios de aceptación:**
- El monto se calcula correctamente: $4.000 COP primera hora, $3.000 COP/hora adicional, máximo $25.000 COP/día
- El conductor puede pagar con tarjeta débito/crédito, Nequi o Daviplata
- Wompi confirma o rechaza el pago en ≤ 10 segundos
- Tras pago exitoso la barrera de salida se abre y la transacción se registra en el sistema legacy
- Si la pasarela falla, el operador puede registrar el pago manualmente
 
---
 
### RF-05: Generación de Factura Electrónica
**Prioridad:** Alta  
**Descripción:** Tras confirmar el pago, el sistema genera automáticamente una factura electrónica conforme a los requisitos de la DIAN y la envía al conductor por email.
 
**Criterios de aceptación:**
- La factura se genera en ≤ 5 segundos después de confirmar el pago
- Incluye: número de factura, fecha/hora, sede, placa (enmascarada), tiempo de permanencia, desglose de tarifas y total pagado
- Se envía al email registrado y queda disponible para descarga en la app
- Las facturas se almacenan por mínimo 5 años según normativa DIAN
 
---
 
### RF-06: Registro Manual por Operador
**Prioridad:** Alta  
**Descripción:** Cuando el sistema automático falle, el operador puede registrar manualmente la entrada o salida de un vehículo desde una interfaz simple en tablet.
 
**Criterios de aceptación:**
- El operador registra una entrada o salida ingresando la placa en ≤ 30 segundos
- El registro manual queda marcado con bandera de "entrada manual" para auditoría
- El sistema calcula igualmente el tiempo de permanencia y cobro
- El operador puede registrar incidentes (vehículo mal parqueado) con descripción y foto opcional
 
---
 
### RF-07: Dashboard de Ocupación para Administradores
**Prioridad:** Media  
**Descripción:** Los administradores acceden a un panel centralizado con ocupación actual de todas las sedes e indicadores financieros del día.
 
**Criterios de aceptación:**
- Muestra espacios libres/ocupados por sede, actualizado cada 30 segundos
- Muestra ingresos acumulados del día actual
- Permite filtrar por sede o ver todas simultáneamente
- Tiempo de carga inicial ≤ 3 segundos
- Accesible desde navegador web sin instalación adicional
 
---
 
### RF-08: Reportes de Ingresos y Estadísticas
**Prioridad:** Media  
**Descripción:** El sistema genera reportes exportables con ingresos y estadísticas operacionales para períodos diarios y mensuales.
 
**Criterios de aceptación:**
- Se puede generar reporte para cualquier día o mes del historial disponible
- Incluye: ingresos totales, número de vehículos, tiempo promedio de permanencia y tasa de ocupación por hora
- Exportable en formato CSV y PDF
- Generación de reporte mensual en ≤ 10 segundos
 
---
 
### RF-09: Configuración de Tarifas por Sede
**Prioridad:** Media  
**Descripción:** El administrador puede modificar tarifas (primera hora, horas adicionales, máximo diario) para cada sede desde el panel de administración.
 
**Criterios de aceptación:**
- Se pueden modificar tarifas de forma independiente por sede
- Los cambios aplican inmediatamente para nuevas entradas sin afectar vehículos ya ingresados
- Solo usuarios con rol Administrador pueden modificar tarifas
- El sistema registra historial de cambios con fecha, hora y usuario
 
---
<!-- AGREGAR MÁS RF SI ES NECESARIO -->

---

## 4. REQUISITOS NO FUNCIONALES

### RNF-01: Rendimiento
**ID:** RNF-01  
**Categoría:** Performance  
**Descripción:** El sistema debe procesar entradas y salidas sin generar congestión, especialmente en horas pico con hasta 80 vehículos/hora.
 
**Métricas:**
- Proceso de entrada (detección LPR → apertura de barrera): ≤ 5 segundos P95
- Proceso de salida (cálculo tarifa → confirmación pago → apertura): ≤ 15 segundos P95
- Consulta de disponibilidad: ≤ 500 ms P95
- Carga del dashboard: ≤ 3 segundos con hasta 10 usuarios concurrentes
 
**Justificación:** Con 80 vehículos/hora en rush hour, cualquier demora superior a 5 segundos genera colas; es el problema central que ParkEasy busca resolver.
 
---
 
### RNF-02: Disponibilidad
**ID:** RNF-02  
**Categoría:** Availability  
**Descripción:** El sistema debe operar de forma continua durante el horario de los parqueaderos sin interrupciones que afecten la operación.
 
**Métricas:**
- Disponibilidad ≥ 99.5% durante horario operacional (6am–11pm)
- Máximo 9.5 horas de inactividad al año en horario operativo
- Cero interrupciones planificadas durante horas pico: 7am–10am y 5pm–8pm
- Recovery Time Objective (RTO): ≤ 30 minutos
- Modo degradado (operación manual) disponible por hasta 4 horas ante fallo del sistema central
 
**Justificación:** Una interrupción en horas pico bloquearía físicamente vehículos. El enunciado establece esta restricción de forma explícita.
 
---
 
### RNF-03: Escalabilidad
**ID:** RNF-03  
**Categoría:** Scalability  
**Descripción:** La arquitectura debe soportar el crecimiento proyectado del negocio sin rediseño estructural.
 
**Métricas:**
- Soportar hasta 1.200 espacios activos y 6 sedes sin cambios arquitecturales
- Incorporar nueva sede en ≤ 2 días de configuración, sin cambios de código
- Soportar hasta 160 transacciones de entrada/salida por hora sin degradación
- Costo de infraestructura al escalar a 6 sedes ≤ $4.000 USD/mes
 
**Justificación:** El enunciado establece la expansión de 450 a 1.200 espacios. Es driver de decisión para base de datos, estilo arquitectural y despliegue.
 
---
 
### RNF-04: Seguridad
**ID:** RNF-04  
**Categoría:** Security  
**Descripción:** El sistema debe proteger los datos personales de los conductores, las transacciones financieras y los accesos administrativos.
 
**Métricas:**
- Placas vehiculares encriptadas en reposo con AES-256 y transmitidas sobre TLS 1.2+
- Cumplimiento PCI-DSS v4.0: tokenización de pagos, sin almacenamiento de datos de tarjeta
- Sesiones de operador y administrador expiran tras 30 minutos de inactividad
- Rate limiting: máximo 100 requests/minuto por IP
- Logs de auditoría de transacciones almacenados por mínimo 5 años
 
**Justificación:** Las placas son datos personales bajo Ley 1581. Los pagos con tarjeta exigen PCI-DSS. Incumplimiento conlleva sanciones de la SIC y la DIAN.
 
---
 
### RNF-05: Usabilidad
**ID:** RNF-05  
**Categoría:** Usability  
**Descripción:** Las interfaces de operador y conductor deben ser utilizables sin formación técnica previa.
 
**Métricas:**
- Un operador nuevo completa su primer registro manual correctamente tras 30 minutos de inducción
- Tasa de error en registro manual ≤ 2% de las transacciones diarias
- El flujo de reserva para conductores se completa en ≤ 4 pasos
- La interfaz del operador funciona en tablets de 10 pulgadas y es operable con dedos
 
**Justificación:** El enunciado especifica que los operadores tienen educación básica. Una interfaz compleja generaría errores y ralentizaría la operación.
 
---
 
### RNF-06: Costo
**ID:** RNF-06  
**Categoría:** Cost  
**Descripción:** El costo de infraestructura en nube no debe superar el presupuesto establecido, ni en operación normal ni en picos.
 
**Métricas:**
- Infraestructura mensual ≤ $2.000 USD/mes para 3 sedes (MVP)
- Al escalar a 6 sedes, costo proyectado ≤ $4.000 USD/mes
- Reducción de costo fuera de horario operacional mediante auto-scaling ≥ 30%
- Licencias de software: $0 (herramientas open source)
 
**Justificación:** Presupuesto limitado establecido en el enunciado. Es driver de decisión para seleccionar proveedor cloud y tamaño de instancias.
 
---

## 5. ALCANCE DEL MVP

### 5.1 Restricciones Técnicas
- **Integración LPR:** Las cámaras existentes exponen API REST; no se pueden cambiar ni reemplazar
- **Sistema legacy VB6:** No puede reemplazarse en el MVP; integración vía SOAP con documentación incompleta
- **Cloud provider:** AWS o GCP (a decisión del equipo, justificado en ADR)
 
### 5.2 Restricciones de Negocio
- **Lanzamiento:** MVP en 8 meses máximo
- **Equipo:** 4 desarrolladores full-time
- **Presupuesto:** $2.000 USD/mes en infraestructura
- **Continuidad:** Los parqueaderos no pueden detener operaciones durante la transición
 
### 5.3 Restricciones Regulatorias
- **Ley 1581 (Colombia):** Protección de datos personales; las placas son dato personal
- **DIAN:** Facturación electrónica con retención mínima de 5 años
- **PCI-DSS:** No almacenar datos de tarjetas de crédito/débito en servidores de ParkEasy
 
---

## 6. SUPUESTOS Y DEPENDENCIAS

### 6.1 Supuestos
1. Las cámaras LPR tienen tasa de reconocimiento correcto ≥ 85% en condiciones normales de iluminación
2. La API REST de las cámaras LPR no requiere cambios de hardware para la integración
3. El sistema de cobro legacy puede recibir transacciones externas vía SOAP sin modificar su código fuente
4. Las tres sedes tienen conectividad a internet estable (mínimo 10 Mbps)
5. La pasarela Wompi cumple con PCI-DSS; ParkEasy no necesita almacenar datos de tarjeta directamente
6. Las placas de los vehículos están en formato estándar colombiano y son legibles por las cámaras
 
### 6.2 Dependencias
 
| Dependencia | Descripción | Criticidad |
|-------------|-------------|------------|
| **Cámaras LPR** | API REST para reconocimiento de placa en entrada/salida. Fallo activa modo manual | Alta |
| **Sistema de cobro legacy (VB6/SOAP)** | Registro de transacciones financieras oficiales. Riesgo: documentación incompleta | Alta |
| **Pasarela de pagos Wompi** | Procesamiento de pagos digitales. Fallo activa pago manual por operador | Alta |
| **Email/SMS (SendGrid + Twilio)** | Notificaciones y confirmaciones. No bloquea operación core ante fallo | Media |
| **DIAN** | Validación y reporte de facturas electrónicas | Media |
 
---

## 7. CRITERIOS DE ACEPTACIÓN DEL SISTEMA

El sistema ParkEasy será aceptado cuando:
 
✅ Todos los RF de prioridad Alta estén implementados y funcionando  
✅ Un vehículo completa el proceso de entrada mediante LPR en ≤ 5 segundos (P95)  
✅ Un vehículo completa salida con pago digital en ≤ 15 segundos (P95)  
✅ La disponibilidad de espacios se actualiza con retraso ≤ 10 segundos  
✅ 20 usuarios beta completan 100 transacciones de entrada/salida sin errores críticos  
✅ Integración con sistema legacy registra transacciones correctamente  
✅ Integración con Wompi procesa pagos exitosamente  
✅ Las facturas electrónicas se generan y envían correctamente tras cada pago  
✅ Los datos de placas se almacenan encriptados (verificable en base de datos)  
✅ El sistema opera sin interrupciones durante una semana de prueba en horario pico  
✅ Documentación técnica (SAD) esté completa  
 
---
Lo siguiente **NO** está incluido en el MVP:
 
❌ **Aplicación móvil nativa (iOS/Android)** — Se entrega PWA responsiva; app nativa se evalúa en fase 2  
❌ **Reemplazo del sistema de cobro legacy (VB6)** — Restricción explícita del negocio; migración futura  
❌ **Programa de fidelización o puntos** — Requiere definición de reglas de negocio adicionales  
❌ **Integración con Waze o Google Maps** — Se evalúa en fase 2 con suficiente volumen de datos  
❌ **Valet parking o gestión de motos/bicicletas** — Solo vehículos livianos en el MVP  
❌ **Inteligencia artificial para predicción de demanda** — Funcionalidad avanzada para fase 2  
❌ **Multitenancy (white-label para otros parqueaderos)** — Fuera del alcance del negocio actual  
 
---

## 8. DRIVERS ARQUITECTURALES IDENTIFICADOS

Los siguientes requisitos tienen mayor impacto en las decisiones arquitecturales:
 
| ID | Driver | Valor/Métrica | Prioridad |
|----|--------|---------------|-----------|
| **DR-01** | Performance de entrada/salida | ≤ 5 seg entrada (P95), ≤ 15 seg salida (P95) | Alta |
| **DR-02** | Disponibilidad en horas pico | ≥ 99.5% operacional; cero downtime 7–10am y 5–8pm | Alta |
| **DR-03** | Escalabilidad horizontal | 3 → 6 sedes / 450 → 1.200 espacios sin rediseño | Alta |
| **DR-04** | Integración legacy VB6/SOAP | Integración no intrusiva con API poco documentada | Alta |
| **DR-05** | Seguridad y cumplimiento regulatorio | PCI-DSS + Ley 1581 + retención DIAN 5 años | Alta |
| **DR-06** | Costo de infraestructura | ≤ $2.000 USD/mes MVP; ≤ $4.000 USD/mes al escalar | Media |
| **DR-07** | Usabilidad operadores sin formación técnica | ≤ 30 min inducción; ≤ 2% error en registro manual | Media |
 
---
 
## APROBACIONES
 
| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | Harold Alejandro Vargas Martínez | Harold Vargas | 18/03/2026 |
| **Integrante 2** | Juan Martin Trejos | __________ | 18/03/2026 |
| **Integrante 3** | Wilson David Sanchez Prieto | __________ | 18/03/2026 |
| **Integrante 4** | Juan Sebastian Forero Moreno | __________ | 18/03/2026 |
 
---
 
**Fin del Documento SRS**
 
---
<!--
## NOTAS PARA TENER EN CUENTA

### ✅ Checklist de Calidad

Antes de entregar, verificar:

- [ ] Mínimo 6 requisitos funcionales documentados
- [ ] Cada RF tiene ID, prioridad, descripción y criterios
- [ ] Mínimo 5 requisitos no funcionales documentados
- [ ] Cada RNF tiene métricas ESPECÍFICAS (no vagas)
- [ ] Alcance claramente definido (qué SÍ y qué NO)
- [ ] Supuestos documentados
- [ ] Drivers arquitecturales identificados (útil para ADRs)
- [ ] Documento profesional y bien redactado
- [ ] Sin errores ortográficos

### 💡 Tips

1. **Requisitos Funcionales:** Piensen en los flujos de usuario
2. **Requisitos No Funcionales:** Usen el enunciado, tiene métricas sugeridas
3. **Drivers:** Pregúntense "¿Este requisito impacta decisiones de arquitectura?"
4. **Alcance:** Sean realistas con 8 meses y 4 devs

### ⚠️ Errores Comunes a Evitar

❌ RNF vago: "El sistema debe ser rápido"  
✅ RNF específico: "Entrada/salida ≤ 5 segundos P95"

❌ RF sin criterios de aceptación  
✅ RF con 3-5 criterios medibles

❌ No documentar supuestos  
✅ Listar todos los supuestos en sección 6.1
-->
