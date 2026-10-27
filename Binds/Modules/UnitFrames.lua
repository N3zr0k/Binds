local _, ns = ...
local Binds = ns.Binds

-- Optional: carries the click cast extras (second spell, resurrection) over to Blizzard's unit frames.
-- Blizzard's click casting is checked first in SecureUnitButton_OnClick: a bound combination (Spell/Macro) is run by the
-- game and never reaches the frame's own attributes. So the combination is moved out of the way: a secure pre-click
-- snippet on the frame turns exactly those clicks (say Shift + right) into an unused virtual button (Button31 ...),
-- which has no Blizzard binding, and the frame's attributes for that virtual button run the same macro as the world
-- mouseover cast. Every other click, and every click cast without an extra, stays with Blizzard. The snippet runs
-- securely, also in combat; attributes can only change out of combat, and the originals are restored on every rebuild.
local UnitFrames = Binds:RegisterModule("UnitFrames")

local applied = {}
local known = {}
local hooked = {}
local wrapped = {}
local header

-- Runs in the restricted environment before the frame's OnClick. The modifier prefix is built like Blizzard's
-- (alt-ctrl-shift); a mapping attribute "binds-<prefix><button>" names the virtual button to click instead.
local WRAP_BODY = [[
	local prefix = ""
	if IsAltKeyDown() then prefix = "alt-" end
	if IsControlKeyDown() then prefix = prefix .. "ctrl-" end
	if IsShiftKeyDown() then prefix = prefix .. "shift-" end
	if prefix == "" then return end
	return self:GetAttribute("binds-" .. prefix .. button)
]]

local BUTTON_NAMES = { "LeftButton", "RightButton", "MiddleButton" }

local function ButtonName(index)
	return BUTTON_NAMES[index] or ("Button" .. index)
end

-- A wrapped script cannot be unwrapped cleanly, so every frame is wrapped once; without mapping attributes the
-- snippet returns nothing and the click passes unchanged.
local function Wrap(frame)
	if wrapped[frame] or not (frame.IsProtected and frame:IsProtected()) then
		return
	end
	header = header or CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
	wrapped[frame] = true
	SecureHandlerWrapScript(frame, "OnClick", header, WRAP_BODY)
end
local pending = false

-- Debug only: what the secure click would run for this modifier and button. Shows whether our attributes are the ones
-- in effect when the click arrives, or whether something else answers first.
local function LogClick(frame, button)
	if not (Binds.db and Binds.db.debug) then
		return
	end
	local ok, kind = pcall(SecureButton_GetModifiedAttribute, frame, "type", button)
	local _, text = pcall(SecureButton_GetModifiedAttribute, frame, "macrotext", button)
	Binds:Debug("frame click %s button=%s type=%s mouseover=%s macro=%s", tostring(frame:GetName()), tostring(button),
		tostring(ok and kind), tostring(UnitExists("mouseover")), type(text) == "string" and (text:gsub("\n", " | ")) or "-")
end

-- Frame names are looked up on every rebuild: group frames appear and disappear with the roster.
local function CollectFrames()
	local frames = {}
	local function add(frame)
		if type(frame) == "table" and frame.SetAttribute and frame.GetAttribute then
			frames[frame] = true
		end
	end
	for _, name in ipairs({ "PlayerFrame", "PetFrame", "TargetFrame", "FocusFrame" }) do
		add(_G[name])
	end
	for index = 1, 5 do
		add(_G["Boss" .. index .. "TargetFrame"])
	end
	for index = 1, 4 do
		add(_G["PartyMemberFrame" .. index])
		add(PartyFrame and PartyFrame["MemberFrame" .. index])
	end
	for index = 1, 5 do
		add(_G["CompactPartyFrameMember" .. index])
	end
	for index = 1, 40 do
		add(_G["CompactRaidFrame" .. index])
	end
	for group = 1, 8 do
		for member = 1, 5 do
			add(_G["CompactRaidGroup" .. group .. "Member" .. member])
		end
	end
	-- Frames the hook has seen since the last rebuild.
	for frame in pairs(known) do
		add(frame)
	end
	return frames
end

-- Remembers what a frame had before, so switching the option off gives Blizzard's value back.
local function SetAttribute(frame, name, value)
	applied[frame] = applied[frame] or {}
	if not hooked[frame] and frame.HookScript and frame.HasScript and frame:HasScript("PreClick") then
		hooked[frame] = true
		frame:HookScript("PreClick", LogClick)
	end
	if not applied[frame][name] then
		applied[frame][name] = { old = frame:GetAttribute(name) }
	end
	frame:SetAttribute(name, value)
end

function UnitFrames:Clear()
	for frame, attributes in pairs(applied) do
		for name, saved in pairs(attributes) do
			frame:SetAttribute(name, saved.old)
		end
	end
	applied = {}
end

function UnitFrames:Apply()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	self:Clear()
	local db = Binds.db
	if not (db and db.mouseoverCasts and db.clicks.unitFrames) then
		return
	end
	local scanner, mouseover = Binds:GetModule("Scanner"), Binds:GetModule("MouseoverCast")
	local macros = {}
	for _, entry in ipairs(scanner:GetClickCastKeys()) do
		local text = entry.attrPrefix and entry.buttonIndex and mouseover:GetExtraMacro(entry)
		-- Virtual buttons count down from Button31; there are plenty for any real click cast profile.
		local virtual = 31 - #macros
		if text and virtual >= 4 then
			table.insert(macros, { prefix = entry.attrPrefix, button = ButtonName(entry.buttonIndex), virtual = virtual, text = text })
		end
	end
	if #macros == 0 then
		return
	end
	local count = 0
	for frame in pairs(CollectFrames()) do
		count = count + 1
		Wrap(frame)
		for _, macro in ipairs(macros) do
			SetAttribute(frame, "binds-" .. macro.prefix .. macro.button, "Button" .. macro.virtual)
			SetAttribute(frame, macro.prefix .. "type" .. macro.virtual, "macro")
			SetAttribute(frame, macro.prefix .. "macrotext" .. macro.virtual, macro.text)
		end
	end
	Binds:Debug("unit frames: %d click casts on %d frames", #macros, count)
end

-- Debug only: the game's own reason when a cast on a frame is refused ("Invalid target" ...).
function UnitFrames:OnUIError(_, _, message)
	if Binds.db and Binds.db.debug and type(message) == "string" and not (issecretvalue and issecretvalue(message)) then
		Binds:Debug("ui error: %s", message)
	end
end

function UnitFrames:OnRegenEnabled()
	if pending then
		self:Apply()
	end
end

function UnitFrames:OnInitialize()
	Binds:RegisterModuleEvent(self, "PLAYER_ENTERING_WORLD", "Apply")
	Binds:RegisterModuleEvent(self, "SPELLS_CHANGED", "Apply")
	Binds:RegisterModuleEvent(self, "GROUP_ROSTER_UPDATE", "Apply")
	Binds:RegisterModuleEvent(self, "PLAYER_REGEN_ENABLED", "OnRegenEnabled")
	Binds:RegisterModuleEvent(self, "UI_ERROR_MESSAGE", "OnUIError")
	Binds:On("BindingsChanged", self, "Apply")
	Binds:On("SettingsChanged", self, "Apply")
	-- Raid frames are created and reused late; catch each one when it gets its unit.
	if CompactUnitFrame_SetUnit then
		hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
			if not known[frame] then
				known[frame] = true
				pending = true
				if C_Timer and C_Timer.After and not InCombatLockdown() then
					C_Timer.After(0, function()
						UnitFrames:Apply()
					end)
				end
			end
		end)
	end
end
