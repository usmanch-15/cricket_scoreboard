# Cricket Scoreboard

A live cricket scoreboard app built with Flutter, featuring an LED stadium-style
theme. Tracks full ball-by-ball scoring, batting/bowling stats, match history,
and post-match summaries (Man of the Match, top scorers, top wicket-takers).

## Tech stack
- Flutter / Dart
- Supabase (Postgres + anonymous auth) for cloud-synced match state
- `shared_preferences` for storing the local device's current match id

## Setup

1. Clone the repo and get dependencies:
```bash
   flutter pub get
```

2. Create a Supabase project at [supabase.com](https://supabase.com).

3. Run `supabase/schema.sql` in the Supabase SQL Editor. This creates the
   `cricket_matches` table with Row Level Security policies scoping every
   row to the device that created it.

4. In Supabase Dashboard → Authentication → Sign In / Providers, enable
   **Anonymous Sign-Ins**. The app uses this to give each device a stable
   identity without requiring login.

5. Fill in `lib/config/supabase_config.dart` with your project's URL and
   anon (public) key — found in Supabase Dashboard → Project Settings → API.
   The anon key is safe to commit; it's meant to be public and access is
   enforced server-side by RLS.

6. Run the app:
```bash
   flutter run
```

## Testing

```bash
flutter test
```

Covers the core scoring rules in `lib/models/match_state.dart`: strike
rotation, wides/no-balls/byes, wickets, over/innings completion, and
undo/redo state integrity.

## Project structure

- `lib/models/` — `MatchState` (all scoring logic) and supporting data models
- `lib/screens/` — one screen per app stage (setup → toss → openers → match → result)
- `lib/services/supabase_service.dart` — Supabase read/write, scoped per device
- `lib/widgets/`, `lib/dialogs/`, `lib/theme/` — shared UI pieces
