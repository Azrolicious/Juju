-- Juju settings panel: Options > AddOns > Juju (or /juju config).
-- Built with the game's own settings list, so it looks like every other page.

local _, ns = ...

local category

function ns.OpenOptions()
	if category then
		Settings.OpenToCategory(category:GetID())
	else
		ns.Print("The settings panel is not available. Type /juju help for the chat commands.")
	end
end

function ns.BuildOptions()
	if category or not (Settings and Settings.RegisterVerticalLayoutCategory) then
		return
	end

	local db = ns.db
	local layout
	category, layout = Settings.RegisterVerticalLayoutCategory("Juju")

	local function header(text)
		if layout and CreateSettingsListSectionHeaderInitializer then
			layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
		end
	end

	local function checkbox(variable, label, tooltip, default, get, set)
		local setting = Settings.RegisterProxySetting(category, variable,
			Settings.VarType.Boolean, label, default, get, function(value)
				set(value)
				ns.Refresh()
			end)
		Settings.CreateCheckbox(category, setting, tooltip)
	end

	checkbox("JUJU_ACTIVE", "Talk like a troll on this character",
		"Turns what you type into troll speech before it is sent. Starts switched on for Troll characters and off for everyone else. You can also set a key for this under Key Bindings > AddOns.",
		ns.IsTroll(),
		ns.IsActive,
		function(value) ns.SetMode(value and "on" or "off", true) end)

	-- What kind of troll this character is.
	if Settings.CreateDropdown and Settings.CreateControlTextContainer then
		local voiceSetting = Settings.RegisterProxySetting(category, "JUJU_VOICE", Settings.VarType.String,
			"Voice on this character", ns.DefaultVoice(), ns.GetVoiceKey, function(value) ns.SetVoice(value) end)
		local function voiceOptions()
			local container = Settings.CreateControlTextContainer()
			for _, key in ipairs(ns.Lexicon.voiceOrder) do
				local voice = ns.Lexicon.voices[key]
				container:Add(key, voice.name, voice.about)
			end
			return container:GetData()
		end
		Settings.CreateDropdown(category, voiceSetting, voiceOptions,
			"What kind of troll this character is. Each voice has its own flourishes and a few words of its own. Try them in the Juju box: the Voice button at the top cycles through them.")
	end

	header("How trolly")

	checkbox("JUJU_VOCAB", "Troll words",
		"Swap in proper troll words as well as the accent: magic becomes juju, luck is mojo, a curse is a hex and the gods are da Loa. Classes get troll names too: a rogue is a backstabba. Switch this off to keep only the accent.",
		ns.DEFAULTS.vocab,
		function() return db.vocab end,
		function(value) db.vocab = value end)

	checkbox("JUJU_FLOURISH", "Troll flourishes",
		"Now and then, about one message in three, adds a bit of troll: a \"Hey, mon!\" in front, or \", mon\", \", ya hear\" or \"! Stay away from da voodoo\" at the end. The preview above the chat line shows exactly what will be sent. Emotes and out-of-character remarks are left alone.",
		ns.DEFAULTS.flourish,
		function() return db.flourish end,
		function(value) db.flourish = value end)

	checkbox("JUJU_CREATURES", "Jujuify creature names",
		"Give creature names the troll accent too: Hogger becomes Hogga, Thunder Lizards become Tunda Lizards. Players' names are still left alone. Juju learns creature names from Questie if you have it, and from every hostile creature you target or point at.",
		ns.DEFAULTS.creatures,
		function() return db.creatures end,
		function(value) db.creatures = value end)

	checkbox("JUJU_PLACES", "Jujuify place names",
		"Give place names the troll accent too: Thunder Bluff becomes Tunda Bluff, the Barrens become da Barrens. Juju knows the game's zones and cities, Questie's subzones if you have it, and every place you visit.",
		ns.DEFAULTS.placeNames,
		function() return db.placeNames end,
		function(value) db.placeNames = value end)

	checkbox("JUJU_QUESTIE", "Questie announcements in troll",
		"If you use the Questie addon and it tells your party when you finish a quest step, say that in troll too. It follows the Party and Raid switches below, and only works while troll speech is on for this character.",
		ns.DEFAULTS.questie,
		function() return db.questie end,
		function(value) db.questie = value end)

	checkbox("JUJU_MON", "Mon! when yelling",
		"Adds \"mon\" to anything you /yell that ends with an exclamation mark: \"Charge!\" becomes \"Charge, mon!\"",
		ns.DEFAULTS.mon,
		function() return db.mon end,
		function(value) db.mon = value end)

	checkbox("JUJU_TYPOS", "Fix typos",
		"When a word is mistyped, work out the word that was meant before turning it into troll: abuot becomes about, sheild becomes shield. Juju only changes a word it does not recognise, and leaves it alone when it is not sure. Contractions typed without an apostrophe (dont, im, thats) and common shorthand (u, ur, idk) are always understood, whatever this says.",
		ns.DEFAULTS.typos,
		function() return db.typos end,
		function(value) db.typos = value end)

	checkbox("JUJU_NAMES", "Mangle names too",
		"Normally a word with a capital letter in the middle of a sentence is treated as a name and left alone, so Thrall stays Thrall. Switch this on and he becomes Trall. People near you are never renamed.",
		ns.DEFAULTS.names,
		function() return db.names end,
		function(value) db.names = value end)

	checkbox("JUJU_PREVIEW", "Show the troll version while typing",
		"Shows what will actually be sent, just above the chat box, as you type.",
		ns.DEFAULTS.preview,
		function() return db.preview end,
		function(value) db.preview = value end)

	checkbox("JUJU_TAG", "Show Troll or Plain on the chat line",
		"Shows a small tag just above the chat line while you type: Troll if the channel you are in will be translated, Plain if not. Click the tag to switch that channel.",
		ns.DEFAULTS.tag,
		function() return db.tag end,
		function(value) db.tag = value end)

	header("Where to talk troll")

	local NUMBERED = { general = true, trade = true, lfg = true, other = true }
	for _, channel in ipairs(ns.CHANNELS) do
		local key = channel.key
		local tooltip = "Talk like a troll in this kind of chat."
		if NUMBERED[key] then
			tooltip = "Talk like a troll in this channel. A key under Key Bindings > AddOns > Juju switches all the numbered channels at once."
		end
		checkbox("JUJU_CHANNEL_" .. strupper(key), channel.label,
			tooltip,
			ns.DEFAULTS.channels[key],
			function() return db.channels[key] end,
			function(value) db.channels[key] = value end)
	end

	Settings.RegisterAddOnCategory(category)
end
