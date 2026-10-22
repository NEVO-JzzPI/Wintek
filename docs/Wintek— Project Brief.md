# Wintek — Project Brief

Oct 19, 2026 · @Nicolas

## Visión

Wintek es una app Android en Flutter que muestra en tiempo real, sobre un globo 3D, dónde están cuatro objetos en órbita terrestre, calculando sus posiciones en el propio dispositivo con mecánica orbital.

- **Propósito:** proyecto personal de portafolio que demuestre dominio de Spec-Driven Development (SDD) y de la matemática orbital detrás de la visualización.
- **Público:** reclutadores, profesores y entusiastas del espacio que revisan el repositorio o instalan el APK.
- **Idioma:** interfaz, código, specs y documentación en inglés.
- **Nombre:** Wintek (Es el *sho'on* más sagrado e importante para los seknam).

## Objetos y fuente de datos

La app rastrea cuatro objetos, cada uno con un tipo de órbita distinto, a partir de elementos orbitales públicos de CelesTrak (sin API key). La NeoWs de NASA quedó descartada porque solo cubre asteroides y cometas.

| Objeto | NORAD ID | Tipo de órbita | Por qué está |
| --- | --- | --- | --- |
| ISS | 25544 | LEO, \~51,6° | Estación espacial de referencia |
| Tiangong (CSS) | 48274 | LEO, \~41,5° | Segunda estación, otra inclinación |
| [FASat-Charlie (SSOT)](https://keeptrack.space/satellite/38011) | 38011 | LEO polar heliosincrónica, \~628 km, 97,8° | Satélite chileno; requisito del autor |
| GOES-East | por confirmar en CelesTrak | Geoestacionaria, \~35.786 km | Parece fijo sobre la Tierra: demuestra la rotación de marcos |

- **Formato:** GP data de CelesTrak en JSON (OMM) o TLE, una consulta por objeto o un grupo filtrado.
- **Refresco:** como máximo una descarga cada pocas horas, según la política de uso de CelesTrak.
- **Offline:** se guardan los últimos elementos descargados; la app sigue calculando sin internet y avisa cuando los datos tienen más de unos días.
- **Fuera de alcance:** asteroides, centros espaciales en tierra y catálogos masivos (por ejemplo, Starlink).

## Pipeline matemático

La posición se calcula localmente en cada frame: los elementos orbitales se descargan pocas veces y el teléfono propaga la órbita hasta el instante actual. Hay dos propagadores: Kepler (implementación propia) y SGP4 (librería).

1. **Elementos orbitales.** Del TLE/OMM se toman la inclinación i, la ascensión del nodo Ω, la excentricidad e, el argumento del perigeo ω, la anomalía media M₀, el movimiento medio n y la época t₀.
2. **Anomalía media en el instante t.**

```latex
M(t) = M_0 + n\,(t - t_0)
```

3. **Ecuación de Kepler**, resuelta por Newton-Raphson para obtener la anomalía excéntrica E.

```latex
M = E - e\sin E \qquad E_{k+1} = E_k - \frac{E_k - e\sin E_k - M}{1 - e\cos E_k}
```

4. **Posición en el plano orbital**, con el semieje mayor a derivado de n (a = (μ / n²)^(1/3), μ = 398600,4418 km³/s²).

```latex
x = a(\cos E - e) \qquad y = a\sqrt{1 - e^2}\,\sin E
```

5. **Rotación al marco inercial** con las tres rotaciones R₃(−Ω) · R₁(−i) · R₃(−ω).
6. **SGP4 (realista).** Reemplaza los pasos 2 a 5: agrega el achatamiento terrestre (J2), el arrastre atmosférico y otras perturbaciones, y entrega la posición en el marco TEME.
7. **Rotación a la Tierra (ECEF)** según el tiempo sidéreo medio de Greenwich (GMST), calculado a partir de la fecha juliana.
8. **Coordenadas geodésicas** (latitud, longitud, altitud) sobre el elipsoide WGS-84.
9. **Proyección a pantalla**: rotación de cámara del globo y proyección a 2D, hecha a mano en `CustomPainter`.

Datos derivados que se muestran: altitud, velocidad (ecuación vis-viva), período orbital (T = 2π / n) e inclinación.

## Alcance

El MVP entrega el globo en tiempo real con los cuatro objetos, su ficha y el modo matemática; la fase 2 suma la predicción de pases y la comparación de modelos.

**MVP (v1)**

- [ ] Globo 3D rotable y con zoom por gestos, centrado en la Tierra
- [ ] Los 4 objetos en movimiento en tiempo real (propagación SGP4)
- [ ] Tocar un objeto abre su ficha: altitud, velocidad, latitud/longitud, período, inclinación y antigüedad de los datos
- [ ] Órbita completa dibujada para el objeto seleccionado
- [ ] Control de tiempo: pausa, ×10, ×100, retroceso y volver a "ahora"
- [ ] Propagador Kepler propio que alimenta el modo matemática: panel con valores intermedios en vivo (M, E, GMST, vector ECEF)
- [ ] Caché local y funcionamiento offline con aviso de datos antiguos

**Fase 2**

- [ ] Vista de comparación Kepler vs SGP4 (desviación en km a lo largo del tiempo)
- [ ] Predicción de pases sobre la ubicación del usuario (azimut, elevación, hora); requiere permiso de ubicación
- [ ] Opcional: port propio de SGP4 validado contra los vectores de prueba de Vallado

## Visualización y estilo

El globo se dibuja a mano con `CustomPainter` y proyección 3D propia, sin motor 3D, con un estilo holográfico tipo radar.

- **Globo:** esfera de meridianos y paralelos, con contornos de continentes como líneas o puntos (a partir de un dataset geográfico simplificado).
- **Escala:** distancias reales. El geoestacionario queda a \~6,6 radios terrestres del centro, así que el zoom debe permitir ver desde órbita baja hasta GEO.
- **Paleta:** fondo casi negro, globo en cian, un color distinto por objeto y su órbita, y acento para el objeto seleccionado.
- **Tipografía:** sans-serif para la interfaz y monoespaciada para el modo matemática y los valores numéricos.
- **Rendimiento:** objetivo de 60 fps en gama media; con 4 objetos el costo está en dibujar el globo, no en el cálculo.
- **Pantallas:** una principal (globo + control de tiempo), una ficha deslizable del objeto, el panel de modo matemática y una pantalla "About / The math".

## Arquitectura

Capas por feature con Riverpod para el estado y un paquete Dart puro, `orbital_core`, que concentra toda la matemática y se testea aislado.

&#91;embedded content: capas de la app · el núcleo orbital no depende de Flutter\]

La UI solo lee posiciones ya calculadas; el núcleo nunca importa Flutter.

- **Estado:** Riverpod. Un `Ticker` avanza un reloj de simulación; ×10, ×100 y retroceso son un multiplicador sobre ese reloj.
- **Estructura:** `domain` / `data` / `presentation` por feature, sin sobreingeniería.
- **Datos:** el repositorio consulta CelesTrak, guarda un JSON local y decide si refrescar según la antigüedad de los elementos.
- **SGP4:** librería de pub.dev envuelta en un adaptador, para poder reemplazarla por un port propio más adelante.

## Calidad y SDD

Cada requisito vive como spec en el repositorio y se verifica con un test; la matemática se valida contra valores publicados.

- **Specs:** carpeta `specs/` con criterios de aceptación verificables; cada test referencia el ID de su requisito.
- **ADRs:** registros cortos de decisiones (Riverpod, SGP4 de librería, globo propio en vez de motor 3D, CelesTrak en vez de NeoWs).
- **Tests unitarios de `orbital_core`:** casos de GMST y Kepler de Vallado y Curtis; verificación de la librería SGP4 con sus vectores oficiales.
- **Widget tests:** al menos la ficha del objeto y el control de tiempo.
- **CI (GitHub Actions):** `flutter analyze`, revisión de formato y tests en cada PR; al crear un tag, compila el APK y lo publica en Releases.
- **Commits convencionales** (`feat:`, `fix:`, `test:`, `docs:`).
- **README en inglés:** GIF de la app, instalación y sección *The math behind it* con las fórmulas.
- **Opcional:** badge de cobertura del núcleo.

## Decisiones

| Tema | Decisión | Alternativa descartada |
| --- | --- | --- |
| Fuente de datos | CelesTrak (GP data) | NASA NeoWs: solo asteroides |
| Objetos | 3 en LEO + 1 GEO, incluido FASat-Charlie | Centros espaciales en tierra, catálogos masivos |
| Propagación | SGP4 (librería) + Kepler propio | Solo Kepler: se desvía en días |
| Tiempo real | Cálculo local por frame, datos refrescados cada pocas horas | Consultar la API por segundo |
| Render | Globo 3D propio en `CustomPainter` | Motor 3D o WebView con Three.js |
| Estado | Riverpod | Bloc |
| Offline | Caché local + aviso de datos antiguos | Requerir conexión |
| Idioma | Inglés | Español |

**Abierto**

- [ ] Confirmar el nombre final (Skytrace, Apsis u OrbitLens) y que esté libre en Play Store y GitHub
- [ ] Confirmar qué satélite es hoy GOES-East y su NORAD ID en CelesTrak
- [ ] Elegir la librería SGP4 de pub.dev y verificar su mantenimiento
- [ ] Elegir el dataset de contornos de continentes y su licencia

**Sources:** [SSOT / FASat-Charlie en KeepTrack](https://keeptrack.space/satellite/38011) · [FASat-Charlie cumple 10 años (Diálogo Américas)](https://dialogo-americas.com/articles/chilean-satellite-celebrates-10-years-in-space-doubles-its-operational-capacity/)
