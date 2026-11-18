# Juju

Talk like a true troll, mon.

Juju is an addon for **World of Warcraft: Forever**, made for Troll characters on RP and RP-PvP realms. You type ordinary English into the chat box; what everyone else sees is how a Darkspear troll would say it.

| You type | Everyone sees |
| --- | --- |
| Hey man, the murlocs are coming through the water! | Hey mon, da murlocs be comin' troo da wata! |
| I think we need a healer and more magic. | I tink we need a witch doctor an' more juju. |
| What's going on? Where is the shaman? | Wha' be goin' on? Where be da spirit-walka? |
| They said their brothers would help them. | Dey said dey bruddas would help dem. |
| You're late, and the gods are angry. | Ya be late, an' da Loa be vexed. |
| `/y` For the Horde! | For da Horde, mon! |

Juju is the sister addon of [Krump](https://github.com/Azrolicious/Krump), which does the same for Orcs. The two can be installed together (see [Juju and Krump together](#juju-and-krump-together)).

## Install

1. Download this repository as a ZIP and unpack it.
2. Make sure the folder is called exactly `Juju` and has `Juju.toc` directly inside it. (GitHub names the unpacked folder `Juju-main` or similar. Rename it.)
3. Move the folder to `World of Warcraft/_forever_/Interface/AddOns/`.
4. Start the game, or type `/reload` if it is already running.

Juju switches itself on for Troll characters and stays off for everyone else. To use it on another race, type `/juju on` on that character.

## How a troll talks

Juju's troll is built from the way trolls talk in the game itself, from Sen'jin Village to Zul'Gurub:

- **th** turns into **d** in the little pointing words (the, this, that, them, they, there: da, dis, dat, dem, dey, dere) and into **t** everywhere else (think, three, thing: tink, tree, ting). At the end of a word it is cut short: both, north, mouth become bot', nort', mout'. Between vowels it doubles: brother, weather, bother become brudda, wedda, bodda.
- **Be** does for is, are and am, and for the 's of it's, that's and what's: "it's here" is "it be here". When the 's means has, it simply goes: "he's got" is "he got".
- **You** is ya, **your** is ya too, **my** is me, **to** is ta, **man** is mon.
- **-ing** loses its g (fightin', goin') and **-er** becomes **-a** (neva, betta, hunta).

## Using it

Just talk. While you type, a small line above the chat box shows the troll version that will be sent.

At the left of that line is a small tag. It says **Troll** if the channel you are typing in will be translated and **Plain** if it will not, and it is there as soon as the chat line opens, before you type anything. Click the tag to switch troll speech on or off for that channel only.

To try things out without saying them, type `/juju`. That opens the Juju box: type English on the top line and the troll version appears underneath as you type. Nothing typed there is said out loud. Enter lets go of the keyboard, Escape closes the box, and you can drag it wherever you like.

When a line looks right, press **Put in chat**. The chat line opens with your words already in it, and the preview above it shows the troll. Press Enter to send it, or change the channel first as you normally would. The game does not let addons say things out loud by themselves, so that last Enter is always yours.

| To do this | Do this |
| --- | --- |
| Say one line plainly | Start it with `! ` (exclamation mark, then a space). The mark is removed. |
| Speak out of character | Wrap it in `((double brackets))`, or start the line with `OOC:` |
| Describe an action inside speech | Put it between `*asterisks*`. It is left alone. |
| Switch troll speech off or on | `/juju off`, `/juju on`, or set a key under Key Bindings > AddOns |
| Go back to "on for Trolls only" | `/juju auto` |
| Try things out without saying them | `/juju` opens the Juju box, or set a key for it |
| Talk troll in General, Trade and other channels | Switch them on in the settings, or set a key under Key Bindings > AddOns > Juju to flip them all at once |
| Switch troll speech for the channel you are typing in | Click the Troll or Plain tag above the chat line |
| Teach Juju your own words | "Ya Own Juju", the bottom half of the Juju box |
| List the chat commands | `/juju help` |
| Open the settings | `/juju config`, or right-click Juju in the minimap addon menu |

## Your own words

The bottom half of the Juju box, "Ya Own Juju", teaches Juju your own words. Type an English word or phrase, what it should become, and press **Save word**:

| English | Becomes | So "give me the gold" says |
| --- | --- | --- |
| gold | shinies | gimme da shinies |
| for the horde | For da Horde, ya hear | (any line with "for the horde" in it) |
| Zanjin | *(left empty)* | Zanjin stays exactly as typed |

Leave the second line empty to keep a word exactly as typed. Use it for names, RP terms, or a word the typo fixer keeps getting wrong. Your words beat everything else Juju knows. They are saved with your settings, so updating Juju keeps them, and they work on every character.

The quickest way in is to click a word. Every translated word in the troll text at the top of the Juju box can be clicked: it is loaded into Ya Own Juju exactly as you typed it, ready for you to type what it should say. Press Enter with the second line empty to keep the word as typed, which is how to fix a typo guess that went wrong.

Your words are listed underneath, in a scrolling list. Click one to change it, or its red X to remove it.

Pressing Enter on the English line moves across, filling in what the word becomes now if it is already one of yours. To remove a word, type it on the English line and press **Remove word**.

The same from chat: `/juju word gold = shinies`, `/juju keep Zanjin`, `/juju forget gold`, and `/juju words` to list them.

## Troll words

With **Troll words** on (it is, to begin with), Juju swaps in words a troll would use as well as the accent:

| English | Troll |
| --- | --- |
| god, gods | Loa, da Loa |
| magic | juju |
| luck | mojo |
| curse, cursed | hex, hexed |
| guild, clan | tribe |
| healer, doctor | witch doctor |
| angry, annoyed | vexed |
| potion | brew |
| beer, ale | grog |
| idiot, moron | fool |
| coward | scaredy-raptor |
| awesome, amazing | mighty fine |

Switch it off and only the accent is left. The list is in `Lexicon.lua` under `L.vocab`.

## Numbered channels

General, Trade, LookingForGroup and the other numbered channels (custom RP channels, local defense) each have their own switch, all off to begin with. Switch on the ones you want under Options > AddOns > Juju, or from chat: `/juju general on`, `/juju trade on`, `/juju lfg on`, `/juju other on`.

To flip them all at once, set a key for **Switch troll speech in General, Trade and other channels** under Key Bindings > AddOns > Juju, or type `/juju channels`. Switching them back on brings back the ones you had on before.

## Classes and roles

Party talk gets troll names for every class and role, while **Troll words** is on:

| You type | Everyone sees |
| --- | --- |
| LFM tank and healer for Ragefire Chasm, need dps too | LFM meat shield an' witch doctor for Ragefire Chasm, need dps too |
| our priest died, can a shaman or druid heal? | our preacha died, can a spirit-walka or bear-hugga mend? |
| rogues and hunters on the left, warriors in front | backstabbas an' beast-tamas on da left, berserkas in front |
| the mage is out of mana | da juju-flinga be outta mana |
| need 1 more paladin | need 1 more bubble-knight |

Melee and ranged become stabby and throwy, a caster is a spell-slinga and a warlock is a fel-dabbla. "Tanks" stays tanks, because that is how a troll says thanks. Inside a creature or place name the words stay put, so Thunder Bluff's Hunter Rise is still Hunta Rise. The list is in `Lexicon.lua` under `L.roles`.

## Creature names

Creature names get the troll accent, while players' names are left alone:

| You type | Everyone sees |
| --- | --- |
| Let's go kill Hogger | Let's go kill Hogga |
| the Harvest Watchers are tough | da Harvest Watchas be tough |
| watch out for the Cursed Raptor | watch out for da Hexed Raptor |
| Elder Mottled Boars everywhere | Elda Mottled Boars everywhere |

Juju learns which names are creatures in two ways:

- **From Questie**, if you have it. QuestieDB lists every creature in the game. A few seconds after you log in, Juju reads the names of the hostile ones and of neutral beasts like Mottled Boars, about 8,000 names, a little each frame so the game does not stutter. The list is kept, so this happens once, and again only when QuestieDB is updated. Nothing in Questie is changed.
- **From the world.** Every hostile creature you target, point at or see a nameplate for is remembered from then on. This works without Questie too.

Type `/juju creatures` to see how many names Juju knows and where they came from, and `/juju creatures off` or `on` to switch the feature. Switch it off with **Jujuify creature names** in the settings, or give one creature a name of your own with Ya Own Juju.

## Place names

Place names get the troll accent too:

| You type | Everyone sees |
| --- | --- |
| meet me in Thunder Bluff | meet me in Tunda Bluff |
| we ride to the Crossroads | we ride ta da Crossroads |
| the Barrens are hot | da Barrens be hot |
| see you in the Thousand Needles | see ya in da Tousand Needles |
| back to the Echo Isles | back ta da Echo Isles |

Juju knows the game's own zones, cities and dungeons, Questie's list of about 2,500 zones and subzones if you have it, and every place you visit. Names it would not change, like Orgrimmar and Razor Hill, stay as they are. Type `/juju places` to see how many it knows, and `/juju places off` or `on` to switch it.

## Swearing

Real-world curse words break the mood, so with **Troll words** on they come out as troll ones. A troll puts a *hex* on what he hates, anyone he does not like is a *fool* (or a *hyena*), and the rest is *raptor dung*. Tell someone to get lost and they are sent to see Bwonsamdi.

| You type | Everyone sees |
| --- | --- |
| What the fuck is that? | Wha' da hex be dat? |
| Shit, they are coming! | Raptor dung, dey be comin'! |
| Fuck off, you stupid bitch | Go see Bwonsamdi, ya stupid hyena |
| Holy shit, look at that | Loa preserve us, look at dat |
| shut the fuck up | shut ya hexed mout' |
| wtf was that | wha' da hex was dat |

- Spellings meant to get round a filter are understood too: `fk`, `fking`, `f**k`, `sh*t`, `b1tch`, `a$$`.
- So is chat shorthand: `wtf`, `stfu`, `ffs`, `omg`.
- Juju never makes a line ruder than you typed it. The typo fixer will not turn a slip of the finger into a curse word, and with troll words off nothing is spelled out.
- The list is in `Lexicon.lua` under `L.swears`. To change one word for yourself, use Ya Own Juju.

## Troll emotes

Nine new emote commands. Add a name to aim one at someone, or target them first:

| Command | You do |
| --- | --- |
| `/voodoo` | wiggles his fingers mysteriously. "Stay away from da voodoo, mon." |
| `/mon` | nods slowly at Rokhan. "Ya, mon. We be cool." |
| `/hex` | points a long finger at Rokhan and mutters a nasty little hex. "Ribbit, mon." |
| `/bones` | casts a handful of bones at Rokhan's feet. "Da bones say ya be in trouble, mon." |
| `/mojo` | sends a little mojo Rokhan's way. "Dere ya go, mon. Good mojo." |
| `/tusks` | polishes his tusks with great care. |
| `/loa` | raises his arms to the sky. "Da Loa be wit' us!" |
| `/bwonsamdi` | grins at Rokhan. "Bwonsamdi be waitin' for ya, mon." |
| `/chill` | kicks back and takes it easy. "No worries, mon." |

The wording follows your voice (a Witch Doctor's `/voodoo` comes with a little doll that looks a lot like your target) and says her for female characters. If the game or another addon already uses one of these commands, Juju leaves it alone and you can type `/juju emote hex` instead. The lines are in `Lexicon.lua` under `L.emotes`.

### The Emotes page

The Juju box has two tabs at the top, **Words** and **Emotes**. `/juju emotes` opens straight onto Emotes. There is a button for every emote: click one to do it, aimed at your target if you have one, and point at it to see exactly what everyone will see.

### Your own emotes

The bottom of the Emotes page makes your own. Give it a name (it becomes `/name`), what you do, and what you do to someone else, then press **Save emote**:

| Name | What you do | What you do to someone |
| --- | --- | --- |
| frog | pulls a frog out of {his} pocket and lets it loose. | throws a frog at {target}. It croaks. |

`{target}` is who you aim at and `{his}` becomes her for a female character. Leave the last line empty to use the same line either way. Your emotes get a teal button, `/name` (unless the game or another addon already has it) and `/juju emote name`. Your emotes are also listed at the bottom of the page: click one to change it, or its red X to remove it (right-clicking its button works too). You can keep up to 12, and they work on every character.

## People you know

Juju never changes the names of your guildmates, your friends, or the characters your Battle.net friends are playing, even when they are not nearby and even when a name matches a creature or a place. Typed in small letters, a name stays as typed unless it is also an ordinary word: "rokhan" stays rokhan, but "the hunter" is still da beast-tama. The names are remembered between sessions; `/juju names` says how many.

## Troll voices

Each character can be a different kind of troll. Pick one with the **Voice** button at the top of the Juju box (click for the next, right-click for the one before, and watch the troll text change), in the settings, or with `/juju voice witchdoctor`.

| Voice | What it is like | For example |
| --- | --- | --- |
| Darkspear | A laid-back Darkspear troll from the Echo Isles. | Hey, mon! We need more juju. |
| Sistah | Sharp tongue, sharper glaive. No time for fools. | Listen 'ere, sugar. We need more juju. |
| Witch Doctor | Hexes, brews and bones. | Da spirits be sayin'... We need more juju. |
| Headhunter | Loves a good hunt and a better trophy. Every yell ends with mon! | We need more juju, an' I be takin' dey head. |
| Shadow Hunter | Calm, quiet and close to the Loa. Talks in riddles. | Where be da witch doctor, or do da shadows lie? |
| Zandalari | Old, proud and sure the Zandalari are the finest trolls. | Where be da witch doctor, lesser troll? |

Each voice has its own flourishes, which you hear while **Troll flourishes** is on, and a few words of its own, used while **Troll words** is on: a Witch Doctor's potion is a brew, a Headhunter's enemies are prey, and a Zandalari greets you with "greetin's" and calls you "young one". Each character keeps its own voice. Until you choose one, female characters start as a Sistah and everyone else as a Darkspear. The voices are in `Lexicon.lua` under `L.voices`, if you want to change them or add your own.

## Troll flourishes

Switch on **Troll flourishes** in the settings (or type `/juju flourishes`) and about one message in three gets a bit of extra troll:

| You type | Might come out as |
| --- | --- |
| We need more magic. | Hey, mon! We need more juju. |
| We need more magic. | We need more juju, mon. |
| Where is the healer? | Where be da witch doctor, mon? |
| For the Horde! | For da Horde! Ya, mon! |

The preview above the chat line shows exactly what will be sent, flourish and all, so there are no surprises when you press Enter. Emotes, single words and lines that already say "mon" or start with "hey" are left alone, and nothing is ever added after an `((OOC))` remark or an `*action*` at the end of a line.

The openers and closers are listed in `Lexicon.lua` under `L.flourishes`, if you want to add your own.

## Questie

If you use [Questie](https://github.com/Questie/Questie) and have it announce quest progress to your party, Juju says those announcements in troll too:

| Questie would say | With Juju |
| --- | --- |
| Kobold Vermin slain: 10/10 for [Kobold Camp Cleanup]! | Dat be 10/10 Kobold Vermin slain for [Kobold Camp Cleanup]! |
| Picked up [Demon Scarred Cloak] which starts [quest]! | Found [Demon Scarred Cloak], it start [quest]! |
| Quest Accepted: [quest] | New job, mon: [quest] |
| Quest Completed: [quest] | Dis job be done: [quest] |
| Quest Abandoned: [quest] | Forget dis job: [quest] |

- Names of creatures, items and places are kept exactly as the game wrote them, and quest and item links stay clickable.
- The "Questie:" marker at the front is untouched, so other players' Questie still shows its logo.
- It follows your **Party** and **Raid** switches, and only works while troll speech is on for the character. Your own words and troll flourishes apply too.
- Which announcements are made at all (objectives, accepted, completed and so on) is still decided in Questie's own options.
- Switch it off with **Questie announcements in troll** in the settings, or `/juju questie`.

Juju only steps in while Questie is announcing. If Questie is not installed, or a later version changes how it announces, Juju leaves it alone. The troll wording is in `Lexicon.lua` under `L.questie`.

## Sloppy typing

Juju works out what you meant before turning it into troll, so typing fast does not break the RP.

| You type | Everyone sees |
| --- | --- |
| Im gonna kill teh murlocs, dont wory abuot it | I be gonna kill da murlocs, don't worry 'bout it |
| thats not waht i siad, u r a coward | dat be not wha' I said, ya be a scaredy-raptor |
| don;t touch that, it;s mine | don't touch dat, it be mine |
| we need more fihgters, the allaince is coming | we need more fightas, da alliance be comin' |

- **Contractions without the apostrophe** (dont, im, thats, doesnt, hasnt, youre) and the `;` key hit instead of `'` are always understood.
- **Common typos and chat shorthand** (teh, adn, becuase, alot, u, ur, idk, thx) are listed in `Lexicon.lua` and always fixed.
- **Other typos** are worked out from a list of about 65,000 English words. A swapped letter, a missing or extra letter, or the key next door is fixed when one word is clearly the likeliest. Juju only changes a word it does not recognise, never a real word, and when it is not sure it leaves your word alone. Words with a capital letter are treated as names and never guessed, and so are lore names, game talk, troll spellings you type yourself (tink, dem, nuttin) and the names of people near you. If a guess is wrong you will see it in the preview before you send. You can switch guessing off with **Fix typos** in the settings.

Some contractions are real words when typed without the apostrophe (its, were, well, ill, shed, lets), so those are left as typed.

## Settings

Under Options > AddOns > Juju:

- **Talk like a troll on this character.** The main switch, remembered per character.
- **Voice on this character.** Darkspear, Sistah, Witch Doctor, Headhunter, Shadow Hunter or Zandalari.
- **Troll words.** On: magic is juju, luck is mojo, the gods are da Loa, and classes get troll names. Off: accent only (`da`, `wit'`, `tink`, `fightin'`).
- **Troll flourishes.** Now and then adds a "Hey, mon!" in front or a ", ya hear" at the end. Off to begin with.
- **Jujuify creature names.** Hogger becomes Hogga. Players' names are still left alone.
- **Jujuify place names.** Thunder Bluff becomes Tunda Bluff.
- **Questie announcements in troll.** If you use Questie, its party announcements are said in troll.
- **Mon! when yelling.** Adds "mon" to any `/yell` that ends in an exclamation mark: "Charge!" becomes "Charge, mon!"
- **Fix typos.** Works out the word you meant when one is mistyped. Contractions and shorthand are understood even with this off.
- **Mangle names too.** Normally a capitalised word in the middle of a sentence is treated as a name and kept, so Thrall stays Thrall. Switch this on and he becomes Trall.
- **Show the troll version while typing.** The preview line above the chat box.
- **Show Troll or Plain on the chat line.** The clickable tag beside the preview.
- **Where to talk troll.** One switch per kind of chat. Say, yell, emote, party, raid, guild and whisper start on. Battle.net whispers, General, Trade, LookingForGroup and the other numbered channels start off.

The same switches work from chat: `/juju guild off`, `/juju trade on`.

## Key bindings

Under Key Bindings > AddOns > Juju:

- **Switch troll speech on or off** for this character.
- **Switch troll speech in General, Trade and other channels.**
- **Open or close the Juju box.**

## Juju and Krump together

Krump is Juju's sister addon for Orc characters. You can have both installed: Juju talks on your Trolls and Krump on your Orcs, and only one of them ever changes a message.

- Typing `/juju on` on a character switches Krump off there, and `/krump on` does the reverse.
- If both are on anyway, the one made for the character's race talks. `/juju help` says when Juju is waiting for Krump.

This needs Krump 1.15.1 or later.

## What Juju leaves alone

- Item, spell and quest links, raid markers such as `{skull}`, and web addresses.
- Emotes, apart from speech in `"double quotes"`. `/e grunts, "What do you want?"` becomes `grunts, "Wha' do ya want?"`.
- The names of you, your target, your group and anyone who has spoken near you recently.
- Zandali and Orcish (`Zul'jin`, `Lok'tar ogar`, `Zug zug`), slash commands and `!keys`-style addon commands.
- Troll you type yourself. "Ya mon, dat be da ting" goes out just as you typed it.
- Macros. Only what you type into the chat box is translated.
- Any message that would become too long for chat once translated. It is sent as you typed it.

Only what you send is changed. What other people say reaches you untouched.

## Changing the words

All the vocabulary is in `Lexicon.lua`, as plain lists:

```lua
["magic"] = "juju",
["luck"] = "mojo",
```

Add a line, save, and `/reload`. Words that are not listed still get the accent from the sound rules in `Translator.lua` (th to t or d, -ing to -in', -er to -a).

The same file has the lists for sloppy typing: `L.contractions`, `L.typos` (fixed exactly as listed, and the value can be several words) and `L.jargon` (names and game words the typo guesser must never touch). If a word you use keeps getting "corrected", add it to `L.jargon`.

`Words.lua` is generated, so do not edit it by hand. `tools/build_words.lua` rebuilds it from the SCOWL word lists (the `scowl` package on Debian and Ubuntu).

## Tests

The translator needs nothing from the game, so it can be tested with a plain Lua 5.1:

```
lua5.1 tests/run.lua
```

This checks the translator on its own, then loads the whole addon into a stand-in game client and sends chat through it.

## Notes

Juju hooks the `ChatFrame.OnEditBoxPreSendText` event, which the game fires so addons can make final edits to a chat message before it is sent. Nothing of the game's own is replaced.

The English word list comes from SCOWL (Spell Checker Oriented Word Lists) by Kevin Atkinson and others. Its licence notices are in `WORDS-LICENSE.txt`.

This is a fan-made addon. It is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.
