# Predicción de Reingresos Hospitalarios (Cardiología)

Pipeline completo de integración de datos clínicos, análisis exploratorio con rigor estadístico, y un scorecard de riesgo (RSC) para anticipar qué pacientes tienen mayor probabilidad de reingresar.

## Contexto de negocio

Un hospital necesita entender qué factores están asociados a los reingresos de pacientes cardiológicos, no solo para reportarlo, sino para poder priorizar el seguimiento de los pacientes con mayor riesgo antes de que se produzca el reingreso.

## Qué hace este proyecto

- **Integración de datos**: unión de 5 tablas clínicas (pacientes, admisiones, factores de riesgo, pruebas de laboratorio, diagnósticos) en un único dataset analítico.
- **Análisis exploratorio con rigor estadístico**: uso de pruebas de Chi-cuadrado y T-Student para validar si las diferencias observadas entre grupos (reingreso vs. no reingreso) son estadísticamente significativas, no solo diferencias visuales en un gráfico.
- **Análisis de insights en SQL**: consultas progresivas (subconsultas, CTEs, window functions, joins) para responder preguntas de negocio como la tasa de reingreso a 30 días, la mortalidad asociada al reingreso, o el tiempo medio entre admisiones.
- **Risk Scorecard (RSC)**: sistema de puntuación de riesgo por paciente, construido a partir de reglas de negocio sobre variables clínicas (comorbilidades, duración de estancia, edad), normalizado a una escala de 0 a 10 y escrito en producción como una tabla reutilizable.

## Herramientas

- **SQL** (MySQL) — modelado relacional, CTEs, window functions
- **Python** (pandas, SQLAlchemy, scipy) — integración de datos, EDA estadístico, pipeline de scoring

## Estructura del repositorio

- `01_Carga_e_integracion_de_datos.ipynb` — conexión a MySQL e integración de las 5 tablas
- `02_Calidad_y_EDA.ipynb` — calidad de datos y análisis exploratorio con pruebas estadísticas
- `03_Minicubo_y_RSC.ipynb` — construcción del cubo analítico y del Risk Scorecard
- `Produccion.ipynb` — pipeline consolidado que calcula el scoring y lo escribe en la base de datos
- `01_Analisis_Insights_General.sql` — insights generales (mortalidad, duración de estancia, distribución por género)
- `02_Analisis_Insights_Reingresos.sql` — insights específicos sobre reingresos (tasa a 30 días, mortalidad asociada, tiempo entre admisiones)
- `03_Verificacion_Tablon_Scoring.sql` — consulta de verificación sobre la tabla de scoring final

## Cómo ejecutarlo

1. Crea una base de datos MySQL llamada `dm_cardiologia` con las tablas `pacientes`, `admisiones`, `factores_riesgo`, `pruebas_laboratorio` y `diagnosticos`.
2. Define la variable de entorno `MYSQL_PASSWORD` con tu contraseña de MySQL antes de ejecutar los notebooks.
3. Ejecuta los notebooks en orden: `01` → `02` → `03` → `Produccion`.
4. Consulta los archivos `.sql` directamente en MySQL Workbench para explorar los insights.

## Autor

Javier Sotoca — portfolio completo: https://sites.google.com/view/javiersotoca/home
