<!-- Research notes compiled 2026-09-25 from public sources (RPGClassics PSIV shrine, Phantasy Star Fandom wiki, VGMaps) and cross-checked against the name tables in the user's PSIV ROM. Facts about the original game for design reference; no original assets. Items marked (unverified) need confirmation. -->
# Phantasy Star IV: The End of the Millennium — Content Bible (research notes)

Sega Mega Drive/Genesis. JP Dec 1993, NA Feb 1995, EU Nov 1995 (Wikipedia). Setting: AW 2284, Algo star system (Motavia, Dezolis, the ruins of Parma, and the hidden 4th planet Rykros).

## 0. Sources, access notes, and confidence conventions

**Sources used (all fetched September 2026):**
- **[RPGC]** RPGClassics PSIV shrine: https://shrines.rpgclassics.com/genesis/ps4/ . Pages: walkthroughs `walkthroughs/part01.shtml` … `part13.shtml`, `bosses.shtml`, `monsters.shtml`, `combo.shtml`, `chrono.shtml` (the technique/skill learning chart), `skills.shtml`, `techniques.shtml`, `items.shtml`, `guild.shtml`, `characters.shtml`. HP values are the author's estimates: regular enemies within about 1–10 HP, bosses less exact, and vehicle battles possibly far off.
- **[FAN]** Phantasy Star Wiki (Fandom), read through the MediaWiki API: https://phantasystar.fandom.com/wiki/Story_of_Phantasy_Star_IV:_The_End_of_the_Millennium , `/wiki/Techniques_in_Phantasy_Star_IV:_The_End_of_the_Millennium`, `/wiki/Skills_in_Phantasy_Star_IV:_The_End_of_the_Millennium`, `/wiki/Items_in_Phantasy_Star_IV:_The_End_of_the_Millennium`, plus individual pages (Aiedo, Krup, Mile, Tonoe, Zema, Kadary, Monsen, Nalya, Piata, Reshel, Motavian Academy Basement, Tonoe Warehouse Basement, Myst Valley, Anger Tower, Vahal Fortress, Weapons Plant, Esper Mansion, Juza, Zio, Seth, Daughter, Rune Walsh, Gryz, Hahn Mahlay, Kyra Tierney, Raja, Demi, Aero-Prism, Rykros). The wiki's story page stops after Garuberk Tower; the later sections are empty.
- **[VGM]** VGMaps atlas (full ripped maps): https://vgmaps.com/Atlas/Genesis/index.htm . Each map is `https://vgmaps.com/Atlas/Genesis/PhantasyStarIV-EndOfTheMillennium-<Name>.png`, for example `...-Motavia-Zio'sFort.png`. I viewed every map image myself and wrote the layout descriptions in §3 from them.
- **[OOC]** "Chaz's Phantasy Star Page" (GeoCities mirror): https://www.oocities.org/timessquare/ring/7674/phantasystar/enemies/enemies.html (enemy *zones*) and `.../phantasystar/combos.html` (combination attacks).
- **[WIKI]** https://en.wikipedia.org/wiki/Phantasy_Star_IV (plot outline and release dates).
- **[LJ]** ladyabaxa, "PS4 Raja Solo part 4": https://ladyabaxa.livejournal.com/85815.html (anecdotal Garuberk Tower enemies).

**Blocked or unavailable:** pscave.com, gamefaqs.gamespot.com, strategywiki.org, neoseeker.com and tcrf.net all returned Cloudflare bot-challenge pages (HTTP 403). web.archive.org and members.tripod.com were unreachable. The only GameFAQs material here is quoted from search-result snippets and is marked as such. pixelguides.org has a PSIV guide, but it contains clear factual errors (for example, it calls Nurvus a "climate-control system" and says Hahn is in the party at Ladea Tower). It looks machine-generated, so I **did not** use it.

**Conventions:** "(unverified)" means from my own recall of the game, or inferred and not confirmed by a source I could read. "(conflict)" means two sources disagree; both values are given. US English names are used, with alternates in parentheses.

---

## 1. Story chapters in order

Party notation: `[Chaz, Alys, …]` lists the active party after the beat. The maximum party size is 5.

| # | Beat | Location(s) | Party changes | Key items / flags | Boss(es) |
|---|------|-------------|---------------|-------------------|----------|
| 1 | Prologue. Alys tells Chaz he is now a full Hunter partner; their first job is at the academy in Piata. | Piata (the VGM map marks the START point inside the academy; Chaz and Alys live in Aiedo) | [Chaz, Alys] | — | — |
| 2 | **Academy Basement.** The headmaster reports biomonsters (Xanafalgue) breeding in the basement. At the basement door they meet Hahn, a student of Professor Holt, and Alys charges him 100 meseta to come along. The bottom floor holds bio-capsules. | Piata Academy Basement | +Hahn → [Chaz, Alys, Hahn] | Flag: after the boss, the headmaster admits Holt went to Birth Valley and that Zio threatened him ("don't go to Birth Valley"). Zio appears. Alys takes the next job for 300 meseta ([RPGC]; 300 per [FAN]). | **Igglanova** (summons Xanafalgue) |
| 3 | Travel north. **Mile** (sandworm ranch, weapon shop). | Mile | — | RPGC advises grinding until Chaz learns Tsu (Lv4). That unlocks the Tri-Blaster combo. | — |
| 4 | **Zema is petrified.** The whole town is stone; two children are hidden in a house basement. In Birth Valley the party finds Holt turned to stone. Alys names the cure, **Alshline**, from the Motavian village Molcum (500 meseta per [RPGC]; 300 per [FAN], conflict). | Zema, Birth Valley (cave floors) | — | Carbon Suit in Birth Valley (right fork on the 2nd level) | — |
| 5 | **Molcum is destroyed** by Zio. **Rune Walsh** waits in the ruins, knows Alys, and invites himself along. He points the party to Tonoe. | Molcum | +Rune → [Chaz, Alys, Hahn, Rune] | — | — |
| 6 | **Krup**, Hahn's hometown: his fiancée Saya, and parents who disowned him. North of Krup, Rune uses **Flaeli** to blast the rocks blocking the cave. | Krup, Valley Maze | — | Flag: rock barrier removed | — |
| 7 | **Tonoe.** Grandfather Dorin (Alys punches him over his joke about her measurements). Dorin assigns **Gryz**, a Molcum survivor, to guide the party. **Rune leaves** with Dorin on business of his own; he later turns up at Ladea Tower. Pana (Gryz's sister) tells what happened at Molcum. | Tonoe; Tonoe Warehouse Basement | +Gryz, −Rune → [Chaz, Alys, Hahn, Gryz] | **Alshline** (bottom of the basement, alongside an Escapipe chest). Titanium Crown on the 3rd level. Gryz opens the rusted door with a hidden switch [FAN]. | — |
| 8 | Return to Zema and cure the town. Holt restarts his investigation. An explosion follows: a **second Igglanova** attacks in front of Birth Valley. | Zema | Gryz stays to hunt Zio [FAN] | Flag: Zema shops and inn unlock (they are locked until the cure [FAN]) | **Igglanova (2nd)** (RPGC: use plain attacks, not techs/skills) |
| 9 | **Bio-Plant** (Bio-Lab, deep inside Birth Valley). Holt is found protected by **Rika**, a Numan. The AI **Seed** explains that Motavia's control systems are malfunctioning and breeding monsters. Nurvus must be shut down, and only the android Demi (Zio's captive) can do it. Seed asks the party to take Rika. On exit, Seed self-destructs the plant. | Bio-Plant | +Rika → [Chaz, Alys, Hahn, Gryz, Rika] | Graphite Crown (left elevator), Ceramic Sword (wire-floor area) | — |
| 10 | The bridge is repaired. **Nalya** is half-destroyed by a "meteorite": the crashed Parma escape ship, the **Wreckage**. The control deck logs describe the refugee ship that orbited for 1000 years (ties to PSIII). | Nalya, Wreckage | — | Ceramic Shield, 1500 meseta, Ceramic Knife, Ceramic Mail | — |
| 11 | **Aiedo** is home: free rest at Chaz and Alys's house, and the **Hunter's Guild** opens (optional jobs; see §2). Optional first job: the **Sand Worm** at Mile. A cave north of Aiedo (the **Passageway**) leads to Kadary, the Church of Zio. | Aiedo, Mile ranch, Passageway, Kadary | — | Laser Slasher (Kadary house, reached along the outer wall) | Optional: **Sand Worm** (Guild, 1450 HP) |
| 12 | **Zio's Fort.** A magic barrier seals the stairs down at the entrance; they lead to Nurvus. The party climbs to the top and kills Juza, and stairs appear. **Demi** is freed and heals everyone with Medical Power. Zio casts Magic Barrier and is invulnerable. He fires the **Black (Energy) Wave** at Chaz; **Alys takes the hit**. The party retreats to Krup (Ryuka). | Zio's Fort | +Demi. Alys is incapacitated and stays in Krup. RPGC says to unequip Alys and Hahn before the top, which implies both are about to leave the active party. | Laser Sword, Moon Dew, Laser Barrier, Laser Claw | **Juza**; **Zio (1st)**, an unwinnable scripted loss |
| 13 | At Krup, Alys asks for Rune. Gryz says Rune went to **Ladea Tower** beyond the quicksand. Demi knows of a **Land Rover** at a **Machine Center** south of Krup. Chaz asks Hahn to stay with Alys. | Krup, Machine Center | −Hahn (stays with Alys) → [Chaz, Gryz, Rika, Demi] | **Control Key**, then the **Land Rover** (crosses quicksand) | — |
| 14 | **Monsen.** Earthquakes (Gryz is scared of them). Demi blames the **Plate System** and shuts it down. | Monsen, Plate System | — | Ceramic Armor, Titanium Gear (Demi), **Phonon Maser** ("Phonomezer", Demi's best skill), Laser Axe, Stun Shot | — |
| 15 | East across more quicksand to **Termi** (shop town), then south to **Ladea Tower**. Rune is found partway up (2nd floor per [FAN] story; 3rd floor per [FAN] Rune page; the conflict is probably 1-based vs 0-based floor counting). He rejoins and wants the **Psycho Wand**, the only thing that can break Zio's barrier. | Termi, Ladea Tower | +Rune → [Chaz, Gryz, Rika, Demi, Rune] | **Frade Mantle** (5F, a PSI item nod), **Psycho Wand** (top) | **Gy-Laguiah** (guards the Psycho Wand) |
| 16 | **Alys dies.** Rune, Rika and Demi sense danger and the party returns to Krup. Alys's last words are "Chaz... thank... you...". She is buried in Krup's cemetery. Rune talks with Chaz; Rika comforts him. Hahn returns to Piata [RPGC]. | Krup | Alys permanently gone. Hahn gone until the finale. | — | — |
| 17 | **Nurvus.** Rune breaks the barrier in Zio's Fort with the Psycho Wand, and the party descends into Nurvus. In the core, Rune dispels Zio's barrier and **Zio** is killed ("Dark For— AAARGH!"). Demi inserts herself into Nurvus. She reports that the orders come from the satellite **Zelan**, and a shuttle is prepared. | Zio's Fort (barrier), Nurvus | **−Gryz, −Demi** after Zio [RPGC] → [Chaz, Rika, Rune] | Wave Shot, Ceramic Gear, Spaced Armor, Plasma Claw. A **Spaceport** appears above Nurvus / the ruined Zio's Fort. | **Zio (2nd)** |
| 18 | **Zelan.** The android **Wren** says the rogue sister satellite **Kuran** has taken over control. | Zelan (satellite) | +Wren → [Chaz, Rika, Rune, Wren] | Plasma Sword, Plasma Claw, **Canceller** (silences encounters, per [RPGC] item text) | — |
| 19 | The shuttle to Kuran is sabotaged in the engine room. The shuttle **crash-lands on Dezolis**, on **Raja's temple** (the "Ryuon Temple" per RPGC). The priest **Raja** joins in exchange for not being charged for the damage. | Shuttle, Raja Temple | +Raja → [Chaz, Rika, Rune, Wren, Raja] | — | **Chaos Sorcerer** |
| 20 | **Ryuon.** Gyuna the bartender says to check the founder's grave in **Tyler** (the Parmanian town). Chaz slips on a panel at the grave, which opens the underground **Hangar**; the spaceship **Landale** is inside. | Ryuon, Tyler, Tyler Hangar (cave) | — | **Landale** (spaceship); Zirconian Gear | — |
| 21 | Optional Motavia jobs are now available (Earth Hole "Fissure of Fear", Missing Student). | Monsen / Earth Hole; Piata; Termi; Kadary | — | — | Optional: **Fract Ooze** |
| 22 | **Kuran.** A growth on the main console is **Dark Force**. Rune recognises it ("I've seen it before"). Wren repairs Kuran. | Kuran | — | **Hyper Jammer** (Wren skill), Zirconian Armor, Napalm Shot | **Dark Force (1st)** |
| 23 | Back at Zelan, the blizzard on Dezolis continues. Wren provides the **Ice Digger**. | Zelan → Dezolis Spaceport | — | **Ice Digger** (breaks ice walls) | — |
| 24 | **Zosa** (shops). **Myst Valley** is a warm cave of Musk Cats. The Old Man (implied to be PSI's Myau) gives the **Silver Tusk**, a weapon for Rika. | Zosa, Myst Valley | — | **Silver Tusk** | — |
| 25 | **Climate Control Center** (NE of Zosa). Wren suspects it; Raja insists the tower is the cause. Gy-Laguiah (again) blocks the entrance. At the end D-Elm-Lars says it was all a trap. | Climate Control Center ("Climatrol") | — | Pulse Vulcan, Compound Gear/Armor | **Gy-Laguiah (2nd)**, **D-Elm-Lars** |
| 26 | **Reshel** is ruined and full of zombies. **Meese** has a plague that started when Garuberk Tower appeared. **Raja falls ill** with the Black Energy Wave sickness and is left in bed. The esper **Kyra** has gone to Garuberk alone. The party fights the **carnivorous trees**, which cannot be beaten (retreat), and rescues Kyra. | Reshel, Meese, carnivorous forest | −Raja (sick in Meese), +Kyra → [Chaz, Rika, Rune, Wren, Kyra] | Flag: forest impassable | **Carnivorous Tree** (unwinnable, 250 HP each, regrows) |
| 27 | **Esper Mansion.** Guards refuse, but give way to Rune. Lutz's room holds only the Telepathy Ball: **Rune is the 5th-generation Lutz**. Dark Force returns every 1000 years; the balance was weakened by Parma's destruction; Rune names Chaz the hero. The **Eclipse Torch** can burn the forest. | Esper Mansion | — | Reflect Robe, Laconian Rod | — |
| 28 | **Jut** has the best shops. **Gumbious Temple**: the honor guard refuses to lend the torch. Three **Xe-A-Thouls** teleport in, steal the **Eclipse Torch**, and taunt Rune. The trail points to the **Air Castle** (Lashiec) in the asteroid belt where Parma was. | Jut, Gumbious Temple | — | — | — |
| 29 | Optional: the **Weapons Plant** (SW of Jut). | Weapons Plant | — | **Burst Rocket** (Wren skill), Elastic Gear/Armor, Plasma Launcher, unlimited Repair Kits at a terminal | — |
| 30 | **Air Castle** (via the Landale from the Dezolis Spaceport). Kill the three Xe-A-Thouls. A fake torch turns into a Spector. The zombie **Lashiec** attacks. Rika snatches the Eclipse Torch as he dissolves ("I must work for Him forever"). The castle explodes. | Air Castle | — | Swift Helmet, Genocide Claw, **Eclipse Torch** | **Xe-A-Thoul ×3**, **Spector** (decoy), **Lashiec** |
| 31 | The torch is lent (to be returned). Chaz burns the forest and enters **Garuberk Tower**, a living, fleshy tower with veins, eyeball switches and vacuole elevators. At the top is a scorpion-like **Dark Force (2nd)**. The tower disperses and the blizzard ends. **Kyra leaves** for Meese. | Garuberk Tower | −Kyra → [Chaz, Rika, Rune, Wren] | **Moon Slasher** (Kyra), Power Shield (casts Shift), Star Dew | **Dark Force (2nd)** |
| 32 | **Gumbious Temple is destroyed.** The Bishop explains that Dark Force is only a tool of the **Profound Darkness**. Dark Force sought **Rykros**, and the **Aero-Prism** will reveal it. Rune: the prism lies in the **Soldier's Temple** on the island east of Krup. The torch is returned. Reshel is being rebuilt (best armor shop once finished). | Gumbious Temple (ruined), Reshel | — | — | — |
| 33 | On Motavia, Demi gives the party the **Hydrofoil**. Late Guild jobs open (see §2). | Motavia Spaceport | — | **Hydrofoil** | Optional: **Dominator ×3** (Vahal Fort / Daughter); **King Rappy** (Rappy Cave) |
| 34 | Optional **Vahal Fort** (Silver Soldier job): the AI **Daughter** is purging other AIs. Wren shuts it down. | Zema (android attack), Vahal Fort | — | **Positron Bolt** (Wren), Photon Eraser, Laconian Gear/Armor | Dominators ×3 |
| 35 | **Island Cave → Soldier's Temple.** The archaeologist **Seth** joins, praising Chaz as he fights. The **Aero-Prism** fires a beam at the sky (Wren records its bearing), and the light reveals **Seth as Dark Force**. | Island Cave, Soldier's Temple | +Seth (temporary) → [Chaz, Rika, Rune, Wren, Seth]; then −Seth (he is Dark Force) | **Aero-Prism** | **Dark Force (3rd)** (fought by 4) |
| 36 | **Rykros.** The Landale follows the beam; the prism flashes again and reveals the hidden planet. A voice (**Le Roof**) at the **Silence Temple** demands trials in the Strength and Courage Towers. | Rykros: Silence Temple | — | **Guardian Sword** (Silence Temple) | — |
| 37 | **Strength Tower** (NW of the Silence Temple). | Strength Tower | — | 2× Guardian Claw, Guardian Rod; boss drops **Parma, Mota, Dezo Rings** | **De-Vars** |
| 38 | **Courage Tower** (SE of the Silence Temple). | Courage Tower | — | Guardian Armor (Wren), Guardian Mail, Guardian Robe; boss drops **Rykros Ring** and **Algo Ring** (Algo Ring is Chaz's) | **Sa-Lews** |
| 39 | Silence Temple: Le Roof recounts the **Genesis of Algo** (the Great Light and the Profound Darkness). Chaz rails against "the mission". Rune sends the party back to Lutz's room. | Silence Temple | — | — | — |
| 40 | **Elsydeon**: the cave beneath Lutz's room at the Esper Mansion holds a statue gripping the sacred sword. Visions of PSI/PSII, Alis, Nei and Alys follow. | Esper Mansion, lower cave | — | **Elsydeon** | — |
| 41 | Demi calls: a **hole (the Edge)** has opened north of Piata / south of **Mile** [RPGC wording], and everyone in **Mile** is dead (Black Energy Wave). **Reunion** at the spaceport: Hahn, Gryz, Demi, Kyra and Raja; **choose 1** for the final party. | Spaceport, Mile | Final party = [Chaz, Rika, Rune, Wren] + 1 of {Hahn, Gryz, Demi, Raja, Kyra} | Returning members arrive with late-game gear [FAN] | — |
| 42 | Optional **Anger Tower** (Rykros, next to the Courage Tower; entry needs Elsydeon). Chaz alone meets an **illusion of Alys**; then **Re-Faze** offers a technique that turns anger into power. Say **"No"** and he teaches **Megid** anyway. Saying yes means fighting him. | Anger Tower | Chaz solo inside | **Megid** (Chaz); a Guardian Mail | **Alys (illusion)** 500 HP; **Re-Faze** (optional; [FAN] claims 1,000,000 HP, unverified) |
| 43 | **The Edge** leads into the Profound Darkness's dimension. | The Edge | — | Defeat Axe (Gryz, rare drop from Chaos Bringer, per [RPGC]) | **Profound Darkness**, 3 forms |
| 44 | Ending. **Elsydeon shatters** to shield the party from the collapsing dimension. Everyone parts; **Rika stays with Chaz** [WIKI]. | — | — | — | — |

Sources: [RPGC] walkthrough parts 1–13; [FAN] story page (through Garuberk) and character/location pages; [WIKI].

---

## 2. Towns in order of first visit (per planet)

Sources: [RPGC] walkthrough parts 1–13 and `guild.shtml`; [FAN] town pages. Positions come from the [VGM] world maps `…-Motavia.png` and `…-Dezolis.png`.

### Motavia (2nd planet)

| Order | Town | Map position | Services / notes |
|---|---|---|---|
| 1 | **Piata** (Town of Learning) | SW part of the main continent | Motavia Academy (headmaster; entrance to the basement dungeon), dorms (Missing Student job), inn (5/person [FAN]), tool shop (Monomate only [FAN]) |
| 2 | **Mile** | W-central, next to the Edge crater | Sandworm ranch (Ranch Owner job; Sand Worm boss); weapons/armor/tools (Steel Sword, Hunter Knife, leather gear). **Destroyed late-game**: all residents dead and every building sealed [FAN]. |
| 3 | **Zema** | N-central | Entrance to Birth Valley. Petrified until the Alshline is used, and shops/inn are locked until then [FAN]. Shops: Broad Axe, Slasher, Graphite Suit, Carbon Shield, etc. Late-game: androids roam the town (Silver Soldier job). |
| 4 | **Molcum** | S-central (south of Zema) | Destroyed Motavian village; Rune is met here. No services. |
| 5 | **Krup** | S, next to the circular lake with the Soldier's Temple island | Hahn's home (father = armorer), Saya's school, Alys's grave. Armor/tools/inn (15/person). |
| 6 | **Tonoe** | NE of Valley Maze | Motavian tent town. Shops are hidden in the market stalls on the east side [RPGC]; Titanium gear. Grandfather Dorin, Pana. Warehouse basement dungeon (back tent). |
| 7 | **Nalya** | Far north | Partly destroyed by the Wreckage crash. Tools; inn (25). |
| 8 | **Aiedo** | NW | Home of Chaz and Alys (free rest), **Hunter's Guild** (N part of town), Ceramic shop, Shortcake shop (around the town walls), fortune teller, jail (Strain in Life job) |
| 9 | **Kadary** | W, through the Passageway cave from Aiedo | Church of Zio. Tool shop, inn (40). Laser Slasher in a house. |
| 10 | **Monsen** | E-central | Earthquake event (Plate System). Tools, inn (45). The crack outside a house leads to the **Earth Hole** (Fissure of Fear). |
| 11 | **Termi** | Far east (across the quicksand) | Psychic Mail/Crown shop; Perolymate (Missing Student job); "Alis' Sword" (Dying Boy job) |
| 12 | **Tornico** | SE | Man with a Twist job (King Rappy); Dying Boy job. Reached by Hydrofoil [RPGC]. |
| 13 | **Uzo** | SW island | Strain in Life job (the mayor's daughters). Hydrofoil access [FAN]. |
| — | Spaceport | Above Nurvus / Zio's Fort | Healing pad; launch to Zelan, Kuran, Dezolis, Air Castle and Rykros |

### Dezolis (3rd planet, frozen)

| Order | Town | Position | Services / notes |
|---|---|---|---|
| 1 | **Raja Temple** | SW | Crash site; Raja joins. |
| 2 | **Ryuon** | N of Raja Temple | Silver Mantle/Circlet, Force Cane; pub with bartender **Gyuna** (spaceship hint) |
| 3 | **Tyler** (Parmanian town) | W edge | Silver gear. The founder's grave (west side) opens onto the **Hangar** cave and the Landale. |
| — | Dezolis Spaceport | — | Healing pad (the Ice Digger starts here) |
| 4 | **Zosa** | N-central (NE of Ryuon, Ice Digger) | Flame Sword, Thunder Claw |
| 5 | **Reshel** | N-central | Ruined and full of zombies at first. After Garuberk it is rebuilt in stages and ends with the **strongest armor shop** (Laconian gear) [FAN][RPGC]. |
| 6 | **Meese** | NE-central | Plague / Black Energy Wave clinic; Raja falls ill here. Reflect Mail. Late-game shop sells Star Dew and Sol Dew [RPGC]. |
| 7 | (Esper Mansion) | Far east | Espers; Lutz's room; Elsydeon cave |
| 8 | **Jut** | Center (SW of Gumbious) | Best weapons (Laconian Sword, etc.), church |
| 9 | (Gumbious Temple) | Center-north of Jut | Eclipse Torch shrine; destroyed after Garuberk |

### Rykros (4th planet)
No towns. The Silence Temple (voice of Le Roof) acts as the hub; the Strength, Courage and Anger Towers surround it ([VGM] `…-Rykros.png`).

### Space
Zelan and Kuran satellites; Air Castle (asteroid belt where Parma was).

### Hunter's Guild jobs (Aiedo) [RPGC guild.shtml]

| Job | Reward | Unlocks | Task |
|---|---|---|---|
| The Ranch Owner | 5000 | On first reaching Aiedo | Kill the oversized Sand Worm at the Mile ranch |
| Tinkerbell's Dog | 2000 | After Alys falls ill | Buy Shortcake in Aiedo and feed the dog Rocky at Monsen (or Termi) |
| Missing Student | 3000 | After the Landale | Perolymate from Termi; the student is in Zio's Church at Kadary |
| Fissure of Fear | 5000 | After the Landale | Monsen boy in the crack: Earth Hole, **Fract Ooze** |
| The Strain in Life | 50,000 | After the Bishop | Uzo mayor's daughters: pay their 50,000 bail at Aiedo jail |
| The Dying Boy | 10,000 | After the Bishop | Tornico: give an "Alis' Sword" (bought in Termi) to a sick boy |
| Man with a Twist | 20,000 | After the Bishop | Tornico: kill **King Rappy** in Rappy Cave. The client turns out to be in the wrong and **no payment** is made. |
| Silver Soldier | 80,000 | After the Bishop | Zema androids: **Vahal Fort**, shut down **Daughter** |

---

## 3. Dungeons in order

All layout descriptions are my reading of the [VGM] map images (URL pattern in §0). Compass directions are map-relative (north = up). "Stairs" includes elevators and doors that change floors. Floor counts are the separate map sections VGMaps draws.

### 3.1 Piata / Motavia Academy Basement (Motavia): 3 levels
- **Map:** `…-Motavia-Piata&MotaviaAcademyBasement.png`
- **Entrance:** stairs in the academy's rear (north) courtyard building, top-right corner.
- **B1:** a wide rectangular block entered at its **NE corner**. A corridor runs west along the north wall with a comb of 3 short northward notches. There is a small side room with a chest at the SW, and a central chamber with bookshelves. Stairs down are in a north notch near the center.
- **B2:** a long **E–W corridor**. Two rooms open off its north side: a west-central study with a chest and desk, and a narrow NE room holding the arrival stairs. The exit stairs are at the **far west end**.
- **B3 (boss):** a small **N–S lab** with 6 glass capsules along the walls. Enter at the south; **Igglanova stands at the north end**.
- **Loot:** 3 chests (100 meseta, an Antidote, a Monomate) [FAN].

### 3.2 Birth Valley (Motavia): 2 cave levels, leading into the Bio-Plant
- **Map:** `…-Motavia-Zema&Birthvalley&Biofactory.png`
- **Entrance:** a cave mouth at the **north edge of Zema**.
- **Cave 1:** a zig-zag gorge running S→N with a few dead-end pockets.
- **Cave 2:** a winding S→N gorge with a side branch east. The right fork on the 2nd level has a Carbon Suit [RPGC]. Stone Holt stands near the Bio-Plant door at the north end.

### 3.3 Bio-Plant (Bio-Lab) (Motavia): about 6 linked sections, a sci-fi lab
- **Map:** same file as 3.2.
- **Entry:** a narrow **N–S corridor in 3 segments** separated by doors, where scanning lights scare Chaz and Hahn. An elevator leads to the **Central Hub**.
- **Central Hub:** cross/crab-shaped. A ring corridor circles a central pillar block, with **4 claw-shaped side wings** (NW, NE, SW, SE); the NE wing holds a chest. From its south edge, two elevators split the route:
  - **West branch:** an L-shaped **wire-grate corridor** runs west, then north up a long grated spine with side rooms on the west (chests). It dead-ends at a small room in the north (treasure: Graphite Crown via the left elevator [RPGC]).
  - **East branch:** a J-shaped corridor leads to the **Capsule Hall**, a tall grated N–S spine with **3 pairs of capsule rooms** mirrored left and right. This is where the capsules shipped to the academy came from. Its top-right elevator leads to a long E–W catwalk.
- **Network Maze:** the catwalk leads south into a maze of thin conduit-like paths linking small square rooms (circuit-board look).
- **Final section:** an L-shaped room connects to twin **U-shaped rooms stacked vertically** (Holt and Rika). A last elevator goes to **Seed's room**: a T-shaped chamber with a wall of monitors along the north.
- **Gimmicks:** multiple elevators; wire-grate floors.
- **Loot:** Ceramic Sword is on the wire floor [RPGC].

### 3.4 Valley Maze (Motavia): 4 cave sections, Krup→Tonoe
- **Map:** `…-Motavia-Valleymaze.png`
- Enter from the **south**. **S1** is a Z-shaped cave with **two exits north**: the east exit leads to a small dead-end pocket with a pool and chest. **S2** is a U/W-shaped cave with **two north exits**. The left exit is the true path to **S3**, a long narrow N–S cave. The right exit leads to a large pond room with a chest.
- The final exit loops back to the overworld on the Tonoe side.
- RPGC: "not much of a maze. Just go up; if it dead-ends, go the other way."

### 3.5 Tonoe Warehouse Basement (Motavia): 3 storage floors + 1 cave
- **Map:** `…-Motavia-Tonoe.png`
- **Entry:** from the back (north) tent of Tonoe. Gryz opens the rusted door with a hidden switch [FAN].
- **B1:** a big square room with a **long double wall down the middle** and scattered crates. Arrive at **south-center**; stairs down are at the **north-center/right**.
- **B2:** a **3×3 grid of shelving blocks** forming corridors. Arrive **top-left**; exit **bottom-right**.
- **B3:** four quadrant blocks separated by a cross-shaped aisle, with more crates. Arrive at the bottom-left notch; the exit stairs are in the bottom-right notch.
- **Cave (bottom level):** an L-shaped rocky cavern opening from a masonry corridor. Enter at the SE; the **Alshline chest** and an Escapipe chest are in the west part.
- **Loot:** Titanium Crown on the 3rd level [RPGC].
- **(conflict)** [FAN] says the Alshline is on the "second level"; [RPGC] and the map put it at the bottom.

### 3.6 Wreckage (Motavia): crashed ship, about 6 sections
- **Map:** `…-Motavia-Wreckage.png`
- **Entrance:** a gap in the hull at the SE, from the desert.
- **Lower Hull:** a **3-row horizontal corridor grid** with N–S connectors (a ladder-like maze), rubble patches, and 2 exits north.
  - The right exit leads to a small room with a chest (Ceramic Shield and 1500 meseta [RPGC]).
  - The left exit leads to a tall **N–S shaft**, then a corridor west with an alcove chest, then a small elevator room.
- **Node Maze:** a **4×3 lattice of square nodes joined by catwalks** (Ceramic Knife; Ceramic Mail up and to the right). Top exits: one to a small chest room, one to an L-room with an elevator.
- **Upper Deck:** a long E–W deck, then a narrow corridor north to the **Control Deck** (bridge with consoles), which holds the PSIII lore log.

### 3.7 Passageway (Motavia): 1 cave level, Aiedo→Kadary
- **Map:** `…-Motavia-Passageway.png`
- Enter at the **SW**, exit at the **NE**. A long cave runs north, then east along the top edge. Diagonal side branches hang south from the top corridor (2 of them end in chests), and one broad diagonal branch runs SE from the NW junction to a chest.

### 3.8 Zio's Fort (Motavia): hub-and-turret castle
- **Map:** `…-Motavia-Zio'sFort.png`. The connection reading below is partly interpretive (unverified).
- **Entrance Hall (south):** a long red carpet runs north to a **magically sealed staircase down**, which leads to Nurvus later. Doors west and east open onto **outdoor bridges**, each leading to a **corner turret**. Each turret's stairs go up to the 2nd floor.
- **Courtyard (middle):** a large sand yard with a central octagonal keep (a pool in the center) and **6 small round turrets** (NW, NE, W, E, SW, SE). Each turret's stairs link, color-coded in pairs, to specific points on the 2nd floor.
- **2nd floor ("ring"):** a huge ring-shaped floor around an open central void. There are staircases in 4 lobes, a long E–W bridge crossing the void with chests, and a north gate room connecting back down to the keep.
- **Top (Demi's cell):** reached by stairs that **appear after Juza is killed**. Walkthrough route per [RPGC]: first room → left stairs (Laser Sword above; a hole drops to a Moon Dew) → the right-hand counterpart (Laser Barrier; stairs to a Laser Claw) → Juza → the top.
- **Gimmicks:** a magic barrier blocking the down-stairs (Psycho Wand later); holes that drop you to lower rooms with loot.

### 3.9 Machine Center (Motavia): 3 small rooms
- **Map:** `…-Motavia-MachineCenter.png`
- It rises out of the ground south of Krup. Surface room → elevator → a T-shaped control room (Control Key, and a teleport pad at the east) → a south corridor to the **Land Rover** bay.

### 3.10 Plate System (Motavia): surface building + 3 levels
- **Map:** `…-Motavia-PlateSystem.png`
- **Surface:** a building with a **blue water/tiled floor**. Enter at the **south**; a winding path leads to stairs in the **NW**.
- **L1:** a **cross-shaped central hall** with **4 grated quadrant wings** (NW, NE, SW, SE) with chests. The exit is at **south-center**.
- **L2:** arrive at **north-center**, then a spine down to a big E–W hall and a central **square ring room**. Two exits at the **SW and SE** corners lead to L3 (Ceramic Armor and Titanium Gear on this "2nd floor" [RPGC]).
- **L3:** **two mirrored U-shaped corridors** wrap a central **cross-shaped chamber** with chests (Phonon Maser via one elevator; Laser Axe via the other [RPGC]). The chamber's stairs lead to the **Control Room**: a T-shaped hall running north to the console (Stun Shot chest; Demi shuts the system down).
- **Gimmicks:** paired elevators, and conveyor-like dashed guide lines.

### 3.11 Ladea Tower (Motavia): 6 floors, shrinking as you climb
- **Map:** `…-Motavia-LadeaTower.png`. A GameFAQs FAQ (Goldenguy, search snippet) also says "six floors".
- **1F:** an **octagonal plaza** with 8 pillars ringing a central circular dais. Enter at the **south**; the only stairs are at the **center** [RPGC: "only 1 stair on the first level"].
- **2F:** an oval of concentric ring-walls. Arrive at the center; two stairs at the **south-left and south-right** split the route (left = treasure, right = toward Rune [RPGC]).
- **3F:** oval. Arrive at the south corners; stairs at **north-center** (Rune is met around here).
- **4F:** a smaller oval split by a central N–S wall. Stairs are at the SW and SE.
- **5F:** narrow, with a central column of tiles. **Frade Mantle** chest; the left stairs lead to extra treasure.
- **6F (top):** a small circular shrine. The Psycho Wand chest sits in a barrier at **north-center**; enter from the south. **Gy-Laguiah** attacks here.

### 3.12 Nurvus (Motavia): large tech complex under Zio's Fort
- **Map:** `…-Motavia-Nurvus.png`
- **Entry:** through the sealed stairs of Zio's Fort, arriving in a small green room at the **SE**.
- **East block:** a symmetric hall with twin north corridors → a U-arch → a **terminal** on the wall (left = Wave Shot; right = continue [RPGC]).
- **Comb Corridor:** a long E–W corridor with **three north stubs** (elevator heads). Two long single-file drop shafts hang south from it.
- **West Complex:** a large "horseshoe" of two tall parallel N–S corridors with nested inner corridors and many color-coded elevators. There is an NW side room with 2 chests (Ceramic Gear via the left elevator; Spaced Armor further on [RPGC]).
- **Twin Bridges:** two parallel **catwalk bridges** span a gap between two tower pillars. Taking the door instead of the elevator leads to a Plasma Claw [RPGC].
- **Final:** a south corridor → an elevator up → **Zio's core room** at the far west, with a wide bank of computers along its north wall.
- **Gimmicks:** many one-to-one elevators (the map color-codes about 8 pairs), so the route is a teleport puzzle more than a maze.

### 3.13 Earth Hole (Motavia, optional): 1 cave
- **Map:** `…-Motavia-Monsen&EarthHole.png`
- Drop in through the crack in Monsen; you land **mid-cave, near the top**. A long serpentine cave runs E–W with switchbacks. The boy and the **Fract Ooze** are at the **NE tip**; the exit is at the **west end**.

### 3.14 Zelan (satellite): 2 sections
- **Map:** `…-Motavia-Zelan.png`
- **South Dock:** a long N–S corridor from the shuttle dock → an elevator → a **cross-shaped hall** with east and west side rooms (3 chests each) → a north corridor → the wide **Control Room** (Wren stands at the top center).
- **Loot:** Plasma Sword, Plasma Claw, Canceller [RPGC].

### 3.15 Tyler Hangar (Dezolis): 1 ice cave
- **Map:** `…-Dezolis-Tyler&Hanger.png`
- Enter at the **NE** from the grave. The cave widens SW, with 3 side branches holding chests (Zirconian Gear [RPGC]). The exit at the **SW** leads to the Landale.

### 3.16 Kuran (satellite): about 5 sections
- **Map:** `Kuran.png`
- **Entrance Spine:** from the dock at the bottom, a long N–S corridor leads to a junction corridor.
- **Circuit Hall:** a central, almost circular maze of **nested corridors with 2 enclosed inner rooms**, entered from the south. Elevators link it to:
  - **Elevator Shaft (west):** a tall vertical shaft (grated) with **4 landing platforms**, each with side rooms and chests. It hosts Hyper Jammer "a little ways in", Zirconian Armor (left branch) and Napalm Shot (right, after an elevator) [RPGC].
  - **Spiral:** a **square-spiral corridor** (concentric), walked inward to its center, then an elevator.
- **Core (far east):** a T-shaped room with a console bank on the north wall. **Dark Force (1st)** is here. RPGC says it is similar to Zelan's top room.

### 3.17 Myst Valley (Dezolis): 5 small cave sections
- **Map:** `…-Dezolis-MystValley.png`
- Enter at the **south**. S1 is an S-bend cave with a chest pocket (NE). S2 is a hub cave with **3 north exits**:
  - the right pair leads to a looped chamber with a chest;
  - the left exit leads to a long E–W corridor, which leads to the **Old Man's chamber** (musk cats; the Silver Tusk), a raised ledge at the NW.
- No boss.

### 3.18 Climate Control Center (Dezolis): 4 sections
- **Map:** `…-Dezolis-ClimateControlCenter.png`
- **Outer Building:** a square building ringed by a water moat. Enter at **south-center**. Inside is a **maze of blue rooms and corridors** around a central stair room; 3 side stairs lead to the grated level. **Gy-Laguiah (2nd)** fights you on entry [RPGC part 9; RPGC bosses lists Gy-Laguiah at "Ladea Tower/Climate Control"].
- **Grated Level:** a big symmetric grated-floor complex. An H-shaped north section connects to a U-shaped south section, with several small stair rooms along the bottom. The exit is at **north-center**.
- **Ring Room:** an oval ring corridor around an inner hook-shaped wall. Arrive at the north; the exit is in the inner hook.
- **Final Room:** a cross-shaped chamber with a console at the top. **D-Elm-Lars** waits at the "end of the line".
- **Loot:** Pulse Vulcan, Compound Gear/Armor.

### 3.19 Esper Mansion (Dezolis): building + inner sanctum
- **Map:** `…-Dezolis-EsperMansion.png`
- **Front Court:** the gate on the south wall → the main hall, an **H/U-shaped corridor** around a central statue sanctum (the statues of the beautiful woman), with 4 corner doors to side buildings (bedrooms, library, a statue room, a chest room with Reflect Robe and Laconian Rod).
- **Inner Sanctum:** a north-center guarded door (opens only for Rune) → the inner hall → stairs down to **Lutz's Room** (Telepathy Ball).
- **Elsydeon Cave:** below Lutz's room, late-game [RPGC]. It is **not** in the VGMaps file; its layout is unknown to me.

### 3.20 Gumbious Temple (Dezolis): 3 small maps
- **Map:** `…-Dezolis-GumbiousTemple.png`
- The main hall is **trident-shaped**: a central north altar holds the Eclipse Torch flame, with two side wings of priests. Side stairs lead to a west chamber (the head priest's dais) and an east underground passage. After Garuberk the temple is **destroyed** (the Bishop scene).

### 3.21 Weapons Plant (Dezolis, optional): about 5 sections
- **Map:** `…-Dezolis-WeaponsPlant.png`
- **Entrance:** a small building surrounded by water, entered from the south → an elevator to the **Central Lobby**. Elevators then fan out to:
  - **West Block:** a **3×3 grid of blue interlocking rooms** (each a hook- or L-shaped corridor) joined by elevators, forming a warp-maze with chests.
  - **Twin Assembly Halls (center):** mirrored conveyor-belt halls.
  - **East Catwalks:** a big rectangular catwalk loop with 4 spur rooms and a south exit. The **Burst Rocket** and the Repair Kit terminal (between boxes) are on this side [FAN; RPGC].

### 3.22 Air Castle (asteroid belt): very large; numbered-door hub design
- **Map:** `AirCastle.png`. VGMaps numbers the doors 1–21 plus A–D.
- **Exterior:** a floating island. You land at the **south tip**. Lower tier: a wide courtyard with doors 1–11. Upper tier: a raised terrace behind it with doors 12–21. Two long **bridges** cross between them (RPGC: "before the bridge on the left side, go down the stairs for the Swift Helmet; across the bridge, first door has the Genocide Claw").
- **Main Keep (door 1):** a symmetric great hall with a central red-carpet colonnade (6 pillars) and side rooms A/B/C, and loft levels accessed from doors 2–11. RPGC: "go right… you can't get lost… reach the loft."
- **Upper Keep (door 13):** a symmetric hall with two side towers. A healing-pad room sits next to an **invisible barrier** that drops once the Xe-A-Thouls die.
- **Xe-A-Thoul Room:** a checkerboard throne room (door 17). The healing pad is behind them.
- **Final Maze:** a "PS1 Air Castle"-style chain of **6 pairs of mirror-image rooms**, each a spiral or switchback corridor, linked by color-coded stairs (the true path alternates between left and right twins). RPGC: "like a maze… the Chaos Sorcerer returns… find a PS1 Air Castle map."
- **Lashiec Chamber:** a dark-red room at the very end with a round dais. The fake torch there becomes a **Spector**, and then **Lashiec** appears.

### 3.23 Garuberk Tower (Dezolis): organic tower, about 6 levels
- **Map:** `…-Dezolis-GaruberkTower.png`
- **Entry:** the tower is surrounded by the carnivorous forest (burn it with the Eclipse Torch).
- **L1:** a small C-shaped fleshy chamber; enter at the **south**.
- **L2:** a large blob of crescent-shaped lobes lined with **pale vein pillars**. A wall blocks progress until you **touch an eye**, which removes it [RPGC]. It holds the Power Shield (casts Shift).
- **L3:** a large amoeboid room with **green vine/cilia patches** and 2 exits that split the route.
- **L4:** two big circular lobes. One elevator leads to the **Moon Slasher** (take it first); the other continues [RPGC].
- **L5:** a hub. A large square-spiral fleshy room (walked inward) plus 3 small satellite chambers, cross-linked by **vacuole elevators**. You must again take the elevator behind a structure and **touch the eye** [RPGC]. A Star Dew room sits here.
- **Top:** an X-shaped spire. Arrive on the east side; **Dark Force (2nd) sits at the north tip**.

### 3.24 Vahal Fort (Motavia NE island, optional): 3 levels
- **Map:** `…-Motavia-VahalFort.png`
- **1F:** a giant **cross/diamond-shaped maze** of pink walls inside a square fort. Enter at **south-center**; stairs are in the **exact center**.
- **2F:** **concentric square rings** (onion layout). Arrive in the **center**; work outward, then down to the exit at the **SE bottom**. It has 2 chests near the south.
- **3F:** a big rectangular hall of rail/conveyor tracks with twin E and W side rooms. **"Use the computer on the left, take the path going right"** for the **Positron Bolt** chest (the far-east dead-end corridor). Then go **left** to the **Daughter** computer room (bottom center, with a wall of screens) [RPGC]. Photon Eraser and Laconian Gear/Armor are inside.

### 3.25 Rappy Cave (Motavia SE, optional): 1 cave
- **Map:** `…-Motavia-RappyCave.png`
- A tall winding S→N cave. Enter at the **south**. There are two shallow pools (W, E) and a ledge with steps midway. **King Rappy** sits on a raised dais at the **north end**. Only Rappys spawn here [RPGC].

### 3.26 Island Cave & Soldier's Temple (Motavia, lake island east of Krup)
- **Map:** `…-Motavia-IslandCave&SoldierTemple.png`
- **Cave A (big):** enter at the **bottom-center**. It is a large chamber split into loops by rock pillars. Exits: a west ledge (stairs up to a small NW cave), an NE hole (to a small round cave) and a north ledge (warp to Cave B).
- **Cave B:** a wide E–W gallery with a south loop.
- **Cave C (small):** leads to the **exit to the surface islet**.
- **Soldier's Temple:** a small shrine on the islet. The antechamber leads to the inner chamber with the **Aero-Prism** in the center.
- RPGC: "stairs at the top section"; on the 2nd floor, take the **lower-left stairs**; Seth compliments you at each.
- **Boss:** **Dark Force (3rd)** is fought **outside** after the Aero-Prism reveals Seth.

### 3.27 Rykros: Silence Temple (hub)
- **Map:** `…-Rykros-SilenceTemple.png`
- A single huge **cross-shaped ring corridor** around a central void. Enter at the **south**. There are 3 treasure alcoves (**N, W, E**). A stair just inside the south entrance leads down to the **inner sanctum**, a diamond-shaped room with an ornamental tile floor and a crystal door at the north. Le Roof's voice speaks here. Guardian Sword [RPGC].

### 3.28 Rykros: Strength Tower: 5 floors
- **Map:** `…-Rykros-StrengthTower.png`
- A crystal-walled island tower. Enter at the **south** of 1F, a cross-shaped floor with an ornamental tile ring.
- Floors 2–4 are rectangular mazes of short walls (a G-, spiral- or E-shaped wall per floor). Stairs alternate between NW, NE, center and south corners, and some pairs cross-link non-adjacent floors (1F↔3F style).
- **Top (5F):** a small floor with an 8-tile ornamental cluster and a chest row. **De-Vars** is here.
- **Loot:** Guardian Claw ×2, Guardian Rod [RPGC].

### 3.29 Rykros: Courage Tower: 5 floors
- **Map:** `…-Rykros-CourageTower.png`
- The same template as the Strength Tower, in lavender crystal. 1F has a central **N–S line of ornamental tiles** and two corner stairs. Floors 2–4 are spiral/G-shaped wall mazes with cross-links. The top floor has a 12-tile ornamental diamond. **Sa-Lews** is here.
- **Loot:** Guardian Armor, Guardian Mail, Guardian Robe [RPGC].

### 3.30 Rykros: Anger Tower: 3 floors (optional)
- **Map:** `…-Rykros-AngerTower.png`
- Needs Elsydeon to enter.
- **1F:** enter at the south. Two tile "rosettes" with chests flank a central N–S tile column; two stairs are at the south corners.
- **2F:** an L/Z-shaped open floor with a chest.
- **3F:** a tile ring in the center. Chaz enters **alone** and meets the **Alys illusion** and then **Re-Faze**.
- **Loot:** a Guardian Mail [RPGC].

### 3.31 The Edge (Motavia, final dungeon): an abstract tile path through the void
- **Map:** `…-Motavia-Edge(Animated).gif`
- A grey void with **single-tile-wide walkways**. Enter at a **south-center** spot. The path is broken into about 8 segments joined by **warp pads** (diamond tiles) that teleport you to distant segments. Several segments have **dead-end spurs**.
- The route zig-zags east, then far south, then back west, and finally up a **very long N–S column** on the far west. The **Profound Darkness** (a black spiked mass) waits at the **NW top**.
- Enemies here are all vulnerable to instant death, so Explode, Crash and Negatis work well [RPGC].

---

## 4. Bosses

HP, XP and meseta are from [RPGC bosses.shtml] and are approximate. Other notes are cited inline.

| Boss | Location | HP | XP / Mes | Notable attacks | Weakness / notes |
|---|---|---|---|---|---|
| Igglanova (×2) | Academy Basement; Zema (in front of Birth Valley) | 300 | 171 / 54 | Fission (summons Xanafalgue) | RPGC opener: Alys Vortex, Hahn Wat, Chaz Earth (paralysis). 2nd fight: RPGC says use plain attacks only. |
| Sand Worm (Guild) | Mile ranch | 1450 | 25160 / 1200 | Earthquake (field version) | Optional; hard for its level |
| Juza | Zio's Fort | 1550 | 5150 / 800 | Foi, Wat, Zan, Force Flash | Weak to **light**, resists dark [FAN Juza] |
| Zio (1st) | Zio's Fort top | invulnerable | — | Magic Barrier, Nightmare, Black Wave | Scripted loss; Black Wave hits Alys |
| Gy-Laguiah (×2) | Ladea Tower top; Climate Control entrance | 2575 | 10000 / 1224 | Fire Breath, heavy physical hits | RPGC tactics: War Cry, Deban/Saner, Barrier, GiWat (ice). That the Wat choice reflects a fire-weakness-to-ice is my inference (unverified). |
| Zio (2nd) | Nurvus core | 2900 | 25995 / 1 | Magic Barrier (Rune dispels it via the Psycho Wand), Nightmare, Black Wave, Corrosion, Hewn | Rika/Deban/Saner plus Demi's Barrier |
| Chaos Sorcerer | Shuttle engine room (also a regular enemy in the Air Castle and Garuberk) | 450 | 18380 / 1200 | Flaeli, Shadow Bind, Hewn, Corrosion | Weak; plain attacks are enough |
| Fract Ooze | Earth Hole (optional) | 2000 | 42235 / 855 | Cell Split, Fission | Barrier and Deban blunt Cell Split |
| Dark Force (1st) | Kuran core | 4500 | 32600 / 1 | Phonon Maser, Flare Shot, Burst Rocket | Opener: Barrier, Deban, Blessing. Wren with Napalm Shot (fire) does heavy damage; Raja's St. Fire (holy). Dark Force forms are evil-type, so Grand Cross, Efess and Holy damage are strong [OOC: Grand Cross is "the ultimate combo against evil opponents"]. |
| D-Elm-Lars | Climate Control end | 800 | 3915 / 500 | GiWat, GiFoi, GiZan | Weak fight. RPGC: most Dezolis monsters (except Helex) are weak to **fire** (applies to the field; for this boss, unverified). |
| Carnivorous Tree | Forest near Garuberk | 250 each | — | — | Unwinnable (regrows); burn with the Eclipse Torch |
| Xe-A-Thoul ×3 | Air Castle | 1500 each | 7374 / 1000 | **Thunder Blast** (only while all 3 live), GiZan, GiWat | Kill them one at a time; Deban plus Barrier; Rayblade |
| Spector (decoy torch) | Air Castle | ~180 (regular Spector) | — | Corrosion, Death Spell, Evil Eye | Undead; Holyword/Efess (unverified) |
| Lashiec | Air Castle final room | 6400 | 29999 / 1 | Thunder Halberd, Possession, Reinforce (near death), Another Gate | Heavy healing (GiSar, Star Dew, Medice). RPGC team: Burst Rocket, Rayblade/NaThu, NaFoi, Hewn (Fire Storm and Shooting Star combos). |
| Dark Force (2nd) | Garuberk Tower top | 7500 | 46380 / 1 | **Lightning Shower** (can kill Wren in 1–2 hits), Shadow Breath, Evil Eye | Barrier first; NaFoi ×2 (Rune and Kyra); holy/light |
| King Rappy | Rappy Cave (optional) | 3000 | 39852 / 555 | Earthquake | Best skills |
| Dominator ×3 | Vahal Fort (Daughter) | 1000 each | 4800 / 500 | Double Slash, Phonon Maser | Machines: **Circuit Break** (Hyper Jammer + Tandle) wipes them out |
| Dark Force (3rd) (Seth) | Outside the Soldier's Temple | 8200 | 49999 / 1 | Corrosion, Shadow Bind, Mind Blast, "power stab" | Party of 4. Positron Bolt, Rayblade/NaThu, Legeon/Efess. |
| De-Vars | Strength Tower top | 5500 (RPGC table; the RPGC walkthrough says 5000, conflict) | 35000 / 1 | **Disrupt Arm** (party-wide) | Drops the Parma, Mota and Dezo rings |
| Sa-Lews | Courage Tower top | 5500 (the RPGC walkthrough says 5000, conflict) | 35000 / 1 | Flaeli, **Legeon**, Hewn | Wren's Barrier is essential (magic). Drops the Rykros and Algo rings. |
| Alys (illusion) | Anger Tower top | 500 | 1 / 1 | — | Chaz solo; Crosscut |
| Re-Faze | Anger Tower top | not listed by RPGC; [FAN] says 1,000,000 (unverified) | — | Megid | Optional/unwinnable per RPGC ("even at level 90"). Answer "No" and he teaches Megid. |
| Profound Darkness, form 1 | The Edge | 5000 | — | Shadow Breath, Fire Breath, Ray Breath (single-target) | Mostly plain attacks |
| Profound Darkness, form 2 | The Edge | 5000 | — | Distortion, Lightning Shower, Another Gate (all-party) | Hurts the androids badly |
| Profound Darkness, form 3 | The Edge | 13000 | — | **Megid**, Evil Eye, Neutralize | Open with **Destruction** (Deban+Megid+Legeon+Positron Bolt, about 1000 damage). St. Fire (Raja), NaFoi and Tandle (Kyra) are also good. |

Sources: [RPGC bosses.shtml, walkthrough parts 1–13], [FAN Juza, Zio, Lashiec, Anger Tower, Daughter, Seth pages], [OOC combos.html].

**Element system note [FAN Techniques]:** the elements are fire, ice, light, physical (the Zan family), gravity, break (Brose), bio (Vol), psi, holy (Efess and St. Fire), energy (Astral, Legeon, Flare, Positron Bolt), electric (Tandle), mech (Spark, Hyper Jammer), exorcism (Holyword) and defeat (instant death). Elemental sensitivity can raise damage, lower it, or cut it to 1. Exact per-boss sensitivity tables were not available in any source I could reach.

---

## 5. Regular enemies by area

**Zone assignments** come from [OOC] unless noted; [OOC] is itself incomplete. Stats are from [RPGC monsters.shtml] (HP / XP / meseta). Rows marked (unverified) are my recall of the game or my inference from enemy type.

| Area | Enemies |
|---|---|
| Piata Academy Basement | Xanafalgue (16 HP), Zoran Bult (25); boss Igglanova [OOC][FAN] |
| Motavia plains (early, around Piata/Mile/Zema/Molcum) | Locusta (68), Crawler (30, Thread), Mini Worm (25), Monster Fly (20) (unverified zone), Sand Newt (41), Infant Worm (50), Scorpirus (145), Fanbite (260, Spiral Blade), Caterpillar (195, Poison), Speard (100), Tech User (80; Wat/Foi/Res), "Depcen" (155, OOC spelling; not in the RPGC list) |
| Birth Valley | Xanafalgue, Zoran Bult, Flatter Plant (32, Acid Breath) |
| Bio-Plant | Arm Drone (68), Gicefalgue (40), Guilgenova (325, Fission), Ismounos (90), Neo Whistle (50), Sensor Bit (40) |
| Valley Maze | Blob (19), Carrion Crawler (35), Sand Newt |
| Tonoe Warehouse Basement | Abe Frog (70), Toadstool (64) |
| Wreckage | Tracer (100), Warren286 (96, Flare Shot), Whistle (50) |
| Passageway (Aiedo–Kadary) | Meta Slug (250), Zol Slug (50, Fusion), Speard |
| Zio's Fort | Ripper (115, Fire Breath), Shadow Saber (110, Deban), Speard, Tech User |
| Ladea Tower | Fly Screamer (130, Acid Breath/Voice), Haunt (3 HP; Corrosion, Evil Eye), Ripper, Shadow Saber, Centaur (190) (GameFAQs Goldenguy search snippet) |
| Plate System | Gunner Bit (70, Rail Gun), Loader (175, Laser Cannon), Seeker (125), Slave (180), Worker Pod (100) |
| Nurvus | Balduel (250), Blauzen (230, Stasis Ball), Float Mine (150, Explode), Greneris (360; Seals/Force Flash/Vol/Rimit), Tarantella (98), Tech Master (120; Foi/Wat/Zan/GiRes/Sar), Tower (335, Warning), Zio's Guard (150) |
| Kuran | Float Mine [OOC]. Others likely from the robotic set: Protect Bit, Satellite Minion, Star Drone, Sweeper, Command Ball, Debugger, Siren386, Browren486 (unverified). |
| Motavia vehicle battles (Land Rover) | Desert Leach (1000, Sand Storm), Grasshound (350) (RPGC marks both as vehicle battles; zone unverified) |
| Motavia sea (Hydrofoil) | Elmelew (300; Wat, Flood Breath), Hewgilla (250), Leviathan (1500, Maelstrom) (vehicle battles; zone unverified) |
| Dezolis plains | Bitter Fly (440, Needle), Dezo Owl (130), Helex (90, Flame Bolt; the only Dezolis monster **not** weak to fire [RPGC]), "Mistralgec" (131, OOC only), Rajago (250), Red Mole (125), Skytiara (160), Snow Mole (80), Snow Slug (220, Cell Split), Snow Worm (100) |
| Dezolis vehicle battles (Ice Digger) | Owl Talon (Wind Storm), Lw-Addmer (Ray Breath), Cula-Bellar (Lightning Breath), Forced Fly (Flame Bolt) (vehicle battles; zone assignment unverified) |
| Reshel (ruined) | Zombies (125, Bad Smell; they keep respawning) [RPGC][FAN] |
| Tyler Hangar / Myst Valley / Climate Control | not given by any readable source. Likely Dezolis field types plus robots such as Sweeper, Debugger, Dragerduel and Jurafaduel in Climate Control (unverified). |
| Weapons Plant | Robots (unverified): Jurafaduel (Flame Launcher, Micro Missile), Dragerduel, Life Deleter (436 HP; Stasis Ball, Micro Missile), Vopel Sphere, C-Ray Tube, Servant |
| Air Castle | Bladeright (230, Fire Breath), Frost Saber (200; GiWat/Deban/Airslash), Stone Heads (220), Spector (180), Dimension Worm (4 HP, Gra) [FAN story]; Chaos Sorcerer (450) [RPGC] |
| Garuberk Tower | Frost Saber (4-packs are deadly [LJ]), Stone Heads, Chaos Sorcerer, Hakenleft (250, Acid Breath), King Saber (260, Ray Spear), Radhin (300; Shift/Deban/Saner/GiSar/Seals/Force Flash) [FAN][LJ]; paralyzing Ghouls (125, Bad Smell) [LJ] |
| Vahal Fort | Robots. Twin Arms, Goldine, Silvalt and Browren486 are plausible (unverified). Circuit Break is recommended [RPGC]. |
| Rappy Cave | Rappy (100, Round Eyes), Blue Rappy (130, Lovel Eyes) (Blue Rappy unverified; RPGC says "only Rappys") |
| Island Cave | Unlisted. RPGC: "monsters are not too tough." |
| Rykros towers | Unlisted. RPGC: "quite strong". [FAN]: the Anger Tower "holds the same enemies". Candidates: Imagion Mage, Illusionist, Soldier Fiend, Dark Rider, Blind Heads, Crimson Heads, Outer Beast, Phantom, Death Bearer, Dark Marauder, Dark Witch (unverified). |
| The Edge | Chaos Bringer (650; Rimit, Shift; drops the Defeat Axe) [RPGC]. The rest are unlisted, but all are vulnerable to instant death [RPGC]. |

**Full RPGC name roster (for sprite and palette-swap planning):** Abe Frog, Arm Drone, Arthropod, Balduel, Bitter Fly, Bladeright, Blauzen, Blind Heads, Blob, Blood Saber, Blue Rappy, Browren486, C-Ray Tube, Carrion Crawler, Caterpillar, Centaur, Chaos Bringer, Chaos Sorcerer, Command Ball, Crawler, Crimson Heads, Cula-Bellar, Dark Marauder, Dark Rider, Dark Witch, Death Bearer, Debugger, Desert Leach, Dezo Owl, Dimension Worm, Dragerduel, Elmelew, Fanbite, Flame Newt, Flatter Plant, Float Mine, Fly Screamer, Forced Fly, Frost Saber, Gerotlux, Ghoul, Gi-le-farg, Gicefalgue, Goldine, Grasshound, Greneris, Guilgenova, Gunner Bit, Hakenleft, Haunt, Helex, Hewgilla, Hungry Mole, Illusionist, Imagion Mage, Infantworm, Ismounos, Jr. Ooze, Jurafaduel, King Saber, Le-faw-gan, Leviathan, Life Deleter, Loader, Locusta, Lw-Addmer, Meta Slug, Mini Worm, Monster Fly, Neo Whistle, Outer Beast, Owl Talon, Phantom, Piercer, Prophallus (PSI Dark Force), Protect Bit, Radhin, Rajago, Rappy, Red Mole, Ripper, Sand Newt, Sand Worm, Satellite Minion, Scorpirus, Seeker, Sensor Bit, Servant, Shadow Saber, Shrieker, Silvalt, Siren386, Skytiara, Slave, Snow Mole, Snow Slug, Snow Worm, Soldier Fiend, Speard, Spector, Star Drone, Stone Heads, Sweeper, Tarantella, Tech Master, Tech Plant, Tech User, Toadstool, Tower, Tracer, Twin Arms, Vopel Sphere, Warren286, Whistle, Wiredine, Worker Pod, Xanafalgue, Zio's Guard, Zol Slug, Zombie, Zoran Bult.

Notes:
- Gi-le-farg (1000 HP; GiZan/Tandle/Flaeli/GiWat/GiFoi) and Le-faw-gan (885) are strong caster types.
- Prophallus (3000 HP, 65,496 XP) is a PSI Dark Force cameo. Where it appears is unverified; I believe it is a rare Edge/Rykros encounter.

---

## 6. Techniques and skills per character

Techniques cost TP. Skills have limited uses that refill at an inn, and the number of uses grows with level. Levels are from [RPGC chrono.shtml] cross-checked against [FAN Techniques] and [FAN Skills]; they agree except where marked. "Start" means the character already knows it on joining.

### 6.1 Technique reference (costs and effects from [FAN Techniques])

| Tech | TP | Target | Power / effect | Element |
|---|---|---|---|---|
| Foi / Gifoi / Nafoi | 3 / 6 / 9 | 1 enemy | 24 / 72 / 136 + mental | fire |
| Wat / Giwat / Nawat | 4 / 7 / 10 | 1 | 32 / 80 / 144 + mental | ice |
| Tsu / Githu / Nathu | 6 / 11 / 15 | 1 | 48 / 96 / 160 + mental | light (RPGC calls it "bolt") |
| Zan / Gizan / Nazan | 8 / 12 / 16 | all | 16 / 64 / 128 + mental | "physical" per FAN (RPGC: wind) |
| Gra / Gigra / Nagra | 10 / 15 / 19 | all | 32 / 80 / 144 + mental | gravity |
| Megid | 30 | all | 255 + mental | light per FAN (RPGC: "extreme fire", conflict) |
| Brose | 16 | all | instant defeat (break) | break |
| Vol / Savol | 8 / 16 | 1 / all | instant defeat | bio |
| Gelun | 5 | all | −attack (RPGC: −dexterity) | bio |
| Doran | 4 | all | −agility | bio |
| Seals | 8 | all | silence | psi |
| Rimit | 10 | all | paralysis | psi |
| Res / Gires / Nares | 3 / 6 / 9 | 1 ally | 16 / 80 / 240 + mental HP | — |
| Sar / Gisar / Nasar | 12 / 24 / 36 | all allies | mental / 64 / 160 + mental | — |
| Shift | 7 | 1 ally | +attack | — |
| Saner | 6 | all allies | +agility | — |
| Deban | 5 | all allies | +defense | — |
| Anti | 2 | 1 | cure poison | — |
| Rimpa | 5 (FAN; RPGC says 2, conflict) | 1 | cure paralysis | — |
| Rever | 12 | 1 | revive | — |
| Regen | 36 | 1 | full revive | — |
| Arows | 9 | all | cure sleep | — |
| Ryuka | 8 | field | teleport to a visited town | — |
| Hinas | 4 | field | escape the dungeon | — |

Healing techniques do not work on the androids (Wren, Demi).

### 6.2 Per character

**Chaz Ashley** (Hunter, 16; sword)
- **Techniques:** Res (start), Tsu 4, Hinas 8, Ryuka 9, Anti 11, Zan 12, Rimpa 14, Gires 16, Githu 17, Brose 21, Gizan 23, Rever 25, Nathu 31, Nares 36, Nazan 37, **Megid** (Anger Tower, from Re-Faze).
- **Skills:**

| Skill | Learned | Effect | Uses |
|---|---|---|---|
| Earth | start | chance to paralyze 1 | 4–46 |
| Crosscut | 6 | 80 + atk to 1 | 1–39 |
| Air Slash | 13 | weapon damage to all | 1–28 |
| Rayblade | 27 | 176 + mental, light, 1 target | 1–21 |
| Explode | 35 | chance to defeat 1 | 1–16 |

Earth, Crosscut, Air Slash and Rayblade need a sword or dagger.

**Alys Brangwin** (Hunter, "Eighth-Stroke Warrior"; slashers, which hit multiple targets)
- **Techniques:** Foi, Shift and Saner (start); Zan 8; Gifoi 14; Gizan 18; Nafoi 22 [RPGC] or 24 [FAN] (conflict); Nazan 27.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Vortex | start | 48 + atk to 1 |
| Moon Shade | 10 | chance to paralyze all |
| Death | 13 | chance to defeat 1 |

All of Alys's skills need a slasher.

**Hahn Mahlay** (Scholar, 24; dagger; starts at level 1)
- **Techniques:** Res and Gelun (start); Wat 3, Anti 6, Doran 7, Zan 9, Vol 10, Gires 11, Rimpa 12, Rimit 13, Giwat 16, Gizan 21, Nares 23, Nawat 28, Savol 33, Nazan 37.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Vision | start | +dexterity to all allies. Bugged in the US version: a flat +8, versus 72 in JP. |
| Astral | 29 | 168 + mental, energy damage |
| Eliminate | 30 | chance to defeat 1; needs a dagger |

**Rune Walsh** (Wizard; rod; joins at level 17)
- **Techniques:** Foi, Wat, Gra, Arows, Hinas and Ryuka (start); Giwat 18, Gifoi 19, Seals 20, Rever 21, Gigra 23, Nafoi 25, Nawat 26, Nagra 30.
- **Skills:**

| Skill | Learned | Effect | Element |
|---|---|---|---|
| Flaeli | start | 48 + mental to 1 | fire |
| Hewn | start | 64 + mental to all | physical/wind |
| Diem | 24 | chance to defeat 1 | bio |
| Tandle | 27 | 144 + mental to all | electric |
| Efess | 29 | 160 + mental to all | holy |
| Negatis | 32 | chance to defeat all | — |
| Legeon | 35 | 224 + mental to all | energy |

**Gryz** (Motavian, 19; axe; joins at level 6)
- **Techniques:** Brose (start). He has very little TP.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Crash | start | chance to defeat 1; needs an axe |
| War Cry | 14 | +attack to self |
| Sweeping | 25 | weapon damage to all |

**Rika** (Numan, 1 year old; claws)
- **Techniques:** Res (start); Saner 8, Gires 13, Deban 14, Shift 19, Sar 20, Gisar 28, Nares 33, Nasar 40.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Illusion | start | lowers the agility of all enemies |
| Double Slash | 4 | 64 + atk to 1 |
| Eliminate | 12 | chance to defeat 1 |
| Disrupt | 17 | weapon damage to all |

Double Slash, Eliminate and Disrupt need claws.

**Demi** (Android; guns)
- **Techniques:** none (androids have no TP).
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Recover | start | heal self 240 + str |
| Stasis Beam | start | chance to paralyze 1 |
| Spark | start | chance to defeat 1 (mech) |
| Barrier | start | +magic defense to the party |
| Medical Power | start | revive and heal all non-androids |
| **Phonon Maser** ("Phonomezer") | found in the **Plate System** | 176 + str to all |

**Wren** (Android; guns)
- **Techniques:** none.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Recover | start | heal self |
| Flare | start | 128 + str, energy, 1 target |
| Spark | start | chance to defeat 1 |
| Barrier | start | +magic defense to the party |
| **Hyper Jammer** | found on **Kuran** | chance to paralyze all (mech) |
| **Burst Rocket** | found in the **Weapons Plant** | 144 + str to all |
| **Positron Bolt** | found in **Vahal Fort** | 240 + str to all, energy |

**Raja** (Dezolian priest, 85; rod or 2 shields)
- **Techniques:** Res, Anti, Rimpa, Sar, Arows, Rimit, Gires, Seals and Rever (start); Nares 27, Gisar 28, Regen 31, Nasar 34.
- **Skills (all known at the start):**

| Skill | Effect | Element |
|---|---|---|
| Blessing | +defense to all | — |
| Holyword | chance to defeat 1 | exorcism |
| Ataraxia | restore TP to the party; the only TP restore in the game | — |
| Miracle | 80 + mental heal to all | — |
| St. Fire | 144 + mental to all | holy |

Raja joins with a full set of silver gear.

**Kyra Tierney** (Esper, 18; slasher; joins at level 27)
- **Techniques:** Res, Foi, Anti, Rimpa, Gires, Gifoi and Gra (start); Gigra 30, Nafoi 33, Nares 36, Nagra 40.
- **Skills:**

| Skill | Learned | Effect |
|---|---|---|
| Medice | start | 128 + mental heal to 1 |
| Flaeli | start | fire, 1 target |
| Telele | start | lowers the attack of all enemies |
| Hewn | start | 112 + mental to all |
| Warla | 29 | +defense to all |
| Bindwa | 35 | chance to paralyze all |
| Tandle | 39 | 176 + mental to all |

**Seth** (Scholar/archaeologist, 39; dagger; temporary member who is secretly Dark Force)
- **Techniques:** none listed.
- **Skills (all known at the start; uses fixed at 26 / 18 / 13 / 9):**

| Skill | Effect |
|---|---|
| Shadow | −agility to all |
| Corrosion | 144 + mental to all |
| Mind Blast | chance to paralyze all |
| Death Spell | chance to defeat 1 |

Sources: [RPGC chrono.shtml, techniques.shtml, skills.shtml, characters.shtml]; [FAN Techniques, Skills, character pages].

---

## 7. Combination attacks

Mechanic: a combination fires when the component techniques or skills are used **back-to-back in the same round**, which in practice means set up in a **Macro**. [RPGC]: "-" means order does not matter; "+" means order matters. The US manual promises 15 combinations, but only 14 are known [OOC]. "*" means any tier of that family works (for example, Foi, Gifoi or Nafoi).

| Combo | Components | Who can supply the components | Effect |
|---|---|---|---|
| **Tri-Blaster** | Foi* – Tsu* – Wat* | Foi: Alys, Rune, Kyra. Tsu: Chaz only. Wat: Hahn, Rune. | All enemies, about 120–350 [OOC]. The classic early setup is Alys Foi, Chaz Tsu, Hahn Wat. |
| **Fire Storm** | Zan* – Foi* / Zan* – Flaeli / Hewn – Foi* / Hewn – Flaeli | Zan: Chaz, Alys, Hahn. Hewn: Rune, Kyra. Foi: Alys, Rune, Kyra. Flaeli: Rune, Kyra. | Strong fire; good on Dezolis and against ice-based enemies |
| **Blizzard** | Wat* – Zan* / Wat* – Hewn | Wat: Hahn, Rune. Zan: Chaz, Alys, Hahn. Hewn: Rune, Kyra. | Strong ice; good on Motavia and against fire-based enemies (early: Rune Hewn + Hahn Wat) |
| **Conduct Thunder** | Wat* **+** Tandle | Wat: Hahn, Rune. Tandle: Rune (27), Kyra (39). | Huge thunder damage, about 350–600; very good on machines |
| **Shooting Star** | Burst Rocket **+** Foi* / Burst Rocket **+** Flaeli | Burst Rocket: Wren. Foi or Flaeli: Alys, Rune, Kyra. | Strong fire, about 150–650 |
| **Circuit Break** | Hyper Jammer – Tandle | Wren + Rune or Kyra | Instantly destroys **all androids and robots** |
| **Silent Wave** | Phonon Maser – Air Slash | Demi + Chaz | Strong wave damage, about 330–500 |
| **Grand Cross** | Efess – Crosscut | Rune + Chaz | A huge cross, 700+ against evil types, but only **1** against non-evil or machine targets [OOC]. The best combo against the Dark Force forms. |
| **Paladin Blow** | Astral – Rayblade | Hahn + Chaz | About 700 to one enemy (any type) |
| **Purify Light** | Holyword – Efess | Raja + Rune | Instantly kills "evil" enemies; ineffective on bosses |
| **Holocaust** | Savol – Diem | Hahn + Rune | Instantly kills bio-type enemies |
| **Black Hole** | Negatis – Gra* | Rune alone supplies both (Negatis 32, Gra), so Rune + Kyra (Gra) is the practical pairing. Whether Rune can pair with himself is unverified (a combo needs two actors in the round). | Kills all enemies on screen; ineffective on bosses |
| **Lethal Image** | Death **+** Illusion | Alys + Rika | Instant kill; unreliable |
| **Destruction** | Deban **+** Megid **+** Legeon **+** Positron Bolt (4 actors, in order) | Rika Deban → Chaz Megid → Rune Legeon → Wren Positron Bolt | **999 to all** [OOC]. The strongest combo, used on the final Profound Darkness form. |

Sources: [RPGC combo.shtml]; [OOC combos.html] (damage ranges). The component-to-character mapping is derived from §6.

---

## 8. Key items and equipment progression

### 8.1 Key / story items and vehicles

| Item | Where / how | Purpose |
|---|---|---|
| **Alshline** | Tonoe Warehouse Basement, bottom level | Cures Zema's petrification (stone to flesh) |
| **Control Key** | Machine Center (south of Krup) | Gives access to the Land Rover |
| **Land Rover** (JP: Land Master) | Machine Center | Overworld vehicle that crosses **quicksand** and fights its own vehicle battles |
| **Psycho Wand** | Ladea Tower top (after Gy-Laguiah) | Breaks Zio's magic barrier (on the stairs in Zio's Fort and in the Nurvus battle). Rune can also equip it; RPGC's late setups give it to Gryz or Rune as a weapon. |
| Frade Mantle | Ladea Tower 5F | Robe for Rune (a PSI homage) |
| **Canceller** | Zelan | "A device that silences movement." Its field effect is unclear (unverified). |
| **Landale** (spaceship) | Tyler Hangar, beneath the founder's grave | Interplanetary travel: Kuran, the Air Castle, Rykros |
| **Ice Digger** | Given by Wren after Kuran | Dezolis vehicle; **breaks ice walls** |
| **Silver Tusk** | Myst Valley, from the Old Man (musk cat) | Claw-class weapon for Rika |
| **Eclipse Torch** | Stolen from Gumbious Temple, recovered from Lashiec (Air Castle) | Burns the carnivorous forest. Usable in battle, where it casts St. Fire [RPGC items]. It is returned after Garuberk. |
| **Hydrofoil** | Given by Demi on Motavia after Garuberk | Crosses the ocean (Uzo, Tornico, Vahal, the Soldier's Temple island) |
| **Aero-Prism** | Soldier's Temple | Beams toward Rykros; exposes Seth as Dark Force; reveals the planet |
| Parma, Mota and Dezo Rings | De-Vars drop (Strength Tower) | For Wren, Rika and Rune [RPGC] |
| Rykros Ring, **Algo Ring** | Sa-Lews drop (Courage Tower) | Algo Ring: Chaz. Rykros Ring: nobody can equip it [RPGC]. |
| **Elsydeon** | Cave below Lutz's room, Esper Mansion | Chaz's sacred sword against the Profound Darkness; lets you into the Anger Tower; shatters in the ending |
| Megid (technique) | Anger Tower, from Re-Faze | Chaz's ultimate technique; a Destruction component |
| Repair Kit (unlimited) | Weapons Plant terminal | Revives an android |
| Shortcake, Perolymate, "Alis' Sword" | Aiedo, Termi, Termi | Guild job items |

### 8.2 Equipment tiers (materials progression)
The materials, in order: **Leather → Carbon → Titanium → Graphite → Ceramic → Laser → Plasma → Silver / Psychic → Zirconian → Reflect / Compound / Elastic → Laconian → Guardian** (plus the uniques Moon Slasher, Silver Tusk, Genocide Claw, Photon Eraser, Sonic Buster, Defeat Axe, Mahlay set and Elsydeon).

Where each tier is bought or found [RPGC walkthrough equipment blocks; FAN town pages]:

| Tier | Shops (towns) | Dungeons / chests |
|---|---|---|
| Leather | Mile | — |
| Titanium | Tonoe | — |
| Graphite / Ceramic | Zema (after the cure) and Aiedo | Bio-Plant, Wreckage |
| Laser | — | Kadary, Zio's Fort |
| Psychic | Termi | — |
| Plasma | — | Nurvus, Zelan |
| Silver | Ryuon, Tyler | — |
| Zirconian | — | Hangar, Kuran |
| Flame / Thunder weapons | Zosa | — |
| Reflect | Meese | Esper Mansion |
| Laconian | Jut (weapons); Reshel after rebuilding (armor) | — |
| Guardian | — | Rykros towers |

Weapon classes by character: sword (Chaz), slasher (Alys, Kyra), dagger (Hahn, Seth, Chaz), rod (Rune, Raja), axe (Gryz), claw (Rika), gun (Demi, Wren).

Wren's weapon line:
- **Guns:** Napalm Shot (Kuran) → Plasma Launcher (Weapons Plant) → Photon Eraser (Vahal).
- **Armor:** Zirconian → Elastic → Laconian → Guardian.

Sample prices [FAN Items]:
- **Healing:** Monomate 20 (+48 HP), Dimate 160 (+96), Trimate 400 (+320).
- **Dews:** Moon Dew 5000 (revive), Star Dew 10000 (+128 HP to all), Sol Dew 20000 (full revive).
- **Pipes:** Telepipe 130, Escapipe 70.

---

## 9. Design-relevant observations (my synthesis, not sourced facts)
- The **party roster changes a lot** (Alys dies around 25% in; Hahn, Gryz and Demi leave before space; Raja and Kyra swap on Dezolis; Seth is a traitor). A Dynasty-Warriors-style roster could lock or unlock officers at these same beats.
- **Dungeon archetypes**, useful for procedural or rebuilt stages:
  - caves: serpentine with 1–3 dead-end treasure spurs;
  - tech complexes: color-paired elevator warp-mazes (Bio-Plant, Nurvus, Weapons Plant, Kuran);
  - towers: 5–6 shrinking floors with alternating corner stairs (Ladea, Rykros);
  - hub castles: numbered doors on a courtyard (Air Castle, Zio's Fort);
  - organic: eye-switch walls and vacuole elevators (Garuberk);
  - void path: warp-pad-linked tile walkways (Edge).
- **Combination attacks** map naturally onto multi-officer "musou" team specials. The component technique/skill identity is what matters, and the order constraint applies only to Conduct Thunder, Shooting Star, Lethal Image and Destruction.
