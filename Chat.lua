-- Juju chat hook: turns what you type into troll just before it is sent.
-- Above the chat line it shows a tag (Troll or Plain, for the channel you are
-- in) and the troll version of what you have typed so far.
--
-- The game announces "ChatFrame.OnEditBoxPreSendText" after it has worked out
-- slash commands and the chat type, and before it reads the text to send. It
-- exists so addons can make final edits, so nothing of the game's own is
-- replaced or wrapped here. Macros do not go through it and are left alone.

local _, ns = ...

local function chatTypeOf(editBox)
	if editBox.GetChatType then
		return editBox:GetChatType()
	end
	return editBox:GetAttribute("chatType")
end

-- The game can mark text as secret, and addons may not look inside it.
local function isHidden(text)
	return type(text) ~= "string" or (issecretvalue ~= nil and issecretvalue(text))
end

-- For numbered channels: the channel's name, such as "Trade - City".
local function channelNameOf(editBox, chatType)
	if chatType ~= "CHANNEL" or not GetChannelName then
		return nil
	end
	local target
	if editBox.GetChannelTarget then
		target = editBox:GetChannelTarget()
	else
		target = editBox:GetAttribute("channelTarget")
	end
	if target == nil then
		return nil
	end
	local _, name = GetChannelName(target)
	if isHidden(name) then
		return nil
	end
	return name
end

-- What this chat box would send, in troll if its channel is switched on.
local function translateBox(editBox, text)
	local chatType = chatTypeOf(editBox)
	return ns.TranslateFor(chatType, text, channelNameOf(editBox, chatType))
end

---------------------------------------------------------------------------
-- Sending
---------------------------------------------------------------------------

local function onPreSendText(_, editBox)
	if not ns.IsActive() then
		return
	end
	local text = editBox:GetText()
	if isHidden(text) or text == "" then
		return
	end
	local trolly = translateBox(editBox, text)
	-- The next message gets a fresh flourish roll.
	ns.NewChatRoll()
	if trolly ~= text then
		editBox:SetText(trolly)
	end
end

EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", onPreSendText, ns)

---------------------------------------------------------------------------
-- Above the chat line: the tag and the preview
--
--   [ Troll ] Hey mon, da murlocs be comin' troo da wata!
--   Say: Hey man, the murlocs are coming through the water!
--
-- The tag says how the channel you are typing in will come out, Troll or
-- Plain, before you type anything. Click it to switch that channel. The
-- preview beside it shows the troll version of what you have typed so far.
---------------------------------------------------------------------------

local PADDING = 8
local MIN_WIDTH = 120
local GAP = 2

-- Both wear Blizzard's tooltip border, so they look like part of the game.
local function tooltipStyle(made)
	if not made.NineSlice then
		-- Without the template (an old client): a plain dark background.
		local background = made:CreateTexture(nil, "BACKGROUND")
		background:SetAllPoints()
		background:SetColorTexture(0, 0, 0, 0.8)
	end
end

local preview = CreateFrame("Frame", "JujuPreviewFrame", UIParent, "TooltipBackdropTemplate")
preview:SetFrameStrata("DIALOG")
preview:Hide()
tooltipStyle(preview)

local label = preview:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
label:SetPoint("TOPLEFT", PADDING, -PADDING)
label:SetJustifyH("LEFT")
label:SetJustifyV("TOP")
label:SetWordWrap(true)

local tag = CreateFrame("Button", "JujuTagFrame", UIParent, "TooltipBackdropTemplate")
tag:SetFrameStrata("DIALOG")
tag:Hide()
tooltipStyle(tag)

local tagText = tag:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
tagText:SetPoint("CENTER")

local focused          -- the chat box being typed in, if any
local watched = {}     -- chat boxes whose typing we already listen to
local tagKey           -- the channel switch the tag stands for
local tagHovered = false

local function showTagTooltip()
	if not tagKey or not ns.db then
		return
	end
	GameTooltip:SetOwner(tag, "ANCHOR_TOPLEFT")
	GameTooltip:AddLine("Juju")
	if ns.db.channels[tagKey] then
		GameTooltip:AddLine(ns.ChannelLabel(tagKey) .. " comes out in troll.", 1, 1, 1)
		GameTooltip:AddLine("Click to talk plainly here.", 0.7, 0.7, 0.7)
	else
		GameTooltip:AddLine(ns.ChannelLabel(tagKey) .. " is sent as you type it.", 1, 1, 1)
		GameTooltip:AddLine("Click to talk troll here.", 0.7, 0.7, 0.7)
	end
	GameTooltip:Show()
end

-- Draws the tag for this chat box. Returns how much room it takes up.
local function updateTag(editBox, chatType, channelName)
	tagKey = ns.db.tag and ns.ChannelKeyFor(chatType, channelName) or nil
	if not tagKey then
		tag:Hide()
		return 0
	end
	if ns.db.channels[tagKey] then
		tagText:SetText("Troll")
		tagText:SetTextColor(0.25, 0.75, 0.69)
	else
		tagText:SetText("Plain")
		tagText:SetTextColor(0.6, 0.6, 0.6)
	end
	local width = tagText:GetStringWidth() + PADDING * 2
	tag:SetSize(width, tagText:GetStringHeight() + PADDING * 2)
	tag:ClearAllPoints()
	tag:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, GAP)
	tag:Show()
	if tagHovered then
		showTagTooltip()
	end
	return width + GAP
end

local function update()
	local editBox = focused
	if not editBox or not ns.db or not ns.IsActive() then
		tag:Hide()
		preview:Hide()
		return
	end
	local chatType = chatTypeOf(editBox)
	local channelName = channelNameOf(editBox, chatType)
	local tagRoom = updateTag(editBox, chatType, channelName)

	local text = editBox:GetText()
	-- Preview off, nothing typed yet, or still typing a slash command.
	if not ns.db.preview or isHidden(text) or text == "" or strsub(text, 1, 1) == "/" then
		preview:Hide()
		return
	end
	local trolly = ns.TranslateFor(chatType, text, channelName)
	if trolly == text then
		preview:Hide()
		return
	end

	local width = math.max((editBox:GetWidth() or 0) - tagRoom, MIN_WIDTH)
	label:SetWidth(width - PADDING * 2)
	if strmatch(text, "^!%s") then
		-- A line starting with "! " is sent as typed, so say so.
		label:SetText("|cff3fbfafPlain:|r " .. trolly)
	elseif tagRoom > 0 then
		label:SetText(trolly) -- the tag beside it already says "Troll"
	else
		label:SetText("|cff3fbfafTroll:|r " .. trolly)
	end
	preview:SetSize(width, label:GetStringHeight() + PADDING * 2)
	preview:ClearAllPoints()
	preview:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", tagRoom, GAP)
	preview:Show()
end
ns.RefreshPreview = update

-- Clicking the tag switches troll speech for the channel being typed in.
tag:SetScript("OnClick", function()
	if tagKey and ns.db then
		ns.db.channels[tagKey] = not ns.db.channels[tagKey]
		ns.Refresh()
	end
end)
tag:SetScript("OnEnter", function()
	tagHovered = true
	showTagTooltip()
end)
tag:SetScript("OnLeave", function()
	tagHovered = false
	GameTooltip:Hide()
end)

EventRegistry:RegisterCallback("ChatFrame.OnEditBoxFocusGained", function(_, editBox)
	focused = editBox
	-- A new message, so a new flourish roll (or the Juju box's, if its
	-- "Put in chat" button just opened the chat line).
	ns.NewChatRoll()
	if not watched[editBox] then
		watched[editBox] = true
		editBox:HookScript("OnTextChanged", function(self)
			if self == focused then
				update()
			end
		end)
	end
	update()
end, preview)

local function onEditBoxClosed(_, editBox)
	if editBox == focused then
		focused = nil
		tagKey = nil
		tag:Hide()
		preview:Hide()
	end
end

EventRegistry:RegisterCallback("ChatFrame.OnEditBoxFocusLost", onEditBoxClosed, preview)
EventRegistry:RegisterCallback("ChatFrame.OnEditBoxHide", onEditBoxClosed, preview)
