-- LARPTER Premium production loader
-- Usage:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_github_loader.lua"))()

local LIBRARY_URL = "https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_premium.lua"

local OPTIONS = {
    Title = "LARPTER Premium",
    Subtitle = "Linoria-inspired control surface",
    SafeMode = true,
    ProtectGui = false,
    GuiParent = "Auto",
    ConsoleLoading = "developer",
    MinBootTime = 2.8,
    PreventDuplicate = true,
    ForceReload = false,
    MaxLogs = 250,
}

local BOOT_SESSION = string.format("%04X", math.random(0, 65535))
local BOOT_STARTED = os.clock()

local function bootBar(progress)
    local width = 20
    local filled = math.floor(progress * width + 0.5)
    return string.rep("#", filled) .. string.rep(".", width - filled)
end

local function bootLog(progress, message)
    if OPTIONS.ConsoleLoading == false or OPTIONS.ConsoleLoading == "silent" then
        return
    end

    progress = math.max(0, math.min(1, tonumber(progress) or 0))
    print(string.format(
        "[LARPTER Loader:%s] %3d%% [%s] %s",
        BOOT_SESSION,
        math.floor(progress * 100 + 0.5),
        bootBar(progress),
        tostring(message or "Loading")
    ))
end

bootLog(0.02, "requesting library")

local okSource, source = pcall(function()
    return game:HttpGet(LIBRARY_URL)
end)

if not okSource then
    bootLog(1, "download failed")
    error("[LARPTER Loader] Failed to download library: " .. tostring(source), 2)
end

bootLog(0.24, "library downloaded")

local chunk, compileError = loadstring(source)

if not chunk then
    bootLog(1, "compile failed")
    error("[LARPTER Loader] Failed to compile library: " .. tostring(compileError), 2)
end

bootLog(0.42, "library compiled")

local okLibrary, Larpter = pcall(chunk)

if not okLibrary then
    bootLog(1, "library runtime failed")
    error("[LARPTER Loader] Library runtime error: " .. tostring(Larpter), 2)
end

if type(Larpter) ~= "table" or type(Larpter.CreateDemo) ~= "function" then
    bootLog(1, "invalid library")
    error("[LARPTER Loader] Invalid library response", 2)
end

bootLog(0.58, "mounting ui")

local Window = Larpter:CreateDemo(OPTIONS)

Window:Info("Loaded from GitHub", {
    source = LIBRARY_URL,
    version = Larpter.Version or "unknown",
})

bootLog(1, string.format("ready in %.1fs", os.clock() - BOOT_STARTED))

return Window
