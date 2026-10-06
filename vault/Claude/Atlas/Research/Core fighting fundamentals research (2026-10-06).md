---
type: research
created: 2026-10-06
author: claude
tags:
  - research
  - combat
  - sao
  - mmorpg
---

Up: [[Claude]] · Feeds: [[Core fighting plan]]

Henry asked for parallel research on action-combat MMORPGs, Roblox combat games and SAO, to find core fighting fundamentals Sword Bound is missing. There were three subagent passes. Reddit was blocked in all three (SITE_BLOCKED), along with ResetEra, the Deepwoken Trello and swordartonline.fandom.com (HTTP 402). Forum sourcing comes from Steam, the GW2 and ESO forums, the Arcane Odyssey forum, Inven Global and the Roblox DevForum. Rankings are judgment calls; facts carry sources.

## What we already have (from the code)
- Client hitbox with server checks for hit window, reach, state and stamina. Parry uses the client's press time, clamped (ping compensation).
- Block covers only the front (BlockAngle 120). A missed parry becomes a block. Re-raising block right after releasing it gets a tiny window (anti-mash).
- Posture: parries and hits drain it, a full break opens a riposte. A light attack's wind-up can be cancelled into block or roll, which works like a feint.
- A single HyperArmor flag. PvP is off (PvPEnabled = false).
- A souls-style death penalty was dropped; SAO town respawn (roadmap #20) covers it.

## Merged ranked list: what to add
1. **Enemy telegraph language.** Readable wind-ups, plus a distinct glow for parryable vs unblockable attacks.
   - Poor telegraphs are the top complaint about enemy CC on the GW2 forum [https://en-forum.guildwars2.com/topic/117960-the-state-of-cc-spam-from-enemies-in-pve].
   - Vindictus: Defying Fate improved feel by removing attacks you couldn't dodge or guard, and adding clear rewards for reacting in time [https://www.invenglobal.com/articles/21507/combat-satisfaction-significantly-increased-vindictus-defying-fate-fgt-feedback-released].
   - Lost Ark gives counterable boss attacks a blue glow [https://vulkk.com/2022/02/11/how-to-use-advanced-combat-mechanics-in-lost-ark/].
   - WildStar uses color-coded telegraph shapes [https://www.engadget.com/2014-01-21-tips-and-tricks-to-survive-wildstars-active-combat.html].
   - In SAO, skilled players read a skill from its preparation pose [https://en.namu.wiki/w/%EC%86%8C%EB%93%9C%20%EC%95%84%ED%8A%B8%20%EC%98%A8%EB%9D%BC%EC%9D%B8/%EC%8A%A4%ED%82%AC%20%EB%AA%A9%EB%A1%9D].
   - Note: Henry deferred perilous attacks. This item is the general readability layer.
2. **Switch, a party posture-break mechanic.** When a boss's posture breaks, an ally who steps in gets the punish window and takes aggro.
   - SAO Switch comes from the episode 2 Illfang fight [https://siliconera.com/?p=377808] [https://otakumode.com/otapedia/anime/sword_art_online/sword_art_online_game_4_sao].
   - GW2's defiance bar works the same way for a party [https://wiki.guildwars2.com/wiki/Defiance_bar].
   - Lost Ark has boss stagger gauges [vulkk above].
   - Boss posture today is tuned around one player.
3. **SAO sword skill rules (fold into plan item #7).**
   - Pre-motion pose, then the system speeds you through the move.
   - An uncancellable post-motion delay that scales with hit count [namu above] [https://www.vsbattles.com/threads/revisions-for-kirito.29724/post-942680].
   - Skill Connect shown with an audio cue as well as a flash. Last Recollection players found its blue window hard to see [https://steamcommunity.com/app/1566880/discussions/0/3879345097432704041] [https://bandainamcoent.com/news/sword-art-online-last-recollection-101-guide].
   - Echoes of Aincrad (2026) matches our plan: SP separate from stamina, refilled by basic hits, 3 skills per weapon [https://thegameswiki.com/echoes-of-aincrad/wiki/sword-skills].
   - Conflict to note: a roll that cancels the skill delay would remove the cost of using skills (UNSOURCED, reasoning).
4. **Anti-stunlock.**
   - A central stun manager where the longest stun wins and stuns never stack [https://devforum.roblox.com/t/stun-handler-v2/1072859].
   - A short CC immunity window after a stagger. BDO caps CC at 2 points and then gives 5 s of immunity [https://garmoth.com/guides/post/bdo-basics-combat-guide]. ESO gives 7 s after break free [https://en.uesp.net/wiki/Online:Block].
   - Roblox fighters add a combo escape: TSB's ragdoll cancel every 30 s [https://games.gg/fr/roblox/guides/guide-de-combat-the-strongest-battlegrounds/], JJS's Q escape [https://games.gg/roblox/guides/jujutsu-shenanigans-beginners-guide/], Blox Fruits' Instinct charges [https://bloxmeta.gg/games/blox-fruits/guides/pvp-combat-guide].
   - Needed before PvP, and also to stop a party chain-staggering one mob.
5. **Lag compensation for hits.**
   - Keep each target's position history (every 0.05 to 0.1 s, about 2 s) and rewind by roughly ping/2 [https://devforum.roblox.com/t/combat-system-with-rollback/3685525].
   - Ping is a top complaint on the Arcane Odyssey forum [https://forum.arcaneodyssey.dev/t/arcane-odysseys-combat-problem/97410].
   - We already have this for parries, not for hits.
6. **Protection tiers instead of one HyperArmor flag.**
   - BDO has super armor, forward guard and i-frames, and grabs beat super armor [garmoth above].
   - Lost Ark has paralysis, push and full immunity [https://upcomer.com/lost-arks-combat-system-explained].
   - Last Recollection's Break skills counter specific actions, such as guard [bandainamcoent above].
   - Pairs with guard-break tags on some sword skills.
7. **NPCs follow player rules.** Arcane Odyssey players call NPCs that block or parry mid-attack unfair [AO forum above]. Our knight should be checked against this.
8. **Settle PvE vs PvP numbers before duels ship.**
   - BDO splits back attack and CC values between PvE and PvP [garmoth above] [https://www.invenglobal.com/blackdesertonline/articles/5153/bdo-kr-patch-notes-may-24th-cc-removed-from-main-skills-only-for-pvp-updated-may-28th].
   - Lost Ark normalizes gear in PvP [https://mein-mmo.de/en/how-pvp-works-in-lost-ark-everything-you-need-to-know,776977].
   - Add a combat-tag logout rule (Deepwoken [https://deepwoken.fandom.com/wiki/Death]) and the SAO orange cursor for PvP crimes [https://orbispatches.com/gaming-faq/what-is-a-red-player-in-sao].

## Lower priority, or already partly covered
- **Feints.** Deepwoken uses M1+M2 [https://deepwoken.fandom.com/wiki/Controls]. Our wind-up cancel already works like a feint.
- **Parry cost.**
  - Combat Warriors' parry has a cooldown and costs stamina [https://gamerjournalist.com/how-to-parry-in-roblox-combat-warriors/] [https://progameguides.com/roblox/how-to-parry-in-combat-warriors-roblox/].
  - Ours uses an anti-mash window instead. Deepwoken's parry also costs posture [https://deepwoken.fandom.com/wiki/Terminology_(game)].
- **Positional bonuses.** Lost Ark front attacks deal +20%, back attacks +5% with +10% crit [vulkk above]. Backstabs are deferred.
- **Downed and revive state.** From GW2 [https://www.engadget.com/2010-07-08-to-live-and-die-in-tyria-death-healing-and-combat-in-guild.html]. It may clash with SAO's death rules (UNSOURCED).
- **Weapon proficiency that unlocks skills.**
  - SAO proficiency runs 0 to 1000 [namu above].
  - Throne and Liberty's mastery changes how skills behave [https://maxroll.gg/throne-and-liberty/resources/weapon-mastery-guide].
  - Cap the grind. Last Recollection players complained about 100 boss kills for an ultimate [https://vaporlens.app/app/1566880/sword_art_online_last_recollection].
- **Avoid.** Bullet-sponge HP, automated fights, and damage multipliers that make co-op mandatory [https://kotaku.com/the-sword-art-online-game-is-a-boring-slog-unless-you-1578870666] [https://steamcommunity.com/app/1009290/discussions/0/2645252442217651354].

## Useful numbers
- **TSB:** a 4-hit M1, with the 4th hit launching.
- **Swordburst 3:** Whirlwind costs 35 SP for 3 hits of 160% [https://itemlevel.net/sword-burst-3-complete-katana-guide/].
- **Hollow Realization:** mastery gives +20% at 100 uses, +50% at 1,000 and double at 10,000 [https://steamcommunity.com/app/607890/discussions/0/1482109512300919143].
- **GW2:** a dodge costs 50 of 100 endurance [https://wiki.guildwars2.com/wiki/Dodge].
