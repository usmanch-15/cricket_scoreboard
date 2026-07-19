# 🏏 Cricket Scoreboard

A live cricket scoreboard app built with Flutter, featuring an immersive
LED stadium-style theme. Track full ball-by-ball scoring, batting and
bowling statistics, match history, and post-match summaries — including
Man of the Match, top scorers, and top wicket-takers — all synced securely
to the cloud with zero login required.

---

## ✨ Features

- **Ball-by-ball scoring** — runs, wides, no-balls, byes, leg byes, and
  wickets, with full ICC strike-rotation rules applied automatically
- **Live match state** — current run rate, required run rate, overs
  remaining, and a real-time "this over" ball strip
- **Full scorecards** — batting and bowling stats per player, updated
  live as the match progresses
- **Ball-by-ball commentary log** — scroll through the entire innings
  from the first ball to the last
- **Post-match summary** — Man of the Match, best batting and bowling
  performances, top scorers, and top wicket-takers
- **Undo support** — reverse the last scoring action at any point
- **Match history** — every match is saved automatically and can be
  resumed or reviewed later
- **No login required** — each device is identified anonymously and
  securely, with all data scoped exclusively to that device

---

## 🛠 Tech Stack

| Layer          | Technology                                      |
|-----------------|--------------------------------------------------|
| Framework       | Flutter / Dart                                   |
| Backend         | Supabase (PostgreSQL + Anonymous Auth)           |
| Local storage   | `shared_preferences` (stores the device's current match ID) |
| Security        | Row Level Security (RLS) — every match is scoped to the device that created it |

---

## 🚀 Getting Started

### 1. Clone the repository and install dependencies

```bash
git clone https://github.com/usmanch-15/cricket_scoreboard.git
cd cricket_scoreboard
flutter pub get
```

### 2. Set up Supabase

1. Create a free project at [supabase.com](https://supabase.com).
2. Open the **SQL Editor** and run `supabase/schema.sql`. This creates the
   `cricket_matches` table along with Row Level Security policies that
   scope every row to the device that created it.
3. Go to **Authentication → Sign In / Providers** and enable
   **Anonymous Sign-Ins**. This gives each device a stable, secure
   identity without requiring the user to log in.

### 3. Configure the app

Open `lib/config/supabase_config.dart` and fill in your project's URL and
anon (public) key, found under **Project Settings → API** in your
Supabase dashboard.

> The anon key is safe to commit — it is designed to be public. Actual
> data access is enforced server-side by Row Level Security.

### 4. Run the app

```bash
flutter run
```

---

## 🧪 Testing

```bash
flutter test
```

The test suite covers the core scoring engine in
`lib/models/match_state.dart`, including:

- Strike rotation on odd runs, wides, and no-balls
- Wide, no-ball, bye, and leg-bye handling
- Wicket recording (including run-outs at either end)
- Over and innings completion logic
- Undo/redo state integrity
- Full save/load (JSON) round-trip correctness

---

## 📁 Project Structure
