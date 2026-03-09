# Apple Platform Security Daily

A daily digest of Apple Platform Security topics, one section at a time.

*Based on the [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web) (January 2026 edition)*

Built for [TRMNL](https://usetrmnl.com) devices, but `today.json` is just JSON – use it however you like.

## How it works

A GitHub action runs a Swift script that selects today's topic each day at midnight UTC. The workflow deterministically selects an entry from [`blurbs.json`](blurbs.json) by mapping a hash of the current date to a blurb index. Each blurb lines up one-to-one with each section of the [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web) and writes it to [`today.json`](today.json).

- **[`blurbs.json`](blurbs.json)** – 70 entries covering every section in the guide, each with `chapter`, `section`, `blurb`, and `keywords`
- **[`pick_blurb.swift`](pick_blurb.swift)** – Swift script that hashes today's date, maps it to an index, and writes the result to `today.json`
- **[`.github/workflows/daily-blurb.yml`](.github/workflows/daily-blurb.yml)** – runs the script daily and commits the output

## today.json format

```json
{
  "blurb": "...",
  "chapter": "System security",
  "date": "2026-03-09",
  "keywords": ["keyword1", "keyword2"],
  "section": "Section name"
}
```

> [!NOTE]
> The blurbs in `blurbs.json` are AI-generated using the Apple Platform Security Guide as source material. They should be verified against the [official documentation](https://support.apple.com/guide/security/welcome/web) before being relied upon for security-critical decisions.
