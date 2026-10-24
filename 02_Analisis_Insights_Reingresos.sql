-- =====================================================================
-- Reingresos hospitalarios en cardiología: análisis de la situación en SQL
-- Base de datos: dm_cardiologia (MySQL 8)
--
-- Revisión (octubre 2026). Las mismas correcciones que en el notebook:
--   1. 1.238 episodios están registrados más de una vez (mismo paciente,
--      misma fecha de ingreso y de alta). Todas las consultas trabajan sobre
--      la vista admisiones_limpias, que deja una sola copia de cada episodio.
--   2. Reingreso = nuevo ingreso en los 30 días siguientes al alta (indicador
--      estándar), no "cualquier ingreso posterior", aunque fuera años después.
--   3. Las altas de los últimos 30 días de datos no tienen seguimiento completo
--      (no sabemos si reingresan) y se excluyen al calcular la tasa.
--   4. Los meses se agrupan por año y mes: los datos cubren dos años
--      (abril 2022 - marzo 2024) y agrupar solo por mes juntaba los dos.
-- =====================================================================

USE dm_cardiologia;


-- ---------------------------------------------------------------------
-- 0. Vista de admisiones sin duplicados y con el siguiente ingreso
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW admisiones_limpias AS
WITH numeradas AS (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY id_paciente, fecha_admision, fecha_alta
                              ORDER BY id_admision) AS copia
    FROM admisiones a
)
SELECT id_admision, id_paciente, fecha_admision, fecha_alta, tipo_admision,
       duracion_estancia, duracion_estancia_ci, resultado,
       -- días desde el alta anterior del mismo paciente (NULL si es su primer ingreso)
       DATEDIFF(fecha_admision,
                LAG(fecha_alta) OVER (PARTITION BY id_paciente ORDER BY fecha_admision, id_admision))
           AS dias_desde_alta_anterior,
       -- días hasta el siguiente ingreso del mismo paciente (NULL si no vuelve)
       DATEDIFF(LEAD(fecha_admision) OVER (PARTITION BY id_paciente ORDER BY fecha_admision, id_admision),
                fecha_alta)
           AS dias_hasta_siguiente_ingreso
FROM numeradas
WHERE copia = 1;

-- Comprobación: 15.038 registros originales, 13.767 episodios reales
SELECT (SELECT COUNT(*) FROM admisiones)         AS registros_originales,
       (SELECT COUNT(*) FROM admisiones_limpias) AS episodios_reales;


-- ¿cuántas admisiones y pacientes únicos hay de media por mes? | fácil | subconsultas
SELECT ROUND(AVG(admisiones), 1) AS media_admisiones_mes,
       ROUND(AVG(pacientes), 1)  AS media_pacientes_mes
FROM (
    SELECT DATE_FORMAT(fecha_admision, '%Y-%m') AS mes,
           COUNT(*)                    AS admisiones,
           COUNT(DISTINCT id_paciente) AS pacientes
    FROM admisiones_limpias
    GROUP BY mes
) AS por_mes;


-- ¿qué porcentaje de pacientes tiene más de un ingreso? | media | subconsultas
SELECT ROUND(100 * AVG(ingresos > 1), 2) AS pct_pacientes_mas_de_un_ingreso
FROM (
    SELECT id_paciente, COUNT(*) AS ingresos
    FROM admisiones_limpias
    GROUP BY id_paciente
) AS por_paciente;


-- ¿cuántas veces ingresan los pacientes? | media | subconsultas
SELECT ingresos, COUNT(*) AS pacientes
FROM (
    SELECT id_paciente, COUNT(*) AS ingresos
    FROM admisiones_limpias
    GROUP BY id_paciente
) AS por_paciente
GROUP BY ingresos
ORDER BY ingresos;


-- ¿cuántos ingresos tiene de media cada paciente? | fácil
SELECT ROUND(COUNT(*) / COUNT(DISTINCT id_paciente), 3) AS ingresos_por_paciente
FROM admisiones_limpias;


-- ¿cuánto tiempo pasa de media entre un alta y el siguiente ingreso? | avanzada | window functions (en la vista)
-- Se mide desde el alta, no desde el ingreso anterior, y sin ingresos solapados
SELECT ROUND(AVG(dias_hasta_siguiente_ingreso), 1)  AS media_dias,
       COUNT(*)                                     AS altas_con_nuevo_ingreso
FROM admisiones_limpias
WHERE dias_hasta_siguiente_ingreso >= 0;


-- ¿qué porcentaje de altas termina en un reingreso en los 30 días siguientes? | pro | ctes
-- Se excluyen las defunciones (no pueden reingresar) y las altas sin 30 días de seguimiento
WITH altas_evaluables AS (
    SELECT id_admision,
           dias_hasta_siguiente_ingreso BETWEEN 0 AND 30 AS reingresa_30d
    FROM admisiones_limpias
    WHERE resultado <> 'Defuncion'
      AND fecha_alta <= (SELECT MAX(fecha_admision) FROM admisiones_limpias) - INTERVAL 30 DAY
)
SELECT COUNT(*)                                          AS altas_evaluables,
       SUM(COALESCE(reingresa_30d, 0))                   AS altas_con_reingreso_30d,
       ROUND(100 * AVG(COALESCE(reingresa_30d, 0)), 2)   AS pct_reingreso_30d
FROM altas_evaluables;


-- ¿cómo cambia la tasa de reingreso a 30 días según la definición? | pro | ctes
-- Muestra por qué la tasa original estaba inflada
WITH originales AS (
    -- definición original: hay otro registro posterior del mismo paciente,
    -- aunque sea una copia duplicada del mismo episodio
    SELECT a.resultado,
           LEAD(a.id_paciente) OVER (PARTITION BY a.id_paciente ORDER BY a.fecha_admision, a.id_admision)
               IS NOT NULL AS tiene_registro_posterior
    FROM admisiones a
)
SELECT 'Cualquier ingreso posterior, con duplicados' AS definicion,
       ROUND(100 * AVG(tiene_registro_posterior), 2) AS pct
FROM originales WHERE resultado <> 'Defuncion'
UNION ALL
SELECT 'Cualquier ingreso posterior, sin duplicados',
       ROUND(100 * AVG(COALESCE(dias_hasta_siguiente_ingreso >= 0, 0)), 2)
FROM admisiones_limpias WHERE resultado <> 'Defuncion'
UNION ALL
SELECT 'Reingreso a 30 días, sin duplicados y con seguimiento completo',
       ROUND(100 * AVG(COALESCE(dias_hasta_siguiente_ingreso BETWEEN 0 AND 30, 0)), 2)
FROM admisiones_limpias
WHERE resultado <> 'Defuncion'
  AND fecha_alta <= (SELECT MAX(fecha_admision) FROM admisiones_limpias) - INTERVAL 30 DAY;


-- ¿cuántos días de hospitalización suponen los reingresos a 30 días y cuánto cuestan? | media
-- Solo cuentan las estancias de los reingresos, no los primeros ingresos de esos pacientes.
-- Coste: estimación de 700 € por día de hospitalización.
SELECT CASE WHEN fecha_admision < '2023-04-01' THEN 'abr 2022 - mar 2023' ELSE 'abr 2023 - mar 2024' END AS periodo,
       COUNT(*)                          AS reingresos_30d,
       SUM(duracion_estancia)            AS dias_hospitalizacion,
       SUM(duracion_estancia) * 700      AS coste_estimado_eur
FROM admisiones_limpias
WHERE dias_desde_alta_anterior BETWEEN 0 AND 30
GROUP BY periodo WITH ROLLUP;


-- ¿las altas que acaban en reingreso tuvieron estancias más largas? | avanzada | ctes
-- Se compara por alta (cada ingreso), no por paciente
WITH altas_evaluables AS (
    SELECT duracion_estancia,
           CASE WHEN dias_hasta_siguiente_ingreso BETWEEN 0 AND 30
                THEN 'reingresa en 30 días' ELSE 'no reingresa' END AS grupo
    FROM admisiones_limpias
    WHERE resultado <> 'Defuncion'
      AND fecha_alta <= (SELECT MAX(fecha_admision) FROM admisiones_limpias) - INTERVAL 30 DAY
)
SELECT grupo, COUNT(*) AS altas, ROUND(AVG(duracion_estancia), 2) AS estancia_media_dias
FROM altas_evaluables
GROUP BY grupo;


-- ¿qué porcentaje de pacientes con algún reingreso a 30 días acaba falleciendo? | pro | ctes
WITH con_reingreso AS (
    SELECT DISTINCT id_paciente
    FROM admisiones_limpias
    WHERE dias_desde_alta_anterior BETWEEN 0 AND 30
),
fallecidos AS (
    SELECT DISTINCT id_paciente
    FROM admisiones_limpias
    WHERE resultado = 'Defuncion'
)
SELECT COUNT(*)                                       AS pacientes_con_reingreso_30d,
       COUNT(f.id_paciente)                           AS de_ellos_fallecidos,
       ROUND(100 * COUNT(f.id_paciente) / COUNT(*), 2) AS pct_fallecidos
FROM con_reingreso c
LEFT JOIN fallecidos f ON f.id_paciente = c.id_paciente;


-- ¿cuál es la edad media de los pacientes que fallecen? | fácil | joins
SELECT ROUND(AVG(p.edad), 1) AS edad_media_fallecidos
FROM admisiones_limpias a
JOIN pacientes p ON p.id_admision = a.id_admision
WHERE a.resultado = 'Defuncion';


-- ¿fallecen proporcionalmente igual hombres y mujeres? | media | joins
SELECT p.genero,
       COUNT(*)                                          AS ingresos,
       ROUND(100 * AVG(a.resultado = 'Defuncion'), 2)    AS pct_ingresos_con_defuncion
FROM admisiones_limpias a
JOIN pacientes p ON p.id_admision = a.id_admision
GROUP BY p.genero;
