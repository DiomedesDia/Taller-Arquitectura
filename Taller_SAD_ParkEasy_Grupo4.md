# Software Architecture Document (SAD)
## Sistema de Gestión de Parqueaderos - "ParkEasy"

**Versión:** 1.0  
**Fecha:** 19/03/2026  
**Grupo:** Grupo 4  
**Preparado por:**
- Harold Alejandro Vargas Martínez - 00020526190
- Juan Martin Trejos - 00020513089
- Wilson David Sanchez Prieto - [Código]
- Juan Sebastian Forero Moreno - [Código]

---

## CONTROL DE VERSIONES

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 0.1 | 19/03/2026 | Harold Alejandro Vargas Martínez | Borrador inicial del SAD |
| 1.0 | 19/03/2026 | Grupo 4 | Versión final para entrega |

---

## TABLA DE CONTENIDOS

1. [Introducción](#1-introducción)
2. [Descripción General de la Arquitectura](#2-descripción-general-de-la-arquitectura)
3. [Vistas Arquitecturales (C4)](#3-vistas-arquitecturales-c4)
4. [Decisiones Arquitecturales (ADRs)](#4-decisiones-arquitecturales-adrs)
5. [Tecnologías y Herramientas](#5-tecnologías-y-herramientas)
6. [Seguridad](#6-seguridad)
7. [Despliegue e Infraestructura](#7-despliegue-e-infraestructura)
8. [Calidad y Atributos](#8-calidad-y-atributos)
9. [Riesgos y Deuda Técnica](#9-riesgos-y-deuda-técnica)

---

## 1. INTRODUCCIÓN

### 1.1 Propósito del Documento

Este documento describe la arquitectura del sistema ParkEasy, una solución para digitalizar la operación de parqueaderos en múltiples sedes de Bogotá, permitiendo disponibilidad en tiempo real, reservas anticipadas, ingreso por reconocimiento de placas, pagos digitales, facturación electrónica y reportes administrativos.

Este documento sirve como:
- guía para el equipo de desarrollo durante la implementación del MVP;
- referencia para justificar las decisiones arquitecturales tomadas;
- documento de apoyo para evaluar la consistencia entre requisitos, decisiones y vistas C4;
- base para futuras iteraciones o evolución de la arquitectura del sistema.

### 1.2 Audiencia

| Rol | Uso de este documento |
|-----|----------------------|
| **Desarrolladores** | Entender la estructura del sistema, responsabilidades de cada servicio, tecnologías y lineamientos de implementación |
| **Arquitectos** | Revisar decisiones, trade-offs, riesgos y trazabilidad con los drivers |
| **Profesor** | Evaluar el diseño arquitectural, su justificación y consistencia documental |

### 1.3 Referencias

- **[SRS]** `Taller_SRS_ParkEasy_Grupo4.md` - Documento de requisitos
- **[DSL]** `Taller_ParkEasy_Architecture_Grupo4.dsl` - Vistas C4 en Structurizr
- **[ADR-001]** `Taller_ADR-001_ServiceBasedArchitecture_Grupo4.md` - Adoptar Service-Based Architecture
- **[ADR-002]** `Taller_ADR-002_PostgreSQL_Grupo4.md` - Adoptar PostgreSQL como base de datos principal
- **[ADR-003]** `Taller_ADR-003_AntiCorruptionLayer_Grupo4.md` - Adoptar Anti-Corruption Layer para integración con sistema legacy

### 1.4 Alcance

Este documento cubre la arquitectura del **MVP** de ParkEasy.

**Dentro de alcance:**
- Gestión de disponibilidad de espacios en tiempo real
- Reservas anticipadas de espacios
- Ingreso automático sin contacto mediante reconocimiento de placa (LPR)
- Procesamiento de pagos digitales al salir
- Generación y envío de factura electrónica
- Panel de gestión para operadores de caseta
- Dashboard y reportes para administradores
- Configuración de tarifas por sede

**Fuera de alcance:**
- Aplicación móvil nativa (iOS/Android)
- Reemplazo del sistema de cobro legacy (VB6)
- Programa de fidelización o puntos
- Integración con Waze o Google Maps
- Valet parking o gestión de motos/bicicletas
- Inteligencia artificial para predicción de demanda
- Multitenancy (white-label para otros parqueaderos)

---

## 2. DESCRIPCIÓN GENERAL DE LA ARQUITECTURA

### 2.1 Filosofía de Diseño

La arquitectura de ParkEasy sigue estos principios:

1. **Entrega incremental del MVP:** se prioriza una solución viable en 8 meses con un equipo de 4 desarrolladores, evitando complejidad innecesaria.
2. **Separación de responsabilidades:** las funcionalidades principales se distribuyen por servicios de negocio para mejorar mantenibilidad y escalabilidad.
3. **Integración desacoplada:** los sistemas externos críticos, especialmente el legacy SOAP, se aíslan para reducir el impacto de cambios o fallos.
4. **Costo-eficiencia:** se eligen tecnologías open source y servicios cloud administrados que permitan mantenerse dentro del presupuesto mensual definido.
5. **Resiliencia operativa:** se busca garantizar continuidad durante horas pico y soportar modos degradados cuando falle un sistema externo.

### 2.2 Estilo Arquitectural Principal

**Service-Based Architecture** (ver ADR-001)

ParkEasy adopta una arquitectura basada en servicios funcionales. En este enfoque, el sistema se divide en servicios con responsabilidades claras, como gestión de parqueadero, reservas, pagos, facturación e integración, manteniendo un nivel de desacoplamiento superior al monolito, pero con menor complejidad operativa que una arquitectura de microservicios.

Este estilo permite aislar funcionalidades críticas, como pagos e integración con sistemas externos, sin introducir la sobrecarga técnica de una solución totalmente distribuida. También facilita que diferentes partes del sistema evolucionen de manera controlada y que componentes de alta demanda puedan optimizarse sin rediseñar todo el sistema.

**Justificación:** esta decisión responde principalmente a los drivers de rendimiento, disponibilidad, escalabilidad, integración con legacy, seguridad y costo. La arquitectura seleccionada ofrece un balance adecuado entre mantenibilidad, escalabilidad y simplicidad operativa para el contexto del proyecto.

### 2.3 Drivers Arquitecturales (ASRs)

Los siguientes Architecturally Significant Requirements guiaron las decisiones:

| ID | Driver | Valor | Prioridad |
|----|--------|-------|-----------|
| **DR-01** | Performance de entrada/salida | ≤ 5 seg entrada (P95), ≤ 15 seg salida (P95) | Alta |
| **DR-02** | Disponibilidad en horas pico | ≥ 99.5% operacional; cero downtime 7–10am y 5–8pm | Alta |
| **DR-03** | Escalabilidad horizontal | 3 → 6 sedes / 450 → 1.200 espacios sin rediseño | Alta |
| **DR-04** | Integración legacy VB6/SOAP | Integración no intrusiva con API poco documentada | Alta |
| **DR-05** | Seguridad y cumplimiento regulatorio | PCI-DSS + Ley 1581 + retención DIAN 5 años | Alta |
| **DR-06** | Costo de infraestructura | ≤ $2.000 USD/mes MVP; ≤ $4.000 USD/mes al escalar | Media |
| **DR-07** | Usabilidad operadores sin formación técnica | ≤ 30 min inducción; ≤ 2% error en registro manual | Media |

---

## 3. VISTAS ARQUITECTURALES (C4)

Este documento utiliza el **modelo C4** para describir la arquitectura.

**Archivo Structurizr DSL:** `Taller_ParkEasy_Architecture_Grupo4.dsl`

**Cómo visualizar:**
1. Ir a `https://structurizr.com/dsl`
2. Copiar el contenido del archivo `.dsl`
3. Hacer clic en **Render**
4. Revisar las vistas en el menú lateral izquierdo

### 3.1 C4 Nivel 1: Context Diagram

**Propósito:** Mostrar cómo ParkEasy se relaciona con usuarios y sistemas externos.

**Elementos clave:**
- **Usuarios:** Conductor, Operador, Administrador
- **Sistema principal:** ParkEasy
- **Sistemas externos:** Sistema de Cámaras LPR, Sistema de Cobro Legacy, Wompi, Servicios de Notificación, DIAN

En esta vista se observa que los conductores usan el sistema para consultar disponibilidad, reservar y pagar; los operadores lo usan para registros manuales e incidencias; y los administradores lo usan para reportes y configuración. A su vez, ParkEasy depende de varios sistemas externos para reconocimiento de placas, pagos, notificaciones, registro de transacciones y facturación.

**Vista en Structurizr:** `SystemContext`

### 3.2 C4 Nivel 2: Container Diagram

**Propósito:** Mostrar los contenedores que componen ParkEasy.

**Contenedores principales:**

| Contenedor | Tecnología | Responsabilidad |
|------------|------------|-----------------|
| **Web App** | React (PWA) | Interfaz para conductores, operadores y administradores |
| **API Backend / Gateway** | Node.js + NestJS | Punto de entrada principal, validación y orquestación |
| **Parking Service** | Node.js + NestJS | Gestión de entradas, salidas, ocupación y comunicación con LPR |
| **Booking Service** | Node.js + NestJS | Gestión de reservas anticipadas |
| **Payment Service** | Node.js + NestJS | Procesamiento de pagos e integración con Wompi y legacy |
| **Billing Service** | Node.js + NestJS | Generación de facturación electrónica e integración con DIAN |
| **Integration Service / ACL** | Node.js + NestJS | Encapsular integración con sistema legacy SOAP |
| **Base de Datos Principal** | PostgreSQL | Almacenar usuarios, reservas, pagos, facturas y operación |

Estos contenedores siguen la arquitectura basada en servicios definida en ADR-001 y están alineados con las necesidades del MVP.

**Vista en Structurizr:** `Containers`

### 3.3 C4 Nivel 3: Component Diagrams

**Propósito:** Mostrar componentes internos de un servicio clave.

**Servicio documentado:** Parking Service

**Componentes:**

| Componente | Responsabilidad |
|------------|-----------------|
| **Parking Controller** | Exponer endpoints REST para entradas, salidas y consulta de ocupación |
| **Parking Service Logic** | Implementar la lógica de negocio del parqueadero |
| **Parking Repository** | Gestionar acceso a datos persistidos en PostgreSQL |
| **LPR Client** | Consumir API REST de las cámaras LPR |

**Vista en Structurizr:** `ComponentsParkingService`

---

## 4. DECISIONES ARQUITECTURALES (ADRs)

### 4.1 ADR-001: Adoptar Service-Based Architecture

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-001_ServiceBasedArchitecture_Grupo4.md`

**Resumen:** Se decidió adoptar una arquitectura basada en servicios para separar las funciones principales del sistema, como parqueadero, reservas, pagos y facturación, manteniendo una complejidad operativa manejable para el equipo.

**Alternativas consideradas:** Monolito, Microservicios, Service-Based Architecture.

**Trade-off aceptado:** Se sacrifica parte del desacoplamiento extremo de microservicios a cambio de menor complejidad operativa y menor costo.

**Ver documento completo:** ADR-001

---

### 4.2 ADR-002: Adoptar PostgreSQL como base de datos principal

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-002_PostgreSQL_Grupo4.md`

**Resumen:** Se seleccionó PostgreSQL como base de datos principal por su consistencia fuerte, soporte transaccional y capacidad para modelar relaciones complejas del dominio como reservas, pagos y facturación.

**Alternativas consideradas:** PostgreSQL, MongoDB, DynamoDB.

**Trade-off aceptado:** Se acepta una escalabilidad horizontal menos simple que en algunas soluciones NoSQL a cambio de integridad de datos y menor riesgo en operaciones financieras.

**Ver documento completo:** ADR-002

---

### 4.3 ADR-003: Adoptar Anti-Corruption Layer para integración con sistema legacy

**Estado:** Aceptado  
**Archivo:** `Taller_ADR-003_AntiCorruptionLayer_Grupo4.md`

**Resumen:** Se definió una capa de anti-corrupción para encapsular la integración con el sistema legacy VB6/SOAP, evitando que la complejidad y fragilidad del sistema antiguo contaminen el resto de la arquitectura.

**Alternativas consideradas:** Integración directa con SOAP, API Gateway como integrador, Anti-Corruption Layer.

**Trade-off aceptado:** Se acepta una capa adicional y algo más de complejidad inicial a cambio de mayor mantenibilidad, resiliencia y desacoplamiento.

**Ver documento completo:** ADR-003

---

## 5. TECNOLOGÍAS Y HERRAMIENTAS

### 5.1 Stack Tecnológico

| Capa | Tecnología | Versión | Justificación |
|------|------------|---------|---------------|
| **Frontend** | React (PWA) | 18.x | Interfaz web responsiva, rápida de desarrollar y suficiente para conductores, operadores y administradores |
| **Backend** | Node.js + NestJS | Node 20 LTS / NestJS 10.x | Framework estructurado, modular y adecuado para APIs REST y servicios empresariales |
| **Database** | PostgreSQL | 16.x | Consistencia ACID, relaciones complejas y soporte transaccional. Ver ADR-002 |
| **Cache** | No aplica en MVP | - | Se evita complejidad adicional; el volumen del MVP puede manejarse sin capa de cache |
| **Message Queue** | No aplica en el MVP | - | Se evita introducir complejidad adicional en esta fase |
| **Contenedores** | Docker | 26.x | Empaquetado reproducible de frontend y servicios backend |
| **Control de versiones** | Git + GitHub | - | Colaboración del equipo y trazabilidad de cambios |
| **CI/CD** | GitHub Actions | - | Automatización de build, tests y despliegue |
| **Modelado C4** | Structurizr DSL | - | Requerido por el taller para documentar arquitectura |

### 5.2 Servicios Cloud

**Proveedor:** AWS

| Servicio | Uso | Costo estimado/mes |
|----------|-----|-------------------|
| **ECS Fargate** | Hosting de servicios backend y frontend | $360 |
| **RDS PostgreSQL** | Base de datos relacional principal | $180 |
| **Application Load Balancer** | Balanceo de tráfico HTTPS | $25 |
| **S3** | Almacenamiento de facturas y reportes exportados | $20 |
| **CloudWatch** | Logs, métricas y alertas | $35 |
| **Secrets Manager** | Gestión de secretos y credenciales | $15 |
| **Route 53 + ACM** | DNS y certificados TLS | $10 |
| **TOTAL** | | **$645/mes aprox.** |

**Validación:** Sí, cumple con **DR-06** y se mantiene por debajo del presupuesto de **$2.000 USD/mes** para el MVP.

### 5.3 Servicios Externos

| Servicio | Uso | Costo |
|----------|-----|-------|
| **Sistema LPR** | Reconocimiento de placas en entrada/salida | Ya existente / asumido fuera del costo cloud del MVP |
| **Wompi** | Procesamiento de pagos digitales | Comisión por transacción |
| **Sistema de cobro legacy VB6/SOAP** | Registro oficial de transacciones | Ya existente |
| **SendGrid + Twilio** | Confirmaciones de reserva y pago | Variable según volumen |
| **DIAN** | Facturación electrónica | Dependiente de integración / proveedor de facturación |

---

## 6. SEGURIDAD

### 6.1 Autenticación y Autorización

**Mecanismo:** JWT

**Flujo:**
1. El usuario inicia sesión con credenciales válidas.
2. El backend autentica al usuario y emite un token JWT firmado.
3. El cliente React envía el token en cada solicitud protegida.
4. Los servicios NestJS validan el token y autorizan según rol.

**Roles:**
- `driver`: consultar disponibilidad, crear reservas, consultar pagos y descargar facturas
- `operator`: registrar entradas/salidas manuales, gestionar incidentes, consultar operación en tiempo real
- `admin`: acceder a dashboard, reportes, configuración de tarifas y administración general

### 6.2 Protección de Datos

**Cumplimiento Ley 1581 (Colombia):**
- [x] Consentimiento explícito
- [x] Política de privacidad
- [x] Encriptación en tránsito (TLS)
- [x] Encriptación en reposo
- [x] Control de acceso por roles
- [x] Auditoría de operaciones sensibles

**Datos sensibles:**
- **Placas vehiculares:** se almacenan cifradas en reposo con AES-256 y se transmiten únicamente sobre TLS 1.2+ o superior.
- **Datos de pago:** ParkEasy no almacena datos completos de tarjeta. El procesamiento se delega a Wompi, reduciendo el alcance PCI-DSS.
- **Facturas y logs de auditoría:** se almacenan con acceso restringido y políticas de retención acordes con DIAN.

### 6.3 Protección de APIs

| Medida | Implementación |
|--------|----------------|
| **HTTPS** | Sí, mediante ALB + AWS Certificate Manager |
| **Rate limiting** | Máximo 100 requests/minuto por IP |
| **Input validation** | Validación en controladores y DTOs de NestJS |
| **Autorización** | Guards y roles con JWT |
| **Gestión de secretos** | AWS Secrets Manager |
| **Auditoría** | Logs de operaciones sensibles y accesos administrativos |

---

## 7. DESPLIEGUE E INFRAESTRUCTURA

### 7.1 Ambientes

| Ambiente | Propósito | URL |
|----------|-----------|-----|
| **Development** | Desarrollo local y pruebas unitarias | localhost |
| **Staging** | Validación funcional, integración y pruebas previas a producción | `staging.parkeasy.grupo4.aws` |
| **Production** | Operación real del MVP | `app.parkeasy.grupo4.aws` |

### 7.2 Estrategia de Despliegue

**Método:** Rolling deployment

**Proceso:**
1. Se ejecuta pipeline de CI/CD con build, pruebas unitarias e integración.
2. Se construyen imágenes Docker para frontend React y servicios NestJS.
3. Las imágenes se publican en el repositorio correspondiente.
4. ECS actualiza progresivamente las tareas del servicio sin interrumpir completamente la operación.
5. Si falla la verificación de salud, se revierte a la versión estable anterior.

### 7.3 Configuración de Infraestructura

| Service | Instancias | CPU | RAM |
|---------|-----------|-----|-----|
| **React Web App** | 2 | 0.25 vCPU | 0.5 GB |
| **API Backend / Gateway** | 2 | 0.5 vCPU | 1 GB |
| **Parking Service** | 2 | 0.5 vCPU | 1 GB |
| **Booking Service** | 2 | 0.5 vCPU | 1 GB |
| **Payment Service** | 2 | 1 vCPU | 2 GB |
| **Billing Service** | 2 | 0.5 vCPU | 1 GB |
| **Integration Service** | 2 | 0.5 vCPU | 1 GB |

**Base de Datos:**
- Instancia: `db.t4g.medium`
- Storage: 100 GB
- Multi-AZ: Sí
- Backups: diarios automáticos con retención de 7 días en MVP

### 7.4 Monitoreo y Alertas

**Métricas clave:**
- Tiempo de entrada P95 > 5 s → alerta inmediata a operación
- Tiempo de salida P95 > 15 s → alerta de rendimiento
- Error rate > 3% en Payment Service → alerta crítica
- Disponibilidad del sistema < 99.5% mensual → revisión prioritaria
- Latencia del sistema legacy > threshold definido → activar investigación
- Uso de CPU > 75% sostenido por 10 min → escalar servicio
- Espacio en base de datos > 80% → alerta preventiva

**Herramientas:**
- AWS CloudWatch
- Dashboards operativos
- Logs centralizados por servicio

---

## 8. CALIDAD Y ATRIBUTOS

### 8.1 Mapa de Atributos a Decisiones

| Atributo | Objetivo (del SRS) | Decisión arquitectural |
|----------|-------------------|------------------------|
| **Performance** | RNF-01: entrada ≤ 5 s P95, salida ≤ 15 s P95, disponibilidad ≤ 500 ms | Service-Based Architecture + separación de servicios críticos + optimización de consultas |
| **Availability** | RNF-02: ≥ 99.5%, cero downtime en horas pico, RTO ≤ 30 min | AWS administrado + múltiples instancias + rolling deployment + modo degradado |
| **Scalability** | RNF-03: 3 → 6 sedes, 450 → 1.200 espacios | Servicios desacoplados + ECS + PostgreSQL |
| **Security** | RNF-04: AES-256, TLS, PCI-DSS, auditoría | JWT + cifrado + integración con Wompi + control de acceso |
| **Cost** | RNF-06: ≤ $2.000 USD/mes MVP | Tecnologías open source + AWS administrado + arquitectura balanceada |
| **Usability** | RNF-05: operadores con baja formación técnica | React PWA con flujos simples y separados por rol |

### 8.2 Tácticas Arquitecturales Aplicadas

**Para Performance:**
- ✅ Separación de servicios críticos como Parking y Payment
- ✅ Índices en PostgreSQL para consultas frecuentes
- ✅ Reducción de lógica pesada en el frontend
- ✅ Consultas optimizadas para disponibilidad por sede

**Para Availability:**
- ✅ Múltiples instancias por servicio
- ✅ RDS Multi-AZ
- ✅ Rolling deployment con health checks
- ✅ Modo degradado para operación manual
- ✅ ACL para aislar fallos del sistema legacy

**Para Scalability:**
- ✅ Escalado horizontal en ECS
- ✅ Servicios independientes por dominio funcional
- ✅ Diseño preparado para agregar nuevas sedes sin rediseño

**Para Security:**
- ✅ JWT y autorización por roles
- ✅ Encriptación de datos sensibles
- ✅ Delegación de pagos a Wompi
- ✅ Auditoría y trazabilidad

**Para Cost:**
- ✅ Stack open source
- ✅ Infraestructura moderada en AWS
- ✅ Sin componentes adicionales no esenciales en el MVP

### 8.3 Testing Strategy

| Tipo | Herramienta | Coverage objetivo |
|------|-------------|-------------------|
| **Unit tests** | Jest | 80% en lógica de negocio |
| **Integration tests** | Jest + Supertest | Flujos entre servicios y base de datos |
| **E2E tests** | Cypress | Reserva, pago, facturación, registro manual |
| **Load tests** | k6 | Hasta 160 transacciones/hora sin degradación significativa |

---

## 9. RIESGOS Y DEUDA TÉCNICA

### 9.1 Riesgos Técnicos Identificados

| ID | Riesgo | Probabilidad | Impacto | Mitigación |
|----|--------|--------------|---------|------------|
| **R-01** | Sistema legacy SOAP poco documentado e inestable | Alta | Alto | Anti-Corruption Layer, timeouts, retries, pruebas de integración |
| **R-02** | Fallas o baja precisión del sistema LPR | Media | Alto | Modo manual por operador, monitoreo y validación por confianza |
| **R-03** | Sobrecarga en Payment Service en horas pico | Media | Alto | Escalado horizontal, métricas y optimización |
| **R-04** | Inconsistencia entre documentos y vistas C4 | Media | Medio | Actualizar DSL para alinear stack y contenedores |
| **R-05** | Desfase entre costo real cloud y proyección | Baja | Medio | Monitoreo de costos AWS y ajuste de tamaños de instancias |

### 9.2 Deuda Técnica Aceptada

| Ítem | Justificación | Plan de resolución |
|------|---------------|-------------------|
| **Base de datos compartida entre servicios** | Simplifica el MVP y reduce complejidad operativa | Evaluar separación más estricta por servicio en una siguiente fase |
| **Sin message broker en MVP** | Se evita complejidad adicional para el equipo pequeño | Considerar eventos asíncronos en fase 2 |
| **Sin capa de cache en MVP** | El volumen proyectado puede manejarse sin cache y reduce complejidad | Evaluar Redis en fase 2 si las métricas reales lo justifican |
| **Modo degradado principalmente manual** | Permite continuidad operativa sin sobreingeniería | Automatizar más escenarios de contingencia en siguientes versiones |

### 9.3 Supuestos Críticos

1. Las cámaras LPR tienen tasa de reconocimiento correcto ≥ 85% en condiciones normales de iluminación.
2. La API REST de las cámaras LPR no requiere cambios de hardware para la integración.
3. El sistema de cobro legacy puede recibir transacciones externas vía SOAP sin modificar su código fuente.
4. Las tres sedes tienen conectividad a internet estable (mínimo 10 Mbps).
5. La pasarela Wompi cumple con PCI-DSS; ParkEasy no necesita almacenar datos de tarjeta directamente.
6. Las placas de los vehículos están en formato estándar colombiano y son legibles por las cámaras.

---

## APROBACIONES

| Rol | Nombre | Firma | Fecha |
|-----|--------|-------|-------|
| **Líder del Grupo** | Harold Alejandro Vargas Martínez | __________ | 19/03/2026 |
| **Arquitecto** | Juan Martin Trejos | __________ |  19/03/2026|
| **Desarrollador 1** | Wilson David Sanchez Prieto | __________ |  19/03/2026 |
| **Desarrollador 2** | Juan Sebastian Forero Moreno | __________ |  19/03/2026 |

---

**Fin del Documento SAD**
