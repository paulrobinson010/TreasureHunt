# TreasureHunt

Lets get the kids out and about!

**X-Marks** (…the spot!) — a native SwiftUI iOS app for making and playing
real-world GPS treasure hunts. The repo, bundle id, `treasurehunt://` scheme
and `.treasurehunt` file extension keep their original names; the user-facing
brand is X-Marks and the site lives at x-marks.robbo-online.uk.
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

- **Universal link (recommended)** — `https://x-marks.robbo-online.uk/hunt/?d=…`
  is tappable in iMessage/WhatsApp and opens straight into the app. Phones
  without the app land on the website's fallback page instead.
- **`.treasurehunt` file** — shared as an attachment; tapping it opens the app.
- **Import button** — paste a whole message into the app and it fishes the
  link out. Legacy `treasurehunt://` links still work here too.

## Website & universal links

The site at https://x-marks.robbo-online.uk lives in `docs/` and deploys
via GitHub Actions (`.github/workflows/pages.yml`) on every push to `main`.
It serves the landing page, the hunt-link fallback page, the privacy policy
(`/privacy/`), and the `apple-app-site-association` file that makes universal
links work.

After changing the domain, the association file, or the bundle id, delete +
reinstall the app on each phone — iOS validates associated domains at install
time. Development builds fetch the association file straight from the site
(the entitlement's `?mode=developer` suffix plus the phone's Associated
Domains Development toggle); App Store/TestFlight builds go through Apple's
CDN, which can lag a new domain by a few hours.

## Progress updates

**Automatic (CloudKit):** hunts created since this feature carry a random
sync token and an AES key inside their encrypted share payload. When a hunter
digs up a point, their found-set is sealed with that key and saved to a
CloudKit *public-database* record named by the token (`ProgressSync.swift`,
modelled on CycleHUD's live tracking) — iCloud stores ciphertext only. The
maker's created-hunt screen polls every 20 s while open and merges all
hunters' finds. Requires the hunter's device to be signed into iCloud;
before shipping to TestFlight/App Store, deploy the CloudKit schema to
Production in the CloudKit Console (the `XMarksProgress` record type is
created automatically on first run in Development).

**Manual fallback:** the hunt map and prize screen keep **Send progress** /
**Tell the hunt maker!** buttons that share an encrypted `/progress/` link;
tapping it on any phone that has the hunt merges the found points in. Also
syncs siblings' copies if they share with each other.

## Look and feel

The theme comes straight from the app icon (see `TreasureHunt/Theme.swift`
and the CSS variables in `docs/`): night navy, water cyan, island lime, sand
gold, and X-marks-the-spot red. The typeface everywhere is **Baloo 2**
(SIL Open Font License) — bundled in the app at `TreasureHunt/Fonts/` and
self-hosted on the website at `docs/assets/fonts/`, so no font CDN is
involved. The app opens with a static launch screen (logo on navy) that hands
over to an animated splash (`SplashView.swift`).

## Demo mode & screenshots (simulator only)

Run the app in the iOS simulator and a **Demo** wand button appears in the
home toolbar (it's compiled out of device builds). Tapping it seeds three
Central Park hunts: one mid-hunt (2/4 found), one solved (prize + confetti
ready), and one "made by me" with a progress report arrived — instant
screenshot material for the site and App Store.

To play the hunt in the simulator, drive the location:

- Quick: Simulator menu → Features → Location → Custom Location…
  (Bethesda Fountain is 40.76593, −73.97106).
- Full walkthrough: add `Demo/CentralParkWalk.gpx` to the Xcode project
  (uncheck target membership), then Debug → Simulate Location → CentralParkWalk
  while running. The blue dot strolls The Mall → Bethesda Fountain →
  Bow Bridge → Belvedere Castle → Alice in Wonderland, finding the two
  remaining points on the way — trail, detector, fanfares, confetti and all.
  Compass heading isn't simulated, so the pointing-buzz is best captured on a
  real phone.

Distances show in the local convention automatically (metres for metric
locales, feet/miles for the US) via MKDistanceFormatter.

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
