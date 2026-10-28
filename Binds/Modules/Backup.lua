local _, ns = ...
local Binds = ns.Binds

-- Export and import of the Binds settings as a line of text that can be copied and pasted. Two scopes:
--   "account":   every setting (all of BindsDB)
--   "character": the part that hangs on the spells of the current character (second spells, combat resurrection)
-- The text is "BINDS1:scope:payload:check" (character texts: "BINDS1:character:Name-Realm:payload:check"): the payload is the settings in a small data format (not Lua code, so
-- pasting a text can never run anything), in base64; the check value catches a text that was cut off.
local Backup = Binds:RegisterModule("Backup")

local VERSION = "BINDS1"

----------------------------------------------------------------------
-- Base64 and check value
----------------------------------------------------------------------

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local ENCODE, DECODE = {}, {}
for index = 1, #ALPHABET do
	local char = ALPHABET:sub(index, index)
	ENCODE[index - 1] = char
	DECODE[char] = index - 1
end

local function Base64Encode(data)
	local out = {}
	for index = 1, #data, 3 do
		local a, b, c = data:byte(index, index + 2)
		local number = a * 65536 + (b or 0) * 256 + (c or 0)
		local first, second = math.floor(number / 262144) % 64, math.floor(number / 4096) % 64
		local third, fourth = math.floor(number / 64) % 64, number % 64
		out[#out + 1] = ENCODE[first] .. ENCODE[second] .. (b and ENCODE[third] or "=") .. (c and ENCODE[fourth] or "=")
	end
	return table.concat(out)
end

local function Base64Decode(text)
	text = text:gsub("[^%w%+/=]", "")
	if #text % 4 ~= 0 then
		return nil
	end
	local out = {}
	for index = 1, #text, 4 do
		local a, b, c, d = text:sub(index, index), text:sub(index + 1, index + 1), text:sub(index + 2, index + 2), text:sub(index + 3, index + 3)
		local va, vb = DECODE[a], DECODE[b]
		local vc, vd = DECODE[c], DECODE[d]
		if not va or not vb or (not vc and c ~= "=") or (not vd and d ~= "=") then
			return nil
		end
		local number = va * 262144 + vb * 4096 + (vc or 0) * 64 + (vd or 0)
		out[#out + 1] = string.char(math.floor(number / 65536) % 256)
		if c ~= "=" then
			out[#out + 1] = string.char(math.floor(number / 256) % 256)
		end
		if d ~= "=" then
			out[#out + 1] = string.char(number % 256)
		end
	end
	return table.concat(out)
end

local function Check(text)
	local sum, weighted = 1, 0
	for index = 1, #text do
		sum = (sum + text:byte(index)) % 65521
		weighted = (weighted + sum) % 65521
	end
	return ("%04x%04x"):format(weighted, sum)
end

----------------------------------------------------------------------
-- Data format: { "key": value, ... } with numbers, strings, booleans and nested tables
----------------------------------------------------------------------

local function Serialize(value)
	local kind = type(value)
	if kind == "boolean" then
		return value and "true" or "false"
	elseif kind == "number" then
		return ("%.14g"):format(value)
	elseif kind == "string" then
		return '"' .. value:gsub("[\\\"]", "\\%0") .. '"'
	elseif kind == "table" then
		local keys = {}
		for key in pairs(value) do
			keys[#keys + 1] = key
		end
		table.sort(keys, function(a, b)
			if type(a) == type(b) then
				return a < b
			end
			return type(a) == "number"
		end)
		local parts = {}
		for _, key in ipairs(keys) do
			local name = type(key) == "number" and ("#" .. ("%.14g"):format(key)) or ('"' .. tostring(key):gsub("[\\\"]", "\\%0") .. '"')
			parts[#parts + 1] = name .. ":" .. Serialize(value[key])
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

-- Reads the format above; returns nil on anything unexpected. Never runs the text.
local function Deserialize(text)
	local position = 1
	local function skip()
		position = text:find("%S", position) or #text + 1
	end
	local function fail()
		error("parse", 0)
	end
	local parseValue

	local function parseString()
		position = position + 1
		local out = {}
		while true do
			local char = text:sub(position, position)
			if char == "" then
				fail()
			elseif char == "\\" then
				out[#out + 1] = text:sub(position + 1, position + 1)
				position = position + 2
			elseif char == '"' then
				position = position + 1
				return table.concat(out)
			else
				out[#out + 1] = char
				position = position + 1
			end
		end
	end

	local function parseKey()
		skip()
		local char = text:sub(position, position)
		if char == "#" then
			local number = text:match("^#(-?[%d%.eE%+%-]+)", position)
			if not number or not tonumber(number) then
				fail()
			end
			position = position + 1 + #number
			return tonumber(number)
		elseif char == '"' then
			return parseString()
		end
		fail()
	end

	function parseValue(depth)
		if depth > 8 then
			fail()
		end
		skip()
		local char = text:sub(position, position)
		if char == "{" then
			position = position + 1
			local result = {}
			skip()
			if text:sub(position, position) == "}" then
				position = position + 1
				return result
			end
			while true do
				local key = parseKey()
				skip()
				if text:sub(position, position) ~= ":" then
					fail()
				end
				position = position + 1
				result[key] = parseValue(depth + 1)
				skip()
				local separator = text:sub(position, position)
				position = position + 1
				if separator == "}" then
					return result
				elseif separator ~= "," then
					fail()
				end
			end
		elseif char == '"' then
			return parseString()
		elseif text:find("^true", position) then
			position = position + 4
			return true
		elseif text:find("^false", position) then
			position = position + 5
			return false
		elseif text:find("^null", position) then
			position = position + 4
			return nil
		end
		local number = text:match("^-?[%d%.eE%+%-]+", position)
		if not number or not tonumber(number) then
			fail()
		end
		position = position + #number
		return tonumber(number)
	end

	local ok, result = pcall(function()
		local value = parseValue(0)
		skip()
		if position <= #text then
			fail()
		end
		return value
	end)
	if ok then
		return result
	end
	return nil
end

Backup.Serialize, Backup.Deserialize = Serialize, Deserialize
Backup.Base64Encode, Backup.Base64Decode, Backup.Check = Base64Encode, Base64Decode, Check

----------------------------------------------------------------------
-- Settings to and from data
----------------------------------------------------------------------

local function Copy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, inner in pairs(value) do
		result[key] = Copy(inner)
	end
	return result
end

-- Keeps only what Binds knows: keys and types follow the defaults. Free-form tables (second spells) take numbers.
local function Sanitize(data, defaults, path)
	if type(data) ~= "table" then
		return nil
	end
	local result = {}
	for key, default in pairs(defaults) do
		local value = data[key]
		local here = path .. "." .. key
		if type(default) == "table" then
			if here == ".clicks.secondSpells" then
				if type(value) == "table" then
					result[key] = {}
					for first, second in pairs(value) do
						if type(first) == "number" and type(second) == "number" then
							result[key][first] = second
						end
					end
				end
			else
				result[key] = Sanitize(value, default, here)
			end
		elseif type(value) == type(default) then
			result[key] = value
		end
	end
	-- Optional values without a default.
	if path == ".clicks" and type(data.combatRez) == "string" and data.combatRez:match("^%a+:%d+$") then
		result.combatRez = data.combatRez
	end
	if path == ".minimap" and type(data.minimapPos) == "number" then
		result.minimapPos = data.minimapPos
	end
	return result
end

local function Merge(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			Merge(target[key], value)
		else
			target[key] = Copy(value)
		end
	end
end

-- Blizzard's own click casting (per character, stored on the server). Entries: type, button, modifiers, actionID.
function Backup:GetBlizzardProfile()
	local list = {}
	if C_ClickBindings and C_ClickBindings.GetProfileInfo then
		local ok, profile = pcall(C_ClickBindings.GetProfileInfo)
		for _, info in ipairs(ok and type(profile) == "table" and profile or {}) do
			if type(info.type) == "number" and type(info.button) == "string" and type(info.modifiers) == "number" then
				list[#list + 1] = { type = info.type, button = info.button, modifiers = info.modifiers, actionID = tonumber(info.actionID) or 0 }
			end
		end
	end
	return list
end

-- Replaces the character's click casting; returns the count, or nil, reason ("COMBAT" / "NOAPI").
function Backup:SetBlizzardProfile(list)
	if not (C_ClickBindings and C_ClickBindings.SetProfileByInfo) then
		return nil, "NOAPI"
	end
	if InCombatLockdown() then
		return nil, "COMBAT"
	end
	local profile = {}
	for _, info in ipairs(type(list) == "table" and list or {}) do
		if type(info) == "table" and type(info.type) == "number" and type(info.button) == "string" and type(info.modifiers) == "number" then
			profile[#profile + 1] = { type = info.type, button = info.button, modifiers = info.modifiers, actionID = tonumber(info.actionID) or 0 }
		end
	end
	if #profile == 0 then
		return nil, "EMPTY"
	end
	local ok = pcall(C_ClickBindings.SetProfileByInfo, profile)
	if not ok then
		return nil, "FAILED"
	end
	return #profile
end

local function Known(spellID)
	return Binds:GetModule("ClickSpells"):IsKnown(spellID)
end

-- What belongs to the current character: second spells whose both spells it knows, and the combat resurrection.
local function CharacterData(withBlizzard)
	local clicks = Binds.db.clicks
	local data = { clicks = { secondSpells = {} } }
	for first, second in pairs(clicks.secondSpells) do
		if Known(first) and Known(second) then
			data.clicks.secondSpells[first] = second
		end
	end
	data.clicks.combatRez = clicks.combatRez
	if withBlizzard ~= false then
		data.blizzard = Backup:GetBlizzardProfile()
	end
	return data
end

----------------------------------------------------------------------
-- Public
----------------------------------------------------------------------

function Backup:Export(scope, withBlizzard)
	local data
	if scope == "character" then
		data = CharacterData(withBlizzard)
	else
		scope = "account"
		data = Copy(Binds.db)
		if withBlizzard ~= false then
			data.blizzard = Backup:GetBlizzardProfile()
		end
	end
	local payload = Base64Encode(Serialize(data))
	local parts = { VERSION, scope, payload, Check(payload) }
	if scope == "character" then
		local name, realm
		if UnitFullName then
			name, realm = UnitFullName("player")
		end
		name = name or UnitName("player")
		if name then
			table.insert(parts, 3, realm and realm ~= "" and (name .. "-" .. realm) or name)
		end
	end
	return table.concat(parts, ":")
end

-- Returns true, scope, count, blizzard on success (blizzard: count of restored Blizzard click casts, or nil, reason);
-- false, error key (a locale key suffix) otherwise. withBlizzard decides whether Blizzard's click casting is restored.
function Backup:Import(text, withBlizzard)
	text = (text or ""):gsub("%s+", "")
	local version, scope, rest = text:match("^([^:]+):([^:]+):(.+)$")
	local name, payload, check
	if rest then
		name, payload, check = rest:match("^([^:]+):([^:]+):([^:]+)$")
		if not name then
			payload, check = rest:match("^([^:]+):([^:]+)$")
		end
	end
	if version ~= VERSION or not payload then
		return false, "FORMAT"
	end
	if Check(payload) ~= check then
		return false, "DAMAGED"
	end
	local decoded = Base64Decode(payload)
	local data = decoded and Deserialize(decoded)
	if type(data) ~= "table" then
		return false, "DAMAGED"
	end
	if scope == "account" then
		local clean = Sanitize(data, Binds.defaults, "")
		if not clean then
			return false, "DAMAGED"
		end
		Merge(Binds.db, clean)
		local blizzard, reason
		if withBlizzard ~= false and type(data.blizzard) == "table" then
			blizzard, reason = self:SetBlizzardProfile(data.blizzard)
		elseif withBlizzard ~= false then
			reason = "EMPTY"
		end
		-- Second spells of an account export replace the stored ones instead of mixing with them.
		if type(clean.clicks) == "table" and type(clean.clicks.secondSpells) == "table" then
			Binds.db.clicks.secondSpells = Copy(clean.clicks.secondSpells)
		end
		return true, scope, 0, blizzard, reason, nil
	elseif scope == "character" then
		local clean = Sanitize(data, { clicks = { secondSpells = {} } }, "")
		local count = 0
		if clean and clean.clicks then
			for first, second in pairs(clean.clicks.secondSpells or {}) do
				if Known(first) and Known(second) then
					Binds.db.clicks.secondSpells[first] = second
					count = count + 1
				end
			end
			if clean.clicks.combatRez then
				Binds.db.clicks.combatRez = clean.clicks.combatRez
			end
		end
		local blizzard, reason
		if withBlizzard ~= false and type(data.blizzard) == "table" then
			blizzard, reason = self:SetBlizzardProfile(data.blizzard)
		elseif withBlizzard ~= false then
			reason = "EMPTY"
		end
		return true, scope, count, blizzard, reason, name
	end
	return false, "FORMAT"
end
