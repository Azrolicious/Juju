-- Juju translator: English in, troll out.
--
-- This file uses no game functions at all, so it can be run and tested with
-- a plain Lua 5.1 interpreter (see tests/run.lua).
--
-- How one message is handled:
--   1. Anything that must arrive untouched is fenced off: item and spell
--      links, raid markers like {skull}, web addresses, ((out of character))
--      remarks and *actions*.
--   2. What is left is cut into words and the gaps between them.
--   3. Sloppy typing is tidied into the English that was meant: "dont"
--      becomes "don't", "teh" becomes "the", "frend" becomes "friend".
--   4. Each word is looked up: phrases first, then the word lists in
--      Lexicon.lua, then the sound rules further down in this file.
--      "is", "are" and "am" all become "be", and so does the 's of "it's".
--   5. Capital letters are put back the way they were typed.

local _, ns = ...
local Lex = ns.Lexicon
local Spell = ns.Spell -- the typo guesser; the translator works without it

local T = {}
ns.Translator = T

local find, sub, gsub, match, gmatch = string.find, string.sub, string.gsub, string.match, string.gmatch
local lower, upper = string.lower, string.upper
local concat, sort = table.concat, table.sort

-- A chat message can show at most this many bytes.
T.MAX_BYTES = 255

-- Text matching any of these is passed through exactly as typed. When two
-- patterns match at the same place, the one listed first wins.
local PROTECTED = {
	"|c.-|r",              -- coloured text, which is how item and spell links arrive
	"|H.-|h.-|h",          -- a bare link
	"|T.-|t",              -- an inline icon
	"|A.-|a",              -- an inline atlas icon
	"|K.-|k",              -- a hidden Battle.net name
	"%b{}",                -- raid markers: {skull}, {rt8}
	"%(%(.-%)%)",          -- ((out of character))
	"%(%(.*",              -- ((out of character, never closed
	"%*[^%*]+%*",          -- *an action*
	"[A-Za-z]+://%S+",     -- a web address
	"www%.%S+",
}

-- Contraction endings. 're and 'm mean "are" and "am", so they become
-- " be": you're -> ya be, I'm -> I be. 's depends on the word before it (see
-- Lexicon.isWords). The rest stay as they are: dey'll, ya've, I'd.
local SUFFIX = {
	["'s"] = "'s", ["'re"] = " be", ["'m"] = " be",
	["'ll"] = "'ll", ["'ve"] = "'ve", ["'d"] = "'d",
}

-- inName: the word is part of a creature or place name, where class and
-- role words are left as they are.
local function lookup(word, opts, inName)
	if opts.vocab then
		local voice = opts.voice
		local found = (voice and voice.words and voice.words[word]) or (not inName and Lex.roles[word])
			or Lex.vocab[word] or Lex.swears[word]
		if found then
			return found
		end
	end
	return Lex.accent[word]
end

---------------------------------------------------------------------------
-- Sound rules: the accent for words that are not in the word lists.
---------------------------------------------------------------------------

-- Endings after which a "ther" turns into "dder": bother, bothering,
-- bothered. Anywhere else (ethereal, otherworldly) it is just "t".
local THER_ENDINGS = { "", "ing", "ed" }

local function soundRules(word)
	if #word < 3 then
		return word
	end
	-- "th" between vowels: weather -> wedda, father -> fadda, bother -> bodda
	for _, ending in ipairs(THER_ENDINGS) do
		word = gsub(word, "eather" .. ending .. "$", "edder" .. ending)
		word = gsub(word, "([aeiou])ther" .. ending .. "$", "%1dder" .. ending)
		word = gsub(word, "rther" .. ending .. "$", "rder" .. ending)
	end
	-- "th" at the end: both -> bot', teeth -> teet', mouth -> mout'
	word = gsub(word, "th$", "t'")
	-- any other "th": think -> tink, three -> tree, thunder -> tunda
	word = gsub(word, "th", "t")
	if #word >= 5 and find(word, "[aeiouy].*ing$") then
		-- fighting -> fightin' (but not king, bring or string)
		word = sub(word, 1, -4) .. "in'"
	elseif #word >= 4 and find(word, "[^aeiou']er$") then
		-- hunter -> hunta, never -> neva (but not beer or deer)
		word = sub(word, 1, -3) .. "a"
	end
	return word
end

-- One lowercase word with no apostrophes in it.
-- Names, places and game words from Lexicon.jargon keep their spelling:
-- "thrall" stays thrall, not trall. ("Mangle names too" lets them go.)
local jargon

-- mob is set for a word of a creature's name: such a word is never kept
-- back as a game word, and mob == "whole" means it is the name's own
-- spelling, so a final s is not a plural (Defias, not Defia + s).
local function plainWord(word, opts, mob)
	local found = lookup(word, opts, mob)
	if found then
		return found
	end
	if not jargon then
		jargon = {}
		for name in gmatch(Lex.jargon or "", "%a+") do
			jargon[lower(name)] = true
		end
	end
	if Lex.keep[word] or (jargon[word] and not opts.names and not mob) then
		return word
	end

	-- Plurals and "he kills": the sound rules work on the word without its s,
	-- then the s goes back on: hunters -> huntas, things -> tings,
	-- curses -> hexes, rogues -> backstabbas
	if #word >= 4 and sub(word, -1) == "s" and not Lex.noPlural[word] and mob ~= "whole" then
		local before = sub(word, -2, -2)
		local stem = sub(word, 1, -2)
		if before ~= "s" and before ~= "u" and before ~= "i" and find(stem, "[aeiouy]") then
			local single = lookup(stem, opts, mob)
			if not single and sub(stem, -1) == "e" then
				-- bosses -> boss, enemies -> enemy
				single = lookup(sub(stem, 1, -2), opts, mob)
				if not single and sub(stem, -2) == "ie" then
					single = lookup(sub(stem, 1, -3) .. "y", opts, mob)
				end
			end
			if not single then
				-- Not in the word lists: the word keeps its own plural.
				-- (months -> mont' -> monts, beings -> bein' -> beins)
				single = Lex.keep[stem] and stem or (gsub(soundRules(stem), "'$", ""))
				return single .. "s"
			end
			single = gsub(single, "'$", "")
			if find(single, "[sxz]$") or find(single, "[cs]h$") then
				return single .. "es"
			end
			return single .. "s"
		end
	end

	return soundRules(word)
end

-- One lowercase word that is not in the word lists as typed. following is
-- the next word, if there is one: it tells "he's got" (has) from "he's
-- here" (is).
local function anyWord(word, opts, mob, following)
	local stem, ending = match(word, "^([a-z]+)('[a-z]+)$")
	if stem then
		local trolly = SUFFIX[ending]
		if trolly then
			local said = plainWord(stem, opts, mob and "whole")
			if ending == "'s" and Lex.isWords and Lex.isWords[stem] then
				-- it's -> it be, what's -> wha' be, but he's got -> he got
				if following and Lex.hasWords and Lex.hasWords[following] then
					return said
				end
				return said .. " be"
			end
			if trolly == " be" then
				return said .. trolly -- you're -> ya be, they're -> dey be
			end
			-- Thrall's -> Thrall's, they'll -> dey'll, you've -> ya've
			-- (somethin's, not somethin''s)
			return (gsub(said, "'$", "")) .. trolly
		end
		return word -- don't, lok'tar, o'clock
	end
	if find(word, "'", 1, true) then
		return word
	end
	return plainWord(word, opts, mob)
end

---------------------------------------------------------------------------
-- Capital letters
---------------------------------------------------------------------------

local function caseOf(word)
	if find(word, "^[A-Z]") then
		if #word > 1 and not find(word, "[a-z]") then
			return "upper"
		end
		return "cap"
	end
	return "lower"
end

local function applyCase(text, case)
	if case == "upper" then
		return upper(text)
	elseif case == "cap" then
		return (gsub(text, "[A-Za-z]", upper, 1))
	end
	return text
end

---------------------------------------------------------------------------
-- Words and gaps
---------------------------------------------------------------------------

-- Cuts text into tokens. A word token has .lw (its lowercase form); anything
-- else is a gap. A trailing apostrophe ("goin'") belongs to the gap.
local function tokenize(text)
	local tokens = {}
	local pos, len = 1, #text
	while pos <= len do
		local first, last = find(text, "[A-Za-z\128-\255][A-Za-z'\128-\255]*", pos)
		if not first then
			tokens[#tokens + 1] = { text = sub(text, pos) }
			break
		end
		if first > pos then
			tokens[#tokens + 1] = { text = sub(text, pos, first - 1) }
		end
		local word, tail = match(sub(text, first, last), "^(.-)('*)$")
		local token = { text = word, lw = lower(word) }
		-- A word that already starts with a dropped letter ('bout, 'round, 'cause)
		-- is troll already. Leave it be.
		if first > 1 and sub(text, first - 1, first - 1) == "'"
			and (first == 2 or not find(sub(text, first - 2, first - 2), "[A-Za-z]")) then
			token.troll = true
		end
		tokens[#tokens + 1] = token
		if tail ~= "" then
			tokens[#tokens + 1] = { text = tail }
		end
		pos = last + 1
	end
	return tokens
end

---------------------------------------------------------------------------
-- Sloppy typing
---------------------------------------------------------------------------

-- The ; key sits right beside the ' key: don;t -> don't, i;m -> i'm
local function fixSemicolons(text)
	if not find(text, ";", 1, true) then
		return text
	end
	text = gsub(text, "([A-Za-z]);([tTsSmMdD])%f[^A-Za-z]", "%1'%2")
	text = gsub(text, "([A-Za-z]);([lL][lL])%f[^A-Za-z]", "%1'%2")
	text = gsub(text, "([A-Za-z]);([rRvV][eE])%f[^A-Za-z]", "%1'%2")
	return text
end

-- Turns each word into the English that was meant, before anything is
-- translated. One typed word can become several ("alot" -> "a lot"), so this
-- returns a new list of tokens. Tidied tokens are marked .fixed.
local function tidy(tokens, opts)
	local tidied = {}
	for _, token in ipairs(tokens) do
		local lw = token.lw
		local meant, case
		local own = opts.words and opts.words.single[lw]
		if own ~= nil and not token.troll then
			token.own = own -- one of the player's own words: hands off
		elseif lw and opts.keepCapitals and not token.mob and find(token.text, "^[A-Z]") then
			token.name = true -- game text: a capital letter marks a name
		elseif lw and not token.troll and not find(lw, "[\128-\255]") then
			case = caseOf(token.text)
			local known = opts.isName ~= nil and opts.isName(lw)
			-- Someone you know. In small letters it is only their name if it
			-- is not also an ordinary word: "grukk" is Grukk, "hunter" is a hunter.
			if known and (case ~= "lower" or not (lookup(lw, opts) or Lex.contractions[lw]
				or Lex.typos[lw] or (Spell and Spell.IsKnown(lw)))) then
				token.name = true -- somebody nearby: hands off
			else
				meant = Lex.contractions[lw] or Lex.typos[lw]
				if not meant and find(lw, "'nt$") then
					meant = gsub(lw, "'nt$", "n't") -- do'nt -> don't
				end
				-- Guesses are only made for words typed all in small letters.
				-- A capital usually means a name, and all capitals usually
				-- mean an abbreviation.
				if not meant and opts.guess and Spell and case == "lower" and not known then
					meant = Spell.Correct(lw)
				end
			end
		end
		if meant then
			local first = true
			for part in gmatch(meant, "%S+") do
				local shown = part
				if case == "upper" then
					shown = upper(part)
				elseif case == "cap" and first then
					shown = applyCase(part, "cap")
				end
				if not first then
					tidied[#tidied + 1] = { text = " " }
				end
				tidied[#tidied + 1] = { text = shown, lw = lower(part), fixed = true, origin = token }
				first = false
			end
		else
			tidied[#tidied + 1] = token
		end
	end
	return tidied
end

local function isSpace(token)
	return token and not token.lw and find(token.text, "^%s+$") ~= nil
end

local function isWord(token, ownAllowed)
	return token and token.lw and not token.troll and (ownAllowed or token.own == nil)
end

---------------------------------------------------------------------------
-- Phrases
---------------------------------------------------------------------------

local phraseIndex

local function buildPhraseIndex()
	phraseIndex = {}
	for _, phrase in ipairs(Lex.phrases) do
		local words = {}
		for word in gmatch(phrase[1], "%S+") do
			words[#words + 1] = word
		end
		local list = phraseIndex[words[1]]
		if not list then
			list = {}
			phraseIndex[words[1]] = list
		end
		local notBefore
		if phrase.notBefore then
			notBefore = {}
			for word in gmatch(phrase.notBefore, "%S+") do
				notBefore[word] = true
			end
		end
		list[#list + 1] = {
			words = words,
			text = phrase[2],
			vocab = phrase.vocab,
			needsNext = phrase.needsNext,
			notBefore = notBefore,
		}
	end
	for _, list in pairs(phraseIndex) do
		sort(list, function(a, b) return #a.words > #b.words end)
	end
end

-- Call this after changing Lexicon.lua while the game is running.
function T.Rebuild()
	phraseIndex = nil
	jargon = nil
	if Spell then
		Spell.Rebuild()
	end
end

-- Returns how many tokens the phrase starting at tokens[i] covers, and its
-- troll form. Returns nil when no phrase starts there.
local function matchPhrase(tokens, i, opts, index, own)
	local list = index[tokens[i].lw]
	if not list then
		return nil
	end
	for _, phrase in ipairs(list) do
		if not phrase.vocab or opts.vocab then
			local last, matched = i, true
			for k = 2, #phrase.words do
				local nextWord = tokens[last + 2]
				if isSpace(tokens[last + 1]) and isWord(nextWord, own) and nextWord.lw == phrase.words[k]
					and not (opts.keepCapitals and nextWord.name) then
					last = last + 2
				else
					matched = false
					break
				end
			end
			if matched and phrase.needsNext then
				matched = isSpace(tokens[last + 1]) and tokens[last + 2] ~= nil and tokens[last + 2].lw ~= nil
			end
			if matched and phrase.notBefore then
				-- "going to kill" is gonna kill, but "going to the inn" and
				-- "going to Orgrimmar" are a trip, not a plan.
				local after = isSpace(tokens[last + 1]) and tokens[last + 2]
				if after and after.lw and (phrase.notBefore[after.lw] or find(after.text, "^%u")) then
					matched = false
				end
			end
			if matched and phrase.keep then
				-- kept exactly as typed
				local typed = {}
				for k = i, last do
					typed[#typed + 1] = tokens[k].text
				end
				return last - i + 1, concat(typed)
			end
			if matched then
				local shouted, letters = true, 0
				for k = i, last, 2 do
					letters = letters + #tokens[k].text
					if find(tokens[k].text, "[a-z]") then
						shouted = false
					end
				end
				local case = "lower"
				if shouted and letters > 1 then
					case = "upper"
				elseif find(tokens[i].text, "^[A-Z]") then
					case = "cap"
				end
				return last - i + 1, applyCase(phrase.text, case)
			end
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- One word in context
---------------------------------------------------------------------------

local function translateWord(tokens, i, state, opts)
	local token = tokens[i]
	local word, lw = token.text, token.lw

	-- Already troll, or not English letters at all: leave it alone.
	if token.troll or find(word, "[\128-\255]") then
		return word
	end

	-- One of the player's own words: false means keep it as typed.
	if token.own == false then
		return word
	elseif token.own then
		return applyCase(token.own, caseOf(word))
	end

	-- The names of people around you are never mangled.
	if token.name then
		return word
	end

	local case = caseOf(word)

	-- "No!" and "No, ..." become "Nah". "No way" and "no gold" stay put.
	if lw == "no" then
		local after = tokens[i + 1]
		if state.atStart and (not after or (not after.lw and find(after.text, "^[,%.!]"))) then
			return applyCase("nah", case)
		end
		return word
	end

	local found = lookup(lw, opts, token.mob)
	if found then
		return applyCase(found, case)
	end

	-- A capital letter in the middle of a sentence, or a first word followed
	-- by a comma ("Grokk, come here"), is most likely somebody's name.
	-- (A word that had to be tidied is known to be a word, not a name.)
	-- (A known creature's name is not a person's name: it gets the accent.)
	if case == "cap" and not opts.names and not token.fixed and not token.mob then
		local after = tokens[i + 1]
		if not state.atStart or (after and not after.lw and find(after.text, "^,")) then
			return word -- Thrall, Thrall's
		end
	end

	-- The next word, if only a space comes between.
	local following = isSpace(tokens[i + 1]) and tokens[i + 2] and tokens[i + 2].lw or nil

	if token.mob then
		local trolly = anyWord(lw, opts, token.mob, following)
		-- Nothing to change: keep the name exactly as written (Mor'Ladim).
		if trolly == lw then
			return word
		end
		return applyCase(trolly, case)
	end

	return applyCase(anyWord(lw, opts, nil, following), case)
end

---------------------------------------------------------------------------
-- Stretches of text
---------------------------------------------------------------------------

-- Plain speech: no links, no markers.
-- What was typed for tokens first..last, as lowercase-ready English with
-- single spaces. A tidied token points back at the token it came from, so
-- "alot" comes back as "alot" and not as "a lot".
local function typedOf(tokens, first, last)
	local parts, previous = {}, nil
	for k = first, last do
		local token = tokens[k]
		if token.lw then
			local origin = token.origin or token
			if origin ~= previous then
				parts[#parts + 1] = origin.text
				previous = origin
			end
		end
	end
	return concat(parts, " ")
end

---------------------------------------------------------------------------
-- Creature names
--
-- A capital letter in the middle of a sentence usually means a name, and
-- names are left alone. Creature names are the exception: "Hogger" and
-- "Harvest Watcher" get the accent like any other words. The names come
-- from T.PrepareMobs / T.AddMob (see Mobs.lua for where they are found).
---------------------------------------------------------------------------

-- PrepareMobs() -> an empty list of creature names for opts.mobs.
function T.PrepareMobs()
	return { count = 0, known = {}, byFirst = {} }
end

-- AddMob(mobs, "Harvest Watcher") -> true if the name was new.
function T.AddMob(mobs, name)
	if type(name) ~= "string" then
		return false
	end
	local words = {}
	for word in gmatch(lower(name), "[%a\128-\255][%a'\128-\255]*") do
		words[#words + 1] = (gsub(word, "'+$", ""))
	end
	local key = concat(words, " ")
	if #words == 0 or #words > 6 or #key < 3 or mobs.known[key] then
		return false
	end
	mobs.known[key] = true
	mobs.count = mobs.count + 1
	-- Each list is kept longest name first, so the longest match wins.
	local list = mobs.byFirst[words[1]]
	if not list then
		list = {}
		mobs.byFirst[words[1]] = list
	end
	local at = #list + 1
	for index, other in ipairs(list) do
		local _, otherWords = gsub(other, " ", "")
		if otherWords < #words - 1 then
			at = index
			break
		end
	end
	table.insert(list, at, key)
	return true
end

-- Between the words of a creature name: spaces, a hyphen, a full stop.
local function isNameGap(token)
	return token ~= nil and not token.lw and find(token.text, "^[%s%-%.]+$") ~= nil
end

-- The last word of a name may be plural or possessive: Watchers, Hogger's.
local function endsName(lw, word)
	if lw == word then
		return true
	end
	return lw == word .. "s" or lw == word .. "es" or lw == word .. "'s"
		or (sub(word, -1) == "y" and lw == sub(word, 1, -2) .. "ies")
end

local function singular(lw)
	return (gsub(gsub(lw, "'s$", ""), "s$", "")), (gsub(lw, "es$", "")), (gsub(lw, "ies$", "y"))
end

-- Marks the words of every known name in tokens with .mob. With
-- ownSpelling, a word exactly as the name spells it keeps its final s
-- (creatures: Defias, not Defiaz). Place names do not: the Barrens are
-- da Barrenz.
local function markMobs(tokens, mobs, ownSpelling)
	local i, count = 1, #tokens
	while i <= count do
		local token = tokens[i]
		local last
		if token.lw and not token.troll then
			local lists = { mobs.byFirst[token.lw] }
			local a, b, c = singular(token.lw)
			for _, form in ipairs({ a, b, c }) do
				if form ~= token.lw then
					lists[#lists + 1] = mobs.byFirst[form]
				end
			end
			for _, list in ipairs(lists) do
				for _, name in ipairs(list) do
					local words = {}
					for word in gmatch(name, "%S+") do
						words[#words + 1] = word
					end
					local at, matched, exact = i, true, {}
					for k = 1, #words do
						local word, here = words[k], tokens[at]
						local isLast = k == #words
						if not here or not here.lw
							or not (here.lw == word or (isLast and endsName(here.lw, word))) then
							matched = false
							break
						end
						exact[here] = ownSpelling and here.lw == word
						if not isLast then
							if not isNameGap(tokens[at + 1]) then
								matched = false
								break
							end
							at = at + 2
						end
					end
					if matched then
						last = at
						for matchedToken, whole in pairs(exact) do
							if whole then
								matchedToken.mob = "whole"
							end
						end
						break
					end
				end
				if last then
					break
				end
			end
		end
		if last then
			for k = i, last do
				if tokens[k].lw then
					tokens[k].mob = tokens[k].mob or "part"
				end
			end
			i = last + 1
		else
			i = i + 1
		end
	end
end

local function translateSpeech(text, state, opts)
	local tokens = tokenize(fixSemicolons(text))
	if opts.mobs then
		markMobs(tokens, opts.mobs, true)
	end
	if opts.places then
		markMobs(tokens, opts.places, false)
	end
	tokens = tidy(tokens, opts)
	local out = {}
	local trace = opts.trace
	local i, count = 1, #tokens
	while i <= count do
		local token = tokens[i]
		if not token.lw then
			out[#out + 1] = token.text
			if find(token.text, "[%.!%?\n]") then
				state.atStart = true
			end
			i = i + 1
		else
			local used, phrase
			if not token.troll then
				if opts.words then
					used, phrase = matchPhrase(tokens, i, opts, opts.words.phrases, true)
				end
				if not used and token.own == nil then
					used, phrase = matchPhrase(tokens, i, opts, phraseIndex)
				end
			end
			local piece, last
			if used then
				piece, last = phrase, i + used - 1
			else
				piece, last = translateWord(tokens, i, state, opts), i
			end
			out[#out + 1] = piece
			if trace and not token.troll and piece ~= "" then
				trace[#trace + 1] = { english = typedOf(tokens, i, last), troll = piece }
			end
			i = last + 1
			state.atStart = false
		end
	end
	return concat(out)
end

-- Emotes: only the words inside "double quotes" are speech.
local function translateQuotes(text, state, opts)
	local out = {}
	local pos = 1
	while true do
		local quote = find(text, '"', pos, true)
		local piece = sub(text, pos, (quote or #text + 1) - 1)
		if state.inQuote then
			out[#out + 1] = translateSpeech(piece, state, opts)
		else
			out[#out + 1] = piece
		end
		if not quote then
			break
		end
		out[#out + 1] = '"'
		state.inQuote = not state.inQuote
		state.atStart = true
		pos = quote + 1
	end
	return concat(out)
end

local function translateMessage(text, opts)
	local state = { atStart = true, inQuote = false }
	local speech = opts.quotesOnly and translateQuotes or translateSpeech
	local out = {}
	local pos, len = 1, #text
	while pos <= len do
		local first, last
		for index = 1, #PROTECTED do
			local a, b = find(text, PROTECTED[index], pos)
			if a and (not first or a < first) then
				first, last = a, b
			end
		end
		if not first then
			out[#out + 1] = speech(sub(text, pos), state, opts)
			break
		end
		if first > pos then
			out[#out + 1] = speech(sub(text, pos, first - 1), state, opts)
		end
		local fenced = sub(text, first, last)
		out[#out + 1] = fenced
		local opener = sub(fenced, 1, 1)
		if opener == "(" or opener == "*" then
			state.atStart = true   -- speech starts afresh after an aside
		elseif opener ~= "{" then
			state.atStart = false  -- a link stands in for a word
		end
		pos = last + 1
	end
	return concat(out)
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------

local NO_OPTIONS = {}

-- True if the text says "mon" already.
local function hasMon(lowered)
	return find(lowered, "%f[%a]mon%f[%A]") ~= nil
end

-- About one message in this many hundred gets a flourish.
T.FLOURISH_CHANCE = 35

-- Adds an opener or a closer from Lexicon.flourishes, or nothing. typed is
-- the message as it was typed, used to keep clear of OOC remarks and
-- *actions* at either end.
local function flourish(out, typed, roll, voice)
	-- A voice's own lists, falling back to the usual ones for any it leaves out.
	local own = voice and voice.flourishes or {}
	local lists = {}
	for _, kind in ipairs({ "openers", "statements", "questions", "shouts" }) do
		lists[kind] = own[kind] or (Lex.flourishes and Lex.flourishes[kind])
		if not lists[kind] or #lists[kind] == 0 then
			return out
		end
	end
	if roll % 100 >= ((voice and voice.chance) or T.FLOURISH_CHANCE) then
		return out
	end
	-- A single word, or one that already says "mon" or starts with "hey", is
	-- left be.
	local _, wordCount = gsub(out, "%a+", "")
	local lowered = lower(out)
	if wordCount < 2 or hasMon(lowered) or find(lowered, "^%W*hey%f[%A]") then
		return out
	end

	local trimmed = gsub(gsub(typed, "^%s+", ""), "%s+$", "")
	local canOpen = not find(trimmed, "^%(%(") and not find(trimmed, "^%*")
	-- An OOC remark left open runs to the end, so nothing may go after it.
	local unclosed = find(gsub(trimmed, "%(%(.-%)%)", ""), "((", 1, true)
	local canClose = not find(trimmed, "%)%)$") and not find(trimmed, "%*$") and not unclosed
	local pick = math.floor(roll / 100)
	local useOpener = pick % 3 == 0
	if useOpener and not canOpen then
		useOpener = false
	elseif not useOpener and not canClose then
		useOpener = canOpen
	end
	if not canOpen and not canClose then
		return out
	end

	-- Shouting in capitals gets shouted flourishes.
	local shouting = find(out, "%a") and not find(out, "%l")
	local function shout(words)
		return shouting and upper(words) or words
	end

	local index = math.floor(pick / 3)
	if useOpener then
		local list = lists.openers
		local opener = list[index % #list + 1]
		-- A new sentence starts after the opener: 'ello -> 'Ello. Only a plain
		-- letter at the very start is touched, never a link or {marker}.
		local rest = gsub(gsub(out, "^%s+", ""), "^(['\"]*)(%l)", function(marks, letter)
			return marks .. upper(letter)
		end, 1)
		opener = shout(opener) .. " "
		return opener .. rest, #opener
	end

	local body, ending = match(out, "^(.-)([%.!%?]*)%s*$")
	body = gsub(body, "[,;:%s]+$", "")
	local list = lists.statements
	if find(ending, "?", 1, true) then
		list = lists.questions
	elseif find(ending, "!", 1, true) then
		list = lists.shouts
	end
	return body .. shout(list[index % #list + 1]) .. ending
end

-- PrepareWords({ [english] = troll or false }) -> a table for opts.words.
-- The English side is lowercase and may be several words ("for the horde").
-- false means "keep this exactly as typed" (good for names).
function T.PrepareWords(words)
	local prepared = { single = {}, phrases = {} }
	for english, said in pairs(words or {}) do
		if type(english) == "string" and (said == false or type(said) == "string") then
			local parts = {}
			for part in gmatch(lower(english), "[%a']+") do
				parts[#parts + 1] = part
			end
			if #parts == 1 then
				prepared.single[parts[1]] = said
			elseif #parts > 1 then
				local list = prepared.phrases[parts[1]]
				if not list then
					list = {}
					prepared.phrases[parts[1]] = list
				end
				list[#list + 1] = { words = parts, text = said or nil, keep = said == false }
			end
		end
	end
	for _, list in pairs(prepared.phrases) do
		sort(list, function(a, b) return #a.words > #b.words end)
	end
	return prepared
end

-- Curse words with symbols in them (f**k, sh1t, a$$) are written out, so
-- that the word list can turn them into troll. See Lexicon.disguised.
local function unmask(text)
	if not Lex.disguised or not find(text, "[%*%$@1]") then
		return text
	end
	local shouting = not find(text, "%l")
	for _, entry in ipairs(Lex.disguised) do
		local subject = text
		text = gsub(subject, "(" .. entry[1] .. ")()", function(found, after)
			local letters = gsub(found, "%A", "")
			if not find(letters, "^%u") then
				return entry[2]
			end
			-- F**K, or a lone capital in the middle of shouting (F***ING)
			if (#letters > 1 and not find(letters, "%l"))
				or (#letters == 1 and (shouting or find(sub(subject, after, after), "%u"))) then
				return upper(entry[2])
			end
			return applyCase(entry[2], "cap")
		end)
	end
	return text
end

-- True if out has a curse word in plain sight that typed did not.
local function spelledOutSwear(out, typed)
	local loweredOut, loweredTyped = lower(out), lower(typed)
	for _, entry in ipairs(Lex.disguised) do
		local whole = "%f[%a]" .. entry[2] .. "%f[%A]"
		if find(loweredOut, whole) and not find(loweredTyped, whole) then
			return true
		end
	end
	return false
end

local function clearTrace(trace)
	if trace then
		for key in pairs(trace) do
			trace[key] = nil
		end
	end
end

-- Translate(text, opts) -> text
--   opts.vocab       use the troll word list (Loa, juju, mojo) as well as the accent
--   opts.mon         add "mon" to a message that ends in "!" (meant for yells)
--   opts.quotesOnly  only translate inside "double quotes" (meant for emotes)
--   opts.names       give capitalised names the accent too
--   opts.guess       guess the word that was meant when one is mistyped
--   opts.words       the player's own words, from T.PrepareWords
--   opts.voice       a voice from Lexicon.voices: its own words and flourishes
--   opts.trace       an empty table. It is filled with one entry per
--                    translated word or phrase, in order:
--                    { english = what was typed, troll = what it became }.
--                    trace.offset is how many letters a flourish put in
--                    front. The Juju box uses this to make words clickable.
--   opts.mobs        known creature names, from T.PrepareMobs. They get the
--                    accent even with a capital letter, unlike other names.
--   opts.places      known place names, in the same form as opts.mobs.
--   opts.keepCapitals  leave every capitalised word as it is. For text the
--                    game wrote, where a capital marks the name of a
--                    creature, item or place ("Kobold Vermin slain").
--   opts.flourish    now and then add a troll opener or closer (see Lexicon.flourishes)
--   opts.roll        a whole number that decides the flourish. The same roll
--                    and text always give the same result, so a preview can
--                    show exactly what will be sent.
--   opts.isName      function(lowercaseWord) -> true for names to leave alone
--   opts.maxBytes    longest message allowed (default T.MAX_BYTES)
function T.Translate(text, opts)
	opts = opts or NO_OPTIONS
	local trace = opts.trace
	clearTrace(trace)
	if type(text) ~= "string" or not find(text, "%S") then
		return text
	end

	-- "! like this" sends the rest exactly as typed.
	local plain = match(text, "^!%s+(.*)$")
	if plain then
		return plain
	end
	-- Slash commands, "!keys" style addon commands and "OOC: ..." are not speech.
	if find(text, "^/") or find(text, "^![A-Za-z]") or find(text, "^%s*[Oo][Oo][Cc]%f[^A-Za-z]") then
		return text
	end

	if not phraseIndex then
		buildPhraseIndex()
	end

	-- Only with troll words on: otherwise the plain curse word would be sent.
	local source = opts.vocab and unmask(text) or text
	local out = translateMessage(source, opts)
	-- Juju must never send a line ruder than the one typed. If a word that
	-- was spelled out above did not get turned into troll after all (it landed
	-- inside an *action*, say), translate the line as it was typed instead.
	if source ~= text and spelledOutSwear(out, text) then
		clearTrace(trace)
		out = translateMessage(text, opts)
	end
	local limit = opts.maxBytes or T.MAX_BYTES

	-- If the troll version grew past what a chat message can hold, say it plain.
	if #out > limit and #out > #text then
		clearTrace(trace)
		return text
	end

	-- Emotes are narration, so they never get a flourish.
	if opts.flourish and opts.roll and not opts.quotesOnly then
		local fancier, opener = flourish(out, text, opts.roll, opts.voice)
		if #fancier <= limit then
			out = fancier
			if trace then
				trace.offset = opener or 0
			end
		end
	end

	-- A Headhunter puts "mon" on every yell; anyone else, on a yell ending
	-- in !  "Run!" -> "Run, mon!"  It goes before the last . ! or ?, so it is
	-- left off when the yell ends in an OOC remark or an *action*.
	local everyYell = opts.voice and opts.voice.alwaysMon
	if opts.mon and (everyYell or find(out, "!%s*$")) and not hasMon(lower(out)) then
		local body, ending = match(out, "^(.-)([%.!%?]*)%s*$")
		body = gsub(body, "[,;:%s]+$", "")
		if find(body, "%a") and not find(body, "[%)%*]$") then
			local shouting = not find(out, "%l")
			if ending == "" or ending == "." then
				ending = "!"
			end
			local louder = body .. (shouting and ", MON" or ", mon") .. ending
			if #louder <= limit then
				out = louder
			end
		end
	end

	return out
end
