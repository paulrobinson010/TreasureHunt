# App Store metadata — X-Marks (emoji-free for Connect)

## Promotional text (170 max)

Real treasure hunts in real places! Drop Xs on a map, send a magic link, and the phone beeps, buzzes and bursts into confetti when the treasure is finally dug up.

## Description

X marks the spot — for real.

X-Marks turns any park, beach, garden or neighbourhood into a treasure hunt. Drop treasure points on a map, write down a secret prize, and send the hunt to your favourite hunters with a single link. Then watch the magic happen.

HOW A HUNT WORKS
- The hunters see mystery zones on their map — never the exact spot
- Get close and a compass appears, pointing the way
- The phone buzzes when it's pointed straight at the treasure
- A metal detector beeps faster and faster as you close in
- Reach the X and DIG! Tap the sand to uncover the treasure
- Every dig earns a collectible for your treasure chest
- Find every X and the secret prize is revealed — confetti included

MADE FOR FAMILIES
- Send hunts over iMessage, WhatsApp or anything else — one tap and the hunt jumps straight into the app
- Watch progress roll in automatically as treasures are found
- Points can be found in any order, or in sequence for a staged adventure
- Choose map or satellite view, follow your dotted trail, and race back to your favourite spots

PRIVACY FIRST
No accounts. No ads. No tracking. Hunts travel inside encrypted links, progress syncs end-to-end encrypted through iCloud, and location is used live on the device only — it is never recorded or shared. Nobody but your family can read any of it.

Get the kids out and about. Treasure hunts. Big adventures. X-Marks ...the spot!

## Keywords (100 max)

treasure,hunt,scavenger,geocaching,kids,family,outdoors,adventure,compass,walk,explore,prize,pirate

## Subtitle (30 max)

Real-world treasure hunts

## Review notes

X-Marks is a family GPS treasure-hunt app. A parent drops treasure points on a map, adds a prize, and sends the hunt to their children as an encrypted link; the children physically walk to each point, guided by a compass and proximity beeps, and "dig up" the treasure on arrival.

WHAT TO PASTE WHERE

Two links are supplied below. Both were generated on the same device, so the hunt's signature matches the hunting card — that pairing is what the safety design checks.

- HUNTING CARD: [PASTE CARD LINK HERE]
- SAMPLE HUNT: [PASTE HUNT LINK HERE]

Import either by opening the app, tapping Import (top left), and pasting.

PATH A — the grown-up experience (about two minutes, works at a desk)

1. On first launch choose "A grown-up's phone", enter any name, then tap "I'll do this later" on the card step.
2. Tap + to make a hunt: move the map, tap "Drop point on the X" two or three times, give it a name, Save. The share screen appears — this is the whole creation flow.
3. Tap Import and paste the SAMPLE HUNT link. Because its sender is not yet known to this device, an invite screen appears naming the sender; accept it via the arithmetic gate. The hunt opens, showing the preview map with fuzzy zones and the guide arrow — the hunter's view.

PATH B — the child device, and the safety behaviour (please try this one)

Delete and reinstall the app first so the device starts fresh.

1. On first launch choose "A young hunter's phone" and set any passcode, e.g. 1234.
2. Note there is no + button anywhere: a child device cannot create hunts.
3. Tap Import and paste the SAMPLE HUNT link. It is REFUSED — the sender is not a known grown-up, and there is no button anywhere to accept them. This is the core protection: knowing a child's phone number is not enough to send them to a location.
4. Tap Import and paste the HUNTING CARD link. The app asks for the passcode from step 1. Enter it, and that sender becomes a trusted grown-up.
5. Tap Import and paste the SAMPLE HUNT link again. It now opens, marked as coming from a trusted sender.

Steps 3 to 5 are the entire trust model, demonstrated in under a minute.

WALKING IS REQUIRED FOR THE REST

Finding a point requires physically standing within a few metres of its GPS location, so the dig, prize and confetti screens cannot be triggered at a desk. Screenshots 4 and 5 show them. In the iOS Simulator they can be reached with Features > Location > Custom Location set to one of the hunt's points.

CHILD SAFETY DESIGN — PLEASE NOTE

Because a hunt directs a child to a physical location, the app treats "who may send one" as a safety question rather than a convenience, and the design may look unusually restrictive:

1. Device roles. On first launch each device is set up as a parent device or a child device. Child devices have no hunt-creation UI at all.

2. Signed hunts. Every shared hunt is signed with a per-device Curve25519 key held in the Keychain.

3. Allow-list, no override. A child device opens a hunt ONLY if its signature verifies against a sender the parent has already added. Anything else is refused outright — there is deliberately no "accept this sender" button on a child device, because such a prompt is exactly what a stranger would coach a child through.

4. Parent passcode. Adding a trusted sender on a child device requires a passcode set by the parent during setup, with lockout after repeated wrong entries. On a parent's own device, creation sits behind a word-form arithmetic gate.

5. Nothing reports back. There is no channel by which a hunt's creator learns which points were found or when — that would be a record of where a child had been. Location is used on-device only and is never transmitted by the app.

The result is that knowing a child's phone number is not sufficient to send them anywhere: the link arrives, the app refuses it, and there is no in-app path to accept it.

PERMISSIONS AND DATA

Location (When In Use) is used solely for gameplay guidance and is never transmitted or stored. There are no accounts, no user directory, no messaging, no analytics, no third-party SDKs, and no developer servers — hunts travel inside the link itself. The only outbound requests are Apple Maps tiles and, in "Path" map mode, Apple walking directions.

A full threat model is published in the project repository as SECURITY.md and can be supplied on request.
