local _, ns = ...
local Binds = ns.Binds

-- Rules for the optional click cast extras: a second spell per click cast (the counterpart on the other side of the
-- fence) and a resurrection for dead group members. This module only decides and looks things up; MouseoverCast turns
-- the result into macros, Scanner and Tooltip display it.
local ClickSpells = Binds:RegisterModule("ClickSpells")

-- Retail can hand out secret values that must not be compared or converted; treat them as missing.
local function Clean(value)
	if value ~= nil and issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

local GetSpellName = (C_Spell and C_Spell.GetSpellName) or function(spellID)
	return (GetSpellInfo(spellID))
end

local GetSpellTexture = (C_Spell and C_Spell.GetSpellTexture) or _G.GetSpellTexture

-- Resurrection spells by variant. A class knows at most one of each; the first known spell wins.
local RESURRECT = {
	normal = { 2006, 50769, 7328, 2008, 115178, 361227 },
	combat = { 20484, 391054, 61999 },
}

-- Unlike the tooltip filter, an unknown answer counts as "not known": a wrong yes would cast another class's spell.
local function IsKnown(spellID)
	if not (spellID and IsPlayerSpell) then
		return false
	end
	local ok, known = pcall(IsPlayerSpell, spellID)
	return ok and Clean(known) == true
end

local function Flag(namespaced, global, spellID)
	local ok, value
	if C_Spell and C_Spell[namespaced] then
		ok, value = pcall(C_Spell[namespaced], spellID)
	elseif _G[global] then
		ok, value = pcall(_G[global], GetSpellName(spellID))
	end
	return ok and Clean(value) == true
end

local function FirstKnown(list)
	for _, spellID in ipairs(list) do
		if IsKnown(spellID) then
			return spellID
		end
	end
	return nil
end

----------------------------------------------------------------------
-- Spell info
----------------------------------------------------------------------

function ClickSpells:Name(spellID)
	return spellID and GetSpellName(spellID) or nil
end

-- Inline texture for tooltips; size 0 follows the font height.
function ClickSpells:IconString(spellID, size)
	local texture = spellID and GetSpellTexture and GetSpellTexture(spellID)
	if not texture then
		return ""
	end
	return ("|T%s:%d|t "):format(tostring(texture), size or 0)
end

function ClickSpells:GetTexture(spellID)
	return spellID and GetSpellTexture and (GetSpellTexture(spellID)) or nil
end

function ClickSpells:IsKnown(spellID)
	return IsKnown(spellID)
end

-- "help" works on friends, "harm" on enemies, "both" on either (e.g. Holy Shock); nil means neither (self buffs ...).
function ClickSpells:Orientation(spellID)
	local help = Flag("IsSpellHelpful", "IsHelpfulSpell", spellID)
	local harm = Flag("IsSpellHarmful", "IsHarmfulSpell", spellID)
	if help and harm then
		return "both"
	end
	return (help and "help") or (harm and "harm") or nil
end

-- Two friendly or two hostile spells make no pair: both would act on the same unit type, the second never runs.
-- Such a choice stays selectable, but counts as inactive.
function ClickSpells:Conflicts(first, second)
	local a, b = self:Orientation(first), self:Orientation(second)
	return a ~= nil and a == b and a ~= "both"
end

----------------------------------------------------------------------
-- Second spell
----------------------------------------------------------------------

-- Walks the player's spellbook, passive and off-spec spells left out. Retail and the older API differ.
local function ForEachSpellbookSpell(callback)
	if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookItemInfo then
		local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
		local spellType = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
		for line = 1, C_SpellBook.GetNumSpellBookSkillLines() do
			local lineInfo = C_SpellBook.GetSpellBookSkillLineInfo(line)
			for index = lineInfo.itemIndexOffset + 1, lineInfo.itemIndexOffset + lineInfo.numSpellBookItems do
				local item = C_SpellBook.GetSpellBookItemInfo(index, bank)
				if item and item.spellID and not item.isPassive and not item.isOffSpec
					and (not spellType or item.itemType == spellType) then
					callback(item.spellID)
				end
			end
		end
	elseif GetNumSpellTabs and GetSpellTabInfo and GetSpellBookItemInfo then
		for tab = 1, GetNumSpellTabs() do
			local _, _, offset, count = GetSpellTabInfo(tab)
			for index = offset + 1, offset + count do
				local kind, spellID = GetSpellBookItemInfo(index, "spell")
				if kind == "SPELL" and spellID and not (IsPassiveSpell and IsPassiveSpell(index, "spell")) then
					callback(spellID)
				end
			end
		end
	end
end

-- Known spells for the second slot of `first`, by name; ranks of one spell count once. Spells of the same kind are
-- listed too, flagged as conflict.
function ClickSpells:GetCandidates(first)
	local byName = {}
	pcall(ForEachSpellbookSpell, function(spellID)
		local name = GetSpellName(spellID)
		if name and IsKnown(spellID) and name ~= GetSpellName(first) then
			byName[name] = spellID
		end
	end)
	local list = {}
	for name, spellID in pairs(byName) do
		table.insert(list, { spellID = spellID, name = name, conflict = self:Conflicts(first, spellID) })
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

-- Which unit type the first spell takes: friends ("help") or enemies ("harm"). The second spell takes the other one.
function ClickSpells:FirstBranch(first, second)
	local a, b = self:Orientation(first), self:Orientation(second)
	if a == "harm" or (a == "both" and b == "help") then
		return "harm"
	end
	return "help"
end

-- "friend" or "enemy": the unit type the second spell acts on.
function ClickSpells:SecondSide(first, second)
	return self:FirstBranch(first, second) == "help" and "enemy" or "friend"
end

function ClickSpells:IsSecondActive()
	local db = Binds.db
	return db ~= nil and db.mouseoverCasts and db.clicks.second
end

-- The stored choice, whether or not it is active; the options page shows it as long as it exists.
function ClickSpells:GetStoredSecond(first)
	return first and Binds.db.clicks.secondSpells[first] or nil
end

-- The second spell that actually takes effect: feature on, spell known, still a valid counterpart.
function ClickSpells:GetSecond(first)
	if not self:IsSecondActive() then
		return nil
	end
	local second = self:GetStoredSecond(first)
	if second and IsKnown(second) and not self:Conflicts(first, second) then
		return second
	end
	return nil
end

-- Returns true and whether the pair is inactive (same kind), or false for a spell the character does not know.
function ClickSpells:SetSecond(first, second)
	if not first then
		return false
	end
	if second == nil then
		Binds.db.clicks.secondSpells[first] = nil
		return true, false
	end
	if not IsKnown(second) then
		return false
	end
	Binds.db.clicks.secondSpells[first] = second
	return true, self:Conflicts(first, second)
end

----------------------------------------------------------------------
-- Resurrection
----------------------------------------------------------------------

-- The normal and the combat resurrection this character can cast; either may be nil.
function ClickSpells:GetAvailableResurrections()
	return FirstKnown(RESURRECT.normal), FirstKnown(RESURRECT.combat)
end

-- The resurrection that takes effect, with its name. A missing variant falls back to the other one.
function ClickSpells:GetResurrection()
	local db = Binds.db
	if not (db and db.mouseoverCasts and db.clicks.resurrect) then
		return nil
	end
	local normal, combat = self:GetAvailableResurrections()
	local spellID
	if db.clicks.resurrectMode == "combat" then
		spellID = combat or normal
	else
		spellID = normal or combat
	end
	return spellID, self:Name(spellID)
end
