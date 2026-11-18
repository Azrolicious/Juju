-- The Emotes page of the Juju box.
--
-- Top half: a button for every emote, Juju's and your own. Click one to do
-- it, aimed at your target if you have one; point at it to see exactly what
-- everyone will see. Right-click one of your own to change it.
--
-- Bottom half: make your own emote. A name (it becomes /name), what you do,
-- and what you do to someone else. They are kept with your settings and work
-- on every character. Your emotes are listed at the very bottom: click one
-- to change it, or its X to remove it.

local _, ns = ...

local kit = ns.BoxKit
local frame, page, inset = kit.frame, kit.page, kit.inset
local text, editBox, button = kit.text, kit.editBox, kit.button
local PAD, INNER, BORDER, R, G, B = kit.PAD, kit.INNER, kit.BORDER, kit.R, kit.G, kit.B

local COLUMNS, GAP, ROW = 4, 6, 26
local MAX_ROWS = 6 -- Juju's 9 emotes and up to 12 of your own
local BUTTON_WIDTH = (INNER - GAP * (COLUMNS - 1)) / COLUMNS

kit.buildOn(page)

---------------------------------------------------------------------------
-- The emote buttons
---------------------------------------------------------------------------

local aim = text("GameFontHighlightSmall", "TOPLEFT", inset, "TOPLEFT", PAD, -PAD)
aim:SetWidth(INNER)

local grid = {} -- the buttons, made as needed

local function gridButton(index)
	local made = grid[index]
	if not made then
		-- Made when the page is first shown, long after loading: put it on the
		-- page itself, so it hides with the page.
		made = button("", BUTTON_WIDTH, page)
		made:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		local column = (index - 1) % COLUMNS
		local row = math.floor((index - 1) / COLUMNS)
		made:SetPoint("TOPLEFT", aim, "BOTTOMLEFT", column * (BUTTON_WIDTH + GAP), -8 - row * ROW)
		grid[index] = made
	end
	return made
end

---------------------------------------------------------------------------
-- Make your own
---------------------------------------------------------------------------

local makeLine = kit.divider(aim, -8 - MAX_ROWS * ROW - 6)

local makeTitle = text("GameFontNormal", "TOPLEFT", makeLine, "BOTTOMLEFT", 0, -10, "Make ya own emote")

local nameLabel = text("GameFontHighlightSmall", "TOPLEFT", makeTitle, "BOTTOMLEFT", 0, -8, "Name (it becomes /name):")
local nameBox = editBox(150 - BORDER, 16)
nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", BORDER, -4)

local save = button("Save emote", 110)
save:SetPoint("LEFT", nameBox, "RIGHT", 10, 0)
local remove = button("Remove emote", 120)
remove:SetPoint("LEFT", save, "RIGHT", 6, 0)

local lineLabel = text("GameFontHighlightSmall", "TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -34,
	"What you do. {his} becomes her for a female character:")
local lineBox = editBox(INNER - BORDER, 180)
lineBox:SetPoint("TOPLEFT", lineLabel, "BOTTOMLEFT", BORDER, -4)

local targetLabel = text("GameFontHighlightSmall", "TOPLEFT", lineLabel, "BOTTOMLEFT", 0, -34,
	"What you do to someone. {target} is who (leave empty to use the line above):")
local targetBox = editBox(INNER - BORDER, 180)
targetBox:SetPoint("TOPLEFT", targetLabel, "BOTTOMLEFT", BORDER, -4)

local status = text("GameFontHighlightSmall", "TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -36)
status:SetWidth(INNER)
status:SetWordWrap(true)

-- Room for two lines of status above it.
local ownTitle = text("GameFontNormalSmall", "TOPLEFT", targetLabel, "BOTTOMLEFT", 0, -64, "Your emotes")

-- Set up below, once the behaviour it calls exists.
local ownList

-- In the button bar along the bottom of the window.
text("GameFontDisableSmall", "BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 4, 10,
	"Emotes are seen by everyone near you.")

kit.buildOn(frame)

-- For the tests.
frame.EmoteButtons, frame.EmoteName, frame.EmoteLine, frame.EmoteTarget = grid, nameBox, lineBox, targetBox
frame.SaveEmoteButton, frame.RemoveEmoteButton, frame.EmoteStatus, frame.EmoteAim = save, remove, status, aim
frame.OwnEmotesTitle = ownTitle

---------------------------------------------------------------------------
-- Behaviour
---------------------------------------------------------------------------

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

local function currentTarget()
	local ok, name = pcall(function()
		if UnitExists("target") and not UnitIsUnit("target", "player") then
			return UnitName("target")
		end
	end)
	return ok and readable(name) and name or nil
end

local function playerName()
	local ok, name = pcall(UnitName, "player")
	return ok and readable(name) and name or "You"
end

local function say(ok, message)
	if ok then
		status:SetTextColor(R, G, B)
	else
		status:SetTextColor(1, 0.35, 0.3)
	end
	status:SetText(message)
end

local function refresh()
	if not page:IsShown() or not ns.db then
		return
	end
	local target = currentTarget()
	if target then
		aim:SetText("Click an emote to do it. Aimed at: |cff3fbfaf" .. target .. "|r")
	else
		aim:SetText("Click an emote to do it. Target someone first to aim it at them.")
	end
	local names = ns.EmoteNames()
	for index, key in ipairs(names) do
		local made = gridButton(index)
		made.emote = key
		made:SetText(ns.IsOwnEmote(key) and ("|cff3fbfaf/" .. key .. "|r") or ("/" .. key))
		made:Show()
	end
	for index = #names + 1, #grid do
		grid[index]:Hide()
	end

	-- your own, in the list at the bottom
	local own = {}
	for _, key in ipairs(names) do
		if ns.IsOwnEmote(key) then
			own[#own + 1] = key
		end
	end
	ownTitle:SetText(#own > 0 and string.format("Your emotes (%d of 12)", #own) or "Your emotes")
	ownList:SetItems(own)
	ownList.empty:SetShown(#own == 0)
end

local function showTooltip(self)
	local key = self.emote
	if not key then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:AddLine("/" .. key)
	GameTooltip:AddLine(playerName() .. " " .. (ns.EmoteText(key, currentTarget()) or ""), 1, 1, 1, true)
	if ns.IsOwnEmote(key) then
		GameTooltip:AddLine("One of yours. Right-click to change it.", 0.7, 0.7, 0.7, true)
	end
	if ns.IsEmoteCommandTaken(key) then
		GameTooltip:AddLine("/" .. key .. " is used by the game or another addon, so this button is the way in.", 1, 0.82, 0, true)
	end
	GameTooltip:Show()
end

-- Right-click on one of your own: load it into the boxes below.
local function edit(key)
	local mine = ns.db.myEmotes[key]
	if not mine then
		return
	end
	nameBox:SetText(key)
	lineBox:SetText(mine.text or "")
	targetBox:SetText(mine.target or "")
	say(true, "Change /" .. key .. " below and press Save emote.")
	lineBox:SetFocus()
end

local function onGridClick(self, mouseButton)
	local key = self.emote
	if not key then
		return
	end
	if mouseButton == "RightButton" then
		edit(key)
	else
		ns.DoEmote(key)
	end
end

local function hookGrid()
	for _, made in ipairs(grid) do
		if not made.jujuHooked then
			made.jujuHooked = true
			made:SetScript("OnClick", onGridClick)
			made:SetScript("OnEnter", showTooltip)
			made:SetScript("OnLeave", function() GameTooltip:Hide() end)
		end
	end
end

local function fullRefresh()
	refresh()
	hookGrid()
end

local function saveEmote()
	local ok, message = ns.SaveOwnEmote(nameBox:GetText(), lineBox:GetText(), targetBox:GetText())
	say(ok, message)
	if ok then
		nameBox:SetText("")
		lineBox:SetText("")
		targetBox:SetText("")
		nameBox:ClearFocus()
		lineBox:ClearFocus()
		targetBox:ClearFocus()
	end
	fullRefresh()
end

-- The list of your own emotes. A row: /name and the start of what you do.
local function removeListedEmote(key)
	local ok, message = ns.RemoveOwnEmote(key)
	say(ok, message)
	if ok and nameBox:GetText() == key then
		nameBox:SetText("")
		lineBox:SetText("")
		targetBox:SetText("")
	end
	refresh()
end

kit.buildOn(page)
ownList = kit.scrollList(INNER, 100, function(row, key)
	if not row.made then
		kit.listRow(row, edit, removeListedEmote, function(item)
			local mine = ns.db.myEmotes[item] or {}
			GameTooltip:AddLine("/" .. item)
			GameTooltip:AddLine(playerName() .. " " .. (mine.text or ""), 1, 1, 1, true)
			if mine.target then
				GameTooltip:AddLine("At someone: " .. playerName() .. " " .. mine.target, 0.9, 0.9, 0.9, true)
			end
			GameTooltip:AddLine("Click to change it.", 0.7, 0.7, 0.7)
		end)
	end
	local mine = ns.db.myEmotes[key] or {}
	row.item = key
	row.Text:SetText("|cff3fbfaf/" .. key .. "|r  |cff808080" .. (mine.text or "") .. "|r")
end)
ownList.frame:SetPoint("TOPLEFT", ownTitle, "BOTTOMLEFT", -2, -4)
ownList.empty:SetText("None yet. Fill in the boxes above and press Save emote.")
kit.buildOn(frame)
frame.OwnEmoteList = ownList

local function removeEmote()
	local ok, message = ns.RemoveOwnEmote(nameBox:GetText())
	say(ok, message)
	if ok then
		nameBox:SetText("")
		lineBox:SetText("")
		targetBox:SetText("")
	end
	fullRefresh()
end

save:SetScript("OnClick", saveEmote)
remove:SetScript("OnClick", removeEmote)

-- Enter and Tab move down the boxes; Enter on the last one saves.
nameBox:SetScript("OnEnterPressed", function() lineBox:SetFocus() end)
nameBox:SetScript("OnTabPressed", function() lineBox:SetFocus() end)
lineBox:SetScript("OnEnterPressed", function() targetBox:SetFocus() end)
lineBox:SetScript("OnTabPressed", function() targetBox:SetFocus() end)
targetBox:SetScript("OnEnterPressed", saveEmote)
targetBox:SetScript("OnTabPressed", function() nameBox:SetFocus() end)

page:SetScript("OnHide", function()
	nameBox:ClearFocus()
	lineBox:ClearFocus()
	targetBox:ClearFocus()
end)

kit.onShow("emotes", fullRefresh)

-- The aim line follows your target while the page is open.
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
watcher:SetScript("OnEvent", function()
	if frame:IsShown() and page:IsShown() then
		refresh()
	end
end)
