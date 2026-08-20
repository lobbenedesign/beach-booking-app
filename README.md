# 🏖️ Beach Manager

**[🇬🇧 Read this in English](README.en.md)**

Prototipo funzionale di piattaforma di gestione stabilimento balneare: prenotazione ombrelloni con motore prezzi stagionale, dashboard gestore con mappa live, modulo ristorante (tavoli, menu, prenotazioni), e un marketplace di servizi extra a consumo (bar, noleggi, servizi in spiaggia) ordinabili in tempo reale dall'app cliente.

> **Stato del progetto:** prototipo/demo tecnico, non un prodotto pronto per la produzione. Vedi [Limiti attuali](#limiti-attuali) prima di valutarlo per un uso reale.

---

## Perché questo progetto

Tra il 2020 e la fine del 2022 ho lavorato in un'azienda IT che sviluppava un sistema di prenotazione per stabilimenti balneari e il relativo gestionale per l'operatore. Sono entrato nel team quando il prodotto aveva già generato circa 300.000€ di transato nei due anni precedenti. Analizzando a fondo il sistema esistente ho identificato i limiti dell'idea originale e proposto un ampliamento delle funzionalità verso un mercato più ampio dello stesso settore — un lavoro che nei miei primi mesi contribuì a una crescita del transato fino a 3.600.000€, e che nei due anni successivi arrivò a superare i 4.600.000€.

Questo progetto nasce proprio in quei primi mesi di collaborazione: un prototipo Flutter per dimostrare che una tecnologia allora nascente potesse essere la soluzione per portare più modernità a un sistema pensato solo come applicazione web, dandogli finalmente un'app multipiattaforma reale. Quella collaborazione si è conclusa alla fine del 2022; da allora ho continuato a sviluppare e ampliare il progetto in autonomia, per dargli la forma completa che vedi oggi — un sistema che copre non solo la prenotazione della singola postazione, ma l'intero ecosistema di un vero stabilimento balneare: ristorante, bar, noleggi, servizi accessori, tutto integrato in un'unica piattaforma per gestore e cliente.

## Screenshot

<p align="center">
  <img src="docs/screenshots/01-login.png" width="48%" alt="Login" />
  <img src="docs/screenshots/02-customer-home.png" width="48%" alt="Home cliente" />
</p>

## Cosa dimostra questo progetto

### Percorso cliente: prenotazione ombrellone

Selezione date → scelta pacchetto → mappa con disponibilità in tempo reale.

<p align="center">
  <img src="docs/screenshots/03-booking-packages.png" width="48%" alt="Scelta pacchetto" />
  <img src="docs/screenshots/04-booking-map.png" width="48%" alt="Mappa selezione ombrellone" />
</p>

### Motore prezzi

- Pacchetti multipli per postazione (es. ombrellone + 2 lettini, oppure ombrellone + lettino king size + sedia regista), ciascuno con prezzo indipendente
- Prezzi differenziati per giorno feriale / venerdì / sabato / domenica, configurabili indipendentemente
- Sotto-periodi stagionali creabili liberamente dal gestore (es. "Bassa Stagione" 20 maggio–15 giugno), ognuno con il proprio listino — con blocco delle sovrapposizioni tra stagioni
- Prezzi differenziati anche per fila/zona dell'ombrellone

<p align="center">
  <img src="docs/screenshots/10-pricing-seasons.png" width="70%" alt="Gestione stagioni" />
</p>

### Editor mappa (spiaggia e ristorante)

- Editor visuale drag-and-drop con undo/redo completo (spostamento, ridimensionamento, rotazione, eliminazione, operazioni in blocco)
- Rilevamento sovrapposizioni: non è possibile trascinare una postazione sopra un'altra già occupata
- Selezione multipla con allineamento e distribuzione automatica
- Generazione guidata di griglie di postazioni/tavoli, gestione zone, sfondo personalizzato

<p align="center">
  <img src="docs/screenshots/09-beach-map-editor.png" width="48%" alt="Editor mappa spiaggia" />
  <img src="docs/screenshots/14-restaurant-map-editor.png" width="48%" alt="Editor mappa tavoli ristorante" />
</p>

### Dashboard gestore

- Mappa live dello stabilimento con stato in tempo reale per data singola o intervallo (libera / occupata / stagionale / last-minute / check-in effettuato)
- Cross-reference automatico: il gestore vede se un cliente ha prenotazioni anche nell'altro modulo (spiaggia ↔ ristorante)
- Ruoli separati: gestore spiaggia e gestore ristorante hanno accessi e dashboard indipendenti

<p align="center">
  <img src="docs/screenshots/08-beach-dashboard.png" width="48%" alt="Dashboard spiaggia" />
  <img src="docs/screenshots/13-restaurant-dashboard.png" width="48%" alt="Dashboard ristorante" />
</p>

### Modulo ristorante

- Tavoli, turni pranzo/cena, note allergie, conto e pagamento
- Menu diviso per categoria (antipasti, pizze, primi, secondi, dessert) con foto, descrizione, allergeni e note su ordine minimo

<p align="center">
  <img src="docs/screenshots/12-menu-management.png" width="48%" alt="Gestione menu" />
  <img src="docs/screenshots/05-menu-order.png" width="48%" alt="Ordine dall'app cliente" />
</p>

### Marketplace servizi extra

- Bar, noleggi a tempo (canoa singola/doppia, barca a motore), campo beach tennis, servizi all'ombrellone (massaggi, aperitivo) — tutti con lo stesso motore di prezzi stagionale
- Ordine dall'app cliente, ricezione istantanea da parte del gestore con badge di notifica

<p align="center">
  <img src="docs/screenshots/06-extra-services-customer.png" width="48%" alt="Servizi extra lato cliente" />
  <img src="docs/screenshots/11-extra-services-admin.png" width="48%" alt="Catalogo servizi extra lato gestore" />
</p>

### Prenotazione tavolo ristorante (app cliente)

<p align="center">
  <img src="docs/screenshots/07-restaurant-booking-customer.png" width="70%" alt="Prenotazione tavolo ristorante" />
</p>

## Stack tecnico

- **Flutter Web** (Dart)
- **Provider** per la gestione dello stato
- **go_router** per il routing
- Persistenza locale via `shared_preferences` (demo, non un backend reale)

## Come avviarlo

```bash
flutter pub get
flutter run -d chrome
```

### Account demo

| Ruolo | Email | Password |
|---|---|---|
| Cliente / Gestore spiaggia | `demo@beach.com` | qualsiasi |
| Gestore ristorante | `ristorante@beach.com` | qualsiasi |

## Limiti attuali

Questo è un prototipo tecnico, non un prodotto pronto per la produzione:

- **Nessun backend**: tutti i dati vivono in memoria e in `localStorage` del browser — non c'è sincronizzazione multi-dispositivo né multi-utente reale
- **Autenticazione demo**: il login accetta qualsiasi password, non è un sistema di sicurezza reale
- **Pagamenti simulati**: l'integrazione Stripe/PayPal è mockata, nessuna transazione reale avviene
- **Copertura test**: buona sulla logica di business (motore prezzi, prenotazioni, ordini), assente sui test end-to-end/UI

## Licenza

**Tutti i diritti riservati.** Il codice è pubblico e consultabile a scopo dimostrativo/portfolio, ma non è concesso alcun diritto di copia, modifica, uso o distribuzione senza autorizzazione scritta dell'autore. Vedi [LICENSE](LICENSE).

Sei un'azienda o un recruiter interessato a questo progetto, a una licenza d'uso commerciale, o a collaborare/assumere l'autore? Contattami su [LinkedIn](https://www.linkedin.com/in/giuseppe-lobbene-39566a5b/) o via email: [giuseppelobbene@gmail.com](mailto:giuseppelobbene@gmail.com).
