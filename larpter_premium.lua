--[[
    LARPTER Premium UI Framework
    Version 7.0.0

    Clean minimal Roblox UI library:
    - window, tabs, sections, controls
    - built-in log console
    - boot overlay with console progress
    - duplicate-load guard and deterministic cleanup
    - simple Fluent-like API
]]

local Larpter = {
    Name = "LARPTER Premium",
    Version = "7.0.0",
}

local STATE_KEY = "__LARPTER_PREMIUM_STATE_V7"

local Services = setmetatable({}, {
    __index = function(self, key)
        local service = game:GetService(key)
        rawset(self, key, service)
        return service
    end,
})

local Players = Services.Players
local TweenService = Services.TweenService
local UserInputService = Services.UserInputService
local RunService = Services.RunService
local LocalPlayer = Players.LocalPlayer

local Theme = {
    Shell = Color3.fromRGB(230, 236, 245),
    Surface = Color3.fromRGB(247, 249, 252),
    SurfaceHigh = Color3.fromRGB(255, 255, 255),
    SurfaceLow = Color3.fromRGB(218, 226, 237),
    Card = Color3.fromRGB(255, 255, 255),
    CardHover = Color3.fromRGB(241, 246, 253),
    Stroke = Color3.fromRGB(198, 209, 223),
    StrokeSoft = Color3.fromRGB(222, 230, 240),
    Accent = Color3.fromRGB(37, 99, 235),
    AccentHover = Color3.fromRGB(29, 78, 216),
    AccentSoft = Color3.fromRGB(219, 234, 254),
    Text = Color3.fromRGB(15, 23, 42),
    TextMuted = Color3.fromRGB(71, 85, 105),
    TextFaint = Color3.fromRGB(100, 116, 139),
    White = Color3.fromRGB(255, 255, 255),
    Green = Color3.fromRGB(16, 185, 129),
    Amber = Color3.fromRGB(245, 158, 11),
    Red = Color3.fromRGB(239, 68, 68),
    Purple = Color3.fromRGB(124, 58, 237),
}

local Radius = {
    Sm = 6,
    Md = 8,
    Lg = 12,
    Xl = 16,
}

local Motion = {
    Fast = 0.12,
    Base = 0.22,
    Slow = 0.36,
}

local LogLevels = {
    info = { Label = "INFO", Color = Theme.Accent },
    success = { Label = "OK", Color = Theme.Green },
    warn = { Label = "WARN", Color = Theme.Amber },
    error = { Label = "ERR", Color = Theme.Red },
    debug = { Label = "DBG", Color = Theme.Purple },
}

local LogOrder = { "info", "success", "warn", "error", "debug" }

local function syncLogColors()
    LogLevels.info.Color = Theme.Accent
    LogLevels.success.Color = Theme.Green
    LogLevels.warn.Color = Theme.Amber
    LogLevels.error.Color = Theme.Red
    LogLevels.debug.Color = Theme.Purple
end

local function noop() end

local function merge(a, b)
    local out = {}

    for key, value in pairs(a or {}) do
        out[key] = value
    end

    for key, value in pairs(b or {}) do
        out[key] = value
    end

    return out
end

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end

    if value > maxValue then
        return maxValue
    end

    return value
end

local function round(value, decimals)
    decimals = decimals or 0

    if decimals <= 0 then
        return math.floor(value + 0.5)
    end

    local factor = 10 ^ decimals
    return math.floor(value * factor + 0.5) / factor
end

local function asString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function safeCall(callback, ...)
    if type(callback) ~= "function" then
        return true
    end

    local ok, result = pcall(callback, ...)

    if not ok then
        warn("[LARPTER Premium] callback error: " .. tostring(result))
    end

    return ok, result
end

local function getEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)

        if ok and type(env) == "table" then
            return env
        end
    end

    return _G
end

local function getState()
    local env = getEnv()
    env[STATE_KEY] = env[STATE_KEY] or {}
    return env[STATE_KEY]
end

local function create(className, props, children)
    local object = Instance.new(className)
    props = props or {}

    for key, value in pairs(props) do
        if key ~= "Parent" then
            object[key] = value
        end
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    if props.Parent then
        object.Parent = props.Parent
    end

    return object
end

local function corner(radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or Radius.Md),
    })
end

local function stroke(color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    })
end

local function padding(left, top, right, bottom)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function list(direction, gap)
    return create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 8),
    })
end

local function textBase(value, size, color, bold)
    return {
        Text = value or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 13,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        TextStrokeTransparency = 1,
    }
end

local function text(parent, props)
    return create("TextLabel", merge(textBase(), merge(props or {}, {
        Parent = parent,
    })))
end

local function tween(object, props, duration, style, direction)
    if not object then
        return nil
    end

    local info = TweenInfo.new(
        duration or Motion.Base,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )

    local animation = TweenService:Create(object, info, props)
    animation:Play()
    return animation
end

local function setButtonPalette(buttonObject, normal, hover, press, apply)
    if normal then
        buttonObject:SetAttribute("LP_Normal", normal)

        if apply ~= false then
            buttonObject.BackgroundColor3 = normal
        end
    end

    if hover then
        buttonObject:SetAttribute("LP_Hover", hover)
    end

    if press then
        buttonObject:SetAttribute("LP_Press", press)
    end
end

local function button(parent, props, children)
    props = props or {}

    local normal = props.BackgroundColor3 or Theme.SurfaceHigh
    local hover = props.HoverColor or Theme.CardHover
    local press = props.PressColor or Theme.SurfaceLow
    local animate = props.Animate ~= false
    local cleanProps = merge({}, props)

    cleanProps.HoverColor = nil
    cleanProps.PressColor = nil
    cleanProps.Animate = nil

    local object = create("TextButton", merge({
        AutoButtonColor = false,
        BackgroundColor3 = normal,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        Parent = parent,
    }, cleanProps), children)

    setButtonPalette(object, normal, hover, press, false)

    if animate then
        object.MouseEnter:Connect(function()
            local color = object:GetAttribute("LP_Hover")
            if color then
                tween(object, { BackgroundColor3 = color }, Motion.Fast)
            end
        end)

        object.MouseLeave:Connect(function()
            local color = object:GetAttribute("LP_Normal")
            if color then
                tween(object, { BackgroundColor3 = color }, Motion.Fast)
            end
        end)

        object.MouseButton1Down:Connect(function()
            local color = object:GetAttribute("LP_Press")
            if color then
                tween(object, { BackgroundColor3 = color }, 0.08)
            end
        end)

        object.MouseButton1Up:Connect(function()
            local color = object:GetAttribute("LP_Hover")
            if color then
                tween(object, { BackgroundColor3 = color }, 0.08)
            end
        end)
    end

    return object
end

local function scroll(parent)
    return create("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = Theme.Stroke,
        ScrollBarThickness = 3,
        Size = UDim2.fromScale(1, 1),
        Parent = parent,
    }, {
        padding(0, 0, 8, 0),
        list(Enum.FillDirection.Vertical, 10),
    })
end

local function keyCode(value, fallback)
    fallback = fallback or Enum.KeyCode.RightShift

    if typeof(value) == "EnumItem" then
        return value
    end

    if type(value) == "string" then
        local ok, resolved = pcall(function()
            return Enum.KeyCode[value]
        end)

        if ok and resolved then
            return resolved
        end
    end

    return fallback
end

local function metaString(meta)
    if meta == nil then
        return ""
    end

    if type(meta) ~= "table" then
        return tostring(meta)
    end

    local out = {}
    local count = 0

    for key, value in pairs(meta) do
        count = count + 1
        out[#out + 1] = tostring(key) .. "=" .. tostring(value)

        if count >= 8 then
            out[#out + 1] = "..."
            break
        end
    end

    return table.concat(out, "  ")
end

local function applyTheme(theme)
    if type(theme) ~= "table" then
        return
    end

    for key, value in pairs(theme) do
        if Theme[key] ~= nil and typeof(value) == "Color3" then
            Theme[key] = value
        end
    end

    syncLogColors()
end

local function normalizeConfig(config)
    config = config or {}

    if config.SafeMode ~= false then
        config.SafeMode = true
        config.ProtectGui = config.ProtectGui == true

        if config.PreventDuplicate == nil then
            config.PreventDuplicate = true
        end

        if config.ForceReload == nil then
            config.ForceReload = false
        end

        if config.ConsoleLoading == nil then
            config.ConsoleLoading = "developer"
        end

        if config.GuiParent == nil then
            config.GuiParent = "Auto"
        end

        if config.MaxLogs == nil then
            config.MaxLogs = 250
        end
    end

    return config
end

local function getGuiParent(config)
    if config.GuiParent == "PlayerGui" and LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    if config.GuiParent ~= "CoreGui" and type(gethui) == "function" then
        local ok, hui = pcall(gethui)

        if ok and hui then
            return hui
        end
    end

    local ok, coreGui = pcall(function()
        return Services.CoreGui
    end)

    if ok and coreGui then
        return coreGui
    end

    if LocalPlayer then
        return LocalPlayer:WaitForChild("PlayerGui")
    end

    return nil
end

local function protectGui(gui, enabled)
    -- Compatibility option only. This library does not implement stealth or bypass behavior.
    return gui, enabled
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ Items = {} }, Maid)
end

function Maid:Add(item)
    self.Items[#self.Items + 1] = item
    return item
end

function Maid:Clean()
    for index = #self.Items, 1, -1 do
        local item = self.Items[index]
        self.Items[index] = nil

        if typeof(item) == "RBXScriptConnection" then
            pcall(function()
                item:Disconnect()
            end)
        elseif typeof(item) == "Instance" then
            pcall(function()
                item:Destroy()
            end)
        elseif type(item) == "function" then
            pcall(item)
        end
    end
end

local Console = {}
Console.__index = Console

function Console.new(option)
    local mode = "line"

    if option == false or option == "silent" then
        mode = "silent"
    elseif option == "developer" or option == "devconsole" or option == "f9" then
        mode = "developer"
    elseif option == "compact" then
        mode = "compact"
    elseif option == "verbose" then
        mode = "verbose"
    end

    return setmetatable({
        Mode = mode,
        StartedAt = os.clock(),
        Session = string.format("%04X", math.random(0, 65535)),
        HasLineConsole = type(rconsoleprint) == "function",
        LastLength = 0,
        LastPercent = 0,
        LastBucket = nil,
        PrintedStart = false,
        PrintedDone = false,
    }, Console)
end

function Console:_bar(progress)
    local width = 22
    local filled = clamp(math.floor(progress * width + 0.5), 0, width)
    return string.rep("#", filled) .. string.rep(".", width - filled)
end

function Console:_line(progress, message)
    local percent = math.floor(progress * 100 + 0.5)
    return string.format(
        "LARPTER %s  %03d/100 [%s] %s",
        self.Session,
        percent,
        self:_bar(progress),
        message or "Loading"
    )
end

function Console:Progress(progress, message, force)
    if self.Mode == "silent" then
        return
    end

    progress = clamp(tonumber(progress) or 0, 0, 1)
    message = tostring(message or "Loading")

    if self.Mode == "line" then
        local line = self:_line(progress, message)

        if self.HasLineConsole then
            local pad = math.max(0, self.LastLength - #line)
            rconsoleprint("\r" .. line .. string.rep(" ", pad))
            self.LastLength = #line

            if progress >= 1 or force == "done" then
                rconsoleprint("\n")
            end
        elseif force or not self.PrintedStart or progress >= 1 then
            self.PrintedStart = true
            print(line)
        end

        return
    end

    if self.Mode == "developer" then
        if not self.PrintedStart then
            self.PrintedStart = true
            print(string.format("[LARPTER] boot session %s", self.Session))
        end

        local target = clamp(math.floor(progress * 100 + 0.5), 0, 100)
        local start = math.max(self.LastPercent + 1, 1)

        for percent = start, target do
            print(string.format(
                "[LARPTER] %03d/100 [%s] %s",
                percent,
                self:_bar(percent / 100),
                message
            ))
        end

        self.LastPercent = math.max(self.LastPercent, target)

        if (progress >= 1 or force == "done") and not self.PrintedDone then
            self.PrintedDone = true
            print(string.format("[LARPTER] ready in %.1fs", os.clock() - self.StartedAt))
        end

        return
    end

    if self.Mode == "compact" and not force then
        local bucket = math.floor(progress * 5)

        if bucket == self.LastBucket then
            return
        end

        self.LastBucket = bucket
    end

    print(self:_line(progress, message))
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function controlShell(section, config, height)
    config = config or {}

    local root = create("Frame", {
        Active = true,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 64),
        Parent = section.Content,
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local title = text(root, merge(textBase(config.Title or "Untitled", 14, Theme.Text, true), {
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -208, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local description = text(root, merge(textBase(config.Description or "", 12, Theme.TextMuted), {
        Position = UDim2.fromOffset(16, 34),
        Size = UDim2.new(1, -208, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = config.Description ~= nil and config.Description ~= "",
    }))

    local accent = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.new(0, 3, 1, -24),
        Parent = root,
    }, {
        corner(3),
    })

    root.MouseEnter:Connect(function()
        tween(root, { BackgroundColor3 = Theme.CardHover }, Motion.Fast)
    end)

    root.MouseLeave:Connect(function()
        tween(root, { BackgroundColor3 = Theme.Card }, Motion.Fast)
    end)

    local item = {
        Root = root,
        TitleLabel = title,
        DescriptionLabel = description,
        Accent = accent,
        Section = section,
    }

    function item:SetTitle(value)
        self.TitleLabel.Text = asString(value)
    end

    function item:SetDescription(value)
        value = asString(value)
        self.DescriptionLabel.Text = value
        self.DescriptionLabel.Visible = value ~= ""
    end

    function item:Destroy()
        self.Root:Destroy()
    end

    return item
end

local function resolveSection(host)
    if getmetatable(host) == Section then
        return host
    end

    if not host.DefaultSection then
        host.DefaultSection = host:AddSection("Controls")
    end

    return host.DefaultSection
end

function Section:AddParagraph(config)
    config = config or {}

    local root = create("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.Content,
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(16, 14, 16, 14),
        list(Enum.FillDirection.Vertical, 6),
    })

    local title = text(root, merge(textBase(config.Title or "Note", 14, Theme.Text, true), {
        Size = UDim2.new(1, 0, 0, 20),
        TextWrapped = true,
    }))

    local body = text(root, merge(textBase(config.Content or config.Description or "", 13, Theme.TextMuted), {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextWrapped = true,
    }))

    local object = {
        Root = root,
        TitleLabel = title,
        ContentLabel = body,
    }

    function object:SetTitle(value)
        self.TitleLabel.Text = asString(value)
    end

    function object:SetContent(value)
        self.ContentLabel.Text = asString(value)
    end

    function object:Destroy()
        self.Root:Destroy()
    end

    return object
end

function Section:AddDivider(config)
    config = config or {}

    local root = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, config.Title and 30 or 16),
        Parent = self.Content,
    })

    create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.StrokeSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = root,
    })

    if config.Title then
        local label = text(root, merge(textBase(string.upper(config.Title), 10, Theme.TextFaint, true), {
            BackgroundColor3 = Theme.Surface,
            BackgroundTransparency = 0,
            Position = UDim2.fromOffset(12, 4),
            Size = UDim2.fromOffset(130, 22),
            TextXAlignment = Enum.TextXAlignment.Center,
        }))
        corner(11).Parent = label
        stroke(Theme.StrokeSoft, 0, 1).Parent = label
    end

    return {
        Root = root,
        Destroy = function(self)
            self.Root:Destroy()
        end,
    }
end

function Section:AddButton(config)
    config = config or {}

    local item = controlShell(self, config, 64)
    local busy = false

    local action = button(item.Root, {
        BackgroundColor3 = Theme.Accent,
        HoverColor = Theme.AccentHover,
        PressColor = Theme.AccentHover,
        Text = string.upper(config.ButtonText or config.Text or "Run"),
        TextColor3 = Theme.White,
        TextSize = 13,
        Position = UDim2.new(1, -112, 0.5, -17),
        Size = UDim2.fromOffset(96, 34),
    }, {
        corner(Radius.Md),
    })

    action.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        tween(action, {
            Size = UDim2.fromOffset(90, 32),
            Position = UDim2.new(1, -109, 0.5, -16),
        }, 0.08)
        safeCall(config.Callback or noop)

        task.delay(tonumber(config.Cooldown) or 0.16, function()
            if action and action.Parent then
                busy = false
                tween(action, {
                    Size = UDim2.fromOffset(96, 34),
                    Position = UDim2.new(1, -112, 0.5, -17),
                }, Motion.Fast)
            end
        end)
    end)

    item.Button = action
    return item
end

function Section:AddToggle(config)
    config = config or {}

    local item = controlShell(self, config, 64)
    local value = config.Default == true

    local track = button(item.Root, {
        BackgroundColor3 = value and Theme.Accent or Theme.SurfaceLow,
        HoverColor = value and Theme.AccentHover or Theme.Stroke,
        PressColor = Theme.Accent,
        Position = UDim2.new(1, -70, 0.5, -14),
        Size = UDim2.fromOffset(54, 28),
    }, {
        corner(14),
        stroke(value and Theme.AccentHover or Theme.Stroke, 0, 1),
    })

    local knob = create("Frame", {
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Position = value and UDim2.fromOffset(28, 4) or UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(20, 20),
        Parent = track,
    }, {
        corner(10),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local function repaint()
        setButtonPalette(
            track,
            value and Theme.Accent or Theme.SurfaceLow,
            value and Theme.AccentHover or Theme.Stroke,
            Theme.Accent,
            false
        )
        tween(track, { BackgroundColor3 = value and Theme.Accent or Theme.SurfaceLow }, Motion.Base)
        tween(knob, { Position = value and UDim2.fromOffset(28, 4) or UDim2.fromOffset(4, 4) }, Motion.Base)

        local border = track:FindFirstChildOfClass("UIStroke")
        if border then
            tween(border, { Color = value and Theme.AccentHover or Theme.Stroke }, Motion.Base)
        end
    end

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = nextValue == true
        repaint()

        if not silent then
            safeCall(config.Callback or noop, value)
        end
    end

    track.MouseButton1Click:Connect(function()
        item:SetValue(not value)
    end)

    item.Track = track
    item.Knob = knob
    return item
end

function Section:AddSlider(config)
    config = config or {}

    local min = tonumber(config.Min) or 0
    local max = tonumber(config.Max) or 100
    local decimals = tonumber(config.Rounding) or 0
    local suffix = config.Suffix or ""
    local value = clamp(tonumber(config.Default) or min, min, max)

    local item = controlShell(self, config, 82)
    item.TitleLabel.Size = UDim2.new(1, -126, 0, 20)
    item.DescriptionLabel.Size = UDim2.new(1, -126, 0, 18)

    local valueLabel = text(item.Root, merge(textBase("", 13, Theme.Accent, true), {
        BackgroundColor3 = Theme.AccentSoft,
        BackgroundTransparency = 0,
        Position = UDim2.new(1, -86, 0, 12),
        Size = UDim2.fromOffset(70, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Radius.Sm).Parent = valueLabel

    local track = button(item.Root, {
        Animate = false,
        BackgroundColor3 = Theme.SurfaceLow,
        Position = UDim2.new(0, 16, 1, -26),
        Size = UDim2.new(1, -32, 0, 10),
    }, {
        corner(5),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    }, {
        corner(5),
    })

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.White,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(20, 20),
        Parent = track,
    }, {
        corner(10),
        stroke(Theme.Accent, 0, 2),
    })

    local dragging = false

    local function alphaFromValue(nextValue)
        if max == min then
            return 0
        end

        return clamp((nextValue - min) / (max - min), 0, 1)
    end

    local function redraw()
        local alpha = alphaFromValue(value)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = tostring(value) .. suffix
    end

    local function setFromX(x)
        local alpha = clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        item:SetValue(min + (max - min) * alpha)
    end

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = clamp(round(tonumber(nextValue) or min, decimals), min, max)
        redraw()

        if not silent then
            safeCall(config.Callback or noop, value)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)

    self.Window.Maid:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))

    self.Window.Maid:Add(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    item:SetValue(value, true)
    return item
end

function Section:AddDropdown(config)
    config = config or {}

    local values = config.Values or {}
    local selected = config.Default or values[1]
    local opened = false
    local optionButtons = {}

    local item = controlShell(self, config, 64)
    item.Root.ClipsDescendants = true

    local display = button(item.Root, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        Text = asString(selected),
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(1, -174, 0.5, -17),
        Size = UDim2.fromOffset(158, 34),
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
        padding(10, 0, 30, 0),
    })

    local arrow = text(item.Root, merge(textBase("v", 12, Theme.TextFaint, true), {
        Position = UDim2.new(1, -38, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local menu = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(16, 64),
        Size = UDim2.new(1, -32, 0, 0),
        Visible = false,
        Parent = item.Root,
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
        padding(6, 6, 6, 6),
        list(Enum.FillDirection.Vertical, 5),
    })

    local function rebuild()
        for _, existing in ipairs(optionButtons) do
            existing:Destroy()
        end

        optionButtons = {}

        for _, option in ipairs(values) do
            local isSelected = option == selected
            local optionButton = button(menu, {
                BackgroundColor3 = isSelected and Theme.AccentSoft or Theme.SurfaceHigh,
                HoverColor = Theme.CardHover,
                PressColor = Theme.SurfaceLow,
                Text = asString(option),
                TextColor3 = isSelected and Theme.Accent or Theme.Text,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
            }, {
                corner(Radius.Sm),
                padding(9, 0, 9, 0),
            })

            optionButton.MouseButton1Click:Connect(function()
                item:SetValue(option)
                item:SetOpen(false)
            end)

            optionButtons[#optionButtons + 1] = optionButton
        end
    end

    function item:SetOpen(nextOpen)
        opened = nextOpen == true
        arrow.Text = opened and "^" or "v"
        menu.Visible = true

        local menuHeight = opened and math.min(#values * 33 + 12, 180) or 0
        tween(item.Root, { Size = UDim2.new(1, 0, 0, opened and 74 + menuHeight or 64) }, Motion.Base)
        tween(menu, { Size = UDim2.new(1, -32, 0, menuHeight) }, Motion.Base)

        if not opened then
            task.delay(Motion.Base + 0.03, function()
                if not opened and menu then
                    menu.Visible = false
                end
            end)
        end
    end

    function item:GetValue()
        return selected
    end

    function item:SetValue(nextValue, silent)
        selected = nextValue
        display.Text = asString(selected)
        rebuild()

        if not silent then
            safeCall(config.Callback or noop, selected)
        end
    end

    function item:SetValues(nextValues)
        values = nextValues or {}
        selected = values[1]
        display.Text = asString(selected)
        rebuild()
    end

    display.MouseButton1Click:Connect(function()
        item:SetOpen(not opened)
    end)

    rebuild()
    return item
end

function Section:AddInput(config)
    config = config or {}

    local item = controlShell(self, config, 64)
    local value = asString(config.Default)

    local input = create("TextBox", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = Theme.TextFaint,
        PlaceholderText = config.Placeholder or "Type...",
        Position = UDim2.new(1, -174, 0.5, -17),
        Size = UDim2.fromOffset(158, 34),
        Text = value,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = item.Root,
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
        padding(10, 0, 10, 0),
    })

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        nextValue = asString(nextValue)

        if config.MaxLength and #nextValue > config.MaxLength then
            nextValue = string.sub(nextValue, 1, config.MaxLength)
        end

        if config.Numeric and nextValue ~= "" and not tonumber(nextValue) then
            nextValue = value
        end

        value = nextValue
        input.Text = value

        if not silent then
            safeCall(config.Callback or noop, value)
        end
    end

    input.Focused:Connect(function()
        tween(input, { BackgroundColor3 = Theme.SurfaceHigh }, Motion.Fast)
        local border = input:FindFirstChildOfClass("UIStroke")
        if border then
            tween(border, { Color = Theme.Accent }, Motion.Fast)
        end
    end)

    input.FocusLost:Connect(function()
        tween(input, { BackgroundColor3 = Theme.Surface }, Motion.Fast)
        local border = input:FindFirstChildOfClass("UIStroke")
        if border then
            tween(border, { Color = Theme.Stroke }, Motion.Fast)
        end
        item:SetValue(input.Text)
    end)

    if not config.Finished then
        input:GetPropertyChangedSignal("Text"):Connect(function()
            if input:IsFocused() then
                item:SetValue(input.Text)
            end
        end)
    end

    item.Input = input
    return item
end

function Section:AddKeybind(config)
    config = config or {}

    local item = controlShell(self, config, 64)
    local bind = keyCode(config.Default, Enum.KeyCode.RightShift)
    local mode = config.Mode or "Toggle"
    local listening = false
    local toggled = false

    local keyButton = button(item.Root, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        Text = bind.Name,
        TextColor3 = Theme.Text,
        TextSize = 13,
        Position = UDim2.new(1, -150, 0.5, -17),
        Size = UDim2.fromOffset(134, 34),
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
    })

    local function setKey(nextKey)
        bind = nextKey
        keyButton.Text = bind.Name
        safeCall(config.ChangedCallback or noop, bind)
    end

    function item:GetValue()
        return bind
    end

    function item:SetValue(nextValue)
        setKey(keyCode(nextValue, bind))
    end

    keyButton.MouseButton1Click:Connect(function()
        listening = true
        keyButton.Text = "Press key"
    end)

    self.Window.Maid:Add(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if listening then
            listening = false
            setKey(input.KeyCode)
            return
        end

        if input.KeyCode == bind then
            if mode == "Hold" then
                safeCall(config.Callback or noop, true)
            else
                toggled = not toggled
                safeCall(config.Callback or noop, toggled)
            end
        end
    end))

    self.Window.Maid:Add(UserInputService.InputEnded:Connect(function(input)
        if mode == "Hold" and input.KeyCode == bind then
            safeCall(config.Callback or noop, false)
        end
    end))

    item.Button = keyButton
    return item
end

function Tab:AddSection(title)
    local config = type(title) == "table" and title or { Title = title }
    local sectionTitle = config.Title or config.Name or "Section"
    local parent = self.FullColumn
    local side = config.Side or self.NextSide

    if not self.Full then
        if side == "Right" or side == 2 then
            parent = self.RightColumn
            self.NextSide = "Left"
        else
            parent = self.LeftColumn
            self.NextSide = "Right"
        end
    end

    local root = create("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = parent,
    }, {
        corner(Radius.Lg),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(14, 14, 14, 14),
        list(Enum.FillDirection.Vertical, 10),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = root,
    })

    text(header, merge(textBase(sectionTitle, 15, Theme.Text, true), {
        Size = UDim2.new(1, -94, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local badge = text(header, merge(textBase(config.Badge or "LARPTER", 10, Theme.Accent, true), {
        BackgroundColor3 = Theme.AccentSoft,
        BackgroundTransparency = 0,
        Position = UDim2.new(1, -82, 0, 1),
        Size = UDim2.fromOffset(78, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(11).Parent = badge

    return setmetatable({
        Window = self.Window,
        Tab = self,
        Root = root,
        Content = root,
    }, Section)
end

for _, method in ipairs({
    "AddParagraph",
    "AddDivider",
    "AddButton",
    "AddToggle",
    "AddSlider",
    "AddDropdown",
    "AddInput",
    "AddKeybind",
}) do
    Tab[method] = function(self, ...)
        return Section[method](resolveSection(self), ...)
    end
end

function Window:_tabButton(tab)
    local visibleIndex = 0

    for _, item in ipairs(self.Tabs) do
        if not item.Internal then
            visibleIndex = visibleIndex + 1
        end
    end

    local tabButton = button(self.TabList, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        LayoutOrder = tab.Internal and 999 or visibleIndex,
        Size = UDim2.fromOffset(math.max(94, #tab.Title * 9 + 34), 32),
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local label = text(tabButton, merge(textBase(tab.Title, 13, Theme.TextMuted, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button = tabButton
    tab.Label = label
end

function Window:AddTab(config)
    config = config or {}

    local page = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHost,
    })

    local fullColumn = nil
    local leftColumn = nil
    local rightColumn = nil

    if config.Full == true then
        fullColumn = scroll(page)
    else
        leftColumn = scroll(page)
        leftColumn.Position = UDim2.fromOffset(0, 0)
        leftColumn.Size = UDim2.new(0.5, -5, 1, 0)

        rightColumn = scroll(page)
        rightColumn.Position = UDim2.new(0.5, 5, 0, 0)
        rightColumn.Size = UDim2.new(0.5, -5, 1, 0)
    end

    local tab = setmetatable({
        Window = self,
        Title = config.Title or "Tab",
        Internal = config.Internal == true,
        Full = config.Full == true,
        Page = page,
        FullColumn = fullColumn,
        LeftColumn = leftColumn,
        RightColumn = rightColumn,
        NextSide = "Left",
        DefaultSection = nil,
    }, Tab)

    self.Tabs[#self.Tabs + 1] = tab
    self:_tabButton(tab)

    if not self.ActiveTab or (self.ActiveTab == self.LogTab and not tab.Internal) then
        self:SelectTab(tab)
    end

    return tab
end

function Window:SelectTab(tab)
    if type(tab) == "number" then
        tab = self.Tabs[tab]
    end

    if not tab or self.ActiveTab == tab then
        return self
    end

    for _, item in ipairs(self.Tabs) do
        local selected = item == tab

        if selected then
            item.Page.Visible = true
            item.Page.Position = UDim2.fromOffset(10, 0)
            tween(item.Page, { Position = UDim2.fromOffset(0, 0) }, Motion.Base)
        else
            item.Page.Visible = false
        end

        setButtonPalette(
            item.Button,
            selected and Theme.Accent or Theme.Surface,
            selected and Theme.AccentHover or Theme.CardHover,
            selected and Theme.AccentHover or Theme.SurfaceLow,
            false
        )
        tween(item.Button, { BackgroundColor3 = selected and Theme.Accent or Theme.Surface }, Motion.Fast)
        item.Label.TextColor3 = selected and Theme.White or Theme.TextMuted
    end

    self.ActiveTab = tab
    self.ActiveLabel.Text = string.upper(tab.Title)
    return self
end

function Window:_logRow(entry)
    local style = LogLevels[entry.Level] or LogLevels.info

    local row = create("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.LogList,
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(12, 10, 12, 10),
        list(Enum.FillDirection.Vertical, 6),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        Parent = row,
    })

    local badge = text(header, merge(textBase(style.Label, 10, Theme.White, true), {
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.fromOffset(58, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(9).Parent = badge

    text(header, merge(textBase(entry.Time, 11, Theme.TextFaint, true), {
        Position = UDim2.fromOffset(68, 0),
        Size = UDim2.fromOffset(92, 22),
    }))

    text(row, merge(textBase(entry.Message, 13, Theme.Text), {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextWrapped = true,
    }))

    local meta = metaString(entry.Meta)
    text(row, merge(textBase(meta, 12, Theme.TextFaint), {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextWrapped = true,
        Visible = meta ~= "",
    }))

    entry.Row = row
    return row
end

function Window:_refreshLogs()
    if not self.LogList then
        return
    end

    local search = string.lower(self.LogSearch or "")

    for _, entry in ipairs(self.LogEntries) do
        local levelOk = self.LogFilters[entry.Level] == true
        local content = string.lower(entry.Message .. " " .. metaString(entry.Meta))
        local searchOk = search == "" or string.find(content, search, 1, true) ~= nil

        if entry.Row then
            entry.Row.Visible = levelOk and searchOk
        end
    end

    if self.AutoScrollLogs then
        task.defer(function()
            if self.LogList then
                self.LogList.CanvasPosition = Vector2.new(0, self.LogList.AbsoluteCanvasSize.Y)
            end
        end)
    end
end

function Window:_buildLogTab()
    local tab = self:AddTab({ Title = "Logs", Internal = true, Full = true })
    self.LogTab = tab

    local page = tab.Page

    if tab.FullColumn then
        tab.FullColumn:Destroy()
        tab.FullColumn = nil
    end

    local toolbar = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 116),
        Parent = page,
    }, {
        corner(Radius.Lg),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(14, 14, 14, 14),
    })

    text(toolbar, merge(textBase("Log Console", 15, Theme.Text, true), {
        Size = UDim2.new(1, -300, 0, 22),
    }))

    local search = create("TextBox", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        PlaceholderColor3 = Theme.TextFaint,
        PlaceholderText = "Search logs",
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, -292, 0, 36),
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toolbar,
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
        padding(10, 0, 10, 0),
    })

    local auto = button(toolbar, {
        BackgroundColor3 = Theme.Accent,
        HoverColor = Theme.AccentHover,
        PressColor = Theme.AccentHover,
        Position = UDim2.new(1, -292, 0, 34),
        Size = UDim2.fromOffset(78, 36),
        Text = "AUTO",
        TextColor3 = Theme.White,
        TextSize = 11,
    }, {
        corner(Radius.Md),
    })

    local copy = button(toolbar, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        Position = UDim2.new(1, -206, 0, 34),
        Size = UDim2.fromOffset(88, 36),
        Text = "COPY",
        TextColor3 = Theme.Text,
        TextSize = 11,
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
    })

    local clear = button(toolbar, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        Position = UDim2.new(1, -110, 0, 34),
        Size = UDim2.fromOffset(110, 36),
        Text = "CLEAR",
        TextColor3 = Theme.Text,
        TextSize = 11,
    }, {
        corner(Radius.Md),
        stroke(Theme.Stroke, 0, 1),
    })

    local filters = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 80),
        Size = UDim2.new(1, 0, 0, 28),
        Parent = toolbar,
    }, {
        list(Enum.FillDirection.Horizontal, 6),
    })

    for _, level in ipairs(LogOrder) do
        local style = LogLevels[level]
        local filter = button(filters, {
            BackgroundColor3 = style.Color,
            HoverColor = style.Color,
            PressColor = Theme.AccentHover,
            Size = UDim2.fromOffset(66, 28),
            Text = style.Label,
            TextColor3 = Theme.White,
            TextSize = 10,
        }, {
            corner(Radius.Sm),
        })

        filter.MouseButton1Click:Connect(function()
            self.LogFilters[level] = not self.LogFilters[level]
            local active = self.LogFilters[level] == true

            setButtonPalette(
                filter,
                active and style.Color or Theme.Surface,
                active and style.Color or Theme.CardHover,
                Theme.SurfaceLow,
                false
            )
            filter.BackgroundColor3 = active and style.Color or Theme.Surface
            filter.TextColor3 = active and Theme.White or Theme.TextFaint
            self:_refreshLogs()
        end)
    end

    local logList = scroll(page)
    logList.Position = UDim2.fromOffset(0, 128)
    logList.Size = UDim2.new(1, 0, 1, -128)
    self.LogList = logList

    search:GetPropertyChangedSignal("Text"):Connect(function()
        self.LogSearch = search.Text
        self:_refreshLogs()
    end)

    auto.MouseButton1Click:Connect(function()
        self.AutoScrollLogs = not self.AutoScrollLogs
        local active = self.AutoScrollLogs == true

        setButtonPalette(
            auto,
            active and Theme.Accent or Theme.Surface,
            active and Theme.AccentHover or Theme.CardHover,
            Theme.SurfaceLow,
            false
        )
        auto.BackgroundColor3 = active and Theme.Accent or Theme.Surface
        auto.TextColor3 = active and Theme.White or Theme.TextFaint
    end)

    copy.MouseButton1Click:Connect(function()
        self:CopyLatestLog()
    end)

    clear.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)
end

function Window:Log(level, message, meta)
    if self.Destroyed then
        return nil
    end

    level = string.lower(asString(level ~= nil and level or "info"))

    if not LogLevels[level] then
        level = "info"
    end

    local entry = {
        Level = level,
        Message = asString(message),
        Meta = meta,
        Time = os.date("%H:%M:%S"),
    }

    self.LogEntries[#self.LogEntries + 1] = entry

    if self.LogList then
        self:_logRow(entry)
    end

    while #self.LogEntries > self.MaxLogs do
        local removed = table.remove(self.LogEntries, 1)

        if removed and removed.Row then
            removed.Row:Destroy()
        end
    end

    self:_refreshLogs()
    return entry
end

function Window:Info(message, meta)
    return self:Log("info", message, meta)
end

function Window:Success(message, meta)
    return self:Log("success", message, meta)
end

function Window:Warn(message, meta)
    return self:Log("warn", message, meta)
end

function Window:Error(message, meta)
    return self:Log("error", message, meta)
end

function Window:Debug(message, meta)
    return self:Log("debug", message, meta)
end

function Window:ClearLogs()
    for _, entry in ipairs(self.LogEntries) do
        if entry.Row then
            entry.Row:Destroy()
        end
    end

    self.LogEntries = {}
end

function Window:CopyLatestLog()
    local entry = self.LogEntries[#self.LogEntries]

    if not entry then
        self:Warn("No log entry to copy")
        return false
    end

    local output = string.format("[%s] [%s] %s", entry.Time, string.upper(entry.Level), entry.Message)
    local meta = metaString(entry.Meta)

    if meta ~= "" then
        output = output .. " | " .. meta
    end

    if type(setclipboard) == "function" then
        setclipboard(output)
        self:Success("Latest log copied")
        return true
    end

    self:Warn("Clipboard API unavailable")
    return false
end

function Window:SetStatus(message, level)
    if self.Destroyed or not self.StatusLabel then
        return self
    end

    local style = LogLevels[string.lower(asString(level or "info"))] or LogLevels.info
    self.StatusLabel.Text = string.upper(asString(message ~= nil and message or "Ready"))
    self.StatusDot.BackgroundColor3 = style.Color
    self.StatusLabel.TextColor3 = style.Color
    return self
end

function Window:ShowLogs()
    if self.LogTab then
        self:SelectTab(self.LogTab)
    end

    return self
end

function Window:Notify(config)
    if self.Destroyed then
        return nil
    end

    config = config or {}
    local style = LogLevels[string.lower(config.Level or "info")] or LogLevels.info

    local card = create("CanvasGroup", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.NotificationHost,
    }, {
        corner(Radius.Lg),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(12, 10, 12, 10),
        list(Enum.FillDirection.Horizontal, 10),
    })

    create("Frame", {
        BackgroundColor3 = style.Color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(4, 44),
        Parent = card,
    }, {
        corner(4),
    })

    local stack = create("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -14, 0, 0),
        Parent = card,
    }, {
        list(Enum.FillDirection.Vertical, 4),
    })

    text(stack, merge(textBase(config.Title or self.Title, 13, Theme.Text, true), {
        Size = UDim2.new(1, 0, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    text(stack, merge(textBase(config.Content or "", 12, Theme.TextMuted), {
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        TextWrapped = true,
    }))

    tween(card, { GroupTransparency = 0 }, Motion.Base)

    task.delay(tonumber(config.Duration) or 3, function()
        if card and card.Parent then
            tween(card, { GroupTransparency = 1 }, Motion.Base)

            task.delay(Motion.Base + 0.05, function()
                if card and card.Parent then
                    card:Destroy()
                end
            end)
        end
    end)

    return card
end

function Window:SetMinimized(value)
    self.Minimized = value == true
    self.ContentPanel.Visible = not self.Minimized
    self.TabBar.Visible = not self.Minimized
    self.MinimizeButton.Text = self.Minimized and "+" or "-"

    tween(self.Root, {
        Size = self.Minimized and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 64) or self.Size,
    }, Motion.Base)

    return self
end

function Window:Toggle()
    self.Root.Visible = not self.Root.Visible
    return self
end

function Window:Destroy()
    if self.Destroyed then
        return
    end

    self.Destroyed = true
    self.Maid:Clean()

    if self.Gui then
        self.Gui:Destroy()
    end

    local state = getState()

    if state.ActiveWindow == self then
        state.ActiveWindow = nil
    end
end

function Window:_progress(progress, label, waitTime)
    if self.Destroyed or not self.LoadingOverlay then
        return
    end

    local target = clamp(progress or 0, 0, 1)
    local start = self.BootProgress or 0
    local duration = math.max(tonumber(waitTime) or 0.16, 0.04)
    local startedAt = os.clock()

    while true do
        if self.Destroyed or not self.LoadingOverlay then
            return
        end

        local alpha = clamp((os.clock() - startedAt) / duration, 0, 1)
        local current = start + (target - start) * alpha
        local percent = math.floor(current * 100 + 0.5)

        self.Console:Progress(current, label)
        self.LoadingStatus.Text = label or "Loading"
        self.LoadingPercent.Text = string.format("%03d/100", percent)
        self.LoadingFill.Size = UDim2.fromScale(current, 1)

        if alpha >= 1 then
            break
        end

        task.wait(0.035)
    end

    self.BootProgress = target
end

function Window:_finishBoot()
    if self.Destroyed or not self.LoadingOverlay then
        return
    end

    self.Console:Progress(1, "Ready", "done")
    self.LoadingStatus.Text = "Ready"
    self.LoadingPercent.Text = "100/100"
    self.LoadingFill.Size = UDim2.fromScale(1, 1)
    self:SetStatus("Ready", "success")

    tween(self.RootScale, { Scale = 1 }, Motion.Slow, Enum.EasingStyle.Back)

    task.delay(0.2, function()
        if self.Destroyed or not self.LoadingOverlay then
            return
        end

        tween(self.LoadingOverlay, {
            BackgroundTransparency = 1,
            GroupTransparency = 1,
        }, Motion.Base)

        task.delay(Motion.Base + 0.05, function()
            if self.LoadingOverlay then
                self.LoadingOverlay:Destroy()
                self.LoadingOverlay = nil
            end
        end)
    end)
end

local function loadingView(root)
    local overlay = create("CanvasGroup", {
        BackgroundColor3 = Theme.Shell,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 90,
        Parent = root,
    }, {
        corner(Radius.Xl),
    })

    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(430, 178),
        ZIndex = 91,
        Parent = overlay,
    }, {
        corner(Radius.Xl),
        stroke(Theme.Stroke, 0, 1),
        padding(20, 18, 20, 18),
    })

    text(card, merge(textBase("LARPTER Premium", 19, Theme.Text, true), {
        Size = UDim2.new(1, -112, 0, 24),
        ZIndex = 92,
    }))

    text(card, merge(textBase("building minimal interface", 12, Theme.TextMuted), {
        Position = UDim2.fromOffset(20, 43),
        Size = UDim2.new(1, -40, 0, 18),
        ZIndex = 92,
    }))

    local percent = text(card, merge(textBase("000/100", 20, Theme.Accent, true), {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -20, 0, 17),
        Size = UDim2.fromOffset(100, 28),
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 92,
    }))

    local status = text(card, merge(textBase("Starting", 13, Theme.TextMuted), {
        Position = UDim2.fromOffset(20, 80),
        Size = UDim2.new(1, -40, 0, 20),
        ZIndex = 92,
    }))

    local track = create("Frame", {
        BackgroundColor3 = Theme.SurfaceLow,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(20, 112),
        Size = UDim2.new(1, -40, 0, 10),
        ZIndex = 92,
        Parent = card,
    }, {
        corner(5),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.01, 1),
        ZIndex = 93,
        Parent = track,
    }, {
        corner(5),
    })

    text(card, merge(textBase("version " .. Larpter.Version .. " / log ready / duplicate guarded", 10, Theme.TextFaint, true), {
        Position = UDim2.fromOffset(20, 138),
        Size = UDim2.new(1, -40, 0, 16),
        ZIndex = 92,
    }))

    return {
        Overlay = overlay,
        Status = status,
        Percent = percent,
        Fill = fill,
    }
end

local function buildWindow(config)
    config = normalizeConfig(config)

    local parent = getGuiParent(config)
    assert(parent, "LARPTER Premium could not find a GUI parent")

    local gui = create("ScreenGui", {
        Name = config.Name or "LARPTERPremium",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })
    protectGui(gui, config.ProtectGui == true)

    local maid = Maid.new()
    local console = Console.new(config.ConsoleLoading)
    local size = config.Size or UDim2.fromOffset(780, 560)

    local root = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Shell,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        Parent = gui,
    }, {
        corner(Radius.Xl),
        stroke(Theme.Stroke, 0, 1),
    })

    local rootScale = create("UIScale", {
        Scale = 0.96,
        Parent = root,
    })

    local header = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 64),
        Parent = root,
    }, {
        corner(Radius.Xl),
    })

    local brand = create("Frame", {
        BackgroundColor3 = Theme.AccentSoft,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(16, 16),
        Size = UDim2.fromOffset(36, 36),
        Parent = header,
    }, {
        corner(Radius.Lg),
    })

    text(brand, merge(textBase("LP", 12, Theme.Accent, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local title = text(header, merge(textBase(config.Title or Larpter.Name, 18, Theme.Text, true), {
        Position = UDim2.fromOffset(64, 13),
        Size = UDim2.new(1, -390, 0, 24),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local subtitle = text(header, merge(textBase(config.Subtitle or "Minimal Roblox UI library", 12, Theme.TextMuted), {
        Position = UDim2.fromOffset(64, 38),
        Size = UDim2.new(1, -390, 0, 16),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local activeLabel = text(header, merge(textBase("ACTIVE", 11, Theme.Accent, true), {
        BackgroundColor3 = Theme.AccentSoft,
        BackgroundTransparency = 0,
        Position = UDim2.new(1, -250, 0, 17),
        Size = UDim2.fromOffset(134, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(15).Parent = activeLabel

    local statusBar = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -250, 0, 48),
        Size = UDim2.fromOffset(134, 10),
        Parent = header,
    }, {
        corner(5),
    })

    local statusDot = create("Frame", {
        BackgroundColor3 = Theme.Green,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 3),
        Size = UDim2.fromOffset(4, 4),
        Parent = statusBar,
    }, {
        corner(2),
    })

    local statusLabel = text(statusBar, merge(textBase("READY", 8, Theme.Green, true), {
        Position = UDim2.fromOffset(16, -1),
        Size = UDim2.new(1, -20, 1, 2),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local minimize = button(header, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Theme.CardHover,
        PressColor = Theme.SurfaceLow,
        Position = UDim2.new(1, -86, 0, 18),
        Size = UDim2.fromOffset(30, 28),
        Text = "-",
        TextColor3 = Theme.TextMuted,
        TextSize = 14,
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local close = button(header, {
        BackgroundColor3 = Theme.Surface,
        HoverColor = Color3.fromRGB(254, 226, 226),
        PressColor = Color3.fromRGB(254, 202, 202),
        Position = UDim2.new(1, -46, 0, 18),
        Size = UDim2.fromOffset(30, 28),
        Text = "X",
        TextColor3 = Theme.Red,
        TextSize = 12,
    }, {
        corner(Radius.Md),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local tabBar = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 76),
        Size = UDim2.new(1, -24, 0, 44),
        Parent = root,
    }, {
        corner(Radius.Lg),
        stroke(Theme.StrokeSoft, 0, 1),
        padding(6, 6, 6, 6),
    })

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = tabBar,
    }, {
        list(Enum.FillDirection.Horizontal, 6),
    })

    local contentPanel = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(12, 132),
        Size = UDim2.new(1, -24, 1, -144),
        Parent = root,
    }, {
        corner(Radius.Lg),
        stroke(Theme.StrokeSoft, 0, 1),
    })

    local pageHost = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 1, -20),
        Parent = contentPanel,
    })

    local notifications = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(330, 430),
        Parent = gui,
    }, {
        list(Enum.FillDirection.Vertical, 8),
    })
    notifications.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local loading = loadingView(root)

    local window = setmetatable({
        Gui = gui,
        Root = root,
        RootScale = rootScale,
        Header = header,
        TabBar = tabBar,
        TabList = tabList,
        ContentPanel = contentPanel,
        PageHost = pageHost,
        NotificationHost = notifications,
        LoadingOverlay = loading.Overlay,
        LoadingStatus = loading.Status,
        LoadingPercent = loading.Percent,
        LoadingFill = loading.Fill,
        MinimizeButton = minimize,
        CloseButton = close,
        ActiveLabel = activeLabel,
        StatusBar = statusBar,
        StatusDot = statusDot,
        StatusLabel = statusLabel,
        TitleLabel = title,
        SubtitleLabel = subtitle,
        Title = config.Title or Larpter.Name,
        Size = size,
        Console = console,
        Maid = maid,
        MinimizeKey = keyCode(config.MinimizeKey, Enum.KeyCode.RightControl),
        MaxLogs = tonumber(config.MaxLogs) or 250,
        BootProgress = 0,
        AutoScrollLogs = true,
        LogSearch = "",
        LogEntries = {},
        LogFilters = {},
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false,
        Minimized = false,
    }, Window)

    for _, level in ipairs(LogOrder) do
        window.LogFilters[level] = true
    end

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    local function drag(input)
        local delta = input.Position - dragStart
        root.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end

    maid:Add(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = root.Position

            local release
            release = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false

                    if release then
                        release:Disconnect()
                        release = nil
                    end
                end
            end)
        end
    end))

    maid:Add(header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    maid:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            drag(input)
        end
    end))

    maid:Add(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window.MinimizeKey then
            window:Toggle()
        end
    end))

    maid:Add(minimize.MouseButton1Click:Connect(function()
        window:SetMinimized(not window.Minimized)
    end))

    maid:Add(close.MouseButton1Click:Connect(function()
        window:Destroy()
    end))

    local minBootTime = tonumber(config.MinBootTime) or 1.8
    local startedAt = os.clock()

    window:_progress(0.08, "Resolving session", 0.18)
    window:_progress(0.22, "Creating shell", 0.22)
    window:_progress(0.38, "Preparing layout", 0.22)
    window:_progress(0.54, "Mounting log console", 0.22)
    window:_buildLogTab()
    window:_progress(0.74, "Binding interactions", 0.24)
    window:Info("LARPTER Premium initialized", {
        version = Larpter.Version,
        maxLogs = window.MaxLogs,
    })

    if config.SafeMode then
        window:Info("Safe mode active", {
            duplicateGuard = config.PreventDuplicate ~= false,
            guiParent = config.GuiParent or "Auto",
            console = config.ConsoleLoading or "developer",
        })
    end

    window:_progress(0.92, "Finalizing interface", 0.22)

    local remaining = minBootTime - (os.clock() - startedAt)
    if remaining > 0 then
        task.wait(remaining)
    end

    window:_finishBoot()
    return window
end

function Larpter:CreateWindow(config)
    config = normalizeConfig(config)
    applyTheme(config.Theme)

    local state = getState()
    local active = state.ActiveWindow
    local preventDuplicate = config.PreventDuplicate ~= false
    local console = Console.new(config.ConsoleLoading)

    if active and not active.Destroyed and active.Gui and active.Gui.Parent then
        if config.ForceReload == true then
            console:Progress(0.05, "Force reload", true)
            active:Destroy()
        elseif preventDuplicate then
            console:Progress(1, "Already loaded", true)
            active.Root.Visible = true

            if active.Minimized then
                active:SetMinimized(false)
            end

            active:Warn("Duplicate load blocked", {
                hint = "Set ForceReload = true to rebuild",
            })
            active:Notify({
                Title = "LARPTER Premium",
                Content = "UI is already loaded",
                Level = "warn",
            })

            return active
        end
    end

    local ok, window = pcall(buildWindow, config)

    if not ok then
        state.ActiveWindow = nil
        error(window, 2)
    end

    state.ActiveWindow = window
    return window
end

function Larpter:GetActiveWindow()
    local active = getState().ActiveWindow

    if active and not active.Destroyed and active.Gui and active.Gui.Parent then
        return active
    end

    return nil
end

function Larpter:IsLoaded()
    return self:GetActiveWindow() ~= nil
end

function Larpter:DestroyActive()
    local active = self:GetActiveWindow()

    if active then
        active:Destroy()
        return true
    end

    return false
end

function Larpter:SetTheme(theme)
    applyTheme(theme)
    return self
end

function Larpter:GetTheme()
    return merge({}, Theme)
end

function Larpter:CreateDemo(config)
    config = normalizeConfig(merge({
        Title = "LARPTER Premium",
        Subtitle = "Minimal UI library",
        MaxLogs = 250,
    }, config or {}))

    local window = self:CreateWindow(config)

    if window.__DemoMounted then
        return window
    end

    window.__DemoMounted = true

    local dashboard = window:AddTab({ Title = "Dashboard" })
    local overview = dashboard:AddSection({ Title = "Overview", Badge = "CORE" })
    overview:AddParagraph({
        Title = "Minimal rebuild",
        Content = "A clean UI foundation with readable colors, stable controls, duplicate protection, and a built-in log console.",
    })
    overview:AddDivider({ Title = "Runtime" })
    overview:AddParagraph({
        Title = "Console loading",
        Content = "Developer Console shows a numbered 001/100 to 100/100 boot sequence while the interface mounts.",
    })

    local actions = dashboard:AddSection({ Title = "Quick Actions", Badge = "DEMO" })
    actions:AddButton({
        Title = "Write success log",
        Description = "Adds a styled entry to Logs",
        Callback = function()
            window:SetStatus("Action complete", "success")
            window:Success("Demo action completed", { source = "button" })
            window:Notify({
                Title = "Action complete",
                Content = "A success log was added.",
                Level = "success",
            })
        end,
    })

    actions:AddButton({
        Title = "Open log console",
        Description = "Switches to the built-in viewer",
        ButtonText = "Logs",
        Callback = function()
            window:SetStatus("Viewing logs", "info")
            window:ShowLogs()
        end,
    })

    actions:AddToggle({
        Title = "Enable module",
        Description = "Smooth toggle with callback logging",
        Default = false,
        Callback = function(value)
            window:SetStatus(value and "Module enabled" or "Module disabled", value and "success" or "warn")
            window:Info("Module toggled", { enabled = value })
        end,
    })

    actions:AddSlider({
        Title = "Intensity",
        Description = "Responsive value control",
        Min = 0,
        Max = 100,
        Default = 42,
        Rounding = 0,
        Suffix = "%",
        Callback = function(value)
            window:Debug("Intensity changed", { value = value })
        end,
    })

    local controls = window:AddTab({ Title = "Controls" })
    local form = controls:AddSection({ Title = "Inputs", Badge = "FORM" })
    form:AddDropdown({
        Title = "Mode",
        Description = "Minimal dropdown menu",
        Values = { "Balanced", "Fast", "Safe" },
        Default = "Balanced",
        Callback = function(value)
            window:Info("Mode selected", { mode = value })
        end,
    })

    form:AddInput({
        Title = "Nickname",
        Description = "Text input with focus state",
        Placeholder = "Enter name",
        Callback = function(value)
            window:Info("Input changed", { value = value })
        end,
    })

    form:AddKeybind({
        Title = "Demo keybind",
        Description = "RightShift by default",
        Default = Enum.KeyCode.RightShift,
        Callback = function(value)
            window:Warn("Keybind triggered", { state = value })
        end,
    })

    window:SelectTab(dashboard)
    window:Success("Demo scaffold ready")
    return window
end

local env = getEnv()
env.LarpterPremium = Larpter

return Larpter
