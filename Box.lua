-- Juju box: a small window for trying things out. Type English on the top
-- line and the troll version appears underneath as you type. Nothing typed
-- here is said out loud. Open it with /juju.
--
-- "Put in chat" opens the chat line with what you typed already in it, so
-- one press of Enter sends it. The game does not let addons say things out
-- loud by themselves in the open world, so the last step is always yours,
-- and it goes through the normal chat path like anything else you type.
--
-- Click any word in the troll text to load it into the bottom half, which
-- teaches Juju your own words: a word and what it should
-- become, or a word to keep exactly as typed (a name, an RP term). They are
-- saved with your settings, so they survive updates to the addon.
--
-- The box has two pages, picked with the tabs at the top: Words (all of the
-- above) and Emotes (built by BoxEmotes.lua).

local _, ns = ...

local gsub = string.gsub

local WIDTH, HEIGHT = 480, 600
local PAD = 12                      -- space inside the inset
local INNER = WIDTH - 10 - PAD * 2  -- the inset is 10 narrower than the window
local HALF = (INNER - 18) / 2
local BORDER = 6                    -- Blizzard's text boxes draw their border outside the box
local R, G, B = 0.25, 0.75, 0.69    -- troll teal
local ROW = 22                      -- height of a row in a scrolling list
local PORTRAIT = "Interface\\Icons\\Racial_Troll_Berserk"

local HINT = "|cff808080Type someting up dere an' see how a true troll say it, mon.|r"

---------------------------------------------------------------------------
-- The window
--
-- Built from the game's own parts, so it looks like every other window in
-- Forever and follows Forever's art: ButtonFrameTemplate gives the frame,
-- title bar, round portrait, close button and inset; the tabs, text boxes
-- and buttons are Blizzard's too.
---------------------------------------------------------------------------

local frame = CreateFrame("Frame", "JujuBoxFrame", UIParent, "ButtonFrameTemplate")
frame:SetSize(WIDTH, HEIGHT)
frame:SetPoint("CENTER", 0, 40)
frame:SetFrameStrata("MEDIUM")
frame:SetToplevel(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
frame:Hide()

if frame.SetTitle then
	frame:SetTitle("Juju")
end
if frame.SetPortraitToAsset then
	frame:SetPortraitToAsset(PORTRAIT)
end

-- Escape closes it, like the game's own windows.
table.insert(UISpecialFrames, "JujuBoxFrame")

-- Where the pages go: the template's inset.
local inset = frame.Inset or frame

local close = frame.CloseButton
if not close then
	close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
end
close:SetScript("OnClick", function() frame:Hide() end)

-- What new parts are made on: the window, or one of its pages.
local parent = frame

local function text(font, anchor, relativeTo, relativePoint, x, y, words)
	local fontString = parent:CreateFontString(nil, "OVERLAY", font)
	fontString:SetPoint(anchor, relativeTo, relativePoint, x, y)
	fontString:SetJustifyH("LEFT")
	if words then
		fontString:SetText(words)
	end
	return fontString
end

-- Blizzard's text box. Its border sits BORDER outside the box itself.
local function editBox(width, maxLetters)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 20)
	box:SetAutoFocus(false)
	box:SetMaxLetters(maxLetters)
	-- Escape closes the whole window, from any line in it.
	box:SetScript("OnEscapePressed", function() frame:Hide() end)
	return box
end

-- on: what to make it on, if not the current parent. Parts made after
-- loading (the emote buttons) must say, or they land on the window itself
-- and stay in sight on every page.
local function button(label, width, on)
	local made = CreateFrame("Button", nil, on or parent, "UIPanelButtonTemplate")
	made:SetSize(width, 22)
	made:SetText(label)
	return made
end

-- A thin line between sections.
local function divider(anchor, y)
	local line = parent:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(1, 1, 1, 0.12)
	line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
	line:SetSize(INNER, 1)
	return line
end

-- A scrolling list in an inset, built the way Blizzard builds its own (the
-- AddOns list, for one): a ScrollBox, the slim scroll bar, a list view that
-- makes the rows and a data provider that holds the items.
--   setupRow(row, item) fills a row; rows are reused as the list scrolls, so
--   anything made only once goes behind "if not row.made".
-- Returns a list with :SetItems(items).
local function scrollList(width, height, setupRow)
	local box = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
	box:SetSize(width, height)
	local scrollBox = CreateFrame("Frame", nil, box, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
	scrollBox:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -20, 4)
	local scrollBar = CreateFrame("EventFrame", nil, box, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, -2)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 2)
	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW)
	view:SetElementInitializer("Button", setupRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)
	local list = { frame = box, scrollBox = scrollBox }
	function list:SetItems(items)
		scrollBox:SetDataProvider(CreateDataProvider(items), true) -- keep the scroll position
	end
	-- the hint shown while the list is empty
	list.empty = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	list.empty:SetPoint("TOPLEFT", box, "TOPLEFT", 10, -10)
	list.empty:SetPoint("RIGHT", box, "RIGHT", -10, 0)
	list.empty:SetJustifyH("LEFT")
	list.empty:SetWordWrap(true)
	return list
end

-- The parts every list row has: its text, a highlight under the mouse and a
-- small red X to remove it. onClick(item) and onRemove(item) say what to do.
local function listRow(row, onClick, onRemove, tooltip)
	row.made = true
	local highlight = row:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
	highlight:SetBlendMode("ADD")
	highlight:SetAlpha(0.5)
	row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.Text:SetPoint("LEFT", row, "LEFT", 6, 0)
	row.Text:SetPoint("RIGHT", row, "RIGHT", -26, 0)
	row.Text:SetJustifyH("LEFT")
	row.Text:SetWordWrap(false)
	row.Remove = CreateFrame("Button", nil, row, "UIPanelCloseButtonNoScripts")
	row.Remove:SetSize(20, 20)
	row.Remove:SetPoint("RIGHT", row, "RIGHT", -2, 0)
	row.Remove:SetScript("OnClick", function(self) onRemove(self:GetParent().item) end)
	row.Remove:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Remove")
		GameTooltip:Show()
	end)
	row.Remove:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row:SetScript("OnClick", function(self) onClick(self.item) end)
	row:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		tooltip(self.item)
		GameTooltip:Show()
	end)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- What kind of troll this character is, in the strip above the inset. Click
-- for the next voice, right-click for the one before.
local voiceButton = button("Voice: Darkspear", 180)
voiceButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -30)
voiceButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

---------------------------------------------------------------------------
-- Pages and tabs: Blizzard tabs along the bottom, like the Character and
-- Friends windows.
---------------------------------------------------------------------------

local pages = {}   -- key -> { frame, tab, index, refresh }
local pageOrder = {}
local shownPage = "words"

local function newPage(key, label)
	local index = #pageOrder + 1
	local page = CreateFrame("Frame", nil, inset)
	page:SetAllPoints()
	page:Hide()
	local tab = CreateFrame("Button", "JujuBoxFrameTab" .. index, frame, "PanelTabButtonTemplate")
	tab:SetID(index)
	tab:SetText(label)
	if index == 1 then
		tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 11, 2)
	end
	pages[key] = { frame = page, tab = tab, index = index, label = label }
	pageOrder[index] = key
	tab:SetScript("OnClick", function() ns.ShowBoxPage(key) end)
	return page
end

-- Shows one page of the box and hides the others.
function ns.ShowBoxPage(key)
	if not pages[key] then
		key = "words"
	end
	shownPage = key
	for name, page in pairs(pages) do
		page.frame:SetShown(name == key)
	end
	if PanelTemplates_SetTab then
		PanelTemplates_SetTab(frame, pages[key].index)
	end
	if pages[key].refresh then
		pages[key].refresh()
	end
end

function ns.BoxPage()
	return shownPage
end

local wordsPage = newPage("words", "Words")
newPage("emotes", "Emotes")
if PanelTemplates_SetNumTabs then
	PanelTemplates_SetNumTabs(frame, #pageOrder) -- also lines the tabs up
end
parent = wordsPage

---------------------------------------------------------------------------
-- English in, troll out
---------------------------------------------------------------------------

local inputLabel = text("GameFontHighlightSmall", "TOPLEFT", inset, "TOPLEFT", PAD, -PAD, "Type English here:")

local input = editBox(INNER - BORDER, ns.Translator.MAX_BYTES)
input:SetPoint("TOPLEFT", inputLabel, "BOTTOMLEFT", BORDER, -4)

local outputLabel = text("GameFontHighlightSmall", "TOPLEFT", inputLabel, "BOTTOMLEFT", 0, -34,
	"What everyone would see (click a word to change how Juju says it):")

-- The troll text sits in an inset of its own so that its words can be
-- clicked: each translated word is written as a link, the way item links
-- are in chat.
local outputFrame = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
outputFrame:SetPoint("TOPLEFT", outputLabel, "BOTTOMLEFT", 0, -4)
outputFrame:SetSize(INNER, 96)
outputFrame:EnableMouse(true)
outputFrame:SetHyperlinksEnabled(true)
-- It covers part of the window, so let it drag the window too.
outputFrame:RegisterForDrag("LeftButton")
outputFrame:SetScript("OnDragStart", function() frame:StartMoving() end)
outputFrame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

local output = outputFrame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
output:SetPoint("TOPLEFT", outputFrame, "TOPLEFT", 8, -8)
output:SetJustifyH("LEFT")
output:SetWidth(INNER - 16)
output:SetJustifyV("TOP")
output:SetWordWrap(true)

-- In the button bar along the bottom of the window, like Blizzard's own.
local putInChat = button("Put in chat", 130)
putInChat:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 4)

text("GameFontDisableSmall", "BOTTOMLEFT", frame, "BOTTOMLEFT", PAD + 4, 10,
	"Nothing here is said out loud until you press Put in chat.")

---------------------------------------------------------------------------
-- Ya Own Juju: teaching Juju your own words. Every witch doctor mixes
-- dey juju a lil' different, an' so can you.
---------------------------------------------------------------------------

local teachLine = divider(outputFrame, -14)

local teachTitle = text("GameFontNormal", "TOPLEFT", teachLine, "BOTTOMLEFT", 0, -10, "Ya Own Juju")

local englishLabel = text("GameFontHighlightSmall", "TOPLEFT", teachTitle, "BOTTOMLEFT", 0, -8, "English word or phrase:")
local becomesLabel = text("GameFontHighlightSmall", "TOPLEFT", englishLabel, "TOPLEFT", HALF + 18, 0, "Becomes (leave empty to keep it as typed):")

local english = editBox(HALF - BORDER, 40)
english:SetPoint("TOPLEFT", englishLabel, "BOTTOMLEFT", BORDER, -4)

local becomes = editBox(HALF - BORDER, 60)
becomes:SetPoint("TOPLEFT", becomesLabel, "BOTTOMLEFT", BORDER, -4)

local save = button("Save word", 110)
save:SetPoint("TOPLEFT", englishLabel, "BOTTOMLEFT", -2, -32)

local remove = button("Remove word", 120)
remove:SetPoint("LEFT", save, "RIGHT", 6, 0)

local status = text("GameFontHighlightSmall", "LEFT", remove, "RIGHT", 10, 0)
status:SetWidth(INNER - 110 - 120 - 6 - 10)
status:SetWordWrap(true)

local wordsTitle = text("GameFontNormalSmall", "TOPLEFT", save, "BOTTOMLEFT", 2, -12, "Your words")

-- Set up below, once the behaviour it calls exists.
local wordList

parent = frame

-- For BoxEmotes.lua, which builds the Emotes page with the same parts.
ns.BoxKit = {
	frame = frame, inset = inset, page = pages.emotes.frame,
	PAD = PAD, INNER = INNER, HALF = HALF, BORDER = BORDER, R = R, G = G, B = B,
	text = text, editBox = editBox, button = button, divider = divider,
	scrollList = scrollList, listRow = listRow, ROW = ROW,
	-- the parts made after this go on the given page
	buildOn = function(page) parent = page end,
	-- called whenever the page is shown
	onShow = function(key, refresh) pages[key].refresh = refresh end,
}

-- For the tests, and for anyone poking at the box from a macro.
frame.Input, frame.Output, frame.OutputFrame, frame.PutInChatButton = input, output, outputFrame, putInChat
frame.English, frame.Becomes, frame.SaveButton, frame.RemoveButton = english, becomes, save, remove
frame.Status, frame.WordsTitle = status, wordsTitle
frame.VoiceButton = voiceButton
frame.WordsTab, frame.EmotesTab = pages.words.tab, pages.emotes.tab

---------------------------------------------------------------------------
-- Behaviour
---------------------------------------------------------------------------

local function readable(value)
	return type(value) == "string" and not (issecretvalue and issecretvalue(value))
end

-- How a word looks in the list: gold = shinies, or bert (kept as typed).
local function wordLine(entry)
	if entry[2] == false then
		return entry[1] .. "  |cff808080(kept as typed)|r"
	end
	return entry[1] .. "  |cff808080=|r  |cff3fbfaf" .. entry[2] .. "|r"
end

local function showWords()
	local list = ns.ListWords()
	wordsTitle:SetText(#list > 0 and string.format("Your words (%d)", #list) or "Your words")
	wordList:SetItems(list)
	wordList.empty:SetShown(#list == 0)
end

-- Which typed word became which troll word, for the text now on show.
local shownWords = {}

local LINK = "|Haddon:Juju:%d|h%s|h"

-- Writes each translated word in the troll text as a clickable link. The words
-- are found in order, starting after anything a flourish put in front.
local function withLinks(trolly, words)
	local parts = {}
	local pos = (words.offset or 0) + 1
	local done = 1 -- everything before this is already in parts
	for index, word in ipairs(words) do
		local first, last = strfind(trolly, word.troll, pos, true)
		if not first and index == 1 then
			-- a flourish in front gives the first word a capital letter
			local capital = gsub(word.troll, "^(['\"]*)(%l)", function(marks, letter)
				return marks .. strupper(letter)
			end, 1)
			first, last = strfind(trolly, capital, pos, true)
		end
		if first then
			parts[#parts + 1] = strsub(trolly, done, first - 1)
			parts[#parts + 1] = format(LINK, index, strsub(trolly, first, last))
			pos, done = last + 1, last + 1
		end
	end
	parts[#parts + 1] = strsub(trolly, done)
	return table.concat(parts)
end

local function update()
	if not frame:IsShown() or not ns.db then
		return
	end
	voiceButton:SetText("Voice: " .. ns.GetVoice().name)
	if shownPage ~= "words" then
		if pages[shownPage].refresh then
			pages[shownPage].refresh()
		end
		return
	end
	local typed = input:GetText()
	local empty = not readable(typed) or not strfind(typed, "%S")
	shownWords = {}
	if empty then
		output:SetText(HINT)
	else
		output:SetText(withLinks(ns.TranslatePreview(typed, shownWords), shownWords))
	end
	putInChat:SetEnabled(not empty)
	showWords()
end
ns.RefreshBox = update

local function say(ok, message)
	if ok then
		status:SetTextColor(R, G, B)
	else
		status:SetTextColor(1, 0.35, 0.3)
	end
	status:SetText(message)
end

-- Clicking a word in the list loads it into the boxes above to change it.
local function editWord(entry)
	english:SetText(entry[1])
	becomes:SetText(type(entry[2]) == "string" and entry[2] or "")
	say(true, "Change \"" .. entry[1] .. "\" above and press Save word.")
	becomes:SetFocus()
end

local function removeListedWord(entry)
	local ok, message = ns.RemoveWord(entry[1])
	say(ok, message)
end

parent = wordsPage
wordList = scrollList(INNER, 186, function(row, entry)
	if not row.made then
		listRow(row, editWord, removeListedWord, function(item)
			GameTooltip:AddLine(wordLine(item))
			GameTooltip:AddLine("Click to change it.", 0.7, 0.7, 0.7)
		end)
	end
	row.item = entry
	row.Text:SetText(wordLine(entry))
end)
wordList.frame:SetPoint("TOPLEFT", wordsTitle, "BOTTOMLEFT", -2, -4)
wordList.empty:SetText("None yet. Try gold, becomes, shinies. Or a name to keep exactly as typed.")
parent = frame
frame.WordList = wordList

local function saveWord()
	local word = english:GetText()
	if not readable(word) or not strfind(word, "%a") then
		say(false, "Type the English word first.")
		english:SetFocus()
		return
	end
	local ok, message = ns.SetWord(word, readable(becomes:GetText()) and becomes:GetText() or "")
	say(ok, message)
	if ok then
		english:SetText("")
		becomes:SetText("")
		english:SetFocus()
	end
end

local function removeWord()
	local word = english:GetText()
	if not readable(word) or not strfind(word, "%a") then
		say(false, "Type the English word to remove.")
		english:SetFocus()
		return
	end
	local ok, message = ns.RemoveWord(word)
	say(ok, message)
	if ok then
		english:SetText("")
		becomes:SetText("")
	end
end

local function wordFromLink(link)
	local index = tonumber(strmatch(link or "", "^addon:Juju:(%d+)$"))
	return index and shownWords[index]
end

-- Clicking a word in the troll text loads it into Ya Own Juju.
outputFrame:SetScript("OnHyperlinkClick", function(_, link)
	local word = wordFromLink(link)
	if not word then
		return
	end
	local key = strlower(word.english)
	local mine = ns.db.words[key]
	english:SetText(key)
	becomes:SetText(type(mine) == "string" and mine or "")
	say(true, "\"" .. key .. "\" says \"" .. word.troll .. "\" now. Type a new word, or leave it empty to keep it as typed.")
	becomes:SetFocus()
end)

outputFrame:SetScript("OnHyperlinkEnter", function(self, link)
	local word = wordFromLink(link)
	if not word then
		return
	end
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
	GameTooltip:AddLine("\"" .. word.english .. "\" became \"" .. word.troll .. "\"")
	GameTooltip:AddLine("Click to change how Juju says it.", 0.7, 0.7, 0.7)
	GameTooltip:Show()
end)

outputFrame:SetScript("OnHyperlinkLeave", function()
	GameTooltip:Hide()
end)

-- The English goes into the chat line, exactly as if you had typed it
-- there: the preview above the chat line shows the troll, and Enter sends it.
local function putTextInChat()
	local typed = input:GetText()
	if not readable(typed) or not strfind(typed, "%S") then
		return
	end
	input:ClearFocus()
	-- The chat line borrows this box's flourish roll, so it shows the same.
	ns.pendingRoll = ns.boxRoll
	local open = (ChatFrameUtil and ChatFrameUtil.OpenChat) or ChatFrame_OpenChat
	if open then
		open(typed)
	end
end
putInChat:SetScript("OnClick", putTextInChat)

save:SetScript("OnClick", saveWord)
remove:SetScript("OnClick", removeWord)

input:SetScript("OnTextChanged", update)
-- Enter lets go of the keyboard but leaves the box open to read.
input:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
input:SetScript("OnTabPressed", function() english:SetFocus() end)

-- Enter on the English line moves across, filling in what the word becomes
-- now if it is already one of yours.
english:SetScript("OnEnterPressed", function(self)
	local word = self:GetText()
	if readable(word) then
		local key = strlower(gsub(gsub(gsub(word, "^%s+", ""), "%s+$", ""), "%s+", " "))
		local current = ns.db.words[key]
		local typedTroll = becomes:GetText()
		if type(current) == "string" and (not readable(typedTroll) or typedTroll == "") then
			becomes:SetText(current)
		end
	end
	becomes:SetFocus()
end)
english:SetScript("OnTabPressed", function() becomes:SetFocus() end)

becomes:SetScript("OnEnterPressed", saveWord)
becomes:SetScript("OnTabPressed", function() input:SetFocus() end)

local function showVoiceTooltip()
	local voice = ns.GetVoice()
	GameTooltip:SetOwner(voiceButton, "ANCHOR_BOTTOM")
	GameTooltip:AddLine("Voice: " .. voice.name)
	GameTooltip:AddLine(voice.about, 1, 1, 1, true)
	GameTooltip:AddLine("Click for the next voice, right-click for the one before. Each character keeps its own.", 0.7, 0.7, 0.7, true)
	if not ns.db.flourish then
		GameTooltip:AddLine("Switch on Troll flourishes to hear the voice's own openers and closers.", 1, 0.82, 0, true)
	end
	GameTooltip:Show()
end

voiceButton:SetScript("OnClick", function(self, mouseButton)
	ns.SetVoice(ns.NextVoice(mouseButton == "RightButton" and -1 or 1))
	if self:IsMouseOver() then
		showVoiceTooltip()
	end
end)
voiceButton:SetScript("OnEnter", showVoiceTooltip)
voiceButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

local openOn -- the page to open on next, if not Words

frame:SetScript("OnShow", function()
	status:SetText("")
	ns.NewBoxRoll()
	ns.ShowBoxPage(openOn or "words")
	openOn = nil
	update()
	if shownPage ~= "words" then
		return
	end
	input:SetFocus()
	-- When opened from a slash command the chat box is still closing and
	-- would take the keyboard back, so ask again a moment later.
	C_Timer.After(0, function()
		if frame:IsShown() and shownPage == "words" then
			input:SetFocus()
		end
	end)
end)

frame:SetScript("OnHide", function()
	input:ClearFocus()
	english:ClearFocus()
	becomes:ClearFocus()
end)

-- Opens the box. With words, they are put on the English line. page picks
-- the page to show: "words" (the default) or "emotes".
function ns.OpenBox(words, page)
	if words and words ~= "" then
		input:SetText(words)
		page = "words"
	end
	if frame:IsShown() then
		ns.ShowBoxPage(page or shownPage)
		update()
		if shownPage == "words" then
			input:SetFocus()
		end
	else
		openOn = page
		frame:Show()
	end
end

function ns.ToggleBox()
	if frame:IsShown() then
		frame:Hide()
	else
		ns.OpenBox()
	end
end
