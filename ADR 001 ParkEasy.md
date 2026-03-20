# ADR-001: Adoptar Service-Based Architecture

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Harold Alejandro Vargas Martínez, Juan Martin Trejos, Wilson David Sanchez Prieto, Juan Sebastian Forero Moreno  
**Relacionado con:** RF-01, RF-02, RF-03, RF-04, RF-05, RNF-01, RNF-02, RNF-03, RNF-04, DR-01, DR-02, DR-03, DR-04, DR-05, DR-06, DR-07  
**Grupo:** Grupo 4  

---

## Contexto y Problema

El sistema ParkEasy debe gestionar en tiempo real la operación de parqueaderos en múltiples sedes, incluyendo funcionalidades críticas como reservas anticipadas, ingreso automático mediante reconocimiento de placas (LPR), procesamiento de pagos digitales, generación de facturación electrónica y paneles administrativos.

El sistema debe integrarse con múltiples sistemas externos y heterogéneos, incluyendo cámaras LPR (API REST), un sistema legacy en VB6 con API SOAP poco documentada, la pasarela de pagos Wompi y servicios de notificación como SendGrid y Twilio. Estas integraciones representan un alto nivel de complejidad técnica y riesgo.

Adicionalmente, el sistema debe cumplir con estrictos requisitos no funcionales, especialmente en rendimiento (procesos de entrada ≤ 5 segundos), disponibilidad (≥ 99.5% sin interrupciones en horas pico), escalabilidad (crecimiento de 3 a 6 sedes sin rediseño) y restricciones de costo (≤ $2.000 USD/mes), todo esto con un equipo reducido de 4 desarrolladores y un plazo de 8 meses.

Por lo tanto, es necesario seleccionar un estilo arquitectural que permita balancear escalabilidad, mantenibilidad, costo y complejidad operativa, asegurando que el sistema pueda evolucionar sin comprometer la operación crítica del negocio.

---

## Drivers de Decisión

- **DR-01:** Performance de entrada/salida ≤ 5 seg (P95) (Prioridad: Alta)  
- **DR-02:** Disponibilidad ≥ 99.5% sin downtime en horas pico (Prioridad: Alta)  
- **DR-03:** Escalabilidad a 1.200 espacios y 6 sedes sin rediseño (Prioridad: Alta)  
- **DR-04:** Integración con sistema legacy VB6 (SOAP) (Prioridad: Alta)  
- **DR-05:** Seguridad y cumplimiento (PCI-DSS, Ley 1581) (Prioridad: Alta)  
- **DR-06:** Costo ≤ $2.000 USD/mes (Prioridad: Media)  
- **DR-07:** Equipo pequeño (4 desarrolladores, 8 meses) (Prioridad: Media)  

---

## Alternativas Consideradas

### Alternativa 1: Monolito

**Descripción:**
Aplicación única que contiene toda la lógica del sistema (reservas, pagos, facturación, integración) desplegada como un solo artefacto.

**Pros:**
- ✅ Simplicidad de desarrollo e implementación inicial  
- ✅ Menor complejidad operativa  
- ✅ Menor costo de infraestructura  

**Contras:**
- ❌ Alto acoplamiento entre módulos  
- ❌ Difícil escalabilidad por componentes  
- ❌ Complejidad al integrar múltiples sistemas externos  
- ❌ Riesgo alto de afectar todo el sistema ante fallos  

---

### Alternativa 2: Microservicios

**Descripción:**
Arquitectura completamente desacoplada donde cada funcionalidad es un servicio independiente desplegable y escalable de forma autónoma.

**Pros:**
- ✅ Alta escalabilidad independiente por servicio  
- ✅ Desacoplamiento total  
- ✅ Flexibilidad tecnológica  

**Contras:**
- ❌ Alta complejidad operativa (DevOps, monitoreo, redes)  
- ❌ Mayor costo de infraestructura  
- ❌ Sobredimensionado para equipo pequeño  
- ❌ Mayor tiempo de desarrollo  

---

### Alternativa 3: Service-Based Architecture

**Descripción:**
Arquitectura modular basada en servicios funcionales independientes (reservas, pagos, facturación, parqueadero), pero con menor complejidad que microservicios y posible compartición de recursos.

**Pros:**
- ✅ Balance entre desacoplamiento y simplicidad  
- ✅ Escalabilidad parcial por servicio  
- ✅ Facilita integración con sistemas externos  
- ✅ Menor costo y complejidad que microservicios  

**Contras:**
- ❌ Menor flexibilidad que microservicios  
- ❌ Posible acoplamiento si no se diseña adecuadamente  

---

## Decisión

Se adopta una **Service-Based Architecture**, organizando el sistema en servicios funcionales principales:

1. **Parking Service:** Manejo de entradas, salidas y LPR  
2. **Booking Service:** Gestión de reservas  
3. **Payment Service:** Procesamiento de pagos e integración con Wompi y sistema legacy  
4. **Billing Service:** Generación de facturación electrónica (DIAN)  
5. **API Backend:** Orquestación de servicios  
6. **Web App (PWA):** Interfaz para conductores, operadores y administradores  

Los servicios se desplegarán en infraestructura cloud (AWS o GCP), compartiendo una base de datos relacional (PostgreSQL), y comunicándose mediante APIs REST.

---

## Justificación

### Por qué esta opción (y no las otras):

Se eligió Service-Based Architecture porque permite un equilibrio adecuado entre escalabilidad, mantenibilidad y complejidad operativa. A diferencia de un monolito, esta arquitectura permite separar responsabilidades críticas como pagos, facturación e integración con sistemas externos, reduciendo el acoplamiento y facilitando la evolución del sistema.

Comparado con microservicios, Service-Based reduce significativamente la complejidad operativa, lo cual es fundamental dado que el equipo está compuesto por solo 4 desarrolladores (DR-07) y existe una restricción de tiempo de 8 meses. Microservicios implicaría sobrecarga en despliegue, monitoreo y comunicación distribuida que no es viable en este contexto.

Además, esta arquitectura permite manejar integraciones complejas como el sistema legacy en SOAP (DR-04) de manera aislada, reduciendo el impacto en el resto del sistema y facilitando el mantenimiento.

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Permite optimizar servicios críticos como Parking y Payment de forma independiente |
| DR-02 | Aislamiento de fallos evita caída total del sistema |
| DR-03 | Permite escalar servicios según demanda por sede |
| DR-04 | Aísla integración con sistema legacy en un servicio específico |
| DR-05 | Permite aplicar controles de seguridad por servicio |
| DR-06 | Reduce costos comparado con microservicios |
| DR-07 | Mantiene complejidad manejable para el equipo |

---

## Consecuencias

### ✅ Positivas:

1. **Escalabilidad modular:** Permite escalar servicios críticos sin afectar otros componentes  
2. **Mejor mantenibilidad:** Separación clara de responsabilidades  
3. **Integraciones desacopladas:** Manejo aislado de LPR, SOAP, pagos y DIAN  

---

### ⚠️ Negativas (y mitigaciones):

1. **Acoplamiento por base de datos compartida**
   - **Riesgo:** Cambios en el esquema pueden afectar múltiples servicios  
   - **Mitigación:** Uso de esquemas separados y control de cambios  

2. **Mayor complejidad que un monolito**
   - **Riesgo:** Curva de aprendizaje para el equipo  
   - **Mitigación:** Definir estándares claros y limitar número de servicios  

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó Monolito:

El enfoque monolítico fue descartado debido a su falta de escalabilidad y alto acoplamiento. Dado que el sistema debe manejar múltiples integraciones externas y crecer en número de sedes, un monolito dificultaría la evolución y el mantenimiento del sistema.

Además, un fallo en un módulo crítico como pagos o integración con el sistema legacy podría afectar todo el sistema, lo cual es inaceptable considerando los requisitos de disponibilidad (DR-02).

**Cuándo sería mejor:**
- Sistemas pequeños sin integraciones externas  
- Equipos muy pequeños con alcance limitado  

---

### Por qué se descartó Microservicios:

La arquitectura de microservicios fue descartada debido a su alta complejidad operativa y costo. Implementarla requeriría infraestructura avanzada, monitoreo distribuido y un equipo con mayor experiencia en DevOps.

Dado el tamaño del equipo (4 desarrolladores) y las restricciones de tiempo (8 meses), esta opción representa un riesgo alto de no cumplir con los objetivos del proyecto.

**Cuándo sería mejor:**
- Equipos grandes (10+ desarrolladores)  
- Sistemas altamente distribuidos con alta carga  

---

## Validación

- [x] Cumple con DR-01: Permite optimizar servicios críticos para cumplir tiempos de respuesta  
- [x] Cumple con DR-02: Aislamiento de fallos mejora disponibilidad  
- [x] Cumple con DR-03: Arquitectura escalable por servicios  
- [x] Cumple con DR-04: Permite encapsular integración legacy  
- [x] Cumple con DR-05: Seguridad aplicada por servicio  
- [x] Cumple con DR-06: Menor costo que microservicios  
- [x] Cumple con DR-07: Complejidad manejable para el equipo  

---

## Notas Adicionales

Esta arquitectura puede evolucionar hacia microservicios en el futuro si el sistema supera las 6 sedes o aumenta significativamente la carga.

---

## Referencias

- SRS - Sistema ParkEasy  
- Documentación del curso de Arquitectura de Software  

---

**Estado final:** ACEPTADO ✅  

**Firmas del equipo:**

