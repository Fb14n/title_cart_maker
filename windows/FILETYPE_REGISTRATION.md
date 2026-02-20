# Title Card Maker - Dateityp-Registrierung

## Automatische Registrierung (Windows)

Um .tcmaker-Dateien automatisch mit der App zu öffnen:

### Option 1: Registry-Datei (Entwicklung)
1. Öffne `windows/register_filetype.reg`
2. Passe den Pfad zur .exe-Datei an (Zeile 13)
3. Doppelklick auf die Datei
4. Bestätige die Sicherheitsabfrage

### Option 2: Manuell im Explorer
1. Rechtsklick auf eine .tcmaker-Datei
2. "Öffnen mit" → "Andere App auswählen"
3. Navigiere zu `build\windows\x64\runner\Debug\title_card_maker.exe`
4. Haken bei "Immer diese App verwenden"

### Option 3: Installation
Bei einer richtigen Installation sollte der Installer die Registrierung übernehmen.
Dies kann mit Tools wie Inno Setup oder NSIS automatisiert werden.

## Kommandozeilenargumente

Die App unterstützt das Öffnen von Dateien beim Start:
```
title_card_maker.exe "C:\path\to\project.tcmaker"
```

## Dateityp-Details

- **Erweiterung**: `.tcmaker`
- **MIME-Type**: `application/x-titlecardmaker`
- **Beschreibung**: Title Card Maker Project
- **Format**: JSON-basiert
