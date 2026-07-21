# ============================================================
# Atlas PC Support - Strings / i18n
# Supported languages: en (default), es, pt, fr, de, it, ro
# To add another: copy the 'en' block and translate the values.
# ============================================================

$script:AtlasStringsDict = @{
    'es' = @{
        'app.tagline'             = 'Panel unificado de soporte técnico para Windows'
        'search.placeholder'      = 'Buscar herramienta...'
        'category.all'            = 'Todo'
        'category.diagnostico'    = 'Diagnóstico'
        'category.mantenimiento'  = 'Mantenimiento'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Redes'
        'category.seguridad'      = 'Seguridad'
        'category.software'       = 'Software'
        'category.entrega'        = 'Entrega'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Usuario'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ Acerca de'
        'button.run'              = '▶  Ejecutar'
        'badge.requiresAdmin'     = '🛡  requiere admin'
        'status.ready'            = 'Listo'
        'status.launching'        = 'Lanzando: {0}...'
        'status.lastRun'          = 'Listo — última: {0}'
        'status.toolsShown'       = '{0} herramienta(s) mostrada(s)'
        'logs.empty'              = 'Aún no hay logs. Ejecuta alguna herramienta primero.'
        'about.title'             = 'Acerca de'
        'about.description'       = 'Panel inspirado en WinUtil (Chris Titus Tech).{NEWLINE}Licencia: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Presiona Enter para cerrar esta ventana...'
        'tool.error'              = '[!] Error en {0}: {1}'
        'tool.notLoaded'          = "No se pudo serializar la función '{0}'. ¿Está cargada?"
        'footer.coffee'           = 'Invítame un café'
        'footer.coffeeTooltip'    = 'Apoya el proyecto con una donación vía PayPal'
        'header.language'         = 'Idioma'
        'header.languageTooltip'  = 'Cambiar idioma del panel'
        'header.restartTooltip'   = 'Reiniciar el panel (aplica el cambio de idioma)'
        'language.restartRequired'= 'Reinicia el panel para aplicar el nuevo idioma.'
        'restart.instructions'    = "El panel se cerrará ahora.{NEWLINE}{NEWLINE}Para reabrirlo, vuelve a ejecutar:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Alertas'
        'dash.alerts.none'        = 'Sin alertas — el equipo está bien.'
        'dash.refreshTooltip'     = 'Actualizar dashboard ahora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Activar/desactivar monitor de recursos en vivo'
        'dash.monitor.paused'     = 'Monitor de recursos apagado — pulsa Monitor OFF para activarlo.'
        'dash.alert.cpu'          = 'CPU al {0}%'
        'dash.alert.ram'          = 'RAM al {0}%'
        'dash.alert.disk'         = 'Disco {0} al {1}% lleno'
        'dash.alert.uptime'       = 'Uptime alto ({0} días) — considera reiniciar'
        'dash.alert.battery'      = 'Batería baja ({0}%)'
        'dash.alert.pendingReboot'= 'Reinicio pendiente de Windows Update'
        'sidebar.header'          = 'EQUIPO'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Usuario'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Encendido desde'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Última actualización'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB libres)'
    }
    'en' = @{
        'app.tagline'             = 'Unified Windows tech-support panel'
        'search.placeholder'      = 'Search tool...'
        'category.all'            = 'All'
        'category.diagnostico'    = 'Diagnostics'
        'category.mantenimiento'  = 'Maintenance'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Network'
        'category.seguridad'      = 'Security'
        'category.software'       = 'Software'
        'category.entrega'        = 'Handover'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 User'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ About'
        'button.run'              = '▶  Run'
        'badge.requiresAdmin'     = '🛡  requires admin'
        'status.ready'            = 'Ready'
        'status.launching'        = 'Launching: {0}...'
        'status.lastRun'          = 'Ready — last: {0}'
        'status.toolsShown'       = '{0} tool(s) shown'
        'logs.empty'              = 'No logs yet. Run a tool first.'
        'about.title'             = 'About'
        'about.description'       = 'Panel inspired by WinUtil (Chris Titus Tech).{NEWLINE}License: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Press Enter to close this window...'
        'tool.error'              = '[!] Error in {0}: {1}'
        'tool.notLoaded'          = "Could not serialize the function '{0}'. Is it loaded?"
        'footer.coffee'           = 'Buy me a coffee'
        'footer.coffeeTooltip'    = 'Support the project with a PayPal donation'
        'header.language'         = 'Language'
        'header.languageTooltip'  = 'Change panel language'
        'header.restartTooltip'   = 'Restart the panel (apply language change)'
        'language.restartRequired'= 'Restart the panel to apply the new language.'
        'restart.instructions'    = "The panel will now close.{NEWLINE}{NEWLINE}To reopen it, run:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disk'
        'dash.alerts'             = 'Alerts'
        'dash.alerts.none'        = 'No alerts — system looks healthy.'
        'dash.refreshTooltip'     = 'Refresh dashboard now'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Turn live resource monitor on/off'
        'dash.monitor.paused'     = 'Resource monitor is off — click Monitor OFF to enable it.'
        'dash.alert.cpu'          = 'CPU at {0}%'
        'dash.alert.ram'          = 'RAM at {0}%'
        'dash.alert.disk'         = 'Disk {0} at {1}% used'
        'dash.alert.uptime'       = 'Long uptime ({0} days) — consider rebooting'
        'dash.alert.battery'      = 'Battery low ({0}%)'
        'dash.alert.pendingReboot'= 'Windows Update reboot pending'
        'sidebar.header'          = 'SYSTEM'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'User'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'Total RAM'
        'sidebar.uptime'          = 'Up since'
        'sidebar.ip'              = 'Local IP'
        'sidebar.lastSync'        = 'Last refresh'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB free)'
    }
    'ro' = @{
        'app.tagline'             = 'Panou unificat de suport tehnic pentru Windows'
        'search.placeholder'      = 'Caută unealta...'
        'category.all'            = 'Toate'
        'category.diagnostico'    = 'Diagnostic'
        'category.mantenimiento'  = 'Mentenanță'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rețea'
        'category.seguridad'      = 'Securitate'
        'category.software'       = 'Software'
        'category.entrega'        = 'Predare'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilizator'
        'header.logs'             = '📋 Jurnale'
        'header.about'            = 'ℹ️ Despre'
        'button.run'              = '▶  Rulează'
        'badge.requiresAdmin'     = '🛡  necesită admin'
        'status.ready'            = 'Gata'
        'status.launching'        = 'Se lansează: {0}...'
        'status.lastRun'          = 'Gata — ultima: {0}'
        'status.toolsShown'       = '{0} unealtă(e) afișată(e)'
        'logs.empty'              = 'Încă nu există jurnale. Rulează o unealtă mai întâi.'
        'about.title'             = 'Despre'
        'about.description'       = 'Panou inspirat din WinUtil (Chris Titus Tech).{NEWLINE}Licență: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Apasă Enter pentru a închide această fereastră...'
        'tool.error'              = '[!] Eroare în {0}: {1}'
        'tool.notLoaded'          = "Nu s-a putut serializa funcția '{0}'. Este încărcată?"
        'footer.coffee'           = 'Oferă-mi o cafea'
        'footer.coffeeTooltip'    = 'Susține proiectul cu o donație prin PayPal'
        'header.language'         = 'Limbă'
        'header.languageTooltip'  = 'Schimbă limba panoului'
        'header.restartTooltip'   = 'Repornește panoul (aplică schimbarea de limbă)'
        'language.restartRequired'= 'Repornește panoul pentru a aplica noua limbă.'
        'restart.instructions'    = "Panoul se va închide acum.{NEWLINE}{NEWLINE}Pentru a-l redeschide, rulează:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disc'
        'dash.alerts'             = 'Alerte'
        'dash.alerts.none'        = 'Fără alerte — sistemul e în regulă.'
        'dash.refreshTooltip'     = 'Reîmprospătează dashboard'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Pornește/oprește monitorul live de resurse'
        'dash.monitor.paused'     = 'Monitorul de resurse este oprit — apasă Monitor OFF pentru activare.'
        'dash.alert.cpu'          = 'CPU la {0}%'
        'dash.alert.ram'          = 'RAM la {0}%'
        'dash.alert.disk'         = 'Disc {0} folosit {1}%'
        'dash.alert.uptime'       = 'Uptime mare ({0} zile) — repornește'
        'dash.alert.battery'      = 'Baterie scăzută ({0}%)'
        'dash.alert.pendingReboot'= 'Restart Windows Update în așteptare'
        'sidebar.header'          = 'SISTEM'
        'sidebar.host'            = 'Nume PC'
        'sidebar.user'            = 'Utilizator'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Pornit din'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Ultima actualizare'
        'sidebar.uptimeFmt'       = '{0}z {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB liberi)'
    }
    'pt' = @{
        'app.tagline'             = 'Painel unificado de suporte técnico para Windows'
        'search.placeholder'      = 'Buscar ferramenta...'
        'category.all'            = 'Tudo'
        'category.diagnostico'    = 'Diagnóstico'
        'category.mantenimiento'  = 'Manutenção'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rede'
        'category.seguridad'      = 'Segurança'
        'category.software'       = 'Software'
        'category.entrega'        = 'Entrega'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilizador'
        'header.logs'             = '📋 Registos'
        'header.about'            = 'ℹ️ Acerca'
        'button.run'              = '▶  Executar'
        'badge.requiresAdmin'     = '🛡  requer admin'
        'status.ready'            = 'Pronto'
        'status.launching'        = 'A iniciar: {0}...'
        'status.lastRun'          = 'Pronto — última: {0}'
        'status.toolsShown'       = '{0} ferramenta(s) mostrada(s)'
        'logs.empty'              = 'Ainda sem registos. Executa uma ferramenta primeiro.'
        'about.title'             = 'Acerca'
        'about.description'       = 'Painel inspirado no WinUtil (Chris Titus Tech).{NEWLINE}Licença: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Pressiona Enter para fechar esta janela...'
        'tool.error'              = '[!] Erro em {0}: {1}'
        'tool.notLoaded'          = "Não foi possível serializar a função '{0}'. Está carregada?"
        'footer.coffee'           = 'Paga-me um café'
        'footer.coffeeTooltip'    = 'Apoia o projeto com um donativo PayPal'
        'header.language'         = 'Idioma'
        'header.languageTooltip'  = 'Mudar idioma do painel'
        'header.restartTooltip'   = 'Reiniciar o painel (aplicar mudança de idioma)'
        'language.restartRequired'= 'Reinicia o painel para aplicar o novo idioma.'
        'restart.instructions'    = "O painel irá fechar agora.{NEWLINE}{NEWLINE}Para reabrir, executa:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Alertas'
        'dash.alerts.none'        = 'Sem alertas — sistema saudável.'
        'dash.refreshTooltip'     = 'Atualizar painel agora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Ativar/desativar monitor de recursos em tempo real'
        'dash.monitor.paused'     = 'Monitor de recursos desligado — clica Monitor OFF para ativar.'
        'dash.alert.cpu'          = 'CPU em {0}%'
        'dash.alert.ram'          = 'RAM em {0}%'
        'dash.alert.disk'         = 'Disco {0} a {1}% cheio'
        'dash.alert.uptime'       = 'Uptime alto ({0} dias) — reinicie'
        'dash.alert.battery'      = 'Bateria fraca ({0}%)'
        'dash.alert.pendingReboot'= 'Reinício do Windows Update pendente'
        'sidebar.header'          = 'SISTEMA'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utilizador'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM total'
        'sidebar.uptime'          = 'Ligado desde'
        'sidebar.ip'              = 'IP local'
        'sidebar.lastSync'        = 'Última atualização'
        'sidebar.uptimeFmt'       = '{0}d {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB livres)'
    }
    'fr' = @{
        'app.tagline'             = 'Panneau unifié de support technique pour Windows'
        'search.placeholder'      = 'Rechercher un outil...'
        'category.all'            = 'Tout'
        'category.diagnostico'    = 'Diagnostic'
        'category.mantenimiento'  = 'Maintenance'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Réseau'
        'category.seguridad'      = 'Sécurité'
        'category.software'       = 'Logiciels'
        'category.entrega'        = 'Livraison'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utilisateur'
        'header.logs'             = '📋 Journaux'
        'header.about'            = 'ℹ️ À propos'
        'button.run'              = '▶  Exécuter'
        'badge.requiresAdmin'     = '🛡  admin requis'
        'status.ready'            = 'Prêt'
        'status.launching'        = 'Lancement : {0}...'
        'status.lastRun'          = 'Prêt — dernier : {0}'
        'status.toolsShown'       = '{0} outil(s) affiché(s)'
        'logs.empty'              = 'Aucun journal pour l''instant. Lance un outil d''abord.'
        'about.title'             = 'À propos'
        'about.description'       = 'Panneau inspiré de WinUtil (Chris Titus Tech).{NEWLINE}Licence : MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Appuyez sur Entrée pour fermer cette fenêtre...'
        'tool.error'              = '[!] Erreur dans {0} : {1}'
        'tool.notLoaded'          = "Impossible de sérialiser la fonction '{0}'. Est-elle chargée ?"
        'footer.coffee'           = 'Offre-moi un café'
        'footer.coffeeTooltip'    = 'Soutiens le projet avec un don PayPal'
        'header.language'         = 'Langue'
        'header.languageTooltip'  = 'Changer la langue du panneau'
        'header.restartTooltip'   = 'Redémarrer le panneau (appliquer le changement de langue)'
        'language.restartRequired'= 'Redémarre le panneau pour appliquer la nouvelle langue.'
        'restart.instructions'    = "Le panneau va se fermer maintenant.{NEWLINE}{NEWLINE}Pour le rouvrir, exécute :{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disque'
        'dash.alerts'             = 'Alertes'
        'dash.alerts.none'        = 'Aucune alerte — système OK.'
        'dash.refreshTooltip'     = 'Actualiser le tableau de bord'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Activer/désactiver le moniteur de ressources'
        'dash.monitor.paused'     = "Moniteur de ressources désactivé — cliquez sur Monitor OFF pour l'activer."
        'dash.alert.cpu'          = 'CPU à {0}%'
        'dash.alert.ram'          = 'RAM à {0}%'
        'dash.alert.disk'         = 'Disque {0} à {1}% plein'
        'dash.alert.uptime'       = 'Uptime élevé ({0} j) — redémarre'
        'dash.alert.battery'      = 'Batterie faible ({0}%)'
        'dash.alert.pendingReboot'= 'Redémarrage Windows Update en attente'
        'sidebar.header'          = 'SYSTÈME'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utilisateur'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM totale'
        'sidebar.uptime'          = 'Allumé depuis'
        'sidebar.ip'              = 'IP locale'
        'sidebar.lastSync'        = 'Dernière actu'
        'sidebar.uptimeFmt'       = '{0}j {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} Go libres)'
    }
    'de' = @{
        'app.tagline'             = 'Einheitliches Windows-Supportpanel'
        'search.placeholder'      = 'Werkzeug suchen...'
        'category.all'            = 'Alle'
        'category.diagnostico'    = 'Diagnose'
        'category.mantenimiento'  = 'Wartung'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Netzwerk'
        'category.seguridad'      = 'Sicherheit'
        'category.software'       = 'Software'
        'category.entrega'        = 'Übergabe'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Benutzer'
        'header.logs'             = '📋 Logs'
        'header.about'            = 'ℹ️ Über'
        'button.run'              = '▶  Ausführen'
        'badge.requiresAdmin'     = '🛡  Admin nötig'
        'status.ready'            = 'Bereit'
        'status.launching'        = 'Starte: {0}...'
        'status.lastRun'          = 'Bereit — zuletzt: {0}'
        'status.toolsShown'       = '{0} Werkzeug(e) angezeigt'
        'logs.empty'              = 'Noch keine Logs. Führe zuerst ein Werkzeug aus.'
        'about.title'             = 'Über'
        'about.description'       = 'Panel inspiriert von WinUtil (Chris Titus Tech).{NEWLINE}Lizenz: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Drücke Enter, um dieses Fenster zu schließen...'
        'tool.error'              = '[!] Fehler in {0}: {1}'
        'tool.notLoaded'          = "Funktion '{0}' konnte nicht serialisiert werden. Ist sie geladen?"
        'footer.coffee'           = 'Spendiere mir einen Kaffee'
        'footer.coffeeTooltip'    = 'Unterstütze das Projekt mit einer PayPal-Spende'
        'header.language'         = 'Sprache'
        'header.languageTooltip'  = 'Panel-Sprache ändern'
        'header.restartTooltip'   = 'Panel neu starten (Sprache anwenden)'
        'language.restartRequired'= 'Starte das Panel neu, um die neue Sprache anzuwenden.'
        'restart.instructions'    = "Das Panel wird jetzt geschlossen.{NEWLINE}{NEWLINE}Zum erneuten Öffnen ausführen:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Datenträger'
        'dash.alerts'             = 'Warnungen'
        'dash.alerts.none'        = 'Keine Warnungen — System OK.'
        'dash.refreshTooltip'     = 'Dashboard jetzt aktualisieren'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Live-Ressourcenmonitor ein-/ausschalten'
        'dash.monitor.paused'     = 'Ressourcenmonitor ist aus — Monitor OFF zum Aktivieren klicken.'
        'dash.alert.cpu'          = 'CPU bei {0}%'
        'dash.alert.ram'          = 'RAM bei {0}%'
        'dash.alert.disk'         = 'Datenträger {0} zu {1}% voll'
        'dash.alert.uptime'       = 'Lange Laufzeit ({0} T) — neu starten'
        'dash.alert.battery'      = 'Akku niedrig ({0}%)'
        'dash.alert.pendingReboot'= 'Windows-Update-Neustart ausstehend'
        'sidebar.header'          = 'SYSTEM'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Benutzer'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM gesamt'
        'sidebar.uptime'          = 'An seit'
        'sidebar.ip'              = 'Lokale IP'
        'sidebar.lastSync'        = 'Letzte Aktualisierung'
        'sidebar.uptimeFmt'       = '{0}T {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB frei)'
    }
    'it' = @{
        'app.tagline'             = 'Pannello unificato di supporto tecnico per Windows'
        'search.placeholder'      = 'Cerca strumento...'
        'category.all'            = 'Tutto'
        'category.diagnostico'    = 'Diagnostica'
        'category.mantenimiento'  = 'Manutenzione'
        'category.copia'          = 'Backup & Sync'
        'category.redes'          = 'Rete'
        'category.seguridad'      = 'Sicurezza'
        'category.software'       = 'Software'
        'category.entrega'        = 'Consegna'
        'header.admin'            = '🛡  Admin'
        'header.user'             = '👤 Utente'
        'header.logs'             = '📋 Log'
        'header.about'            = 'ℹ️ Info'
        'button.run'              = '▶  Esegui'
        'badge.requiresAdmin'     = '🛡  richiede admin'
        'status.ready'            = 'Pronto'
        'status.launching'        = 'Avvio: {0}...'
        'status.lastRun'          = 'Pronto — ultimo: {0}'
        'status.toolsShown'       = '{0} strumento/i mostrato/i'
        'logs.empty'              = 'Ancora nessun log. Esegui prima uno strumento.'
        'about.title'             = 'Info'
        'about.description'       = 'Pannello ispirato a WinUtil (Chris Titus Tech).{NEWLINE}Licenza: MIT.'
        'about.web'               = 'Web'
        'tool.closePrompt'        = 'Premi Invio per chiudere questa finestra...'
        'tool.error'              = '[!] Errore in {0}: {1}'
        'tool.notLoaded'          = "Impossibile serializzare la funzione '{0}'. È caricata?"
        'footer.coffee'           = 'Offrimi un caffè'
        'footer.coffeeTooltip'    = 'Sostieni il progetto con una donazione PayPal'
        'header.language'         = 'Lingua'
        'header.languageTooltip'  = 'Cambia lingua del pannello'
        'header.restartTooltip'   = 'Riavviare il pannello (applicare il cambio lingua)'
        'language.restartRequired'= 'Riavvia il pannello per applicare la nuova lingua.'
        'restart.instructions'    = "Il pannello si chiuderà ora.{NEWLINE}{NEWLINE}Per riaprirlo, esegui:{NEWLINE}  irm ""https://toolspanel.atlaspcsupport.com"" | iex"
        'dash.cpu'                = 'CPU'
        'dash.ram'                = 'RAM'
        'dash.disk'               = 'Disco'
        'dash.alerts'             = 'Avvisi'
        'dash.alerts.none'        = 'Nessun avviso — sistema OK.'
        'dash.refreshTooltip'     = 'Aggiorna dashboard ora'
        'dash.monitor.on'         = 'Monitor ON'
        'dash.monitor.off'        = 'Monitor OFF'
        'dash.monitor.tooltip'    = 'Attiva/disattiva monitor risorse live'
        'dash.monitor.paused'     = 'Monitor risorse spento — clicca Monitor OFF per attivarlo.'
        'dash.alert.cpu'          = 'CPU al {0}%'
        'dash.alert.ram'          = 'RAM al {0}%'
        'dash.alert.disk'         = 'Disco {0} al {1}% pieno'
        'dash.alert.uptime'       = 'Uptime alto ({0} g) — riavvia'
        'dash.alert.battery'      = 'Batteria scarica ({0}%)'
        'dash.alert.pendingReboot'= 'Riavvio Windows Update in sospeso'
        'sidebar.header'          = 'SISTEMA'
        'sidebar.host'            = 'Hostname'
        'sidebar.user'            = 'Utente'
        'sidebar.os'              = 'Windows'
        'sidebar.cpu'             = 'CPU'
        'sidebar.ram'             = 'RAM totale'
        'sidebar.uptime'          = 'Acceso da'
        'sidebar.ip'              = 'IP locale'
        'sidebar.lastSync'        = 'Ultimo aggiornamento'
        'sidebar.uptimeFmt'       = '{0}g {1}h {2}m'
        'dash.disk.detail'        = '{0}% ({1} GB liberi)'
    }
}

$script:AtlasCurrentLang = 'en'

# Nombres nativos de los idiomas para mostrar en el selector.
$script:AtlasLanguageNames = [ordered]@{
    'es' = 'Español'
    'en' = 'English'
    'pt' = 'Português'
    'fr' = 'Français'
    'de' = 'Deutsch'
    'it' = 'Italiano'
    'ro' = 'Română'
}

function Get-AtlasSystemLanguage {
    try {
        $culture = [System.Globalization.CultureInfo]::CurrentUICulture
        $two = $culture.TwoLetterISOLanguageName.ToLower()
        if ($script:AtlasStringsDict.ContainsKey($two)) {
            return $two
        }
    } catch {}
    return 'en'
}

function Set-AtlasLanguage {
    [CmdletBinding()]
    param(
        [string]$Language = 'auto'
    )
    if ($Language -eq 'auto' -or -not $Language) {
        $Language = Get-AtlasSystemLanguage
    }
    $Language = $Language.ToLower()
    if (-not $script:AtlasStringsDict.ContainsKey($Language)) {
        Write-Warning "Language '$Language' not supported. Using 'en'."
        $Language = 'en'
    }
    $script:AtlasCurrentLang = $Language
    return $Language
}

function Get-AtlasString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)] [string]$Key,
        [Parameter(Position=1, ValueFromRemainingArguments=$true)] [object[]]$Args
    )
    $dict = $script:AtlasStringsDict[$script:AtlasCurrentLang]
    if (-not $dict.ContainsKey($Key)) {
        # fallback to English
        $dict = $script:AtlasStringsDict['en']
    }
    $value = $dict[$Key]
    if (-not $value) { return $Key }
    if ($Args -and $Args.Count -gt 0) {
        $value = [string]::Format($value, $Args)
    }
    $value = $value -replace '\{NEWLINE\}', [Environment]::NewLine
    return $value
}

function Get-AtlasSupportedLanguages {
    # Si hay AtlasLanguageNames (ordenado), usarlo para orden estable en dropdowns.
    if ($script:AtlasLanguageNames) {
        return @($script:AtlasLanguageNames.Keys | Where-Object { $script:AtlasStringsDict.ContainsKey($_) })
    }
    return @($script:AtlasStringsDict.Keys)
}

function Get-AtlasLanguageName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Code)
    if ($script:AtlasLanguageNames -and $script:AtlasLanguageNames.Contains($Code)) {
        return $script:AtlasLanguageNames[$Code]
    }
    return $Code.ToUpper()
}

# ----- Persistencia de preferencia de idioma -----
function _Get-AtlasConfigPath {
    $dir = Join-Path $env:LOCALAPPDATA 'AtlasPC'
    if (-not (Test-Path -LiteralPath $dir)) {
        try { New-Item -ItemType Directory -Path $dir -Force | Out-Null } catch {}
    }
    return (Join-Path $dir 'config.json')
}

function Get-AtlasLanguagePref {
    try {
        $cfgPath = _Get-AtlasConfigPath
        if (Test-Path -LiteralPath $cfgPath) {
            $obj = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            if ($obj.language -and $script:AtlasStringsDict.ContainsKey([string]$obj.language)) {
                return [string]$obj.language
            }
        }
    } catch {}
    return $null
}

function Set-AtlasLanguagePref {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Language)
    try {
        $cfgPath = _Get-AtlasConfigPath
        $obj = [ordered]@{}
        if (Test-Path -LiteralPath $cfgPath) {
            try {
                $existing = Get-Content -LiteralPath $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($existing) {
                    foreach ($p in $existing.PSObject.Properties) { $obj[$p.Name] = $p.Value }
                }
            } catch {}
        }
        $obj['language'] = $Language
        $json = $obj | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $cfgPath -Value $json -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}
