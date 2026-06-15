-- LARPTER Premium production loader
-- Usage:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_github_loader.lua"))()

local LIBRARY_URL = "https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_premium.lua"

local OPTIONS = {
    Title = "LARPTER Premium",
    Subtitle = "Prism steel Roblox control deck",
    ConsoleLoading = "line",
    MinBootTime = 2.8,
    PreventDuplicate = true,
    ForceReload = false,
    MaxLogs = 250,
}

local okSource, source = pcall(function()
    return game:HttpGet(LIBRARY_URL)
end)

if not okSource then
    error("[LARPTER Loader] Failed to download library: " .. tostring(source), 2)
end

local chunk, compileError = loadstring(source)

if not chunk then
    error("[LARPTER Loader] Failed to compile library: " .. tostring(compileError), 2)
end

local okLibrary, Larpter = pcall(chunk)

if not okLibrary then
    error("[LARPTER Loader] Library runtime error: " .. tostring(Larpter), 2)
end

if type(Larpter) ~= "table" or type(Larpter.CreateDemo) ~= "function" then
    error("[LARPTER Loader] Invalid library response", 2)
end

local Window = Larpter:CreateDemo(OPTIONS)

Window:Info("Loaded from GitHub", {
    source = LIBRARY_URL,
    version = Larpter.Version or "unknown",
})

return Window
