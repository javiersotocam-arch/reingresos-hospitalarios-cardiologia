use dm_cardiologia;

#Cantidad de pacientes y admisiones
SELECT 
    COUNT(DISTINCT id_paciente) AS total_pacientes,
    COUNT(DISTINCT id_admision) AS total_admisiones
FROM admisiones;


#Distribución por género
SELECT 
    genero,
    COUNT(*) AS total_pacientes
FROM pacientes
GROUP BY genero;


#Promedio de edad de los pacientes
SELECT 
    AVG(edad) AS edad_promedio
FROM pacientes;


#Duración promedio de la estancia hospitalaria
SELECT 
    AVG(duracion_estancia) AS duracion_promedio_estancia
FROM admisiones;


#Distribución de tipos de admisión
SELECT 
    tipo_admision,
    COUNT(*) AS total_admisiones
FROM admisiones
GROUP BY tipo_admision;


#Porcentaje de Mortalidad
SELECT 
    fallecidos.total_fallecidos,
    pacientes.total_pacientes,
    (fallecidos.total_fallecidos * 100.0 / pacientes.total_pacientes) AS porcentaje_mortalidad
FROM 
    (SELECT COUNT(*) AS total_fallecidos
     FROM admisiones
     WHERE resultado = 'Defuncion') AS fallecidos,
    (SELECT COUNT(DISTINCT id_paciente) AS total_pacientes
     FROM admisiones) AS pacientes;
     
     



