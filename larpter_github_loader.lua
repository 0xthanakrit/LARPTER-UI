local LIBRARY_URL = "https://raw.githubusercontent.com/0xthanakrit/LARPTER-UI/main/larpter_premium.lua"

local source = game:HttpGet(LIBRARY_URL)
local Larpter = loadstring(source)()

local Window = Larpter:CreateDemo({
    ForceReload = true,
    ConsoleLoading = "line",
    MinBootTime = 2,
})

Window:Info("Loaded from GitHub", {
    source = LIBRARY_URL,
})
