# Next Steps - Piano Esecutivo IRIS

## Stato rapido (aggiornato)
Completato in questa iterazione:
- Dashboard TL/Manager/Admin con selezione mese
- Nuova sezione "Complessivo mese per progetto e utente"
- Export CSV compatibile Excel (download web, clipboard fallback)
- Supporto admin come contributor assegnabile a un TeamLead
- Setup `.env` per Firebase tramite script run/build
- Integrazione GECO base: `commesse`, `projects.commessaId`, `timesheet_entries.commessaId`
- KPI ufficiali mensili su dashboard (completion, saturazione, DSO, quality, over/under)
- KPI economici progetto (costo, ricavo, margine, burn rate, forecast)
- Export `.xlsx` multi-sheet (Utenti, Progetti, Economico)
- Hardening Firestore rules per coerenza commessa/progetto/timesheet

## 1) Priorita integrazione commessa GECO
Raccomandazione: **SI, priorita alta (Fase 1)**.

Livello di dettaglio consigliato:
1. `projects.commessaId` obbligatorio per progetti fatturabili
2. `timesheet_entries.commessaId` opzionale (attivabile per granularita extra)
3. anagrafica `commesse` centralizzata (codice, descrizione, cliente, stato)

Beneficio:
- raccordo diretto tra ore consuntivate e reporting economico/contabile.

## 3) KPI ufficiali da monitorare mensilmente
KPI core consigliati:
1. Completion timesheet = ore consuntivate / ore teoriche lavorative
2. Overtime/undertime = ore consuntivate - ore teoriche
3. Distribuzione ore per progetto (% sul totale)
4. Saturazione team = media ore per persona / target
5. DSO compilazione = giorni medi di ritardo compilazione
6. Quality score = % giorni con consuntivo completo (8h)

Soglie iniziali (proposta):
- completion < 85% = alert
- saturazione > 110% = rischio overload
- saturazione < 70% = rischio sotto-utilizzo

## 4) Stima economica per progetto
Aggiunte raccomandate a modello progetto:
- `hourlyCost` (costo medio orario)
- `hourlyRate` (tariffa verso cliente, se applicabile)
- `estimatedHours`
- `estimatedBudget`

Metriche economiche:
1. Costo consuntivato = ore * hourlyCost
2. Ricavo stimato = ore * hourlyRate
3. Margine lordo = ricavo - costo
4. Burn rate budget = costo consuntivato / estimatedBudget
5. Forecast fine mese = trend ore * costo medio

## 5) `.env` Firebase
Disponibile:
- `.env.example`
- `scripts/run_web_with_env.sh`
- `scripts/build_web_with_env.sh`

Uso rapido:
```bash
cp .env.example .env
# valorizza FIREBASE_WEB_*
./scripts/run_web_with_env.sh
```

## 6) Dashboard più intuitiva TL/Manager
Implementato:
- vista mensile selezionabile
- aggregato progetto + dettaglio utenti contributor
- filtri avanzati (team lead, progetto, developer type)
- colonne KPI economici e pannello KPI ufficiali
- export mensile utenti/progetti

## 7) Admin anche sviluppatore sotto TL
Supportato in lettura/team analytics:
- se un admin ha `teamLeadId`, viene incluso come contributor nei team TL/Manager.

Step successivo:
- UI gestione utenti: toggle esplicito "Admin contributor" per assegnazione controllata.

## 8) Cambio mese dashboard TL/Manager
Implementato:
- selector mese (prev/next + picker calendario)
- tutte le metriche e grafici si allineano al mese selezionato

## 9) Export Excel per utente
Implementato:
- export mensile con righe per utente/progetto
- download diretto su web
- fallback clipboard su piattaforme senza download diretto
- export `.xlsx` nativo multi-sheet (Utenti, Progetti, Economico)

## 10) UI sito più funzionale (meno "app-like")
Implementato (baseline):
- dashboard web responsive a 2 colonne
- card analytics più dense
- tabella operativa team su layout desktop

Step successivo prioritario:
1. layout desktop 12-col completo anche per tutte le pagine secondarie
2. tabella operativa con sorting/filter persistenti (stato filtri)
3. quick actions in header sticky con CTA contestuali
