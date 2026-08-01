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

HOW TO REVIEW WITHOUT WALKING

The making side works anywhere. On first launch choose "A grown-up's phone", enter a name, and skip the card step. Tap + to make a hunt: move the map, tap "Drop point on the X" a few times, name it, save, and you will see the share screen. That covers creation and sharing.

To see the hunter side, import this sample hunt (open the app, tap Import, paste): [PASTE A HUNT LINK HERE]

Finding a point requires physically standing within a few metres of its GPS location, so the dig, prize and confetti screens cannot be triggered at a desk. Screenshots 4 and 5 show them. In the iOS Simulator they can be reached with Features > Location > Custom Location set to a point in the hunt.

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
