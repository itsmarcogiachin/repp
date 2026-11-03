# Repp

App iOS per registrare e seguire le sessioni in palestra: schede, sessione con timer di riposo, sostituzioni solo per oggi, macchine, note, qualità delle serie e storico.

- **Interfaccia:** SwiftUI, iOS 17 o successivo, solo iPhone
- **Dati:** SwiftData, salvati solo sul telefono. Nessun account e nessun server nella v1.
- **Progetto Xcode:** generato con [XcodeGen](https://github.com/yonaskolb/XcodeGen) da `project.yml`. Il file `Repp.xcodeproj` non è nel repository.

## Struttura

```
project.yml            Definizione del progetto Xcode
Repp/
  App/                 Punto di ingresso e configurazione del database locale
  Theme/               Colori, argento metallico, font
  Models/              Modelli SwiftData (macchine, esercizi, schede, sessioni, serie, note)
  Data/                Dati di partenza: macchine e attrezzi della palestra
  Views/               Schermate
  Resources/           Asset (icona, colore d'accento)
```

## Primo avvio sul Mac

1. Installa Xcode dal Mac App Store e aprilo una volta per completare l'installazione.
2. Installa XcodeGen con Homebrew:
   ```sh
   brew install xcodegen
   ```
3. Clona il repository, o aggiorna la cartella se l'hai già:
   ```sh
   git clone https://github.com/itsmarcogiachin/repp.git Repp
   cd Repp
   ```
4. Genera il progetto e aprilo:
   ```sh
   xcodegen generate
   open Repp.xcodeproj
   ```
5. In Xcode seleziona il target **Repp**, poi la scheda **Signing & Capabilities**. Come **Team** scegli il tuo Apple ID (Xcode › Settings › Accounts per aggiungerlo).
6. Collega l'iPhone con il cavo, sbloccalo e accetta "Considera attendibile questo computer".
7. Sull'iPhone attiva la modalità sviluppatore: Impostazioni › Privacy e sicurezza › Modalità sviluppatore, poi riavvia.
8. In Xcode scegli l'iPhone come destinazione e premi Run (⌘R).
9. Al primo avvio iOS può bloccare l'app: Impostazioni › Generali › VPN e gestione dispositivi, poi autorizza il tuo profilo sviluppatore.

Con un Apple ID gratuito l'app installata scade dopo 7 giorni: basta ripetere il passo 8. Con l'Apple Developer Program dura un anno.

Ogni volta che aggiungi o sposti file Swift, rilancia `xcodegen generate`.
