---
name: spec-creator
description: Genera el spec atómico specs/<ID>.md de una fila del roadmap de Wintek (SDD). Úsalo para crear el ticket de trabajo de un requerimiento.
argument-hint: <spec-id, ej. req-orb-001>
disable-model-invocation: true
---

# SKILL: Generador de Especificaciones SDD (Wintek)

## Entrada
- **ID de la tarea:** `$ARGUMENTS`
- Si el ID está vacío, pregunta al usuario qué tarea del roadmap quiere especificar antes de continuar.

## Contexto Operativo
Eres un Arquitecto de Software generando un ticket de trabajo (Spec) atómico.
Antes de hacer nada, DEBES leer silenciosamente:
1. `docs/Wintek— Project Brief.md`
2. `docs/Constitution.md`
3. `docs/adr/ADR-0001-baseline-packages.md`
4. `docs/roadmap.md`

## Instrucciones de Ejecución
Al invocarse este skill con el ID `$ARGUMENTS`, ejecuta esta secuencia estricta:

1. **Análisis de Dependencias:** Busca la fila `$ARGUMENTS` en `docs/roadmap.md` y confirma qué tarea se solicitó y cuáles son sus dependencias previas. Si el ID no existe en el roadmap, detente y avísale al usuario.
2. **Clarificación (QA Interno):** Antes de escribir el archivo final, hazte estas preguntas mentalmente:
   - ¿Esta tarea viola algún principio de la Constitución?
   - ¿Requiere dependencias no listadas en el ADR-0001?
   - ¿Estoy intentando programar lógica matemática en un paso donde no corresponde?
3. **Consultas** Realiza preguntas al usuario si necesitas aclarar el alcance, los criterios de aceptación o los casos de prueba. No continúes hasta que todas las dudas estén resueltas.
4. **Generación del Archivo:** Redacta el archivo en `specs/$ARGUMENTS.md` íntegramente en INGLÉS, usando esta estructura:
   - **Context & Objective:** Dependencias y valor de la tarea.
   - **Functional Requirements (REQ-x):** Criterios de aceptación verificables.
   - **Mathematical Validation / Testing:** Comandos exactos de consola para probarlo.
   - **Edge Cases & Errors:** Manejo de fallos.
   - **Out of Scope:** Qué NO se debe programar.

## Restricciones Absolutas
- Detente, NO crees el archivo hasta que todas las preguntas de clarificación estén respondidas y el usuario lo autorice.
- DEFINE EL QUÉ Y EL POR QUÉ. Prohibido escribir código fuente, clases o variables en el spec.
- No uses parsers YAML externos en los tests.
- Asegura que cualquier prueba estructural no contamine paquetes de Dart puro con `dart:io`.
