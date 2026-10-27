# Fase 2 de la auditoría integral: diagnósticos coherentes

Entrega 1.5.14. Atiende A02, A05 y A07 del
[informe integral](AUDITORIA-INTEGRAL-1.5.12-2026-10-27.md), conservando las 27
entradas, las aplicaciones actuales y Windows PowerShell 5.1 como runtime.

## Cambios y motivos

- PartsUpgrade comparte con Master el cálculo de capacidades/matrices de memoria:
  máximo extendido, varias matrices y valores ausentes sin convertirlos en cero.
  No deduce generación universal del nombre de CPU, XMP de velocidades diferentes
  ni soldadura del código SMBIOS 6. La ampliación exige verificar el modelo OEM.
  Se retiran promesas de arranque desde HDD, mejoras universales y un hash que
  no correspondía al archivo final. Tamaño desconocido y salud de enum cero se
  presentan correctamente; el estado del proveedor físico queda visible.
- GPU Check conserva la señal observada más fuerte en vez de diluirla con pesos
  de fuentes ausentes. Temperatura o ralentización térmica notificadas pueden
  alcanzar el nivel alto. La escala es una regla de cribado, no probabilidad
  calibrada ni especificación térmica OEM. WHEA aislado no se atribuye a la GPU.
  La severidad de eventos usa el número, independiente del idioma de Windows.
  Los fallos de consulta no se convierten en una sesión sin hallazgos; el alcance
  temporal y el límite de filas permanecen explícitos. El vigilante ACPI mide
  zonas del sistema y no garantiza protección térmica de la GPU.
- Printer Doctor y Keyboard Doctor distinguen consulta observada/vacía de fallo.
  Las vistas y los informes no convierten acceso denegado en «sin dispositivo»,
  «sin trabajos» o «sin eventos». La lectura de eventos queda acotada. Los flags
  de accesibilidad no consultados no se presentan como desactivados.
- Keyboard Doctor conserva presencia/carga cuando se conocen. Elimina el cálculo
  de desgaste que mezclaba las primeras filas de dos proveedores sin identidad.
  El detalle de capacidad por batería sigue disponible en Master, con la
  implementación ya validada en 1.5.12; no se añade otro exportador ni se instala
  una utilidad para simular cobertura. Desgaste no establece hinchazón.
- IA mantiene RAM/VRAM desconocidas como null, no las usa para diagnosticar poca
  capacidad ni recomendar un modelo con inventario esencial incompleto. El
  distintivo visual refleja ese estado. Master deja BSOD como no evaluado si no
  obtiene contenido aprovechable de una exportación nueva; no afirma ausencia
  de fallos por faltar ese contenido.

## Comprobación y alcance

Las regresiones ejercitan el informe real de PartsUpgrade con inventario y
escritura simulados; matrices múltiples, acceso denegado, código 6 y velocidades
distintas; rutas de consulta de impresoras/teclado y ausencia válida de eventos;
varias baterías sin cruce de capacidades; y ramas reales de la puntuación GPU
con temperatura 95, eventos localizados y falta de cobertura. IA cubre capacidad
ausente sin consejo de compra/modelo. No se ejecutan estrés ni reparaciones.

La suite completa aprobó 365 pruebas en PowerShell 5.1.26100.9711 y otras 365 en
PowerShell 7.6.9: cero fallos, cero omitidas y cero errores del analizador. Los
guards, la carga WPF sin mostrar ventana y la reproducción del bundle también
pasaron, sin alterar los artefactos durante las pruebas. Se añadieron diez
regresiones respecto de la fase anterior. El manifiesto de 1.5.14 es
`bc27d7ac30eae80a2089d9924219737ee13283066fac060518f746df429b2a51`.
La promoción exige además CI aprobado para el SHA exacto y comprobación pública
posterior. El registro de la entrega/PR conserva esos resultados; esta nota
explica el alcance funcional y no sustituye la evidencia física.

Windows 10 sigue sin homologación completa y las VMs permanecen pausadas.
Ni mocks ni clasificación térmica certifican GPU, batería, conectores, módulos
o ampliación real. No se alteran Defender, políticas, cuentas o red del host.
Las fases 3–5 del informe no se dan por realizadas mediante estos cambios.

Fase anterior publicada: 1.5.13, fuente
`320de4418e9aafeb02ab13994b3161013c0bca85`, manifiesto
`aaa0e69799272619f01b7d1751d311c1f945b1867b0c8a36f80917fed0e6a9e4`.
CI completo y 355 pruebas por runtime aprobados; dominio, 34 miembros, sidecars,
errores HTTP esperados y verificación offline sin abrir panel comprobados.
