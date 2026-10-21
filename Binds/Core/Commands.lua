local _, ns = ...
local Binds = ns.Binds
local L = ns.L

-- Deliberately few commands; everything else lives in the options panel.
local commands = {}

commands[""] = function()
	Binds:OpenOptions()
end

commands.minimap = function()
	local broker = Binds:GetModule("Broker")
	if broker then
		broker:ToggleMinimapButton()
	end
end

commands.help = function()
	Binds:Print(L.CMD_HELP)
end

SLASH_BINDS1 = "/binds"
SlashCmdList.BINDS = function(input)
	local command = strtrim(input or ""):lower()
	local handler = commands[command]
	if handler then
		handler()
	else
		Binds:Print(L.CMD_UNKNOWN)
		commands.help()
	end
end
