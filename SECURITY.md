# X-Marks threat model

X-Marks sends children to physical places. That single fact makes it a
different kind of app from most family software: the worst outcome is not a
data leak, it is a child walking to a location chosen by someone who should
not have been able to choose it.

This document lists what is at stake, every route by which content or
coordinates can reach a child's phone, what stops each one, and — importantly
— what the app cannot solve and what is still open.

Last reviewed: 26 July 2026.

---

## 1. What is at stake

Ranked by severity, worst first.

| # | Harm | Why it matters |
|---|---|---|
| A1 | A child is routed to a place chosen by a bad actor | The app actively navigates: compass, beeping, "keep going". It is persuasive by design. |
| A2 | A stranger establishes contact with a child | A hunt carries free text (name, prize) that appears on a child's screen. |
| A3 | Someone learns where a child has been, or will be | Hunt points are real places; found-times would be a movement record. |
| A4 | Inappropriate text reaches a child's screen | Hunt name and prize are attacker-controlled strings if a hostile hunt opens. |
| A5 | A child is nudged somewhere unsafe by a *trusted* adult's carelessness | A well-meaning hunt across a main road is still a hazard. |

Note that A1 and A2 are safety, not privacy. They are the reason the design
prioritises *who may send* over *what is encrypted*.

---

## 2. Who we are defending against

| Actor | Capability assumed |
|---|---|
| Stranger with the child's number | Can deliver any link, file or text to the phone via SMS, iMessage, WhatsApp, email, AirDrop. |
| Stranger who is technically capable | Can also read the app binary, extract the built-in key, and craft or decrypt hunt payloads. |
| Someone with brief physical access to the child's phone | Can tap anything on screen; assumed not to know the grown-up passcode. |
| A crew member who turns out to be untrustworthy | Full sender rights, because a grown-up granted them. |
| Another child (sibling, school friend) | Curious rather than hostile; may try to guess a passcode. |
| Passive observer of the message channel | Sees the link in transit. |
| Infrastructure (Apple, GitHub) | Sees what the app sends it. |

Explicitly **out of scope**: a hostile parent (the app cannot referee who has
custody of a child's phone), and a jailbroken/compromised device.

---

## 3. Trust model

Every phone declares at first launch what it is (`DeviceRole.swift`,
`SetupView.swift`):

- **Grown-up's phone** — creates hunts, decides the crew, hunts too. Grown-up
  actions sit behind a word-form multiplication. That check exists only to
  stop a *child* wandering into hunt-making on a parent's phone; it is not
  claimed to stop an adult.
- **Young hunter's phone** — hunting only. No create button exists. Grown-up
  actions require the **passcode** set when the phone was handed over.

Identity is a Curve25519 signing key per device, private half in the Keychain
(`HunterIdentity.swift`). Every shared hunt is signed. The **crew** is the set
of public keys a grown-up has accepted (`CrewStore`).

**The load-bearing rule:** on a hunter's phone, a hunt whose signature does
not verify against a key already in the crew is refused outright. There is no
accept button, no override, no "ask a grown-up" prompt on that device.

The absence of that prompt is deliberate and is the single most important
decision in this document. An earlier design *did* prompt, gated by a sum. It
was defeated by the obvious script: a stranger sends a hunt, the child is
excited, the stranger says "just get a grown-up to do the sum" — or the child,
being nine, does the sum. A check that a child can pass, or be coached
through, is not a check.

---

## 4. Every path onto a child's phone

| # | Path | What stops a hostile version |
|---|---|---|
| P1 | Universal link `https://x-marks…/hunt/?d=…` tapped in any messenger | Signature must verify against a crew key, else refused with no accept path. |
| P2 | Custom scheme `treasurehunt://hunt/?d=…` | Same code path as P1 — `HuntShareCodec.decode` is the single entry point. |
| P3 | `.treasurehunt` file opened from Files/Mail/AirDrop | Same code path. |
| P4 | Code pasted into the in-app **Import** box | Same code path. |
| P5 | Website "Open in X-Marks" button | Hands the same URL to the app; same code path. |
| P6 | Crew invite `…/crew/?k=…` | On a hunter's phone, adding a crew member requires the grown-up passcode. |
| P7 | Forwarding by another child | Hunter phones have no share UI, and a forwarded hunt still carries its original signature, so it is refused on any phone whose crew lacks that key. |
| P8 | Nearby Bluetooth broadcast | **Not built.** If it ever is, it must filter on the crew, never prompt. |

Single-entry-point discipline matters here: adding a new way to receive a hunt
without routing it through `HuntShareCodec.decode` + the crew check would
reopen everything. Any future receive path must land there.

---

## 5. What is deliberately absent

Things that would be useful, and are not built, because of what they would
enable:

- **No progress reporting back to a hunt's creator.** Removed entirely — not
  made optional. "Point 3 found, 14:32" is a record of where a child was and
  when, and a creator is not automatically someone entitled to that.
- **No live location sharing**, of any kind, to anyone.
- **No accounts, no directory, no discovery.** There is no way to look up
  another user, so there is no way to enumerate children.
- **No analytics, no crash reporting, no advertising SDKs.**
- **No accept-a-stranger prompt on hunter phones** (see §3).
- **No in-app messaging.** Hunt name and prize are the only free text, and
  they only render for senders already trusted.

---

## 6. Data flows that do leave the device

Complete list. Everything else stays local.

| Flow | Destination | Contains | Notes |
|---|---|---|---|
| Hunt link/file, when a grown-up shares one | Whichever messenger they choose | Encrypted hunt payload | The grown-up chooses the recipient. |
| Map tiles | Apple | Approximate viewport | Standard MapKit. |
| Walking directions, **Path mode only** | Apple | Start point and the *fuzzy* target centre | Only while Path mode is on. |
| Website page loads | GitHub Pages | Standard web logs | Only for phones without the app. |

Location is never transmitted by X-Marks itself. The walked trail exists only
in memory and is discarded when the hunt screen closes.

---

## 7. Known limitations — stated plainly

These are real. They are documented rather than hidden.

1. **Hunt payload encryption is obfuscation, not confidentiality.** The AES
   key derives from a secret compiled into the app, so anyone who
   reverse-engineers the binary can decrypt any hunt link they intercept and
   learn its locations. It defeats messengers, link previews and casual
   snooping; it does not defeat a determined technical attacker who already
   has the link.
   *Why it is tolerable:* decryption reveals locations to someone who already
   had the message. It does not let them **inject** a hunt, because injection
   requires a signature from a crew key, which the built-in secret does not
   provide.

2. **The passcode is only as good as its handling.** A child who watches it
   being typed knows it. Same trust model as Screen Time.

3. **A crew member is trusted completely.** Once a grown-up adds someone, that
   person can send any hunt to any location, with any text. The app cannot
   evaluate whether a person is safe — that judgement is the parent's, and the
   app should make it feel like a decision, which is why adding someone is a
   separate deliberate act rather than a by-product of accepting a hunt.

4. **Sender names are self-chosen.** A stranger can call themselves "Dad".
   The signature will be genuinely theirs, so it verifies — as a *new,
   unknown* key, never as the existing Dad. The invite screen now leads with a
   red warning when a name collides with a crew member, and tells the reader
   that names are checked by nobody. It remains true that the only real
   identity is the key, and only a human can decide whether they recognise the
   person behind it.

5. **A hunter phone mis-set-up as a grown-up phone loses every hunter
   protection.** The setup screen is the whole game; it should stay
   unmissable.

6. **The app cannot judge whether a location is safe.** A hunt from a loving
   grandparent may still cross a dual carriageway (harm A5).

---

## 8. Residual risks the app cannot fix

- A parent who adds an unsafe person to the crew.
- A parent who shares the passcode, or types it in view of the child.
- A child taken somewhere by a route that has nothing to do with this app.
- The physical world: traffic, water, weather, strangers in parks.

The app's job is to not *add* a route to harm, and to not lend an adult's
authority to a stranger. It is not a substitute for knowing where your
children are going.

---

## 9. Open items

Items 1–2 were found by writing this document and are now fixed; the rest
remain open.

1. ~~**Warn hard on sender-name collision.**~~ Done — if an incoming sender's
   name matches a crew member but the key differs, the invite screen leads
   with a red STOP panel saying this is not them. Unknown senders are also now
   told plainly that names are self-chosen and checked by nobody.
2. ~~**Throttle passcode attempts.**~~ Done — three wrong tries starts a
   lockout that doubles from 30 s to a ten-minute cap, so 10,000 guesses is no
   longer an afternoon's work.
3. **Consider a distance sanity check.** A hunt whose points are far from
   where the phone usually is could ask a grown-up to confirm before the child
   starts — a useful net even for crew-sent hunts (harm A5).
4. **Consider a grown-up review step on the hunter's phone**: show the points
   to a grown-up, passcode-gated, before a hunt can be started for the first
   time. Stronger, but adds friction to the good case; worth weighing.
5. **If nearby broadcast is ever built**, it must surface only crew-signed
   hunts, and must never prompt to trust someone new.
6. **Independent review.** This document is written by the people who wrote
   the app. Before any wide release, someone else should try to break it.

---

## 10. For App Review

Summary of the child-safety design, suitable for review notes:

> Each device is configured at first launch as a parent device or a child
> device. Child devices cannot create hunts. Hunts are cryptographically
> signed by the sender; a child device will only open a hunt whose signature
> verifies against a sender the parent has explicitly added, and refuses all
> others with no in-app way to accept them. Adding a trusted sender on a child
> device requires a parent-set passcode. The app has no accounts, no user
> directory, no messaging, no analytics, and never transmits location.
