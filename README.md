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

## Nothing reports back

There is deliberately no channel for a hunt's creator to learn how hunters are
getting on. Found points live only on the hunter's own device: no progress
links, no CloudKit sync, nothing in the share payload travelling the other
way, and the creator's own screen shows their points without any found-state.

This is a safety property, not an oversight. A hunt's points are real
locations, so "point 3 found at 14:32" is a record of where a child was and
when — the app is built so that record never exists.

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
ready), and one "made by me" — instant
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
| `foundRadius` | 3 m | Distance that starts the dig |
| `maxDigRadius` | 8 m | Ceiling on the dig trigger when GPS is vague |
| `onTargetTolerance` | 20° | How exactly you must point before it buzzes |
| `previewRadius` | 150 m | Rough area circle in the pre-hunt preview |

The spec said "within a meter" for finding a point, but phone GPS rarely
resolves better than ~3 m even outdoors, so `foundRadius` defaults to 3 m to
keep the game winnable. `digRadius(accuracy:)` opens the trigger up to match
the reported GPS uncertainty (capped at `maxDigRadius`), because a phone
reporting ±6 m can never measure a distance under 3 m even standing on the
treasure.

## Grown-up check

Making a hunt (which means placing real-world locations) and opening **My
Crew** (which changes who may send hunts to this phone) sit behind a parental
gate: a multiplication written in words — "seven × twelve" — so it takes
reading as well as arithmetic. A wrong answer re-rolls the sum, so guessing
can't wear it down. One pass unlocks ten minutes of grown-up work, and
backgrounding the app re-locks it. See `ParentGate.swift`.

## Crew: who can send you hunts

Every phone has a hunting identity — a display name plus a Curve25519 signing
key whose private half lives in the Keychain (`HunterIdentity.swift`). Shared
hunts are signed with it, so the recipient can tell a hunt from a known sender
apart from one that merely turned up.

**Sending is just sending.** The handshake happens by itself on the first
hunt: a hunt from someone already in the crew drops straight into the list,
and one from anyone else opens an invite screen naming the sender, where a
grown-up must pass the parental gate to accept. Accepting adds that sender to
the crew, so it only ever happens once per person.

The **My Crew** screen answers "who can send me treasure hunts?" — with a
swipe to remove anyone, a place to set your hunting name, and an optional
card link (`/crew/?k=…`) for pairing ahead of time.

Nothing bypasses this: an unsigned or unknown-sender hunt always needs the
grown-up check, which is also what nearby broadcast will filter on.

## Scheduled hunts

A hunt can carry a start time (held with a live countdown until it opens) and
an end time (after which it shows as finished) — for birthday mornings and
events where the treasure is genuinely packed away afterwards.

## Map modes while hunting

| Mode | Behaviour |
|---|---|
| **Free** | Locked to the hunter, heading up — turn and the map turns. Pinch to zoom; panning is disabled so a stray drag can't break the follow. |
| **Path** | Free mode plus a lime walking route to the target zone (`MKDirections`, routed to the *fuzzy* centre so it never gives the spot away). Requests are rate-limited to target changes, 40 m of wandering, or 45 s. |
| **Roam** | Hands off: pan, zoom, rotate anywhere. |

Zoom works in every mode; the arrow button re-centres.

## Privacy

No accounts, no backend, no analytics. Hunts live in JSON on each device and
travel only inside the files/links you choose to share.
