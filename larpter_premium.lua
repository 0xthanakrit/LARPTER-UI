--[[
    LARPTER Premium UI Framework
    Version 3.1.0

    Production-oriented single-file Roblox UI framework:
    - graphite / electric-blue design system
    - deterministic cleanup
    - duplicate-load guard
    - boot overlay with real timing and motion
    - built-in log console
    - stable Fluent-like public API
]]

local Larpter = {
    Name = "LARPTER Premium",
    Version = "3.1.0",
}

local STATE_KEY = "__LARPTER_PREMIUM_STATE"

local Services = setmetatable({}, {
    __index = function(self, name)
        local service = game:GetService(name)
        rawset(self, name, service)
        return service
    end,
})

local Players = Services.Players
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local RunService = Services.RunService

local LocalPlayer = Players.LocalPlayer

local Tokens = {
    Color = {
        Shell = Color3.fromRGB(52, 58, 70),
        ShellTop = Color3.fromRGB(64, 72, 86),
        ShellBottom = Color3.fromRGB(42, 48, 60),
        Panel = Color3.fromRGB(61, 69, 83),
        PanelRaised = Color3.fromRGB(72, 82, 99),
        PanelSunken = Color3.fromRGB(49, 56, 69),
        Card = Color3.fromRGB(67, 76, 93),
        CardHover = Color3.fromRGB(79, 91, 112),
        Border = Color3.fromRGB(105, 123, 151),
        BorderSoft = Color3.fromRGB(83, 98, 123),
        BorderHot = Color3.fromRGB(91, 157, 255),
        Blue = Color3.fromRGB(74, 149, 255),
        BlueSoft = Color3.fromRGB(156, 207, 255),
        BlueDim = Color3.fromRGB(54, 102, 170),
        Mint = Color3.fromRGB(91, 221, 183),
        Text = Color3.fromRGB(248, 250, 255),
        TextMuted = Color3.fromRGB(218, 226, 238),
        TextFaint = Color3.fromRGB(168, 181, 202),
        BlackText = Color3.fromRGB(14, 24, 38),
        Red = Color3.fromRGB(255, 84, 112),
        Amber = Color3.fromRGB(255, 193, 96),
        Violet = Color3.fromRGB(166, 185, 255),
    },
    Radius = {
        Sm = 6,
        Md = 9,
        Lg = 13,
        Xl = 18,
    },
    Motion = {
        Fast = 0.12,
        Base = 0.22,
        Slow = 0.38,
    },
}

local LogLevels = {
    info = { Label = "INFO", Color = Tokens.Color.Blue },
    success = { Label = "OK", Color = Tokens.Color.BlueSoft },
    warn = { Label = "WARN", Color = Tokens.Color.Amber },
    error = { Label = "ERR", Color = Tokens.Color.Red },
    debug = { Label = "DBG", Color = Tokens.Color.Violet },
}

local LogLevelOrder = { "info", "success", "warn", "error", "debug" }

local function syncLogLevelColors()
    LogLevels.info.Color = Tokens.Color.Blue
    LogLevels.success.Color = Tokens.Color.Mint
    LogLevels.warn.Color = Tokens.Color.Amber
    LogLevels.error.Color = Tokens.Color.Red
    LogLevels.debug.Color = Tokens.Color.Violet
end

syncLogLevelColors()

local function noop() end

local function applyTheme(theme)
    if type(theme) ~= "table" then
        return
    end

    for key, value in pairs(theme) do
        if Tokens.Color[key] ~= nil and typeof(value) == "Color3" then
            Tokens.Color[key] = value
        end
    end

    syncLogLevelColors()
end

local function getState()
    local env = _G

    if type(getgenv) == "function" then
        local ok, genv = pcall(getgenv)
        if ok and type(genv) == "table" then
            env = genv
        end
    end

    env[STATE_KEY] = env[STATE_KEY] or {}
    return env[STATE_KEY]
end

local function merge(base, patch)
    local out = {}

    for key, value in pairs(base or {}) do
        out[key] = value
    end

    for key, value in pairs(patch or {}) do
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

local function getGuiParent()
    if type(gethui) == "function" then
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

local function protectGui(gui)
    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    elseif type(protectgui) == "function" then
        pcall(protectgui, gui)
    end
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
        CornerRadius = UDim.new(0, radius or Tokens.Radius.Md),
    })
end

local function stroke(color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Tokens.Color.Border,
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

local function gradient(colors, rotation)
    local points = {}

    for index, color in ipairs(colors) do
        local alpha = (#colors == 1) and 0 or ((index - 1) / (#colors - 1))
        points[#points + 1] = ColorSequenceKeypoint.new(alpha, color)
    end

    return create("UIGradient", {
        Rotation = rotation or 0,
        Color = ColorSequence.new(points),
    })
end

local function textBase(text, size, color, bold)
    return {
        Text = text or "",
        TextSize = size or 13,
        TextColor3 = color or Tokens.Color.Text,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }
end

local function text(parent, props)
    return create("TextLabel", merge(textBase(), merge(props or {}, {
        Parent = parent,
    })))
end

local function tween(object, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or Tokens.Motion.Base,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )

    local created = TweenService:Create(object, info, props)
    created:Play()
    return created
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({
        Items = {},
    }, Maid)
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
    return setmetatable({
        Mode = option == false and "silent" or (option == "verbose" and "verbose" or (option == "compact" and "compact" or "line")),
        HasLineConsole = type(rconsoleprint) == "function",
        LastLength = 0,
        LastBucket = nil,
        LastMessage = nil,
    }, Console)
end

function Console:_line(progress, message)
    local width = 24
    local filled = math.floor(progress * width + 0.5)
    local empty = width - filled
    local percent = math.floor(progress * 100 + 0.5)
    local bar = string.rep("=", filled) .. string.rep("-", empty)
    return string.format("[LARPTER] [%s] %3d%%  %s", bar, percent, message or "Loading")
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
        elseif progress >= 1 or force then
            print(line)
        end

        return
    end

    if self.Mode == "compact" and not force then
        local bucket = math.floor(progress * 4)

        if bucket == self.LastBucket and message == self.LastMessage then
            return
        end

        self.LastBucket = bucket
    end

    self.LastMessage = message
    print(self:_line(progress, message))
end

local function button(parent, props, children)
    props = props or {}

    local animate = props.Animate ~= false
    local normal = props.BackgroundColor3
    local hover = props.HoverColor or Tokens.Color.CardHover
    local press = props.PressColor or Tokens.Color.Blue
    local instanceProps = merge({}, props)

    instanceProps.Animate = nil
    instanceProps.HoverColor = nil
    instanceProps.PressColor = nil

    local object = create("TextButton", merge({
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = parent,
    }, instanceProps), children)

    if animate then
        object.MouseEnter:Connect(function()
            if normal then
                tween(object, { BackgroundColor3 = hover }, Tokens.Motion.Fast)
            end
        end)

        object.MouseLeave:Connect(function()
            if normal then
                tween(object, { BackgroundColor3 = normal }, Tokens.Motion.Fast)
            end
        end)

        object.MouseButton1Down:Connect(function()
            if normal then
                tween(object, { BackgroundColor3 = press }, 0.08)
            end
        end)

        object.MouseButton1Up:Connect(function()
            if normal then
                tween(object, { BackgroundColor3 = hover }, 0.08)
            end
        end)
    end

    return object
end

local function scroll(parent)
    return create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Tokens.Color.BorderHot,
        Size = UDim2.fromScale(1, 1),
        Parent = parent,
    }, {
        padding(0, 0, 7, 0),
        list(Enum.FillDirection.Vertical, 12),
    })
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

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function component(section, config, height)
    config = config or {}

    local root = create("Frame", {
        Active = true,
        BackgroundColor3 = Tokens.Color.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 66),
        Parent = section.Content,
    }, {
        corner(Tokens.Radius.Md),
    })

    local border = stroke(Tokens.Color.Border, 0.22, 1)
    border.Parent = root

    create("Frame", {
        BackgroundColor3 = Tokens.Color.BlueDim,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.new(0, 3, 1, -24),
        Parent = root,
    }, {
        corner(4),
    })

    local title = text(root, merge(textBase(config.Title or "Untitled", 13, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(17, 11),
        Size = UDim2.new(1, -220, 0, 19),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local desc = text(root, merge(textBase(config.Description or "", 12, Tokens.Color.TextMuted), {
        Position = UDim2.fromOffset(17, 35),
        Size = UDim2.new(1, -220, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = config.Description ~= nil and config.Description ~= "",
    }))

    root.MouseEnter:Connect(function()
        tween(root, { BackgroundColor3 = Tokens.Color.CardHover }, Tokens.Motion.Fast)
        tween(border, { Color = Tokens.Color.BorderHot, Transparency = 0.08 }, Tokens.Motion.Fast)
    end)

    root.MouseLeave:Connect(function()
        tween(root, { BackgroundColor3 = Tokens.Color.Card }, Tokens.Motion.Fast)
        tween(border, { Color = Tokens.Color.Border, Transparency = 0.22 }, Tokens.Motion.Fast)
    end)

    local object = {
        Root = root,
        TitleLabel = title,
        DescriptionLabel = desc,
        Section = section,
    }

    function object:SetTitle(value)
        self.TitleLabel.Text = asString(value)
    end

    function object:SetDescription(value)
        value = asString(value)
        self.DescriptionLabel.Text = value
        self.DescriptionLabel.Visible = value ~= ""
    end

    function object:Destroy()
        self.Root:Destroy()
    end

    return object
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
        BackgroundColor3 = Tokens.Color.Card,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.Content,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Border, 0.22, 1),
        padding(14, 13, 14, 13),
        list(Enum.FillDirection.Vertical, 6),
    })

    local title = text(root, merge(textBase(config.Title or "Notice", 13, Tokens.Color.Text, true), {
        Size = UDim2.new(1, 0, 0, 18),
        TextWrapped = true,
    }))

    local body = text(root, merge(textBase(config.Content or config.Description or "", 12, Tokens.Color.TextMuted), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
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
        Size = UDim2.new(1, 0, 0, config.Title and 28 or 16),
        Parent = self.Content,
    })

    local line = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Tokens.Color.BorderSoft,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        Parent = root,
    })

    if config.Title then
        local label = text(root, merge(textBase(string.upper(config.Title), 10, Tokens.Color.TextFaint, true), {
            BackgroundColor3 = Tokens.Color.Panel,
            BackgroundTransparency = 0,
            Position = UDim2.fromOffset(12, 4),
            Size = UDim2.fromOffset(132, 20),
            TextXAlignment = Enum.TextXAlignment.Center,
        }))
        corner(10).Parent = label
        stroke(Tokens.Color.BorderSoft, 0.35, 1).Parent = label
    end

    local object = {
        Root = root,
        Line = line,
    }

    function object:Destroy()
        self.Root:Destroy()
    end

    return object
end

function Section:AddButton(config)
    config = config or {}

    local item = component(self, config, 66)
    local busy = false

    local action = button(item.Root, {
        BackgroundColor3 = Tokens.Color.Blue,
        HoverColor = Tokens.Color.BlueSoft,
        PressColor = Tokens.Color.BorderHot,
        Text = string.upper(config.ButtonText or "Run"),
        TextColor3 = Tokens.Color.BlackText,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -106, 0.5, -16),
        Size = UDim2.fromOffset(90, 32),
    }, {
        corner(Tokens.Radius.Md),
        gradient({ Tokens.Color.Blue, Tokens.Color.BlueSoft }, 0),
    })

    action.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        tween(action, { Size = UDim2.fromOffset(84, 30), Position = UDim2.new(1, -103, 0.5, -15) }, 0.08)
        safeCall(config.Callback or noop)

        task.delay(tonumber(config.Cooldown) or 0.18, function()
            if action and action.Parent then
                busy = false
                tween(action, { Size = UDim2.fromOffset(90, 32), Position = UDim2.new(1, -106, 0.5, -16) }, 0.12)
            end
        end)
    end)

    item.Button = action
    return item
end

function Section:AddToggle(config)
    config = config or {}

    local item = component(self, config, 66)
    local value = config.Default == true

    local track = button(item.Root, {
        BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.PanelRaised,
        HoverColor = value and Tokens.Color.BlueSoft or Tokens.Color.CardHover,
        PressColor = Tokens.Color.Blue,
        Position = UDim2.new(1, -68, 0.5, -14),
        Size = UDim2.fromOffset(52, 28),
    }, {
        corner(14),
        stroke(Tokens.Color.Border, 0.25, 1),
    })

    local knob = create("Frame", {
        BackgroundColor3 = Tokens.Color.Text,
        BorderSizePixel = 0,
        Position = value and UDim2.fromOffset(27, 4) or UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(20, 20),
        Parent = track,
    }, {
        corner(10),
    })

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = nextValue == true
        tween(track, { BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.PanelRaised }, Tokens.Motion.Base)
        tween(knob, { Position = value and UDim2.fromOffset(27, 4) or UDim2.fromOffset(4, 4) }, Tokens.Motion.Base)

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

    local item = component(self, config, 80)
    item.TitleLabel.Size = UDim2.new(1, -250, 0, 19)
    item.DescriptionLabel.Size = UDim2.new(1, -250, 0, 18)

    local valueLabel = text(item.Root, merge(textBase("", 12, Tokens.Color.BlueSoft, true), {
        Position = UDim2.new(1, -108, 0, 13),
        Size = UDim2.fromOffset(92, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
    }))

    local track = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Animate = false,
        Position = UDim2.new(0, 17, 1, -23),
        Size = UDim2.new(1, -34, 0, 8),
    }, {
        corner(4),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    }, {
        corner(4),
        gradient({ Tokens.Color.Blue, Tokens.Color.BlueSoft }, 0),
    })

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Text,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(17, 17),
        Parent = track,
    }, {
        corner(9),
        stroke(Tokens.Color.Blue, 0, 2),
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
    local buttons = {}

    local item = component(self, config, 66)
    item.Root.ClipsDescendants = true

    local display = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = asString(selected),
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(1, -194, 0, 17),
        Size = UDim2.fromOffset(178, 32),
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 28, 0),
    })

    local arrow = text(item.Root, merge(textBase("v", 12, Tokens.Color.TextMuted, true), {
        Position = UDim2.new(1, -44, 0, 23),
        Size = UDim2.fromOffset(18, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local menu = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(17, 66),
        Size = UDim2.new(1, -34, 0, 0),
        Visible = false,
        Parent = item.Root,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Border, 0.22, 1),
        padding(6, 6, 6, 6),
        list(Enum.FillDirection.Vertical, 5),
    })

    local function rebuild()
        for _, existing in ipairs(buttons) do
            existing:Destroy()
        end

        buttons = {}

        for _, option in ipairs(values) do
            local isSelected = option == selected
            local optionButton = button(menu, {
                BackgroundColor3 = isSelected and Tokens.Color.BlueDim or Tokens.Color.Panel,
                Text = asString(option),
                TextColor3 = isSelected and Tokens.Color.BlueSoft or Tokens.Color.Text,
                TextSize = 12,
                Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
            }, {
                corner(Tokens.Radius.Sm),
                padding(9, 0, 9, 0),
            })

            optionButton.MouseButton1Click:Connect(function()
                item:SetValue(option)
                item:SetOpen(false)
            end)

            buttons[#buttons + 1] = optionButton
        end
    end

    function item:SetOpen(nextOpen)
        opened = nextOpen == true
        menu.Visible = true
        arrow.Text = opened and "^" or "v"

        local menuHeight = opened and math.min(#values * 33 + 12, 178) or 0
        tween(item.Root, { Size = UDim2.new(1, 0, 0, opened and 76 + menuHeight or 66) }, Tokens.Motion.Base)
        tween(menu, { Size = UDim2.new(1, -34, 0, menuHeight) }, Tokens.Motion.Base)

        if not opened then
            task.delay(Tokens.Motion.Base, function()
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

    local item = component(self, config, 66)
    local value = asString(config.Default)

    local input = create("TextBox", {
        ClearTextOnFocus = false,
        Text = value,
        PlaceholderText = config.Placeholder or "Type...",
        TextColor3 = Tokens.Color.Text,
        PlaceholderColor3 = Tokens.Color.TextFaint,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -194, 0.5, -16),
        Size = UDim2.fromOffset(178, 32),
        Parent = item.Root,
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 10, 0),
        stroke(Tokens.Color.Border, 0.25, 1),
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
        tween(input, { BackgroundColor3 = Tokens.Color.CardHover }, Tokens.Motion.Fast)
    end)

    input.FocusLost:Connect(function()
        tween(input, { BackgroundColor3 = Tokens.Color.PanelRaised }, Tokens.Motion.Fast)
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

    local item = component(self, config, 66)
    local bind = keyCode(config.Default, Enum.KeyCode.RightShift)
    local mode = config.Mode or "Toggle"
    local listening = false
    local toggled = false

    local keyButton = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = bind.Name,
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -146, 0.5, -16),
        Size = UDim2.fromOffset(130, 32),
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Border, 0.25, 1),
    })

    local function setKey(nextKey)
        bind = nextKey
        keyButton.Text = bind.Name
        safeCall(config.ChangedCallback or noop, bind)
    end

    function item:GetValue()
        return bind
    end

    function item:SetValue(value)
        setKey(keyCode(value, bind))
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
    local root = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.Page,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.23, 1),
        padding(14, 14, 14, 14),
        list(Enum.FillDirection.Vertical, 11),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = root,
    })

    text(header, merge(textBase(string.upper(title or "Section"), 12, Tokens.Color.BlueSoft, true), {
        Size = UDim2.new(1, -90, 1, 0),
    }))

    text(header, merge(textBase("SYSTEM", 10, Tokens.Color.TextFaint, true), {
        Position = UDim2.new(1, -70, 0, 2),
        Size = UDim2.fromOffset(70, 20),
        TextXAlignment = Enum.TextXAlignment.Right,
    }))

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

function Window:_progress(progress, label, waitTime)
    if self.Destroyed or not self.LoadingOverlay then
        return
    end

    progress = clamp(progress or 0, 0, 1)
    self.Console:Progress(progress, label)
    self.LoadingStatus.Text = string.format("%s  %d%%", label or "Loading", math.floor(progress * 100 + 0.5))
    tween(self.LoadingFill, { Size = UDim2.fromScale(progress, 1) }, Tokens.Motion.Base)
    task.wait(waitTime or 0.18)
end

function Window:_finishBoot()
    if self.Destroyed or not self.LoadingOverlay then
        return
    end

    self.Console:Progress(1, "Ready", "done")
    self.LoadingStatus.Text = "Ready"
    self:SetStatus("Ready", "success")
    tween(self.LoadingFill, { Size = UDim2.fromScale(1, 1) }, Tokens.Motion.Base)
    tween(self.RootScale, { Scale = 1 }, Tokens.Motion.Slow, Enum.EasingStyle.Back)
    tween(self.Root, { Position = UDim2.fromScale(0.5, 0.5) }, Tokens.Motion.Slow)

    task.delay(0.22, function()
        if self.Destroyed or not self.LoadingOverlay then
            return
        end

        tween(self.LoadingOverlay, {
            BackgroundTransparency = 1,
            GroupTransparency = 1,
        }, Tokens.Motion.Base)

        task.delay(Tokens.Motion.Base + 0.05, function()
            if self.LoadingOverlay then
                self.LoadingOverlay:Destroy()
                self.LoadingOverlay = nil
            end
        end)
    end)
end

function Window:_tabButton(tab)
    local visibleIndex = 0

    for _, item in ipairs(self.Tabs) do
        if not item.Internal then
            visibleIndex = visibleIndex + 1
        end
    end

    local badgeText = tab.Internal and "LG" or string.format("%02d", visibleIndex)

    local root = button(self.TabList, {
        BackgroundColor3 = Tokens.Color.Card,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = tab.Internal and 999 or visibleIndex,
    }, {
        corner(Tokens.Radius.Md),
    })

    local rail = create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(3, 20),
        Parent = root,
    }, {
        corner(4),
    })

    local badge = text(root, merge(textBase(badgeText, 10, Tokens.Color.TextFaint, true), {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BackgroundTransparency = 0.12,
        Position = UDim2.fromOffset(11, 10),
        Size = UDim2.fromOffset(30, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Tokens.Radius.Sm).Parent = badge

    local label = text(root, merge(textBase(tab.Title, 13, Tokens.Color.TextMuted, true), {
        Position = UDim2.fromOffset(50, 0),
        Size = UDim2.new(1, -58, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    root.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button = root
    tab.Rail = rail
    tab.Badge = badge
    tab.Label = label
end

function Window:AddTab(config)
    config = config or {}

    local page = scroll(self.PageHost)
    page.Visible = false
    page.Position = UDim2.fromOffset(12, 0)

    local tab = setmetatable({
        Window = self,
        Title = config.Title or "Tab",
        Internal = config.Internal == true,
        Page = page,
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
        return
    end

    for _, item in ipairs(self.Tabs) do
        local selected = item == tab

        if selected then
            item.Page.Visible = true
            item.Page.Position = UDim2.fromOffset(12, 0)
            tween(item.Page, { Position = UDim2.fromOffset(0, 0) }, Tokens.Motion.Base)
        else
            item.Page.Visible = false
        end

        tween(item.Button, {
            BackgroundColor3 = selected and Tokens.Color.CardHover or Tokens.Color.Card,
            BackgroundTransparency = selected and 0.03 or 1,
        }, Tokens.Motion.Fast)
        tween(item.Rail, { BackgroundTransparency = selected and 0 or 1 }, Tokens.Motion.Fast)

        item.Label.TextColor3 = selected and Tokens.Color.Text or Tokens.Color.TextMuted
        item.Badge.TextColor3 = selected and Tokens.Color.BlackText or Tokens.Color.TextFaint
        item.Badge.BackgroundColor3 = selected and Tokens.Color.Blue or Tokens.Color.PanelRaised
    end

    self.ActiveTab = tab
    self.ActiveLabel.Text = "ACTIVE  " .. string.upper(tab.Title)
end

function Window:_logRow(entry)
    local style = LogLevels[entry.Level] or LogLevels.info

    local row = create("Frame", {
        BackgroundColor3 = Tokens.Color.Card,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.LogList,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Border, 0.25, 1),
        padding(11, 9, 11, 9),
        list(Enum.FillDirection.Vertical, 6),
    })

    local top = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = row,
    })

    local badge = text(top, merge(textBase(style.Label, 10, Tokens.Color.BlackText, true), {
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0,
        Position = UDim2.fromOffset(0, 1),
        Size = UDim2.fromOffset(58, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Tokens.Radius.Sm).Parent = badge

    text(top, merge(textBase(entry.Time, 11, Tokens.Color.TextFaint, true), {
        Position = UDim2.fromOffset(68, 0),
        Size = UDim2.fromOffset(90, 20),
    }))

    text(row, merge(textBase(entry.Message, 12, Tokens.Color.Text), {
        Font = Enum.Font.Code,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
    }))

    local meta = metaString(entry.Meta)
    text(row, merge(textBase(meta, 11, Tokens.Color.TextFaint), {
        Font = Enum.Font.Code,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
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
    local tab = self:AddTab({ Title = "Logs", Internal = true })
    self.LogTab = tab

    local toolbar = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 106),
        Parent = tab.Page,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.24, 1),
        padding(12, 12, 12, 12),
    })

    text(toolbar, merge(textBase("LOG CONSOLE", 12, Tokens.Color.BlueSoft, true), {
        Size = UDim2.new(1, -250, 0, 18),
    }))

    local search = create("TextBox", {
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search logs",
        TextColor3 = Tokens.Color.Text,
        PlaceholderColor3 = Tokens.Color.TextFaint,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, -250, 0, 32),
        Parent = toolbar,
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 10, 0),
        stroke(Tokens.Color.Border, 0.25, 1),
    })

    local auto = button(toolbar, {
        BackgroundColor3 = Tokens.Color.Blue,
        Text = "AUTO",
        TextColor3 = Tokens.Color.BlackText,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -250, 0, 30),
        Size = UDim2.fromOffset(62, 32),
    }, { corner(Tokens.Radius.Md) })

    local copy = button(toolbar, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "COPY",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -180, 0, 30),
        Size = UDim2.fromOffset(78, 32),
    }, { corner(Tokens.Radius.Md) })

    local clear = button(toolbar, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "CLEAR",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -94, 0, 30),
        Size = UDim2.fromOffset(94, 32),
    }, { corner(Tokens.Radius.Md) })

    local filters = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 70),
        Size = UDim2.new(1, 0, 0, 26),
        Parent = toolbar,
    }, {
        list(Enum.FillDirection.Horizontal, 6),
    })

    for _, level in ipairs(LogLevelOrder) do
        local style = LogLevels[level]
        local filter = button(filters, {
            BackgroundColor3 = style.Color,
            Text = style.Label,
            TextColor3 = Tokens.Color.BlackText,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Size = UDim2.fromOffset(58, 26),
        }, { corner(Tokens.Radius.Sm) })

        filter.MouseButton1Click:Connect(function()
            self.LogFilters[level] = not self.LogFilters[level]
            filter.BackgroundColor3 = self.LogFilters[level] and style.Color or Tokens.Color.PanelRaised
            filter.TextColor3 = self.LogFilters[level] and Tokens.Color.BlackText or Tokens.Color.TextFaint
            self:_refreshLogs()
        end)
    end

    local logList = scroll(tab.Page)
    logList.Size = UDim2.new(1, 0, 1, -118)
    self.LogList = logList

    search:GetPropertyChangedSignal("Text"):Connect(function()
        self.LogSearch = search.Text
        self:_refreshLogs()
    end)

    auto.MouseButton1Click:Connect(function()
        self.AutoScrollLogs = not self.AutoScrollLogs
        auto.BackgroundColor3 = self.AutoScrollLogs and Tokens.Color.Blue or Tokens.Color.PanelRaised
        auto.TextColor3 = self.AutoScrollLogs and Tokens.Color.BlackText or Tokens.Color.TextFaint
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
        return
    end

    local style = LogLevels[string.lower(asString(level or "info"))] or LogLevels.info
    self.StatusLabel.Text = string.upper(asString(message ~= nil and message or "Ready"))
    self.StatusDot.BackgroundColor3 = style.Color
    self.StatusLabel.TextColor3 = style.Color
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
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.NotificationHost,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.BorderHot, 0.25, 1),
        padding(12, 10, 12, 10),
        list(Enum.FillDirection.Horizontal, 9),
    })

    create("Frame", {
        BackgroundColor3 = style.Color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(3, 44),
        Parent = card,
    }, {
        corner(4),
    })

    local stack = create("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -12, 0, 0),
        Parent = card,
    }, {
        list(Enum.FillDirection.Vertical, 3),
    })

    text(stack, merge(textBase(config.Title or self.Title, 12, Tokens.Color.Text, true), {
        Size = UDim2.new(1, 0, 0, 16),
    }))

    text(stack, merge(textBase(config.Content or "", 12, Tokens.Color.TextMuted), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
    }))

    tween(card, { GroupTransparency = 0 }, Tokens.Motion.Base)

    task.delay(tonumber(config.Duration) or 3, function()
        if card and card.Parent then
            tween(card, { GroupTransparency = 1 }, Tokens.Motion.Base)

            task.delay(Tokens.Motion.Base + 0.05, function()
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
    self.Body.Visible = not self.Minimized
    self.MinimizeButton.Text = self.Minimized and "+" or "-"
    tween(self.Root, { Size = self.Minimized and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 84) or self.Size }, Tokens.Motion.Base)
end

function Window:Toggle()
    self.Root.Visible = not self.Root.Visible
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

local function loadingView(root)
    local overlay = create("CanvasGroup", {
        BackgroundColor3 = Tokens.Color.Shell,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 90,
        Parent = root,
    }, {
        corner(Tokens.Radius.Xl),
        gradient({ Tokens.Color.ShellTop, Tokens.Color.ShellBottom }, 90),
    })

    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(420, 170),
        ZIndex = 91,
        Parent = overlay,
    }, {
        corner(Tokens.Radius.Xl),
        padding(18, 16, 18, 16),
        list(Enum.FillDirection.Vertical, 9),
    })

    local cardStroke = stroke(Tokens.Color.BorderHot, 0.14, 1)
    cardStroke.Parent = card

    local cardScale = create("UIScale", {
        Scale = 1,
        Parent = card,
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 30),
        ZIndex = 92,
        Parent = card,
    })

    text(header, merge(textBase("LARPTER PREMIUM", 16, Tokens.Color.BlueSoft, true), {
        Size = UDim2.new(1, -44, 1, 0),
        ZIndex = 93,
    }))

    local spinner = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(30, 30),
        ZIndex = 93,
        Parent = header,
    })

    local dotPositions = {
        UDim2.new(0.5, -3, 0, 1),
        UDim2.new(1, -7, 0.5, -3),
        UDim2.new(0.5, -3, 1, -7),
        UDim2.new(0, 1, 0.5, -3),
    }

    for index, position in ipairs(dotPositions) do
        create("Frame", {
            BackgroundColor3 = index == 1 and Tokens.Color.BlueSoft or Tokens.Color.Blue,
            BackgroundTransparency = 0.04 + (index - 1) * 0.16,
            BorderSizePixel = 0,
            Position = position,
            Size = UDim2.fromOffset(6, 6),
            ZIndex = 94,
            Parent = spinner,
        }, {
            corner(3),
        })
    end

    local status = text(card, merge(textBase("Preparing interface", 12, Tokens.Color.TextMuted), {
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 92,
    }))

    local track = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 8),
        ZIndex = 92,
        Parent = card,
    }, {
        corner(4),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.03, 1),
        ZIndex = 93,
        Parent = track,
    }, {
        corner(4),
    })

    local fillGradient = gradient({ Tokens.Color.Blue, Tokens.Color.BlueSoft, Color3.fromRGB(71, 118, 255) }, 0)
    fillGradient.Offset = Vector2.new(-1, 0)
    fillGradient.Parent = fill

    text(card, merge(textBase("LARPTER RUNTIME  " .. Larpter.Version, 10, Tokens.Color.TextFaint, true), {
        Size = UDim2.new(1, 0, 0, 16),
        ZIndex = 92,
    }))

    return {
        Overlay = overlay,
        Status = status,
        Fill = fill,
        Spinner = spinner,
        FillGradient = fillGradient,
        Stroke = cardStroke,
        CardScale = cardScale,
    }
end

local function buildWindow(config)
    config = config or {}

    local parent = getGuiParent()
    assert(parent, "LARPTER Premium could not find a GUI parent")

    local gui = create("ScreenGui", {
        Name = config.Name or "LARPTERPremium",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })
    protectGui(gui)

    local maid = Maid.new()
    local console = Console.new(config.ConsoleLoading)
    local tabWidth = tonumber(config.TabWidth) or 190
    local size = config.Size or UDim2.fromOffset(820, 560)

    local root = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Shell,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.54),
        Size = size,
        Parent = gui,
    }, {
        corner(Tokens.Radius.Xl),
        stroke(Tokens.Color.BorderHot, 0.08, 1),
        gradient({ Tokens.Color.ShellTop, Tokens.Color.ShellBottom }, 90),
    })

    local rootScale = create("UIScale", {
        Scale = 0.92,
        Parent = root,
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 86),
        Parent = root,
    })

    create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -28, 0, 2),
        Parent = header,
    }, {
        corner(2),
        gradient({ Tokens.Color.Blue, Tokens.Color.BlueSoft, Color3.fromRGB(38, 79, 168) }, 0),
    })

    local brand = create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 20),
        Size = UDim2.fromOffset(44, 44),
        Parent = header,
    }, {
        corner(Tokens.Radius.Lg),
        gradient({ Tokens.Color.Blue, Color3.fromRGB(40, 86, 190) }, 45),
    })

    text(brand, merge(textBase("LP", 14, Tokens.Color.BlackText, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local title = text(header, merge(textBase(config.Title or Larpter.Name, 17, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(76, 17),
        Size = UDim2.new(1, -470, 0, 24),
    }))

    local subtitle = text(header, merge(textBase(config.Subtitle or "Production-grade control surface", 12, Tokens.Color.TextMuted), {
        Position = UDim2.fromOffset(76, 44),
        Size = UDim2.new(1, -470, 0, 18),
    }))

    local activeLabel = text(header, merge(textBase("ACTIVE", 11, Tokens.Color.TextMuted, true), {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BackgroundTransparency = 0.05,
        Position = UDim2.new(1, -324, 0, 27),
        Size = UDim2.fromOffset(184, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(15).Parent = activeLabel
    stroke(Tokens.Color.Border, 0.3, 1).Parent = activeLabel

    local statusBar = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelSunken,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -324, 0, 61),
        Size = UDim2.fromOffset(184, 17),
        Parent = header,
    }, {
        corner(9),
        stroke(Tokens.Color.BorderSoft, 0.38, 1),
    })

    local statusDot = create("Frame", {
        BackgroundColor3 = Tokens.Color.Mint,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.fromOffset(7, 7),
        Parent = statusBar,
    }, {
        corner(4),
    })

    local statusLabel = text(statusBar, merge(textBase("READY", 10, Tokens.Color.TextMuted, true), {
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -32, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local minimize = button(header, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "-",
        TextColor3 = Tokens.Color.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -92, 0, 27),
        Size = UDim2.fromOffset(34, 30),
    }, { corner(Tokens.Radius.Md) })

    local close = button(header, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "X",
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -48, 0, 27),
        Size = UDim2.fromOffset(34, 30),
    }, { corner(Tokens.Radius.Md) })

    local body = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 92),
        Size = UDim2.new(1, -28, 1, -106),
        Parent = root,
    })

    local sidebar = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, tabWidth, 1, 0),
        Parent = body,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.22, 1),
        padding(10, 10, 10, 10),
    })

    text(sidebar, merge(textBase("NAVIGATION", 10, Tokens.Color.TextFaint, true), {
        Size = UDim2.new(1, 0, 0, 18),
    }))

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 1, -54),
        Parent = sidebar,
    }, {
        list(Enum.FillDirection.Vertical, 7),
    })

    text(sidebar, merge(textBase("LARPTER UI  /  v" .. Larpter.Version, 10, Tokens.Color.TextFaint, true), {
        Position = UDim2.new(0, 0, 1, -22),
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local pageHost = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth + 14, 0, 0),
        Size = UDim2.new(1, -tabWidth - 14, 1, 0),
        Parent = body,
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
        Body = body,
        Sidebar = sidebar,
        TabList = tabList,
        PageHost = pageHost,
        NotificationHost = notifications,
        LoadingOverlay = loading.Overlay,
        LoadingStatus = loading.Status,
        LoadingFill = loading.Fill,
        LoadingSpinner = loading.Spinner,
        LoadingGradient = loading.FillGradient,
        LoadingStroke = loading.Stroke,
        LoadingCardScale = loading.CardScale,
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
        MinimizeKey = keyCode(config.MinimizeKey, Enum.KeyCode.LeftControl),
        Console = console,
        Maid = maid,
        MaxLogs = tonumber(config.MaxLogs) or 250,
        AutoScrollLogs = true,
        LogSearch = "",
        LogEntries = {},
        LogFilters = {},
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false,
        Minimized = false,
    }, Window)

    for _, level in ipairs(LogLevelOrder) do
        window.LogFilters[level] = true
    end

    local shimmer = TweenService:Create(
        window.LoadingGradient,
        TweenInfo.new(1.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
        { Offset = Vector2.new(1, 0) }
    )
    shimmer:Play()
    maid:Add(function()
        pcall(function()
            shimmer:Cancel()
        end)
    end)

    local pulse = TweenService:Create(
        window.LoadingStroke,
        TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Transparency = 0.44 }
    )
    pulse:Play()
    maid:Add(function()
        pcall(function()
            pulse:Cancel()
        end)
    end)

    local breathe = TweenService:Create(
        window.LoadingCardScale,
        TweenInfo.new(0.95, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { Scale = 1.025 }
    )
    breathe:Play()
    maid:Add(function()
        pcall(function()
            breathe:Cancel()
        end)
    end)

    local spinnerConnection
    spinnerConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if window.Destroyed or not window.LoadingOverlay or not window.LoadingSpinner.Parent then
            if spinnerConnection then
                spinnerConnection:Disconnect()
            end
            return
        end

        window.LoadingSpinner.Rotation = (window.LoadingSpinner.Rotation + deltaTime * 240) % 360
    end)
    maid:Add(spinnerConnection)

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

            local releaseConnection
            releaseConnection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false

                    if releaseConnection then
                        releaseConnection:Disconnect()
                        releaseConnection = nil
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

    local minBootTime = tonumber(config.MinBootTime) or 2
    local startedAt = os.clock()

    window:_progress(0.06, "Booting " .. Larpter.Name, 0.18)
    window:_progress(0.18, "Creating interface", 0.2)
    window:_progress(0.34, "Mounting shell", 0.2)
    window:_progress(0.54, "Preparing logs", 0.22)
    window:_buildLogTab()
    window:_progress(0.76, "Binding components", 0.2)
    window:Info("LARPTER Premium initialized", {
        version = Larpter.Version,
        maxLogs = window.MaxLogs,
    })
    window:_progress(0.9, "Finalizing motion", 0.18)

    local remaining = minBootTime - (os.clock() - startedAt)
    if remaining > 0 then
        task.wait(remaining)
    end

    window:_finishBoot()
    return window
end

function Larpter:CreateWindow(config)
    config = config or {}
    applyTheme(config.Theme)

    local state = getState()
    local active = state.ActiveWindow
    local preventDuplicate = config.PreventDuplicate ~= false
    local console = Console.new(config.ConsoleLoading)

    if active and not active.Destroyed and active.Gui and active.Gui.Parent then
        if config.ForceReload == true then
            console:Progress(0.06, "Force reload", true)
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
    return merge({}, Tokens.Color)
end

function Larpter:CreateDemo(config)
    config = merge({
        Title = "LARPTER Premium",
        Subtitle = "Production-grade Roblox control surface",
        MaxLogs = 200,
    }, config or {})

    local window = self:CreateWindow(config)

    if window.__DemoMounted then
        return window
    end

    window.__DemoMounted = true

    local dashboard = window:AddTab({ Title = "Dashboard" })
    local overview = dashboard:AddSection("Overview")
    overview:AddParagraph({
        Title = "Production rebuild",
        Content = "Graphite premium interface with cleaner runtime structure, animated boot, duplicate guard, and a log-first workflow.",
    })
    overview:AddDivider({ Title = "Runtime" })
    overview:AddParagraph({
        Title = "Theme system",
        Content = "Use Larpter:SetTheme({...}) or CreateWindow({ Theme = {...} }) before mounting custom surfaces.",
    })

    local actions = dashboard:AddSection("Quick Actions")
    actions:AddButton({
        Title = "Write success log",
        Description = "Adds a styled entry to the console",
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
        Description = "Switches to the built-in log viewer",
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
    local form = controls:AddSection("Inputs")
    form:AddDropdown({
        Title = "Mode",
        Description = "Styled dropdown menu",
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

if type(getgenv) == "function" then
    local ok, genv = pcall(getgenv)

    if ok and type(genv) == "table" then
        genv.LarpterPremium = Larpter
    end
end

return Larpter
