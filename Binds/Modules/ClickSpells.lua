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

-- Spells that remove a debuff (curse, poison, disease, magic); the game's flags cannot tell them from other heals.
local DISPEL = {}
for _, spellID in ipairs({ 4987, 213644, 527, 213634, 528, 32375, 475, 88423, 2782, 115450, 218164, 51886, 77130,
	360823, 365585, 374251, 388874, 383013, 393024 }) do
	DISPEL[spellID] = true
end

local GetItemIcon = (C_Item and C_Item.GetItemIconByID) or _G.GetItemIcon
local GetItemName = (C_Item and C_Item.GetItemNameByID) or function(itemID)
	return (GetItemInfo(itemID))
end
local GetItemCount = (C_Item and C_Item.GetItemCount) or _G.GetItemCount
local GetItemSpell = (C_Item and C_Item.GetItemSpell) or _G.GetItemSpell
local GetBagSlots = (C_Container and C_Container.GetContainerNumSlots) or _G.GetContainerNumSlots
local GetBagItemID = (C_Container and C_Container.GetContainerItemID) or _G.GetContainerItemID
local GetSpellDescription = (C_Spell and C_Spell.GetSpellDescription) or _G.GetSpellDescription

-- Words that mark a spell description as a resurrection; the game text is localized, so each language has its own.
local REZ_WORDS = { "resurrect", "revive", "wiederbeleb", "belebt", "auferst", "ressusc", "anim" }

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

-- What a spell is for, as shown by the arrow colors on the options page: "friend", "enemy", "dispel" or "buff"
-- (everything else: self buffs, spells for friends and enemies alike).
function ClickSpells:Kind(spellID)
	if spellID and DISPEL[spellID] then
		return "dispel"
	end
	local orientation = self:Orientation(spellID)
	if orientation == "help" then
		return "friend"
	elseif orientation == "harm" then
		return "enemy"
	end
	return "buff"
end

-- Arrow colors by kind, as r/g/b fractions (options page and tooltips).
ClickSpells.KIND_COLORS = {
	friend = { r = 0.35, g = 0.85, b = 0.40 },
	enemy = { r = 0.92, g = 0.30, b = 0.28 },
	buff = { r = 0.40, g = 0.65, b = 1.00 },
	dispel = { r = 0.75, g = 0.50, b = 1.00 },
}

local TOOLTIP_BRIGHTEN = 0.5

local function AtlasInfo(atlas)
	local ok, info = pcall(function()
		return C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
	end)
	return ok and info or nil
end

-- Tooltip text for one arrow, tinted: the same slider arrow of the game as on the options page (texture and
-- coordinates come from the atlas; a mirrored atlas has its horizontal coordinates the other way round, which the
-- texture escape keeps). Without a right arrow atlas the left one is used with swapped coordinates. Without atlases
-- (other clients) our own white arrow head stands in.
local function ArrowString(pointsLeft, color)
	-- The grey atlas art only gets darker under a tint, so the color is mixed towards white to come closer to the
	-- full-brightness arrows of the options page.
	color = { r = color.r + (1 - color.r) * TOOLTIP_BRIGHTEN, g = color.g + (1 - color.g) * TOOLTIP_BRIGHTEN,
		b = color.b + (1 - color.b) * TOOLTIP_BRIGHTEN }
	local info = AtlasInfo(pointsLeft and "Minimal_SliderBar_Button_Left" or "Minimal_SliderBar_Button_Right")
	local mirror = false
	if not (info and (info.file or info.filename)) and not pointsLeft then
		info, mirror = AtlasInfo("Minimal_SliderBar_Button_Left"), true
	end
	local file = info and (info.file or info.filename)
	local left, right, top, bottom = info and info.leftTexCoord, info and info.rightTexCoord, info and info.topTexCoord, info and info.bottomTexCoord
	if file and left and right and top and bottom and left ~= right and top ~= bottom and info.width and info.height then
		if mirror then
			left, right = right, left
		end
		local textureWidth, textureHeight = info.width / math.abs(right - left), info.height / math.abs(bottom - top)
		local function round(value)
			return math.floor(value + 0.5)
		end
		return ("|T%s:14:%d:0:0:%d:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(tostring(file), round(info.width * 14 / info.height),
			round(textureWidth), round(textureHeight), round(left * textureWidth), round(right * textureWidth),
			round(top * textureHeight), round(bottom * textureHeight),
			round(color.r * 255), round(color.g * 255), round(color.b * 255))
	end
	return ("|T%s%s:14:10:0:0:32:32:0:32:0:32:%d:%d:%d|t"):format(Binds.mediaPath,
		pointsLeft and "arrow_links_weiss_32x32" or "arrow_weiss_32x32",
		math.floor(color.r * 255 + 0.5), math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5))
end

-- Arrow for the legend tooltip on the options page.
function ClickSpells:ArrowString(pointsLeft, color)
	return ArrowString(pointsLeft, color)
end

-- Tooltip text for a spell pair: both icons with a colored arrow each between them, the left one pointing at the
-- first spell, the right one at the second. Without icons (option off) it is empty.
function ClickSpells:PairString(first, second)
	local colors = self.KIND_COLORS
	-- A transparent 2 px picture keeps the two arrows exactly 2 px apart.
	local gap = ("|T%sspacer_32x32:14:2|t"):format(Binds.mediaPath)
	return self:IconString(first) .. ArrowString(true, colors[self:Kind(first)]) .. gap
		.. ArrowString(false, colors[self:Kind(second)]) .. " " .. self:IconString(second)
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

local function ItemInBags(itemID)
	if not GetItemCount then
		return false
	end
	local ok, count = pcall(GetItemCount, itemID)
	return ok and Clean(count) ~= nil and count > 0
end

-- Can this character use the item? The game's own check covers level, class and profession requirements (the
-- engineering resurrection items need the profession); the item tooltip is read as well, where an unmet requirement
-- shows as a red line. Returns usable, and the text of the first red line when it is not.
function ClickSpells:IsItemUsable(itemID)
	local isUsable = (C_Item and C_Item.IsUsableItem) or _G.IsUsableItem
	if isUsable then
		local ok, usable = pcall(isUsable, itemID)
		if ok and Clean(usable) ~= nil and not usable then
			return false
		end
	end
	if C_TooltipInfo and C_TooltipInfo.GetItemByID then
		local ok, data = pcall(C_TooltipInfo.GetItemByID, itemID)
		if ok and type(data) == "table" and type(data.lines) == "table" then
			for _, line in ipairs(data.lines) do
				local color = line.leftColor
				local text = line.leftText
				if type(color) == "table" and Clean(color.r) and Clean(color.g) and Clean(color.b)
					and color.r > 0.9 and color.g < 0.3 and color.b < 0.3 and Clean(text) and text ~= "" then
					return false, text
				end
			end
		end
	end
	return true
end

function ClickSpells:ItemName(itemID)
	return GetItemName and GetItemName(itemID) or nil
end

function ClickSpells:ItemTexture(itemID)
	return GetItemIcon and GetItemIcon(itemID) or nil
end

-- The resurrection spell for use out of combat; nil if the class has none.
function ClickSpells:GetNormalResurrection()
	return FirstKnown(RESURRECT.normal)
end

-- The combat resurrection spells of the class; items from the bags come from GetBagItems.
-- Entries: { kind = "spell", id, key = "spell:123" }
function ClickSpells:GetCombatChoices()
	local list = {}
	for _, spellID in ipairs(RESURRECT.combat) do
		if IsKnown(spellID) then
			table.insert(list, { kind = "spell", id = spellID, key = "spell:" .. spellID })
		end
	end
	return list
end

-- The chosen combat resurrection: a dragged item while it is still in the bags, a chosen spell while known, otherwise
-- the first class spell; nil if there is none.
function ClickSpells:GetCombatResurrection()
	local stored = Binds.db and Binds.db.clicks.combatRez
	local itemID = stored and tonumber(stored:match("^item:(%d+)$"))
	if itemID and ItemInBags(itemID) and self:IsItemUsable(itemID) then
		return { kind = "item", id = itemID, key = stored }
	end
	local choices = self:GetCombatChoices()
	for _, choice in ipairs(choices) do
		if choice.key == stored then
			return choice
		end
	end
	return choices[1]
end

-- Items in the bags that have a use effect, by name. Unless `all`, only those whose effect text speaks of
-- resurrecting: that is how the engineering resurrection items are told apart, without keeping a list of them.
-- Entries: { id, name, texture, usable, reason }; unusable items are only listed with `all`.
function ClickSpells:GetBagItems(all)
	local byID, list = {}, {}
	if not (GetBagSlots and GetBagItemID and GetItemSpell) then
		return list
	end
	for bag = 0, 5 do
		for slot = 1, (GetBagSlots(bag) or 0) do
			local itemID = Clean(GetBagItemID(bag, slot))
			if itemID and not byID[itemID] then
				byID[itemID] = true
				local _, spellID = GetItemSpell(itemID)
				spellID = Clean(spellID)
				if spellID then
					local matches = false
					local text = GetSpellDescription and Clean(GetSpellDescription(spellID))
					if type(text) == "string" then
						text = text:lower()
						for _, word in ipairs(REZ_WORDS) do
							if text:find(word, 1, true) then
								matches = true
								break
							end
						end
					end
					if all or matches then
						local usable, reason = self:IsItemUsable(itemID)
						-- Items this character cannot use (e.g. no Engineering) only appear with "show all", marked.
						if usable or all then
							table.insert(list, { id = itemID, name = self:ItemName(itemID) or "?", texture = self:ItemTexture(itemID),
								usable = usable, reason = reason })
						end
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.name < b.name
	end)
	return list
end

function ClickSpells:SetCombatResurrection(key)
	Binds.db.clicks.combatRez = key
end

function ClickSpells:ChoiceName(choice)
	if not choice then
		return nil
	end
	return choice.kind == "item" and self:ItemName(choice.id) or self:Name(choice.id)
end

function ClickSpells:ChoiceTexture(choice)
	if not choice then
		return nil
	end
	return choice.kind == "item" and self:ItemTexture(choice.id) or self:GetTexture(choice.id)
end

function ClickSpells:IsResurrectionActive()
	local db = Binds.db
	return db ~= nil and db.mouseoverCasts and db.clicks.resurrect
end

-- Whether any resurrection is set up (independent of the combat state, the macros hold both variants).
function ClickSpells:HasResurrection()
	return self:IsResurrectionActive() and (self:GetNormalResurrection() ~= nil or self:GetCombatResurrection() ~= nil)
end

-- Out of combat the normal resurrection, in combat the combat one: returns the choice-like { kind, id } that applies
-- right now, with its name.
function ClickSpells:GetResurrection(inCombat)
	if not self:IsResurrectionActive() then
		return nil
	end
	local choice
	if inCombat then
		choice = self:GetCombatResurrection()
	else
		local normal = self:GetNormalResurrection()
		choice = normal and { kind = "spell", id = normal } or nil
	end
	return choice, self:ChoiceName(choice)
end

-- Bags change often; the macros only need a rebuild when the chosen combat item changed.
function ClickSpells:OnBagsChanged()
	if not self:IsResurrectionActive() then
		return
	end
	local choice = self:GetCombatResurrection()
	local key = choice and choice.key or false
	if key ~= self.lastCombatKey then
		self.lastCombatKey = key
		Binds:Fire("SettingsChanged")
	end
end

function ClickSpells:OnInitialize()
	Binds:RegisterModuleEvent(self, "BAG_UPDATE_DELAYED", "OnBagsChanged")
end
