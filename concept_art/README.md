# Lantern Engine Concept Art Notes

This folder contains early visual direction for Lantern Engine. The material points to a darker, more atmospheric version of the project than the current top-down prototype, but it is still useful as a tone guide, readability reference, and future art-direction anchor.

## Overall visual direction

Core mood:
- post-collapse ruin exploration
- oppressive darkness with small islands of safety created by light
- the player is vulnerable, underpowered, and visually small relative to the world
- light is not just illumination; it is the main dramatic and mechanical language

Recurring themes:
- collapsed urban spaces
- overgrown wilderness reclaiming civilization
- underground/cavern dread
- narrow flashlight cones cutting through deep black space
- strong occlusion silhouettes and shadow shapes
- a scavenger/survivor character carrying improvised gear and a light source

## What the concept set is good for

Use this folder as reference for:
- atmosphere and tonal target
- player silhouette and gear language
- environment scale and occlusion style
- how darkness/light should frame exploration and combat
- future biome planning
- future UI direction for a more serious survival-horror presentation

Do not treat it as a strict one-to-one implementation target for the current prototype. Some labels and ability names in the text/images appear to come from an earlier or alternate concept pass.

## Key observations from the files

### Character / player-state concepts

#### `base_pose.png`
Shows the core character fantasy clearly:
- lone scavenger
- backpack + flashlight
- grounded, practical silhouette
- readable stance for exploration gameplay

Useful takeaways:
- the player silhouette reads well even in dim scenes
- flashlight direction is visually important and should remain obvious in gameplay
- gear-heavy silhouette fits the world better than a clean heroic fantasy look

#### `flickering.png`
Represents unstable light / low-resource pressure.

Useful takeaways:
- flicker can be used both as gameplay feedback and emotional pressure
- the player’s own equipment can catch light/shadow in interesting ways
- low-light states should feel anxious, not just numerically “low battery”

#### `dashing_or_sprinting.png`
Suggests a mobility state with strong forward momentum.

Useful takeaways:
- movement states should have clear body-language differences
- even in 2D, strong pose language can sell mobility spikes

#### `downed.png`
Good failure-state image.

Useful takeaways:
- dropped light source is a strong visual for defeat
- a low-angle surviving flashlight beam is a good death/downed scene idea

### Gameplay / scene concepts

#### `dungeon_crawl.png`
Strong core loop visualization.

What it communicates well:
- high contrast between safe illuminated corridor and unreadable darkness
- broken walls/debris work as both navigation and light-shaping geometry
- the world feels larger than the player, which helps vulnerability

Gameplay relevance:
- occluders are a major part of the visual identity
- the beam/cone should create “safe-view pockets” and information control
- environment readability matters as much as enemy readability

#### `encounter.png`
Combat presentation mockup.

What it communicates well:
- combat should feel like light colliding with horror, not generic shooting
- enemy weak-point or impact illumination is visually strong
- UI can stay minimal if the light effects are doing enough work

Caution:
- the image/text references older names like Photon Lance / Strobe / Lance, which do not match the current Lantern Engine mechanical naming exactly
- use it as visual inspiration, not canonical mechanic naming

#### `surge.png`
High-intensity room-clear / burst concept.

What it communicates well:
- max-brightness moments should feel overwhelming and cleansing
- a burst ability should visually read as light erupting outward and burning darkness away
- this is especially relevant now that Prism Surge exists in the game

Practical relevance:
- useful reference for future polish on Surge VFX
- strong candidate for the visual fantasy of Light Burn / luminous corrosion effects

### Environment / biome concepts

#### `forest_ruin.png` + `dungeon_crawl_nature.png`
Direction for reclaimed wilderness / black timber spaces.

Takeaways:
- organic occluders can create more irregular, dramatic beam shapes
- forest spaces can feel claustrophobic without being corridor-bound
- charred/alien overgrowth fits the “world gone wrong” tone well

#### `city_facade.png` + `dungeon_crawl_city.png`
Direction for ruined urban spaces.

Takeaways:
- hard-surface occlusion and broken architecture are central to the world identity
- windows, facades, and collapsed interiors can produce strong “light leak” compositions
- the character should remain visually tiny against the city scale

#### `cavern_entrance.png`
Direction for deeper subterranean darkness.

Takeaways:
- good anchor for “ambient light approaches zero” scenarios
- suggests a later biome where dependence on carried light intensifies

#### `overgrown_plains.png`
Direction for a more open but still threatening exterior space.

Takeaways:
- low-height cover can hide enemies in a different way than walls do
- could support future enemy types that rely on partial concealment rather than pure darkness

## Readability implications for the game

The set consistently argues for these design priorities:

1. Light must define gameplay space
   - not just pretty glow
   - the player should read danger, safety, and opportunity through illumination

2. Occluders matter
   - debris, walls, trunks, windows, ruins, and openings should shape both vision and tactics

3. The player should feel small
   - scale is doing thematic work here
   - avoid making environments feel too flat or toy-like if/when visuals are upgraded

4. Darkness should feel oppressive, not empty
   - silhouette, fog, and partial reveal are more important than just lowering brightness

5. Burst light events need payoff
   - Surge-like moments should feel cleansing, dangerous, and dramatically brighter than baseline exploration light

## Naming / canon caveat

`explanations.txt` includes terms like:
- Scavenger
- Light Fuel
- Photon Lance
- Beacon Sacrifice
- Shadow Step
- Strobe

These do not fully match the current shipped Lantern Engine naming/mechanics. Treat them as material from an adjacent concept phase rather than hard canon.

## Recommendation

Use this folder as a visual North Star for future passes, especially when working on:
- Prism Surge VFX
- Light Burn visuals
- future biome identity
- environmental occlusion polish
- player silhouette / animation tone
- death/downed presentation

If this concept direction is meant to become canonical, the next sensible cleanup would be:
- rename `explanations.txt` to a markdown document
- separate canonical Lantern Engine direction from legacy/alternate concept labels
- annotate each image with whether it is character reference, environment reference, combat/VFX reference, or UI reference
