-- Juju emotes: /voodoo, /mon, /hex and the rest (see Lexicon.emotes).
--
-- Each sends a custom emote, the same as typing /e yourself:
--   /voodoo          Zanjin wiggles his fingers mysteriously. "Stay away from da voodoo, mon."
--   /mon Rokhan      Zanjin nods slowly at Rokhan. "Ya, mon. We be cool."
-- With no name typed, your target is used if you have one. The wording
-- follows the character's voice and whether the character is a he or a she.
--
-- A command the game or another addon already uses is left alone; every
-- emote also works as /juju emote <name>.
--
-- Your own emotes (made on the Emotes page of the Juju box) are kept in
-- JujuDB.myEmotes and work the same way as Juju's.

local _, ns = ...

local gsub, strfind, strmatch, strlower, strupper = string.gsub, string.find, string.match, string.lower, string.upper

local PRONOUNS = {
	[2] = { his = "his", him = "him", he = "he" },
	[3] = { his = "her", him = "her", he = "she" },
}
local NEUTRAL = { his = "their", him = "them", he = "they" }

local taken = {}       -- emote name -> true when its command belongs to someone else
local handlers = {}    -- our own slash command functions, to tell them apart

local MAX_OWN = 12     -- your own emotes
local MAX_LINE = 180   -- letters in one line of an emote

-- Juju's emote, or one of your own.
local function findEmote(key)
	return ns.Lexicon.emotes[key] or (ns.db and ns.db.myEmotes[key])
end
ns.FindEmote = findEmote

-- All emote names, Juju's first and then your own in alphabetical order.
function ns.EmoteNames()
	local names = {}
	for _, key in ipairs(ns.Lexicon.emoteOrder) do
		names[#names + 1] = key
	end
	local own = {}
	for key in pairs(ns.db and ns.db.myEmotes or {}) do
		own[#own + 1] = key
	end
	table.sort(own)
	for _, key in ipairs(own) do
		names[#names + 1] = key
	end
	return names
end

function ns.IsOwnEmote(key)
	return ns.db ~= nil and ns.db.myEmotes[key] ~= nil and not ns.Lexicon.emotes[key]
end

-- True if typing /key would run something other than this emote.
function ns.IsEmoteCommandTaken(key)
	return taken[key] == true
end

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

-- The name to aim at: the one typed, or else your target (not yourself).
local function targetName(typed)
	if readable(typed) and strfind(typed, "%S") then
		return (gsub(gsub(typed, "^%s+", ""), "%s+$", ""))
	end
	local ok, name = pcall(function()
		if UnitExists("target") and not UnitIsUnit("target", "player") then
			return UnitName("target")
		end
	end)
	if ok and readable(name) then
		return name
	end
	return nil
end

-- The line to send for an emote, without your own name (the game adds it).
function ns.EmoteText(key, target)
	local emote = findEmote(key)
	if not emote then
		return nil
	end
	local line
	local own = emote.voices and emote.voices[ns.GetVoiceKey()]
	if type(own) == "string" then
		line = own
	elseif type(own) == "table" then
		-- A voice may have a line of its own for only one of the two.
		if target then
			line = own.target
		else
			line = own.text
		end
	end
	if not line then
		line = target and emote.target or emote.text
	end
	-- A line written for a target needs one; without one, use the plain line.
	if not target and strfind(line, "{target}", 1, true) then
		line = emote.text
	end

	local ok, sex = pcall(UnitSex, "player")
	local pronouns = (ok and PRONOUNS[sex]) or NEUTRAL
	line = gsub(line, "{(%a+)}", function(word)
		if word == "target" then
			return target or ""
		end
		return pronouns[word]
	end)
	return line
end

local function send(line)
	local sendChat = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
	local ok = sendChat ~= nil and pcall(sendChat, line, "EMOTE")
	if not ok then
		-- If the game will not let it through, put it in the chat line instead.
		local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
		if open then
			open("/e " .. line)
		end
	end
end

-- Performs an emote. typedTarget is whatever was typed after the command.
function ns.DoEmote(key, typedTarget)
	local line = ns.EmoteText(key, targetName(typedTarget))
	if not line then
		return false
	end
	send(line)
	return true
end

-- For /juju emotes.
function ns.DescribeEmotes()
	local free, other = {}, {}
	for _, key in ipairs(ns.EmoteNames()) do
		if taken[key] then
			other[#other + 1] = key
		else
			free[#free + 1] = "/" .. key
		end
	end
	local text = "Troll emotes: " .. table.concat(free, " ")
		.. ". Add a name to aim one at someone, or target them first."
	if #other > 0 then
		text = text .. " Already used by the game or another addon, so type /juju emote and the name: "
			.. table.concat(other, ", ") .. "."
	end
	return text
end

---------------------------------------------------------------------------
-- Registering the commands
---------------------------------------------------------------------------

-- Every command already in use by the game's emotes or other addons.
local function commandsInUse()
	local inUse = {}
	if MAXEMOTEINDEX then
		for i = 1, MAXEMOTEINDEX do
			local j = 1
			while _G["EMOTE" .. i .. "_CMD" .. j] do
				inUse[strlower(_G["EMOTE" .. i .. "_CMD" .. j])] = true
				j = j + 1
			end
		end
	end
	local function addCommands(name)
		if type(name) ~= "string" or strfind(name, "^JUJU_EMOTE_") then
			return
		end
		local j = 1
		while _G["SLASH_" .. name .. j] do
			inUse[strlower(_G["SLASH_" .. name .. j])] = true
			j = j + 1
		end
	end
	for name in pairs(SlashCmdList) do
		addCommands(name)
	end
	-- Once the game has read a command, it moves it out of SlashCmdList into
	-- a table behind it, and into hash_SlashCmdList: look there too.
	local meta = getmetatable(SlashCmdList)
	if meta and type(meta.__index) == "table" then
		for name in pairs(meta.__index) do
			addCommands(name)
		end
	end
	if type(hash_SlashCmdList) == "table" then
		for command, handler in pairs(hash_SlashCmdList) do
			if type(command) == "string" and not handlers[handler] then
				inUse[strlower(command)] = true
			end
		end
	end
	return inUse
end

-- Gives an emote its own /command, unless something else already has it.
-- Returns true if the command is Juju's.
local function registerOne(key, inUse)
	local command = "/" .. key
	local id = "JUJU_EMOTE_" .. strupper(key)
	if _G["SLASH_" .. id .. "1"] == command and SlashCmdList[id] then
		return true -- already ours
	end
	if (inUse or commandsInUse())[command] then
		taken[key] = true
		return false
	end
	taken[key] = nil
	local handler = function(typed)
		if findEmote(key) then
			ns.DoEmote(key, typed)
		else
			ns.Print("The emote " .. command .. " is gone.")
		end
	end
	handlers[handler] = true
	_G["SLASH_" .. id .. "1"] = command
	SlashCmdList[id] = handler
	return true
end

local function unregisterOne(key)
	local id = "JUJU_EMOTE_" .. strupper(key)
	SlashCmdList[id] = nil
	_G["SLASH_" .. id .. "1"] = nil
	taken[key] = nil
end

local function register()
	local inUse = commandsInUse()
	for _, key in ipairs(ns.EmoteNames()) do
		registerOne(key, inUse)
	end
end

---------------------------------------------------------------------------
-- Your own emotes
---------------------------------------------------------------------------

local function cleanLine(line)
	if not readable(line) then
		return ""
	end
	-- | starts the game's colour and link codes, so it may not be typed here.
	line = gsub(line, "|", "")
	return (gsub(gsub(gsub(line, "^%s+", ""), "%s+$", ""), "%s+", " "))
end

-- SaveOwnEmote("frog", "pulls out a frog.", "throws a frog at {target}.")
-- Returns true and a message, or false and why not.
function ns.SaveOwnEmote(name, line, targetLine)
	name = readable(name) and strlower(gsub(gsub(name, "^%s*/?", ""), "%s+$", "")) or ""
	if not strfind(name, "^%a%a+$") or #name > 16 then
		return false, "The name is one word of letters, 2 to 16 long. It becomes /name."
	end
	if ns.Lexicon.emotes[name] then
		return false, "/" .. name .. " is one of Juju's own emotes. Pick another name."
	end
	if name == "juju" then
		return false, "/juju is taken by Juju itself. Pick another name."
	end
	line, targetLine = cleanLine(line), cleanLine(targetLine)
	if line == "" then
		return false, "Type what you do, like: pulls a frog out of {his} pocket."
	end
	if #line > MAX_LINE or #targetLine > MAX_LINE then
		return false, "Keep each line to " .. MAX_LINE .. " letters or fewer."
	end
	local own = ns.db.myEmotes
	if not own[name] then
		local count = 0
		for _ in pairs(own) do
			count = count + 1
		end
		if count >= MAX_OWN then
			return false, "You have " .. MAX_OWN .. " emotes already. Remove one first."
		end
	end
	own[name] = { text = line, target = targetLine ~= "" and targetLine or nil }
	local free = registerOne(name)
	ns.Refresh() -- the Emotes page shows it straight away
	if free then
		return true, "Saved /" .. name .. "."
	end
	return true, "Saved. /" .. name .. " is already used by the game or another addon, so use the button or /juju emote " .. name .. "."
end

function ns.RemoveOwnEmote(name)
	name = readable(name) and strlower(gsub(gsub(name, "^%s*/?", ""), "%s+$", "")) or ""
	if not ns.IsOwnEmote(name) then
		return false, "/" .. name .. " is not one of your emotes."
	end
	ns.db.myEmotes[name] = nil
	unregisterOne(name)
	ns.Refresh()
	return true, "Removed /" .. name .. "."
end

-- After every addon has loaded, so their commands are known.
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function()
	pcall(register)
end)
