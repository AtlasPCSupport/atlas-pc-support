# Dominio existente de Atlas

La entrada sigue siendo `https://toolspanel.atlaspcsupport.com`, asociada al Worker
`atlas-launcher`. La fase 2 no cambia el dominio ni el onboarding de clientes.

La fuente versionada está en `api/cloudflare-worker/src/index.js`; no mantener otra
copia de su código en esta guía. El procedimiento de build, CI, promoción con pins,
prueba de endpoints y recuperación está en [RELEASES.md](RELEASES.md).

- `/` y `/get.ps1`: bootstrap verificado, ligado a una publicación aprobada.
- `/release.json`: descriptor con commit y digest del manifiesto.
- `/release-manifest.json`: manifiesto verificado de esa publicación.
- `/launcher.sha256` y `/tool-hashes.sha256`: compatibilidad con clientes anteriores;
  ya no se describen como autoridad independiente por sí solos.
- `/install.bat`: batch público del mismo commit aprobado.
- `/install.ps1` y su `.sha256`: distribución pública del instalador alojado en el
  repositorio privado, usando el secreto `GITHUB_PAT` existente. Sin caché compartida.
  Un repositorio privado no convierte estas URLs en endpoints autenticados.
- `/healthz`: comprobación de disponibilidad.

Solo se admiten GET y HEAD. Rutas desconocidas responden 404; métodos no admitidos,
405. `?ref=` acepta únicamente el commit completo de la publicación actual o la
anterior, además del alias `main` de la actual. No cae a `main` ante un error.

No hace falta ejecutar un prompt de instalación general para mantener este Worker.
Wrangler usa su sesión autorizada; no añadir credenciales a los archivos públicos.
