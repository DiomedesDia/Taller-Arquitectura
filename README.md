# Taller: Documentación Arquitectural - ParkEasy
## Grupo 4

**Integrantes:**
- Harold Alejandro Vargas Martínez - 00020526190 
- Juan Martin Trejos - 00020513089 
- Wilson David Sanchez Prieto - [Código] 
- Juan Sebastian Forero Moreno - [Código] 

**Fecha de entrega:** 19/03/2026

---

## 📋 CONTENIDO DE LA ENTREGA

Este ZIP contiene la documentación arquitectural completa del sistema ParkEasy:

```
├── README.md                          (Este archivo)
├── Plantilla_SRS_ParkEasy.md         (Requisitos)
├── ADR 001 ParkEasy.md               (Decisión arquitectural 1)
├── 003_ADR-002_PostgreSQL.md         (Decisión arquitectural 2)
├── 004_ADR-003_Modelo_Anticorru.md   (Decisión arquitectural 3)
├── Structurizr_ParkEasy.dsl          (Vistas C4)
└── Taller_SAD_ParkEasy_Grupo4.md     (Documento arquitectural)
```

---

## 🎨 CÓMO VISUALIZAR LAS VISTAS C4

### Opción 1: Structurizr Online (RECOMENDADO)

1. Ir a: https://structurizr.com/dsl
2. Abrir el archivo `Structurizr_ParkEasy.dsl`
3. Copiar TODO el contenido
4. Pegar en el editor de Structurizr
5. Click en **"Render"**
6. Ver las vistas en el menú izquierdo:
   - **SystemContext:** Vista de contexto (C4 Nivel 1)
   - **Containers:** Vista de contenedores (C4 Nivel 2)
   - **ComponentsParkingService:** Vista de componentes del Parking Service (C4 Nivel 3)

---

## 🏗️ DECISIONES ARQUITECTURALES CLAVE

### 1. Estilo Arquitectural: Service-Based Architecture

**Decisión:** Service-Based Architecture con 6 servicios funcionales independientes.

**Alternativas consideradas:** Monolito, Microservicios.

**Por qué lo elegimos:** Ofrece el balance ideal entre desacoplamiento y simplicidad operativa para un equipo de 4 desarrolladores con 8 meses de plazo. Microservicios resultaba sobredimensionado y un monolito no permitía aislar los sistemas externos críticos como el legacy SOAP y los pagos.

**Ver:** `ADR 001 ParkEasy.md`

---

### 2. Base de Datos: PostgreSQL en AWS RDS

**Decisión:** PostgreSQL 16 desplegado en AWS RDS con configuración Multi-AZ.

**Alternativas consideradas:** MongoDB, DynamoDB.

**Por qué lo elegimos:** Garantiza consistencia ACID obligatoria para transacciones financieras (pagos, facturación). PostgreSQL es conocido por el equipo y su modelo relacional encaja naturalmente con las entidades del dominio (reservas → pagos → facturas).

**Ver:** `003_ADR-002_PostgreSQL.md`

---

### 3. Integración con Sistema Legacy: Anti-Corruption Layer (ACL)

**Decisión:** Integration Service dedicado que actúa como Anti-Corruption Layer, siendo el único punto de contacto con el sistema VB6/SOAP.

**Alternativas consideradas:** Integración directa con SOAP, API Gateway como integrador.

**Por qué lo elegimos:** El sistema legacy tiene una API SOAP poco documentada e inestable. El ACL aísla esa complejidad del resto de la arquitectura, implementa patrones de resiliencia (circuit breaker, retries, timeouts) y facilita el reemplazo futuro del legacy sin afectar otros servicios.

**Ver:** `004_ADR-003_Modelo_Anticorru.md`

---

## 📊 RESUMEN DE LA ARQUITECTURA

### Estilo Arquitectural

**Service-Based Architecture** — servicios funcionales con base de datos compartida (PostgreSQL), comunicación síncrona vía REST y cola asíncrona (AWS SQS) para integración con el sistema legacy.

### Componentes Principales

1. **Web App** — React (PWA) — Interfaz unificada para conductores, operadores y administradores con soporte offline
2. **API Backend / Gateway** — Node.js + NestJS — Punto de entrada, validación y orquestación de servicios
3. **Parking Service** — Node.js + NestJS — Gestión de entradas, salidas, ocupación y comunicación con cámaras LPR
4. **Booking Service** — Node.js + NestJS — Gestión de reservas anticipadas (hasta 2 horas antes)
5. **Payment Service** — Node.js + NestJS — Procesamiento de pagos digitales con Wompi
6. **Billing Service** — Node.js + NestJS — Generación de facturación electrónica (DIAN)
7. **Integration Service (ACL)** — Node.js + NestJS — Encapsulación de integración con sistema legacy VB6/SOAP

### Stack Tecnológico

| Capa | Tecnología |
|------|------------|
| **Frontend** | React 18 (PWA) |
| **Backend** | Node.js 20 LTS + NestJS 10 + TypeScript |
| **Base de Datos** | PostgreSQL 16 (AWS RDS Multi-AZ) |
| **Cache** | No aplica en MVP — se evalúa Redis en Fase 2 |
| **Message Queue** | AWS SQS (sincronización asíncrona con legacy) |
| **Contenedores** | Docker + AWS ECS Fargate |
| **CI/CD** | GitHub Actions |
| **Cloud** | AWS |

### Integraciones Externas

- **Cámaras LPR:** API REST — reconocimiento automático de placas en entrada/salida
- **Sistema de Cobro Legacy (VB6):** SOAP — registro oficial de transacciones (vía ACL)
- **Wompi:** API REST — pasarela de pagos (tarjeta, Nequi, Daviplata)
- **SendGrid + Twilio:** API REST — notificaciones por email y SMS
- **DIAN:** Proveedor habilitado — facturación electrónica

---

## 💰 ESTIMACIÓN DE COSTOS

| Servicio AWS | Costo mensual |
|--------------|---------------|
| ECS Fargate (7 servicios) | $360 |
| RDS PostgreSQL Multi-AZ | $180 |
| Application Load Balancer | $25 |
| S3 (facturas 5 años + reportes) | $20 |
| AWS SQS | $5 |
| CloudWatch | $35 |
| Secrets Manager | $15 |
| Route 53 + ACM | $10 |
| **TOTAL** | **$650/mes** |

**¿Cumple con presupuesto de $2.000 USD/mes?** ✅ SÍ — con un margen de $1.350/mes disponible para crecer a 6 sedes.

---

## 🎯 CÓMO CUMPLIMOS LOS DRIVERS

| Driver | Objetivo | Cómo lo cumplimos |
|--------|----------|-------------------|
| **DR-01: Performance** | Entrada ≤ 5 seg P95 / Salida ≤ 15 seg P95 | Servicios críticos con más recursos en ECS + índices optimizados en PostgreSQL + SQS desacopla operaciones asíncronas del legacy |
| **DR-02: Disponibilidad** | ≥ 99.5% sin downtime en horas pico | RDS Multi-AZ (SLA 99.95%) + múltiples instancias ECS + rolling deployment + modo fallback manual para operadores |
| **DR-03: Escalabilidad** | 450 → 1.200 espacios sin rediseño | Auto-scaling en ECS (CPU > 70%) + nueva sede configurable en ≤ 8 horas sin desarrollo adicional |
| **DR-04: Legacy** | Integración SOAP no intrusiva | Anti-Corruption Layer con circuit breaker, retries y timeouts |
| **DR-05: Seguridad** | PCI-DSS + Ley 1581 + DIAN 5 años | Placas cifradas AES-256 + TLS 1.2+ + pagos delegados a Wompi + facturas en S3 con retención 5 años |
| **DR-06: Costo** | ≤ $2.000 USD/mes MVP | Stack open source + infraestructura AWS moderada = $650/mes |
| **DR-07: Usabilidad** | Operadores con educación básica | PWA con flujos separados por rol, máximo 3 pasos por tarea |

---

## 📝 SUPUESTOS ASUMIDOS

1. **API de cámaras LPR:** La API REST tiene documentación suficiente para integrarse sin cambios de hardware, con tasa de reconocimiento exitoso ≥ 90% en condiciones normales de iluminación.
2. **Sistema legacy SOAP:** El sistema VB6 puede recibir transacciones externas vía SOAP sin modificar su código fuente. Se estiman entre 4 y 6 semanas de ingeniería inversa para documentar el protocolo.
3. **Conectividad en sedes:** Cada parqueadero cuenta con conexión a internet de mínimo 10 Mbps con respaldo de red 4G para el modo offline de operadores.
4. **Wompi como pasarela PCI-DSS:** Wompi está certificado PCI-DSS, por lo que ParkEasy no necesita almacenar datos de tarjeta directamente.
5. **Proveedor DIAN habilitado:** ParkEasy ya cuenta con un proveedor de facturación electrónica habilitado por la DIAN antes del inicio del desarrollo.
6. **Volumen de reservas:** Se estima que el 20% del volumen diario provendrá de reservas anticipadas, conforme al enunciado.
7. **Placas en formato estándar:** Todas las placas están en formato colombiano estándar y son legibles por las cámaras en condiciones normales.

---

## ⚠️ RIESGOS IDENTIFICADOS

| Riesgo | Mitigación |
|--------|------------|
| **Sistema legacy SOAP poco documentado e inestable** | Anti-Corruption Layer con circuit breaker, retries y timeouts. Investigación del protocolo SOAP desde la semana 1 |
| **Fallas o baja precisión del sistema LPR** | Modo fallback manual para operadores activado cuando confianza < 90% |
| **Sobrecarga en Payment Service en horas pico** | Auto-scaling en ECS con trigger a CPU > 70% y alertas tempranas en CloudWatch |

---

## 🔄 PROCESO DE TRABAJO DEL GRUPO

### División de Trabajo

| Integrante | Responsabilidades |
|------------|-------------------|
| Harold Alejandro Vargas Martínez | Líder del grupo, SRS, ADR-001, coordinación general |
| Juan Martin Trejos | ADR-002 (PostgreSQL), vistas C4 en Structurizr DSL |
| Wilson David Sanchez Prieto | ADR-003 (Anti-Corruption Layer), seguridad e infraestructura del SAD |
| Juan Sebastian Forero Moreno | SAD completo, README, integración y revisión de consistencia |

### Metodología

Nos reunimos en sesiones virtuales para analizar el enunciado en conjunto e identificar los drivers arquitecturales antes de dividir el trabajo. Cada integrante redactó su documento asignado y luego hicimos una revisión cruzada para garantizar consistencia entre SRS, ADRs y SAD. Usamos el repositorio de GitHub para centralizar todos los archivos y mantener trazabilidad de cambios.

---

## 💡 APRENDIZAJES Y REFLEXIONES

### ¿Qué aprendimos?

Este taller nos permitió entender que la arquitectura de software no se trata solo de elegir tecnologías, sino de justificar cada decisión con base en requisitos concretos y trade-offs explícitos. Aprendimos a usar los drivers arquitecturales como brújula: cada vez que evaluábamos una alternativa, preguntábamos si cumplía con los drivers identificados en el SRS.

También comprendimos el valor de documentar lo que no elegimos. Los ADRs con alternativas descartadas son tan importantes como la decisión tomada, porque muestran que el equipo analizó el problema con profundidad y no eligió por intuición o moda tecnológica.

### Desafíos enfrentados

El mayor desafío fue la integración con el sistema legacy VB6/SOAP. Al no tener documentación completa, tuvimos que tomar decisiones con incertidumbre y documentarla honestamente en el ADR-003 y en los supuestos del SRS.

Otro desafío fue estimar los costos de AWS. Usamos la calculadora oficial y tomamos como referencia el ejemplo de CourtBooker para validar que nuestras estimaciones eran razonables.

### Si pudiéramos empezar de nuevo...

Comenzaríamos identificando los drivers arquitecturales desde el primer día, antes de pensar en tecnologías. El orden correcto es: requisitos → drivers → decisiones → tecnologías.

---

## 📚 REFERENCIAS CONSULTADAS

- Ejemplo completo CourtBooker — material del curso (Profesor Rafael Ocampo)
- Structurizr DSL: https://docs.structurizr.com/
- C4 Model: https://c4model.com/
- ADR Format: https://adr.github.io/
- AWS Pricing Calculator: https://calculator.aws/
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- NestJS Documentation: https://docs.nestjs.com/

---

## ✅ VALIDACIÓN FINAL

Antes de entregar, verificamos:

- [x] Todos los archivos están incluidos en el ZIP
- [x] Archivo .dsl renderiza correctamente en Structurizr
- [x] SRS tiene mínimo 6 RF y 5 RNF con métricas específicas
- [x] 3 ADRs completos con mínimo 2 alternativas y trade-offs explícitos
- [x] SAD referencia correctamente todos los documentos
- [x] Costos estimados suman $650/mes ≤ $2.000 USD/mes ✅
- [x] Documentos profesionales sin errores ortográficos
- [x] README explica claramente el trabajo y cómo visualizar las vistas C4

---

**Fecha de entrega:** 19/03/2026  
**Grupo:** 4  
**Curso:** Arquitectura de Software  
**Pontificia Universidad Javeriana**

---

## ANEXO: Estructura de Archivos Detallada

```
Grupo4_Taller_Documentacion_Arquitectural.zip
│
├── README.md
│   └── Explica el trabajo, cómo visualizar C4, decisiones clave y reflexiones
│
├── Plantilla_SRS_ParkEasy.md
│   └── 7 requisitos funcionales con criterios de aceptación
│   └── 6 requisitos no funcionales con métricas específicas
│   └── 7 drivers arquitecturales identificados
│
├── ADR 001 ParkEasy.md
│   └── Decisión: Service-Based vs Monolito vs Microservicios
│
├── 003_ADR-002_PostgreSQL.md
│   └── Decisión: PostgreSQL vs MongoDB vs DynamoDB
│
├── 004_ADR-003_Modelo_Anticorru.md
│   └── Decisión: ACL vs Integración directa SOAP vs API Gateway
│
├── Structurizr_ParkEasy.dsl
│   └── Vista SystemContext (C4 Nivel 1)
│   └── Vista Containers (C4 Nivel 2)
│   └── Vista ComponentsParkingService (C4 Nivel 3)
│
└── Taller_SAD_ParkEasy_Grupo4.md
    └── Documento maestro que integra SRS, ADRs y vistas C4
    └── Stack tecnológico, seguridad, infraestructura AWS
    └── Riesgos, deuda técnica y evolución futura
```

---

**Creado:** Marzo 2026  
**Última actualización:** 19 de marzo de 2026
