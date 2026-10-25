# Apple Platform Security Daily

Picks one topic a day from the Apple Platform Security Guide and publishes it as `today.json`. The main consumer is a TRMNL recipe ("Apple Platform Security Daily") that polls the raw GitHub URL for that file.

## How it fits together

- `blurbs.json`: the source list, one entry per section of the guide. Each entry has `chapter`, `section`, `blurb` and `keywords`.
- `pick_blurb.swift`: picks today's entry, adds a `date` field, and writes `today.json`.
- `.github/workflows/daily-blurb.yml`: runs the script once a day (scheduled for midnight UTC, but GitHub usually starts it a few hours late) and commits `today.json` to `main` as github-actions[bot].
- `today.json`: what TRMNL reads, from `https://raw.githubusercontent.com/pbraccia/apple-platform-security-daily/refs/heads/main/today.json`.
- `assets/trmnl-title-bar-image.png`: the icon shown in the TRMNL title bar, also loaded from the raw GitHub URL.
- `apple-platform-security-guide.pdf`: the source PDF. It's gitignored, so it only exists locally.

The TRMNL markup doesn't live in this repo. It's edited in the TRMNL web editor (plugin 257916).

## Things to know before changing anything

- **The bot commits to `main` every day.** Pull before you start, or your local `main` will be behind.
- **Don't hand-edit or commit `today.json`.** The workflow owns it. If you run the script to test something, run `git restore today.json` afterwards.
- **The picker has to be deterministic.** Every run for the same date must produce the same file, byte for byte:
  - It goes through every blurb once per cycle in a shuffled order, then reshuffles. The shuffle uses a seeded generator and a hand-written Fisher-Yates loop. Don't swap in Swift's `shuffled()`, because its algorithm isn't guaranteed to stay the same between Swift versions.
  - The JSON is written with `.sortedKeys`. Without it, the key order changes on every run, Git sees a change every time, and the workflow's skip-if-unchanged check stops working.
- **Changing the number of blurbs reshuffles the order** from that day on. That's expected; topics still won't repeat within a cycle.
- **Keep the `today.json` fields as they are.** The TRMNL markup uses `chapter`, `section`, `blurb` and `date`. Renaming or removing any of them breaks the screen for everyone who installed the recipe. `keywords` isn't shown at the moment.

## Testing

Pass a date to see what any day would show:

```bash
swift pick_blurb.swift 2027-01-01
```

This overwrites `today.json`, so restore it afterwards (`git restore today.json`), or copy the script and `blurbs.json` into a temp folder and run it there.

There are no automated tests and no CI on pull requests. If you change the picker, check it over a long range of dates: every full cycle should contain each blurb exactly once, nothing should repeat on consecutive days, and running the same date twice should give identical output.

## Writing blurbs

- The blurbs were AI-generated from the guide, and the README says so. Check new or edited ones against the guide.
- Keep them about the length of the existing ones (roughly 350–750 characters). TRMNL's content limiter shrinks long text and then cuts it off, especially in the smaller mashup views.
- Up to five `keywords` per entry.

## Style

- Commit messages are short and plain, like "Updated title bar image" or "Show every blurb once before repeating", with a sentence or two of explanation in the body if needed.
- Comments in the Swift script are short and explain why, not what. Keep that tone.
