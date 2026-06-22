# Tagar 🌸

A nature-inspired messaging app built with Flutter and Supabase.

## Features

- Real-time messaging via Supabase Realtime
- Add contacts using QR codes or tagar IDs
- Friend request system
- Cross-platform (Android, Windows)

## Tech Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Backend:** Supabase (Auth, Database, Realtime)
- **Local Storage:** SQLite
- **QR:** qr_flutter + mobile_scanner

## Setup

1. Run `flutter pub get`
2. Create a `.env` file in the project root with your Supabase credentials:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

3. Apply the SQL migrations from `migrations/` to your Supabase project
4. Run `flutter run`

## License

All Rights Reserved. See `LICENSE` for details.
