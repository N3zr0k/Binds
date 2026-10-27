local _, ns = ...
local Binds = ns.Binds

-- Optional: lets the Blizzard click casts that have a modifier (Shift + right click ...) also work on units in the
-- world, as mouseover casts. The click casting profile itself is not changed; this only mirrors it with override
-- bindings. Off by default. Override bindings and secure buttons can only change out of combat.
-- The click cast extras (second spell, resurrection) are built into the same macros, see ClickSpells.
local MouseoverCast = Binds:RegisterModule("MouseoverCast")

local TYPE = (Enum and Enum.ClickBindingType) or { Spell = 1, Macro = 2, Interaction = 3 }
local GetSpellName = (C_Spell and C_Spell.GetSpellName) or function(spellId)
	return (GetSpellInfo(spellId))
end

local owner
local buttons = {}
local pending = false

local function GetButton(index)
	local button = buttons[index]
	if not button then
		button = CreateFrame("Button", "BindsMouseoverCast" .. index, UIParent, "SecureActionButtonTemplate")
		-- Both directions: the secure template itself picks up or down according to the "action button use key
		-- down" setting. Registering only one of them silently drops the click whenever the setting is the other.
		button:RegisterForClicks("AnyUp", "AnyDown")
		buttons[index] = button
	end
	return button
end

-- Nothing happens when the mouse is not over a unit, instead of casting on an invalid target.
local GUARD = "/stopmacro [@mouseover,noexists]\n"

-- Resurrection only for dead members of the player's group; "party" and "raid" are separate conditions.
local REZ_TARGETS = { "@mouseover,help,dead,party", "@mouseover,help,dead,raid" }

local function RezOptions(rezName)
	local options = {}
	for _, target in ipairs(REZ_TARGETS) do
		table.insert(options, "[" .. target .. "] " .. rezName)
	end
	return options
end

-- One /cast line where the first matching option casts. With a second spell each unit type picks its own spell.
local function SpellMacro(spellID)
	local name = spellID and GetSpellName(spellID)
	if not name then
		return nil
	end
	local clickSpells = Binds:GetModule("ClickSpells")
	local options = {}
	local _, rezName = clickSpells:GetResurrection()
	if rezName then
		options = RezOptions(rezName)
	end
	local second = clickSpells:GetSecond(spellID)
	local secondName = second and GetSpellName(second)
	if secondName then
		local own = clickSpells:FirstBranch(spellID, second)
		local other = own == "help" and "harm" or "help"
		table.insert(options, "[@mouseover," .. own .. ",nodead] " .. name)
		table.insert(options, "[@mouseover," .. other .. ",nodead] " .. secondName)
	else
		table.insert(options, "[@mouseover] " .. name)
	end
	return GUARD .. "/cast " .. table.concat(options, "; ")
end

-- A macro keeps its own body; the resurrection runs first and ends the macro when it applies.
local function UserMacro(macroID)
	local body = macroID and GetMacroBody and GetMacroBody(macroID)
	if not body then
		return nil
	end
	local _, rezName = Binds:GetModule("ClickSpells"):GetResurrection()
	if not rezName then
		return GUARD .. body
	end
	local lines = { "/cast " .. table.concat(RezOptions(rezName), "; ") }
	for _, target in ipairs(REZ_TARGETS) do
		table.insert(lines, "/stopmacro [" .. target .. "]")
	end
	table.insert(lines, body)
	return GUARD .. table.concat(lines, "\n")
end

local function MacroText(entry)
	if entry.type == TYPE.Spell then
		return SpellMacro(entry.actionID)
	elseif entry.type == TYPE.Macro then
		return UserMacro(entry.actionID)
	end
	-- Target and menu interactions already work on units in the world.
	return nil
end

-- The macro for a click cast, but only if an extra (second spell, resurrection) changes it; the unit frames only
-- take over click casts that need it.
function MouseoverCast:GetExtraMacro(entry)
	local clickSpells = Binds:GetModule("ClickSpells")
	local hasResurrection = clickSpells:GetResurrection() ~= nil
	if entry.type == TYPE.Spell then
		if not (hasResurrection or clickSpells:GetSecond(entry.actionID)) then
			return nil
		end
	elseif entry.type ~= TYPE.Macro or not hasResurrection then
		return nil
	end
	return MacroText(entry)
end

function MouseoverCast:Apply()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	owner = owner or CreateFrame("Frame")
	ClearOverrideBindings(owner)
	if not (Binds.db and Binds.db.mouseoverCasts) then
		return
	end
	local scanner = Binds:GetModule("Scanner")
	if not scanner then
		return
	end
	local index = 0
	for _, entry in ipairs(scanner:GetClickCastKeys()) do
		local text = MacroText(entry)
		if text then
			index = index + 1
			local button = GetButton(index)
			button:SetAttribute("type", "macro")
			button:SetAttribute("unit", "mouseover")
			button:SetAttribute("macrotext", text)
			SetOverrideBindingClick(owner, true, entry.key, button:GetName(), "LeftButton")
			Binds:Debug("mouseover cast %s: %s", entry.key, (text:gsub("\n", " | ")))
		end
	end
	Binds:Debug("mouseover casts applied: %d", index)
end

function MouseoverCast:OnRegenEnabled()
	if pending then
		self:Apply()
	end
end

function MouseoverCast:OnInitialize()
	Binds:RegisterModuleEvent(self, "PLAYER_ENTERING_WORLD", "Apply")
	-- Known spells decide which resurrection and second spells apply.
	Binds:RegisterModuleEvent(self, "SPELLS_CHANGED", "Apply")
	Binds:RegisterModuleEvent(self, "PLAYER_REGEN_ENABLED", "OnRegenEnabled")
	Binds:On("BindingsChanged", self, "Apply")
	Binds:On("SettingsChanged", self, "Apply")
end
