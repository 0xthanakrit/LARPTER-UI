local LIBRARY_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/larpter_premium.lua"

local source = game:HttpGet(LIBRARY_URL)
local Larpter = loadstring(source)()

local Window = Larpter:CreateDemo()

Window:Info("Loaded from GitHub", {
    source = LIBRARY_URL,
})

