# Bard-ish

A minimalist, void-themed note-taking app built with Flutter and powered by Hive.
Simplicity is the ultimate sophistication.

## Features

* **Markdown Support**
  Real-time preview with instant rendering.

* **Local-First**
  Notes are stored locally using Hive.
  No cloud services, no accounts, no external dependencies.

* **Void Aesthetic**
  Deep dark mode designed for focus and minimal visual noise.

* **Fast Search**
  Instant, full-text search across all notes.

## Installation

Download the latest APK from the Releases page:
[https://github.com/LinearJet/bard-ish/releases](https://github.com/LinearJet/bard-ish/releases)

## Building from Source

1. **Install Flutter**
   Ensure you are using the latest stable SDK.

2. **Clone the Repository**

   ```bash
   git clone https://github.com/LinearJet/bard-ish.git
   cd bard-ish
   ```

3. **Install Dependencies**

   ```bash
   flutter pub get
   ```

4. **Generate Required Files**

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the App**

   ```bash
   flutter run
   ```

## Credits & Inspiration

Bard-ish is a spiritual successor and open-source homage to the app Bardo.
It aims to capture the same clean, focused vibe while remaining lightweight and fully local.

## License

See the `LICENSE` file in the repository.
