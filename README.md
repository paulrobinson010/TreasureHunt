# TreasureHunt

Lets get the kids out and about!

A native SwiftUI iOS app for making and playing real-world GPS treasure hunts.
A parent drops points on a map, adds a name and a prize, and sends the hunt to
the kids over iMessage or WhatsApp. The kids hunt the points down with a fuzzy
map, a compass, and a phone that buzzes when they point it the right way.

## How it plays

1. **Make a hunt** — tap points on the map, give the hunt a name and a prize
   description, save.
2. **Send it** — share it from the app via the normal iOS share sheet. No
   server involved: the whole hunt is encoded into the file or link itself.
3. **Preview** — the kids see the hunt's rough area (a heavily blurred circle
   near the point closest to them) before they start.
4. **Hunt** — the map shows a 50 m fuzzy circle per point. The circles are
   deliberately off-centre so their middle never gives the spot away.
5. **Get warm** — inside 25 m of a point the app pings and a compass appears.
   Point the phone at the treasure and it buzzes and pings; point away and it
   stops.
6. **Find it** — reach the point and it pings, the map gets a green success
   marker.
7. **Win** — find every point and the prize is revealed. Hunt solved!

## Building and running

- **Requirements:** Xcode 16 or newer, iOS 17+ device.
- Open `TreasureHunt.xcodeproj`, select the TreasureHunt target, and set your
  Apple developer team under Signing & Capabilities (change the bundle id if
  Xcode complains it's taken).
- **Run it on a real iPhone.** The simulator has no GPS walk-around, no
  compass, and no haptics — the whole game loop needs a real device outdoors.

## Adding the app icon

Save the logo as a 1024×1024 PNG (no transparency, square — iOS rounds the
corners itself) named `AppIcon.png` and drop it into
`TreasureHunt/Assets.xcassets/AppIcon.appiconset/`. That's it — the catalog
already expects that filename. Until the file lands, Xcode shows a harmless
missing-file warning.

## Sharing between phones

Every phone playing needs the app installed (until it's on TestFlight or the
App Store, that means building it onto each kid's phone from Xcode).

Hunts are sent serverlessly — the whole hunt travels inside the link or file
itself as **encrypted ciphertext** (JSON → zlib → AES-256-GCM, with the key
derived in-app by hashing an app secret with SHA-256, see
`TreasureHunt/Models/HuntCrypto.swift`). Messaging services, link previews and
snoopers see only gibberish; only the app can decrypt it. Since the key ships
inside the app this is transport protection between copies of the app, not
end-to-end secrecy from someone who reverse-engineers the binary. On-device,
the hunt store is written with iOS complete file protection.

Three ways a hunt can arrive, all handled automatically:

- **Universal link (recommended)** — `https://treasurehunt.robbo-online.uk/hunt/?d=…`
  is tappable in iMessage/WhatsApp and opens straight into the app. Phones
  without the app land on the website's fallback page instead.
- **`.treasurehunt` file** — shared as an attachment; tapping it opens the app.
- **Import button** — paste a whole message into the app and it fishes the
  link out. Legacy `treasurehunt://` links still work here too.

## Website & universal links

The site at https://treasurehunt.robbo-online.uk lives in `docs/` and deploys
via GitHub Actions (`.github/workflows/pages.yml`) on every push to `main`.
It serves the landing page, the hunt-link fallback page, the privacy policy
(`/privacy/`), and the `apple-app-site-association` file that makes universal
links work.

**One manual step remains:** edit
`docs/.well-known/apple-app-site-association` and replace `TEAMID` with your
Apple Team ID (Xcode → target → Signing & Capabilities, under your team name;
or developer.apple.com → Membership). If Xcode made you change the bundle id,
update it there too. Then push, and delete + reinstall the app on each phone —
iOS fetches the association file at install time.

## Tuning the game

All gameplay thresholds live in `TreasureHunt/Models/Config.swift`:

| Constant | Default | Meaning |
|---|---|---|
| `displayRadius` | 50 m | Fuzzy circle drawn per unfound point |
| `zoneRadius` | 25 m | Distance that wakes the compass |
| `foundRadius` | 3 m | Distance that counts as "found" |
| `onTargetTolerance` | 20° | How exactly you must point before it buzzes |
| `previewRadius` | 150 m | Rough area circle in the pre-hunt preview |

The spec said "within a meter" for finding a point, but phone GPS rarely
resolves better than ~3 m even outdoors, so `foundRadius` defaults to 3 m to
keep the game winnable. Drop it to 1–2 m if you want it harder.

## Privacy

No accounts, no backend, no analytics. Hunts live in JSON on each device and
travel only inside the files/links you choose to share.
