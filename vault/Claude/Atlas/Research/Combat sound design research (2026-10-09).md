---
type: research
created: 2026-10-09
author: claude
tags:
  - research
  - audio
---

Up: [[Claude]] · Used by: [[Hit feel round 3]]

Produced by a research agent on 2026-10-09 after Henry said attacks are missing key features (flinching, enemies pushed back while you push forward, super armor for bosses, sounds that feel chopped) and that the fundamentals must be done before other classes. How melee combat sound is layered, varied, timed and mixed, plus Roblox audio specifics and a sound plan. Reproduced as the agent returned it. Claims marked unsourced are the agent's own calls.

Research date 2026-10-09. Every sourced claim carries an inline URL. Anything marked (unsourced) is my own judgment. Facts marked (observed in Studio) come from reading the open Sword Bound place (placeId 97172972533828) through the Studio connection on 2026-10-09; they have no URL.

## Source reachability

- Reddit: not reachable. WebSearch with `site:reddit.com` filters for r/GameAudio, r/sounddesign and r/robloxgamedev returned zero reddit.com results (only shops and itch.io pages), WebSearch with `allowed_domains: reddit.com` was rejected by the search proxy (HTTP 400), and WebFetch on reddit.com returned "SITE_BLOCKED". No retries through other routes were attempted. So this report contains no Reddit sourcing.
- X/Twitter: not reachable. `site:x.com` searches returned no x.com results, and WebFetch on x.com returned "ROBOTS_DISALLOWED".
- Discord: no usable content. `site:discord.com` searches returned only Discord support pages and a server listing for a "Sound Design" community server (https://discord.com/servers/sound-design-519238874581565458); Discord message content is not indexed.
- GDC Vault: talk pages load but full talks are members only, so only abstracts were usable.
- Forum sourcing that did work: the Roblox Developer Forum (devforum.roblox.com) pages fetched fine and are cited below.

## What Sword Bound plays today (observed in Studio)

- All sounds live in `ReplicatedStorage.Combat.Assets.Sounds`. Swing = `rbxasset://sounds/swordslash.wav` (0.65 s), Lunge = `swordlunge.wav` (0.78 s), HeavySwing = swordlunge at PlaybackSpeed 0.75, Roll = swordslash at PlaybackSpeed 0.55, Hit, Block and GuardBreak all = `metal.ogg` at speeds 1.10, 0.60 and 0.50, Draw/Sheath = `unsheath.wav`. Parry and ParryRing use two Pro Sound Effects ids (9125669267, 9125672551).
- Every sound uses RollOffMode Inverse, RollOffMinDistance 10 and RollOffMaxDistance 10000 (the engine defaults), except the two parry sounds at max 120. There are no SoundGroups anywhere under SoundService and no SoundEffects on any sound.
- `Effects.PlaySound` clones the template per play, so overlapping plays do not cut each other off. Hit gets plus or minus 6 percent random pitch and Block plus or minus 4 percent (`randomPitch` in `Combat.Effects`). Parry pitch already rises 4 percent per consecutive parry. The brief's "fixed pitch" is therefore true for swings, rolls and lunges but not for hits.
- The swing sound fires in `Sword:OnAttackStart` at t = 0 on the HumanoidRootPart, while light hits land at 0.19 s. The flesh hit, the armor hit, the light hit and the finisher hit all play the same metal.ogg clink regardless of DamageType or Weight.

Likely reasons it sounds "super chopped" (unsourced): one short legacy sample per event with no tail and no low end; the same metal clink for flesh, blocks and guard breaks, so the ear cannot tell outcomes apart; the roll and heavy swing are the same slash file pitched down to 0.55 to 0.75, which makes them sound grainy and slowed; and nothing in the mix ever gives the hit room, because swing, hit and everything else play at the same priority.

## 1. Anatomy of a sword swing and hit

### Layers

- A hit is usually built from separate parts. One article on responsive game audio describes a hit as "the attack, a material response, a low component, and a subtle environmental reflection" and says layering "can add detail without making every hit loud" (https://cogconnected.com/2026/06/making-gameplay-feel-more-responsive-using-sound/).
- For Honor's team split every hit into attacker-generated and target-generated elements so they had "total control over what combination of sounds was to be triggered" across weapon versus armor, weapon versus weapon and simultaneous attacks; they built swing whooshes with Doppler and filter chains plus live recordings of poles and sticks, and recorded real forged swords and steel rods for impacts (https://www.asoundeffect.com/for-honor-sound).
- Ghost of Yotei splits it the same way: "the weapon swings and source impacts play on the weapon, the target impacts play on the enemy", and target impacts are organized by base material (metal, chain, shield, wood, flesh) instead of weapon pairs, which cut the asset count (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- The Force Unleashed and Conan chose the event by weapon type and hit type (Heavy, Light, Deflected), then layered a material-specific impact on top using a surface type from collision detection (https://designingsound.org/2009/12/01/audio-implementation-on-star-wars-the-force-unleashed-and-conan/).
- Mortal Kombat 1 gives each impact category its own texture: "body impacts have more crunch, face hits have more squish, and blade hits sound sharp and painful", and "the size and shape of the impacts correspond well to the amount of damage a character takes" (https://www.asoundeffect.com/mortal-kombat-1-game-audio/).
- Ghost of Tsushima recorded knives, bayonets and razors slicing fruit, vegetables and cloth to capture "the ripping of flesh, armor and sinew in a very forward but not overly exaggerated way" (https://www.asoundeffect.com/ghost-of-tsushima-sound/).
- Low end matters. A Naughty Dog designer describes God of War's axe as "a brute force slam with lots of low end" and says reduced camera shake "is made up for in audio and animation" (https://blog.playstation.com/?p=370399). A general impact guide recommends "layering low-end booms with transient cracks and tails" and warns that "loud impacts with no contrast or low end ... feel weak despite the volume" (https://sounddesign.irpr.agency/guides/how-to-add-weight-to-impacts/).

### Timing (attack and release)

- A motion sound can lead, sync or trail the action: "Starting a motion sound just before an attack can prepare the player", "Aligning it with the animation makes movement feel direct", and a trailing tail "can carry momentum into the next moment" (https://cogconnected.com/2026/06/making-gameplay-feel-more-responsive-using-sound/).
- God of War sweetener layers "seek into the audio file so their peak lines up with the hand-grab", and core sounds use separate Start, Loop and Release pieces to absorb timing changes (https://asoundeffect.com/god-of-war-sound/).
- In fast combat there is "very little time for those sounds to 'speak'" (Dan Forden on Mortal Kombat 1, https://www.asoundeffect.com/mortal-kombat-1-game-audio/), and "a rapid combo needs lighter effects that remain clear in close succession" while a powerful attack "may need a longer tail" (https://cogconnected.com/2026/06/making-gameplay-feel-more-responsive-using-sound/).
- Leaving a gap before a big hit helps it land: "leave space and quiet before an impact so it has contrast to land against" (https://sounddesign.irpr.agency/guides/how-to-add-weight-to-impacts/). God of War Ragnarok used a brief silence before Dreki's electric explosion for the same reason (https://asoundeffect.com/god-of-war-ragnarok-game-audio).

### Swing weight and attack type

- Chivalry 2 gives each weapon "different and unique sounds for every single attack type" (https://chivalry2.com/2022/06/24/chivalry-2-audio-with-buckley-twitch-stream-recap/).
- God of War Ragnarok's spear has distinct characteristics for each move in the light combo and separate "visceral impacts" for stabs, the blunt side and slices; its held charge plays a charge-up sound and the release slam is much bigger at max charge (https://asoundeffect.com/god-of-war-ragnarok-game-audio).
- Pitch can carry strength: "The harder a ball hits the ground, the higher pitch the sound it makes", and raising pitch one semitone per step in a chained sequence reinforces combo length (George Prosser, https://www.gamedeveloper.com/audio/the-power-of-pitch-shifting).

### Parry, clash and block

- For Honor added extra layers to blocks so players could tell a full block from a weak one, which told them whether a counter was available (https://www.asoundeffect.com/for-honor-sound).
- Ghost of Yotei says "when you get a parry off, it has to sound like you just did the coolest thing ever", and layered its parry with Soulsborne-style sweeteners while staying grounded; a correct weapon choice branches to a different sound with a reverb send (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- Conan had separate sounds for Blocked Break, Blocked Heavy, Blocked Light, Deflect and Parried (https://designingsound.org/2009/12/01/audio-implementation-on-star-wars-the-force-unleashed-and-conan/).
- Clair Obscur: Expedition 33 uses distinct cues "from the swish to the glissando woosh" so players can time parries, and a GDC summary notes "audio often gets the last-mile job of signaling exact timing" (https://gamedev.net/news/5168-audio-cues-for-parry-timing-in-expedition-33/).
- Sword Bound's code already keeps blocks "deliberately dull ... so a parry is obvious by ear alone" (observed in Studio, comment in `Combat.Effects`), which matches the For Honor and Yotei approach.

### Hit confirm versus whiff

- Distinct outcomes should sound different: "A successful hit, blocked attack ... can each use distinct feedback", and a duller response can signal a miss or block (https://cogconnected.com/2026/06/making-gameplay-feel-more-responsive-using-sound/).
- Hades composer and sound designer Darren Korb describes hit sounds as adding "a little bit of, sort of, Pavlovian delight" (https://gameplay.co/hades-game-music-sound-design-darren-korb-supergiant-games/). For Honor wanted "that pleasurable aural confirmation of having hit someone" (https://www.mcvuk.com/drums-of-war-for-honors-audio-design/).
- Ghost of Yotei ducks the swing "a few dB on various bands" with dynamic sidechain EQ when the weapon makes contact, so the impact stands out over the whoosh (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).

### Footsteps, cloth and body

- Ghost of Tsushima's samurai combat focuses on "the katana sounds and character Foley" (https://www.asoundeffect.com/ghost-of-tsushima-sound/). For Honor added body and armor layers with Foley and used "processed chains or chainmail" for movement (https://www.asoundeffect.com/for-honor-sound, https://www.mcvuk.com/drums-of-war-for-honors-audio-design/).
- Ghost of Yotei tags assassinations as separate layers (weapon swings, source impacts, target impacts, character foley, haptics, sweeteners) instead of one baked asset (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- God of War places a small humanoid's weapon whooshes at the blade tip and its other sounds at the head; larger enemies get emitters on head, feet, torso and hands (https://asoundeffect.com/god-of-war-sound/).

## 2. Variation and anti-repetition

- Variation methods named by the Conan team: content variation, "pitch and volume randomization, and elemental layering" (https://designingsound.org/2009/12/01/audio-implementation-on-star-wars-the-force-unleashed-and-conan/). Chivalry 2 randomizes "so you never hear the same sound twice in a row" (https://chivalry2.com/2022/06/24/chivalry-2-audio-with-buckley-twitch-stream-recap/).
- Numbers: one guide suggests "at least 3-5 distinct variations" for frequent sounds, pitch "-/+ 2 semitones" and volume "-/+ 1.5 dB" (https://sfxengine.com/blog/common-game-audio-mistakes). Stars Reach's audio lead says footsteps can "get away with eight or even five (I usually use twenty)" and creature vocals need "at least 30", and that layering seven layers of about twenty variants each gives over a billion combinations (https://starsreach.com/stars-reach-audio-insights-part-two/). I found no AAA studio source that publishes exact pitch ranges for sword sounds.
- God of War Ragnarok applied "a new EQ change" on every player attack with a shifting notch filter to avoid frequency repetition (https://asoundeffect.com/god-of-war-ragnarok-game-audio).
- Container modes, using Unity's Random Container as the reference: Sequential, Shuffle ("Remove audio clips from the pool after they've played") and Random; "Avoid Repeating Last" sets how many items play before one can repeat; pitch randomization is in cents (https://docs.unity3d.com/Manual/AudioRandomContainer-UI.html).
- Pitch math: one semitone is a speed multiplier of 2^(1/12), about 1.06 (https://www.gamedeveloper.com/audio/the-power-of-pitch-shifting). In Roblox, PlaybackSpeed "changes both speed and pitch, so 2 plays one octave higher and twice as fast" (https://create.roblox.com/docs/sound/objects), so large pitch shifts also stretch timing (which is why the 0.55 roll sounds slow and grainy, unsourced).
- Memory trade-off: God of War Ragnarok consolidated Kratos's 4 to 8 voices per attack into one file to save memory and cut variations in memory sweeps (https://asoundeffect.com/god-of-war-ragnarok-game-audio). On Roblox, ID-verified accounts can import 2,000 free audio assets per 30 days, unverified accounts 100 (https://create.roblox.com/docs/sound/assets), so asset count is not the constraint (unsourced inference).

## 3. Mixing for readability in group fights

- Priority by threat: Overwatch built a system that "always 'hears' what is important for the player", driven by who is the greatest threat, who the player is looking at and who is looking at the player (https://audiokinetic.com/en/blog/overwatch-game-audio-using-wwise-1). God of War Ragnarok's threat system kept "the things that were directly attacking you" in focus, with player attacks at highest priority and companions lower, and left "finishing moves and impacts" untouched even when combat was deprioritized (https://asoundeffect.com/god-of-war-ragnarok-game-audio).
- Ducking: God of War used side-chain compression to "pull down less significant sounds" during big attacks (https://asoundeffect.com/god-of-war-sound/). Mortal Kombat 1 uses a ducking system so "each hit punches through the mix" (https://www.asoundeffect.com/mortal-kombat-1-game-audio/). Hades keeps effects "out of the way of the vocals or the VO" (https://gameplay.co/hades-game-music-sound-design-darren-korb-supergiant-games/).
- Fewer voices in combat: Ghost of Yotei "significantly reduced" the maximum simultaneous sounds in combat, narrowed the listener cone, attenuated and filtered NPC swings and impacts outside the cone, and turned ambience down during fights (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- Concurrency rules, using Unreal as the reference: a Max Count per group, then a Resolution Rule (Stop Oldest, Stop Quietest, Stop Lowest Priority, Prevent New), optional volume ducking of older instances, a Retrigger Time between plays, and a Voice Steal Release fade (https://dev.epicgames.com/documentation/unreal-engine/sound-concurrency-reference-guide).
- Loudness targets: PlayStation recommends -24 LUFS integrated for console and -18 LUFS for mobile and portable, plus or minus 2 LU, max -1 dBTP (https://audiokinetic.com/en/mastering-a-game-with-wwise-part1). The older IESD guideline gave -24 LUFS console and -16 LUFS mobile (https://www.audiogang.org/wp-content/uploads/2015/04/IESD-Mix-Ref-Levels-v03.02.pdf). Ghost of Yotei measured about -18 LKFS after 6 to 8 hours of play, with combat and UI as the loudest sources (https://www.asoundeffect.com/ghost-of-yotei-game-audio/).
- Listener fatigue: For Honor's team worked to limit fatigue because players spend hours in combat (https://www.asoundeffect.com/for-honor-sound).

## 4. Roblox specifics

### Licensed library

- The Creator Store has "more than 100,000 professionally-produced sound effects and music tracks from top audio and music partners", free to use in games (https://create.roblox.com/docs/sound/assets). Roblox partnered with Pro Sound Effects in March 2022 to upload over 100,000 SFX, searchable by "[name] (SFX)" (https://www.moguravr.com/?p=163858).
- In search results, Pro Sound Effects uploads appear under creator "ProSoundEffects", are named "... (SFX)", and carry a description with a category line such as "Category: Weapons - Knives & Swords", "Category: Metal - Hits" or "Category: Whooshes - Bys" and "Courtesy of Pro Sound Effects" (for example https://create.roblox.com/store/asset/9119747138 and https://create.roblox.com/store/asset/9114156829). APM Music uploads appear under "APMOfficial" (https://create.roblox.com/store/asset/9042807094).
- Many PSE files are 1 to 2 seconds long and hold several hits in one file, for example "Sword Impact, Multiple Metal Hits" (https://create.roblox.com/store/asset/9119747138) and "Metal Clanks, Hollow Pipe Hits, Some Ring, Many Hit Variations" (https://create.roblox.com/store/asset/9116542304). These can be sliced into separate variants with PlaybackRegion (see below).
- Copyright caution (unsourced): many free user uploads are ripped from commercial games. Examples seen in search: one describes itself as "taken straight from silksong audio files" (https://create.roblox.com/store/asset/92333163118441), others are named after Castle Crashers, Warframe, Limbus Company, Bayonetta and Risk of Rain 2. I would not ship these.

### Sound objects (legacy but working)

- Placement: a Sound under a block, sphere or cylinder part emits from the whole surface (volumetric); under an Attachment or MeshPart it is a point source, which the docs suggest for impacts; under SoundService or Workspace it plays everywhere at constant volume (https://create.roblox.com/docs/sound/objects).
- RollOff: RollOffMinDistance is where volume starts to drop, RollOffMaxDistance is the farthest a listener can hear it. Modes are Inverse (default), Linear, LinearSquare and InverseTapered; with Inverse and Linear a low max distance can cut audio off abruptly (https://create.roblox.com/docs/sound/objects). The defaults are min 10, max 10000, Volume 0.5 (observed in Studio with a fresh `Instance.new("Sound")`). Volume ranges 0 to 10 and values above 2 are rarely needed (https://create.roblox.com/docs/sound/objects).
- The default listener location is the Camera (`SoundService.DefaultListenerLocation = Camera`, observed in Studio), so in third person the listener sits behind the player's own character.
- SoundGroups are mixers; each Sound must be assigned through its SoundGroup property, groups can nest, and Volume multiplies (0.5 inside a 0.5 group plays at 0.25). Ducking is done with a CompressorSoundEffect in the low-priority group whose SideChain points at the high-priority Sound or SoundGroup; Threshold -80 to 0 dB, Attack and Release 0.001 to 1 s, Ratio 1 to 50 (https://create.roblox.com/docs/sound/groups). Roblox now calls SoundGroups "discouraged in favor of the more robust functionality of audio objects" (same URL).
- PlaybackRegion is a NumberRange with a PlaybackRegionsEnabled toggle (https://create.roblox.com/docs/reference/engine/classes/Sound). A July 2026 bug where creating Sounds with PlaybackRegionsEnabled made other audio stutter was fixed by a flag in version 734, rolled out August 19, 2026 (https://devforum.roblox.com/t/creatingcloning-sound-instances-with-playbackregionsenabled-causes-stuttering-in-audio-streams/4757400).

### New audio API (AudioPlayer, AudioEmitter, AudioListener, Wire)

- Objects: AudioPlayer plays an asset, AudioEmitter is a virtual speaker, AudioListener a virtual microphone on the camera or character, Wire connects them, plus effects such as AudioEqualizer, AudioCompressor and AudioReverb. A 3D sound needs AudioPlayer, AudioEmitter, AudioListener, AudioDeviceOutput and two Wires; DistanceAttenuation sets volume over distance (https://create.roblox.com/docs/audio/objects).
- The beta announcement (February 2024) lists 15 instances including AudioPitchShifter and AudioFader, says one sound can be emitted from several 3D locations at once, and says effects can be chained or run in parallel, which SoundEffect cannot. It also notes AudioEmitter uses real-world-style attenuation that "doesn't fully decay to zero" (https://devforum.roblox.com/t/2848873).
- AudioEmitter takes a custom distance curve; the docs example sets full volume within 10 studs, 0.4 at 100 and silent past 300 (https://create.roblox.com/docs/reference/engine/classes/AudioEmitter).
- I could not find a post announcing that the audio API left beta. The current docs describe Sound, SoundGroup and SoundEffect as "now discouraged" (https://create.roblox.com/docs/audio/objects), and the `AudioApiRollout` enum still says Automatic "currently behaves the same as Disabled" for voice (https://robloxapi.github.io/ref/enum/AudioApiRollout.html).
- Suitability for combat (unsourced): for short one-shot combat sounds, legacy Sound is simpler (one instance per play versus about six objects and two Wires), already supports PlaybackRegion, PlaybackSpeed randomization and sidechain ducking through SoundGroups, and is what the project uses. The new API wins when you want per-listener effects (underwater, low-health muffle), custom distance curves or one emitter feeding several effects. My call is to keep Sound for now but route every play through one module so the backend can be swapped later.

### Polyphony

- I found no official Roblox number for maximum simultaneous sounds. A devforum thread on the topic has only community guesses ("if there is one it will most likely be beyond 100 sounds") and no staff answer (https://devforum.roblox.com/t/limit-to-amount-of-sounds/776706). The beta announcement also left a question about many simultaneous sounds unanswered (https://devforum.roblox.com/t/2848873). So voice limiting has to be done in your own code (unsourced).

## 5. Creator Store search terms

What worked when searching from Studio (observed in Studio; Creator Store search is semantic, so description words matter as much as names):

- PSE category phrases pull licensed results reliably: "Weapons - Knives & Swords", "Metal - Hits", "Whooshes - Bys", "Courtesy of Pro Sound Effects" plus a noun (whoosh, sword, impact). Example hits: Sword Impact 202 (SFX) https://create.roblox.com/store/asset/9119747138, Metal Impacts 2 (SFX) https://create.roblox.com/store/asset/9116689911, Metal Hits 7 (SFX) https://create.roblox.com/store/asset/9116651688, Axe Clang Twice 1 (SFX) https://create.roblox.com/store/asset/9113224751, Metal Impact Crowbar Railroad Hammer (SFX) https://create.roblox.com/store/asset/9125669419, Scissor Scrape Sharpening Blades Metal Shing (SFX) https://create.roblox.com/store/asset/9125899723 (a usable draw or parry "shing" source), Doppler Whooshes Crackly Airy Bursts 2 (SFX) https://create.roblox.com/store/asset/9114156829.
- Plain terms like "sword swing whoosh", "sword impact flesh" and "sword stab" mostly return user uploads, many ripped from other games.
- The "verified creators only" filter did not help; it returned mostly APM music.
- Suggested query list for the team (unsourced, built from PSE naming style): "Sword Whoosh", "Sword Swish", "Blade Whoosh", "Whoosh Swish Fast", "Whoosh Heavy", "Doppler Whoosh", "Sword Impact", "Sword Clash", "Sword Hit Metal", "Sword Unsheath", "Sword Scrape", "Metal Shing", "Knife Stab", "Knife Slash", "Body Hit", "Body Punch", "Body Fall", "Flesh Impact", "Gore Squish", "Bone Crack", "Armor Impact", "Chainmail Movement", "Leather Creak", "Cloth Movement Fast", "Footstep Scuff", "Sub Boom", "Low Impact Hit", "Cinematic Hit", "Debris Rubble". Add "(SFX)" or a category phrase to bias toward PSE, and filter by duration under 2 s.

## Sound plan for Sword Bound (unsourced unless a URL is given)

### Principles

1. Split every combat sound into attacker side (whoosh, cloth, footstep) and target side (material impact, body, low end, tail), following For Honor and Ghost of Yotei (https://www.asoundeffect.com/for-honor-sound, https://www.asoundeffect.com/ghost-of-yotei-game-audio/). Choose the target layer by what was hit: Flesh, Armor (Sparring Knight), Wood (dummies), Blade (block or parry).
2. Never play the same file twice in a row (shuffle with no repeat of the last 2), and randomize each layer independently so combinations multiply.
3. Hits must outrank swings: duck the swing group about 4 to 6 dB for about 150 ms when a hit plays, the Roblox version of Yotei's sidechain EQ.
4. Time the whoosh so its loudest point lands on the hit frame, not at t = 0. Light hits land at 0.19 s, so start the whoosh around 0.06 to 0.10 s, or keep t = 0 and set PlaybackRegion so the file starts about 0.1 s before its peak.
5. The local player's own combat sounds stay full volume despite the camera listener sitting 10 to 15 studs back.

### PlaybackSpeed values for pitch ranges

PlaybackSpeed = 2^(semitones / 12). Plus or minus 0.5 st = 0.971 to 1.029. Plus or minus 1 st = 0.944 to 1.059. Plus or minus 1.5 st = 0.917 to 1.091. Plus or minus 2 st = 0.891 to 1.122. Volume plus or minus 1.5 dB = multiply Volume by 0.841 to 1.189. Roll the random value per layer per play.

### Events

| Event | Layers | Variants | Pitch (st) | Volume (dB) | Notes |
|---|---|---|---|---|---|
| Light swing L1, L2 | thin blade whoosh, cloth flick | 6 whoosh, 4 cloth | +/-1.5 | +/-1.5 | Each combo step plays 0.5 to 1 st higher than the last (Prosser, https://www.gamedeveloper.com/audio/the-power-of-pitch-shifting) |
| Overhead chop L3 | heavier whoosh, cloth, armor rattle | 4 | +/-1 | +/-1.5 | Slightly lower whoosh than L1 and L2 |
| Spinning finisher L4 | long whoosh with Doppler, cloth, footstep scuff, low air swell | 3 | +/-1 | +/-1 | Longer tail allowed here only |
| Heavy charge | rising metal or air tone loop, cloth tension | 2 | none | none | Raise PlaybackSpeed of the loop toward full charge, like GoW's spear charge-up (https://asoundeffect.com/god-of-war-ragnarok-game-audio) |
| Heavy release | big whoosh, low thump, footstep stomp | 4 | +/-1 | +/-1 | A real heavy whoosh, not the lunge file at 0.75 |
| Thrust (roll Pierce, running attack) | short sharp air pierce, metal shing, footstep scuff | 4 | +/-1 | +/-1.5 | Running thrust adds a dash whoosh at lunge start |
| Lunge or warp | short air dash, footstep scuff | 4 | +/-1.5 | +/-1.5 | Quiet, under the swing |
| Hit flesh, light | blade slice transient, flesh thud, small low thump | 6 slice, 4 thud | +/-1 | +/-1.5 | No metal clink on flesh |
| Hit flesh, heavy or finisher | slice, bigger body impact, sub boom, short debris or blood tail | 4 each | +/-0.75 | +/-1 | Plays at hitstop start and rings through the freeze |
| Hit armor (Sparring Knight) | metal on armor clank, body thud, chainmail rattle | 5 | +/-1 | +/-1.5 | |
| Hit wood (training dummy) | wood knock, cloth or straw | 4 | +/-1.5 | +/-1.5 | Makes dummies stop sounding like metal |
| Counter or riposte hit | flesh heavy layers plus a short bright stinger | 2 stingers | +/-0.5 | none | Extra reward cue |
| Poise break or stagger | heavy impact, metal crunch, low boom, enemy armor clatter | 3 | +/-0.5 | none | High priority |
| Whiff (swing that hits nothing) | the whoosh alone | uses swing pool | as swing | as swing | Never add an impact layer on a miss |
| Block | dull metal clunk, low thump, guard Foley | 4 | +/-1 | +/-1.5 | Keep dull, as the code comment already intends |
| Guard break | big metal crash, low boom, grunt slot | 2 | +/-0.5 | none | Different file from Block, not Block pitched to 0.5 |
| Parry | bright ring, sharp "shing" transient, short reverb tail | 2 to 3 | +/-0.3 | none | Keep the existing streak pitch rise; consistency matters more than variety for a reward cue |
| Perfect parry | parry plus sweetener and a 1 to 2 frame silence of everything else before it | 1 to 2 | none | none | Mirrors the impact frame visual |
| Roll | cloth whoosh, armor rattle, landing scuff | 4 | +/-1.5 | +/-1.5 | Replace the 0.55-speed slash |
| Draw and sheath | real unsheath and sheath, small rattle | 3 each | +/-0.5 | +/-1 | |
| Footsteps in combat | surface step, armor jingle | 8 per surface | +/-1 | +/-2 | Plant steps on lunge start and attack recovery |

### Voice limits and priority

- Priority order: own hits and parries > enemy attacks aimed at you > own swings > other players' hits > other players' swings > footsteps and Foley > ambience and music.
- Per-group caps with steal-oldest and a 60 to 100 ms fade (Unreal-style rules, https://dev.epicgames.com/documentation/unreal-engine/sound-concurrency-reference-guide): swings 6, hits 8, blocks and parries 4, footsteps 8, global combat 24. Use a 30 ms retrigger guard so the same event on the same character cannot stack in one frame.
- SoundGroups under SoundService: Master > Combat (> Player, Others) > Foley > Ambience > Music > UI. Put a CompressorSoundEffect on Others and Ambience with SideChain set to Combat.Player, and one on Combat.Player swings with SideChain set to the hit sounds (https://create.roblox.com/docs/sound/groups). Start around Threshold -30 dB, Ratio 4, Attack 0.005 s, Release 0.15 s and tune by ear.
- Loudness: aim near -18 LUFS integrated with peaks under -1 dBFS, since Roblox play is heavily mobile and headphones (the -18 mobile target is from https://audiokinetic.com/en/mastering-a-game-with-wwise-part1; applying it to Roblox is my call).

### Rolloff (legacy Sound, studs)

| Category | Mode | Min | Max | Notes |
|---|---|---|---|---|
| Own swings, hits, parries | InverseTapered | 20 | 120 | Min above camera distance so the camera listener hears them at full level |
| Other players' and NPC swings | InverseTapered | 8 | 70 | Swings are cheap information past a few meters |
| Other players' and NPC hits, blocks | InverseTapered | 10 | 110 | |
| Parry, guard break, poise break, boss heavies | InverseTapered | 12 | 160 | Readable across a group fight |
| Footsteps, cloth, roll | InverseTapered | 6 | 45 | |
| Draw and sheath | InverseTapered | 6 | 40 | |

Replace the current max of 10000 everywhere; at 10000 every swing on the server is audible to every player (observed default; consequence is my inference). Parent impact sounds to an Attachment at the hit point (point source per https://create.roblox.com/docs/sound/objects) instead of a Part, and parent swing whooshes to an Attachment on the blade tip, as God of War does (https://asoundeffect.com/god-of-war-sound/).

### Implementation steps

1. Build a `CombatAudio` module: `Play(eventName, parent, context)` picks per-layer variants with no-repeat, applies the pitch and volume ranges above, sets SoundGroup and rolloff, enforces the voice caps, and plays the layers with per-layer delays.
2. Slice multi-hit PSE files into variants with PlaybackRegion (now safe on version 734 or later, https://devforum.roblox.com/t/creatingcloning-sound-instances-with-playbackregionsenabled-causes-stuttering-in-audio-streams/4757400) before uploading anything new.
3. Pass DamageType, Weight, Counter and target material (already in the Hit payload) into the module so flesh, armor, wood, light, heavy and counter hits differ.
4. Move the swing call from `OnAttackStart` to a whoosh marker timed so the peak hits at HitStart.
5. Playtest the 4-hit string against the Sparring Knight with 4 to 6 players and listen for repetition, buried hits and fatigue before adding more content.
