# Fase 1 de la auditoría integral: DNS, privacidad y teclado

Entrega 1.5.13. Implementa A01, A03 y A06 del
[informe integral](AUDITORIA-INTEGRAL-1.5.12-2026-10-27.md).

- Mullvad deja de ser seleccionable como DNS clásico. También se rechazan sus
  direcciones en entrada personalizada antes de obtener snapshot o cambiar red;
  se explica el requisito de DNS cifrado y el cierre anunciado del servicio.
  No se migra automáticamente ninguna configuración existente. El ping se
  identifica como ICMP y el enlace informativo usa ECH.
- Los informes IA redactan ClientName/ConsultantName y usan carpetas con ID
  aleatorio. Reutilizar deliberadamente un ID conserva la comparación anterior;
  los directorios antiguos con nombres no se borran ni se importan solos.
  El informe de cuentas se guarda mediante el escritor compartido, omitiendo
  nombres de usuarios/equipo en vez de depender de la longitud del texto.
- El monitor de teclado conserva solo conteo agregado. Diagnóstico, HTML y TXT
  consumen ese esquema; cero teclas no se transforma en un evento por contar el
  registro contenedor. Las guías IA/teclado reflejan el comportamiento real.

Pruebas ejecutadas: **355 aprobadas en 5.1.26100.9711 y 355 en 7.6.9**, cero
fallidas/omitidas y cero errores del analizador (290/316 advertencias conservadas).
Incluyen fixtures aislados de DNS sin cambios de adaptadores, identidades cortas,
contención por ID, comparación explícita y conteos cero/uno/varios, además de
carga WPF sin mostrar ventana y reproducción del bundle. CI y publicación se
verifican posteriormente en el SHA de la PR de esta entrega.

Manifiesto: `aaa0e69799272619f01b7d1751d311c1f945b1867b0c8a36f80917fed0e6a9e4`.

No se ejecutan operaciones de cuentas, red, reparación o hardware en el host.
Defender activo; VMs pausadas. Windows 10 sigue sin homologación completa.
Los ensayos de extremo a extremo con hardware se mantienen pendientes.

Fuente del cambio de proveedor:
[Mullvad DNS](https://mullvad.net/en/help/dns-over-https-and-dns-over-tls),
consultada el 27/10/2026. La retirada evita configurar DNS clásico no utilizable;
no desinstala Mullvad VPN ni modifica aplicaciones del equipo.
