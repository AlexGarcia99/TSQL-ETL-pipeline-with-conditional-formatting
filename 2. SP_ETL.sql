USE [HIS_WEB]
GO
/****** Object:  StoredProcedure [dbo].[SP_CORTE_SEMANAL]    Script Date: 23/07/2025 01:39:06 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_CORTE_SEMANAL]
AS
;WITH CTE_CORTE_SEMANAL AS (
	SELECT
		ROW_NUMBER() OVER (PARTITION BY XX.NSS, CONVERT(DATE, XX.FECHA_DEL_ESTUDIO) ORDER BY(XX.FECHA_DEL_ESTUDIO)) AS NvecesRepetido,
		*
	FROM
	(SELECT
		E.IdPaciente,
		E.FOLIO AS UIDESTUDIO,
		ROW_NUMBER() OVER (PARTITION BY E.FOLIO/*, CONVERT(DATE, FechaEstudio)*/ ORDER BY (SELECT 1)) AS UID_DUPLICADOS,
		E.FechaEstudio AS FECHA_DEL_ESTUDIO,
		'HGZ 98' AS UNIDAD_TRATANTE,
		P.ApellidoPaterno,
		P.ApellidoMaterno,
		CONCAT(P.PrimerNombre,' ' /*COLLATE Modern_Spanish_CI_AI*/, P.SegundoNombre) AS NOMBRE_DEL_PACIENTE,
		NSS = left(P.Folio + replicate('0', 10), 10),
		CASE	
			WHEN E.Modalidades='CR'
				THEN '80.15.001'		
			WHEN E.Modalidades='DX'
				THEN '80.15.001'
			WHEN E.Modalidades='MG'
				THEN '80.15.002'
			WHEN E.Modalidades='BDUS' OR E.Modalidades='BMD'
				THEN '80.15.003'
			WHEN E.Modalidades='RF'
				THEN '80.15.004'
			WHEN E.Modalidades= 'US'
				THEN	(
							CASE 
								WHEN E.Descripcion NOT LIKE '%DOPPLER%' /*OR E.Descripcion NOT LIKE '%DOPLER%'*/ THEN '80.15.005'
								WHEN E.Descripcion  LIKE '%DOPPLER%' OR E.Descripcion LIKE '%DOPLER%' THEN '80.15.006'
							ELSE '80.15.005'
				END		)
			WHEN E.Modalidades= 'CT'
				THEN	(
							CASE	
								WHEN E.Descripcion NOT LIKE '%CONTRAST%' THEN '80.15.007'
								WHEN E.Descripcion LIKE '%CONTRASTADO%' OR E.Descripcion LIKE '%CONTRASTADA%' /*OR E.Descripcion LIKE '%GADOLIN%'*/ THEN '80.15.008'
							ELSE '80.15.007'
				END		)
			WHEN E.Modalidades='MR'
				THEN	(
							CASE	
								WHEN E.Descripcion NOT LIKE '%CONTRASTADO%' OR E.Descripcion NOT LIKE '%GADOLIN%' THEN '80.15.009'
								WHEN E.Descripcion  LIKE '%CONTRAST%' OR E.Descripcion LIKE '%GADOLIN%' THEN '80.15.010'
							ELSE '80.15.009'
				END		)
			WHEN E.Modalidades='XA'
				THEN '80.15.011'
			WHEN E.Modalidades = 'ES'
				THEN '80.15.012'
			ELSE '80.15.014'
		END AS CLAVE_CPIM,
		AGREGADO_MEDICO = LEFT(SUBSTRING(P.Folio,11,18) + REPLICATE('0',8),8),
		CASE	
			WHEN E.Modalidades='CR'
				THEN 'Radiología Simple'					
			WHEN E.Modalidades='DX'
				THEN 'Radiología Simple'
			WHEN E.Modalidades='MG'
				THEN 'Mastografía'
			WHEN E.Modalidades='BDUS' OR E.Modalidades='BMD'
				THEN 'Densitometría'
			WHEN E.Modalidades='RF'
				THEN 'Radiología Contrastada'
			WHEN E.Modalidades='US'
				THEN	(
							CASE
								WHEN E.Descripcion NOT LIKE '%DOPPLER%' /*OR E.Descripcion NOT LIKE '%DOPLER%'*/ THEN 'Ultrasonido'
								WHEN E.Descripcion LIKE '%DOPPLER%' OR E.Descripcion LIKE '%DOPLER%' THEN 'Ultrasonido Doppler'
							ELSE 'Ultrasonido'
				END		)
			WHEN E.Modalidades='CT'
				THEN	(
							CASE
								WHEN E.Descripcion NOT LIKE '%CONTRAST%' THEN 'Tomografía Computada Simple'
								WHEN E.Descripcion  LIKE '%CON CONTRASTE%' OR E.Descripcion LIKE '%CONTRASTADO%' OR E.Descripcion LIKE '%CONTRASTADA%' OR E.Descripcion LIKE '%GADOLIN%' THEN 'Tomografía Computada con medio de Contraste'
							ELSE 'Tomografía Computada Simple'								
				END		)
			WHEN E.Modalidades='MR'
				THEN	(
							CASE
								WHEN E.Descripcion NOT LIKE '%CONTRAST%' THEN 'Resonancia Magnética Simple'
								WHEN E.Descripcion  LIKE '%CON CONTRAST%' OR E.Descripcion LIKE '%CONTRASTADO%' OR E.Descripcion LIKE '%CONTRASTADA%' OR E.Descripcion LIKE '%GADOLIN%' THEN 'Resonancia Magnética Contrastada'
							ELSE 'Resonancia Magnética Simple'
				END		)
			WHEN E.Modalidades='XA'
				THEN 'RADIOLOGIA INTERVENCIONISTA VASCULAR'
			WHEN E.Modalidades='ES'
				THEN 'RADIOLOGIA INTERVENCIONISTA NO VASCULAR'
			ELSE 'OTRAS MODALIDADES DICOM'
		END AS TIPO_DE_ESTUDIO,
		E.Modalidades AS MODALIDAD,
		CASE
			WHEN I_R_E.IdEstadoResultado IN (0,1,2)
				THEN ' '
			ELSE CONVERT(VARCHAR,I_R_E.FechaResultado,103)
		END AS INTERPRETACION
	FROM
		DBO.Pacientes AS P
	INNER JOIN
		DBO.ImagenologiaEstudios AS E ON P.IDPACIENTE=E.IdPaciente
	LEFT JOIN
		dbo.ImagenologiaResultadosEstudio AS I_R_E ON E.IdEstudio=I_R_E.IdEstudio AND E.IdEstudio=I_R_E.IdEstudio
	WHERE
		DATEADD(day, -1, convert(date, GETDATE())) = CONVERT(DATE, E.FechaEstudio)  AND E.VisiblePACS = 1
	/*ORDER BY
		E.FechaEstudio*/) AS XX
		)
INSERT INTO HIS_CORTES.dbo.CORTE_SEMANAL2 (
	[NvecesRepetido],[FECHA_DEL_ESTUDIO],[UNIDAD_TRATANTE],[ApellidoPaterno],[ApellidoMaterno],[NOMBRE_DEL_PACIENTE],[NSS],[CLAVE_CPIM],[AGREGADO_MEDICO],
	[TIPO_DE_ESTUDIO],[MODALIDAD],[INTERPRETACION])
SELECT TOP 1000
	[NvecesRepetido],[FECHA_DEL_ESTUDIO],[UNIDAD_TRATANTE],[ApellidoPaterno],[ApellidoMaterno],[NOMBRE_DEL_PACIENTE],[NSS],[CLAVE_CPIM],[AGREGADO_MEDICO],
	[TIPO_DE_ESTUDIO],[MODALIDAD],[INTERPRETACION]
FROM
	CTE_CORTE_SEMANAL
WHERE
	CTE_CORTE_SEMANAL.UID_DUPLICADOS=1
ORDER BY
	CONVERT(VARCHAR, CTE_CORTE_SEMANAL.FECHA_DEL_ESTUDIO, 2),
	CTE_CORTE_SEMANAL.NSS
GO
