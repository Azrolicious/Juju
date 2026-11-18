-- A tiny stand-in for the game client, just big enough to load Juju and
-- push chat messages through it the way the real chat box does.
--
-- The chat box here follows the same order of steps as the game's own
-- ChatFrameEditBoxBaseMixin:SendText: work out slash commands, announce
-- "ChatFrame.OnEditBoxPreSendText", then read the text and send it.

local Mock = {}

local function noop() end

local function widget(methods)
	local object = {}
	for _, name in ipairs(methods) do
		object[name] = noop
	end
	return object
end

-- Chat-type slash commands the fake chat box understands.
local CHAT_COMMANDS = {
	["/s"] = "SAY", ["/say"] = "SAY",
	["/y"] = "YELL", ["/yell"] = "YELL",
	["/e"] = "EMOTE", ["/me"] = "EMOTE", ["/emote"] = "EMOTE",
	["/p"] = "PARTY", ["/party"] = "PARTY",
	["/raid"] = "RAID", ["/rw"] = "RAID_WARNING",
	["/g"] = "GUILD", ["/guild"] = "GUILD", ["/o"] = "OFFICER",
}

-- Mock.new{ race = "Troll", name = "Zanjin", target = nil, saved = {...} }
function Mock.new(config)
	config = config or {}
	local game = {
		sent = {},        -- every chat message that left the client
		printed = {},     -- every line Juju printed to the chat window
		settings = {},    -- settings panel entries, by variable name
		frames = {},      -- frames created by the addon
		target = config.target,
		openedCategory = nil,
	}

	local env = setmetatable({}, { __index = _G })
	game.env = env
	env._G = env

	-- string and table helpers the game provides as globals
	env.strmatch, env.strlower, env.strupper, env.strsub = string.match, string.lower, string.upper, string.sub
	env.strfind = string.find
	env.format = string.format
	env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end

	-- saved variables, as if read back from disk
	if config.saved then
		env.JujuDB = config.saved.JujuDB
		env.JujuCharDB = config.saved.JujuCharDB
	end

	-- units
	-- config.sex: 2 male, 3 female, as the game's UnitSex returns
	env.UnitSex = function(unit)
		if unit == "player" then
			return config.sex or 2
		end
	end
	env.UnitRace = function(unit)
		if unit == "player" then
			local race = config.race or "Troll"
			return race, race
		end
	end
	-- creatures and other units: game.units[token] = { name = "Hogger",
	-- player = false, pet = false, hostile = true }
	game.units = {}
	env.UnitExists = function(unit) return game.units[unit] ~= nil end
	env.UnitIsPlayer = function(unit)
		if game.units[unit] then
			return game.units[unit].player == true
		end
		-- game.target, a plain name, is a player you have targeted
		return unit == "target" and game.target ~= nil
	end
	env.UnitPlayerControlled = function(unit) return game.units[unit] ~= nil and game.units[unit].pet == true end
	env.UnitCanAttack = function(_, unit) return game.units[unit] ~= nil and game.units[unit].hostile == true end
	env.UnitIsUnit = function(a, b) return a == b end
	local unitExists = env.UnitExists
	env.UnitExists = function(unit) return unitExists(unit) or (unit == "target" and game.target ~= nil) end

	-- messages sent by addon code: emotes
	env.C_ChatInfo = { SendChatMessage = function(text, chatType, _, target)
		if game.blockSending then
			error("blocked")
		end
		game.sent[#game.sent + 1] = { text = text, chatType = chatType, target = target }
	end }

	-- guild, friends and Battle.net friends: config.guild, config.friends,
	-- config.battlenet = lists of names
	env.IsInGuild = function() return config.guild ~= nil end
	env.GetNumGuildMembers = function() return config.guild and #config.guild or 0 end
	env.GetGuildRosterInfo = function(index) return config.guild[index] end
	env.C_GuildInfo = { GuildRoster = function() game.rosterRequested = true end }
	env.C_FriendList = {
		GetNumFriends = function() return config.friends and #config.friends or 0 end,
		GetFriendInfoByIndex = function(index) return { name = config.friends[index] } end,
	}
	env.BNGetNumFriends = function() return config.battlenet and #config.battlenet or 0 end
	env.C_BattleNet = {
		GetFriendNumGameAccounts = function() return 1 end,
		GetFriendGameAccountInfo = function(friend)
			local entry = config.battlenet[friend]
			return { clientProgram = entry.program or "WoW", characterName = entry.name }
		end,
	}
	env.UnitName = function(unit)
		if game.units[unit] then
			return game.units[unit].name
		elseif unit == "player" then
			return config.name or "Zanjin"
		elseif unit == "target" then
			return game.target
		elseif config.group then
			local index = tonumber(string.match(unit, "^party(%d+)$"))
			return index and config.group[index]
		end
	end
	-- numbered channels: config.channels = { [1] = "General - Durotar", ... }
	env.GetChannelName = function(id)
		id = tonumber(id) or 0
		local name = config.channels and config.channels[id]
		if name then
			return id, name
		end
		return 0, nil
	end
	env.GetNumGroupMembers = function() return config.group and #config.group + 1 or 0 end
	env.IsInRaid = function() return false end

	-- chat window
	env.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, message) game.printed[#game.printed + 1] = message end,
	}
	env.SlashCmdList = {}
	-- opening the chat line with text in it, as shift-clicking a link does
	env.ChatFrameUtil = { OpenChat = function(text) game.openedChat = text end }
	env.GameTooltip = widget({ "SetOwner", "AddLine", "Show", "Hide" })
	env.UIParent = {}
	env.UISpecialFrames = {}
	env.ChatFontNormal = {}

	-- timers run when the test says a frame has passed
	local timers = {}
	env.C_Timer = { After = function(_, func) timers[#timers + 1] = func end }
	function game:nextFrame()
		local due = timers
		timers = {}
		for _, func in ipairs(due) do
			func()
		end
	end

	-- the game's callback registry
	local callbacks = {}
	env.EventRegistry = {
		RegisterCallback = function(_, event, func, owner)
			assert(type(event) == "string" and type(func) == "function", "bad RegisterCallback arguments")
			assert(owner ~= nil and type(owner) ~= "number", "callback owner must be a non-number value")
			callbacks[event] = callbacks[event] or {}
			callbacks[event][owner] = func
		end,
		TriggerEvent = function(_, event, ...)
			for owner, func in pairs(callbacks[event] or {}) do
				func(owner, ...)
			end
		end,
	}
	game.callbacks = callbacks

	-- frames
	local function region(methods)
		local object = widget({ "SetPoint", "SetAllPoints", "ClearAllPoints", "SetSize", "SetWidth", "SetHeight" })
		object.shown = true
		function object:Show() self.shown = true end
		function object:Hide() self.shown = false end
		function object:SetShown(shown) self.shown = shown and true or false end
		function object:IsShown() return self.shown end
		for _, name in ipairs(methods) do
			object[name] = noop
		end
		return object
	end

	-- frame type names are not case-sensitive in the game
	local FRAME_TYPES = { frame = "Frame", editbox = "EditBox", button = "Button", eventframe = "Frame" }

	env.CreateFrame = function(frameType, name, parent, template)
		frameType = FRAME_TYPES[string.lower(tostring(frameType))]
			or error("mock does not know frame type " .. tostring(frameType))
		local frame = region({
			"SetFrameStrata", "SetToplevel", "SetClampedToScreen", "EnableMouse", "SetHyperlinksEnabled",
			"SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
		})
		frame.events, frame.scripts, frame.shown = {}, {}, true
		frame.fontStrings = {}
		frame.name, frame.frameType, frame.parent, frame.template = name, frameType, parent, template
		function frame:RegisterEvent(event) self.events[event] = true end
		function frame:UnregisterEvent(event) self.events[event] = nil end
		function frame:SetScript(script, handler) self.scripts[script] = handler end
		function frame:run(script, ...)
			if self.scripts[script] then
				return self.scripts[script](self, ...)
			end
		end
		function frame:Show()
			if not self.shown then
				self.shown = true
				self:run("OnShow")
			end
		end
		function frame:Hide()
			if self.shown then
				self.shown = false
				self:run("OnHide")
			end
		end
		function frame:IsShown() return self.shown end
		function frame:SetShown(shown) if shown then self:Show() else self:Hide() end end
		-- shown on screen: this frame and every frame it sits in
		function frame:IsVisible()
			local at = self
			while at do
				if at.shown == false then
					return false
				end
				at = at.parent
			end
			return true
		end
		function frame:GetWidth() return 400 end
		function frame:CreateTexture()
			return region({ "SetColorTexture", "SetTexture", "SetAtlas", "SetBlendMode", "SetAlpha", "SetVertexColor" })
		end
		function frame:CreateFontString()
			local fontString = region({ "SetJustifyH", "SetJustifyV", "SetWordWrap", "SetTextColor" })
			function fontString:SetText(text) self.text = text end
			function fontString:GetText() return self.text end
			function fontString:GetStringHeight() return 14 end
			function fontString:GetStringWidth() return 7 * #(self.text or "") end
			frame.fontString = fontString
			frame.fontStrings[#frame.fontStrings + 1] = fontString
			return fontString
		end

		if frameType == "EditBox" then
			for _, method in ipairs({ "SetFontObject", "SetAutoFocus", "SetMaxLetters", "SetTextInsets", "HighlightText" }) do
				frame[method] = noop
			end
			frame.text, frame.focus = "", false
			function frame:GetText() return self.text end
			function frame:SetText(text)
				self.text = text
				self:run("OnTextChanged", false)
			end
			function frame:SetFocus() game.focus = self end
			function frame:ClearFocus() if game.focus == self then game.focus = nil end end
			function frame:HasFocus() return game.focus == self end
			-- the player typing: the text changes with userInput = true
			function frame:userType(text)
				game.focus = self
				self.text = text
				self:run("OnTextChanged", true)
			end
		elseif frameType == "Button" then
			function frame:SetText(text) self.text = text end
			function frame:GetText() return self.text end
			function frame:RegisterForClicks() end
			function frame:IsMouseOver() return false end
			frame.enabled = true
			function frame:SetEnabled(enabled) self.enabled = enabled and true or false end
			function frame:IsEnabled() return self.enabled end
			-- a disabled or hidden button ignores clicks, as in the game
			function frame:click(mouseButton)
				if self.enabled and self.shown then
					self:run("OnClick", mouseButton or "LeftButton")
				end
			end
		end

		function frame:GetParent() return self.parent end
		function frame:SetID(id) self.id = id end
		function frame:GetID() return self.id end

		-- the parts of Blizzard's templates that Juju uses
		if template == "ButtonFrameTemplate" then
			frame.NineSlice = {}
			frame.Inset = env.CreateFrame("Frame", nil, frame, "InsetFrameTemplate")
			frame.CloseButton = env.CreateFrame("Button", nil, frame, "UIPanelCloseButton")
			function frame:SetTitle(title) self.title = title end
			function frame:SetPortraitToAsset(texture) self.portraitTexture = texture end
		elseif template == "InsetFrameTemplate" or template == "TooltipBackdropTemplate" then
			frame.NineSlice = {}
		elseif template == "WowScrollBoxList" then
			-- a list with every row made at once (the real one makes only
			-- the rows in view, and reuses them as it scrolls)
			frame.rows = {}
			function frame:SetDataProvider(provider)
				local items = provider.items
				for index, item in ipairs(items) do
					local row = self.rows[index]
					if not row then
						row = env.CreateFrame(self.view.frameType, nil, self)
						self.rows[index] = row
					end
					row:Show()
					self.view.initializer(row, item)
				end
				for index = #items + 1, #self.rows do
					self.rows[index]:Hide()
				end
			end
			-- the rows on show, for tests
			function frame:ShownRows()
				local shown = {}
				for _, row in ipairs(self.rows) do
					if row.shown then shown[#shown + 1] = row end
				end
				return shown
			end
		elseif template == "PanelTabButtonTemplate" and parent then
			parent.Tabs = parent.Tabs or {}
			table.insert(parent.Tabs, frame)
		end

		game.frames[#game.frames + 1] = frame
		if name then
			env[name] = frame
		end
		return frame
	end

	-- settings panel
	env.Settings = {
		VarType = { Boolean = "boolean", String = "string" },
		RegisterVerticalLayoutCategory = function(name)
			local category = { name = name, GetID = function() return name end }
			local layout = { initializers = {}, AddInitializer = function(self, init) self.initializers[#self.initializers + 1] = init end }
			game.category, game.layout = category, layout
			return category, layout
		end,
		RegisterProxySetting = function(category, variable, variableType, name, default, get, set)
			assert(category == game.category, "setting registered on the wrong category")
			assert(type(variable) == "string" and type(name) == "string", "setting needs a variable and a name")
			assert(type(default) == variableType, variable .. ": default must be a " .. variableType)
			assert(type(get()) == variableType, variable .. ": getter must return a " .. variableType)
			local setting = { variable = variable, name = name, default = default, get = get, set = set }
			function setting:GetVariableType() return variableType end
			assert(not game.settings[variable], variable .. " registered twice")
			game.settings[variable] = setting
			return setting
		end,
		CreateCheckbox = function(category, setting, tooltip)
			assert(setting:GetVariableType() == "boolean")
			setting.tooltip = tooltip
		end,
		CreateDropdown = function(category, setting, options, tooltip)
			assert(setting:GetVariableType() == "string", "dropdowns here hold text")
			setting.options = options()
			setting.tooltip = tooltip
		end,
		CreateControlTextContainer = function()
			local container = { data = {} }
			function container:Add(value, label, tooltip)
				self.data[#self.data + 1] = { value = value, label = label, text = label, tooltip = tooltip }
			end
			function container:GetData() return self.data end
			return container
		end,
		RegisterAddOnCategory = function(category) game.registeredCategory = category end,
		OpenToCategory = function(id) game.openedCategory = id end,
	}
	-- Blizzard's scrolling list helpers
	env.CreateScrollBoxListLinearView = function()
		local view = {}
		function view:SetElementExtent(extent) self.extent = extent end
		function view:SetElementInitializer(frameType, initializer) self.frameType, self.initializer = frameType, initializer end
		return view
	end
	env.ScrollUtil = { InitScrollBoxListWithScrollBar = function(box, bar, view) box.view, box.scrollBar = view, bar end }
	env.CreateDataProvider = function(items) return { items = items or {} } end

	-- Blizzard's tab helpers
	env.PanelTemplates_SetNumTabs = function(owner, count) owner.numTabs = count end
	env.PanelTemplates_SetTab = function(owner, id) owner.selectedTab = id end

	env.CreateSettingsListSectionHeaderInitializer = function(text) return { header = text } end

	-----------------------------------------------------------------------
	-- Driving the game
	-----------------------------------------------------------------------

	-- Loads the addon the way the client does: every file listed in the
	-- .toc, in order, each handed the addon name and one shared table.
	function game:load(root)
		self.ns = {}
		self.files = {}
		for line in io.lines(root .. "/Juju.toc") do
			line = line:gsub("%s+$", "")
			if line ~= "" and line:sub(1, 1) ~= "#" then
				local chunk = assert(loadfile(root .. "/" .. line))
				setfenv(chunk, env)
				chunk("Juju", self.ns)
				self.files[#self.files + 1] = line
			end
		end
		self:fire("ADDON_LOADED", "Juju")
		self:fire("PLAYER_LOGIN")
		return self
	end

	function game:fire(event, ...)
		for _, frame in ipairs(self.frames) do
			if frame.events[event] and frame.scripts.OnEvent then
				frame.scripts.OnEvent(frame, event, ...)
			end
		end
	end

	-- A chat box. Behaves like the game's, as far as Juju can tell.
	function game:editBox()
		local box = { text = "", chatType = "SAY", sticky = "SAY", hooks = {} }
		function box:GetText() return self.text end
		function box:SetText(text)
			self.text = text
			for _, hook in ipairs(self.hooks) do
				hook(self, false)
			end
		end
		function box:GetChatType() return self.chatType end
		function box:SetChatType(chatType) self.chatType = chatType end
		function box:GetAttribute(name) if name == "chatType" then return self.chatType end end
		function box:GetChannelTarget()
			local id = env.GetChannelName(self.channelTarget)
			return id
		end
		function box:GetWidth() return 400 end
		function box:HookScript(script, handler)
			assert(script == "OnTextChanged", "unexpected script hook: " .. tostring(script))
			self.hooks[#self.hooks + 1] = handler
		end

		function box:ParseText()
			local text = self.text
			if text:sub(1, 1) ~= "/" then
				return
			end
			local command = text:match("^(/%S+)") or ""
			local message = text:sub(#command + 2):match("^%s*(.*)$")
			local lowered = command:lower()
			if CHAT_COMMANDS[lowered] then
				self.chatType = CHAT_COMMANDS[lowered]
				self:SetText(message)
			elseif lowered == "/w" or lowered == "/whisper" then
				local target, rest = message:match("^(%S+)%s*(.*)$")
				self.chatType, self.tellTarget = "WHISPER", target
				self:SetText(rest or "")
			elseif lowered:match("^/%d+$") then
				self.chatType, self.channelTarget = "CHANNEL", tonumber(lowered:sub(2))
				self:SetText(message)
			else
				for name, handler in pairs(env.SlashCmdList) do
					local index = 1
					while env["SLASH_" .. name .. index] do
						if env["SLASH_" .. name .. index] == lowered then
							handler(message, self)
							self:SetText("")
							return
						end
						index = index + 1
					end
				end
				self:SetText("") -- unknown command
			end
		end

		function box:SendText()
			self:ParseText()
			env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxPreSendText", self)
			local chatType = self:GetChatType()
			local text = self:GetText()
			if text:find("%s*[^%s]+") then
				local target
				if chatType == "WHISPER" or chatType == "BN_WHISPER" then
					target = self.tellTarget
				elseif chatType == "CHANNEL" then
					target = self.channelTarget
				end
				game.sent[#game.sent + 1] = { text = text, chatType = chatType, target = target }
			end
		end

		-- Type a line and press Enter. Returns what was sent, if anything.
		function box:say(text)
			local before = #game.sent
			env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusGained", self)
			self:SetText(text)
			self:SendText()
			self:SetText("")
			self.chatType = self.sticky
			env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxHide", self)
			local message = game.sent[before + 1]
			return message and message.text, message
		end

		-- Type without pressing Enter.
		function box:type(text)
			env.EventRegistry:TriggerEvent("ChatFrame.OnEditBoxFocusGained", self)
			self:SetText(text)
		end

		return box
	end

	return game
end

return Mock
