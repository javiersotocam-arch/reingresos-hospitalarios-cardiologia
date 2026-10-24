-- =====================================================================
-- Reingresos hospitalarios en cardiología: indicadores generales
-- Revisión (octubre 2026): se usa la vista admisiones_limpias (creada en
-- 02_Analisis_Insights_Reingresos.sql), sin los 1.238 episodios duplicados.
-- Ejecuta primero el bloque 0 de ese archivo.
-- =====================================================================

USE dm_cardiologia;


-- Pacientes, registros y episodios reales
SELECT COUNT(DISTINCT id_paciente)                  AS pacientes,
       (SELECT COUNT(*) FROM admisiones)            AS registros_originales,
       COUNT(*)                                     AS episodios_reales
FROM admisiones_limpias;


-- Distribución por género (pacientes distintos, con el género de su primer ingreso)
SELECT genero, COUNT(*) AS pacientes
FROM (
    SELECT p.id_paciente, p.genero,
           ROW_NUMBER() OVER (PARTITION BY p.id_paciente ORDER BY a.fecha_admision) AS n
    FROM admisiones_limpias a
    JOIN pacientes p ON p.id_admision = a.id_admision
) t
WHERE n = 1
GROUP BY genero;


-- Edad media al ingreso
SELECT ROUND(AVG(p.edad), 1) AS edad_media
FROM admisiones_limpias a
JOIN pacientes p ON p.id_admision = a.id_admision;


-- Duración media de la estancia (días)
SELECT ROUND(AVG(duracion_estancia), 2) AS estancia_media
FROM admisiones_limpias;


-- Distribución por tipo de admisión
SELECT tipo_admision, COUNT(*) AS ingresos,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM admisiones_limpias
GROUP BY tipo_admision;


-- Mortalidad: por ingreso y por paciente (son indicadores distintos)
SELECT ROUND(100 * AVG(resultado = 'Defuncion'), 2)                     AS pct_ingresos_con_defuncion,
       ROUND(100 * COUNT(DISTINCT CASE WHEN resultado = 'Defuncion' THEN id_paciente END)
                 / COUNT(DISTINCT id_paciente), 2)                       AS pct_pacientes_fallecidos
FROM admisiones_limpias;
