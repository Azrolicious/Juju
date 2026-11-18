-- Builds Words.lua, the English word list Juju uses to tell a typo from a
-- real word. The addon itself never runs this. Run it again after adding
-- many new words to Lexicon.lua, or to use a different dictionary:
--
--     lua5.1 tools/build_words.lua [scowl-directory] [output-file]
--
-- It reads SCOWL (Spell Checker Oriented Word Lists), which Debian and Ubuntu
-- ship as the "scowl" package in /usr/share/dict/scowl. SCOWL sorts English
-- words into sizes: 10 holds the commonest few thousand, 20 the next most
-- common, and so on up to very rare words.
--
-- Every word in Words.lua carries a rank:
--   1  size 10       the commonest words
--   2  size 20       common words
--   3  size 35       ordinary words (shield, tavern, warrior)
--   9  sizes 40-80   real but rare words, and common first and last names.
--                    Juju never offers these as a guess; they are listed
--                    so it leaves them alone.
--
-- Only those rare words that sit one slip away from a commoner word are kept.
-- The rest could never be mistaken for a typo, so leaving them out keeps the
-- file small. That check is done by running Juju's own Spell.lua.

local root = (arg and arg[0] or "tools/build_words.lua"):match("^(.*)[/\\]tools[/\\][^/\\]+$") or "."
local scowl = arg and arg[1] or "/usr/share/dict/scowl"
local outputPath = arg and arg[2] or (root .. "/Words.lua")

local SPELLINGS = { "english", "american", "british", "british_z" }
local RANKED = { { rank = 1, sizes = { 10 } }, { rank = 2, sizes = { 20 } }, { rank = 3, sizes = { 35 } } }
local RARE_SIZES = { 40, 50, 55, 60, 70, 80 }
local NAME_SIZES = { 10, 20, 35, 40, 50, 55, 60, 70, 80 }
local RARE = 9

-- Real words, but nothing Juju should ever turn a typo into.
local NEVER_GUESS = {
	arse = true, ass = true, rape = true, raped = true, rapes = true, raping = true,
	rapist = true, rapists = true, sex = true, sexy = true, suicide = true, suicides = true,
}

-- Calls each(word) for every plain lowercase word in the given sizes that
-- has not been seen before. No names, no apostrophes, no accents.
local seen = {}
local function readSizes(sizes, each)
	for _, size in ipairs(sizes) do
		for _, spelling in ipairs(SPELLINGS) do
			local file = io.open(scowl .. "/" .. spelling .. "-words." .. size, "r")
			if file then
				for line in file:lines() do
					if line:find("^[a-z]+$") and not seen[line] then
						seen[line] = true
						each(line)
					end
				end
				file:close()
			end
		end
	end
end

local rankOf, counts = {}, {}
for _, tier in ipairs(RANKED) do
	counts[tier.rank] = 0
	readSizes(tier.sizes, function(word)
		rankOf[word] = NEVER_GUESS[word] and RARE or tier.rank
		counts[rankOf[word]] = (counts[rankOf[word]] or 0) + 1
	end)
end
assert(counts[1] > 0, "no SCOWL word lists found in " .. scowl)

-- Load Juju's own spelling code knowing only the ranked words, and ask it
-- about every rare word. Any it would "correct" has to be listed as real.
local ns = {}
assert(loadfile(root .. "/Lexicon.lua"))("Juju", ns)
ns.Words = { unpacked = rankOf }
assert(loadfile(root .. "/Spell.lua"))("Juju", ns)

local rare, checked = {}, 0
local function checkRare(word)
	checked = checked + 1
	if NEVER_GUESS[word] or ns.Spell.Correct(word) then
		rare[#rare + 1] = word
	end
end
readSizes(RARE_SIZES, checkRare)

-- Names typed in small letters ("bert", "rita") must not be "corrected".
for _, size in ipairs(NAME_SIZES) do
	for _, spelling in ipairs(SPELLINGS) do
		local file = io.open(scowl .. "/" .. spelling .. "-proper-names." .. size, "r")
		if file then
			for line in file:lines() do
				if line:find("^[A-Z][a-z]+$") then
					local word = line:lower()
					if not seen[word] then
						seen[word] = true
						checkRare(word)
					end
				end
			end
			file:close()
		end
	end
end
for _, word in ipairs(rare) do
	rankOf[word] = RARE
end
counts[RARE] = (counts[RARE] or 0) + #rare

-- Pack: one string per first letter and length, each word followed by its
-- rank digit. Spell.lua searches these strings directly.
local buckets, keys = {}, {}
local words = {}
for word in pairs(rankOf) do
	words[#words + 1] = word
end
table.sort(words)
for _, word in ipairs(words) do
	local key = word:sub(1, 1) .. #word
	if not buckets[key] then
		buckets[key] = {}
		keys[#keys + 1] = key
	end
	table.insert(buckets[key], word .. rankOf[word])
end
table.sort(keys, function(a, b)
	if a:sub(1, 1) ~= b:sub(1, 1) then
		return a < b
	end
	return tonumber(a:sub(2)) < tonumber(b:sub(2))
end)

local out = assert(io.open(outputPath, "w"))
out:write([[
-- Juju's English word list. This file is made by tools/build_words.lua.
-- Do not edit it by hand: change the script and run it again.
--
-- Juju uses it to tell a typo from a real word (see Spell.lua).
--
-- Each entry is named after a first letter and a word length, and holds
-- every such word followed by a digit saying how common it is:
--   1, 2, 3   common words, which Juju may guess you meant
--   9         real but rare words, listed so Juju leaves them alone
--
-- The words come from SCOWL (Spell Checker Oriented Word Lists),
-- sizes 10 to 80. Copyright 2000-2011 by Kevin Atkinson. The full notice,
-- which must stay with this file, is in WORDS-LICENSE.txt.

local _, ns = ...

ns.Words = {
]])
for _, key in ipairs(keys) do
	out:write("\t", key, ' = "', table.concat(buckets[key]), '",\n')
end
out:write("}\n")
out:close()

print(("rank 1: %d, rank 2: %d, rank 3: %d, rare: %d (of %d checked), %d words in %d entries -> %s"):format(
	counts[1], counts[2], counts[3], counts[RARE], checked, #words, #keys, outputPath))
