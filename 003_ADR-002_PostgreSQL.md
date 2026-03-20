# ADR-002: Adoptar PostgreSQL como base de datos principal

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Harold Alejandro Vargas Martínez, Juan Martin Trejos, Wilson David Sanchez Prieto, Juan Sebastian Forero Moreno  
**Relacionado con:** RF-01, RF-02, RF-04, RF-05, RNF-01, RNF-03, RNF-05, DR-01, DR-03, DR-05, DR-06  
**Grupo:** Grupo 4  

---

## Contexto y Problema

El sistema ParkEasy debe almacenar y gestionar información crítica como disponibilidad de espacios, reservas, transacciones de pago, facturación electrónica y datos de usuarios. Esta información requiere consistencia, integridad y capacidad de consulta en tiempo real.

Adicionalmente, el sistema debe cumplir requisitos estrictos de rendimiento (consultas de disponibilidad ≤ 5 s), escalabilidad (crecimiento de 450 a 1.200 espacios sin rediseño) y seguridad (cumplimiento de PCI-DSS y Ley 1581).

El sistema también debe operar bajo restricciones de costo (≤ $2.000 USD/mes en MVP) y ser manejable por un equipo pequeño de 4 desarrolladores, lo cual limita la complejidad tecnológica que puede adoptarse.

Por lo tanto, es necesario seleccionar una tecnología de base de datos que equilibre consistencia, rendimiento, escalabilidad, costo y facilidad de uso.

---

## Drivers de Decisión

- **DR-01:** Performance (≤ 5 seg entrada, ≤ 500 ms consultas) (Prioridad: Alta)
- 
- **DR-03:** Escalabilidad (450 → 1.200 espacios) (Prioridad: Alta)  
- **DR-05:** Seguridad (PCI-DSS, Ley 1581, retención DIAN) (Prioridad: Alta)  
- **DR-06:** Costo ≤ $2.000 USD/mes (Prioridad: Media)  

---

## Alternativas Consideradas

### Alternativa 1: PostgreSQL (Elegida)

**Descripción:**  
Base de datos relacional open source con soporte ACID, ampliamente utilizada en sistemas empresariales.

**Pros:**
- ✅ Alta consistencia (ACID) ideal para transacciones financieras  
- ✅ Excelente soporte para relaciones (reservas, pagos, usuarios)  
- ✅ Open source (sin costos de licencia)  
- ✅ Buen rendimiento en consultas complejas  
- ✅ Soporte para escalabilidad vertical y horizontal (replicas)  

**Contras:**
- ❌ Escalabilidad horizontal más compleja que NoSQL  
- ❌ Requiere diseño adecuado de índices y esquema  

---

### Alternativa 2: MongoDB

**Descripción:**  
Base de datos NoSQL orientada a documentos (JSON).

**Pros:**
- ✅ Alta flexibilidad en el esquema  
- ✅ Escalabilidad horizontal sencilla  
- ✅ Buen rendimiento en lecturas  

**Contras:**
- ❌ Menor consistencia (eventual consistency)  
- ❌ No ideal para transacciones complejas (pagos/facturación)  
- ❌ Relaciones complejas más difíciles de manejar  
- ❌ Riesgo en cumplimiento de integridad de datos  

---

### Alternativa 3: DynamoDB (AWS)

**Descripción:**  
Base de datos NoSQL totalmente gestionada en la nube (AWS).

**Pros:**
- ✅ Alta escalabilidad automática  
- ✅ Alta disponibilidad  
- ✅ Bajo mantenimiento operativo  

**Contras:**
- ❌ Costo variable difícil de controlar  
- ❌ Dependencia fuerte del proveedor (vendor lock-in)  
- ❌ No ideal para relaciones complejas  
- ❌ Curva de aprendizaje para modelado  

---

## Decisión

Se adopta **PostgreSQL** como base de datos principal del sistema ParkEasy.

La implementación será:

1. Base de datos relacional PostgreSQL compartida entre servicios  
2. Uso de esquemas separados por servicio (Booking, Payment, Parking, Billing)  
3. Índices optimizados para consultas de disponibilidad y transacciones  
4. Uso de replicación para alta disponibilidad  
5. Backup automático y políticas de retención de datos  

---

## Justificación

### Por qué esta opción (y no las otras):

Se eligió PostgreSQL porque garantiza consistencia fuerte (ACID), lo cual es crítico para el manejo de pagos y facturación electrónica (DR-05). En este sistema, no se puede permitir inconsistencia en datos financieros.

MongoDB fue descartado porque su modelo eventual consistency introduce riesgos en operaciones críticas como pagos, donde se requiere precisión absoluta.

DynamoDB también fue descartado debido a su costo variable y dependencia de proveedor, lo cual entra en conflicto con la restricción de presupuesto (DR-06) y el control de costos.

Además, PostgreSQL permite modelar fácilmente relaciones complejas entre entidades (usuarios, reservas, pagos, facturas), lo cual es fundamental en el dominio del problema.

Finalmente, PostgreSQL es una tecnología ampliamente conocida, lo que reduce la curva de aprendizaje para el equipo (4 desarrolladores) y facilita el desarrollo dentro del plazo establecido.

---

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Consultas optimizadas con índices ≤ 500 ms |
| DR-03 | Escalable mediante replicación y tuning |
| DR-05 | Soporte ACID garantiza integridad de datos |
| DR-06 | Open source reduce costos de licencia |

---

## Consecuencias

### ✅ Positivas:

1. **Consistencia de datos:** Garantiza integridad en pagos y facturación  
2. **Facilidad de modelado:** Manejo natural de relaciones complejas  
3. **Bajo costo:** Sin licencias, compatible con presupuesto  

---

### ⚠️ Negativas (y mitigaciones):

1. **Escalabilidad horizontal limitada**
   - **Riesgo:** Puede ser más difícil escalar que NoSQL  
   - **Mitigación:** Uso de replicas, particionamiento y optimización  

2. **Posible acoplamiento entre servicios**
   - **Riesgo:** Base de datos compartida puede generar dependencias  
   - **Mitigación:** Uso de esquemas separados y buenas prácticas  

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó MongoDB:

MongoDB fue descartado porque no garantiza consistencia fuerte por defecto, lo cual representa un riesgo en operaciones financieras.

Además, las relaciones entre entidades son complejas (reservas, pagos, facturación), lo que hace que el modelo documental sea menos adecuado.

**Cuándo sería mejor:**
- Sistemas con datos no estructurados  
- Aplicaciones con alta flexibilidad de esquema  

---

### Por qué se descartó DynamoDB:

DynamoDB fue descartado debido a su costo variable y dependencia del proveedor, lo cual dificulta cumplir el presupuesto.

También introduce complejidad en el modelado de relaciones y requiere experiencia adicional del equipo.

**Cuándo sería mejor:**
- Sistemas con alta escala global  
- Equipos con experiencia en AWS  

---

## Validación

- [x] Cumple con DR-01: Consultas eficientes con índices  
- [x] Cumple con DR-03: Escalabilidad mediante replicas  
- [x] Cumple con DR-05: Integridad de datos (ACID)  
- [x] Cumple con DR-06: Bajo costo operativo  

---

## Notas Adicionales

En el futuro, se puede complementar PostgreSQL con soluciones de cache (ej. Redis) si se requiere mejorar el rendimiento en consultas de alta frecuencia.

---

## Referencias

- SRS - Sistema ParkEasy  
- Documentación PostgreSQL  

---

**Estado final:** ACEPTADO ✅  

**Firmas del equipo:**
- Harold Alejandro Vargas Martínez: Harold Vargas - Fecha: 19_/03/2026
- Juan Martin Trejos: Juan Martin Trejos - Fecha: 19/03/2026  
- Wilson David Sanchez Prieto: Wilson Sanchez - Fecha: 19/03/2026 
- Juan Sebastian Forero Moreno: Juan Sebastian Forero - Fecha: 19/03/2026
