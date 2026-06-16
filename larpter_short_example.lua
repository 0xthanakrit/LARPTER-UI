-- LARPTER Premium short API example
-- Run this after pushing larpter_premium.lua to GitHub.

local Larpter = loadstring(game:HttpGet("https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_premium.lua"))()

if Larpter:IsLoaded() then
    Larpter:DestroyActive()
end

local UI = Larpter:New({
    Title = "LARPTER Short",
    Subtitle = "Short API example",
    ConsoleLoading = "developer",
    MinBootTime = 1.5,
    F9Logs = true,
    F9LogPrefix = "LARPTER",
})

local Main = UI:Tab("Main")
local Farm = Main:Sec("Farm")

Farm:Note("Short API", "Use Btn, Tog, Sld, Drop, Box, and Bind for quick UI scripts.")

Farm:Btn("Start", function()
    UI:OK("Start clicked")
    UI:Dev("This line is sent only to F9")
end)

Farm:Tog("Auto Farm", false, function(enabled)
    UI:I("Auto Farm changed", { enabled = enabled })
end)

Farm:Sld("Speed", 16, 100, 24, function(value)
    UI:D("Speed changed", { value = value })
end)

Farm:Drop("Mode", { "Safe", "Fast", "Balanced" }, "Safe", function(mode)
    UI:I("Mode selected", { mode = mode })
end)

Farm:Box("Webhook", "Paste URL", function(value)
    UI:I("Webhook changed", { length = #value })
end)

Farm:Bind("Toggle UI", Enum.KeyCode.RightShift, function()
    UI:Toggle()
end)

local Settings = UI:Tab("Settings")
local General = Settings:Sec("General")

General:Tog("Mirror logs to F9", true, function(enabled)
    UI:F9(enabled)
    UI:I("F9 mirror changed", { enabled = enabled })
end)

General:Btn("Open Logs", function()
    UI:Logs()
end)

General:Line("Builder")
General:Note("Config builder", "You can also use Larpter:Build({...}) when you want one table to create the whole UI.")

UI:OK("Short API ready")

return UI
