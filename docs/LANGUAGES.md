# Idiomas / Languages / Limbi

El panel está disponible en varios idiomas. El texto de la interfaz (botones,
categorías, mensajes de estado, pop-ups) se traduce automáticamente.

Las 27 tarjetas tienen nombre y descripción en español/inglés; otros idiomas usan
fallback inglés para tarjetas. La búsqueda admite ambos idiomas, IDs y categorías,
sin distinguir acentos o mayúsculas. Cada herramienta tiene cobertura de idioma
propia; no se declara traducción completa de todos sus menús.

---

## Idiomas soportados

| Código | Idioma    | Estado      |
|:------:|:----------|:------------|
| `es`   | Español   | Cadenas del panel y tarjetas |
| `en`   | English   | Cadenas del panel y tarjetas |
| `ro`   | Română    | Cadenas del panel |
| `pt`   | Português | Cadenas del panel |
| `fr`   | Français  | Cadenas del panel |
| `de`   | Deutsch   | Cadenas del panel |
| `it`   | Italiano  | Cadenas del panel |
| `auto` | Detectar del sistema | ✅ Por defecto |

---

## Cómo cambiar el idioma

Edita `branding.json` y pon uno de los códigos arriba en `language`:

```json
{
  "language": "en"
}
```

Valores válidos:

- `"auto"` (por defecto) — detecta el idioma de Windows y usa el fallback del panel cuando no está disponible.
- `"es"` — español
- `"en"` — inglés
- `"ro"` — rumano
- `"pt"`, `"fr"`, `"de"`, `"it"` — portugués, francés, alemán e italiano

Reinicia el launcher para ver el cambio.

---

## Añadir un idioma nuevo

Para añadir un idioma que aún no esté en la tabla:

1. Abre `src/lib/Strings.ps1`.
2. Duplica el bloque `'es' = @{ ... }` y cámbiale la clave (ej. `'fr'`).
3. Traduce cada valor (no las claves).
4. Recompila con `pwsh -File build.ps1`.
5. Abre un Pull Request — ¡bienvenido!

Ejemplo mínimo (fragmento):

```powershell
'fr' = @{
    'app.tagline'         = 'Panneau unifié de support technique Windows'
    'search.placeholder'  = 'Rechercher un outil...'
    'category.all'        = 'Tout'
    'status.ready'        = 'Prêt'
    'button.run'          = '▶  Exécuter'
    # ...
}
```

---

## Cadenas disponibles

| Clave                     | Descripción                                    |
|:--------------------------|:-----------------------------------------------|
| `app.tagline`             | Subtítulo bajo el nombre de marca              |
| `search.placeholder`      | Texto del buscador                             |
| `category.all`            | Pill "Todo"                                    |
| `category.<id>`           | Label de cada categoría (diagnostico, redes…)  |
| `header.admin`            | Badge "Admin" (con elevación)                  |
| `header.user`             | Badge "Usuario" (sin elevación)                |
| `header.logs`             | Botón "Logs"                                   |
| `header.about`            | Botón "Acerca de"                              |
| `button.run`              | Botón "Ejecutar" de cada tarjeta               |
| `badge.requiresAdmin`     | Badge bajo tools que requieren admin           |
| `status.ready`            | Barra de estado en reposo                      |
| `status.launching`        | Barra al lanzar una herramienta (`{0}`=nombre) |
| `status.lastRun`          | Barra tras lanzar (`{0}`=nombre)               |
| `status.toolsShown`       | Barra filtrada (`{0}`=cantidad)                |
| `logs.empty`              | Mensaje cuando no hay logs aún                 |
| `about.title`             | Título del diálogo "Acerca de"                 |
| `about.description`       | Texto final del "Acerca de"                    |
| `about.web`               | Label del enlace web                           |
| `tool.closePrompt`        | Prompt al cerrar una ventana de herramienta    |
| `tool.error`              | Mensaje de error en herramienta                |
| `tool.notLoaded`          | Error si no se pudo serializar la función      |
