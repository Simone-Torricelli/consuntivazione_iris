# IRIS Consuntivazione - Recap Completo per Slide PPT

## 1) Executive Summary
IRIS Consuntivazione e una piattaforma Flutter (mobile + web) per gestire la consuntivazione giornaliera delle ore di lavoro su progetti.

Obiettivo principale:
- ridurre errori e ritardi nella compilazione timesheet
- aumentare visibilita per Team Lead, Manager e Admin
- avere reporting operativo in tempo reale su team, progetti e carico ore

Valore business:
- controllo puntuale delle 8h giornaliere
- migliore governance dei progetti
- dati affidabili per pianificazione, billing e performance

---

## 2) Problema che risolve
Scenario tipico:
- ogni developer lavora su uno o piu progetti al giorno
- compilazione spesso frammentata o in ritardo
- poca trasparenza su allocazione ore e saturazione team
- difficolta a controllare ownership progetto e gerarchie team

IRIS risolve con:
- inserimento rapido ore (step da 0.5h)
- validazioni automatiche
- dashboard per ruolo
- storico e trend per persona, team e progetto

---

## 3) Cosa fa oggi l'app

### 3.1 Consuntivazione giornaliera
- inserimento/modifica/cancellazione ore
- range ore per entry: 0.5h - 8h
- limite giornaliero totale: max 8h
- supporto progetto ferie/permessi
- note opzionali per ogni entry

### 3.2 Calendario e riepiloghi
- vista calendario mensile
- dettaglio giornaliero ore registrate
- aggregazioni per progetto e per periodo
- reminder giornaliero (giorni lavorativi)

### 3.3 Dashboard per ruoli
- Admin/Manager: visione completa dei progetti
- Team Lead: visione dei progetti di ownership
- Developer: visione dei progetti assegnati
- accesso ai dettagli persona per tutti gli utenti autenticati

### 3.4 Team e gerarchie
- struttura Manager -> Team Lead -> Developer
- sezione dedicata "Il mio team"
- allineamento robusto relazioni anche con dati legacy (match per id/email)

### 3.5 Grafici e monitoraggio
- andamento ore (trend)
- distribuzione ore per progetto (pie chart)
- top contributor, completion e indicatori team

### 3.6 Gamification e UX
- streak giorni perfetti
- XP mensile e card reward
- evidenza giorno stipendio (ultimo giorno lavorativo del mese, con festivi)
- UI moderna con animazioni e transizioni

### 3.7 Esperienza Web
- dashboard web responsive ottimizzata
- shell web dedicata con navigazione laterale
- mantenimento del linguaggio visivo dell'app mobile

---

## 4) Ruoli e permessi (stato attuale)

Admin
- gestione completa utenti e progetti
- visibilita totale su dati e team
- puo assegnare gerarchie

Manager
- vede tutti i progetti
- puo modificare assegnazione Team Lead da dettaglio persona (vincolata da regole)
- monitora TL e developer nel proprio perimetro

Team Lead
- vede solo i progetti di cui e owner
- vede chi lavora sui propri progetti
- ha dashboard con grafici andamento ore e pie progetti

Developer
- vede solo i progetti assegnati
- consuntiva solo su progetti consentiti
- accede ai dettagli persona in sola consultazione

---

## 5) Architettura tecnica

Stack:
- Flutter + Dart
- Provider per state management
- Firebase Auth (sessione persistente)
- Cloud Firestore (users, projects, timesheet_entries)
- fallback locale (SharedPreferences) se Firebase non disponibile
- fl_chart per analytics

Pattern dati:
- stream realtime Firestore per aggiornamenti live UI
- pull-to-refresh globale per refresh manuale
- parser robusto per compatibilita dati legacy

Collezioni principali:
- users/{userId}
- projects/{projectId}
- timesheet_entries/{entryId}

---

## 6) KPI e valore operativo
KPI suggeriti per presentazione:
- completion rate timesheet giornaliero/mensile
- ore non consuntivate per team
- saturazione media per developer
- distribuzione ore per progetto
- giorni perfetti (8h complete)
- tempo medio di compilazione dopo reminder

Benefici attesi:
- meno ritardi e meno errori di rendicontazione
- reporting manageriale piu rapido
- migliore capacity planning su team/progetti

---

## 7) Gap e opportunita di miglioramento

### 7.1 AI (priorita alta)
1. Suggerimento automatico consuntivo
- AI propone ripartizione ore in base a storico utente/progetto
- click unico per confermare o correggere

2. Rilevazione anomalie
- segnalazione pattern anomali (ore incoerenti, progetti fuori profilo, picchi anomali)

3. Forecasting carico team
- previsione saturazione a fine mese per team/progetto

4. Smart reminder personalizzati
- reminder dinamici in base a comportamento utente (orario migliore, frequenza)

5. Assistente testuale interno
- "mostrami progetti sotto target" / "chi ha meno ore questa settimana"

### 7.2 Integrazione Commessa GECO (priorita alta)
Proposta funzionale:
- associare ogni entry a una commessa GECO (codice + descrizione)
- supportare relazione Progetto -> Commessa e/o Entry -> Commessa
- validare compilazione commessa obbligatoria su progetti fatturabili
- esportazione report ore per commessa

Proposta dati (nuovi campi/collezioni):
- collection `commesse`
  - id, codice, descrizione, cliente, stato, dataInizio, dataFine
- in `projects`
  - commessaId (opzionale o obbligatorio per tipo progetto)
- in `timesheet_entries`
  - commessaId (se serve granularita massima)

Beneficio:
- allineamento diretto con controllo economico/contabile e processi GECO

### 7.3 Evoluzioni prodotto
- export avanzato (Excel/PDF)
- filtri avanzati dashboard
- audit log modifiche critiche
- workflow approvazione timesheet (TL/Manager)
- notifiche web push
- offline-first con sync differita

---

## 8) Roadmap proposta (90 giorni)

Fase 1 (0-30 gg)
- stabilizzazione web + hardening permessi
- integrazione base commesse (modello dati + CRUD)
- dashboard filtri per commessa

Fase 2 (31-60 gg)
- AI suggestion per consuntivazione
- anomaly detection base
- export report per progetto/commessa/team

Fase 3 (61-90 gg)
- forecasting carico team
- assistente query testuali
- workflow approvazione consuntivi

---

## 9) Rischi e mitigazioni
Rischio: qualita dati storici non uniforme
- mitigazione: migration script + validazioni input

Rischio: complessita permessi multi-ruolo
- mitigazione: policy centralizzate Firestore + test ruoli

Rischio: adozione bassa da parte utenti
- mitigazione: UX semplice, autofill AI, reminder intelligenti

Rischio: disallineamento con processi amministrativi
- mitigazione: integrazione commessa GECO e report condivisi

---

## 10) Scaletta PPT pronta (12 slide)

Slide 1 - Titolo e vision
- "IRIS Consuntivazione: controllo ore smart per team e management"

Slide 2 - Problema
- frammentazione compilazione, poca visibilita, errori reporting

Slide 3 - Soluzione
- app unica mobile+web per consuntivazione, controllo e analytics

Slide 4 - Funzionalita core
- timesheet, calendario, reminder, regole 8h, ferie

Slide 5 - Ruoli e governance
- Admin / Manager / TL / Developer + permessi

Slide 6 - Dashboard e analytics
- trend ore, pie progetti, team overview

Slide 7 - Architettura
- Flutter + Firebase + realtime stream + fallback locale

Slide 8 - UX e gamification
- streak, XP, reward, giorno stipendio, animazioni

Slide 9 - Benefici e KPI
- completion rate, qualita dato, controllo saturazione

Slide 10 - Evoluzione AI
- suggerimenti ore, anomalie, forecasting, assistente query

Slide 11 - Integrazione GECO
- commessa su progetto/entry, report economici

Slide 12 - Roadmap e next step
- piano 30/60/90 giorni + decisioni richieste

---

## 11) Messaggi chiave da portare in presentazione
- Non e solo un timesheet: e una piattaforma di controllo operativo.
- La web dashboard abilita governance manageriale in tempo reale.
- L'integrazione GECO trasforma il dato ore in valore economico.
- L'AI riduce attrito utente e migliora affidabilita del dato.

---

## 12) Decisioni richieste al management
1. Priorita integrazione commessa GECO (si/no e livello di dettaglio)
2. Priorita roadmap AI (quick win vs progetto esteso)
3. Definizione KPI ufficiali da monitorare mensilmente
4. Go-live plan (pilota su un team o rollout completo)
5. Stima economica per progetto, costo per ora, stima consumata...
6. Mettere su .env le cose di Firebase
