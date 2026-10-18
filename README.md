# Predicción de Reingresos Hospitalarios (Cardiología)

Pipeline completo de integración de datos clínicos, análisis exploratorio con rigor estadístico y un scorecard de riesgo (RSC) para anticipar qué pacientes tienen mayor probabilidad de reingresar en los 30 días siguientes al alta.

## Contexto de negocio

Un hospital necesita entender qué factores están asociados a los reingresos de pacientes cardiológicos, no solo para reportarlo, sino para poder priorizar el seguimiento de los pacientes con mayor riesgo antes de que se produzca el reingreso.

## Resultados

- **Datos**: 15.038 admisiones de 11.796 pacientes (abril 2022 – marzo 2024); 13.767 episodios reales tras eliminar duplicados.
- **Tasa de reingreso a 30 días**: 4,5 %.
- **Scorecard**: 9 diagnósticos (insuficiencia cardiaca, ICFEr, ICFEn, cardiomiopatía, LRA, ERC, IAMCEST, DM, SCA) más urea, edad y días en cuidados intensivos, con una nota final de 0 a 10.
- **Rendimiento**: AUC de 0,89 en un periodo de prueba (desde julio de 2023) que el scorecard no vio al construirse.
- **Uso práctico**: las altas con nota ≥ 5 son el 27 % del total y concentran el 94 % de los reingresos.

## Qué hace este proyecto

- **Integración de datos**: unión de 5 tablas clínicas (pacientes, admisiones, factores de riesgo, pruebas de laboratorio, diagnósticos) en un único dataset analítico.
- **Calidad del dato**: detección de estancias incoherentes, episodios duplicados, ingresos solapados e incoherencias entre diagnósticos.
- **Análisis exploratorio con rigor estadístico**: pruebas de Chi-cuadrado y t de Welch para validar si las diferencias entre grupos (reingreso vs. no reingreso) son estadísticamente significativas, no solo diferencias visuales en un gráfico.
- **Análisis de insights en SQL**: consultas progresivas (subconsultas, CTEs, window functions, joins) para responder preguntas de negocio como la tasa de reingreso a 30 días, la mortalidad asociada al reingreso o el tiempo medio entre admisiones.
- **Risk Scorecard (RSC)**: puntuación de riesgo por paciente a partir de la penetración del reingreso en cada variable clínica (comorbilidades, días en cuidados intensivos, edad, urea), normalizada a una escala de 0 a 10, validada en un periodo de prueba y escrita en producción como una tabla reutilizable.

## Revisión y correcciones (octubre 2026)

La primera versión del proyecto se revisó a fondo. Las correcciones más importantes:

- **Episodios duplicados**: 1.238 episodios estaban registrados más de una vez y cada copia contaba como un reingreso del mismo día, lo que inflaba la tasa del 14,8 % al 23,1 %.
- **Definición del reingreso**: de "cualquier ingreso posterior" (aunque fuera años después) al indicador estándar de 30 días, excluyendo las altas sin seguimiento completo.
- **Scoring completo**: la función de puntuación no llegaba a sumar la edad ni las estancias; ahora puntúan todas las variables.
- **Escala estable**: la nota de 0 a 10 dependía de los pacientes de cada carga; ahora usa el rango teórico del scorecard, fijo.
- **Validación**: el scorecard se medía con los mismos datos con que se construía; ahora se evalúa en un periodo de prueba.
- **Seguridad**: la contraseña de la base de datos ya no está en el código.

El detalle de todas las correcciones está al principio del notebook.

## Herramientas

- **SQL** (MySQL): modelado relacional, CTEs, window functions
- **Python** (pandas, SQLAlchemy, scipy, scikit-learn): integración de datos, EDA estadístico, scorecard y pipeline de producción

## Estructura del repositorio

- `reingresos_cardiologia_corregido.ipynb`: todo el análisis en Python, explicado paso a paso (carga, calidad, EDA, scorecard, validación y producción)
- `reingresos_cardiologia_corregido.pdf`: el mismo notebook en PDF
- `scorecard_reingresos.json`: tabla de puntos, cortes y rango del scorecard que usa producción
- `01_Analisis_Insights_General.sql`: insights generales (mortalidad, duración de estancia, distribución por género)
- `02_Analisis_Insights_Reingresos.sql`: insights específicos sobre reingresos (tasa a 30 días, mortalidad asociada, tiempo entre admisiones)
- `03_Verificacion_Tablon_Scoring.sql`: consulta de verificación sobre la tabla de scoring final

## Cómo ejecutarlo

1. Crea una base de datos MySQL llamada `dm_cardiologia` con las tablas `pacientes`, `admisiones`, `factores_riesgo`, `pruebas_laboratorio` y `diagnosticos`.
2. Define la variable de entorno `MYSQL_PASSWORD` con tu contraseña de MySQL (si no la defines, el notebook te la pedirá al ejecutarse).
3. Ejecuta el notebook de arriba abajo (Restart & Run All).
4. Consulta los archivos `.sql` directamente en MySQL Workbench para explorar los insights.

## Autor

Javier Sotoca — portfolio completo: https://sites.google.com/view/javiersotoca/home
