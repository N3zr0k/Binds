local _, ns = ...
local Binds = ns.Binds

-- Optional: lets the Blizzard click casts that have a modifier (Shift + right click ...) also work on units in the
-- world, as mouseover casts. The click casting profile itself is not changed; this only mirrors it with override
-- bindings. Off by default. Override bindings and secure buttons can only change out of combat.
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

local function MacroText(entry)
	if entry.type == TYPE.Spell then
		local name = entry.actionID and GetSpellName(entry.actionID)
		return name and (GUARD .. "/cast [@mouseover] " .. name)
	elseif entry.type == TYPE.Macro then
		local body = entry.actionID and GetMacroBody and GetMacroBody(entry.actionID)
		return body and (GUARD .. body)
	end
	-- Target and menu interactions already work on units in the world.
	return nil
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
	Binds:RegisterModuleEvent(self, "PLAYER_REGEN_ENABLED", "OnRegenEnabled")
	Binds:On("BindingsChanged", self, "Apply")
	Binds:On("SettingsChanged", self, "Apply")
end
