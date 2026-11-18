-- Juju core: saved settings, who is a troll, and the /juju command.

local ADDON, ns = ...

local gsub, strfind = string.gsub, string.find

local TEAL = "|cff3fbfaf"
local PREFIX = TEAL .. "Juju|r: "

local function Print(message)
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. message)
end
ns.Print = Print

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------

-- Account-wide. JujuCharDB.mode is the only per-character setting.
local DEFAULTS = {
	channels = {
		say = true,
		yell = true,
		emote = true,
		party = true,
		raid = true,
		guild = true,
		whisper = true,
		bnet = false,
		-- numbered channels
		general = false,
		trade = false,
		lfg = false,
		other = false,
	},
	words = {},      -- the player's own words: english -> troll, or false to keep as typed
	vocab = true,    -- use troll words (Loa, juju, mojo), not just the accent
	mon = true,      -- add "mon" to yells that end in "!"
	names = false,   -- give capitalised names the accent too
	typos = true,    -- guess the word that was meant when one is mistyped
	flourish = false, -- now and then add a troll "Hey, mon!" or ", ya hear"
	questie = true,  -- say Questie's party announcements in troll
	preview = true,  -- show the troll version above the chat box while typing
	tag = true,      -- show a Troll/Plain tag above the chat line
	creatures = true, -- give creature names the accent (Hogger -> Hogga)
	mobs = {},       -- creature names met in the world: name -> true
	questieNames = {}, -- creature names read from QuestieDB, kept until it updates
	placeNames = true, -- give place names the accent (Thunder Bluff -> Tunda Bluff)
	knownPlaces = {}, -- zones and subzones visited: name -> true
	people = {},     -- guildmates' and friends' names, never Jujuified
	myEmotes = {},   -- your own emotes: name -> { text = ..., target = ... }
}
ns.DEFAULTS = DEFAULTS

-- Which setting covers which kind of chat. Kinds not listed are never touched.
local CHANNEL_OF = {
	SAY = "say",
	YELL = "yell",
	EMOTE = "emote",
	PARTY = "party",
	RAID = "raid",
	RAID_WARNING = "raid",
	INSTANCE_CHAT = "raid",
	BATTLEGROUND = "raid",
	GUILD = "guild",
	OFFICER = "guild",
	WHISPER = "whisper",
	BN_WHISPER = "bnet",
	-- CHANNEL depends on which channel it is: see channelKey
}

-- The numbered channels (/1, /2 ...), told apart by name. Channel names
-- arrive as "General - Durotar", "Trade - City" or "LookingForGroup".
local NUMBERED = { "general", "trade", "lfg", "other" }

local function channelKey(name)
	if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then
		return "other"
	end
	local base = strlower(strmatch(name, "^(.-)%s+%-%s") or name)
	base = gsub(base, "%s+", "")
	if base == "general" then
		return "general"
	elseif strmatch(base, "^trade") then
		return "trade"
	elseif base == "lookingforgroup" then
		return "lfg"
	end
	return "other"
end
ns.ChannelKey = channelKey

-- Which switch covers this kind of chat, or nil if Juju never touches it.
-- channelName is only needed for numbered channels.
function ns.ChannelKeyFor(chatType, channelName)
	if chatType == "CHANNEL" then
		return channelKey(channelName)
	end
	return CHANNEL_OF[chatType]
end

-- Order and labels for the settings panel and for "/juju <channel> on|off".
ns.CHANNELS = {
	{ key = "say", label = "Say" },
	{ key = "yell", label = "Yell" },
	{ key = "emote", label = "Emote (only the words inside \"quotes\")" },
	{ key = "party", label = "Party" },
	{ key = "raid", label = "Raid, raid warning and battleground" },
	{ key = "guild", label = "Guild and officer" },
	{ key = "whisper", label = "Whisper" },
	{ key = "bnet", label = "Battle.net whisper" },
	{ key = "general", label = "General channel" },
	{ key = "trade", label = "Trade channel" },
	{ key = "lfg", label = "LookingForGroup channel" },
	{ key = "other", label = "Other numbered channels (custom RP channels, local defense)" },
}

-- A channel's name without the explanation in brackets: "Emote", "Party".
function ns.ChannelLabel(key)
	for _, channel in ipairs(ns.CHANNELS) do
		if channel.key == key then
			return (gsub(channel.label, "%s*%(.*$", ""))
		end
	end
	return key
end

local function fillDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end
			fillDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end
end

---------------------------------------------------------------------------
-- On or off
---------------------------------------------------------------------------

function ns.IsTroll()
	local _, race = UnitRace("player")
	return race == "Troll" or race == "ZandalariTroll"
end

-- JujuCharDB.mode is "auto" (on for Troll characters), "on" or "off".
-- True when Juju would talk on this character, by its own settings alone.
function ns.IsSwitchedOn()
	if not ns.db then
		return false
	end
	local mode = JujuCharDB.mode
	if mode == "on" then
		return true
	elseif mode == "off" then
		return false
	end
	return ns.IsTroll()
end

---------------------------------------------------------------------------
-- Sharing a character with Krump, Juju and the like
--
-- Krump (Ork) and Juju (troll) both change what you type before it is
-- sent. If both changed the same message, the second would mangle the
-- first. So each one signs in to RoleplayAccents, and only one talks:
--   * Switching one on (/juju on, /krump on) switches the others off on
--     that character.
--   * If two are on anyway, the one made for the character's race talks.
--     When neither or both are, the one first in the alphabet does.
---------------------------------------------------------------------------

local function ask(other, question)
	local ok, answer = pcall(other[question])
	return ok and answer == true
end

-- The name of another accent addon that talks on this character instead
-- of Juju, or nil.
function ns.SpeakingInstead()
	local accents = type(RoleplayAccents) == "table" and RoleplayAccents or {}
	local native = ns.IsTroll()
	for name, other in pairs(accents) do
		if name ~= ADDON and type(other) == "table" and type(other.IsOn) == "function"
			and type(other.IsNative) == "function" and ask(other, "IsOn") then
			local theirs = ask(other, "IsNative")
			if (theirs and not native) or (theirs == native and name < ADDON) then
				return name
			end
		end
	end
	return nil
end

-- True when Juju is the one talking on this character.
function ns.IsActive()
	return ns.IsSwitchedOn() and ns.SpeakingInstead() == nil
end

-- Switches every other accent addon off on this character. Returns their
-- names.
local function switchOthersOff()
	local stopped = {}
	local accents = type(RoleplayAccents) == "table" and RoleplayAccents or {}
	for name, other in pairs(accents) do
		if name ~= ADDON and type(other) == "table" and type(other.IsOn) == "function"
			and type(other.SwitchOff) == "function" and ask(other, "IsOn") then
			pcall(other.SwitchOff)
			stopped[#stopped + 1] = name
		end
	end
	table.sort(stopped)
	return stopped
end

RoleplayAccents = type(RoleplayAccents) == "table" and RoleplayAccents or {}
RoleplayAccents[ADDON] = {
	IsOn = function() return ns.IsSwitchedOn() end,
	IsNative = function() return ns.IsTroll() end,
	SwitchOff = function() ns.SetMode("off", true) end,
}

-- Redraws whatever is showing a translation, after a setting changes.
function ns.Refresh()
	if ns.RefreshPreview then
		ns.RefreshPreview()
	end
	if ns.RefreshBox then
		ns.RefreshBox()
	end
end

function ns.SetMode(mode, quiet)
	JujuCharDB.mode = mode
	local stopped = mode == "on" and switchOthersOff() or {}
	ns.Refresh()
	if quiet then
		return
	end
	if #stopped > 0 then
		Print(table.concat(stopped, " and ") .. " switched off on this character, so only Juju talks.")
	end
	if ns.IsActive() then
		Print("Ya be talkin' like a true troll now, mon.")
	elseif ns.IsSwitchedOn() then
		Print("Waiting: " .. ns.SpeakingInstead() .. " is talking on this character. Type /juju on to switch to Juju.")
	elseif mode == "auto" then
		Print("Off. This character is not a troll. Type /juju on to talk like one anyway.")
	else
		Print("Off. You are talking plainly again.")
	end
end

function ns.Toggle()
	ns.SetMode(ns.IsActive() and "off" or "on")
end

---------------------------------------------------------------------------
-- Names to leave alone
---------------------------------------------------------------------------

local RECENT_LIMIT = 60
local recentNames, recentOrder = {}, {}
local groupNames = {}

local function nameKey(name)
	if type(name) ~= "string" or (issecretvalue and issecretvalue(name)) then
		return nil
	end
	name = strmatch(name, "^[^%-]+") -- drop the realm
	return name and strlower(name)
end

local function rememberName(name)
	local key = nameKey(name)
	if not key or recentNames[key] then
		return
	end
	recentNames[key] = true
	recentOrder[#recentOrder + 1] = key
	if #recentOrder > RECENT_LIMIT then
		recentNames[table.remove(recentOrder, 1)] = nil
	end
end

local function refreshGroupNames()
	wipe(groupNames)
	local count = GetNumGroupMembers and GetNumGroupMembers() or 0
	local unitPrefix = IsInRaid and IsInRaid() and "raid" or "party"
	for index = 1, count do
		local key = nameKey(UnitName(unitPrefix .. index))
		if key then
			groupNames[key] = true
		end
	end
end

-- True for you, your target, your group and anyone who spoke recently.
function ns.IsKnownName(lowercaseWord)
	if recentNames[lowercaseWord] or groupNames[lowercaseWord] then
		return true
	end
	-- Guildmates, friends and Battle.net friends' characters (People.lua).
	if ns.IsKnownPerson and ns.IsKnownPerson(lowercaseWord) then
		return true
	end
	if lowercaseWord == nameKey(UnitName("player")) then
		return true
	end
	-- Your target counts only if it is a player: when you target Hogger and
	-- type his name, he should still get the accent.
	local ok, isTarget = pcall(function()
		return UnitIsPlayer("target") and lowercaseWord == nameKey(UnitName("target"))
	end)
	return ok and isTarget == true
end

---------------------------------------------------------------------------
-- Translating one outgoing message
---------------------------------------------------------------------------

local options = { isName = ns.IsKnownName }

-- Flourishes are decided by a roll. The chat line keeps one roll from when
-- you start typing until the message is sent, so the preview above it shows
-- exactly what will be said. The Juju box has its own roll, which travels
-- with "Put in chat".
ns.Random = math.random

local function newRoll()
	return ns.Random(0, 999999999)
end

function ns.NewChatRoll()
	ns.chatRoll = ns.pendingRoll or newRoll()
	ns.pendingRoll = nil
end

function ns.NewBoxRoll()
	ns.boxRoll = newRoll()
end

-- Returns the text to send for this kind of chat: troll if that channel is
-- switched on, otherwise exactly what was typed. channelName is only needed
-- for numbered channels.
function ns.TranslateFor(chatType, text, channelName)
	local db = ns.db
	local channel = ns.ChannelKeyFor(chatType, channelName)
	if not db or not channel or not db.channels[channel] then
		return text
	end
	options.trace = nil
	if not ns.chatRoll then
		ns.NewChatRoll()
	end
	options.words = ns.ownWords
	options.mobs = db.creatures and ns.Mobs or nil
	options.places = db.placeNames and ns.Places or nil
	options.voice = ns.GetVoice()
	options.flourish = db.flourish
	options.roll = ns.chatRoll
	options.vocab = db.vocab
	options.names = db.names
	options.guess = db.typos
	options.mon = db.mon and chatType == "YELL"
	options.quotesOnly = chatType == "EMOTE"
	return ns.Translator.Translate(text, options)
end

-- Always translates, whatever the channel settings. Used by the Juju box.
-- trace, if given, is filled with which typed word became which troll word.
function ns.TranslatePreview(text, trace)
	if not ns.boxRoll then
		ns.NewBoxRoll()
	end
	options.trace = trace
	options.words = ns.ownWords
	options.mobs = ns.db.creatures and ns.Mobs or nil
	options.places = ns.db.placeNames and ns.Places or nil
	options.voice = ns.GetVoice()
	options.flourish = ns.db.flourish
	options.roll = ns.boxRoll
	options.vocab = ns.db.vocab
	options.names = ns.db.names
	options.guess = ns.db.typos
	options.mon = false
	options.quotesOnly = false
	return ns.Translator.Translate(text, options)
end

-- Announcements another addon makes on your behalf (Questie's "objective
-- done" messages to the party). The addon's own marker at the front, such as
-- "{rt1} Questie: ", is kept exactly, because other players' copies of that
-- addon look for it.
local announceOptions = {}

function ns.TranslateAnnouncement(message, chatType)
	local db = ns.db
	if type(message) ~= "string" or (issecretvalue and issecretvalue(message)) then
		return message
	end
	local channel = CHANNEL_OF[chatType]
	if not db or not db.questie or not ns.IsActive() or not channel or not db.channels[channel] then
		return message
	end

	local marker, rest = strmatch(message, "^(.-Questie%s?:%s*)(.*)$")
	if not marker then
		marker, rest = "", message
	end
	-- Questie's own wording, said the troll way (see Lexicon.questie).
	for _, template in ipairs(ns.Lexicon.questie or {}) do
		local reworded, count = gsub(rest, template[1], template[2], 1)
		if count > 0 then
			rest = reworded
			break
		end
	end

	announceOptions.words = ns.ownWords
	announceOptions.mobs = db.creatures and ns.Mobs or nil
	announceOptions.places = db.placeNames and ns.Places or nil
	announceOptions.voice = ns.GetVoice()
	announceOptions.vocab = db.vocab
	announceOptions.flourish = db.flourish
	announceOptions.roll = newRoll()
	announceOptions.keepCapitals = true
	announceOptions.maxBytes = ns.Translator.MAX_BYTES - #marker
	return marker .. ns.Translator.Translate(rest, announceOptions)
end

---------------------------------------------------------------------------
-- Numbered channels, all at once
---------------------------------------------------------------------------

function ns.NumberedChannelsOn()
	for _, key in ipairs(NUMBERED) do
		if ns.db.channels[key] then
			return true
		end
	end
	return false
end

-- Switches troll speech in General, Trade, LookingForGroup and other numbered
-- channels off together, or back on. Turning them back on restores the
-- ones that were on before; if none were, all of them come on.
function ns.SetNumberedChannels(on, quiet)
	local channels = ns.db.channels
	if on then
		local remembered = ns.db.numberedRemembered
		local any = false
		for _, key in ipairs(NUMBERED) do
			if type(remembered) == "table" and remembered[key] then
				any = true
			end
		end
		for _, key in ipairs(NUMBERED) do
			channels[key] = not any or remembered[key] == true
		end
	else
		if ns.NumberedChannelsOn() then
			local remembered = {}
			for _, key in ipairs(NUMBERED) do
				remembered[key] = channels[key] or nil
			end
			ns.db.numberedRemembered = remembered
		end
		for _, key in ipairs(NUMBERED) do
			channels[key] = false
		end
	end
	ns.Refresh()
	if quiet then
		return
	end
	if on then
		local names = {}
		for _, channel in ipairs(ns.CHANNELS) do
			for _, key in ipairs(NUMBERED) do
				if channel.key == key and channels[key] then
					names[#names + 1] = (gsub(channel.label, " %(.*", ""))
				end
			end
		end
		Print("Talkin' troll in numbered channels: " .. table.concat(names, ", ") .. ".")
		if not ns.IsActive() then
			Print("Troll speech is switched off on this character, though. Type /juju on.")
		end
	else
		Print("Plain speech in General, Trade and the other numbered channels.")
	end
end

function ns.ToggleNumberedChannels()
	ns.SetNumberedChannels(not ns.NumberedChannelsOn())
end

---------------------------------------------------------------------------
-- Troll voices (see Lexicon.voices). One per character.
---------------------------------------------------------------------------

-- The voice a character has until one is chosen: Sistah for a woman,
-- Darkspear otherwise. (UnitSex says 3 for female characters.)
function ns.DefaultVoice()
	local ok, sex = pcall(UnitSex, "player")
	if ok and sex == 3 then
		return "sistah"
	end
	return "darkspear"
end

function ns.GetVoiceKey()
	local saved = JujuCharDB and JujuCharDB.voice
	if saved and ns.Lexicon.voices[saved] then
		return saved
	end
	return ns.DefaultVoice()
end

function ns.GetVoice()
	return ns.Lexicon.voices[ns.GetVoiceKey()] or ns.Lexicon.voices.darkspear
end

-- SetVoice("witchdoctor") -> true, or false if there is no such voice.
-- "Witch Doctor" and "witch-doctor" are understood too.
function ns.SetVoice(key)
	if type(key) == "string" then
		key = strlower(gsub(key, "[%s%-']", ""))
	end
	if type(key) ~= "string" or not ns.Lexicon.voices[key] then
		return false
	end
	JujuCharDB.voice = key
	JujuCharDB.voiceChosen = true
	ns.Refresh()
	return true
end

-- The voice after this one, or before it with step -1, in Lexicon.voiceOrder.
function ns.NextVoice(step)
	local order = ns.Lexicon.voiceOrder
	local current = ns.GetVoiceKey()
	for index, key in ipairs(order) do
		if key == current then
			return order[(index - 1 + (step or 1)) % #order + 1]
		end
	end
	return order[1]
end

function ns.VoiceList()
	local keys = {}
	for _, key in ipairs(ns.Lexicon.voiceOrder) do
		keys[#keys + 1] = key
	end
	return table.concat(keys, ", ")
end

---------------------------------------------------------------------------
-- The player's own words
---------------------------------------------------------------------------

local MAX_WORDS = 300

-- Lowercase, single spaces, nothing but letters, apostrophes and spaces.
local function cleanEnglish(english)
	if type(english) ~= "string" then
		return nil
	end
	english = strlower(gsub(gsub(english, "^%s+", ""), "%s+$", ""))
	english = gsub(english, "%s+", " ")
	if english == "" or #english > 40 or strfind(english, "[^a-z' ]") or not strfind(english, "%a") then
		return nil
	end
	return english
end

local function cleanTroll(said)
	if type(said) ~= "string" then
		return ""
	end
	-- | starts the game's colour and link codes, so it may not be typed here.
	said = gsub(said, "|", "")
	return (gsub(gsub(gsub(said, "^%s+", ""), "%s+$", ""), "%s+", " "))
end

function ns.RebuildWords()
	ns.ownWords = ns.Translator.PrepareWords(ns.db.words)
	ns.Refresh()
end

-- SetWord("gold", "shinies") or SetWord("zanjin", "") to keep a word as typed.
-- Returns true and a message to show, or false and why it did not work.
function ns.SetWord(english, said)
	local key = cleanEnglish(english)
	if not key then
		return false, "Use only letters, spaces and apostrophes on the English side, up to 40 of them."
	end
	said = cleanTroll(said)
	if #said > 60 then
		return false, "Keep the troll side to 60 letters or fewer."
	end
	local words = ns.db.words
	if words[key] == nil then
		local count = 0
		for _ in pairs(words) do
			count = count + 1
		end
		if count >= MAX_WORDS then
			return false, "You have " .. MAX_WORDS .. " words already. Remove some first."
		end
	end
	words[key] = said ~= "" and said or false
	ns.RebuildWords()
	if said == "" then
		return true, "\"" .. key .. "\" will be kept exactly as you type it."
	end
	return true, "\"" .. key .. "\" becomes \"" .. said .. "\"."
end

function ns.RemoveWord(english)
	local key = cleanEnglish(english)
	if not key or ns.db.words[key] == nil then
		return false, "\"" .. (key or english or "") .. "\" is not one of your words."
	end
	ns.db.words[key] = nil
	ns.RebuildWords()
	return true, "Removed \"" .. key .. "\"."
end

-- Your words in alphabetical order, as { english, troll-or-false } pairs.
function ns.ListWords()
	local list = {}
	for english, said in pairs(ns.db.words) do
		list[#list + 1] = { english, said }
	end
	table.sort(list, function(a, b) return a[1] < b[1] end)
	return list
end

function ns.DescribeWord(entry)
	if entry[2] == false then
		return entry[1] .. " (kept as typed)"
	end
	return entry[1] .. " = " .. entry[2]
end

---------------------------------------------------------------------------
-- /juju
---------------------------------------------------------------------------

local function printStatus()
	if ns.IsActive() then
		Print("On. Ya be talkin' like a true troll, mon.")
	elseif ns.IsSwitchedOn() then
		Print("Waiting: " .. ns.SpeakingInstead() .. " is talking on this character. Type /juju on to switch to Juju.")
	elseif (JujuCharDB.mode or "auto") == "auto" then
		Print("Off, because this character is not a troll. Type /juju on to talk like one anyway.")
	else
		Print("Off.")
	end
end

local function printHelp()
	printStatus()
	Print("/juju - open the Juju box: type English, see the troll as you type. Nothing is said.")
	Print("/juju on, /juju off, /juju auto - switch troll speech for this character (auto = on for Trolls)")
	Print("/juju <channel> on|off - channels: say yell emote party raid guild whisper bnet general trade lfg other")
	Print("/juju channels - switch troll speech in General, Trade and other numbered channels on or off")
	Print("/juju flourishes - now and then add a troll \"Hey, mon!\" or \", ya hear\" (on or off)")
	Print("/juju creatures - how many creature names Juju knows; add on or off to switch Jujuifying them")
	Print("/juju places - the same for place names")
	Print("/juju voice - what kind of troll this character is: darkspear, sistah, witchdoctor, headhunter, shadowhunter or zandalari")
	Print("/juju emotes - list the troll emotes: /voodoo, /mon, /hex, /bones and more")
	Print("/juju names - how many guildmates' and friends' names Juju keeps safe")
	Print("/juju questie - say Questie's party announcements in troll (on or off)")
	Print("/juju word gold = shinies, /juju keep Zanjin, /juju forget gold, /juju words - your own words (also in the Juju box)")
	Print("/juju config - open the settings")
	Print("Start a message with ((  or with \"! \" to say it plainly.")
end

local function handleSlash(message)
	local command, rest = strmatch(message or "", "^%s*(%S*)%s*(.-)%s*$")
	command = strlower(command or "")

	if command == "" then
		ns.ToggleBox()
	elseif command == "help" then
		printHelp()
	elseif command == "on" or command == "off" or command == "auto" then
		ns.SetMode(command)
	elseif command == "toggle" then
		ns.Toggle()
	elseif command == "test" or command == "box" then
		-- "/juju test some words" opens the box with those words in it.
		ns.OpenBox(rest)
	elseif command == "config" or command == "options" or command == "settings" then
		ns.OpenOptions()
	elseif command == "channel" or command == "channels" then
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.SetNumberedChannels(value == "on")
		else
			ns.ToggleNumberedChannels()
		end
	elseif command == "emotes" then
		Print(ns.DescribeEmotes())
		if ns.OpenBox then
			ns.OpenBox(nil, "emotes")
		end
	elseif command == "emote" then
		local name, target = strmatch(rest, "^(%S+)%s*(.-)$")
		if not name or not ns.FindEmote(strlower(name)) then
			Print(ns.DescribeEmotes())
		else
			ns.DoEmote(strlower(name), target)
		end
	elseif command == "names" or command == "people" then
		Print(ns.DescribePeople())
	elseif command == "voice" then
		local wanted = strlower(rest)
		if wanted ~= "" then
			local ok = ns.SetVoice(wanted)
			if not ok then
				Print("No such voice. Pick one of: " .. ns.VoiceList() .. ".")
				return
			end
		end
		local voice = ns.GetVoice()
		Print("This character talks like a " .. voice.name .. ". " .. voice.about)
		if wanted == "" then
			Print("Voices: " .. ns.VoiceList() .. ". Type /juju voice witchdoctor, for example, or use the button in the Juju box.")
		end
	elseif command == "places" then
		-- On its own it only reports; "on" or "off" switches.
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.db.placeNames = value == "on"
			ns.Refresh()
		end
		Print(ns.db.placeNames and "Place names get the troll accent: Tunda Bluff, da Barrens. (/juju places off to stop)"
			or "Place names are left as they are. (/juju places on to Jujuify them)")
		if ns.DescribePlaces then
			Print(ns.DescribePlaces())
		end
	elseif command == "creatures" or command == "mobs" then
		-- On its own it only reports; "on" or "off" switches.
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.db.creatures = value == "on"
			ns.Refresh()
		end
		Print(ns.db.creatures and "Creature names get the troll accent: Hogger be Hogga. (/juju creatures off to stop)"
			or "Creature names are left as they are. (/juju creatures on to Jujuify them)")
		if ns.DescribeCreatures then
			Print(ns.DescribeCreatures())
		end
	elseif command == "questie" then
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.db.questie = value == "on"
		else
			ns.db.questie = not ns.db.questie
		end
		Print(ns.db.questie and "Questie's party announcements will be said in troll." or "Questie's party announcements are left as they are.")
	elseif command == "flourish" or command == "flourishes" then
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.db.flourish = value == "on"
		else
			ns.db.flourish = not ns.db.flourish
		end
		ns.Refresh()
		Print(ns.db.flourish and "Troll flourishes on. Ya, mon!" or "Troll flourishes off.")
	elseif command == "word" then
		local english, troll = strmatch(rest, "^(.-)%s*=%s*(.*)$")
		if not english or english == "" then
			Print("Try: /juju word gold = shinies")
		else
			local _, said = ns.SetWord(english, troll)
			Print(said)
		end
	elseif command == "keep" then
		local _, said = ns.SetWord(rest, "")
		Print(said)
	elseif command == "forget" or command == "unword" then
		local _, said = ns.RemoveWord(rest)
		Print(said)
	elseif command == "words" then
		local list = ns.ListWords()
		if #list == 0 then
			Print("You have not taught Juju any words yet. Open the Juju box with /juju.")
		else
			local shown = {}
			for _, entry in ipairs(list) do
				shown[#shown + 1] = ns.DescribeWord(entry)
			end
			Print("Your words: " .. table.concat(shown, ", "))
		end
	elseif ns.db.channels[command] ~= nil then
		local value = strlower(rest)
		if value == "on" or value == "off" then
			ns.db.channels[command] = value == "on"
			ns.Refresh()
		end
		Print(command .. " is " .. (ns.db.channels[command] and "on" or "off") .. ".")
	else
		printHelp()
	end
end

SLASH_JUJU1 = "/juju"
SlashCmdList["JUJU"] = handleSlash

---------------------------------------------------------------------------
-- Key binding and minimap addon menu
---------------------------------------------------------------------------

BINDING_HEADER_JUJU = "Juju"
BINDING_NAME_JUJU_TOGGLE = "Switch troll speech on or off"
BINDING_NAME_JUJU_TOGGLE_CHANNELS = "Switch troll speech in General, Trade and other channels"
BINDING_NAME_JUJU_BOX = "Open or close the Juju box"

function Juju_Toggle()
	ns.Toggle()
end

function Juju_ToggleChannels()
	ns.ToggleNumberedChannels()
end

function Juju_ToggleBox()
	ns.ToggleBox()
end

function Juju_OnAddonCompartmentClick(_, button)
	if button == "RightButton" then
		ns.OpenOptions()
	else
		ns.Toggle()
	end
end

function Juju_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	GameTooltip:AddLine("Juju")
	GameTooltip:AddLine(ns.IsActive() and "Troll speech is on." or "Troll speech is off.", 1, 1, 1)
	GameTooltip:AddLine("Click to switch it. Right-click for settings.", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end

function Juju_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Start-up
---------------------------------------------------------------------------

local NAME_EVENTS = {
	"CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_GUILD", "CHAT_MSG_WHISPER",
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")

frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		if ... ~= ADDON then
			-- Another addon finished loading. If it was Questie, join up.
			if ns.db and ns.HookQuestie then
				ns.HookQuestie()
			end
			return
		end

		if type(JujuDB) ~= "table" then
			JujuDB = {}
		end
		if type(JujuCharDB) ~= "table" then
			JujuCharDB = {}
		end
		fillDefaults(JujuDB, DEFAULTS)
		if JujuCharDB.mode ~= "on" and JujuCharDB.mode ~= "off" then
			JujuCharDB.mode = "auto"
		end
		-- A voice is only kept once it has been chosen. Until then the
		-- character gets the voice that suits it (see ns.DefaultVoice).
		local voice = JujuCharDB.voice
		if not (voice and ns.Lexicon.voices[voice] and JujuCharDB.voiceChosen) then
			JujuCharDB.voice = nil
			JujuCharDB.voiceChosen = nil
		end
		ns.db = JujuDB
		ns.ownWords = ns.Translator.PrepareWords(JujuDB.words)

		for _, name in ipairs(NAME_EVENTS) do
			self:RegisterEvent(name)
		end
	elseif event == "PLAYER_LOGIN" then
		if not ns.db then
			return
		end
		refreshGroupNames()
		if ns.HookQuestie then
			ns.HookQuestie()
		end
		if ns.BuildOptions then
			ns.BuildOptions()
		end
		-- Say hello once per character, so nobody wonders why it is quiet.
		if not JujuCharDB.greeted then
			JujuCharDB.greeted = true
			if ns.IsActive() then
				Print("Hey, mon! Ya be talkin' like a true troll now. Type /juju to try it out, or /juju help.")
			else
				Print("Sleepin' on this character, because it is not a troll. Type /juju on to talk like one anyway.")
			end
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		refreshGroupNames()
	else
		-- A chat message: the second value is who said it.
		local _, sender = ...
		rememberName(sender)
	end
end)
