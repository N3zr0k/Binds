local _, ns = ...
local Binds = ns.Binds
local L = ns.L

-- Diagnostics for the optional addon BugLab. Shipped in the release on purpose: users can run them for bug reports.
-- Log lines stay English: they are developer output, not UI.
if not (BugLab and BugLab.RegisterProbe) then
	return
end

local ADDON = Binds.name

local function Scanner()
	return Binds:GetModule("Scanner")
end

BugLab:RegisterProbe(ADDON, "env", {
	title = L.PROBE_ENV,
	desc = L.PROBE_ENV_DESC,
	mode = "once",
	run = function(ctx)
		local _, build, _, interface = GetBuildInfo()
		ctx.log:Dump({
			version = Binds.version,
			interface = interface,
			build = build,
			tooltipDataProcessor = TooltipDataProcessor ~= nil,
			clickBindings = Scanner():IsClickCastingAvailable(),
			settingsApi = Settings ~= nil and Settings.RegisterCanvasLayoutCategory ~= nil,
			addonCompartment = AddonCompartmentFrame ~= nil,
			libDataBroker = LibStub("LibDataBroker-1.1", true) ~= nil,
			libDBIcon = LibStub("LibDBIcon-1.0", true) ~= nil,
		}, "Environment")
	end,
})

BugLab:RegisterProbe(ADDON, "scan", {
	title = L.PROBE_SCAN,
	desc = L.PROBE_SCAN_DESC,
	mode = "once",
	run = function(ctx)
		local scanner = Scanner()
		scanner:Rebuild()
		local counts = {}
		for kind, entries in pairs(scanner:GetAll()) do
			local count = 0
			for _ in pairs(entries) do
				count = count + 1
			end
			counts[kind] = count
		end
		ctx.log:Dump(counts, "Actions with bindings")
	end,
})

BugLab:RegisterProbe(ADDON, "lookup", {
	title = L.PROBE_LOOKUP,
	desc = L.PROBE_LOOKUP_DESC,
	mode = "once",
	params = {
		{ key = "kind", type = "choice", label = L.PROBE_PARAM_KIND, values = { "spell", "item", "macro" } },
		{ key = "id", type = "number", label = L.PROBE_PARAM_ID },
	},
	run = function(ctx, p)
		local entry = Scanner():Get(p.kind, p.id)
		if not entry then
			ctx.log:Info("No bindings for %s %s", p.kind, p.id)
			return
		end
		ctx.log:Dump({ keyboard = entry.keyboard, mouse = entry.mouse, click = entry.click }, p.kind .. " " .. p.id)
	end,
})

BugLab:RegisterProbe(ADDON, "key", {
	title = L.PROBE_KEY,
	desc = L.PROBE_KEY_DESC,
	mode = "once",
	params = {
		{ key = "key", type = "text", label = L.PROBE_PARAM_KEY },
	},
	run = function(ctx, p)
		local key = p.key:upper()
		local scanner = Scanner()
		ctx.log:Info("%s -> %s, \"%s\"", key, tostring(scanner:Classify(key)), scanner:FormatKey(key))
	end,
})

BugLab:RegisterProbe(ADDON, "clickcasts", {
	title = L.PROBE_CLICKCASTS,
	desc = L.PROBE_CLICKCASTS_DESC,
	mode = "once",
	run = function(ctx)
		local scanner = Scanner()
		if not scanner:IsClickCastingAvailable() then
			ctx.log:Warn("Click casting API not available in this client")
			return
		end
		ctx.log:Dump(scanner:GetClickCasts(), "Click casts")
	end,
})
