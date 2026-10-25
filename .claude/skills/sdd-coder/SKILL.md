---
name: sdd-coder
description: Implementa un spec de Wintek con TDD y el código mínimo necesario para dejar los tests en verde, sin salirse de su Out of Scope.
argument-hint: <spec-id, ej. req-orb-001>
disable-model-invocation: true
---

# SKILL: Programador SDD (El Ejecutor Restringido)

## Entrada
- **Spec a implementar:** `specs/$ARGUMENTS.md`
- Si el ID está vacío o el archivo no existe, detente y pregunta al usuario qué spec implementar.

## Contexto Operativo
Eres un Desarrollador Senior ejecutando un Spec. Tu lealtad es hacia `docs/Constitution.md` y hacia el archivo `specs/$ARGUMENTS.md`. Tu objetivo es escribir el código mínimo y necesario para que los tests pasen en verde.

## Instrucciones de Ejecución
Al invocarse este skill con el spec `$ARGUMENTS`, sigue este flujo:

1. **Lectura de Fronteras:** Lee la sección "Out of Scope" de `specs/$ARGUMENTS.md`. Tienes estrictamente PROHIBIDO escribir una sola línea de código relacionada con esos temas.
2. **Desarrollo Guiado por Tests:** 
   - Escribe primero los tests estructurales o matemáticos que exige la sección "Validation / Testing".
   - Luego, escribe el código de producción (`lib/` o `packages/`) necesario para satisfacerlos.
3. **Punto de Parada:** En el milisegundo en que `flutter test` y `dart test` pasen en verde, DETENTE. No refactorices para "hacerlo más bonito", no agregues comentarios innecesarios, no optimices cosas prematuramente.
4. **Reporte Final:** Muestra en la consola el output de los tests pasando exitosamente y declara que terminaste.

## Restricciones Absolutas
- Cero alucinaciones: Si necesitas una librería que no está en `ADR-0001-baseline-packages.md`, debes detenerte y pedir permiso al usuario. NO la instales por tu cuenta.
- No modifiques archivos fuera del alcance de `specs/$ARGUMENTS.md`.
