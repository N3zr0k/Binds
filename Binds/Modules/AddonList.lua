local _, ns = ...
local Binds = ns.Binds

-- Retail shows the TOC IconTexture in the addon list, Forever does not. There the icon is put in front of the
-- title at display time instead of in the TOC, so Retail never shows it twice. Only text is changed.
local AddonList = Binds:RegisterModule("AddonList")

local ICON = Binds:Texture("Binds_Icon_32x32", 0) .. " "

local function Decorate(titleText)
	if not titleText or not titleText.GetText then
		return
	end
	local text = titleText:GetText()
	if text and not text:find(ICON, 1, true) and text:find(Binds.title, 1, true) then
		titleText:SetText(ICON .. text)
	end
end

local function IsBinds(addonIndex)
	local getInfo = (C_AddOns and C_AddOns.GetAddOnInfo) or GetAddOnInfo
	return addonIndex and getInfo and getInfo(addonIndex) == Binds.name
end

local function TitleOf(entry)
	return entry and (entry.Title or (entry.GetName and entry:GetName() and _G[entry:GetName() .. "Title"]))
end

function AddonList:OnInitialize()
	if Binds.isRetail then
		return
	end
	-- Scroll box list (newer UI): one call per visible entry.
	if AddonList_InitButton then
		hooksecurefunc("AddonList_InitButton", function(entry, addonIndex)
			if IsBinds(addonIndex) then
				Decorate(TitleOf(entry))
			end
		end)
	end
	-- Fixed entry frames (older UI): check the visible rows after each update.
	if AddonList_Update then
		hooksecurefunc("AddonList_Update", function()
			for i = 1, MAX_ADDONS_DISPLAYED or 0 do
				local entry = _G["AddonListEntry" .. i]
				if entry and entry:IsShown() and IsBinds(entry:GetID()) then
					Decorate(TitleOf(entry))
				end
			end
		end)
	end
end
