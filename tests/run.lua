-- Juju tests. Run from anywhere with a plain Lua 5.1:
--
--     lua5.1 tests/run.lua
--
-- Part one checks the translator by itself. Part two loads the whole addon
-- into a stand-in game client (tests/mock.lua) and sends chat through it.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\][^/\\]+$") or "."
package.path = root .. "/tests/?.lua;" .. package.path

local Mock = require("mock")

local passed, failed = 0, 0

-- The Juju box writes each translated word as a clickable link. This gives
-- back the text as it reads on screen.
local function unlinked(text)
	return (string.gsub(text or "", "|Haddon:Juju:%d+|h(.-)|h", "%1"))
end

local function check(name, got, want)
	if got == want then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL  " .. name)
		print("      want: " .. tostring(want))
		print("      got:  " .. tostring(got))
	end
end

---------------------------------------------------------------------------
-- Part one: the translator
---------------------------------------------------------------------------

local ns = {}
for _, file in ipairs({ "Lexicon.lua", "Words.lua", "Spell.lua", "Translator.lua" }) do
	assert(loadfile(root .. "/" .. file))("Juju", ns)
end
local Translate = ns.Translator.Translate
local Correct = ns.Spell.Correct

local TROLL = { vocab = true }
local ACCENT = {}
local YELL = { vocab = true, mon = true }
local EMOTE = { vocab = true, quotesOnly = true }
local NAMES = { vocab = true, names = true }
local GUESS = { vocab = true, guess = true }

local cases = {
	-- { what it shows, English, troll, options }
	{ "greeting", "Hey man, the murlocs are coming through the water!", "Hey mon, da murlocs be comin' troo da wata!" },
	{ "be for is and are", "The trolls are here and the shaman is ready.", "Da trolls be here an' da spirit-walka be ready." },
	{ "th becomes t", "I think three things are worth it.", "I tink tree tings be wort' it." },
	{ "th at the end", "Both of them went north with the truth.", "Bot' of dem went nort' wit' da trut'." },
	{ "pointing words", "This is the place, those are the ones.", "Dis be da place, dose be da ones." },
	{ "they and them", "They said their friends would help them.", "Dey said dey friends would help dem." },
	{ "with and without", "Come with me, not without your spear.", "Come wit' me, not widout ya spear." },
	{ "-ther words", "This weather is terrible, I would rather be fighting.", "Dis wedda be terrible, I would radda be fightin'." },
	{ "bother", "Stop bothering me, brother.", "Stop bodderin' me, brudda." },
	{ "family", "My mother and father are together again.", "Me mudda an' fadda be togedda again." },
	{ "-er becomes -a", "The player never gives up, he is better than ever.", "Da playa neva gives up, he be betta dan eva." },
	{ "-ing", "We are fighting and winning, nothing can stop us.", "We be fightin' an' winnin', nuttin' can stop us." },
	{ "some, any, every", "Something is wrong, anything could happen, everything is quiet.", "Someting be wrong, anyting could happen, everyting be quiet." },
	{ "you and your", "You have your orders, do it yourself.", "Ya have ya ordas, do it yaself." },
	{ "my and me", "My spear is mine, I did it myself.", "Me spear be mine, I did it meself." },
	{ "it's and that's", "It's here and that's that.", "It be here an' dat be dat." },
	{ "what's and where's", "What's going on? Where's the boss?", "Wha' be goin' on? Where be da boss?" },
	{ "you're and they're", "You're late and they're angry.", "Ya be late an' dey be vexed." },
	{ "I'm", "I'm ready.", "I be ready." },
	{ "'s for has", "He's got the gold and it's been a long day.", "He got da gold an' it been a long day." },
	{ "possessive stays", "The troll's tusks and Thrall's axe.", "Da troll's tusks an' Thrall's axe." },
	{ "you'll", "You'll see, they'll come, we'll win.", "Ya gonna see, dey'll come, we'll win." },
	{ "going to do something", "I am going to win.", "I be gonna win." },
	{ "going to somewhere", "I am going to the inn, then going to Orgrimmar.", "I be goin' ta da inn, den goin' ta Orgrimmar." },
	{ "got to", "We got to the top, you got to see this.", "We got ta da top, ya gotta see dis." },
	{ "plural of a listed word", "Nothing can stop us now, brothers!", "Nuttin' can stop us now, bruddas!" },
	{ "verbs ending in s", "He thinks he is better than everyone else.", "He tinks he be betta dan everyone else." },
	{ "thanks", "Thanks for everything, see you later.", "Tanks for everyting, lata, mon." },
	{ "man becomes mon", "Hey man, what's up?", "Hey mon, wassup?" },
	{ "little", "a little help, just a little", "a lil' help, jus' a lil'" },
	{ "to becomes ta", "We want to go to the island.", "We wanna go ta da island." },
	{ "how are you", "How are you, man?", "How ya doin', mon?" },
	{ "you guys", "You guys are the best.", "All o' ya be da best." },
	{ "chat shorthand is left alone", "ok brb 5 min, wtb [Linen Cloth] x20 pst", "ok brb 5 min, wtb [Linen Cloth] x20 pst" },
	{ "da Loa", "By the gods, that was amazing!", "By da Loa, dat was mighty fine!" },
	{ "juju and mojo", "This magic needs luck.", "Dis juju needs mojo." },
	{ "hex", "The curse is strong, we are cursed.", "Da hex be strong, we be hexed." },
	{ "tribe", "Join our guild, the best clan around.", "Join our tribe, da best tribe 'round." },
	{ "witch doctor", "We need a healer, find a doctor.", "We need a witch doctor, find a witch doctor." },
	{ "no witch witch doctor", "the witch doctor and the witch doctors", "da witch doctor an' da witch doctors" },
	{ "vexed", "The chief is angry and annoyed.", "Da chief be vexed an' vexed." },
	{ "grog", "Any beer or ale around here?", "Any grog or grog 'round here?" },
	{ "fool", "Shut up, you stupid idiot.", "Shut ya mout', ya stupid fool." },
	{ "coward", "Run, you coward!", "Run, ya scaredy-raptor!" },
	{ "foes", "Our enemies are many.", "Our foes be many." },
	{ "king, bring and string keep their g", "bring the king a string", "bring da king a string" },
	{ "beer and deer keep their r", "the deer drinks", "da deer drinks" },
	{ "boss, class and focus keep their s", "the boss has class and focus", "da boss has class an' focus" },
	{ "this, his and its", "this is his and its", "dis be his an' its" },
	{ "ethereal is not edder", "the ethereal glow", "da etereal glow" },
	{ "Orcish is left alone", "Lok'tar ogar! Throm-Ka, Grokk. Zug zug.", "Lok'tar ogar! Throm-Ka, Grokk. Zug zug." },
	{ "Zandali names are left alone", "Zul'jin and Vol'jin at Zul'Gurub.", "Zul'jin an' Vol'jin at Zul'Gurub." },
	{ "words that are not English letters", "über cool the thing", "über cool da ting" },
	{ "No, as an answer", "No, I won't do it.", "Nah, I won't do it." },
	{ "No!", "No!", "Nah!" },
	{ "no way", "No way that is true", "No way dat be true" },
	{ "no gold", "There is no gold here", "Dere be no gold here" },
	{ "shouting", "KILL THEM ALL! NO MERCY!", "KILL DEM ALL! NO MERCY!" },
	{ "shouting be", "THE TROLLS ARE HERE!", "DA TROLLS BE HERE!" },
	{ "capital at the start", "The boss is here", "Da boss be here" },
	{ "I AM", "I AM THE BOSS", "I BE DA BOSS" },
	{ "I'm in the middle", "Yes, I'm here", "Ya, I be here" },
	{ "name in mid-sentence is kept", "Tell Thrall the hunters are here", "Tell Thrall da beast-tamas be here" },
	{ "name before a comma is kept", "Zanjin, throw the spear!", "Zanjin, trow da spear!" },
	{ "place name is kept", "Looking for more fighters to raid the Barrens.", "Lookin' for more fightas ta raid da Barrens." },
	{ "name's stays name's", "That is Thrall's axe", "Dat be Thrall's axe" },
	{ "listed words ignore capitals", "Tell Brother Thrall the news", "Tell Brudda Thrall da news" },
	{ "names option mangles them", "Tell Thrall the hunters are here", "Tell Trall da beast-tamas be here", NAMES },
	{ "known names are always kept", "Thrall is here", "Thrall be here", { vocab = true, names = true, isName = function(word) return word == "thrall" end } },
	{ "item link", "the best sword is |cffff8000|Hitem:19019::::::::60:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r for the fight", "da best sword be |cffff8000|Hitem:19019::::::::60:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r for da fight" },
	{ "bare link", "see |Hplayer:Thrall|h[Thrall]|h there", "see |Hplayer:Thrall|h[Thrall]|h dere" },
	{ "raid markers", "{skull} Kill the skull first then {cross}", "{skull} Kill da skull first den {cross}" },
	{ "out of character", "((brb, phone)) Where were we?", "((brb, phone)) Where was we?" },
	{ "out of character, never closed", "the door ((sorry, the dog needs out", "da door ((sorry, the dog needs out" },
	{ "actions", "*scratches his head* What do you mean?", "*scratches his head* Wha' do ya mean?" },
	{ "web address", "Visit https://example.com/the/thing for the rules", "Visit https://example.com/the/thing for da rules" },
	{ "OOC: prefix", "OOC: sorry guys I have to leave", "OOC: sorry guys I have to leave" },
	{ "addon command", "!keys", "!keys" },
	{ "slash command", "/dance with the humans", "/dance with the humans" },
	{ "plain prefix is removed", "! this goes out plain", "this goes out plain" },
	{ "empty", "", "" },
	{ "only spaces", "   ", "   " },
	{ "troll stays troll", "Ya mon, dat be da ting, me brudda tink so.", "Ya mon, dat be da ting, me brudda tink so." },
	{ "troll stays troll (2)", "Dem bodda us widout reason, nuttin' togedda.", "Dem bodda us widout reason, nuttin' togedda." },
	{ "accent without troll words", "I am going to use magic on that human and take his gold.", "I be gonna use magic on dat human an' take his gold.", ACCENT },
	{ "accent keeps fools", "you guys are idiots", "all o' ya be idiots", ACCENT },
	{ "mon on a yell", "For the Horde!", "For da Horde, mon!", YELL },
	{ "no mon on a question", "Has anyone seen my wolf?", "Has anyone seen me wolf?", YELL },
	{ "no mon on a plain yell", "Get them", "Get dem", YELL },
	{ "only one mon", "Ya mon! Get them!", "Ya mon! Get dem!", YELL },
	{ "shouted mon", "RUN!", "RUN, MON!", YELL },
	{ "mon before the last marks", "Run! Run!!", "Run! Run, mon!!", YELL },
	{ "no mon after OOC", "Charge! ((brb))", "Charge! ((brb))", YELL },
	{ "emote translates only the quote", "scratches his head and grunts, \"What do you want, man?\" before turning away.", "scratches his head and grunts, \"Wha' do ya want, mon?\" before turning away.", EMOTE },
	{ "emote without a quote", "waves at the trolls.", "waves at the trolls.", EMOTE },
	{ "emote with an unclosed quote", "growls, \"Get out of here", "growls, \"Get outta here", EMOTE },
	{ "im", "Im going to kill them", "I be gonna kill dem" },
	{ "dont", "dont touch that", "don't touch dat" },
	{ "doesnt and wasnt", "doesnt matter, it wasnt me", "don't matta, it wasn't me" },
	{ "hasnt and havent", "i havent seen him and he hasnt seen me", "I ain't seen him an' he ain't seen me" },
	{ "youre, ive", "youre a fool and ive had enough", "ya be a fool an' I've had enough" },
	{ "thats, whats, wheres", "thats it. whats that? wheres the boss?", "dat be it. wha' be dat? where be da boss?" },
	{ "theyre, cant", "theyre coming, we cant stay", "dey be comin', we can't stay" },
	{ "hes, shes", "hes here and shes there", "he be here an' she be dere" },
	{ "shouting without apostrophes", "DONT TOUCH THAT", "DON'T TOUCH DAT" },
	{ "capital without apostrophes", "Dont touch that. Im warning you.", "Don't touch dat. I be warnin' ya." },
	{ "semicolon instead of apostrophe", "don;t touch that, it;s mine, i;ll kill you", "don't touch dat, it be mine, I'll kill ya" },
	{ "apostrophe in the wrong place", "is'nt that the same? i ca'nt tell", "ain't dat da same? I can't tell" },
	{ "real words are left alone", "its a trap, well ill go", "its a trap, well ill go" },
	{ "teh, adn, yuo", "teh boss adn yuo", "da boss an' ya" },
	{ "waht, thier, becuase", "waht is thier plan? becuase i said so", "wha' be dey plan? 'cause I said so" },
	{ "alot, idk", "alot of gold, idk how much", "lotsa gold, I dunno how much" },
	{ "u r", "u r a coward", "ya be a scaredy-raptor" },
	{ "thx, cya, tommorow", "thx for the help, cya tommorow", "tanks for da help, see ya tomorrow" },
	{ "a lone i", "i think so", "I tink so" },
	{ "trol", "the trol is here", "da troll be here" },
	{ "guess: swapped letters", "dont wory abuot it", "don't worry 'bout it", GUESS },
	{ "guess: plural with a typo", "we need more fihgters", "we need more fightas", GUESS },
	{ "guess: troll word after a typo", "the magci is strong", "da juju be strong", GUESS },
	{ "guess: missing letter", "the allaince is coming", "da alliance be comin'", GUESS },
	{ "guess: off by default", "dont wory abuot it", "don't wory abuot it" },
	{ "guess: real words never change", "the form of the cost", "da form of da cost", GUESS },
	{ "guess: capitalised words are names", "ask Bert about it", "ask Bert 'bout it", GUESS },
	{ "guess: lowercase names are known", "ask bert and rita", "ask bert an' rita", GUESS },
	{ "guess: game words are known", "lfm ubrs, need dps and heals", "lfm ubrs, need dps an' mendin'", GUESS },
	{ "guess: troll stays troll", "dem tings be widout reason, nuttin togedda", "dem tings be widout reason, nuttin togedda", GUESS },
	{ "guess: more troll stays troll", "me brudda tink da wedda be bodda", "me brudda tink da wedda be bodda", GUESS },
	{ "guess: noises stay", "nooo hahaha grrr heeey", "nooo hahaha grrr heeey", GUESS },
	{ "guess: abbreviations stay", "LFG ZG, need DPS", "LFG ZG, need DPS", GUESS },
	{ "lore names keep their spelling", "grom and thrall and voljin", "grom an' thrall an' voljin" },
	{ "roles: tank and priest", "need a tank and a priest", "need a meat shield an' a preacha" },
	{ "roles: heals", "LF2M tank and heals for the Deadmines", "LF2M meat shield an' mendin' for da Deadmines" },
	{ "roles: mage and warlock", "our mage and warlock are AFK", "our juju-flinga an' fel-dabbla be AFK" },
	{ "roles: plurals", "two rogues and three hunters", "two backstabbas an' tree beast-tamas" },
	{ "roles: paladins", "the paladins and the pally", "da bubble-knights an' da bubble-knight" },
	{ "roles: druid and shaman", "a druid and a shaman", "a bear-hugga an' a spirit-walka" },
	{ "roles: warriors", "warriors, charge!", "berserkas, charge!" },
	{ "roles: melee and ranged", "melee stack, ranged spread", "stabby stack, throwy spread" },
	{ "roles: capitalised", "LF Tank", "LF Meat shield" },
	{ "roles: tanking", "I am tanking, you heal", "I be holdin' da line, ya mend" },
	{ "roles: need troll words on", "need a tank and a priest", "need a tank an' a priest", ACCENT },
	{ "roles: plural typos are not corrected", "the paladins and warlocks", "da bubble-knights an' fel-dabblas", GUESS },
	{ "swear: exclamation", "Shit, they are coming!", "Raptor dung, dey be comin'!" },
	{ "swear: insult", "Fuck off, you stupid bitch", "Go see Bwonsamdi, ya stupid hyena" },
	{ "swear: what the", "What the fuck is that?", "Wha' da hex be dat?" },
	{ "swear: no doubled hexed", "You fucking asshole", "Ya hexed fool" },
	{ "swear: shouted", "FUCK YOU", "HEX YA" },
	{ "swear: holy", "Holy shit, look at that", "Loa preserve us, look at dat" },
	{ "swear: give a", "I don't give a shit", "I don't give a hex" },
	{ "swear: son of a", "Son of a bitch!", "Son of a hyena!" },
	{ "swear: longest phrase wins", "shut the fuck up", "shut ya hexed mout'" },
	{ "swear: past tense", "damn it, we are fucked", "hex it, we be hexed" },
	{ "swear: ass", "kiss my ass", "kiss me backside" },
	{ "swear: the hell", "get the hell out of here", "get da hex outta here" },
	{ "swear: oaths", "Jesus Christ, what a mess", "Spirits above, wha' a mess" },
	{ "swear: plural", "those bastards and bitches", "dose fools an' hyenas" },
	{ "swear: shorthand", "wtf was that", "wha' da hex was dat" },
	{ "swear: shouted shorthand", "WTF", "WHA' DA HEX" },
	{ "swear: spelled round a filter", "fk this, fking humans", "hex dis, hexed humans" },
	{ "swear: stars", "f**k you", "hex ya" },
	{ "swear: stars while shouting", "F***ING HELL", "HEXED HELL" },
	{ "swear: stars with a capital", "F*** this", "Hex dis" },
	{ "swear: more stars", "sh*t, kick his a**", "raptor dung, kick his backside" },
	{ "swear: a digit for a letter", "b1tch please", "hyena please" },
	{ "swear: stars next to an action", "a *big* axe and *waves* sh*t", "a *big* axe an' *waves* raptor dung" },
	{ "swear: never ruder than typed", "*f* waves* a** *grins*", "*f* waves* a** *grins*" },
	{ "swear: innocent words", "class and pass and assassin, the dam broke", "class an' pass an' assassin, da dam broke" },
	{ "swear: pissed off", "I am pissed off", "I be vexed" },
	{ "swear: left alone with troll words off", "f**k this shit, wtf", "f**k dis shit, wtf", ACCENT },
	{ "swear: your own word wins", "this is shit", "dis be muck", { vocab = true, words = ns.Translator.PrepareWords({ shit = "muck" }) } },
}

for _, case in ipairs(cases) do
	check(case[1], Translate(case[2], case[4] or TROLL), case[3])
end

-- Saying a troll sentence again must not change it (the game puts what was
-- sent, not what was typed, into the chat box history).
for _, case in ipairs(cases) do
	local options = case[4] or TROLL
	if not options.mon and case[2]:sub(1, 1) ~= "!" then
		local once = Translate(case[2], options)
		check("stable: " .. case[1], Translate(once, options), once)
	end
end

-- The player's own words, at translator level.
do
	local words = ns.Translator.PrepareWords({
		gold = "shinies", bert = false, warchief = "big chief", going = "goin'",
		["for the horde"] = "for da Horde, mon", ["zug zug"] = false,
		wory = "frettin'",
	})
	local OWN = { vocab = true, guess = true, words = words }
	check("own: word", Translate("give me the gold", OWN), "gimme da shinies")
	check("own: capital", Translate("Gold is nice", OWN), "Shinies be nice")
	check("own: shouted", Translate("GOLD!", OWN), "SHINIES!")
	check("own: beats the word lists", Translate("the warchief", OWN), "da big chief")
	check("own: kept as typed", Translate("ask bert", OWN), "ask bert")
	check("own: kept even with capitals and names on",
		Translate("Ask Bert", { vocab = true, names = true, words = words }), "Ask Bert")
	check("own: phrase", Translate("For the Horde!", OWN), "For da Horde, mon!")
	check("own: phrase kept as typed", Translate("zug zug, boss", OWN), "zug zug, boss")
	check("own: built-in phrases leave it alone", Translate("we are going to win", OWN), "we be goin' ta win")
	check("own: beats typo fixing", Translate("dont wory", OWN), "don't frettin'")
	check("own: no words, no change", Translate("the magic", { vocab = true, words = ns.Translator.PrepareWords({}) }), "da juju")
	check("own: bad entries ignored", next(ns.Translator.PrepareWords({ [""] = "x", gold = 5 }).single), nil)
end

-- Troll flourishes, at translator level. A roll decides: roll % 100 below 35
-- means a flourish; floor(roll / 100) % 3 == 0 picks an opener, otherwise a
-- closer; floor(roll / 300) picks which one.
do
	local function F(text, roll, extra)
		local opts = { vocab = true, flourish = true, roll = roll }
		for key, value in pairs(extra or {}) do
			opts[key] = value
		end
		return Translate(text, opts)
	end
	check("flourish: opener", F("We need more magic.", 0), "Hey, mon! We need more juju.")
	check("flourish: statement closer", F("We need more magic.", 100), "We need more juju, mon.")
	check("flourish: closer without punctuation", F("hello friends", 100), "hello friends, mon")
	check("flourish: question closer", F("Where is the healer?", 100), "Where be da witch doctor, mon?")
	check("flourish: shout closer", F("For the Horde!", 100), "For da Horde, mon!")
	check("flourish: second shout closer", F("For the Horde!", 400), "For da Horde! Ya, mon!")
	check("flourish: second opener", F("We need more magic.", 300), "Listen up, mon. We need more juju.")
	check("flourish: just under the chance", F("We need more magic.", 34), "Hey, mon! We need more juju.")
	check("flourish: just over the chance", F("We need more magic.", 35), "We need more juju.")
	check("flourish: most rolls add nothing", F("We need more magic.", 99), "We need more juju.")
	check("flourish: same roll, same result", F("Where is the healer?", 12345), F("Where is the healer?", 12345))
	check("flourish: shouted", F("KILL THEM ALL!", 0), "HEY, MON! KILL DEM ALL!")
	check("flourish: shouted closer", F("KILL THEM ALL!", 100), "KILL DEM ALL, MON!")
	check("flourish: capital after the opener", F("the boss is here", 0), "Hey, mon! Da boss be here")
	check("flourish: raid marker untouched", F("{skull} kill the skull", 0), "Hey, mon! {skull} kill da skull")
	check("flourish: link untouched", F("|cffff8000|Hitem:1|h[Axe]|h|r is mine", 0), "Hey, mon! |cffff8000|Hitem:1|h[Axe]|h|r be mine")
	check("flourish: not on one word", F("yes", 0), "ya")
	check("flourish: not after a hey", F("Hey, come here", 0), "Hey, come here")
	check("flourish: not with a mon already", F("Ya mon, get them", 100), "Ya mon, get dem")
	check("flourish: not after OOC at the end", F("Hello there ((brb))", 100), "Hey, mon! Hello dere ((brb))")
	check("flourish: not before OOC at the start", F("((brb)) hello there", 0), "((brb)) hello dere, mon")
	check("flourish: not after an action at the end", F("Hello there *waves*", 100), "Hey, mon! Hello dere *waves*")
	check("flourish: not when both ends are taken", F("*grins* hello there *waves*", 0), "*grins* hello dere *waves*")
	check("flourish: not after an unclosed OOC", F("hello there ((back soon", 100), "Hey, mon! Hello dere ((back soon")
	check("flourish: never in emotes", F('grunts, "What do you want?"', 0, { quotesOnly = true }), 'grunts, "Wha\' do ya want?"')
	check("flourish: off without the setting", Translate("We need more magic.", { vocab = true, roll = 0 }), "We need more juju.")
	check("flourish: off without a roll", Translate("We need more magic.", { vocab = true, flourish = true }), "We need more juju.")
	check("flourish: with mon on a yell", F("For the Horde!", 100, { mon = true }), "For da Horde, mon!")
	check("flourish: only one mon on a yell", F("For the Horde!", 400, { mon = true }), "For da Horde! Ya, mon!")
	check("flourish: mon after a flourish without one", F("For the Horde!", 700, { mon = true }), "For da Horde! Stay away from da voodoo, mon!")
	local long = string.rep("he ", 84) .. "he."    -- 255 bytes, stays 255 in troll
	check("flourish: left off when it would not fit", F(long, 100), Translate(long, { vocab = true }))
end

-- Troll voices, at translator level.
do
	local voices = ns.Lexicon.voices
	local function V(key, text, roll, extra)
		local opts = { vocab = true, flourish = roll ~= nil, roll = roll, voice = voices[key] }
		for k, v in pairs(extra or {}) do
			opts[k] = v
		end
		return Translate(text, opts)
	end
	check("voice: every voice listed in order", #ns.Lexicon.voiceOrder, 6)
	for _, key in ipairs(ns.Lexicon.voiceOrder) do
		check("voice: " .. key .. " has a name and a description", type(voices[key].name) == "string" and type(voices[key].about) == "string", true)
	end
	-- words of their own
	check("voice: sistah words", V("sistah", "my sisters, dear"), "me sistahs, sugar")
	check("voice: witch doctor words", V("witchdoctor", "heal me, I need a potion"), "patch me, I need a brew")
	check("voice: headhunter words", V("headhunter", "attack the enemies"), "hunt da prey")
	check("voice: shadow hunter words", V("shadowhunter", "good luck, say a prayer"), "good fate, say a blessin'")
	check("voice: zandalari words", V("zandalari", "hello my friends, yes man"), "greetin's me allies, indeed young one")
	check("voice: darkspear has no words of its own", V("darkspear", "hello my friends, yes man"), "hello me friends, ya mon")
	check("voice: words need troll words on", Translate("heal me with a potion", { voice = voices.witchdoctor }), "heal me wit' a potion")
	check("voice: own words still win", V("witchdoctor", "a potion", nil, { words = ns.Translator.PrepareWords({ potion = "bottle" }) }), "a bottle")
	-- flourishes of their own
	check("voice: sistah opener", V("sistah", "We need more magic.", 0), "Listen 'ere, sugar. We need more juju.")
	check("voice: sistah closer", V("sistah", "We need more magic.", 100), "We need more juju, sugar.")
	check("voice: sistah question", V("sistah", "Who did this?", 400), "Who did dis, mon?")
	check("voice: sistah shout", V("sistah", "Charge them!", 100), "Charge dem! Outta me way!")
	check("voice: witch doctor opener", V("witchdoctor", "We need more magic.", 0), "Da spirits be sayin'... We need more juju.")
	check("voice: headhunter closer", V("headhunter", "We need more magic.", 100), "We need more juju, an' I be takin' dey head.")
	check("voice: shadow hunter question", V("shadowhunter", "Where is the healer?", 100), "Where be da witch doctor, or do da shadows lie?")
	check("voice: zandalari question", V("zandalari", "Where is the healer?", 100), "Where be da witch doctor, lesser troll?")
	check("voice: zandalari shout", V("zandalari", "Charge them!", 400), "Charge dem! Da empire rise again!")
	check("voice: darkspear uses the usual flourishes", V("darkspear", "We need more magic.", 0), "Hey, mon! We need more juju.")
	check("voice: some voices flourish more often", V("headhunter", "We need more magic.", 40), "Time ta hunt! We need more juju.")
	check("voice: than the usual", V("darkspear", "We need more magic.", 40), "We need more juju.")
	check("voice: flourishes still need the setting", V("headhunter", "We need more magic."), "We need more juju.")
	-- a Headhunter says mon on every yell
	check("voice: headhunter yell", V("headhunter", "Charge", nil, { mon = true }), "Charge, mon!")
	check("voice: headhunter yell after a question", V("headhunter", "Ready?", nil, { mon = true }), "Ready, mon?")
	check("voice: headhunter yell in capitals", V("headhunter", "CHARGE", nil, { mon = true }), "CHARGE, MON!")
	check("voice: others only after !", V("witchdoctor", "Charge", nil, { mon = true }), "Charge")
	check("voice: never twice", V("headhunter", "Ya mon", nil, { mon = true }), "Ya mon")
end

-- The guesser by itself.
check("correct: abuot", Correct("abuot"), "about")
check("correct: untill", Correct("untill"), "until")
check("correct: kull (key next door)", Correct("kull"), "kill")
check("correct: real word", Correct("form"), nil)
check("correct: too short to guess", Correct("teh"), nil)
check("correct: stretched word", Correct("nooooo"), nil)
check("correct: nonsense", Correct("xqzvkjw"), nil)
check("correct: same answer twice", Correct("abuot"), "about")
-- What the sound rules make is troll, not a typo.
for _, troll in ipairs({ "fightin", "tings", "betta", "tink", "bodda", "wedda", "togedda", "nuttin",
	"widout", "brudda", "mudda", "radda", "furda", "hunta", "playas", "teet" }) do
	check("correct: troll spelling (" .. troll .. ")", Correct(troll), nil)
end
-- A slip of the finger is never turned into a curse word.
for _, slip in ipairs({ "fukc", "shti", "biitch", "bastrad", "craap", "dmn", "asss" }) do
	check("correct: never guesses a curse word (" .. slip .. ")", Correct(slip), nil)
end
for swear in pairs(ns.Lexicon.swears) do
	if Correct(swear) ~= nil then
		check("correct: curse words are known words (" .. swear .. ")", Correct(swear), nil)
	end
end

-- A message that would outgrow the chat limit is sent as typed.
do
	local long = string.rep("he ", 85)          -- 255 bytes; "he" stays "he"
	check("fits: same length is fine", #Translate(long, TROLL), 255)
	local growing = string.rep("doctor ", 36) .. "doc" -- 255 bytes; "witch doctor" would not fit
	check("too long: sent as typed", Translate(growing, TROLL), growing)
	local yell = string.rep("a", 250) .. "!"
	check("too long for mon: left off", Translate(yell, YELL), yell)
	check("not a string", Translate(nil, TROLL), nil)
end

---------------------------------------------------------------------------
-- Part two: the addon inside a stand-in game
---------------------------------------------------------------------------

local function newGame(config)
	return Mock.new(config):load(root)
end

-- A troll types things.
do
	local game = newGame({ race = "Troll" })
	local box = game:editBox()

	check("toc lists fourteen files", #game.files, 14)
	check("troll: on by default", game.ns.IsActive(), true)
	check("troll: greeted once", #game.printed, 1)

	check("say", box:say("Hello man"), "Hello mon")
	local text, message = box:say("/y For the Horde!")
	check("yell text", text, "For da Horde, mon!")
	check("yell type", message.chatType, "YELL")
	check("emote", box:say('/e grunts, "What do you want?"'), 'grunts, "Wha\' do ya want?"')
	check("party", box:say("/p kill the healer"), "kill da witch doctor")
	check("guild", box:say("/g hello man"), "hello mon")

	text, message = box:say("/w Bob give me the gold")
	check("whisper text", text, "gimme da gold")
	check("whisper target", message.target, "Bob")

	check("numbered channel is off by default", box:say("/1 selling the axe"), "selling the axe")
	box.chatType = "BN_WHISPER"
	check("battle.net whisper is off by default", box:say("hello there"), "hello there")
	box.chatType = "AFK"
	check("unknown chat types are never touched", box:say("back in the morning"), "back in the morning")

	check("out of character", box:say("((be right back))"), "((be right back))")
	check("plain prefix", box:say("! the plain truth"), "the plain truth")

	-- slash commands run and send nothing
	local before = #game.sent
	box:say("/juju help")
	check("/juju help sends nothing", #game.sent, before)
	check("/juju help prints", game.printed[#game.printed]:match("say it plainly") ~= nil, true)

	box:say("/juju off")
	check("off: not active", game.ns.IsActive(), false)
	check("off: sent as typed", box:say("Hello man"), "Hello man")
	check("off: saved for this character", game.env.JujuCharDB.mode, "off")
	box:say("/juju on")
	check("on again", box:say("Hello man"), "Hello mon")

	box:say("/juju channel on")
	check("channel switched on", box:say("/1 selling the axe"), "sellin' da axe")
	box:say("/juju guild off")
	check("guild switched off", box:say("/g hello man"), "hello man")
	check("officer follows guild", box:say("/o hello man"), "hello man")

	box:say("/juju config")
	check("config opens the panel", game.openedCategory, "Juju")

	game.env.Juju_Toggle()
	check("key binding switches off", game.ns.IsActive(), false)
	game.env.Juju_OnAddonCompartmentClick("Juju", "LeftButton")
	check("minimap menu switches on", game.ns.IsActive(), true)
	game.openedCategory = nil
	game.env.Juju_OnAddonCompartmentClick("Juju", "RightButton")
	check("minimap menu right-click opens the panel", game.openedCategory, "Juju")
	game.env.Juju_OnAddonCompartmentEnter("Juju", {})
	game.env.Juju_OnAddonCompartmentLeave("Juju", {})
end

-- Somebody who is not a troll.
do
	local game = newGame({ race = "Human" })
	local box = game:editBox()
	check("human: off by default", game.ns.IsActive(), false)
	check("human: sent as typed", box:say("Hello man"), "Hello man")
	box:say("/juju on")
	check("human: forced on", box:say("Hello man"), "Hello mon")
	box:say("/juju auto")
	check("human: back to auto", box:say("Hello man"), "Hello man")
end

-- Settings survive a reload, and new settings get their defaults.
do
	local saved = {
		JujuDB = { vocab = false, channels = { say = true, yell = false } },
		JujuCharDB = { mode = "on", greeted = true },
	}
	local game = newGame({ race = "Tauren", saved = saved })
	local box = game:editBox()
	check("saved: no second greeting", #game.printed, 0)
	check("saved: forced on for a tauren", game.ns.IsActive(), true)
	check("saved: accent only", box:say("kill the human"), "kill da human")
	check("saved: yell stays off", box:say("/y kill the human"), "kill the human")
	check("saved: missing settings filled in", game.env.JujuDB.channels.party, true)
	check("saved: missing settings filled in (2)", game.env.JujuDB.mon, true)
end

-- The settings panel.
do
	local game = newGame({ race = "Troll" })
	local box = game:editBox()
	local settings = game.settings

	check("panel registered", game.registeredCategory == game.category and game.category.name, "Juju")
	local count = 0
	for _ in pairs(settings) do count = count + 1 end
	check("panel has every setting", count, 12 + #game.ns.CHANNELS)
	check("panel has two headers", #game.layout.initializers, 2)

	check("active box starts ticked for a troll", settings.JUJU_ACTIVE.get(), true)
	check("active box default follows race", settings.JUJU_ACTIVE.default, true)
	settings.JUJU_ACTIVE.set(false)
	check("unticking switches off", box:say("Hello man"), "Hello man")
	settings.JUJU_ACTIVE.set(true)

	settings.JUJU_VOCAB.set(false)
	check("troll words off", box:say("use the magic"), "use da magic")
	settings.JUJU_VOCAB.set(true)

	settings.JUJU_MON.set(false)
	check("mon off", box:say("/y For the Horde!"), "For da Horde!")

	check("typos fixed by default", box:say("dont wory"), "don't worry")
	settings.JUJU_TYPOS.set(false)
	check("typos setting off", box:say("dont wory"), "don't wory")
	check("typos setting is saved", game.env.JujuDB.typos, false)
	settings.JUJU_TYPOS.set(true)

	settings.JUJU_NAMES.set(true)
	check("names on", box:say("Tell Thrall"), "Tell Trall")

	settings.JUJU_CHANNEL_SAY.set(false)
	check("say off", box:say("Hello man"), "Hello man")
	check("say off is saved", game.env.JujuDB.channels.say, false)
end

-- Names of people nearby are left alone.
do
	local game = newGame({ race = "Troll", name = "Hakkar", group = { "Thrand" } })
	local box = game:editBox()
	game.ns.db.names = true -- mangle every other name

	check("stranger is mangled", box:say("Thrall is here"), "Trall be here")
	game.target = "Thrall"
	check("target is kept", box:say("Thrall is here"), "Thrall be here")
	game.target = nil
	check("own name is kept", box:say("Hakkar is here"), "Hakkar be here")
	check("group member is kept", box:say("Thrand is here"), "Thrand be here")

	check("not heard yet", box:say("Hogger is here"), "Hogga be here")
	game:fire("CHAT_MSG_SAY", "Raaargh!", "Hogger-Stormwind")
	check("recent speaker is kept", box:say("Hogger is here"), "Hogger be here")
	game:fire("CHAT_MSG_SAY", "Hi", "Rokhan")
	check("recent speaker is never guessed", box:say("ask rokhan"), "ask rokhan")
	check("in small letters too, as it is not a word", box:say("the hogger is here"), "da hogger be here")
end

-- The preview above the chat box.
do
	local game = newGame({ race = "Troll" })
	local box = game:editBox()
	local preview = game.env.JujuPreviewFrame

	check("preview starts hidden", preview:IsShown(), false)
	box:type("Hello man")
	check("preview shows while typing", preview:IsShown(), true)
	check("preview shows the troll", preview.fontString:GetText():match("Hello mon") ~= nil, true)
	box:type("! the plain truth")
	check("preview labels plain lines", preview.fontString:GetText():match("Plain:|r the plain truth") ~= nil, true)
	box:type("zug zug")
	check("preview hides when nothing changes", preview:IsShown(), false)
	box:type("/juju te")
	check("preview hides for slash commands", preview:IsShown(), false)

	box:type("Hello man")
	game.env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusLost", box)
	check("preview hides when the chat box closes", preview:IsShown(), false)

	game.settings.JUJU_PREVIEW.set(false)
	box:type("Hello man")
	check("preview can be switched off", preview:IsShown(), false)
	game.settings.JUJU_PREVIEW.set(true)
	check("preview comes back", preview:IsShown(), true)

	game.ns.SetMode("off", true)
	check("preview hides when Juju is off", preview:IsShown(), false)
end

-- The Juju box: type English, see the troll as you type.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()
	local window = game.env.JujuBoxFrame

	local input = window.Input

	-- the text of the line that shows the translation
	local function shown()
		return unlinked(window.Output:GetText())
	end

	check("box: has an English line", input ~= nil, true)
	check("box: starts closed", window:IsShown(), false)
	check("box: Escape closes it", game.env.UISpecialFrames[1], "JujuBoxFrame")

	local before = #game.sent
	chat:say("/juju")
	check("box: /juju opens it", window:IsShown(), true)
	check("box: /juju says nothing", #game.sent, before)
	check("box: ready to type", input:HasFocus(), true)
	game:nextFrame()
	check("box: still ready a frame later", input:HasFocus(), true)
	check("box: empty shows the hint", shown():match("Type someting") ~= nil, true)

	input:userType("Hello man")
	check("box: follows typing", shown(), "Hello mon")
	input:userType("Hello man, the trolls are attacking!")
	check("box: follows typing (2)", shown(), "Hello mon, da trolls be attackin'!")
	check("box: typing says nothing", #game.sent, before)
	input:userType("   ")
	check("box: blank shows the hint again", shown():match("Type someting") ~= nil, true)

	-- settings changes show up straight away
	input:userType("use the magic")
	check("box: troll words on", shown(), "use da juju")
	game.settings.JUJU_VOCAB.set(false)
	check("box: troll words off", shown(), "use da magic")
	game.settings.JUJU_VOCAB.set(true)

	-- it works even while troll speech is switched off
	game.ns.SetMode("off", true)
	input:userType("Hello man")
	check("box: works while speech is off", shown(), "Hello mon")
	game.ns.SetMode("on", true)

	-- Put in chat: the English goes into the chat line, and Enter sends troll
	local putInChat = window.PutInChatButton
	input:userType("")
	check("box: Put in chat greyed out when empty", putInChat:IsEnabled(), false)
	putInChat:click()
	check("box: Put in chat does nothing when empty", game.openedChat, nil)
	input:userType("Hello man, the trolls are attacking!")
	check("box: Put in chat ready", putInChat:IsEnabled(), true)
	local sentBefore = #game.sent
	putInChat:click()
	check("box: Put in chat opens the chat line with the English", game.openedChat, "Hello man, the trolls are attacking!")
	check("box: Put in chat says nothing by itself", #game.sent, sentBefore)
	check("box: Put in chat lets go of the keyboard", input:HasFocus(), false)
	check("box: Put in chat leaves the box open", window:IsShown(), true)
	check("box: Put in chat keeps the words", input:GetText(), "Hello man, the trolls are attacking!")
	check("box: Enter in the chat line sends the troll", chat:say(game.openedChat), "Hello mon, da trolls be attackin'!")
	before = before + 1 -- that one was sent on purpose
	game.openedChat = nil
	input:userType("Hello man")

	input:run("OnEnterPressed")
	check("box: Enter lets go of the keyboard", input:HasFocus(), false)
	check("box: Enter leaves it open", window:IsShown(), true)

	chat:say("/juju")
	check("box: /juju again closes it", window:IsShown(), false)

	chat:say("/juju test We need more magic")
	check("box: /juju test opens it", window:IsShown(), true)
	check("box: /juju test fills in the words", input:GetText(), "We need more magic")
	check("box: /juju test shows the troll", shown(), "We need more juju")
	chat:say("/juju test Hello man")
	check("box: /juju test while open replaces the words", shown(), "Hello mon")

	input:userType("something")
	input:run("OnEscapePressed")
	check("box: Escape on the line closes it", window:IsShown(), false)
	check("box: closing lets go of the keyboard", input:HasFocus(), false)

	chat:say("/juju")
	for _, frame in ipairs(game.frames) do
		if frame.frameType == "Button" and frame.template == "UIPanelCloseButton" and frame.parent == window then
			frame:click()
		end
	end
	check("box: the X closes it", window:IsShown(), false)
	check("box: nothing was ever said", #game.sent, before)
end

-- Teaching Juju your own words.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()
	local window = game.env.JujuBoxFrame

	chat:say("/juju")
	local headings = {}
	for _, someFrame in ipairs(game.frames) do
		for _, fontString in ipairs(someFrame.fontStrings or {}) do
			headings[fontString:GetText() or ""] = true
		end
	end
	check("teach: section is called Ya Own Juju", headings["Ya Own Juju"], true)
	local wordRows = function() return window.WordList.scrollBox:ShownRows() end
	check("teach: list starts empty", #wordRows(), 0)
	check("teach: says so", window.WordList.empty:IsShown(), true)

	window.English:userType("gold")
	window.Becomes:userType("shinies")
	window.SaveButton:click()
	check("teach: saved", game.env.JujuDB.words.gold, "shinies")
	check("teach: says so", window.Status:GetText(), "\"gold\" becomes \"shinies\".")
	check("teach: lines cleared", window.English:GetText() .. window.Becomes:GetText(), "")
	check("teach: ready for the next word", window.English:HasFocus(), true)
	check("teach: listed", #wordRows() == 1 and wordRows()[1].Text:GetText(), "gold  |cff808080=|r  |cff3fbfafshinies|r")
	check("teach: empty hint gone", window.WordList.empty:IsShown(), false)
	check("teach: counted", window.WordsTitle:GetText(), "Your words (1)")
	window.Input:userType("we need more gold")
	check("teach: box uses it", unlinked(window.Output:GetText()), "we need more shinies")
	check("teach: chat uses it", chat:say("give me the gold"), "gimme da shinies")

	-- Enter moves across and fills in what the word becomes now
	window.English:userType("Gold ")
	window.English:run("OnEnterPressed")
	check("teach: Enter fills in the current word", window.Becomes:GetText(), "shinies")
	check("teach: Enter moves to the second line", window.Becomes:HasFocus(), true)
	window.Becomes:userType("loot")
	window.Becomes:run("OnEnterPressed")
	check("teach: Enter on the second line saves", game.env.JujuDB.words.gold, "loot")

	-- keep as typed
	window.English:userType("Rokhan")
	window.SaveButton:click()
	check("teach: empty means keep", game.env.JujuDB.words.rokhan, false)
	check("teach: keep message", window.Status:GetText(), "\"rokhan\" will be kept exactly as you type it.")
	check("teach: kept word untouched", chat:say("rokhan is the boss"), "rokhan be da boss")

	-- mistakes
	window.English:userType("")
	window.SaveButton:click()
	check("teach: needs a word", window.Status:GetText(), "Type the English word first.")
	window.English:userType("gold!!")
	window.Becomes:userType("x")
	window.SaveButton:click()
	check("teach: odd characters refused", game.env.JujuDB.words["gold!!"], nil)
	check("teach: and explained", window.Status:GetText():match("^Use only letters") ~= nil, true)
	window.English:userType("hello")
	window.Becomes:userType("|cffff0000oi|r")
	window.SaveButton:click()
	check("teach: colour codes stripped", game.env.JujuDB.words.hello, "cffff0000oir")

	-- the list: kept words, clicking a row, and its X
	window.English:userType("Bert")
	window.SaveButton:click()
	check("list: in alphabetical order", wordRows()[1].Text:GetText() .. " | " .. wordRows()[2].Text:GetText(),
		"bert  |cff808080(kept as typed)|r | gold  |cff808080=|r  |cff3fbfafloot|r")
	window.English:userType("")
	window.Becomes:userType("")
	wordRows()[2]:click()
	check("list: click loads it to change", window.English:GetText() .. " = " .. window.Becomes:GetText(), "gold = loot")
	check("list: ready to type", window.Becomes:HasFocus(), true)
	wordRows()[1]:run("OnEnter")
	wordRows()[1]:run("OnLeave")
	wordRows()[1].Remove:click()
	check("list: X removes it", game.env.JujuDB.words.bert, nil)
	check("list: row gone", #wordRows(), 3) -- gold, rokhan and hello are left
	check("list: says so", window.Status:GetText(), "Removed \"bert\".")

	-- removing
	window.English:userType("gold")
	window.RemoveButton:click()
	check("teach: removed", game.env.JujuDB.words.gold, nil)
	check("teach: removed message", window.Status:GetText(), "Removed \"gold\".")
	check("teach: back to normal", chat:say("give me the gold"), "gimme da gold")
	window.English:userType("gold")
	window.RemoveButton:click()
	check("teach: removing twice", window.Status:GetText(), "\"gold\" is not one of your words.")

	-- slash commands
	chat:say("/juju word for the horde = For da Horde, ya hear")
	check("slash word: phrase saved", game.env.JujuDB.words["for the horde"], "For da Horde, ya hear")
	check("slash word: used", chat:say("/y For the Horde!"), "For da Horde, ya hear, mon!")
	chat:say("/juju keep Thrall")
	check("slash keep", game.env.JujuDB.words.thrall, false)
	chat:say("/juju forget thrall")
	check("slash forget", game.env.JujuDB.words.thrall, nil)
	chat:say("/juju words")
	check("slash words lists them", game.printed[#game.printed]:match("for the horde = For da Horde, ya hear") ~= nil, true)
	local before = #game.sent
	chat:say("/juju word gold")
	check("slash word: needs =", game.printed[#game.printed]:match("Try: /juju word gold = shinies") ~= nil, true)
	check("slash word: says nothing aloud", #game.sent, before)

	-- your words survive a reload
	local saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB }
	local again = newGame({ race = "Troll", saved = saved })
	check("teach: words survive a reload", again:editBox():say("rokhan is the boss"), "rokhan be da boss")
end

-- Numbered channels: General, Trade, LookingForGroup and the rest.
do
	local CHANNELS = { "General - Durotar", "Trade - City", "LocalDefense - Durotar", "LookingForGroup", "OrcRP" }
	local game = newGame({ race = "Troll", channels = CHANNELS })
	local chat = game:editBox()
	local channels = game.env.JujuDB.channels

	check("numbered: names sorted out", table.concat({
		game.ns.ChannelKey("General - Durotar"), game.ns.ChannelKey("Trade - City"),
		game.ns.ChannelKey("LookingForGroup"), game.ns.ChannelKey("LocalDefense - Durotar"),
		game.ns.ChannelKey("OrcRP"), game.ns.ChannelKey(nil),
	}, " "), "general trade lfg other other other")

	check("numbered: General off by default", chat:say("/1 hello man"), "hello man")
	check("numbered: Trade off by default", chat:say("/2 selling the axe"), "selling the axe")

	chat:say("/juju general on")
	check("numbered: General on", chat:say("/1 hello man"), "hello mon")
	check("numbered: Trade still off", chat:say("/2 selling the axe"), "selling the axe")
	chat:say("/juju other on")
	check("numbered: custom RP channel", chat:say("/5 hello man"), "hello mon")
	check("numbered: local defense counts as other", chat:say("/3 the humans are here"), "da humans be here")
	check("numbered: LookingForGroup still off", chat:say("/4 need a healer"), "need a healer")

	-- the key binding switches them all off, then back to how they were
	game.env.Juju_ToggleChannels()
	check("numbered: key switches all off", game.ns.NumberedChannelsOn(), false)
	check("numbered: says so", game.printed[#game.printed]:match("^.-Plain speech in General") ~= nil, true)
	check("numbered: General plain again", chat:say("/1 hello man"), "hello man")
	game.env.Juju_ToggleChannels()
	check("numbered: key restores General", channels.general, true)
	check("numbered: key restores other", channels.other, true)
	check("numbered: key leaves Trade off", channels.trade, false)
	check("numbered: names what came on", game.printed[#game.printed]:match("General channel, Other numbered channels") ~= nil, true)

	-- /juju channels on with nothing remembered turns them all on
	chat:say("/juju channels off")
	game.env.JujuDB.numberedRemembered = nil
	chat:say("/juju channels on")
	check("numbered: all on", channels.general and channels.trade and channels.lfg and channels.other, true)
	check("numbered: Trade now troll", chat:say("/2 selling the axe"), "sellin' da axe")
	chat:say("/juju channel off")
	check("numbered: old /juju channel off still works", game.ns.NumberedChannelsOn(), false)

	-- other kinds of chat are not affected
	check("numbered: say unaffected", chat:say("hello man"), "hello mon")

	-- a warning when troll speech is off on the character
	game.ns.SetMode("off", true)
	game.env.Juju_ToggleChannels()
	check("numbered: reminds when Juju is off", game.printed[#game.printed]:match("switched off on this character") ~= nil, true)

	-- the box key binding
	game.env.Juju_ToggleBox()
	check("box key opens", game.env.JujuBoxFrame:IsShown(), true)
	game.env.Juju_ToggleBox()
	check("box key closes", game.env.JujuBoxFrame:IsShown(), false)
end

-- Troll flourishes inside the game.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()
	local preview = game.env.JujuPreviewFrame

	-- rolls come from this list, in order
	local rolls = {}
	game.ns.Random = function() return table.remove(rolls, 1) or 99 end

	check("flourish: off by default", game.env.JujuDB.flourish, false)
	rolls = { 0 }
	check("flourish: nothing while off", chat:say("We need more magic."), "We need more juju.")

	chat:say("/juju flourishes on")
	check("flourish: /juju flourishes on", game.env.JujuDB.flourish, true)

	-- the preview shows exactly what is sent, and the roll holds while typing
	rolls = { 100, 0 }
	chat:type("We need")
	chat:SetText("We need more magic.")
	check("flourish: preview shows it", preview.fontString:GetText(), "We need more juju, mon.")
	chat:SendText()
	check("flourish: sent the same", game.sent[#game.sent].text, "We need more juju, mon.")
	chat:SetText("")
	-- the next message has a new roll (0: an opener)
	chat:SetText("We need more magic.")
	chat:SendText()
	check("flourish: next message rolls again", game.sent[#game.sent].text, "Hey, mon! We need more juju.")

	rolls = { 0 }
	check("flourish: not in emotes", chat:say('/e grunts, "What do you want?"'), 'grunts, "Wha\' do ya want?"')

	-- the Juju box shows a flourish, and Put in chat sends that same one
	rolls = { 99, 300 } -- the chat line takes one roll for /juju, then the box opens
	chat:say("/juju")
	local window = game.env.JujuBoxFrame
	window.Input:userType("We need more magic.")
	check("flourish: box shows it", unlinked(window.Output:GetText()), "Listen up, mon. We need more juju.")
	window.PutInChatButton:click()
	check("flourish: chat line sends what the box showed", chat:say(game.openedChat), "Listen up, mon. We need more juju.")
	chat:say("/juju")

	-- the settings checkbox
	game.settings.JUJU_FLOURISH.set(false)
	rolls = { 0 }
	check("flourish: checkbox off", chat:say("We need more magic."), "We need more juju.")
	game.settings.JUJU_FLOURISH.set(true)
	rolls = { 0 }
	check("flourish: checkbox on", chat:say("We need more magic."), "Hey, mon! We need more juju.")
	chat:say("/juju flourishes")
	check("flourish: /juju flourishes toggles", game.env.JujuDB.flourish, false)
end

-- The Troll/Plain tag above the chat line.
do
	local CHANNELS = { "General - Durotar", "Trade - City" }
	local game = newGame({ race = "Troll", channels = CHANNELS })
	local chat = game:editBox()
	local tag = game.env.JujuTagFrame
	local preview = game.env.JujuPreviewFrame
	local channels = game.env.JujuDB.channels
	local function says() return tag.fontString:GetText() end

	check("tag: hidden until the chat line opens", tag:IsShown(), false)
	chat:type("")
	check("tag: shows before anything is typed", tag:IsShown(), true)
	check("tag: Troll in say", says(), "Troll")
	check("tag: no preview yet", preview:IsShown(), false)

	chat:type("Hello man")
	check("tag: still there while typing", tag:IsShown(), true)
	check("tag: preview beside it has no Troll: prefix", preview.fontString:GetText(), "Hello mon")

	-- clicking switches the channel being typed in, and only that one
	tag:click()
	check("tag: click switches say off", channels.say, false)
	check("tag: now Plain", says(), "Plain")
	check("tag: preview gone", preview:IsShown(), false)
	check("tag: other channels untouched", channels.party and channels.yell, true)
	check("tag: sent as typed", chat:say("Hello man"), "Hello man")
	chat:type("Hello man")
	tag:click()
	check("tag: click again switches say on", channels.say, true)
	check("tag: Troll again", says(), "Troll")
	check("tag: preview back", preview.fontString:GetText(), "Hello mon")

	-- it follows the channel in the chat line
	chat.chatType = "PARTY"
	chat:type("hello")
	check("tag: party", says(), "Troll")
	chat.chatType, chat.channelTarget = "CHANNEL", 2
	chat:type("selling the axe")
	check("tag: Trade starts Plain", says(), "Plain")
	tag:click()
	check("tag: click switches Trade on", channels.trade, true)
	check("tag: General left alone", channels.general, false)
	check("tag: Trade preview", preview.fontString:GetText(), "sellin' da axe")
	chat.chatType, chat.channelTarget = "BN_WHISPER", nil
	chat:type("hello")
	check("tag: Battle.net whisper is Plain", says(), "Plain")
	chat.chatType = "AFK"
	chat:type("back soon")
	check("tag: hidden for chat Juju never touches", tag:IsShown(), false)
	chat.chatType = "SAY"

	-- a line that will go out plain keeps its own label
	chat:type("! the plain truth")
	check("tag: plain line still labelled", preview.fontString:GetText(), "|cff3fbfafPlain:|r the plain truth")

	-- the tooltip follows the state
	chat:type("hello")
	tag:run("OnEnter")
	tag:click()
	tag:run("OnLeave")
	check("tag: click while hovering", channels.say, false)
	tag:click()

	-- closing the chat line hides it
	game.env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusLost", chat)
	check("tag: hidden when the chat line closes", tag:IsShown(), false)
	check("tag: say is back on", chat:say("Hello man"), "Hello mon")

	-- the setting: without the tag the preview has its Troll: prefix back
	game.settings.JUJU_TAG.set(false)
	chat:type("Hello man")
	check("tag: can be switched off", tag:IsShown(), false)
	check("tag: preview gets its prefix back", preview.fontString:GetText(), "|cff3fbfafTroll:|r Hello mon")
	game.settings.JUJU_TAG.set(true)
	check("tag: and on again", tag:IsShown(), true)

	-- no tag on a character where Juju is asleep
	game.ns.SetMode("off", true)
	check("tag: hidden while troll speech is off", tag:IsShown(), false)
end

-- Clicking a word in the Juju box loads it into Ya Own Juju.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()
	local window = game.env.JujuBoxFrame
	local rolls = {}
	game.ns.Random = function() return table.remove(rolls, 1) or 99 end

	chat:say("/juju")
	window.Input:userType("Hello man, the trolls are going to kill teh healer")
	local shown = window.Output:GetText()
	check("click: reads the same on screen", unlinked(shown), "Hello mon, da trolls be gonna kill da witch doctor")
	check("click: every word is a link", shown,
		"|Haddon:Juju:1|hHello|h |Haddon:Juju:2|hmon|h, |Haddon:Juju:3|hda|h |Haddon:Juju:4|htrolls|h "
		.. "|Haddon:Juju:5|hbe|h |Haddon:Juju:6|hgonna|h |Haddon:Juju:7|hkill|h |Haddon:Juju:8|hda|h |Haddon:Juju:9|hwitch doctor|h")

	local area = window.OutputFrame
	area:run("OnHyperlinkClick", "addon:Juju:2", "mon", "LeftButton")
	check("click: English word loaded", window.English:GetText(), "man")
	check("click: second line empty and ready", window.Becomes:GetText() == "" and window.Becomes:HasFocus(), true)
	check("click: says what it does now", window.Status:GetText():match('^"man" says "mon" now%.') ~= nil, true)
	window.Becomes:userType("bruddah")
	window.Becomes:run("OnEnterPressed")
	check("click: saved", game.env.JujuDB.words.man, "bruddah")
	check("click: box shows the new word", unlinked(window.Output:GetText()):match("^Hello bruddah,") ~= nil, true)

	-- a phrase is loaded whole, and a typo as it was typed
	area:run("OnHyperlinkClick", "addon:Juju:6", "gonna", "LeftButton")
	check("click: phrase loaded whole", window.English:GetText(), "going to")
	area:run("OnHyperlinkClick", "addon:Juju:8", "da", "LeftButton")
	check("click: typo loaded as typed", window.English:GetText(), "teh")

	-- a word you already taught shows what you taught
	area:run("OnHyperlinkClick", "addon:Juju:2", "bruddah", "LeftButton")
	check("click: own word fills in", window.Becomes:GetText(), "bruddah")

	-- leaving it empty keeps the word as typed: the fix for a bad guess
	window.Input:userType("we fight wory")
	check("click: a guess", unlinked(window.Output:GetText()), "we fight worry")
	area:run("OnHyperlinkClick", "addon:Juju:3", "worry", "LeftButton")
	check("click: guessed word loaded as typed", window.English:GetText(), "wory")
	window.Becomes:run("OnEnterPressed")
	check("click: empty keeps it", game.env.JujuDB.words.wory, false)
	check("click: guess gone", unlinked(window.Output:GetText()), "we fight wory")

	-- links, markers and OOC are not clickable; flourishes in front are skipped
	window.Input:userType("{skull} kill it ((brb))")
	check("click: only words are links", window.Output:GetText(),
		"{skull} |Haddon:Juju:1|hkill|h |Haddon:Juju:2|hit|h ((brb))")
	game.env.JujuDB.flourish = true
	rolls = { 0 }
	chat:say("/juju")
	chat:say("/juju")
	rolls = {}
	game.ns.boxRoll = 0
	window.Input:userType("hello there")
	check("click: flourish in front is not a link", window.Output:GetText(),
		"Hey, mon! |Haddon:Juju:1|hHello|h |Haddon:Juju:2|hdere|h")
	area:run("OnHyperlinkClick", "addon:Juju:1", "'Ello", "LeftButton")
	check("click: first word after a flourish", window.English:GetText(), "hello")
	game.ns.boxRoll = 100
	window.Input:userType("hello there")
	check("click: flourish at the end is not a link", window.Output:GetText(),
		"|Haddon:Juju:1|hhello|h |Haddon:Juju:2|hdere|h, mon")
	game.env.JujuDB.flourish = false

	-- hovering, and links that are not ours
	area:run("OnHyperlinkEnter", "addon:Juju:1", "'ello")
	area:run("OnHyperlinkLeave")
	window.English:userType("")
	area:run("OnHyperlinkClick", "item:1234", "[Axe]", "LeftButton")
	area:run("OnHyperlinkClick", "addon:Juju:99", "x", "LeftButton")
	check("click: other links ignored", window.English:GetText(), "")

	-- an empty box shows the hint, with nothing to click
	window.Input:userType("")
	check("click: hint has no links", window.Output:GetText():find("|H", 1, true), nil)
end

-- Creature names, at translator level.
do
	local mobs = ns.Translator.PrepareMobs()
	for _, name in ipairs({ "Hogger", "Harvest Watcher", "Harvest Golem", "Cursed Raptor", "Mor'Ladim",
		"Defias Bandit", "Venture Co. Logger", "Harpy", "Mother Fang", "Elder Mottled Boar" }) do
		ns.Translator.AddMob(mobs, name)
	end
	check("mobs: count", mobs.count, 10)
	check("mobs: no duplicates", ns.Translator.AddMob(mobs, "HOGGER"), false)
	check("mobs: nothing silly", ns.Translator.AddMob(mobs, "a") or ns.Translator.AddMob(mobs, nil), false)
	local MOBS = { vocab = true, mobs = mobs }
	local function M(text, extra)
		local opts = { vocab = true, mobs = mobs }
		for key, value in pairs(extra or {}) do
			opts[key] = value
		end
		return Translate(text, opts)
	end
	check("mobs: one-word name", M("Let's go kill Hogger"), "Let's go kill Hogga")
	check("mobs: two words, plural", M("the Harvest Watchers are tough"), "da Harvest Watchas be tough")
	check("mobs: troll word inside a name", M("watch out for the Cursed Raptor"), "watch out for da Hexed Raptor")
	check("mobs: possessive", M("Hogger's head"), "Hogga's head")
	check("mobs: kept exactly when nothing changes", M("Mor'Ladim is here"), "Mor'Ladim be here")
	check("mobs: a name's own s is not a plural", M("Defias Bandit ahead"), "Defias Bandit ahead")
	check("mobs: full stop inside a name", M("a Venture Co. Logger"), "a Venture Co. Logga")
	check("mobs: -ies plural, game word or not", M("kill the Harpies"), "kill da Harpies")
	check("mobs: plural of a longer name", M("Elder Mottled Boars everywhere"), "Elda Mottled Boars everywhere")
	check("mobs: longest name wins", M("Mother Fang hits"), "Mudda Fang hits")
	check("mobs: part of a name is not a name", M("ask Harvest about it"), "ask Harvest 'bout it")
	check("mobs: other names still kept", M("ask Rokhan about Hogger"), "ask Rokhan 'bout Hogga")
	check("mobs: lore names kept", M("Thrall and Hogger"), "Thrall an' Hogga")
	check("mobs: off without the list", Translate("Let's go kill Hogger", TROLL), "Let's go kill Hogger")
	check("mobs: a player nearby with that name wins", M("kill Hogger", { isName = function(word) return word == "hogger" end }), "kill Hogger")
	check("mobs: your own word wins", M("kill Hogger", { words = ns.Translator.PrepareWords({ hogger = "big dog" }) }), "kill Big dog")
	check("mobs: Questie announcements", M("Harvest Watcher slain: 5/5, Gold Dust", { keepCapitals = true }), "Harvest Watcha slain: 5/5, Gold Dust")
	check("mobs: lowercase works as before", M("kill hogger"), "kill hogga")
	check("mobs: shouted", M("KILL HOGGER"), "KILL HOGGA")
	ns.Translator.AddMob(mobs, "Scarlet Priest")
	check("mobs: class words inside a name stay", M("kill the Scarlet Priest and the priest"), "kill da Scarlet Priest an' da preacha")
	check("mobs: stable", M(M("the Harvest Watchers are tough")), M("the Harvest Watchers are tough"))
	local trace = {}
	Translate("kill the Harvest Watchers", { vocab = true, mobs = mobs, trace = trace })
	check("mobs: clickable words", trace[3].english .. "=" .. trace[3].troll .. ", " .. trace[4].english .. "=" .. trace[4].troll,
		"Harvest=Harvest, Watchers=Watchas")
end

-- Place names, at translator level.
do
	local places = ns.Translator.PrepareMobs()
	for _, name in ipairs({ "Thunder Bluff", "The Barrens", "Barrens", "The Crossroads", "Crossroads", "Razor Hill",
		"Thousand Needles", "Orgrimmar", "Swamp of Sorrows", "Un'Goro Crater" }) do
		ns.Translator.AddMob(places, name)
	end
	local mobs = ns.Translator.PrepareMobs()
	ns.Translator.AddMob(mobs, "Defias Bandit")
	local function P(text) return Translate(text, { vocab = true, places = places, mobs = mobs }) end
	check("places: two words", P("meet me in Thunder Bluff"), "meet me in Tunda Bluff")
	check("places: plural kept", P("the Barrens are hot"), "da Barrens be hot")
	check("places: without The", P("ride to Crossroads"), "ride ta Crossroads")
	check("places: with The", P("ride to The Crossroads"), "ride ta Da Crossroads")
	check("places: one word", P("heading to Razor Hill"), "headin' ta Razor Hill")
	check("places: of inside", P("lost in the Swamp of Sorrows"), "lost in da Swamp of Sorrows")
	check("places: kept exactly when nothing changes", P("back to Un'Goro Crater"), "back ta Un'Goro Crata")
	check("places: lore place unchanged", P("Thrall is in Orgrimmar"), "Thrall be in Orgrimmar")
	check("places: creature s still kept", P("Defias Bandits in the Barrens"), "Defias Bandits in da Barrens")
	check("places: off without the list", Translate("meet me in Thunder Bluff", TROLL), "meet me in Thunder Bluff")
end

-- Place names in the game: the map list, Questie's list, and travels.
do
	local game = Mock.new({ race = "Troll" })
	local env = game.env
	local maps = {
		[1] = { name = "Azeroth", mapType = 1 },          -- the world: left out
		[12] = { name = "Kalimdor", mapType = 2 },
		[1411] = { name = "Durotar", mapType = 3 },
		[1456] = { name = "Thunder Bluff", mapType = 5 },
		[1457] = { name = "Test Map", mapType = 3 },      -- developer entry
	}
	env.C_Map = { GetMapInfo = function(id) return maps[id] end }
	local zoneLookup = { [17] = { [17] = "The Barrens", [380] = "The Crossroads", [9999] = "UNUSED Cave" },
		[14] = { [362] = "Razor Hill", [367] = "Sen'jin Village" } }
	env.QuestieLoader = { ImportModule = function(_, name) return name == "l10n" and { zoneLookup = zoneLookup } or {} end }
	game.zone, game.subzone = "Durotar", "Valley of Trials"
	env.GetRealZoneText = function() return game.zone end
	env.GetZoneText = function() return game.zone end
	env.GetSubZoneText = function() return game.subzone end
	env.GetMinimapZoneText = function() return game.subzone end
	game:load(root)
	for _ = 1, 60 do game:nextFrame() end
	local chat = game:editBox()
	local known = game.ns.Places.known

	check("places: from the maps", known["thunder bluff"] and known.kalimdor, true)
	check("places: not the world map", known.azeroth, nil)
	check("places: from Questie", known["the crossroads"] and known.crossroads and known["razor hill"], true)
	check("places: developer entries left out", known["test map"] or known["unused cave"], nil)
	check("places: where you are", known["valley of trials"], true)
	check("places: where you are is kept", game.env.JujuDB.knownPlaces["Valley of Trials"], true)
	check("places: Jujuified in chat", chat:say("/p meet at the Crossroads near Thunder Bluff"), "meet at da Crossroads near Tunda Bluff")

	-- moving to a new subzone
	game.subzone = "Hunter Rise"
	game:fire("ZONE_CHANGED")
	check("places: new subzone learned", chat:say("/p see you at Hunter Rise"), "see ya at Hunta Rise")

	chat:say("/juju places")
	check("places: /juju places reports", game.printed[#game.printed],
		"|cff3fbfafJuju|r: Juju knows 11 place names: 2 from the game's maps, 6 from Questie and 3 visited.")
	check("places: /juju places on its own does not switch", game.env.JujuDB.placeNames, true)
	chat:say("/juju places off")
	check("places: /juju places off", chat:say("/p meet in Thunder Bluff"), "meet in Thunder Bluff")
	chat:say("/juju places on")
	game.settings.JUJU_PLACES.set(false)
	check("places: setting off", chat:say("/p meet in Thunder Bluff"), "meet in Thunder Bluff")
	game.settings.JUJU_PLACES.set(true)

	-- visited places come back next session, with no maps or Questie at all
	local again = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB } })
	check("places: visited ones remembered", again:editBox():say("/p see you at Hunter Rise"), "see ya at Hunta Rise")
end

-- Creature names in the game: met in the world, and read from Questie.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()
	local function target(unit)
		game.units.target = unit
		game:fire("PLAYER_TARGET_CHANGED")
	end

	check("creatures: on by default", game.env.JujuDB.creatures, true)
	check("creatures: unknown name kept", chat:say("/p kill Hogger"), "kill Hogger")
	target({ name = "Hogger", hostile = true })
	check("creatures: learned from the target", chat:say("/p kill Hogger"), "kill Hogga")
	check("creatures: remembered", game.env.JujuDB.mobs.hogger, true)

	target({ name = "Marshal Dughan", hostile = false })
	check("creatures: friendly NPCs not learned", game.env.JujuDB.mobs["marshal dughan"], nil)
	target({ name = "Rokhan", player = true, hostile = true })
	check("creatures: players not learned", game.env.JujuDB.mobs.rokhan, nil)
	game.ns.db.names = true
	check("creatures: a targeted player is still protected", chat:say("/p ask Rokhan"), "ask Rokhan")
	game.ns.db.names = false
	target({ name = "Fluffy", pet = true, hostile = true })
	check("creatures: pets not learned", game.env.JujuDB.mobs.fluffy, nil)
	target({ name = 12345, hostile = true })
	check("creatures: odd names ignored", game.env.JujuDB.mobs["12345"], nil)

	game.units.mouseover = { name = "Harvest Watcher", hostile = true }
	game:fire("UPDATE_MOUSEOVER_UNIT")
	check("creatures: learned from the mouse", chat:say("/p the Harvest Watchers"), "da Harvest Watchas")
	game.units.nameplate3 = { name = "Riverpaw Gnoll", hostile = true }
	game:fire("NAME_PLATE_UNIT_ADDED", "nameplate3")
	check("creatures: learned from nameplates", game.env.JujuDB.mobs["riverpaw gnoll"], true)

	-- a unit the game hides details of is skipped without an error
	game.env.UnitCanAttack = function() error("secret") end
	game.units.target = { name = "Murloc", hostile = true }
	game:fire("PLAYER_TARGET_CHANGED")
	check("creatures: hidden details skipped", game.env.JujuDB.mobs.murloc, nil)

	-- the setting
	game.settings.JUJU_CREATURES.set(false)
	check("creatures: setting off", chat:say("/p kill Hogger"), "kill Hogger")
	chat:say("/juju creatures on")
	check("creatures: /juju creatures on", chat:say("/p kill Hogger"), "kill Hogga")
	chat:say("/juju creatures")
	check("creatures: /juju creatures on its own does not switch", game.env.JujuDB.creatures, true)
	check("creatures: /juju creatures says how many", game.printed[#game.printed], "|cff3fbfafJuju|r: Juju knows 3 creature names, all met in the world.")
	chat:say("/juju creatures off")
	check("creatures: /juju creatures off", chat:say("/p kill Hogger"), "kill Hogger")
	chat:say("/juju creatures on")

	-- names met carry over to the next session
	local again = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB } })
	check("creatures: remembered next session", again:editBox():say("/p kill Hogger"), "kill Hogga")
end

-- Creature names from Questie's database.
do
	local game = Mock.new({ race = "Troll" })
	local env = game.env
	local npcs = {
		[1] = { name = "Hogger" },
		[2] = { name = "Harvest Watcher" },
		[3] = { name = "Marshal Dughan", friendlyToFaction = "A" },
		[4] = { name = "Thrall", friendlyToFaction = "H" },
		[5] = { name = "Kobold Vermin", friendlyToFaction = "" },
		-- neutral beasts are listed as friendly to both, with no title or services
		[6] = { name = "Mottled Boar", friendlyToFaction = "AH", npcFlags = 0 },
		[7] = { name = "Plainstrider", friendlyToFaction = "AH" },
		-- townsfolk friendly to both have a title or a service
		[8] = { name = "Wharfmaster Dizzywig", friendlyToFaction = "AH", npcFlags = 3 },
		[9] = { name = "Gazlowe", friendlyToFaction = "AH", npcFlags = 0, subName = "Gazlowe's Engineering" },
		-- placeholders and developer entries
		[10] = { name = "Riding Horse (Brown)" },
		[11] = { name = "Boy - placeholder 05" },
		[12] = { name = "Shambling Skeleton UNUSED" },
	}
	-- 901 more, each with its own name: digits spelled as letters
	for id = 100, 1000 do
		npcs[id] = { name = "Creature " .. string.gsub(tostring(id), "%d", function(d) return string.char(97 + d) end) }
	end
	local database = {
		QueryNPCSingle = function(id, key) return npcs[id] and npcs[id][key] end,
	}
	env.Questie = { started = false }
	env.QuestieLoader = { ImportModule = function(_, name) return name == "QuestieDB" and database or {} end }
	env.C_AddOns = { GetAddOnMetadata = function(addon, key)
		return addon == "QuestieDB" and key == "Version" and game.questieDBVersion or nil
	end }
	game.questieDBVersion = "1.1.2"
	game:load(root)
	local chat = game:editBox()

	check("questie db: waits for Questie", chat:say("/p kill Hogger"), "kill Hogger")
	game:nextFrame()
	check("questie db: still waiting", chat:say("/p kill Hogger"), "kill Hogger")
	-- Questie finishes starting up
	local pointers = {}
	for id in pairs(npcs) do pointers[id] = true end
	database.NPCPointers = pointers
	env.Questie.started = true
	game:nextFrame()
	chat:say("/juju creatures")
	check("questie db: reading in batches", game.printed[#game.printed]:match("Still reading") ~= nil, true)
	for _ = 1, 20 do game:nextFrame() end
	check("questie db: read", chat:say("/p kill Hogger"), "kill Hogga")
	check("questie db: all read", game.ns.Mobs.count, 5 + 901)
	check("questie db: friendly NPCs left out", game.ns.Mobs.known["marshal dughan"] or game.ns.Mobs.known.thrall, nil)
	check("questie db: neutral beasts read", game.ns.Mobs.known["mottled boar"] and game.ns.Mobs.known.plainstrider, true)
	check("questie db: neutral townsfolk left out", game.ns.Mobs.known["wharfmaster dizzywig"] or game.ns.Mobs.known.gazlowe, nil)
	check("questie db: placeholders left out", game.ns.Mobs.known["riding horse brown"] or game.ns.Mobs.known["boy placeholder"]
		or game.ns.Mobs.known["shambling skeleton unused"], nil)
	check("questie db: neutral beasts Jujuified", chat:say("/p the Mottled Boars"), "da Mottled Boars")
	check("questie db: two-word names", chat:say("/p the Harvest Watchers"), "da Harvest Watchas")
	chat:say("/juju creatures")
	check("questie db: says where they came from", game.printed[#game.printed],
		"|cff3fbfafJuju|r: Juju knows 906 creature names: 906 from Questie and 0 met in the world.")
	check("questie db: not counted as met", next(game.env.JujuDB.mobs), nil)
	check("questie db: names kept for next time", #game.env.JujuDB.questieNames.names, 906)
	check("questie db: with QuestieDB's version", game.env.JujuDB.questieNames.version, "1.1.2")

	-- next login, same QuestieDB: the kept names are used, QuestieDB is not read
	local function nextLogin(version, withQuestie)
		local after = Mock.new({ race = "Troll" })
		after.questieDBVersion = version
		after.env.C_AddOns = { GetAddOnMetadata = function(addon, key)
			return addon == "QuestieDB" and key == "Version" and after.questieDBVersion or nil
		end }
		after.reads = 0
		if withQuestie then
			after.env.Questie = { started = true }
			local counting = { NPCPointers = pointers, QueryNPCSingle = function(id, key)
				after.reads = after.reads + 1
				return database.QueryNPCSingle(id, key)
			end }
			after.env.QuestieLoader = { ImportModule = function(_, name) return name == "QuestieDB" and counting or {} end }
		end
		after.env.JujuDB, after.env.JujuCharDB = game.env.JujuDB, game.env.JujuCharDB
		after:load(root)
		for _ = 1, 20 do after:nextFrame() end
		return after
	end
	local same = nextLogin("1.1.2", true)
	check("questie db kept: names back", same.ns.Mobs.count, 906)
	check("questie db kept: QuestieDB not read", same.reads, 0)
	check("questie db kept: works", same:editBox():say("/p kill Hogger"), "kill Hogga")
	local updated = nextLogin("1.1.3", true)
	check("questie db updated: read again", updated.reads > 0, true)
	check("questie db updated: new version kept", updated.env.JujuDB.questieNames.version, "1.1.3")
	local removed = nextLogin(nil, false)
	check("questie db removed: kept names still used", removed:editBox():say("/p kill Hogger"), "kill Hogga")
	check("questie db: Questie announcement", game.ns.TranslateAnnouncement("{rt1} Questie: Harvest Watcher slain: 5/5 for [q]!", "PARTY"),
		"{rt1} Questie: Dat be 5/5 Harvest Watcha slain for [q]!")
end

-- A Questie whose database changed shape: no error, names from the world only.
do
	local game = Mock.new({ race = "Troll" })
	game.env.Questie = { started = true }
	game.env.QuestieLoader = { ImportModule = function()
		return { NPCPointers = { [1] = true }, QueryNPCSingle = function() error("changed") end }
	end }
	game:load(root)
	game:nextFrame()
	local chat = game:editBox()
	chat:say("/juju creatures")
	check("questie db changed: says so", game.printed[#game.printed]:match("could not be read") ~= nil, true)
	game.units.target = { name = "Hogger", hostile = true }
	game:fire("PLAYER_TARGET_CHANGED")
	check("questie db changed: world still works", chat:say("/p kill Hogger"), "kill Hogga")
end

-- Sharing a character with another accent addon (Krump). Only one talks.
local function otherAccent(on, native)
	local other = { on = on, native = native, switchedOff = 0 }
	other.IsOn = function() return other.on end
	other.IsNative = function() return other.native end
	other.SwitchOff = function() other.on = false; other.switchedOff = other.switchedOff + 1 end
	return other
end

do
	-- On a Troll, Juju talks even when Krump is switched on too.
	local game = Mock.new({ race = "Troll" })
	local other = otherAccent(true, false)
	game.env.RoleplayAccents = { Krump = other }
	game:load(root)
	local chat = game:editBox()
	check("two accents: Juju talks on its own race", chat:say("Hello man"), "Hello mon")
	check("two accents: signs in", type(game.env.RoleplayAccents.Juju), "table")
	check("two accents: keeps the other's entry", game.env.RoleplayAccents.Krump, other)
	check("two accents: says it is on", game.env.RoleplayAccents.Juju.IsOn(), true)
	check("two accents: says it is native", game.env.RoleplayAccents.Juju.IsNative(), true)
	game.env.RoleplayAccents.Juju.SwitchOff()
	check("two accents: switched off by the other", game.env.RoleplayAccents.Juju.IsOn(), false)
	check("two accents: then sends as typed", chat:say("Hello man"), "Hello man")
end

do
	-- On an Orc, Krump is the native one, so Juju waits until it is
	-- switched on, and then switches Krump off.
	local game = Mock.new({ race = "Orc" })
	local other = otherAccent(false, true)
	game.env.RoleplayAccents = { Krump = other }
	game:load(root)
	local chat = game:editBox()
	chat:say("/juju on")
	check("two accents: on does nothing to an accent that is off", other.switchedOff, 0)
	check("two accents: on works", chat:say("Hello man"), "Hello mon")
	other.on = true
	check("two accents: waits while the native one talks", chat:say("Hello man"), "Hello man")
	check("two accents: no tag while waiting", game.ns.IsActive(), false)
	chat:say("/juju help")
	local said = false
	for _, line in ipairs(game.printed) do
		if line:find("Waiting: Krump is talking on this character", 1, true) then
			said = true
		end
	end
	check("two accents: says who is talking", said, true)
	chat:say("/juju on")
	check("two accents: on switches the other off", other.on, false)
	check("two accents: and says so", game.printed[#game.printed - 1]:find("Krump switched off on this character, so only Juju talks.", 1, true) ~= nil, true)
	check("two accents: then talks", chat:say("Hello man"), "Hello mon")
end

do
	-- Neither is native (a Tauren with both switched on): the first in the
	-- alphabet talks, so the two never both do.
	local game = Mock.new({ race = "Tauren" })
	local other = otherAccent(true, false)
	game.env.RoleplayAccents = { Krump = other }
	game:load(root)
	local chat = game:editBox()
	game.env.JujuCharDB.mode = "on"
	local expected = "Krump" < "Juju" and "Hello man" or "Hello mon"
	check("two accents: a tie goes to the first in the alphabet", chat:say("Hello man"), expected)
	-- A broken entry from some other addon is ignored.
	game.env.RoleplayAccents.Broken = { IsOn = function() error("oops") end, IsNative = function() return true end }
	check("two accents: a broken entry is ignored", chat:say("Hello man"), expected)
end

-- Questie's party announcements. This stand-in has the same shape as the
-- real addon: a global loader, an announce module with public functions,
-- and a private function that calls the global SendChatMessage.
local QUEST = "|cffffff00|Hquest:7:5|h[Kobold Camp Cleanup]|h|r"

local function installQuestie(game)
	local env = game.env
	local modules = {}
	env.QuestieLoader = {
		ImportModule = function(_, name)
			modules[name] = modules[name] or { private = {} }
			return modules[name]
		end,
	}
	game.realSend = function(message, chatType)
		game.sent[#game.sent + 1] = { text = message, chatType = chatType }
	end
	env.SendChatMessage = game.realSend
	game.questieChannel = "PARTY"

	local announce = env.QuestieLoader:ImportModule("QuestieAnnounce")
	local function toChannel(message)
		env.SendChatMessage("{rt1} Questie: " .. message, game.questieChannel)
	end
	function announce:AnnounceObjectiveToChannel(_, objectiveText)
		toChannel(objectiveText .. " for " .. QUEST .. "!")
	end
	function announce:ObjectiveChanged(questId, text)
		announce:AnnounceObjectiveToChannel(questId, text)
	end
	function announce:AnnounceQuestItemLootedToChannel(_, itemLink)
		toChannel("Picked up " .. itemLink .. " which starts " .. QUEST .. "!")
		return true
	end
	function announce:AcceptedQuest() toChannel("Quest Accepted: " .. QUEST) end
	function announce:AbandonedQuest() toChannel("Quest Abandoned: " .. QUEST) end
	function announce:CompletedQuest()
		toChannel("Quest Completed: " .. QUEST)
		-- one announcer calling another must not translate twice
		announce:AnnounceObjectiveToChannel(7, "Kobold Vermin slain: 10/10")
	end
	return announce
end

do
	local game = Mock.new({ race = "Troll" })
	local questie = installQuestie(game)
	game:load(root)
	local function last() return game.sent[#game.sent].text end

	questie:ObjectiveChanged(7, "Kobold Vermin slain: 10/10")
	check("questie: objective with a count", last(), "{rt1} Questie: Dat be 10/10 Kobold Vermin slain for " .. QUEST .. "!")
	check("questie: sent to the party", game.sent[#game.sent].chatType, "PARTY")
	questie:ObjectiveChanged(7, "Gold Dust: 5/5")
	check("questie: item names are not renamed", last(), "{rt1} Questie: Dat be 5/5 Gold Dust for " .. QUEST .. "!")
	questie:ObjectiveChanged(7, "Scout the gazebo on Mystral Lake that overlooks the nearby Alliance outpost")
	check("questie: objective without a count", last(),
		"{rt1} Questie: Scout da gazebo on Mystral Lake dat overlooks da nearby Alliance outpost for " .. QUEST .. "!")

	questie:AcceptedQuest(7)
	check("questie: accepted", last(), "{rt1} Questie: New job, mon: " .. QUEST)
	questie:AbandonedQuest(7)
	check("questie: abandoned", last(), "{rt1} Questie: Forget dis job: " .. QUEST)
	local item = "|cffffffff|Hitem:4854::::::::5:::::|h[Demon Scarred Cloak]|h|r"
	check("questie: return values pass through", questie:AnnounceQuestItemLootedToChannel(7, item), true)
	check("questie: item that starts a quest", last(), "{rt1} Questie: Found " .. item .. ", it start " .. QUEST .. "!")

	local before = #game.sent
	questie:CompletedQuest(7)
	check("questie: completed", game.sent[before + 1].text, "{rt1} Questie: Dis job be done: " .. QUEST)
	check("questie: nested announcement translated once", game.sent[before + 2].text,
		"{rt1} Questie: Dat be 10/10 Kobold Vermin slain for " .. QUEST .. "!")
	check("questie: the real send function is put back", game.env.SendChatMessage == game.realSend, true)

	-- raid chat follows the raid switch
	game.questieChannel = "RAID"
	questie:AcceptedQuest(7)
	check("questie: raid", last(), "{rt1} Questie: New job, mon: " .. QUEST)
	game.env.JujuDB.channels.raid = false
	questie:AcceptedQuest(7)
	check("questie: raid switch off", last(), "{rt1} Questie: Quest Accepted: " .. QUEST)
	game.questieChannel = "PARTY"
	game.env.JujuDB.channels.party = false
	questie:AcceptedQuest(7)
	check("questie: party switch off", last(), "{rt1} Questie: Quest Accepted: " .. QUEST)
	game.env.JujuDB.channels.party = true

	-- the setting, the slash command, and troll speech being off
	game.settings.JUJU_QUESTIE.set(false)
	questie:AcceptedQuest(7)
	check("questie: setting off", last(), "{rt1} Questie: Quest Accepted: " .. QUEST)
	game:editBox():say("/juju questie on")
	questie:AcceptedQuest(7)
	check("questie: /juju questie on", last(), "{rt1} Questie: New job, mon: " .. QUEST)
	game.ns.SetMode("off", true)
	questie:AcceptedQuest(7)
	check("questie: troll speech off", last(), "{rt1} Questie: Quest Accepted: " .. QUEST)
	game.ns.SetMode("on", true)

	-- your own words and flourishes apply
	game.ns.SetWord("slain", "stomped flat")
	questie:ObjectiveChanged(7, "Kobold Vermin slain: 10/10")
	check("questie: own words", last(), "{rt1} Questie: Dat be 10/10 Kobold Vermin stomped flat for " .. QUEST .. "!")
	game.ns.RemoveWord("slain")
	game.env.JujuDB.flourish = true
	game.ns.Random = function() return 0 end
	questie:ObjectiveChanged(7, "Kobold Vermin slain: 10/10")
	check("questie: flourish opener", last(), "{rt1} Questie: Hey, mon! Dat be 10/10 Kobold Vermin slain for " .. QUEST .. "!")
	game.ns.Random = function() return 100 end
	questie:ObjectiveChanged(7, "Kobold Vermin slain: 10/10")
	check("questie: flourish closer", last(), "{rt1} Questie: Dat be 10/10 Kobold Vermin slain for " .. QUEST .. ", mon!")
	game.env.JujuDB.flourish = false

	-- Juju's own chat is unaffected
	check("questie: typed chat still works", game:editBox():say("/p kill the healer"), "kill da witch doctor")
	check("questie: hooking twice changes nothing", game.ns.HookQuestie(), true)
	questie:AcceptedQuest(7)
	check("questie: still translated once", last(), "{rt1} Questie: New job, mon: " .. QUEST)
end

-- An error inside Questie is passed on, and the send function is put back.
do
	local game = Mock.new({ race = "Troll" })
	local questie = installQuestie(game)
	function questie:AcceptedQuest() error("questie went wrong", 0) end
	game:load(root)
	local ok, err = pcall(questie.AcceptedQuest, questie, 7)
	check("questie error: passed on", ok, false)
	check("questie error: same message", err, "questie went wrong")
	check("questie error: send function put back", game.env.SendChatMessage == game.realSend, true)
	questie:CompletedQuest(7)
	check("questie error: still works afterwards", game.sent[1].text, "{rt1} Questie: Dis job be done: " .. QUEST)
end

-- Questie loading after Juju, and Questie not being there at all.
do
	local game = newGame({ race = "Troll" })
	check("no questie: nothing to hook", game.ns.HookQuestie(), false)
	check("no questie: no send function invented", game.env.SendChatMessage, nil)
	local questie = installQuestie(game)
	game:fire("ADDON_LOADED", "Questie")
	questie:AcceptedQuest(7)
	check("late questie: hooked when it loads", game.sent[#game.sent].text, "{rt1} Questie: New job, mon: " .. QUEST)

	-- a Questie whose functions were renamed is left alone, without errors
	local other = Mock.new({ race = "Troll" })
	other.env.QuestieLoader = { ImportModule = function() return { private = {} } end }
	other:load(root)
	check("renamed questie: not hooked, no error", other.ns.HookQuestie(), false)
end

-- Troll voices in the game: one per character.
do
	local game = newGame({ race = "Troll" })
	local chat = game:editBox()

	check("voices: Darkspear to begin with", game.ns.GetVoiceKey(), "darkspear")
	check("voices: nothing saved until chosen", game.env.JujuCharDB.voice, nil)
	chat:say("/juju voice")
	check("voices: /juju voice lists them", game.printed[#game.printed]:match("darkspear, sistah, witchdoctor, headhunter, shadowhunter, zandalari") ~= nil, true)
	chat:say("/juju voice witchdoctor")
	check("voices: /juju voice witchdoctor", game.env.JujuCharDB.voice, "witchdoctor")
	check("voices: says what it is", game.printed[#game.printed]:match("talks like a Witch Doctor") ~= nil, true)
	check("voices: chat uses it", chat:say("/p I need a potion"), "I need a brew")
	chat:say("/juju voice wizard")
	check("voices: unknown voice refused", game.env.JujuCharDB.voice, "witchdoctor")
	check("voices: and explained", game.printed[#game.printed]:match("^.-No such voice") ~= nil, true)
	chat:say("/juju voice Shadow Hunter")
	check("voices: spaces and capitals are fine", game.env.JujuCharDB.voice, "shadowhunter")
	chat:say("/juju voice witch-doctor")
	check("voices: and hyphens", game.env.JujuCharDB.voice, "witchdoctor")

	-- the preview above the chat line shows the voice
	chat:type("I need a potion")
	check("voices: preview", game.env.JujuPreviewFrame.fontString:GetText(), "I need a brew")

	-- the settings dropdown
	local setting = game.settings.JUJU_VOICE
	check("voices: dropdown has all six", #setting.options, 6)
	check("voices: dropdown labels", setting.options[2].label .. ", " .. setting.options[3].label, "Sistah, Witch Doctor")
	check("voices: dropdown shows the current one", setting.get(), "witchdoctor")
	setting.set("zandalari")
	check("voices: dropdown sets it", chat:say("/p my friends are here"), "me allies be here")

	-- the button in the Juju box: click for the next, right-click for the one before
	chat:say("/juju")
	local window = game.env.JujuBoxFrame
	local voiceButton = window.VoiceButton
	local function shown() return (window.Output:GetText():gsub("|Haddon:Juju:%d+|h(.-)|h", "%1")) end
	check("voices: box button shows it", voiceButton:GetText(), "Voice: Zandalari")
	window.Input:userType("my friends need a potion")
	check("voices: box text in the voice", shown(), "me allies need a brew")
	voiceButton:click()
	check("voices: click wraps round to the first", voiceButton:GetText(), "Voice: Darkspear")
	check("voices: box text follows", shown(), "me friends need a brew")
	voiceButton:click()
	check("voices: then Sistah", voiceButton:GetText(), "Voice: Sistah")
	voiceButton:click()
	check("voices: then Witch Doctor", voiceButton:GetText(), "Voice: Witch Doctor")
	check("voices: box text follows again", shown(), "me friends need a brew")
	voiceButton:click()
	voiceButton:click()
	check("voices: click twice more", voiceButton:GetText(), "Voice: Shadow Hunter")
	voiceButton:click("RightButton")
	check("voices: right-click goes back", voiceButton:GetText(), "Voice: Headhunter")
	voiceButton:run("OnEnter")
	voiceButton:run("OnLeave")
	chat:say("/juju")

	-- each character keeps its own voice
	local same = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB } })
	check("voices: kept for this character", same.ns.GetVoiceKey(), "headhunter")
	local alt = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = {} } })
	check("voices: another character starts as a Darkspear", alt.ns.GetVoiceKey(), "darkspear")
	local broken = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = { voice = "nonsense", voiceChosen = true } } })
	check("voices: an unknown saved voice is dropped", broken.ns.GetVoiceKey(), "darkspear")

	-- a Headhunter's yells
	game.ns.SetVoice("headhunter")
	check("voices: headhunter yell", chat:say("/y Charge"), "Charge, mon!")
	game.ns.SetVoice("darkspear")
	check("voices: others only after !", chat:say("/y Charge"), "Charge")
end

-- Female characters start as a Sistah.
do
	local game = newGame({ race = "Troll", sex = 3 })
	local chat = game:editBox()
	check("sistah: a woman starts as a Sistah", game.ns.GetVoiceKey(), "sistah")
	check("sistah: chat uses it", chat:say("/p my sisters are here"), "me sistahs be here")
	check("sistah: the dropdown starts there too", game.settings.JUJU_VOICE.get(), "sistah")
	check("sistah: and its default is Sistah", game.settings.JUJU_VOICE.default, "sistah")
	chat:say("/juju voice darkspear")
	local again = newGame({ race = "Troll", sex = 3, saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB } })
	check("sistah: choosing Darkspear sticks", again.ns.GetVoiceKey(), "darkspear")
	local unchosen = newGame({ race = "Troll", sex = 3, saved = { JujuDB = game.env.JujuDB, JujuCharDB = { voice = "darkspear" } } })
	check("sistah: a voice never chosen is not kept", unchosen.ns.GetVoiceKey(), "sistah")
end

-- Guildmates, friends and Battle.net friends' characters are never Jujuified.
do
	local game = newGame({ race = "Troll",
		guild = { "Thrallson-Stormrage", "Hogger-Stormrage", "Hunter-Stormrage" },
		friends = { "Rokhan", "Thunderbluff" },
		battlenet = { { name = "Harvest" }, { name = "Skyrimguy", program = "App" } },
		channels = { "General - Durotar" } })
	local chat = game:editBox()
	-- creature and place names, to show that people win over both
	game.ns.Translator.AddMob(game.ns.Mobs, "Hogger")
	game.ns.Translator.AddMob(game.ns.Places, "Thunder Bluff")
	game.ns.Translator.AddMob(game.ns.Places, "Thunderbluff")
	game.ns.db.names = true -- mangle every other name

	check("people: roster asked for", game.rosterRequested, true)
	check("people: guildmate kept", chat:say("/g ask Thrallson"), "ask Thrallson")
	check("people: guildmate kept in small letters", chat:say("/g ask thrallson"), "ask thrallson")
	check("people: a guildmate named like a creature", chat:say("/g Hogger is on"), "Hogger be on")
	check("people: a name that is a word, capitalised", chat:say("/g ask Hunter"), "ask Hunter")
	check("people: the same word in small letters is a word", chat:say("/g ask the hunter"), "ask da beast-tama")
	check("people: friend kept", chat:say("/p tell Rokhan"), "tell Rokhan")
	check("people: friend named like a place", chat:say("/p tell Thunderbluff"), "tell Thunderbluff")
	check("people: Battle.net friend's character kept", chat:say("/p tell Harvest"), "tell Harvest")
	check("people: only characters in WoW", game.ns.IsKnownPerson("skyrimguy"), false)
	check("people: strangers still mangled with the setting on", chat:say("/p tell Thrall"), "tell Trall")

	chat:say("/juju names")
	check("people: /juju names", game.printed[#game.printed]:match("6 names of people you know: 3 from your guild, 2 friends and 1 Battle.net") ~= nil, true)

	-- remembered next session, before the game sends the lists
	local again = newGame({ race = "Troll", saved = { JujuDB = game.env.JujuDB, JujuCharDB = game.env.JujuCharDB } })
	again.ns.db.names = true
	check("people: remembered next session", again:editBox():say("/p ask Thrallson"), "ask Thrallson")

end

-- New guildmates are picked up when the roster updates.
do
	local config = { race = "Troll", guild = {} }
	local game = Mock.new(config)
	game:load(root)
	game.ns.db.names = true
	local chat = game:editBox()
	check("roster: not yet known", chat:say("/g ask Thrallson"), "ask Trallson")
	config.guild[1] = "Thrallson-Stormrage"
	game:fire("GUILD_ROSTER_UPDATE")
	check("roster: known after the update", chat:say("/g ask Thrallson"), "ask Thrallson")
	config.friends = { "Grommash" }
	game:fire("FRIENDLIST_UPDATE")
	check("roster: new friend", game.ns.IsKnownPerson("grommash"), true)
end

-- Troll emotes.
do
	local game = newGame({ race = "Troll", name = "Zanjin" })
	local chat = game:editBox()
	local function emote(line)
		local before = #game.sent
		chat:say(line)
		local message = game.sent[before + 1]
		return message and message.text, message and message.chatType
	end

	local text, kind = emote("/voodoo")
	check("emote: voodoo", text, 'wiggles his fingers mysteriously. "Stay away from da voodoo, mon."')
	check("emote: sent as an emote", kind, "EMOTE")
	check("emote: with a name", emote("/mon Rokhan"), 'nods slowly at Rokhan. "Ya, mon. We be cool."')
	game.target = "Hogger"
	check("emote: at your target", emote("/bones"), 'casts a handful of bones at Hogger\'s feet. "Da bones say ya be in trouble, mon."')
	check("emote: a typed name beats the target", emote("/hex Rokhan"), 'points a long finger at Rokhan and mutters a nasty little hex. "Ribbit, mon."')
	game.target = nil
	check("emote: no target", emote("/bones"), 'casts a handful of bones on the ground and studies them closely. "Hmm."')
	check("emote: every one works", emote("/mojo") ~= nil and emote("/tusks") ~= nil and emote("/loa") ~= nil
		and emote("/bwonsamdi") ~= nil and emote("/chill") ~= nil, true)
	check("emote: not Jujuified twice", emote("/loa"), 'raises his arms to the sky. "Da Loa be wit\' us!"')

	-- voices
	game.ns.SetVoice("witchdoctor")
	check("emote: witch doctor voodoo", emote("/voodoo"), 'rattles a string of tiny skulls. "Da voodoo be strong today. Heh heh heh."')
	check("emote: witch doctor voodoo with a name", emote("/voodoo Rokhan"), 'holds up a little doll that looks a lot like Rokhan. "Heh heh heh."')
	check("emote: voice without its own line", emote("/mojo"), "rolls his shoulders and feels the mojo flowing.")
	game.ns.SetVoice("zandalari")
	check("emote: zandalari's own line", emote("/mon"), 'sighs deeply. "Must every troll say mon?"')
	check("emote: falls back for the other line", emote("/mon Rokhan"), 'nods slowly at Rokhan. "Ya, mon. We be cool."')
	game.ns.SetVoice("headhunter")
	check("emote: headhunter at a target", emote("/tusks Rokhan"), 'taps a tusk and eyes Rokhan\'s head. "Dat would look good on me wall."')
	game.ns.SetVoice("darkspear")

	-- /juju emote and /juju emotes
	check("emote: /juju emote", emote("/juju emote mon Rokhan"), 'nods slowly at Rokhan. "Ya, mon. We be cool."')
	chat:say("/juju emotes")
	check("emote: /juju emotes lists them", game.printed[#game.printed]:match("/voodoo /mon /hex /bones /mojo /tusks /loa /bwonsamdi /chill") ~= nil, true)
	chat:say("/juju emote nonsense")
	check("emote: unknown name lists them", game.printed[#game.printed]:match("^.-Troll emotes:") ~= nil, true)

	-- if the game will not send it, it goes into the chat line instead
	game.blockSending = true
	game.openedChat = nil
	chat:say("/hex")
	check("emote: blocked, so put in the chat line", game.openedChat, "/e traces a crooked sign in the air and mutters a hex.")
	game.blockSending = nil
end

-- The Juju box and the chat line strips are built from Blizzard's own parts.
do
	local game = newGame({ race = "Troll" })
	local window = game.env.JujuBoxFrame
	local function templateOf(made)
		for _, someFrame in ipairs(game.frames) do
			if someFrame == made then
				return someFrame.template
			end
		end
	end
	check("native: window", window.template, "ButtonFrameTemplate")
	check("native: title", window.title, "Juju")
	check("native: portrait", window.portraitTexture, "Interface\\Icons\\Racial_Troll_Berserk")
	check("native: tabs are Blizzard tabs", templateOf(window.WordsTab) .. ", " .. templateOf(window.EmotesTab),
		"PanelTabButtonTemplate, PanelTabButtonTemplate")
	check("native: tabs counted", window.numTabs, 2)
	check("native: tabs listed on the window", #window.Tabs, 2)
	check("native: text boxes", templateOf(window.Input) .. ", " .. templateOf(window.English) .. ", " .. templateOf(window.EmoteName),
		"InputBoxTemplate, InputBoxTemplate, InputBoxTemplate")
	check("native: troll text in an inset", templateOf(window.OutputFrame), "InsetFrameTemplate")
	check("native: pages sit in the window's inset", window.Input.parent.parent, window.Inset)
	check("native: tag and preview use the tooltip border",
		game.env.JujuTagFrame.template .. ", " .. game.env.JujuPreviewFrame.template, "TooltipBackdropTemplate, TooltipBackdropTemplate")
	game:editBox():say("/juju")
	check("native: opens on the Words tab", window.selectedTab, 1)
	window.CloseButton:click()
	check("native: the window's own close button", window:IsShown(), false)
end

-- The Emotes page of the Juju box.
do
	local game = newGame({ race = "Troll", name = "Zanjin" })
	local chat = game:editBox()
	local window = game.env.JujuBoxFrame
	local grid = window.EmoteButtons
	local function lastSent() return game.sent[#game.sent] and game.sent[#game.sent].text end

	-- tabs
	chat:say("/juju")
	check("page: opens on Words", game.ns.BoxPage(), "words")
	check("page: Words visible", window.Input:IsVisible(), true)
	window.EmotesTab:click()
	check("page: Emotes tab", game.ns.BoxPage(), "emotes")
	check("page: Words hidden", window.Input:IsVisible(), false)
	check("page: Emotes visible", window.EmoteName:IsVisible(), true)
	check("page: Emotes tab selected", window.selectedTab, 2)
	window.WordsTab:click()
	check("page: back to Words", window.Input:IsVisible() and not window.EmoteName:IsVisible(), true)
	-- the emote buttons were made while the Emotes page was open: they
	-- must hide with it
	local stillShowing = 0
	for _, made in ipairs(grid) do
		if made:IsVisible() then stillShowing = stillShowing + 1 end
	end
	check("page: emote buttons made", #grid, 9)
	check("page: emote buttons hide on the Words page", stillShowing, 0)
	for _, made in ipairs(grid) do
		check("page: emote button sits on the Emotes page", made.parent, game.ns.BoxKit.page)
		break
	end
	window.EmotesTab:click()
	check("page: and come back on the Emotes page", grid[1]:IsVisible(), true)
	window.WordsTab:click()
	chat:say("/juju")
	chat:say("/juju emotes")
	check("page: /juju emotes opens on Emotes", window:IsShown() and game.ns.BoxPage(), "emotes")

	-- the buttons
	local visible = 0
	for _, made in ipairs(grid) do
		if made:IsShown() then visible = visible + 1 end
	end
	check("page: a button per emote", visible, 9)
	check("page: first button", grid[1]:GetText(), "/voodoo")
	check("page: no target", window.EmoteAim:GetText(), "Click an emote to do it. Target someone first to aim it at them.")
	grid[1]:click()
	check("page: click does it", lastSent(), 'wiggles his fingers mysteriously. "Stay away from da voodoo, mon."')
	game.units.target = { name = "Hogger", hostile = true }
	game:fire("PLAYER_TARGET_CHANGED")
	check("page: aim follows your target", window.EmoteAim:GetText(), "Click an emote to do it. Aimed at: |cff3fbfafHogger|r")
	grid[5]:click()
	check("page: aimed at the target", lastSent(), 'sends a little mojo Hogger\'s way. "Dere ya go, mon. Good mojo."')
	local before = #game.sent
	grid[1]:click("RightButton")
	check("page: right-click on Juju's own does nothing", #game.sent, before)
	grid[1]:run("OnEnter")
	grid[1]:run("OnLeave")
	game.units.target = nil

	-- making your own
	window.EmoteName:userType("frog")
	window.EmoteLine:userType("pulls a frog out of {his} pocket and lets it loose.")
	window.EmoteTarget:userType("throws a frog at {target}. It bites.")
	window.SaveEmoteButton:click()
	check("own: saved", game.env.JujuDB.myEmotes.frog.text, "pulls a frog out of {his} pocket and lets it loose.")
	check("own: says so", window.EmoteStatus:GetText(), "Saved /frog.")
	check("own: boxes cleared", window.EmoteName:GetText() .. window.EmoteLine:GetText() .. window.EmoteTarget:GetText(), "")
	check("own: a button for it, in green", grid[10]:GetText(), "|cff3fbfaf/frog|r")
	grid[10]:click()
	check("own: the button works", lastSent(), "pulls a frog out of his pocket and lets it loose.")
	check("own: /frog works", (function() chat:say("/frog Rokhan") return lastSent() end)(), "throws a frog at Rokhan. It bites.")
	check("own: /juju emote works", (function() chat:say("/juju emote frog") return lastSent() end)(), "pulls a frog out of his pocket and lets it loose.")

	-- the list of your own at the bottom
	local ownRows = function() return window.OwnEmoteList.scrollBox:ShownRows() end
	check("own list: one row", #ownRows(), 1)
	check("own list: what it shows", ownRows()[1].Text:GetText(), "|cff3fbfaf/frog|r  |cff808080pulls a frog out of {his} pocket and lets it loose.|r")
	check("own list: counted", window.OwnEmotesTitle:GetText(), "Your emotes (1 of 12)")
	check("own list: hint hidden", window.OwnEmoteList.empty:IsShown(), false)
	window.EmoteName:userType("")
	ownRows()[1]:click()
	check("own list: click loads it to change", window.EmoteName:GetText(), "frog")
	ownRows()[1]:run("OnEnter")
	ownRows()[1]:run("OnLeave")

	-- changing it
	grid[10]:click("RightButton")
	check("own: right-click loads it", window.EmoteName:GetText() .. "|" .. window.EmoteTarget:GetText(), "frog|throws a frog at {target}. It bites.")
	window.EmoteLine:userType("lets a frog loose. It looks hungry.")
	window.EmoteTarget:userType("")
	window.EmoteTarget:run("OnEnterPressed")
	check("own: Enter on the last line saves", game.env.JujuDB.myEmotes.frog.text, "lets a frog loose. It looks hungry.")
	check("own: empty target line means the same line", (function() chat:say("/frog Rokhan") return lastSent() end)(), "lets a frog loose. It looks hungry.")

	-- mistakes
	local function tryName(name, line)
		window.EmoteName:userType(name)
		window.EmoteLine:userType(line or "does a thing.")
		window.EmoteTarget:userType("")
		window.SaveEmoteButton:click()
		return window.EmoteStatus:GetText()
	end
	check("own: two words refused", tryName("big frog"):match("^The name is one word") ~= nil, true)
	check("own: numbers refused", tryName("frog2"):match("^The name is one word") ~= nil, true)
	check("own: Juju's own names refused", tryName("voodoo"), "/voodoo is one of Juju's own emotes. Pick another name.")
	check("own: /juju refused", tryName("juju"), "/juju is taken by Juju itself. Pick another name.")
	check("own: needs a line", tryName("blank", ""):match("^Type what you do") ~= nil, true)
	check("own: colour codes stripped", (function() tryName("shiny", "|cffff0000glows|r") return game.env.JujuDB.myEmotes.shiny.text end)(), "cffff0000glowsr")
	game.ns.RemoveOwnEmote("shiny")
	for index = 1, 11 do
		tryName("extra" .. string.rep("a", index))
	end
	check("own: up to twelve", tryName("onetoomany"):match("^You have 12 emotes already") ~= nil, true)
	for index = 1, 11 do
		game.ns.RemoveOwnEmote("extra" .. string.rep("a", index))
	end

	-- removing with the X in the list
	game.ns.SaveOwnEmote("babble", "babbles at {his} tusks.", "")
	check("own list: two rows", #ownRows(), 2)
	ownRows()[1].Remove:click() -- babble comes first
	check("own list: X removes it", game.env.JujuDB.myEmotes.babble, nil)
	check("own list: says so", window.EmoteStatus:GetText(), "Removed /babble.")
	check("own list: one row left", #ownRows(), 1)

	-- removing
	window.EmoteName:userType("/frog")
	window.RemoveEmoteButton:click()
	check("own: removed", game.env.JujuDB.myEmotes.frog, nil)
	check("own: button gone", grid[10]:IsShown(), false)
	check("own list: empty again", #ownRows(), 0)
	check("own list: hint back", window.OwnEmoteList.empty:IsShown(), true)
	before = #game.sent
	chat:say("/frog")
	check("own: /frog gone", #game.sent, before)
	window.EmoteName:userType("frog")
	window.RemoveEmoteButton:click()
	check("own: removing twice", window.EmoteStatus:GetText(), "/frog is not one of your emotes.")
	chat:say("/juju")
end

-- Your own emotes: kept between sessions, and a command someone else has.
do
	local game = Mock.new({ race = "Troll" })
	game.env.MAXEMOTEINDEX = 1
	game.env.EMOTE1_CMD1 = "/spit"
	game:load(root)
	local chat = game:editBox()
	local ok, message = game.ns.SaveOwnEmote("spit", "spits on the ground.", "")
	check("own taken: saved anyway", ok, true)
	check("own taken: explained", message, "Saved. /spit is already used by the game or another addon, so use the button or /juju emote spit.")
	game.ns.SaveOwnEmote("frog", "lets a frog loose.", "throws a frog at {target}.")
	local again = Mock.new({ race = "Troll" })
	again.env.JujuDB, again.env.JujuCharDB = game.env.JujuDB, game.env.JujuCharDB
	again:load(root)
	local before = #again.sent
	again:editBox():say("/frog Rokhan")
	check("own: kept between sessions", again.sent[before + 1] and again.sent[before + 1].text, "throws a frog at Rokhan.")
	again:editBox():say("/juju emotes")
	check("own: listed", again.printed[#again.printed]:match("/chill /frog /spit") ~= nil, true)
end

-- Pronouns follow the character.
do
	local her = newGame({ race = "Troll", sex = 3 })
	local function emote(game, line)
		local before = #game.sent
		game:editBox():say(line)
		return game.sent[before + 1] and game.sent[before + 1].text
	end
	her.ns.SetVoice("darkspear")
	check("emote: her fingers", emote(her, "/voodoo"), 'wiggles her fingers mysteriously. "Stay away from da voodoo, mon."')
	her.ns.SetVoice("sistah")
	check("emote: sistah mon", emote(her, "/mon Rokhan"), 'looks Rokhan up and down. "Mmhmm. Ya, mon."')
	check("emote: her tusks", emote(her, "/tusks"), "polishes her tusks with great care.")
	local them = newGame({ race = "Troll", sex = 1 })
	check("emote: their tusks", emote(them, "/tusks"), "polishes their tusks with great care.")
end

-- Commands the game or another addon already uses are left alone.
do
	local game = Mock.new({ race = "Troll" })
	game.env.MAXEMOTEINDEX = 2
	game.env.EMOTE1_CMD1 = "/roar"
	game.env.EMOTE2_CMD1 = "/hex" -- as if the game had its own
	game.env.SLASH_OTHERADDON1 = "/mojo"
	game.env.SlashCmdList.OTHERADDON = function() game.otherAddonRan = true end
	game:load(root)
	local chat = game:editBox()
	check("taken: the game's /hex left alone", game.env.SLASH_JUJU_EMOTE_HEX1, nil)
	chat:say("/mojo")
	check("taken: the other addon's /mojo still runs", game.otherAddonRan, true)
	chat:say("/juju emotes")
	check("taken: listed as taken", game.printed[#game.printed]:match("type /juju emote and the name: hex, mojo%.") ~= nil, true)
	local before = #game.sent
	chat:say("/juju emote hex")
	check("taken: still works through /juju emote", game.sent[before + 1].text, "traces a crooked sign in the air and mutters a hex.")
	check("taken: the others are there", game.env.SLASH_JUJU_EMOTE_VOODOO1, "/voodoo")
end

-- The addon adds only the globals it means to.
do
	local game = newGame({ race = "Troll" })
	local expected = {
		JujuDB = true, JujuCharDB = true, JujuPreviewFrame = true, JujuBoxFrame = true, JujuTagFrame = true,
		JujuBoxFrameTab1 = true, JujuBoxFrameTab2 = true,
		SLASH_JUJU1 = true, BINDING_HEADER_JUJU = true, BINDING_NAME_JUJU_TOGGLE = true,
		Juju_Toggle = true, Juju_OnAddonCompartmentClick = true,
		Juju_OnAddonCompartmentEnter = true, Juju_OnAddonCompartmentLeave = true,
		BINDING_NAME_JUJU_BOX = true, BINDING_NAME_JUJU_TOGGLE_CHANNELS = true,
		Juju_ToggleBox = true, Juju_ToggleChannels = true, RoleplayAccents = true,
	}
	for _, emote in ipairs(game.ns.Lexicon.emoteOrder) do
		expected["SLASH_JUJU_EMOTE_" .. string.upper(emote) .. "1"] = true
	end
	local mockGlobals = {}
	for key in pairs(Mock.new().env) do mockGlobals[key] = true end
	local stray = {}
	for key in pairs(game.env) do
		if not expected[key] and not mockGlobals[key] then
			stray[#stray + 1] = key
		end
	end
	table.sort(stray)
	check("no stray globals", table.concat(stray, ", "), "")
	for key in pairs(expected) do
		check("global exists: " .. key, game.env[key] ~= nil, true)
	end
end

---------------------------------------------------------------------------

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
