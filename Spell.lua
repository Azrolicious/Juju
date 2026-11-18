-- Juju spelling: works out which word you meant when a finger slips.
--
-- This file uses no game functions, so it runs under a plain Lua 5.1.
--
-- The rule that matters most: a word that is already a real word is never
-- changed. Only a word nobody would recognise is looked at, and then only if
-- it is exactly one slip away from a common word:
--
--     abuot   -> about     two letters swapped
--     wory    -> worry     a letter missing
--     untill  -> until     a letter too many
--     kull    -> kill      the key next door
--     seperate -> separate the wrong vowel
--
-- If two words are equally likely, Juju does not guess. It leaves what you
-- typed alone.

local _, ns = ...
local Lex = ns.Lexicon

local S = {}
ns.Spell = S

local sub, find, gsub, gmatch, lower, byte = string.sub, string.find, string.gsub, string.gmatch, string.lower, string.byte

-- Shorter words have too many lookalikes to guess safely. The common ones
-- (teh, adn, yuo) are listed by hand in Lexicon.typos instead.
S.MIN_LENGTH = 4
S.MAX_LENGTH = 20
-- How much likelier the best guess must be than the next best. When two
-- guesses are close, Juju leaves the word alone rather than pick wrongly.
S.MARGIN = 2

-- Letters that sit next to each other on a QWERTY keyboard.
local NEIGHBOURS = {
	q = "wa", w = "qeas", e = "wrsd", r = "etdf", t = "ryfg", y = "tugh", u = "yihj",
	i = "uojk", o = "ipkl", p = "ol",
	a = "qwsz", s = "adwezx", d = "sferxc", f = "dgrtcv", g = "fhtyvb", h = "gjyubn",
	j = "hkuinm", k = "jliom", l = "kop",
	z = "asx", x = "zcsd", c = "xvdf", v = "cbfg", b = "vngh", n = "bmhj", m = "njk",
}
local VOWELS = "aeiou"
local ALPHABET = "abcdefghijklmnopqrstuvwxyz"

local function nextDoor(a, b)
	local row = NEIGHBOURS[a]
	return row ~= nil and b ~= "" and find(row, b, 1, true) ~= nil
end

-- How likely each kind of slip is. Lower is likelier.
local SWAPPED, DOUBLED, NEXT_DOOR, MISSING, VOWEL, EXTRA = 1, 2, 3, 4, 5, 6
-- A slip on the very first letter is rarer than one further in.
local FIRST_LETTER = 2

-- How common a word is. A guess must be a word Juju has its own troll for
-- (rank 0) or one from the first three lists in Words.lua (ranks 1 to 3).
-- Rank 9 marks real words that are never offered as a guess.
local GUESSABLE = 3
local REAL_ONLY = 9

---------------------------------------------------------------------------
-- The word list
---------------------------------------------------------------------------

-- Words.lua holds about 60,000 words. Loading them into an ordinary table
-- would cost several megabytes, so they stay packed as the file has them:
-- one string per first letter and word length, holding every such word
-- followed by its rank digit, for example  a4 = "able1ably3aced9..."
-- Looking a word up is a plain search of one of those strings.
local packed

local special       -- words from Lexicon.lua: word -> 0 or 9
local cache = {}    -- typed word -> the guess, or false
local cached = 0
local CACHE_LIMIT = 4000

local function packedRank(word)
	if not packed then
		return nil
	end
	-- The build script hands the words over unpacked, to save itself time.
	if packed.unpacked then
		return packed.unpacked[word]
	end
	local length = #word
	local bucket = packed[sub(word, 1, 1) .. length]
	if bucket then
		-- Every entry is the same width, so a match can only be a whole word.
		local at = find(bucket, word, 1, true)
		if at then
			return byte(bucket, at + length) - 48
		end
	end
	return nil
end

local function rankOf(word)
	return special[word] or packedRank(word)
end

-- Every run of letters in a piece of text is a real word.
local function real(text)
	for word in gmatch(lower(text), "%a+") do
		if not special[word] and not packedRank(word) then
			special[word] = REAL_ONLY
		end
	end
end

-- Built the first time a word needs checking, not when the game loads.
local function load()
	packed = ns.Words
	special = {}

	for _, list in ipairs({ Lex.accent, Lex.vocab, Lex.roles }) do
		for english, said in pairs(list) do
			real(said) -- troll words are words too
		end
	end
	for _, phrase in ipairs(Lex.phrases) do
		real(phrase[2])
	end
	for _, list in ipairs({ Lex.keep, Lex.noPlural }) do
		for word in pairs(list) do
			real(word)
		end
	end
	real(Lex.jargon or "")
	-- Whatever a contraction, shorthand or listed typo stands for is real.
	for _, list in ipairs({ Lex.contractions or {}, Lex.typos or {} }) do
		for typed, meant in pairs(list) do
			real(typed)
			real(meant)
		end
	end

	-- Words Juju translates specially are the likeliest things you meant.
	for _, list in ipairs({ Lex.accent, Lex.vocab, Lex.roles }) do
		for english in pairs(list) do
			if find(english, "^%a+$") then
				special[english] = 0
			end
		end
	end

	-- Plurals of class and role words are real words too: paladins, rogues.
	for role in pairs(Lex.roles or {}) do
		if not special[role .. "s"] and not packedRank(role .. "s") then
			special[role .. "s"] = REAL_ONLY
		end
	end

	-- Curse words are real words, but never a guess: Juju must not turn a
	-- slip of the finger into swearing.
	for swear, said in pairs(Lex.swears or {}) do
		real(said)
		special[swear] = REAL_ONLY
	end
end

-- Call this after changing the word lists while the game is running.
function S.Rebuild()
	special = nil
	cache = {}
	cached = 0
end

-- True for any word Juju recognises as real.
function S.IsKnown(word)
	if not special then
		load()
	end
	return rankOf(word) ~= nil
end

---------------------------------------------------------------------------
-- Is it troll already?
---------------------------------------------------------------------------

-- "fightin", "betta", "tink" and "bodda" are not English, but they are not
-- typos either: they are what the sound rules in Translator.lua produce.
-- Undo those rules and see whether a real word falls out.
local function alreadyTroll(word)
	local seen = { [word] = true }
	local forms = { word }
	local function add(form)
		if not seen[form] then
			seen[form] = true
			forms[#forms + 1] = form
		end
	end
	local function each(change)
		for index = 1, #forms do
			change(forms[index])
		end
	end

	each(function(form)                       -- huntas -> hunta, tings -> ting
		if sub(form, -1) == "s" then
			add(sub(form, 1, -2))
		end
	end)
	each(function(form)                       -- fightin -> fighting, betta -> better
		if sub(form, -2) == "in" then
			add(form .. "g")
		elseif sub(form, -1) == "a" then
			add(sub(form, 1, -2) .. "er")
		end
	end)
	each(function(form)                       -- wedder -> weather, bodder -> bother
		if find(form, "edd", 1, true) then
			add((gsub(form, "edd", "eath")))
		end
		if find(form, "dd", 1, true) then
			add((gsub(form, "dd", "th")))
		end
		if find(form, "rd", 1, true) then
			add((gsub(form, "rd", "rth")))
		end
	end)
	each(function(form)                       -- tink -> think, teet -> teeth
		if find(form, "t", 1, true) then
			add((gsub(form, "t", "th")))
			local from = 1
			while true do
				local at = find(form, "t", from, true)
				if not at then
					break
				end
				add(sub(form, 1, at - 1) .. "th" .. sub(form, at + 1))
				from = at + 1
			end
		end
	end)

	for index = 2, #forms do
		if rankOf(forms[index]) then
			return true
		end
	end
	return false
end

-- Stretched words and laughter are meant to look odd: nooo, heeey, grrr,
-- hahaha, mwahaha.
local function isNoise(word)
	return find(word, "(%a)%1%1") ~= nil
		or find(word, "haha", 1, true) ~= nil
		or find(word, "hehe", 1, true) ~= nil
		or find(word, "^[ahe]+$") ~= nil
end

---------------------------------------------------------------------------
-- Guessing
---------------------------------------------------------------------------

local function guess(word)
	local length = #word
	local scores = {} -- candidate -> its best score; lower is likelier

	local function consider(candidate, kind, position)
		if scores[candidate] == false then
			return -- looked up already: not a word we may guess
		end
		local commonness = rankOf(candidate)
		if not commonness or commonness > GUESSABLE then
			scores[candidate] = false
			return
		end
		if position == 1 then
			kind = kind + FIRST_LETTER
		end
		-- Words Juju has troll for count as common, but are not preferred over
		-- other common words.
		local score = math.max(commonness, 1) * 10 + kind
		if not scores[candidate] or score < scores[candidate] then
			scores[candidate] = score
		end
	end

	for i = 1, length do
		local before, letter, after = sub(word, 1, i - 1), sub(word, i, i), sub(word, i + 1)
		local previous, following = sub(word, i - 1, i - 1), sub(word, i + 1, i + 1)

		-- two letters swapped: abuot -> about
		if i < length and letter ~= following then
			consider(before .. following .. letter .. sub(word, i + 2), SWAPPED)
		end

		-- a letter too many: untill -> until, thje -> the
		local kind = EXTRA
		if letter == previous or letter == following then
			kind = DOUBLED
		elseif nextDoor(letter, previous) or nextDoor(letter, following) then
			kind = NEXT_DOOR
		end
		consider(before .. after, kind, i)

		-- the key next door: kull -> kill
		local row = NEIGHBOURS[letter]
		for k = 1, #row do
			consider(before .. sub(row, k, k) .. after, NEXT_DOOR, i)
		end

		-- the wrong vowel: seperate -> separate
		if find(VOWELS, letter, 1, true) then
			for k = 1, #VOWELS do
				local vowel = sub(VOWELS, k, k)
				if vowel ~= letter then
					consider(before .. vowel .. after, VOWEL, i)
				end
			end
		end
	end

	-- a letter missing: wory -> worry, frend -> friend
	for i = 0, length do
		local before, after = sub(word, 1, i), sub(word, i + 1)
		local previous, following = sub(word, i, i), sub(word, i + 1, i + 1)
		for k = 1, #ALPHABET do
			local letter = sub(ALPHABET, k, k)
			local kind = (letter == previous or letter == following) and DOUBLED or MISSING
			consider(before .. letter .. after, kind, i + 1)
		end
	end

	-- The likeliest candidate wins, but only if nothing else comes close.
	local best, bestScore, secondScore
	for candidate, score in pairs(scores) do
		if not score then
			-- not a candidate
		elseif not bestScore or score < bestScore then
			best, secondScore, bestScore = candidate, bestScore, score
		elseif not secondScore or score < secondScore then
			secondScore = score
		end
	end
	if best and (not secondScore or secondScore - bestScore > S.MARGIN) then
		return best
	end
	return nil
end

-- Correct(word) -> the word you probably meant, or nil to leave it alone.
-- The word must be lowercase letters only.
function S.Correct(word)
	local known = cache[word]
	if known ~= nil then
		return known or nil
	end
	if not special then
		load()
	end

	local result = false
	local length = #word
	if length >= S.MIN_LENGTH and length <= S.MAX_LENGTH
		and find(word, "^[a-z]+$") and not rankOf(word)
		and not isNoise(word) and not alreadyTroll(word) then
		result = guess(word)
		-- fihgters -> fighters: guess the word without its s, then put it back
		if not result and length > S.MIN_LENGTH and sub(word, -1) == "s" and sub(word, -2, -2) ~= "s" then
			local single = sub(word, 1, -2)
			if not rankOf(single) and not alreadyTroll(single) then
				local meant = guess(single)
				result = meant and (meant .. "s")
			end
		end
		result = result or false
	end

	if cached >= CACHE_LIMIT then
		cache, cached = {}, 0
	end
	cache[word] = result
	cached = cached + 1
	return result or nil
end
