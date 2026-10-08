---
type: research
created: 2026-10-08
author: claude
tags:
  - research
  - weapons
  - souls
---

Up: [[Claude]] · Used by: [[Weapons and sword skills plan]]

## Sourcing status
- **Reddit was blocked.** WebFetch returned SITE_BLOCKED for reddit.com and old.reddit.com, the egress proxy refused CONNECT to both hosts (403, organization policy), and a WebSearch restricted to reddit.com was rejected (HTTP 400). Some searches turned up third-party Reddit mirrors. I didn't use them because they would get around the block.
- **Forum pass used other sources.** It covers Steam Community discussions (Elden Ring, DS3, Lies of P, MH Wilds) and Fextralife comment sections. GameFAQs searches surfaced no GameFAQs threads, only Steam ones.
- **No per-class startup frame data.** No source I could reach gave startup frames by class. Fextralife and wiki.gg weapon pages had no attack tables, and one Fextralife commenter asks for exactly that missing chart [https://eldenring.wiki.fextralife.com/Stamina]. For speed and reach I used Mordhau's published windup and length values as the numeric stand-in.

## 1. Class data

**Dagger**
- Elden Ring calls daggers fast with "very short reach and low damage against both health and poise." Rapid slashes, thrusting heavies, and they "won't stagger most foes" [https://eldenring.wiki.gg/wiki/Daggers].
- Critical multiplier is 130 on the Dagger and 140 on the Misericorde, against an implied base of 100 [https://eldenring.wiki.gg/wiki/Critical_Attack].
- A dagger parry starts in 3 frames with 5 active frames, versus 4 and 6 for a small shield, measured at 30fps [https://eldenring.wiki.gg/wiki/Parrying].
- Mordhau's dagger has a 400ms windup, 45cm length and 14 stamina drain [https://mordhau.fandom.com/wiki/Dagger].

**Straight sword / longsword**
- Mordhau's longsword has a 560ms windup, 105cm length and 19 stamina drain [https://mordhau.fandom.com/wiki/Longsword].
- A standard light hit needs 51 poise to endure, versus 41 for a dagger and 45 for a rapier [https://eldenring.wiki.fextralife.com/Poise].

**Greatsword / colossal**
- Colossal swords have "excellent reach" but slow speed, mostly horizontal slashes with overhead-slam heavies, and their slow one-handed set "is at risk of getting parried" [https://eldenring.wiki.gg/wiki/Colossal_Swords].
- Greatswords get hyper armor on two-handed attacks only. Colossals get it with no hand restriction [https://eldenring.wiki.gg/wiki/Super_Armor].
- PvP hyper armor damage negation is 17.5% for colossals and 7.5% for greatswords [https://eldenring.wiki.gg/wiki/Super_Armor].
- In DS3, two-handed ultra greatsword normal attacks can't be parried [https://darksouls3.wiki.fextralife.com/Ultra+Greatswords].

**Katana**
- Bleed (blood loss) buildup is on by default. One-handed swings are horizontal and two-handed swings are mostly vertical [https://eldenring.wiki.gg/wiki/Katanas].

**Rapier / thrust**
- Pierce counter-hits deal +30% vs enemies and +15% in PvP. The bonus needs Pierce damage, so thrusting alone doesn't trigger it [https://eldenring.wiki.gg/wiki/Spear_Talisman].

**Spear**
- Elden Ring spears can attack with a shield raised [https://eldenring.wiki.fextralife.com/Spears].
- Mordhau's spear is 180cm with a 650ms stab windup but only a 325ms stab release [https://mordhau.fandom.com/wiki/Spear].
- Sekiro's Mikiri Counter answers thrusts and deals more posture damage than any other defense [https://sekiroshadowsdietwice.wiki.fextralife.com/Mikiri+Counter].

**Axe**
- Mordhau's battle axe has a 625ms windup, 90cm length, and 45 wood damage versus 22 for the longsword [https://mordhau.fandom.com/wiki/Battle_Axe].
- Elden Ring tags axes as "Standard" damage, the same as straight swords [https://eldenring.wiki.gg/wiki/Damage_Types].

**Mace / hammer**
- Strike damage type [https://eldenring.wiki.gg/wiki/Damage_Types]. Hammers are known for "destroying shields and breaking guards" [https://eldenring.wiki.fextralife.com/Hammers].
- The Hammer Talisman raises stamina damage to blocking targets by 40% [https://eldenring.wiki.gg/wiki/Hammer_Talisman].
- The mace is the one class with hyper armor on one-handed heavy and charged attacks [https://eldenring.wiki.gg/wiki/Super_Armor].
- Sekiro's Loaded Axe breaks shields and fills posture [https://sekiroshadowsdietwice.wiki.fextralife.com/Loaded+Axe].

**Stance and poise damage by class** (Steam players, Dec 2022, possibly outdated) [https://steamcommunity.com/app/1245620/discussions/0/3729575042620520686/]
- Guard counter stance damage: daggers 18, thrusting swords 24, axes, straight swords and katanas 30, colossals and maces 36, great hammers 39.
- Two-handed charged heavy poise: great hammers 42.7, hammers 39.6, colossal swords 39.6, greatswords 36.3.

### Comparison table

Mordhau numbers are windup and length. Elden Ring poise numbers are guard counter stance damage.

| Class | Speed | Reach | Poise dmg | Special |
|---|---|---|---|---|
| Dagger | Fastest (400ms) | 45cm | 18 | Crit 130 to 140, 3-frame parry |
| Straight sword | Mid (560ms) | 105cm | 30 | Baseline |
| Greatsword | Slow | Excellent | about 36 | Two-handed hyper armor |
| Katana | Mid | Mid | 30 | Bleed buildup |
| Rapier | Fast | Mid | 24 | Pierce counter +30% / +15% |
| Spear | Slow windup, fast release (325ms) | 180cm | 30, cut in PvP | Attack while guarding |
| Axe | 625ms | 90cm | 30 | Damage type identical to sword |
| Hammer / mace | Slow | Short | 36 to 39 | Guard break, one-handed hyper armor |

The UNSOURCED cells are filled in from class descriptions, with no class-wide number behind them:
- Greatsword "about 36" is the charged heavy figure, since no guard counter value was given for greatswords.
- Katana speed and reach.
- Rapier speed and reach.

## 2. Making classes distinct

- **A new class must not overlap the old ones.** MH producer Tsujimoto said a new weapon type "would really have to add something new" and not overlap the existing 14 [https://www.thesixthaxis.com/2020/10/07/monster-hunter-rise-weapons-gameplay/].
- **Stats follow the concept.** MH designers "determine the stats and values based on the concepts of each weapon and action" [http://nintendoeverything.com/monster-hunter-rise-dev-on-how-switch-skills-ended-up-in-the-game-balancing-the-weapons-more/].
- **One resource loop per weapon** [https://mhworld.kiranico.com/guide/long-sword] [https://mhworld.kiranico.com/guide/charge-blade] [https://mhworld.kiranico.com/guide/hammer]
  - Long Sword fills a 3-level spirit gauge on hits, and its Foresight Slash counter spends gauge.
  - Charge Blade stores phials and gets Guard Points built into its attacks.
  - Hammer has 3 charge levels, can move while charging, and builds KO on head hits plus exhaust anywhere.
- **Elden Ring shares movesets per class and varies the skill.** Swappable Ashes of War carry the variety, compatibility depends on moveset (a thrust skill needs a thrust-capable weapon), and some uniques lock their skill [https://eldenring.wiki.gg/wiki/Ashes_of_War]. Even inside a class, "seven swords have unique heavy and charged heavy attacks" [https://eldenring.wiki.gg/wiki/Colossal_Swords].
- **Lies of P splits blade and handle.** The blade sets damage, guard and the main Fable Art. The handle sets moveset and scaling [https://www.ginx.tv/en/weapon-assembly].
- **Bloodborne used fewer weapons that transform.** Miyazaki said variety is "absorbed down on a customisation level, rather than in the quantity of actual weapons" [https://www.gamebanshee.com/kw3xa].
- **Nioh 2 stances change behavior.** High-stance heavies don't bounce off guard, and low stance is the fastest with the least Ki use [https://nioh2.wiki.fextralife.com/Stances].
- **Weight comes from feel too.** God of War's axe gets its heft from hit stop and a low-end thud sound [https://blog.playstation.com/?p=370399].

## 3. Balance lessons

- **Bleed katanas were overtuned.** Bleed was "basically overkill" in PvP and got recalibrated in 1.04 [https://kotaku.com/elden-ring-patch-1-04-bleed-vyke-patches-carian-retalia-1848811870]. Rivers of Blood's Corpse Piler then had its damage and bleed cut in 1.06 [https://www.gamesradar.com/elden-ring-patch-106].
- **Colossals started too slow.** They got faster attacks and shorter recovery in 1.04 [https://www.bandainamcoent.com/news/elden-ring-patch-notes-v1-04] and again in 1.07 [https://www.shacknews.com/article/132654/elden-ring-version-107-patch-notes-pvp-damage-scaling]. A crouch-poke exploit later gave them "extremely fast attack speed and a ton of range" [https://windowscentral.com/gaming/new-elden-ring-glitch-makes-colossal-weapons-unstoppable-in-pvp].
- **PvE and PvP need separate numbers.**
  - 1.07 added separate PvP damage scaling [https://www.shacknews.com/article/132654/elden-ring-version-107-patch-notes-pvp-damage-scaling].
  - 1.08 cut poise damage for straight swords, thrusting swords, spears and katanas in PvP only. It also reduced thrust counter damage in PvP [https://eldenring.wiki.gg/wiki/Game_Version/1.08].
- **DS3 hyper armor caused stunlock complaints.** Poise only works during the active frames of certain attacks. Commenters complained about stunlock and heavy builds dying, leaving dagger and estoc builds [https://darksouls3.wiki.fextralife.com/Poise].
- **Forum views (Steam)**
  - Some Elden Ring players call maces and axes "pretty underwhelming." They say daggers' low reach and poise make them "less usable" [https://steamcommunity.com/app/1245620/discussions/0/4031346899449014778].
  - DS3 straight swords: players were split on "OP." Ultras "hyperarmor through" them [https://steamcommunity.com/app/374320/discussions/0/1735463620089263873/].
  - Lies of P players called greatsword blade on a rapier handle the only sensible build [https://steamcommunity.com/app/1627720/discussions/0/3808406410966233976]. The lesson is that fast moveset plus big damage wins unless stamina gates it. That lesson is UNSOURCED inference.
  - In MH Wilds, the counter-centric Long Sword has the top pick rate at 17.76%, from third-party data on 50,000+ players [https://www.icy-veins.com/monster-hunter-wilds/news/what-are-the-most-played-weapons-in-monster-hunter-wilds/].

## 4. Recommended roster (UNSOURCED synthesis built on the facts above)

1. **One-handed sword (existing).** The all-round baseline that everything else is balanced against.
2. **Dagger.** The fastest attacks and parry, the highest crit and riposte multiplier, and almost no poise damage. Systems needed: crit multiplier field, short hitbox.
3. **Greatsword (two-handed).** Long reach, hyper armor on two-handed heavies, and multi-level charge in the style of MH Hammer. Systems needed: per-attack hyper armor frame windows with damage negation, a charge tier table.
4. **Katana.** Fast slashes that build bleed, plus a sheathe or iai counter stance that fills a spirit-style meter. Systems needed: status buildup bar, meter resource.
5. **Spear (absorbs rapier).** Longest reach, a Pierce counter bonus, and attacks while guarding. Systems needed: thrust capsule hitbox, damage-type tags, a guard-poke state.
6. **Mace / hammer (absorbs axe).** Strike damage, high stamina damage to guard and guard break, one-handed hyper armor, and head-hit stagger buildup. Systems needed: guard stamina multiplier, a stagger meter on enemies.

**Shared systems to build first**
- Damage-type tag (Slash, Strike, Pierce).
- Per-class reach scalar.
- Per-attack hyper armor windows.
- Charge levels.
- Separate PvE and PvP multiplier tables from day one, following the 1.07 lesson.

I'm cutting the axe as its own class. Elden Ring gave it the same damage type as straight swords, and players call it underwhelming, which points to a reskin risk (inference).
