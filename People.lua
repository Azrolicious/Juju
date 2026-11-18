-- Juju and the people you know: guildmates, friends, and the characters
-- your Battle.net friends play. Their names are never Jujuified, even when
-- they are not nearby and even when a name matches a creature or a place.
--
-- The names are read from the game's guild roster and friends lists, and
-- kept between sessions (JujuDB.people) so they are protected straight
-- after login too.

local _, ns = ...

local gsub, strfind, strmatch, strlower, strupper = string.gsub, string.find, string.match, string.lower, string.upper

local MAX_SAVED = 3000

local people = {}  -- lowercase name, no realm -> true
local counts = { guild = 0, friends = 0, battlenet = 0 }

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

-- "Grukk-Stormrage" -> "grukk"
local function key(name)
	if not readable(name) then
		return nil
	end
	name = strmatch(name, "^[^%-]+")
	if not name or name == "" then
		return nil
	end
	return strlower(name)
end

local function add(name, source)
	local k = key(name)
	if not k or people[k] then
		return
	end
	people[k] = true
	counts[source] = counts[source] + 1
	if ns.db then
		local saved = ns.db.people
		if not saved[k] then
			local count = 0
			for _ in pairs(saved) do
				count = count + 1
				if count >= MAX_SAVED then
					return
				end
			end
			saved[k] = true
		end
	end
end

function ns.IsKnownPerson(lowercaseName)
	return people[lowercaseName] == true
end

-- For /juju names.
function ns.DescribePeople()
	local total = 0
	for _ in pairs(people) do
		total = total + 1
	end
	return string.format("Juju never changes %d names of people you know: %d from your guild, %d friends and %d Battle.net friends' characters this session, the rest remembered from before.",
		total, counts.guild, counts.friends, counts.battlenet)
end

---------------------------------------------------------------------------
-- Reading the lists
---------------------------------------------------------------------------

local function readGuild()
	if not (IsInGuild and IsInGuild()) or not GetNumGuildMembers then
		return
	end
	for index = 1, GetNumGuildMembers() or 0 do
		add((GetGuildRosterInfo(index)), "guild")
	end
end

local function readFriends()
	local list = C_FriendList
	if not (list and list.GetNumFriends and list.GetFriendInfoByIndex) then
		return
	end
	for index = 1, list.GetNumFriends() or 0 do
		local info = list.GetFriendInfoByIndex(index)
		if type(info) == "table" then
			add(info.name, "friends")
		end
	end
end

-- Battle.net friends: only the characters they are playing right now are
-- known, so each one is remembered for next time.
local function readBattleNet()
	local battleNet = C_BattleNet
	if not (BNGetNumFriends and battleNet and battleNet.GetFriendNumGameAccounts and battleNet.GetFriendGameAccountInfo) then
		return
	end
	for friend = 1, BNGetNumFriends() or 0 do
		for account = 1, battleNet.GetFriendNumGameAccounts(friend) or 0 do
			local info = battleNet.GetFriendGameAccountInfo(friend, account)
			if type(info) == "table" and info.clientProgram == "WoW" then
				add(info.characterName, "battlenet")
			end
		end
	end
end

local READERS = {
	GUILD_ROSTER_UPDATE = readGuild,
	PLAYER_GUILD_UPDATE = readGuild,
	FRIENDLIST_UPDATE = readFriends,
	BN_FRIEND_INFO_CHANGED = readBattleNet,
	BN_FRIEND_LIST_SIZE_CHANGED = readBattleNet,
	BN_FRIEND_ACCOUNT_ONLINE = readBattleNet,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		if not ns.db then
			return
		end
		for name in pairs(ns.db.people) do
			people[name] = true
		end
		for name in pairs(READERS) do
			self:RegisterEvent(name)
		end
		-- Ask the game for the guild roster; it answers with GUILD_ROSTER_UPDATE.
		pcall(function()
			if C_GuildInfo and C_GuildInfo.GuildRoster then
				C_GuildInfo.GuildRoster()
			elseif GuildRoster then
				GuildRoster()
			end
		end)
		for _, read in ipairs({ readGuild, readFriends, readBattleNet }) do
			pcall(read)
		end
	else
		pcall(READERS[event])
	end
end)
