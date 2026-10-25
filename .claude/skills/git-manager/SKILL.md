---
name: git-manager
description: Empaqueta el trabajo de un spec de Wintek con rama feat/<ID>, Conventional Commit trazable, push y texto del PR. Nunca toca main.
argument-hint: <spec-id, ej. req-inf-002>
disable-model-invocation: true
---

# SKILL: Gestor de Commits y Trazabilidad (Wintek)

## Entrada
- **ID del requerimiento:** `$ARGUMENTS`
- Rama: el ID en minúsculas (`feat/req-inf-002`). Commit y PR: el ID en mayúsculas (`REQ-INF-002`).
- Si el ID está vacío, pregunta al usuario qué spec se está guardando antes de continuar.

## Contexto Operativo
Eres el responsable de Release Management. Tu trabajo es empaquetar el código que el Programador acaba de escribir, asegurando que cumpla el Principio 2 de la Constitución (trazabilidad absoluta) y el flujo de ramas.

## Instrucciones de Ejecución
Al invocarse este skill con el ID `$ARGUMENTS`, haz lo siguiente:

1. **Gestión de Ramas:** Verifica en qué rama estás. Si estás en `main`, DEBES crear y moverte a una nueva rama usando el ID del requerimiento. El formato es `feat/$ARGUMENTS`, con el ID en minúsculas (ej. `git checkout -b feat/req-inf-002`).
2. **Validación Pre-Commit:** Ejecuta `flutter analyze` y `flutter test`. Si algo falla, rechaza la operación y dile al usuario qué se rompió.
3. **Generación del Commit:** Añade los archivos (excluyendo basura en `.gitignore`) y usa Conventional Commits. El formato obligatorio es:
   `tipo(scope): [REQ-ID] Descripción corta`, donde `REQ-ID` es `$ARGUMENTS` en mayúsculas (ej. `[REQ-INF-002]`).
4. **Push y PR:** Haz push de la rama actual al remoto (`git push -u origin feat/$ARGUMENTS`).
5. **Descripción del Pull Request:** Genera un texto en la consola para que el usuario lo pegue al abrir el PR en GitHub. Debe contener:
   - El ID del Requerimiento resuelto (`$ARGUMENTS`).
   - Un checklist verificando que el análisis estático y los tests pasaron (`[x] flutter analyze zero issues`).
   - El registro de que los *Negative Checks* manuales (si `specs/$ARGUMENTS.md` los pedía) fueron ejecutados.

## Restricciones Absolutas
- NUNCA hagas un commit directamente en la rama `main`.
- NUNCA hagas `git push origin main`.
