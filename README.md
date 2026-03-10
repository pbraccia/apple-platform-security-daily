# Apple Platform Security Daily

A daily selection of interesting Apple Platform Security topics, in JSON format.

*Based on the [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web) (January 2026 edition)*

Built for display on [TRMNL](https://usetrmnl.com) devices, but `today.json` is just JSON – you can use it however you'd like.

## How it works

Each day at midnight UTC, a Github action runs a Swift script that selects the day's topic. The workflow deterministically selects an entry from [`blurbs.json`](blurbs.json) by mapping a hash of the current date to a blurb index number, then writes its contents to [`today.json`](today.json). One blurb exists for each section in the [Apple Platform Security Guide](https://support.apple.com/guide/security/welcome/web).

- **[`today.json`](today.json)** – the current day's entry
- **[`blurbs.json`](blurbs.json)** – the collection of entries covering each section in the guide, including its relevant `chapter`, `section`, and `keywords`
- **[`pick_blurb.swift`](pick_blurb.swift)** – Swift script that hashes today's date, maps it to an index, and writes the selected blurb to `today.json`
- **[`.github/workflows/daily-blurb.yml`](.github/workflows/daily-blurb.yml)** – runs the script daily and commits the output


> [!NOTE]
> The blurbs in `blurbs.json` are AI-generated using the Apple Platform Security Guide as source material. They should be verified against the [official documentation](https://support.apple.com/guide/security/welcome/web) before being relied upon for security-critical decisions.

## today.json format

```json
{
  "date": "2026-01-24",
  "chapter": "Hardware security and biometrics",
  "section": "The Secure Enclave",
  "blurb": "The Secure Enclave is a dedicated security coprocessor ...",
  "keywords": ["sepOS", "SKP", "UID", "mailbox interface", "key wrapping"]
}
```

---

*Apple, Swift, iOS, iPadOS, macOS, tvOS, watchOS, and visionOS are trademarks of Apple Inc., registered in the U.S. and other countries. This project is not affiliated with or endorsed by Apple Inc.*
