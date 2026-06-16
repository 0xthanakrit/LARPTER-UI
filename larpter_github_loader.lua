-- LARPTER Premium production loader
-- Usage:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_github_loader.lua"))()

local LIBRARY_URL = "https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_premium.lua"

local OPTIONS = {
    Title = "LARPTER Premium",
    Subtitle = "Minimal UI library",
    SafeMode = true,
    ProtectGui = false,
    GuiParent = "Auto",
    ConsoleLoading = "developer",
    MinBootTime = 1.8,
    PreventDuplicate = true,
    ForceReload = false,
    MaxLogs = 250,
}

local BOOT_STARTED = os.clock()

local function bootLog(message)
    if OPTIONS.ConsoleLoading == false or OPTIONS.ConsoleLoading == "silent" then
        return
    end

    print("[LARPTER Loader] " .. tostring(message or "Loading"))
end

bootLog("requesting library")

local okSource, source = pcall(function()
    return game:HttpGet(LIBRARY_URL)
end)

if not okSource then
    bootLog("download failed")
    error("[LARPTER Loader] Failed to download library: " .. tostring(source), 2)
end

bootLog("library downloaded")

local chunk, compileError = loadstring(source)

if not chunk then
    bootLog("compile failed")
    error("[LARPTER Loader] Failed to compile library: " .. tostring(compileError), 2)
end

bootLog("library compiled")

local okLibrary, Larpter = pcall(chunk)

if not okLibrary then
    bootLog("library runtime failed")
    error("[LARPTER Loader] Library runtime error: " .. tostring(Larpter), 2)
end

if type(Larpter) ~= "table" or type(Larpter.CreateDemo) ~= "function" then
    bootLog("invalid library")
    error("[LARPTER Loader] Invalid library response", 2)
end

bootLog("mounting ui")

local Window = Larpter:CreateDemo(OPTIONS)

Window:Info("Loaded from GitHub", {
    source = LIBRARY_URL,
    version = Larpter.Version or "unknown",
})

bootLog(string.format("ready in %.1fs", os.clock() - BOOT_STARTED))

return Window
