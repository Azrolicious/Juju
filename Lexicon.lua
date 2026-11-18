-- Juju word lists.
--
-- Everything here is plain data, so this is the file to edit if you want your
-- troll to talk differently. Keys are always lowercase English; the
-- translator sorts out capital letters by itself ("The" -> "Da", "THE" -> "DA").
--
-- Words that are not listed still get the troll accent from the sound rules
-- in Translator.lua (think -> tink, both -> bot', fighting -> fightin',
-- never -> neva, brother -> brudda).

local _, ns = ...

local L = {}
ns.Lexicon = L

-- The accent: how a troll says ordinary words. Always applied.
L.accent = {
	-- pointing words (the "th" here turns into "d", not "t")
	["the"] = "da", ["this"] = "dis", ["that"] = "dat", ["these"] = "dese",
	["those"] = "dose", ["them"] = "dem", ["they"] = "dey", ["their"] = "dey",
	["theirs"] = "deirs", ["there"] = "dere", ["then"] = "den", ["than"] = "dan",
	["though"] = "tho", ["tho"] = "tho", ["although"] = "altho", ["thus"] = "so",
	["therefore"] = "so", ["themselves"] = "demselves",
	["thee"] = "ya", ["thou"] = "ya", ["thy"] = "ya", ["thine"] = "yours",

	-- with / other
	["with"] = "wit'", ["without"] = "widout", ["within"] = "widin",
	["other"] = "udda", ["another"] = "anudda", ["otherwise"] = "uddawise",
	["brother"] = "brudda", ["mother"] = "mudda",

	-- you / me
	["you"] = "ya", ["your"] = "ya", ["yours"] = "yours",
	["yourself"] = "yaself", ["yourselves"] = "yaselves",
	["my"] = "me", ["myself"] = "meself",
	["i'm"] = "I be", ["i'll"] = "I'll", ["i've"] = "I've", ["i'd"] = "I'd",
	["you'll"] = "ya gonna",

	-- being and doing: trolls use "be" for everything
	["is"] = "be", ["are"] = "be", ["am"] = "be",
	["was"] = "was", ["were"] = "was",
	["isn't"] = "ain't", ["aren't"] = "ain't", ["wasn't"] = "wasn't", ["weren't"] = "wasn't",
	["haven't"] = "ain't", ["hasn't"] = "ain't",
	["does"] = "do", ["doesn't"] = "don't", ["cannot"] = "can't",

	-- question words
	["what"] = "wha'",

	-- little joining words
	["and"] = "an'", ["to"] = "ta", ["just"] = "jus'",
	["about"] = "'bout", ["around"] = "'round", ["because"] = "'cause", ["cuz"] = "'cause",
	["until"] = "'til", ["little"] = "lil'", ["probably"] = "prob'ly", ["suppose"] = "s'pose",
	["perhaps"] = "maybe",

	-- some / every / no
	["something"] = "someting", ["anything"] = "anyting", ["everything"] = "everyting",
	["nothing"] = "nuttin'",

	-- hello and goodbye
	["greetings"] = "greetin's", ["bye"] = "lata", ["goodbye"] = "walk wit' da Loa",
	["farewell"] = "walk wit' da Loa",
	-- "tanks" is how a troll says thanks, so it is not a plural of the tank
	-- role (see L.roles): saying it twice must not make "meat shields".
	["yes"] = "ya", ["thanks"] = "tanks", ["thx"] = "tanks", ["tanks"] = "tanks",
	["man"] = "mon", ["dude"] = "mon", ["bro"] = "mon", ["buddy"] = "mon", ["pal"] = "mon",

	-- spellings the sound rules would not find
	["through"] = "troo", ["thru"] = "troo", ["throughout"] = "all troo",
}

-- Troll words, from da Echo Isles to Zul'Gurub: da Loa, juju, mojo and hexes.
-- Only used while "Troll words" is switched on.
L.vocab = {
	-- da Loa are a troll's gods
	["god"] = "Loa", ["gods"] = "da Loa", ["goddess"] = "Loa", ["deity"] = "Loa", ["deities"] = "da Loa",

	-- magic and luck
	["magic"] = "juju", ["magical"] = "juju", ["sorcery"] = "juju", ["witchcraft"] = "voodoo",
	["luck"] = "mojo", ["unlucky"] = "hexed",
	["curse"] = "hex", ["cursed"] = "hexed",

	-- who you run with
	["guild"] = "tribe", ["clan"] = "tribe",
	["healer"] = "witch doctor", ["doctor"] = "witch doctor", ["medic"] = "witch doctor",
	["surgeon"] = "witch doctor",
	["children"] = "lil' ones", ["kids"] = "lil' ones",
	["enemy"] = "foe", ["enemies"] = "foes",

	-- moods
	["angry"] = "vexed", ["annoyed"] = "vexed", ["furious"] = "vexed", ["irritated"] = "vexed",

	-- brews and grog
	["potion"] = "brew", ["medicine"] = "brew", ["elixir"] = "brew",
	["beer"] = "grog", ["ale"] = "grog", ["booze"] = "grog", ["alcohol"] = "grog",

	-- insults
	["idiot"] = "fool", ["moron"] = "fool", ["imbecile"] = "fool",
	["coward"] = "scaredy-raptor", ["cowards"] = "scaredy-raptors",
	["small"] = "lil'", ["tiny"] = "lil'",

	-- the good stuff
	["awesome"] = "mighty fine", ["amazing"] = "mighty fine", ["excellent"] = "mighty fine",
	["wonderful"] = "mighty fine", ["fantastic"] = "mighty fine",
}

-- Classes and roles, for party talk: "need a tank and a priest" ->
-- "need a meat shield an' a preacha". Written in troll spelling already, so
-- that saying them twice changes nothing. Used while "Troll words" is on, but
-- never inside a creature or place name (Thunder Bluff's Hunter Rise stays
-- Hunta Rise). Plurals come by themselves: rogues -> backstabbas.
L.roles = {
	-- roles
	["tank"] = "meat shield", ["tanking"] = "holdin' da line", ["tanked"] = "held da line",
	["heal"] = "mend", ["heals"] = "mendin'", ["healing"] = "mendin'",
	["melee"] = "stabby", ["ranged"] = "throwy", ["caster"] = "spell-slinga",
	-- classes
	["warrior"] = "berserka",
	["paladin"] = "bubble-knight", ["pally"] = "bubble-knight", ["pallies"] = "bubble-knights",
	["priest"] = "preacha",
	["mage"] = "juju-flinga",
	["warlock"] = "fel-dabbla",
	["shaman"] = "spirit-walka",
	["druid"] = "bear-hugga",
	["rogue"] = "backstabba",
	["hunter"] = "beast-tama",
}

-- Swearing. Real-world curse words break the mood, so they become troll ones:
-- a hex is what a troll puts on a thing he hates, a fool is anyone he does
-- not like, and raptor dung is what it sounds like. Used while "Troll words"
-- is switched on, like the list above.
--
-- These words get special care elsewhere: the typo guesser never turns a
-- mistyped word into one of them (see Spell.lua), though common ways of
-- spelling them are understood (see L.typos and L.disguised below).
L.swears = {
	["fuck"] = "hex", ["fucked"] = "hexed", ["fucking"] = "hexed", ["fuckin"] = "hexed",
	["fucker"] = "fool", ["fuckers"] = "fools", ["fuckup"] = "mess", ["clusterfuck"] = "big mess",
	["fuckwit"] = "fool",
	["motherfucker"] = "hexed fool", ["motherfuckers"] = "hexed fools", ["motherfucking"] = "hexed",

	["shit"] = "raptor dung", ["shits"] = "raptor dung", ["shite"] = "raptor dung",
	["bullshit"] = "raptor dung", ["horseshit"] = "raptor dung", ["bollocks"] = "raptor dung",
	["shitty"] = "rotten", ["shitting"] = "hexed", ["shitload"] = "whole heap", ["shitshow"] = "big mess",
	["shithead"] = "dung-head", ["shitheads"] = "dung-heads", ["dipshit"] = "dung-head",
	["crap"] = "dung", ["bullcrap"] = "dung", ["crappy"] = "rotten",
	["piss"] = "swamp water", ["pissed"] = "vexed",

	["damn"] = "hex", ["damned"] = "hexed", ["dammit"] = "hex it", ["damnit"] = "hex it",
	["goddamn"] = "Loa-cursed", ["goddamned"] = "Loa-cursed", ["goddamnit"] = "hex it", ["goddammit"] = "hex it",
	["darn"] = "hex", ["dang"] = "hex", ["bugger"] = "hex", ["bloody"] = "hexed",
	["freaking"] = "hexed", ["freakin"] = "hexed", ["frigging"] = "hexed", ["friggin"] = "hexed",
	["fricking"] = "hexed", ["frickin"] = "hexed", ["effing"] = "hexed",

	["bitch"] = "hyena", ["bitches"] = "hyenas", ["bitching"] = "whinin'",
	["bastard"] = "fool", ["bastards"] = "fools",
	["cunt"] = "fool", ["cunts"] = "fools", ["twat"] = "fool", ["twats"] = "fools",
	["dick"] = "fool", ["dicks"] = "fools", ["prick"] = "fool", ["pricks"] = "fools",
	["wanker"] = "fool", ["wankers"] = "fools", ["tosser"] = "fool", ["tossers"] = "fools",
	["douche"] = "fool", ["douchebag"] = "fool", ["douchebags"] = "fools",
	["scumbag"] = "fool", ["scumbags"] = "fools",
	["dickhead"] = "dung-head", ["dickheads"] = "dung-heads",
	["pussy"] = "scaredy-raptor", ["pussies"] = "scaredy-raptors",

	["ass"] = "backside", ["asses"] = "backsides",
	["asshole"] = "fool", ["assholes"] = "fools",
	["arsehole"] = "fool", ["arseholes"] = "fools",
	["dumbass"] = "dumb fool", ["dumbasses"] = "dumb fools", ["jackass"] = "dumb fool",
	["asshat"] = "dumb fool", ["smartass"] = "smart mout'", ["badass"] = "mighty fierce",

	-- oaths
	["jesus"] = "spirits", ["christ"] = "spirits",

	-- chat shorthand
	["wtf"] = "wha' da hex", ["wth"] = "wha' da hex", ["stfu"] = "shut ya mout'",
	["gtfo"] = "go see Bwonsamdi", ["ffs"] = "for da Loa's sake",
	["omg"] = "by da Loa", ["omfg"] = "by da Loa",
}

-- Words that come after "going to" or "got to" when it is a trip, not a plan.
local PLACES_AHEAD = "the a an my your his her their our this that these those da dat dis dem me ya"

-- Several words that become one troll word. The longest match wins.
--   vocab     = true: only while "Troll words" is switched on
--   notBefore = words that stop the phrase when they come next (a word
--               with a capital letter, such as a place, always does)
L.phrases = {
	{ "going to", "gonna", notBefore = PLACES_AHEAD },
	{ "want to", "wanna" },
	{ "got to", "gotta", notBefore = PLACES_AHEAD },
	{ "have to", "gotta" },
	{ "has to", "gotta" },
	{ "kind of", "kinda" },
	{ "sort of", "sorta" },
	{ "out of", "outta" },
	{ "a lot of", "lotsa" },
	{ "lots of", "lotsa" },
	{ "lot of", "lotsa" },
	{ "give me", "gimme" },
	{ "let me", "lemme" },
	{ "come on", "c'mon" },
	{ "don't know", "dunno" },
	{ "do not know", "dunno" },
	{ "is not", "ain't" },
	{ "are not", "ain't" },
	{ "am not", "ain't" },
	{ "have not", "ain't" },
	{ "has not", "ain't" },
	{ "was not", "wasn't" },
	{ "were not", "wasn't" },
	{ "do not", "don't" },
	{ "does not", "don't" },
	{ "did not", "didn't" },
	{ "will not", "won't" },
	{ "can not", "can't" },
	{ "thank you", "tank ya" },
	{ "excuse me", "'scuse me" },
	{ "shut up", "shut ya mout'" },
	{ "what's up", "wassup" },
	{ "what is up", "wassup" },
	{ "how are you", "how ya doin'" },
	{ "you guys", "all o' ya" },
	{ "you all", "all o' ya" },
	{ "y'all", "all o' ya" },
	{ "see you later", "lata, mon" },

	{ "go away", "go see Bwonsamdi", vocab = true },
	{ "get lost", "go see Bwonsamdi", vocab = true },
	{ "piss off", "go see Bwonsamdi", vocab = true },
	{ "fuck off", "go see Bwonsamdi", vocab = true },
	{ "bugger off", "go see Bwonsamdi", vocab = true },
	{ "sod off", "go see Bwonsamdi", vocab = true },
	{ "screw off", "go see Bwonsamdi", vocab = true },
	{ "go to hell", "go see Bwonsamdi", vocab = true },
	{ "pissed off", "vexed", vocab = true },
	{ "what the hell", "wha' da hex", vocab = true },
	{ "what the fuck", "wha' da hex", vocab = true },
	{ "what the heck", "wha' da hex", vocab = true },
	{ "the hell", "da hex", vocab = true },
	{ "the fuck", "da hex", vocab = true },
	{ "the heck", "da hex", vocab = true },
	{ "hell yeah", "ya, mon", vocab = true },
	{ "hell yes", "ya, mon", vocab = true },
	{ "hell no", "no way, mon", vocab = true },
	{ "shut the fuck up", "shut ya hexed mout'", vocab = true },
	{ "shut the hell up", "shut ya hexed mout'", vocab = true },
	{ "screw you", "hex ya", vocab = true },
	{ "screw it", "hex it", vocab = true },
	{ "screw this", "hex dis", vocab = true },
	{ "screw that", "hex dat", vocab = true },
	{ "son of a bitch", "son of a hyena", vocab = true },
	{ "sons of bitches", "sons of hyenas", vocab = true },
	{ "piece of shit", "lump of raptor dung", vocab = true },
	{ "pieces of shit", "lumps of raptor dung", vocab = true },
	{ "piece of crap", "lump of dung", vocab = true },
	{ "give a shit", "give a hex", vocab = true },
	{ "give a crap", "give a hex", vocab = true },
	{ "no shit", "no lie, mon", vocab = true },
	{ "oh shit", "oh hex", vocab = true },
	{ "holy shit", "Loa preserve us", vocab = true },
	{ "holy crap", "Loa preserve us", vocab = true },
	{ "holy fuck", "Loa preserve us", vocab = true },
	{ "holy hell", "Loa preserve us", vocab = true },
	{ "oh my god", "by da Loa", vocab = true },
	{ "oh my gosh", "by da Loa", vocab = true },
	{ "jesus christ", "spirits above", vocab = true },
	{ "god damn it", "hex it", vocab = true },
	{ "god dammit", "hex it", vocab = true },
	{ "god damn", "Loa-cursed", vocab = true },
	{ "bad ass", "mighty fierce", vocab = true },
	{ "the gods", "da Loa", vocab = true },
	-- already troll: do not make a witch witch doctor
	{ "witch doctor", "witch doctor", vocab = true },
	{ "witch doctors", "witch doctors", vocab = true },
}

-- "it's", "that's", "he's": after these words 's means "is", so it becomes
-- "be" (it be, dat be, he be). After any other word it means "belongs to",
-- and stays: Thrall's axe, da troll's tusks.
L.isWords = {
	["it"] = true, ["that"] = true, ["this"] = true, ["what"] = true, ["where"] = true,
	["who"] = true, ["how"] = true, ["there"] = true, ["here"] = true, ["he"] = true,
	["she"] = true, ["everything"] = true, ["nothing"] = true, ["something"] = true,
	["everyone"] = true, ["someone"] = true, ["everybody"] = true, ["somebody"] = true,
	["nobody"] = true,
}

-- When one of these comes next, 's meant "has", and is simply dropped:
-- "he's got a spear" -> "he got a spear", "it's been ages" -> "it been ages".
L.hasWords = {
	["been"] = true, ["got"] = true, ["gotten"] = true, ["gone"] = true, ["had"] = true,
}

-- Words the sound rules must leave alone.
L.keep = {
	-- noises
	["ha"] = true, ["hah"] = true, ["har"] = true, ["heh"] = true, ["huh"] = true, ["ho"] = true,
	["hooray"] = true, ["hurrah"] = true, ["huzzah"] = true,
	-- "-er" words that would stop making sense as "-a"
	["prefer"] = true, ["refer"] = true, ["defer"] = true, ["confer"] = true,
	["infer"] = true, ["transfer"] = true, ["deter"] = true, ["paper"] = true,
	-- Orcish and dungeon shorthand
	["throm"] = true, ["ubrs"] = true, ["lbrs"] = true, ["hots"] = true,
}

-- Words ending in "s" that are not plurals.
L.noPlural = {
	["chaos"] = true, ["alas"] = true, ["atlas"] = true, ["bias"] = true,
	["canvas"] = true, ["whereas"] = true, ["kudos"] = true, ["cosmos"] = true,
	["series"] = true, ["species"] = true, ["lens"] = true,
	["oops"] = true, ["whoops"] = true,
}

---------------------------------------------------------------------------
-- Sloppy typing
--
-- Everything below turns what was typed into proper English first. The
-- English is then translated like anything else, so "dont" and "don't" both
-- come out the same way.
---------------------------------------------------------------------------

-- Contractions typed without the apostrophe.
-- Left out on purpose because they are real words too: its, were, well,
-- hell, shell, shed, wed, ill, id, lets.
L.contractions = {
	["im"] = "I'm", ["ive"] = "I've",
	["i'm"] = "I'm", ["i've"] = "I've", ["i'll"] = "I'll", ["i'd"] = "I'd",
	["youre"] = "you're", ["youve"] = "you've", ["youll"] = "you'll", ["youd"] = "you'd",
	["theyre"] = "they're", ["theyve"] = "they've", ["theyll"] = "they'll", ["theyd"] = "they'd",
	["weve"] = "we've", ["hes"] = "he's", ["shes"] = "she's",
	["thats"] = "that's", ["whats"] = "what's", ["wheres"] = "where's", ["theres"] = "there's",
	["heres"] = "here's", ["whos"] = "who's", ["hows"] = "how's",
	["itll"] = "it'll", ["itd"] = "it'd", ["thatll"] = "that'll", ["thatd"] = "that'd",
	["whod"] = "who'd", ["whove"] = "who've",
	["isnt"] = "isn't", ["arent"] = "aren't", ["wasnt"] = "wasn't", ["werent"] = "weren't",
	["dont"] = "don't", ["doesnt"] = "doesn't", ["didnt"] = "didn't",
	["hasnt"] = "hasn't", ["havent"] = "haven't", ["hadnt"] = "hadn't",
	["cant"] = "can't", ["wont"] = "won't", ["aint"] = "ain't",
	["wouldnt"] = "wouldn't", ["couldnt"] = "couldn't", ["shouldnt"] = "shouldn't",
	["mustnt"] = "mustn't", ["neednt"] = "needn't",
	["wouldve"] = "would've", ["couldve"] = "could've", ["shouldve"] = "should've",
	["mustve"] = "must've", ["mightve"] = "might've",
	["yall"] = "y'all", ["oclock"] = "o'clock", ["maam"] = "ma'am",
}

-- Typos and shorthand that are fixed exactly as listed. The value is what
-- was meant, and may be more than one word.
--
-- Anything not listed here is left to Spell.lua, which can work out most
-- single slips in words of four letters or more by itself. So this list is
-- for the cases it cannot do: short words, slips with two possible answers,
-- words run together, and spellings that are wrong in two places.
L.typos = {
	-- the, and, you
	["teh"] = "the", ["hte"] = "the", ["tthe"] = "the", ["thw"] = "the", ["tge"] = "the",
	["adn"] = "and", ["nad"] = "and", ["anf"] = "and", ["abd"] = "and",
	["yuo"] = "you", ["yoy"] = "you", ["yiu"] = "you", ["tou"] = "you", ["uoy"] = "you",
	["yoru"] = "your", ["yuor"] = "your", ["yoiur"] = "your",
	-- that, this, what, with, when, then, than, them, they, there, their
	["taht"] = "that", ["thta"] = "that", ["htat"] = "that", ["tath"] = "that",
	["thsi"] = "this", ["tihs"] = "this", ["htis"] = "this",
	["waht"] = "what", ["whta"] = "what", ["wath"] = "what", ["hwat"] = "what", ["wat"] = "what", ["wut"] = "what",
	["wiht"] = "with", ["wtih"] = "with", ["iwth"] = "with", ["whit"] = "with", ["wih"] = "with",
	["wehn"] = "when", ["whne"] = "when", ["hwen"] = "when",
	["thne"] = "then", ["tehn"] = "then", ["thna"] = "than", ["tahn"] = "than",
	["tehm"] = "them", ["thme"] = "them", ["tehy"] = "they", ["thye"] = "they", ["tyhe"] = "they",
	["tehre"] = "there", ["theer"] = "there", ["htere"] = "there",
	["thier"] = "their", ["tehir"] = "their", ["theri"] = "their",
	["wich"] = "which", ["whcih"] = "which", ["wihch"] = "which",
	["wether"] = "whether", ["wheter"] = "whether",
	-- small everyday words
	["jsut"] = "just", ["ujst"] = "just", ["jstu"] = "just",
	["liek"] = "like", ["lkie"] = "like", ["likr"] = "like",
	["knwo"] = "know", ["konw"] = "know", ["nkow"] = "know", ["kno"] = "know",
	["wnat"] = "want", ["watn"] = "want", ["wnet"] = "went",
	["ahve"] = "have", ["hvae"] = "have", ["haev"] = "have", ["hav"] = "have",
	["ahd"] = "had", ["hsa"] = "has", ["ahs"] = "has",
	["cna"] = "can", ["acn"] = "can", ["nto"] = "not", ["nwo"] = "now", ["woh"] = "who",
	["aer"] = "are", ["wsa"] = "was", ["aws"] = "was", ["wre"] = "were",
	["smoe"] = "some", ["soem"] = "some", ["cmoe"] = "come", ["coem"] = "come",
	["tiem"] = "time", ["tmie"] = "time", ["mroe"] = "more", ["moer"] = "more",
	["mcuh"] = "much", ["muhc"] = "much", ["siad"] = "said", ["sadi"] = "said",
	["ehre"] = "here", ["heer"] = "here",
	["ot"] = "to", ["si"] = "is", ["ti"] = "it", ["fi"] = "if",
	["ocr"] = "orc", ["ocrs"] = "orcs", ["trol"] = "troll", ["torll"] = "troll", ["trolsl"] = "trolls",
	-- two possible answers, so the likelier one is chosen here
	["wierd"] = "weird", ["frend"] = "friend", ["frends"] = "friends", ["freind"] = "friend",
	["freinds"] = "friends", ["sence"] = "sense", ["peice"] = "piece", ["peices"] = "pieces",
	["alway"] = "always", ["somthing"] = "something", ["sumthing"] = "something",
	["evrything"] = "everything",
	-- wrong in two places
	["tommorow"] = "tomorrow", ["tommorrow"] = "tomorrow", ["tomorow"] = "tomorrow", ["tmrw"] = "tomorrow",
	["definately"] = "definitely", ["definatly"] = "definitely", ["definetly"] = "definitely", ["defintely"] = "definitely",
	["basicly"] = "basically", ["probally"] = "probably", ["probaly"] = "probably",
	["dissapear"] = "disappear", ["dissapeared"] = "disappeared", ["dissapoint"] = "disappoint",
	["dissapointed"] = "disappointed", ["neccesary"] = "necessary", ["neccessary"] = "necessary",
	["necesary"] = "necessary", ["reccomend"] = "recommend", ["rember"] = "remember",
	["remeber"] = "remember", ["beggining"] = "beginning", ["begining"] = "beginning",
	["becuase"] = "because", ["becasue"] = "because", ["beacuse"] = "because", ["becuse"] = "because",
	["ebcause"] = "because", ["bcause"] = "because", ["becouse"] = "because",
	["peopel"] = "people", ["poeple"] = "people", ["pepole"] = "people", ["peolpe"] = "people",
	["thnaks"] = "thanks", ["thansk"] = "thanks", ["thakns"] = "thanks", ["tahnks"] = "thanks",
	["probalby"] = "probably", ["suposed"] = "supposed", ["supossed"] = "supposed",
	["enemys"] = "enemies", ["enemeis"] = "enemies", ["enimies"] = "enemies",
	["dwarfes"] = "dwarves", ["elfs"] = "elves", ["theif"] = "thief", ["theives"] = "thieves",
	["wolfs"] = "wolves", ["dieing"] = "dying", ["lieing"] = "lying",
	-- words run together
	["alot"] = "a lot", ["aswell"] = "as well", ["infront"] = "in front", ["atleast"] = "at least",
	["eachother"] = "each other", ["incase"] = "in case", ["noone"] = "no one", ["abit"] = "a bit",
	["ofcourse"] = "of course", ["everytime"] = "every time", ["alittle"] = "a little",
	["thankyou"] = "thank you", ["iam"] = "I am", ["idont"] = "I don't", ["ima"] = "I'm going to",
	["imma"] = "I'm going to", ["hafta"] = "have to", ["tryna"] = "trying to",
	["whatsup"] = "what's up", ["wassup"] = "what's up", ["sup"] = "what's up",
	-- chat shorthand
	["i"] = "I", ["u"] = "you", ["ur"] = "your", ["r"] = "are",
	["thx"] = "thanks", ["thnx"] = "thanks", ["thanx"] = "thanks", ["tnx"] = "thanks",
	["ty"] = "thank you", ["tyvm"] = "thank you very much",
	["pls"] = "please", ["plz"] = "please", ["sry"] = "sorry", ["srry"] = "sorry",
	["ppl"] = "people", ["rly"] = "really", ["prolly"] = "probably", ["probly"] = "probably",
	["idk"] = "I don't know", ["ofc"] = "of course", ["nvm"] = "never mind", ["np"] = "no problem",
	["yw"] = "you're welcome", ["omw"] = "on my way", ["cya"] = "see you",
	["bc"] = "because", ["bcuz"] = "because", ["coz"] = "because", ["cos"] = "because",
	["em"] = "them", ["bout"] = "about", ["til"] = "until", ["till"] = "until",
	["nite"] = "night", ["tonite"] = "tonight",
	-- curse words spelled to get round a filter. They are turned into the
	-- plain word here, and into troll by L.swears.
	["fuk"] = "fuck", ["fuc"] = "fuck", ["fck"] = "fuck", ["fk"] = "fuck", ["phuck"] = "fuck", ["fuq"] = "fuck",
	["fuking"] = "fucking", ["fukin"] = "fucking", ["fucken"] = "fucking", ["fking"] = "fucking",
	["fkn"] = "fucking", ["fkin"] = "fucking", ["fcking"] = "fucking", ["fckin"] = "fucking",
	["fuckn"] = "fucking", ["fkng"] = "fucking",
	["fuked"] = "fucked", ["fcked"] = "fucked", ["fuker"] = "fucker", ["fcker"] = "fucker",
	["mofo"] = "motherfucker", ["mfer"] = "motherfucker",
	["sht"] = "shit", ["shyt"] = "shit", ["shiet"] = "shit", ["shiit"] = "shit",
	["shity"] = "shitty", ["bullsht"] = "bullshit",
	["biatch"] = "bitch", ["btch"] = "bitch", ["bich"] = "bitch", ["bytch"] = "bitch", ["beotch"] = "bitch",
	["azz"] = "ass", ["azzhole"] = "asshole", ["ahole"] = "asshole",
	["damm"] = "damn", ["goddam"] = "goddamn",
}

-- Curse words with letters swapped for symbols: f**k, sh1t, a$$. Each entry
-- is a Lua pattern and the word it stands for. Only looked at while "Troll
-- words" is on, so that the word is always turned into troll afterwards.
L.disguised = {
	{ "%f[%a][Ff]%*+[Cc]?[Kk]", "fuck" },            -- f*ck  f**k
	{ "%f[%a][Ff][Uu]%*+[Kk]?", "fuck" },            -- fu*k  fu**
	{ "%f[%a][Ff]%*%*%*+", "fuck" },                 -- f***
	{ "%f[%a][Ff]@[Cc][Kk]", "fuck" },               -- f@ck
	{ "%f[%a][Ss][Hh]%*+[Tt]?", "shit" },            -- sh*t  sh**
	{ "%f[%a][Ss]%*+[Ii]?[Tt]", "shit" },            -- s**t  s*it
	{ "%f[%a][Ss][Hh]1[Tt]", "shit" },               -- sh1t
	{ "%f[%S]%$[Hh][Ii][Tt]", "shit" },              -- $hit
	{ "%f[%a][Bb]%*+[Tt]?[Cc][Hh]", "bitch" },       -- b*tch  b**ch
	{ "%f[%a][Bb][Ii]%*+[Cc]?[Hh]", "bitch" },       -- bi*ch  bi**h
	{ "%f[%a][Bb]1[Tt][Cc][Hh]", "bitch" },          -- b1tch
	{ "%f[%a][Aa]%*+[Hh][Oo][Ll][Ee]", "asshole" },  -- a**hole
	{ "%f[%S][Aa]%*%*%f[^%*%a]", "ass" },            -- a**
	{ "%f[%a][Aa]%$%$", "ass" },                     -- a$$
	{ "%f[%S]@[Ss][Ss]", "ass" },                    -- @ss
	{ "%f[%a][Dd]%*+[Mm][Nn]", "damn" },             -- d*mn
	{ "%f[%a][Dd][Aa]%*+[Nn]", "damn" },             -- da*n
	{ "%f[%a][Cc][Rr]%*+[Pp]", "crap" },             -- cr*p
}


-- Words the typo guesser must never touch: names, places, game talk, Zandali,
-- Orcish, troll spellings and noises. A word only needs to be here if it is
-- not in an ordinary dictionary. Add your own freely.
L.jargon = [[
	orc orcs tauren troll trolls undead forsaken goblin goblins gnome gnomes dwarf elf
	draenei worgen pandaren ogre ogres murloc murlocs gnoll gnolls kobold kobolds
	quilboar quilboars centaur centaurs harpy harpies naga satyr satyrs furbolg furbolgs
	tuskarr wyvern wyverns kodo kodos raptor raptors gryphon gryphons hippogryph
	zeppelin zeppelins
	totem totems hearthstone hearth mana mojo voodoo juju hex hexed hexes

	azeroth kalimdor draenor outland lordaeron orgrimmar durotar barrens mulgore
	tirisfal undercity stormwind ironforge darnassus ashenvale stranglethorn tanaris
	feralas desolace azshara felwood winterspring silithus ungoro senjin gadgetzan
	everlook ratchet alterac arathi warsong khaz modan thrall grom hellscream
	saurfang garrosh nazgrel rexxar cairne voljin sylvanas onyxia ragnaros nefarian

	loa bwonsamdi hakkar zandalar zandalari gurubashi amani darkspear zuljin zulaman
	gurub jintha jinthaalor shadra jeklik marli arlokk thekal venoxis mandokir jindo
	zanzil hethiss gahzranka hexxer zalazane rokhan vanira zentabra senjin zul

	lok tar ogar zug dabu swobu throm mok gol kosh kagh aka magosh nogah regas
	grombolar zugzug loktar

	aggro mob mobs buff buffs debuff debuffs nerf nerfed proc procs crit crits spec
	respec mats ench alch herb herbs dps hps rez rezz rezzed ress lvl lvls exp rep
	inv grp pug pugs pvp pve afk brb lfg lfm wts wtb wtt pst grats gratz noob noobs
	newb twink twinks gank ganked ganking ganker gankers epics epix purps addon
	addons macro macros keybind keybinds hotkey cooldown cooldowns aoe dot dots hots
	kite kiting kited strat strats scholo mara gnomer naxx ubrs lbrs strath
	deadmines uldaman zulfarrak warstomp bloodlust windfury frostbolt berserking

	mon ya da dis dat dese dose dem dey dere den dan wit widout widin tink tinkin
	ting tings nuttin someting anyting everyting udda uddas anudda brudda bruddas
	mudda fadda togedda yaself yaselves meself deirs lil troo trow wassup bot
	berserka preacha backstabba spell slinga flinga dabbla walka hugga tama stabby
	throwy

	haha hahaha hehe hehehe heh hah har lol lolz rofl lmao kek hmm ugh argh aargh
	grr rawr bah pfft psst shh ooh aah ahh ohh uhh umm ehh mhm yeah yep yup nope
	nah yay yea okay ok alright aight gonna wanna gotta kinda sorta dunno lemme
	gimme coulda shoulda woulda outta lotsa cmon mmhmm
]]

---------------------------------------------------------------------------
-- Troll flourishes
--
-- With "Troll flourishes" switched on, about one message in three gets one
-- of these. Openers go in front of the message. Closers go just before the
-- message's last . ! or ? (or at the very end if it has none), so
-- "We need more juju." becomes "We need more juju, mon."
---------------------------------------------------------------------------

L.flourishes = {
	-- in front of any message
	openers = { "Hey, mon!", "Listen up, mon.", "Ah, mon.", "Eh, mon.", "Oh ho!", "Ya see..." },
	-- at the end of a plain statement
	statements = { ", mon", ", ya know", ", ya hear", ", I tell ya", ", an' dat be dat", ", ya mon" },
	-- at the end of a question
	questions = { ", mon", ", eh", ", ya hear", ", eh, mon" },
	-- at the end of something shouted with !
	shouts = { ", mon", "! Ya, mon", "! Stay away from da voodoo", "! Spirits be wit' us" },
}

---------------------------------------------------------------------------
-- Questie
--
-- If you use the Questie addon and have it announce quest progress to your
-- party, Juju says those announcements the troll way. Each entry is Questie's
-- English wording (as a Lua pattern) and what to say instead: %1, %2 and %3
-- stand for the pieces in brackets, such as the quest link or the count. The
-- first entry that fits is used. Whatever comes out then gets the usual
-- accent, except that capitalised words (names of creatures, items and
-- places) are left exactly as the game wrote them.
---------------------------------------------------------------------------

L.questie = {
	{ "^Quest Accepted: (.+)$", "New job, mon: %1" },
	{ "^Quest Completed: (.+)$", "Dis job be done: %1" },
	{ "^Quest Abandoned: (.+)$", "Forget dis job: %1" },
	{ "^Picked up (.+) which starts (.+)!$", "Found %1, it start %2!" },
	-- "Kobold Vermin slain: 10/10 for [Quest]!"
	{ "^(.-): (%d+/%d+) for (.+)!$", "Dat be %2 %1 for %3!" },
	-- any other finished objective
	{ "^(.+) for (.+)!$", "%1 for %2!" },
}

---------------------------------------------------------------------------
-- Troll voices
--
-- Each character can be a different kind of troll. A voice has its own
-- flourishes (used while "Troll flourishes" is on; any list a voice leaves
-- out comes from L.flourishes), how often they come (chance, out of 100),
-- and a few words of its own (used while "Troll words" is on, ahead of
-- everything else). alwaysMon puts "mon" on every yell, not just the ones
-- ending in "!".
---------------------------------------------------------------------------

L.voices = {
	darkspear = {
		name = "Darkspear",
		about = "A laid-back Darkspear troll from da Echo Isles: da usual flourishes, mon.",
	},

	sistah = {
		name = "Sistah",
		about = "A Darkspear sistah: sharp tongue, sharper glaive. She ain't got time for fools, mon.",
		chance = 40,
		flourishes = {
			openers = { "Listen 'ere, sugar.", "Oh, honey...", "Mmhmm.", "Don't make me come over dere!", "Ah-ah-ah." },
			statements = { ", sugar", ", mon", ", an' dat be dat", ", don't be testin' me", ", ya hear" },
			questions = { ", sugar", ", mon", ", or do I gotta do it meself", ", hmm" },
			shouts = { "! Outta me way", ", ya big lump", "! Mind ya tusks", "! Spirits take ya" },
		},
		words = {
			["sister"] = "sistah", ["sisters"] = "sistahs", ["girl"] = "gal", ["girls"] = "gals",
			["dear"] = "sugar", ["honey"] = "sugar", ["sweetie"] = "sugar", ["sweetheart"] = "sugar",
		},
	},

	witchdoctor = {
		name = "Witch Doctor",
		about = "A witch doctor: hexes, brews an' bones. Stay away from da voodoo, mon.",
		chance = 40,
		flourishes = {
			openers = { "Da spirits be sayin'...", "Hmm, da bones tell me...", "Heh heh heh.", "Come closer, mon.", "Ah, da voodoo be strong today." },
			statements = { ", da spirits say so", ", stay away from da voodoo", ", heh heh", ", or I hex ya", ", mon" },
			questions = { ", ya want a hex", ", or should I ask da bones", ", mon", ", eh" },
			shouts = { "! Da voodoo be strong", ", heh heh heh", "! Hex 'em", "! Bwonsamdi be watchin'" },
		},
		words = {
			["potion"] = "brew", ["potions"] = "brews", ["poison"] = "nasty brew", ["poisons"] = "nasty brews",
			["spell"] = "juju", ["spells"] = "juju", ["doll"] = "voodoo doll", ["dolls"] = "voodoo dolls",
			["heal"] = "patch", ["healed"] = "patched", ["healing"] = "patchin'", ["heals"] = "patchin'",
		},
	},

	headhunter = {
		name = "Headhunter",
		about = "A Headhunter: loves a good hunt an' a better trophy. Every yell ends wit' mon!",
		chance = 45,
		alwaysMon = true,
		flourishes = {
			openers = { "Time ta hunt!", "Heh, fresh meat.", "Ya hear dat?", "Me spear be hungry.", "Who be first?" },
			statements = { ", an' I be takin' dey head", ", fresh meat", ", heh", ", for da trophy wall", ", mon" },
			questions = { ", who be next", ", ya want ta lose ya head", ", mon", ", eh" },
			shouts = { "! Heads for da wall", "! Kill 'em all", ", fresh meat", "! Nobody escape" },
		},
		words = {
			["enemy"] = "prey", ["enemies"] = "prey", ["foe"] = "prey", ["foes"] = "prey",
			["target"] = "prey", ["attack"] = "hunt", ["attacking"] = "huntin'", ["attacked"] = "hunted",
			["trophy"] = "head", ["trophies"] = "heads",
		},
	},

	shadowhunter = {
		name = "Shadow Hunter",
		about = "A shadow hunter: calm, quiet an' close ta da Loa. Talks in riddles, mon.",
		chance = 40,
		flourishes = {
			openers = { "Da shadows be speakin'.", "Patience.", "Da Loa be watchin'.", "Hmm.", "Walk careful now." },
			statements = { ", so say da Loa", ", in time", ", da shadows know", ", be patient", ", mon" },
			questions = { ", or do da shadows lie", ", ya feel it too", ", mon", ", hmm" },
			shouts = { "! Da Loa be wit' us", "! Strike from da shadows", ", for da Darkspear", "! Spirits guide me spear" },
		},
		words = {
			["luck"] = "fate", ["lucky"] = "blessed", ["unlucky"] = "cursed by fate",
			["pray"] = "ask da Loa", ["prayer"] = "blessin'", ["prayers"] = "blessin's",
		},
	},

	zandalari = {
		name = "Zandalari",
		about = "A Zandalari: old, proud an' very sure da Zandalari be da first an' finest trolls.",
		chance = 40,
		flourishes = {
			openers = { "Hear me.", "Know dis:", "As it was in Zandalar...", "Kneel.", "Lesser trolls..." },
			statements = { ", as it was in da old days", ", dis be known", ", lesser troll", ", by da will of da Loa", ", as da Zandalari decree" },
			questions = { ", lesser troll", ", or do ya question da Zandalari", ", hmm", ", young one" },
			shouts = { "! For Zandalar", "! Da empire rise again", ", by da Loa", "! Kneel before da Zandalari" },
		},
		words = {
			["man"] = "young one", ["dude"] = "young one", ["bro"] = "young one", ["buddy"] = "young one",
			["friend"] = "ally", ["friends"] = "allies", ["hi"] = "greetin's", ["hey"] = "greetin's",
			["hello"] = "greetin's", ["bye"] = "farewell", ["yeah"] = "indeed", ["yes"] = "indeed",
		},
	},
}

-- The order voices are listed and cycled through.
L.voiceOrder = { "darkspear", "sistah", "witchdoctor", "headhunter", "shadowhunter", "zandalari" }

---------------------------------------------------------------------------
-- Troll emotes
--
-- Each one becomes a slash command: /voodoo, /mon and so on. text is used
-- with no target, target when you have one (or name one: /mon Zanjin).
-- {target} is the target's name. {his}, {him} and {he} become her, her and
-- she for a female character. A voice can have its own lines, either one
-- line for both or { text = ..., target = ... }.
-- If the game or another addon already uses one of these commands, Juju
-- leaves it alone; /juju emote <name> always works.
---------------------------------------------------------------------------

L.emotes = {
	voodoo = {
		text = 'wiggles {his} fingers mysteriously. "Stay away from da voodoo, mon."',
		target = 'wiggles {his} fingers at {target}. "Ya best stay away from da voodoo, mon."',
		voices = {
			witchdoctor = { text = 'rattles a string of tiny skulls. "Da voodoo be strong today. Heh heh heh."',
				target = 'holds up a little doll that looks a lot like {target}. "Heh heh heh."' },
			zandalari = 'raises a jeweled hand. "Lesser trolls play wit\' voodoo. Da Zandalari BE da voodoo."',
		},
	},
	mon = {
		text = 'leans back, all easy-like. "Ya, mon."',
		target = 'nods slowly at {target}. "Ya, mon. We be cool."',
		voices = {
			sistah = { target = 'looks {target} up and down. "Mmhmm. Ya, mon."' },
			zandalari = { text = 'sighs deeply. "Must every troll say mon?"' },
		},
	},
	hex = {
		text = 'traces a crooked sign in the air and mutters a hex.',
		target = 'points a long finger at {target} and mutters a nasty little hex. "Ribbit, mon."',
		voices = {
			witchdoctor = { target = 'blows a pinch of strange dust at {target}. "Ya feel dat? Dat be da hex, mon."' },
		},
	},
	bones = {
		text = 'casts a handful of bones on the ground and studies them closely. "Hmm."',
		target = 'casts a handful of bones at {target}\'s feet. "Da bones say ya be in trouble, mon."',
		voices = {
			shadowhunter = { text = 'casts the bones and nods slowly. "As da Loa will it."' },
		},
	},
	mojo = {
		text = 'rolls {his} shoulders and feels the mojo flowing.',
		target = 'sends a little mojo {target}\'s way. "Dere ya go, mon. Good mojo."',
	},
	tusks = {
		text = 'polishes {his} tusks with great care.',
		target = 'bares {his} tusks at {target} in a wide grin.',
		voices = {
			headhunter = { target = 'taps a tusk and eyes {target}\'s head. "Dat would look good on me wall."' },
		},
	},
	loa = {
		text = 'raises {his} arms to the sky. "Da Loa be wit\' us!"',
		target = 'asks the Loa to watch over {target}. "Spirits be wit\' ya, mon."',
	},
	bwonsamdi = {
		text = 'shivers. "Bwonsamdi be callin\' for somebody... not me, mon."',
		target = 'grins at {target}. "Bwonsamdi be waitin\' for ya, mon."',
	},
	chill = {
		text = 'kicks back and takes it easy. "No worries, mon."',
		target = 'claps {target} on the shoulder. "Relax, mon. No worries."',
		voices = {
			headhunter = { text = 'sits down to sharpen {his} spear. "Relax? Me? Heh."' },
		},
	},
}

-- The order they are listed in.
L.emoteOrder = { "voodoo", "mon", "hex", "bones", "mojo", "tusks", "loa", "bwonsamdi", "chill" }
