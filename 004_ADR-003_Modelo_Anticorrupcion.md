# ADR-003: Adoptar Anti-Corruption Layer para integración con sistema legacy

**Estado:** Aceptado  
**Fecha:** 19/03/2026  
**Decisores:** Harold Alejandro Vargas Martínez, Juan Martin Trejos, Wilson David Sanchez Prieto, Juan Sebastian Forero Moreno  
**Relacionado con:** RF-04, RF-05, RNF-01, RNF-02, DR-01, DR-02, DR-04, DR-07  
**Grupo:** Grupo 4  

---

## Contexto y Problema

El sistema ParkEasy debe integrarse obligatoriamente con un sistema de cobro legacy desarrollado en VB6, el cual expone una API SOAP poco documentada y no puede ser reemplazado en el MVP debido a restricciones de negocio. Este sistema es crítico ya que registra las transacciones financieras oficiales del parqueadero.

Esta integración presenta varios retos: incompatibilidad tecnológica (REST vs SOAP), documentación limitada, posibles fallos impredecibles y alto riesgo de acoplamiento si los servicios modernos interactúan directamente con el sistema legacy. Además, el sistema debe cumplir requisitos estrictos de rendimiento (≤ 5 segundos en entrada) y disponibilidad (≥ 99.5%), lo que implica que fallas en el sistema legacy no pueden afectar la operación completa.

Dado que se adoptó una arquitectura Service-Based (ADR-001), es necesario definir una estrategia de integración que permita desacoplar el sistema moderno del legacy, manejar la complejidad técnica de forma controlada y garantizar resiliencia, sin sobrecargar al equipo de desarrollo que es reducido (4 personas).

---

## Drivers de Decisión

- **DR-01:** Performance de entrada ≤ 5 segundos P95 (Prioridad: Alta)  
- **DR-02:** Disponibilidad ≥ 99.5% sin interrupciones (Prioridad: Alta)  
- **DR-04:** Integración con sistema legacy VB6 (SOAP) (Prioridad: Alta)  
- **DR-07:** Usabilidad y simplicidad para equipo pequeño (Prioridad: Media)  

---

## Alternativas Consideradas

### Alternativa 1: Integración directa con SOAP

**Descripción:**  
Cada servicio (Payment, Billing, etc.) consume directamente la API SOAP del sistema legacy.

**Pros:**
- ✅ Implementación rápida inicial  
- ✅ Menor número de componentes  
- ✅ Menor esfuerzo de diseño  

**Contras:**
- ❌ Alto acoplamiento con el sistema legacy  
- ❌ Duplicación de lógica de integración en múltiples servicios  
- ❌ Mayor dificultad de mantenimiento  
- ❌ Propagación de fallos del legacy a todo el sistema  

---

### Alternativa 2: API Gateway como integrador

**Descripción:**  
El API Gateway se encarga de manejar la comunicación con el sistema legacy además del routing general.

**Pros:**
- ✅ Centraliza la integración  
- ✅ Reduce duplicación de lógica  
- ✅ Facilita control de acceso  

**Contras:**
- ❌ Sobrecarga de responsabilidades en el gateway  
- ❌ Posible cuello de botella  
- ❌ Mezcla responsabilidades de orquestación e integración  
- ❌ Mayor complejidad operativa  

---

### Alternativa 3: Anti-Corruption Layer (ACL) (Elegida)

**Descripción:**  
Se crea un servicio intermedio que encapsula toda la lógica de integración con el sistema legacy, traduciendo entre REST y SOAP.

**Pros:**
- ✅ Desacoplamiento total del sistema legacy  
- ✅ Centralización de la lógica de integración  
- ✅ Aislamiento de errores del sistema legacy  
- ✅ Facilita reemplazo futuro del sistema legacy  

**Contras:**
- ❌ Introduce una capa adicional  
- ❌ Incrementa ligeramente la latencia  
- ❌ Requiere mayor esfuerzo inicial  

---

## Decisión

Se adopta un **Anti-Corruption Layer (ACL)** implementado como un **Integration Service** dentro de la arquitectura Service-Based.

La solución se implementará así:

1. Se crea un servicio dedicado (**Integration Service**)  
2. Este servicio será el único que interactúe con el sistema legacy (SOAP)  
3. Internamente:
   - Consume SOAP  
   - Transforma datos a JSON/REST  
4. Los demás servicios (Payment, Billing) consumen este servicio vía REST  
5. Se implementan patrones de resiliencia:
   - Circuit Breaker  
   - Retries  
   - Timeouts  

---

## Justificación

### Por qué esta opción (y no las otras):

Se eligió Anti-Corruption Layer porque permite aislar completamente el sistema legacy, lo cual es fundamental dado que su API es poco confiable y está mal documentada (DR-04). Esto evita que la complejidad del legacy se propague a todos los servicios.

La integración directa fue descartada porque introduce un alto acoplamiento y duplicación de lógica, lo cual afecta negativamente la mantenibilidad y aumenta el riesgo de fallos en cascada, comprometiendo la disponibilidad del sistema (DR-02).

El uso de API Gateway como integrador también fue descartado porque mezcla responsabilidades. El gateway debería encargarse de routing y seguridad, no de transformación de protocolos complejos, lo que puede convertirlo en un punto crítico de falla.

Aunque el ACL introduce una capa adicional, este trade-off es aceptable ya que mejora la resiliencia, permite manejar errores del sistema legacy sin afectar la operación y facilita su futura sustitución, manteniendo la complejidad controlada para el equipo (DR-07).

---

### Cómo cumple con los drivers:

| Driver | Cómo esta decisión lo cumple |
|--------|------------------------------|
| DR-01 | Permite controlar latencia mediante retries y optimización de llamadas |
| DR-02 | Aísla fallos del sistema legacy con circuit breaker |
| DR-04 | Encapsula completamente la integración SOAP |
| DR-07 | Centraliza la complejidad en un solo servicio manejable |

---

## Consecuencias

### ✅ Positivas:

1. **Desacoplamiento del sistema legacy:** El sistema moderno no depende directamente de SOAP  
2. **Mayor resiliencia:** Fallos del sistema legacy no afectan toda la operación  
3. **Facilidad de evolución:** Permite reemplazar el sistema legacy en el futuro  

---

### ⚠️ Negativas (y mitigaciones):

1. **Incremento en latencia**
   - **Riesgo:** Puede afectar tiempos de respuesta (RNF-01)  
   - **Mitigación:** Uso de cache, optimización de llamadas y timeouts  

2. **Mayor complejidad inicial**
   - **Riesgo:** Más esfuerzo de desarrollo  
   - **Mitigación:** Mantener el servicio simple y bien documentado  

---

## Alternativas Descartadas (Detalle)

### Por qué se descartó Integración directa con SOAP:

Esta alternativa fue descartada porque genera un alto acoplamiento entre los servicios y el sistema legacy. Cada servicio tendría que manejar SOAP directamente, aumentando la complejidad y dificultando el mantenimiento.

Además, cualquier fallo del sistema legacy impactaría múltiples servicios, lo cual compromete la disponibilidad (DR-02), especialmente en horas pico donde no se permite downtime.

**Cuándo sería mejor:**
- Sistemas pequeños  
- Integraciones simples y estables  

---

### Por qué se descartó API Gateway como integrador:

Se descartó porque el API Gateway no debe encargarse de lógica de integración compleja. Agregar esta responsabilidad puede convertirlo en un cuello de botella y afectar el rendimiento global del sistema.

Además, aumenta la complejidad operativa y dificulta el mantenimiento.

**Cuándo sería mejor:**
- Transformaciones simples  
- Sistemas con baja carga  

---

## Validación

- [x] Cumple con DR-01: Control de latencia mediante timeouts y retries  
- [x] Cumple con DR-02: Aislamiento de fallos del legacy  
- [x] Cumple con DR-04: Encapsulación completa del sistema SOAP  
- [x] Cumple con DR-07: Complejidad manejable para el equipo  

---

## Notas Adicionales

Esta decisión permite migrar progresivamente el sistema legacy en el futuro sin afectar el resto de la arquitectura.

---

## Referencias

- SRS - Sistema ParkEasy  
- Enunciado del Taller ParkEasy  

---

**Estado final:** ACEPTADO ✅  

**Firmas del equipo:**
- Harold Alejandro Vargas Martínez: __________ - Fecha: ___/___/___  
- Juan Martin Trejos: __________ - Fecha: ___/___/___  
- Wilson David Sanchez Prieto: __________ - Fecha: ___/___/___  
- Juan Sebastian Forero Moreno: __________ - Fecha: ___/___/___  