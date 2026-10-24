# CI de Atlas

Las definiciones vigentes son [build](../../.github/workflows/build.yml) y
[revisión de documentación](../../.github/workflows/auto-merge.yml). Se retiraron
las copias de YAML para evitar instrucciones divergentes.

CI exige artefactos reproducibles, inventario generado vigente, regresiones
PowerShell, carga WPF en Windows y pruebas/auditoría npm del Worker. Los jobs
`build`, `windows-compat` y `worker` deben pasar en el commit publicado.

El único merge automático permitido es documentación Markdown del bot previsto,
con aprobación humana del mismo SHA y los tres jobs correctos. Cualquier otro
archivo, renombre desde código o diff incompleto requiere merge humano. Una
etiqueta no autoriza un merge. El job consulta metadatos sin ejecutar código de PR.
Usa la definición de la rama base (`pull_request_target`) y `workflow_run`, sin
checkout. Si la aprobación llega después del CI, un cambio de etiqueta vuelve a
evaluar la elegibilidad; no se ejecuta un workflow privilegiado desde el PR.

Las acciones oficiales están fijadas por SHA; revisar nuevas versiones y notas
antes de actualizar. Los runners hospedados ejecutan Node 24 para las acciones;
Node no se instala como dependencia del cliente Windows.
