-- Juju and Questie.
--
-- Questie can tell your party when you finish a quest step, accept a quest
-- and so on. It sends those messages itself, not through the chat line, so
-- Juju's usual hook never sees them. This file steps in while Questie is
-- announcing, and only then:
--
--   1. Questie's announcing functions are wrapped.
--   2. While one of them runs, the SendChatMessage it calls is swapped for
--      one that translates the text first.
--   3. The moment Questie is done, the real one is put back.
--
-- So no other addon's messages ever pass through Juju. On this client
-- SendChatMessage is an old-name helper for addons; the game's own chat does
-- not use it.
--
-- If Questie is not installed, or a later version renames these functions,
-- nothing here does anything and Questie carries on as it always did.

local _, ns = ...

-- The functions in Questie's "QuestieAnnounce" module that end in a message
-- to the group.
local ANNOUNCERS = {
	"AnnounceObjectiveToChannel",
	"AnnounceQuestItemLootedToChannel",
	"AcceptedQuest",
	"AbandonedQuest",
	"CompletedQuest",
}

local hooked = false
local announcing = false

-- Puts the real SendChatMessage back, then passes on whatever Questie
-- returned (or the error it raised).
local function finish(realSend, ok, ...)
	SendChatMessage = realSend
	announcing = false
	if not ok then
		error((...), 0)
	end
	return ...
end

local function wrap(announce)
	return function(...)
		local realSend = SendChatMessage
		-- One announcer can call another; only the outermost one steps in.
		if announcing or type(realSend) ~= "function" or not (ns.db and ns.db.questie and ns.IsActive()) then
			return announce(...)
		end
		announcing = true
		SendChatMessage = function(message, chatType, ...)
			return realSend(ns.TranslateAnnouncement(message, chatType), chatType, ...)
		end
		return finish(realSend, pcall(announce, ...))
	end
end

-- Safe to call any number of times. Returns true once Questie is hooked.
function ns.HookQuestie()
	if hooked then
		return true
	end
	local loader = QuestieLoader
	if type(loader) ~= "table" or type(loader.ImportModule) ~= "function" then
		return false -- Questie is not here (yet)
	end
	local module = loader:ImportModule("QuestieAnnounce")
	if type(module) ~= "table" then
		return false
	end
	local found = 0
	for _, name in ipairs(ANNOUNCERS) do
		if type(module[name]) == "function" then
			module[name] = wrap(module[name])
			found = found + 1
		end
	end
	-- Questie's files load together, so if none of the functions are there
	-- yet, it has not loaded: try again later.
	hooked = found > 0
	return hooked
end
