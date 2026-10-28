# Personalización de marca

Atlas fusiona el primer JSON válido con los valores predeterminados. La plantilla
[branding.example.json](../branding.example.json) solo muestra campos consumidos.
No cambia licencias, privilegios ni integridad del release.

Guarda branding.json en `%LOCALAPPDATA%\AtlasPC\` o `%APPDATA%\AtlasPC\`. También se
busca junto al script y en la raíz de desarrollo. No edites fuentes, hashes o el
manifiesto de un release para personalizarlo.

```json
{
  "brand":{"name":"MI SOPORTE","shortName":"Soporte","tagline":"Servicio técnico"},
  "theme":{"accentColor":"#0078D4","darkMode":true,"fontFamily":"Segoe UI"},
  "window":{"title":"Mi panel","width":1100,"height":720},
  "language":"auto"
}
```

| Grupo | Campos consumidos |
|---|---|
| brand | name, shortName, tagline, copyright, companyUrl (texto de Acerca de) |
| theme | accentColor, secondaryColor, darkMode, cornerRadius, fontFamily |
| window | title, width/height, minWidth/minHeight; ajustados al área del escritorio |
| language | auto/es/en/ro; la preferencia guardada por el selector tiene prioridad |
| categories | id, label, icon, order; los labels conocidos pueden traducirse |

brand.version puede sobrescribir texto visible, pero no la versión real de los
artefactos o informes; se omite del ejemplo para evitar confusiones.

Campos antiguos **sin comportamiento implementado**: autoElevate, logPath,
dependenciesPath, defaultCategory, confirmBeforeRun, showSearch, showFooter,
useSystemAccent, supportEmail y logo. No se activan al escribirlos en JSON.
Cada herramienta conserva requiresAdmin; branding no autoeleva el panel. Logs y
dependencias usan sus rutas propias; búsqueda y footer siguen visibles.

No hay esquema JSON externo mantenido; se retira la referencia a un esquema
inexistente. Usa JSON válido y revisa los consumidores antes de añadir campos.
Para distribuir usa la entrada completa de [releases](RELEASES.md), no un launcher
suelto. [Idiomas](LANGUAGES.md), [compatibilidad](SUPPORT-MATRIX.md).
