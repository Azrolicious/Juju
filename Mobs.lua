-- Juju creature names: where they come from.
--
-- Creature names get the troll accent ("Hogger" -> "Hogga") while players'
-- names are left alone, so Juju needs to know which names are creatures.
-- It finds out two ways:
--
--   1. From Questie, if it is installed. QuestieDB holds every creature in
--      the game. Juju reads the names of the hostile ones, and of neutral
--      beasts like Mottled Boars, a few hundred per frame so the game never
--      stutters. Nothing is changed in Questie. The names are kept, so this
--      happens once, and again only when QuestieDB is updated.
--   2. From the world. Every hostile creature you target, point at or see a
--      nameplate for is remembered, and saved, so this works without
--      Questie too and keeps growing as you play.

local _, ns = ...

local MAX_SAVED = 5000      -- creature names met in the world, kept between sessions
local FRAME_BUDGET = 3      -- milliseconds of work per frame while reading names
local PER_FRAME = 100       -- entries per frame where the game's timer is not available
local WAIT_TRIES = 90       -- checks for Questie being ready, 2 seconds apart

ns.Mobs = ns.Translator.PrepareMobs()
local counts = { questie = 0, met = 0, saved = 0 }
local importState = "none" -- none, waiting, reading, done, failed

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

-- Adds a creature name. save keeps it for next time.
local function remember(name, save)
	if not readable(name) or not strfind(name, "^%u") then
		return false
	end
	local added = ns.Translator.AddMob(ns.Mobs, name)
	if save and ns.db then
		local key = strlower(name)
		if not ns.db.mobs[key] and counts.saved < MAX_SAVED then
			ns.db.mobs[key] = true
			counts.saved = counts.saved + 1
		end
		if added then
			counts.met = counts.met + 1
		end
	end
	return added
end

---------------------------------------------------------------------------
-- From the world
---------------------------------------------------------------------------

-- Hostile or attackable, not a player and not someone's pet (pets have
-- names their owners chose).
local function learnFrom(unit)
	if not (ns.db and ns.db.creatures) then
		return
	end
	-- Some unit details can be hidden from addons in combat; if anything is
	-- off limits, skip this one quietly.
	pcall(function()
		if UnitExists(unit) and not UnitIsPlayer(unit) and not UnitPlayerControlled(unit)
			and UnitCanAttack("player", unit) then
			remember(UnitName(unit), true)
		end
	end)
end

---------------------------------------------------------------------------
-- From Questie
---------------------------------------------------------------------------

-- QuestieDB also holds placeholders and developer entries: "Riding Horse
-- (Brown)", "Boy - placeholder 05", "Shambling Skeleton UNUSED".
local function isRealName(name)
	return readable(name) and not strfind(name, "[%d%[%]%(%)<>{}:/]")
		and not strfind(name, "UNUSED") and not strfind(name, "[Pp]laceholder")
		and not strfind(name, "DND") and not strfind(name, "Only GM")
end

-- Hostile creatures are friendly to neither faction. Neutral beasts (boars,
-- plainstriders, adders) are listed as friendly to both, like townsfolk, but
-- unlike townsfolk they have no title and no services.
local function isCreature(query, id)
	local friendly = query(id, "friendlyToFaction")
	if friendly == nil or friendly == "" then
		return true
	end
	if friendly ~= "AH" then
		return false -- one faction's own people
	end
	local flags, title = query(id, "npcFlags"), query(id, "subName")
	return (flags == nil or flags == 0) and (title == nil or title == "")
end

local function questieDatabase()
	local loader = QuestieLoader
	if type(loader) ~= "table" or type(loader.ImportModule) ~= "function" then
		return nil
	end
	local ok, database = pcall(loader.ImportModule, loader, "QuestieDB")
	if ok and type(database) == "table" then
		return database
	end
	return nil
end

-- Questie builds its creature list at login; wait until it says it is done.
local function questieReady(database)
	return type(Questie) == "table" and Questie.started
		and type(database.NPCPointers) == "table"
		and type(database.QueryNPCSingle) == "function"
end

-- Works through list a slice per frame, keeping each frame's share of the
-- work to a few milliseconds so the game never stutters. each(item) does the
-- work; finished(ok) runs at the end.
local function inSlices(list, each, finished, checkEvery)
	checkEvery = checkEvery or 1
	local position = 1
	local clock = debugprofilestop
	local function step()
		local started = clock and clock()
		local ok = pcall(function()
			local done = 0
			while position <= #list do
				each(list[position])
				position = position + 1
				done = done + 1
				if clock then
					if done % checkEvery == 0 and clock() - started > FRAME_BUDGET then
						return
					end
				elseif done >= PER_FRAME then
					return
				end
			end
		end)
		if not ok then
			finished(false)
		elseif position <= #list then
			C_Timer.After(0, step)
		else
			finished(true)
		end
	end
	step()
end

ns.InSlices = inSlices

local function questieVersion()
	local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
	local ok, version = pcall(get, "QuestieDB", "Version")
	return ok and readable(version) and version or nil
end

-- The names kept from the last time QuestieDB was read.
local function loadSavedQuestieNames(finished)
	local saved = ns.db.questieNames
	if type(saved.names) ~= "table" or #saved.names == 0 then
		finished(false)
		return
	end
	importState = "reading"
	inSlices(saved.names, function(name)
		if ns.Translator.AddMob(ns.Mobs, name) then
			counts.questie = counts.questie + 1
		end
	end, function()
		importState = "done"
		finished(true)
	end, 10)
end

local function readQuestie(database, version)
	importState = "reading"
	local ids = {}
	for id in pairs(database.NPCPointers) do
		ids[#ids + 1] = id
	end
	local query = database.QueryNPCSingle
	local found = {}
	inSlices(ids, function(id)
		if isCreature(query, id) then
			local name = query(id, "name")
			if isRealName(name) and remember(name, false) then
				counts.questie = counts.questie + 1
				found[#found + 1] = strlower(name)
			end
		end
	end, function(ok)
		if not ok then
			importState = "failed" -- Questie changed: keep what was read
			return
		end
		importState = "done"
		-- Keep the names, so the next login does not read QuestieDB again.
		if version then
			ns.db.questieNames = { version = version, names = found }
		end
	end)
end

function ns.StartCreatureImport()
	local database = questieDatabase()
	local version = questieVersion()
	local saved = ns.db.questieNames
	-- Names kept from before: use them, unless QuestieDB has been updated.
	if type(saved) == "table" and saved.version ~= nil and (not database or saved.version == version) then
		loadSavedQuestieNames(function(ok)
			if not ok and database then
				saved.version = nil
				ns.StartCreatureImport()
			end
		end)
		return
	end
	if not database then
		return -- no Questie: names come from the world alone
	end
	importState = "waiting"
	local tries = 0
	local function check()
		tries = tries + 1
		if questieReady(database) then
			readQuestie(database, version)
		elseif tries < WAIT_TRIES then
			C_Timer.After(2, check)
		else
			importState = "failed"
		end
	end
	check()
end

-- For /juju creatures: how many names Juju knows, and from where.
function ns.DescribeCreatures()
	local parts = { string.format("Juju knows %d creature names", ns.Mobs.count) }
	if importState == "done" or counts.questie > 0 then
		parts[#parts + 1] = string.format(": %d from Questie and %d met in the world.", counts.questie, ns.Mobs.count - counts.questie)
	else
		parts[#parts + 1] = ", all met in the world."
	end
	if importState == "waiting" or importState == "reading" then
		parts[#parts + 1] = " Still reading Questie's list."
	elseif importState == "failed" then
		parts[#parts + 1] = " Questie's list could not be read."
	end
	return table.concat(parts)
end

---------------------------------------------------------------------------
-- Start-up
---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, unit)
	if event == "PLAYER_LOGIN" then
		if not ns.db then
			return
		end
		for name in pairs(ns.db.mobs) do
			counts.saved = counts.saved + 1
			ns.Translator.AddMob(ns.Mobs, name)
		end
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
		ns.StartCreatureImport()
	elseif event == "PLAYER_TARGET_CHANGED" then
		learnFrom("target")
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		learnFrom("mouseover")
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		learnFrom(unit)
	end
end)
