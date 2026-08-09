use dm_cardiologia;


# ¿cuántas admisiones hay de media por mes? | fácil | subconsultas

select
	avg(total_admisiones) as media_total_admisiones
from
	(
    select
		month(fecha_admision) as mes,
        count(*) as total_admisiones
        from admisiones
        group by mes    
    )as admisiones_por_mes;
    

# ¿y cuántos pacientes únicos de media por mes? | fácil | subconsultas

select
	avg(total_pacientes) as media_total_pacientes
from
	(
    select
		month(fecha_admision) as mes,
        count(distinct id_paciente) as total_pacientes
        from admisiones
        group by mes    
    )as pacientes_por_mes;


# ¿qué porcentaje de pacientes tienen más de un ingreso? | media | subconsultas
select
	(sum(case when total_reingresos > 1 then 1 else 0 end) * 100.0 / count(distinct id_paciente)) as porcentaje_reingresos
from (
	select id_paciente, count(*) as total_reingresos
	from admisiones
	group by id_paciente) as pacientes;



# ¿cual es el tiempo promedio entre una admisión y el siguiente reingreso? | avanzada | subconsultas | window functions
SELECT
	avg(dias_reingreso) as tiempo_promedio_global_reingreso
from(
	select
		id_paciente,
        datediff(lead(fecha_admision) over (partition by id_paciente order by fecha_admision), fecha_admision) as dias_reingreso
	from admisiones) as diferencias
where dias_reingreso is not null;


# ¿cuántas veces ingresan los pacientes? (cuántos pacientes una vez, cuántos 2 veces, etc) | media | subconsultas
select
	total_ingresos, count(*) as num_pacientes
from (
	select id_paciente, count(*) as total_ingresos
    from admisiones
    group by id_paciente) as ingresos_por_paciente
group by total_ingresos
order by total_ingresos;



# ¿cual es la media de ingresos de todos los pacientes? | avanzada | ctes

with ingresos_por_paciente as (
	select id_paciente, count(*) as total_ingresos
    from admisiones
    group by id_paciente),
    distribucion_ingresos as (
    select total_ingresos, count(*) as num_pacientes
    from ingresos_por_paciente
    group by total_ingresos)
select 
sum(total_ingresos * num_pacientes) * 1.0 / sum(num_pacientes) as media_ponderada
from distribucion_ingresos;


# ¿cual es la media de reingresos de los pacientes que han tenido reingresos? | media | subconsultas
select
	avg(total_reingresos) as media_reingresos
from (
	select
		id_paciente,
        count(*) - 1 as total_reingresos
	from admisiones
    group by id_paciente
    having count(*) > 1)
as reingresos_por_paciente;




# ¿cuántos días de hospitalización supusieron los reingresos en el último año que tengamos completo? | media | subconsultas
select 
	sum(duracion_estancia) as total_dias_reingresos
    from admisiones
where id_paciente in(
	select id_paciente
    from admisiones	
    group by id_paciente
    having count(*) > 1)
and year(fecha_admision) = 2023;





# ¿cual es la duración promedio de la estancia de los pacientes que reingresan frente a los que no reingresan? | avanzada | ctes
with tipo_ingreso as(
	select
		id_paciente,
        duracion_estancia,
		case when id_paciente in(
				select id_paciente
                from admisiones
                group by id_paciente
                having count(*) > 1)
			then 'reingreso'
            else 'no_reingreso'
		end as tipo_ingreso
        from admisiones
        )
select 
	tipo_ingreso,
    avg(duracion_estancia) as duracion_promedio_estancia
from tipo_ingreso
group by tipo_ingreso;







# ¿qué porcentaje de pacientes con reingreso terminan falleciendo? | pro | ctes
with pacientes_con_reingreso as(
		select id_paciente
		from admisiones
		group by id_paciente
		having count(*) >1),
    total_pacientes_con_reingreso as (
		select count(*) as total_pacientes_con_reingreso
		from pacientes_con_reingreso),
    fallecidos_con_reingreso as (
		select count(*) as total_fallecidos_con_reingreso
        from admisiones
        where resultado = 'Defuncion'
			and id_paciente in (
				select id_paciente from pacientes_con_reingreso
			))
select 
	(num.total_fallecidos_con_reingreso * 100.0 / denom.total_pacientes_con_reingreso) as porc_fallecidos_reingreso
   
from fallecidos_con_reingreso num,
	total_pacientes_con_reingreso denom;
    


# ¿cual es el promedio de edad de los pacientes que fallecen? | fácil | joins
select 
	avg(p.edad) as edad_promedio_fallecidos
from pacientes p join admisiones a on p.id_admision = a.id_admision
where a.resultado = 'Defuncion';




# ¿fallecen proporcionalmente el mismo número de hombres y mujeres? | media | joins
select 
	p.genero,
    sum(case when a.resultado = 'Defuncion' then 1 else 0 end) * 100.0 / count(*) as porcentaje_fallecidos
from pacientes p join admisiones a on p.id_admision = a.id_admision
group by p.genero;





# ¿cual es el porcentaje de altas que terminan teniendo un reingreso dentro de los 30 días siguientes al alta? | pro | ctes | joins
with altas as (
	select
		id_paciente,
        id_admision,
        fecha_alta,
        resultado
	   from admisiones
	   where resultado != 'Defuncion'),
    total_altas as(
		select count(*) as total_altas
        from altas),
	reingresos_en_30_dias as (
		select
			a1.id_paciente,
            a1.id_admision as alta_id_admision,
            a2.id_admision as reingreso_id_admision,
            a1.fecha_alta,
            a2.fecha_admision
        from altas a1 join admisiones a2 on a1.id_paciente = a2.id_paciente
			and a2.fecha_admision > a1.fecha_alta
            and datediff(a2.fecha_admision, a1.fecha_alta) <= 30),
		total_reingresos_en_30_dias as (
			select count(alta_id_admision) as total_reingresos_en_30_dias
			from reingresos_en_30_dias)
 select 
	round((num.total_reingresos_en_30_dias * 100.0 / denom.total_altas),2) as porc_reingresos_30_dias
 from total_reingresos_en_30_dias num, total_altas denom;
            
        




