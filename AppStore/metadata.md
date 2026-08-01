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

X-Marks is a family GPS treasure-hunt app. A parent drops treasure points on a map, adds a prize, and sends the hunt to their children as an encrypted link. The children walk to each point, guided by a compass and proximity beeps, and dig up the treasure on arrival.

No links or accounts are needed to review it — you generate both test links yourself in step 1.

PART 1 — the grown-up side (works at a desk, about 3 minutes)

1. On first launch choose "A grown-up's phone" and enter any name.
2. On the card step tap "Send my hunting card", choose Copy, and paste the link into Notes. Label it CARD.
3. Tap + to make a hunt: move the map, tap "Drop point on the X" two or three times, give it a name, Save.
4. On the share screen tap "Copy link" and paste that into Notes too. Label it HUNT. Tap Done.

You now have both links, and have seen the whole creation flow.

PART 2 — the child device and the safety model (please try this)

5. Delete the app and reinstall it, so the device starts fresh.
6. Choose "A young hunter's phone" and set any passcode, e.g. 1234.
7. Note there is no + button anywhere: a child device cannot create hunts.
8. Tap Import (top left) and paste the HUNT link. It is REFUSED — the sender is not a known grown-up, and there is no button anywhere to accept them.
9. Tap Import and paste the CARD link. The app asks for the passcode from step 6; enter it, and that sender becomes trusted.
10. Tap Import and paste the HUNT link again. It now opens.

Steps 8–10 are the entire trust model, in about a minute.

Finding a treasure point requires physically standing within a few metres of its real GPS location, so the dig, prize and confetti screens cannot be triggered at a desk — screenshots 4 and 5 show them. In the Simulator, use Features > Location > Custom Location set to one of the hunt's points.

WHY THE RESTRICTIONS

A hunt directs a child to a physical place, so "who may send one" is treated as a safety question rather than a convenience:

1. Each device is set up as a parent or child device. Child devices have no hunt-creation UI.
2. Every hunt is signed with a per-device Curve25519 key held in the Keychain.
3. A child device opens a hunt only if its signature verifies against a sender the parent has already added. Everything else is refused — there is deliberately no "accept this sender" button on a child device, because such a prompt is exactly what a stranger would coach a child through.
4. Adding a trusted sender on a child device requires a parent-set passcode, with lockout after repeated wrong entries.
5. Nothing reports back: a hunt's creator is never told which points were found or when, as that would be a record of where a child had been.

The result is that knowing a child's phone number is not enough to send them anywhere.

DATA

Location (When In Use) is used only for on-device gameplay guidance and is never transmitted or stored. There are no accounts, no user directory, no messaging, no analytics, no third-party SDKs and no developer servers — hunts travel inside the link itself. The only outbound requests are Apple Maps tiles and, in Path map mode, Apple walking directions. A full threat model (SECURITY.md) is available on request.
