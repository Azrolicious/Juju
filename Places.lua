-- Juju place names: where they come from.
--
-- Place names get the troll accent like creature names do ("Thunder Bluff" ->
-- "Tunda Bluff", "the Barrens" -> "da Barrens"), so Juju needs to know
-- which capitalised words are places. It finds out three ways:
--
--   1. From the game's own map list: zones, cities, continents and dungeons.
--   2. From Questie, if it is installed: its list of zones and subzones,
--      such as Razor Hill and the Crossroads. Nothing in Questie is changed.
--   3. From your travels: every zone and subzone you enter is remembered,
--      and kept between sessions, so this works without Questie too.
--
-- The first two are read a little each frame after login, so the game never
-- stutters.

local _, ns = ...

local MAX_SAVED = 3000   -- places visited, kept between sessions
local MAX_MAP_ID = 3000  -- the game's map numbers go up to about here

ns.Places = ns.Translator.PrepareMobs()
local counts = { maps = 0, questie = 0, visited = 0 }
local reading = 0 -- lists still being read

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

-- Real place names start with a capital and have no numbers, brackets or
-- developer notes in them.
local function isRealName(name)
	return readable(name) and strfind(name, "^%u") ~= nil
		and not strfind(name, "[%d%[%]%(%)<>{}:/_]")
		and not strfind(name, "UNUSED") and not strfind(name, "DND")
		and not strfind(name, "DELETE") and not strfind(name, "[Pp]laceholder")
		and not strfind(name, "[Uu][Nn][Uu][Ss][Ee][Dd]") and not strfind(name, "%f[%a]Test%f[%A]")
end

-- Adds a place, and returns how many names were new. Names starting with
-- "The" can be said without it too: "the Barrens" and "Barrens" both count.
local function addPlace(name)
	if not isRealName(name) then
		return 0
	end
	local added = ns.Translator.AddMob(ns.Places, name) and 1 or 0
	local shorter = strmatch(name, "^The%s+(.+)$")
	if shorter and ns.Translator.AddMob(ns.Places, shorter) then
		added = added + 1
	end
	return added
end

local function finishedOne()
	reading = reading - 1
end

---------------------------------------------------------------------------
-- From the game's map list
---------------------------------------------------------------------------

local COSMIC, WORLD = 0, 1

local function readMaps()
	if not (C_Map and C_Map.GetMapInfo) then
		return
	end
	local ids = {}
	for id = 1, MAX_MAP_ID do
		ids[id] = id
	end
	reading = reading + 1
	ns.InSlices(ids, function(id)
		local info = C_Map.GetMapInfo(id)
		if type(info) == "table" and info.mapType ~= COSMIC and info.mapType ~= WORLD then
			counts.maps = counts.maps + addPlace(info.name)
		end
	end, finishedOne, 25)
end

---------------------------------------------------------------------------
-- From Questie
---------------------------------------------------------------------------

local function readQuestie()
	local loader = QuestieLoader
	if type(loader) ~= "table" or type(loader.ImportModule) ~= "function" then
		return
	end
	local ok, l10n = pcall(loader.ImportModule, loader, "l10n")
	if not ok or type(l10n) ~= "table" or type(l10n.zoneLookup) ~= "table" then
		return
	end
	-- zoneLookup[zone][area] = "Name"
	local names = {}
	for _, areas in pairs(l10n.zoneLookup) do
		if type(areas) == "table" then
			for _, name in pairs(areas) do
				names[#names + 1] = name
			end
		end
	end
	reading = reading + 1
	ns.InSlices(names, function(name)
		counts.questie = counts.questie + addPlace(name)
	end, finishedOne, 25)
end

---------------------------------------------------------------------------
-- From your travels
---------------------------------------------------------------------------

local function visited(name)
	if not (ns.db and isRealName(name)) then
		return
	end
	counts.visited = counts.visited + addPlace(name)
	local saved = ns.db.knownPlaces
	if not saved[name] then
		local count = 0
		for _ in pairs(saved) do
			count = count + 1
			if count >= MAX_SAVED then
				return
			end
		end
		saved[name] = true
	end
end

local function lookAround()
	pcall(function()
		for _, get in ipairs({ GetRealZoneText, GetZoneText, GetSubZoneText, GetMinimapZoneText }) do
			if type(get) == "function" then
				visited(get())
			end
		end
	end)
end

---------------------------------------------------------------------------
-- Reporting and start-up
---------------------------------------------------------------------------

-- For /juju places: how many names Juju knows, and from where.
function ns.DescribePlaces()
	local text = string.format("Juju knows %d place names: %d from the game's maps, %d from Questie and %d visited.",
		ns.Places.count, counts.maps, counts.questie, counts.visited)
	if reading > 0 then
		text = text .. " Still reading."
	end
	return text
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		if not ns.db then
			return
		end
		for name in pairs(ns.db.knownPlaces) do
			counts.visited = counts.visited + addPlace(name)
		end
		readMaps()
		readQuestie()
		for _, name in ipairs({ "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD" }) do
			self:RegisterEvent(name)
		end
		lookAround()
	else
		lookAround()
	end
end)
