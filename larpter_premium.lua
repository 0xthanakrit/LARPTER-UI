--[[
    LARPTER Premium UI Framework
    Version 5.0.0

    Production-oriented single-file Roblox UI framework:
    - Linoria-inspired compact control surface
    - deterministic cleanup
    - duplicate-load guard
    - boot overlay with real timing and motion
    - built-in log console
    - stable Fluent-like public API
]]

local Larpter = {
    Name = "LARPTER Premium",
    Version = "5.0.0",
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
        Shell = Color3.fromRGB(31, 34, 41),
        ShellTop = Color3.fromRGB(41, 45, 54),
        ShellBottom = Color3.fromRGB(25, 28, 34),
        Panel = Color3.fromRGB(35, 38, 46),
        PanelRaised = Color3.fromRGB(44, 48, 58),
        PanelSunken = Color3.fromRGB(27, 30, 36),
        Card = Color3.fromRGB(39, 43, 52),
        CardHover = Color3.fromRGB(50, 55, 66),
        Border = Color3.fromRGB(74, 80, 94),
        BorderSoft = Color3.fromRGB(55, 60, 72),
        BorderHot = Color3.fromRGB(117, 145, 255),
        Blue = Color3.fromRGB(92, 125, 255),
        BlueSoft = Color3.fromRGB(157, 177, 255),
        BlueDim = Color3.fromRGB(49, 69, 135),
        Mint = Color3.fromRGB(88, 212, 172),
        Gold = Color3.fromRGB(234, 184, 98),
        Rose = Color3.fromRGB(239, 93, 128),
        Text = Color3.fromRGB(236, 240, 248),
        TextMuted = Color3.fromRGB(196, 205, 222),
        TextFaint = Color3.fromRGB(139, 150, 171),
        BlackText = Color3.fromRGB(16, 19, 25),
        Red = Color3.fromRGB(239, 93, 128),
        Amber = Color3.fromRGB(234, 184, 98),
        Violet = Color3.fromRGB(172, 153, 255),
    },
    Radius = {
        Sm = 2,
        Md = 3,
        Lg = 4,
        Xl = 5,
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
        Font = Enum.Font.Code,
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
    local mode = "line"

    if option == false then
        mode = "silent"
    elseif option == "verbose" then
        mode = "verbose"
    elseif option == "compact" then
        mode = "compact"
    elseif option == "developer" or option == "devconsole" or option == "f9" then
        mode = "developer"
    elseif option == "silent" then
        mode = "silent"
    end

    return setmetatable({
        Mode = mode,
        HasLineConsole = type(rconsoleprint) == "function",
        Session = string.format("%04X", math.random(0, 65535)),
        StartedAt = os.clock(),
        LastLength = 0,
        LastBucket = nil,
        LastMessage = nil,
        PrintedStart = false,
        SpinnerIndex = 0,
    }, Console)
end

function Console:_bar(progress)
    local width = 22
    local filled = math.floor(progress * width + 0.5)
    return string.rep("#", filled) .. string.rep(".", width - filled)
end

function Console:_line(progress, message)
    self.SpinnerIndex = (self.SpinnerIndex % 4) + 1

    local spinner = ({ "-", "\\", "|", "/" })[self.SpinnerIndex]
    local percent = math.floor(progress * 100 + 0.5)
    local elapsed = os.clock() - self.StartedAt
    return string.format(
        "LARPTER BOOT %s  %s  [%s]  %3d%%  %-22s  %.1fs",
        self.Session,
        spinner,
        self:_bar(progress),
        percent,
        message or "Loading",
        elapsed
    )
end

function Console:_developerLine(progress, message)
    local percent = math.floor(progress * 100 + 0.5)
    return string.format(
        "[LARPTER] %3d%% [%s] %s",
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
        elseif not self.PrintedStart then
            self.PrintedStart = true
            print(line)
        elseif progress >= 1 or force then
            print(line)
        end

        return
    end

    if self.Mode == "developer" then
        if not self.PrintedStart then
            self.PrintedStart = true
            print(string.format("[LARPTER] boot session %s started", self.Session))
        end

        local bucket = math.floor(progress * 8)
        local shouldPrint = force or progress >= 1 or message ~= self.LastMessage or bucket ~= self.LastBucket

        if shouldPrint then
            print(self:_developerLine(progress, message))
            self.LastBucket = bucket
            self.LastMessage = message
        end

        if progress >= 1 or force == "done" then
            print(string.format("[LARPTER] ready in %.1fs", os.clock() - self.StartedAt))
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
        Size = UDim2.new(1, 0, 0, height or 54),
        Parent = section.Content,
    }, {
        corner(Tokens.Radius.Md),
    })

    local border = stroke(Tokens.Color.Border, 0.22, 1)
    border.Parent = root

    create("Frame", {
        BackgroundColor3 = Tokens.Color.BlueDim,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 9),
        Size = UDim2.new(0, 2, 1, -18),
        Parent = root,
    }, {
        corner(4),
    })

    local title = text(root, merge(textBase(config.Title or "Untitled", 12, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -178, 0, 17),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local desc = text(root, merge(textBase(config.Description or "", 11, Tokens.Color.TextMuted), {
        Position = UDim2.fromOffset(12, 27),
        Size = UDim2.new(1, -178, 0, 16),
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

    local item = component(self, config, 54)
    local busy = false

    local action = button(item.Root, {
        BackgroundColor3 = Tokens.Color.Blue,
        HoverColor = Tokens.Color.BlueSoft,
        PressColor = Tokens.Color.BorderHot,
        Text = string.upper(config.ButtonText or "Run"),
        TextColor3 = Tokens.Color.BlackText,
        TextSize = 11,
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -90, 0.5, -12),
        Size = UDim2.fromOffset(78, 24),
    }, {
        corner(Tokens.Radius.Md),
        gradient({ Tokens.Color.Blue, Tokens.Color.BlueSoft }, 0),
    })

    action.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        tween(action, { Size = UDim2.fromOffset(74, 22), Position = UDim2.new(1, -88, 0.5, -11) }, 0.08)
        safeCall(config.Callback or noop)

        task.delay(tonumber(config.Cooldown) or 0.18, function()
            if action and action.Parent then
                busy = false
                tween(action, { Size = UDim2.fromOffset(78, 24), Position = UDim2.new(1, -90, 0.5, -12) }, 0.12)
            end
        end)
    end)

    item.Button = action
    return item
end

function Section:AddToggle(config)
    config = config or {}

    local item = component(self, config, 54)
    local value = config.Default == true

    local track = button(item.Root, {
        BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.PanelRaised,
        HoverColor = value and Tokens.Color.BlueSoft or Tokens.Color.CardHover,
        PressColor = Tokens.Color.Blue,
        Position = UDim2.new(1, -56, 0.5, -10),
        Size = UDim2.fromOffset(44, 20),
    }, {
        corner(10),
        stroke(Tokens.Color.Border, 0.25, 1),
    })

    local knob = create("Frame", {
        BackgroundColor3 = Tokens.Color.Text,
        BorderSizePixel = 0,
        Position = value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(14, 14),
        Parent = track,
    }, {
        corner(7),
    })

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = nextValue == true
        tween(track, { BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.PanelRaised }, Tokens.Motion.Base)
        tween(knob, { Position = value and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) }, Tokens.Motion.Base)

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

    local item = component(self, config, 64)
    item.TitleLabel.Size = UDim2.new(1, -118, 0, 17)
    item.DescriptionLabel.Size = UDim2.new(1, -118, 0, 16)

    local valueLabel = text(item.Root, merge(textBase("", 11, Tokens.Color.BlueSoft, true), {
        Position = UDim2.new(1, -76, 0, 7),
        Size = UDim2.fromOffset(64, 17),
        TextXAlignment = Enum.TextXAlignment.Right,
    }))

    local track = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Animate = false,
        Position = UDim2.new(0, 12, 1, -18),
        Size = UDim2.new(1, -24, 0, 6),
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
        Size = UDim2.fromOffset(13, 13),
        Parent = track,
    }, {
        corner(7),
        stroke(Tokens.Color.Blue, 0, 1),
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

    local item = component(self, config, 54)
    item.Root.ClipsDescendants = true

    local display = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = asString(selected),
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.new(1, -142, 0.5, -12),
        Size = UDim2.fromOffset(130, 24),
    }, {
        corner(Tokens.Radius.Md),
        padding(7, 0, 22, 0),
    })

    local arrow = text(item.Root, merge(textBase("v", 12, Tokens.Color.TextMuted, true), {
        Position = UDim2.new(1, -31, 0.5, -9),
        Size = UDim2.fromOffset(14, 18),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local menu = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.fromOffset(12, 54),
        Size = UDim2.new(1, -24, 0, 0),
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
                Font = Enum.Font.Code,
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

        local menuHeight = opened and math.min(#values * 31 + 10, 160) or 0
        tween(item.Root, { Size = UDim2.new(1, 0, 0, opened and 62 + menuHeight or 54) }, Tokens.Motion.Base)
        tween(menu, { Size = UDim2.new(1, -24, 0, menuHeight) }, Tokens.Motion.Base)

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

    local item = component(self, config, 54)
    local value = asString(config.Default)

    local input = create("TextBox", {
        ClearTextOnFocus = false,
        Text = value,
        PlaceholderText = config.Placeholder or "Type...",
        TextColor3 = Tokens.Color.Text,
        PlaceholderColor3 = Tokens.Color.TextFaint,
        TextSize = 11,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -142, 0.5, -12),
        Size = UDim2.fromOffset(130, 24),
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

    local item = component(self, config, 54)
    local bind = keyCode(config.Default, Enum.KeyCode.RightShift)
    local mode = config.Mode or "Toggle"
    local listening = false
    local toggled = false

    local keyButton = button(item.Root, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = bind.Name,
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -126, 0.5, -12),
        Size = UDim2.fromOffset(114, 24),
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
    local config = type(title) == "table" and title or { Title = title }
    local sectionTitle = config.Title or config.Name or "Groupbox"
    local side = config.Side or self.NextSectionSide
    local parent = self.Page

    if not self.Full then
        if side == "Right" or side == 2 then
            parent = self.RightColumn
            self.NextSectionSide = "Left"
        else
            parent = self.LeftColumn
            self.NextSectionSide = "Right"
        end
    end

    local root = create("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = parent,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.08, 1),
        padding(10, 10, 10, 10),
        list(Enum.FillDirection.Vertical, 8),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        Parent = root,
    })

    text(header, merge(textBase(sectionTitle, 13, Tokens.Color.Text, true), {
        Size = UDim2.new(1, -90, 1, 0),
    }))

    text(header, merge(textBase(config.Badge or "LARPTER", 10, Tokens.Color.TextFaint, true), {
        Position = UDim2.new(1, -74, 0, 0),
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

    local target = clamp(progress or 0, 0, 1)
    local start = self.BootProgress or 0
    local duration = math.max(tonumber(waitTime) or 0.18, 0.05)
    local startedAt = os.clock()

    while true do
        if self.Destroyed or not self.LoadingOverlay then
            return
        end

        local alpha = clamp((os.clock() - startedAt) / duration, 0, 1)
        local current = start + (target - start) * alpha
        local percent = math.floor(current * 100 + 0.5)

        self.Console:Progress(current, label)
        self.LoadingStatus.Text = string.format("%s  %d%%", label or "Loading", percent)

        if self.LoadingPercent then
            self.LoadingPercent.Text = string.format("%d%%", percent)
        end

        if self.LoadingStage then
            self.LoadingStage.Text = current < 0.5 and "building runtime shell" or "binding interface modules"
        end

        self.LoadingFill.Size = UDim2.fromScale(current, 1)

        if alpha >= 1 then
            break
        end

        task.wait(0.04)
    end

    self.BootProgress = target
end

function Window:_finishBoot()
    if self.Destroyed or not self.LoadingOverlay then
        return
    end

    self.Console:Progress(1, "Ready", "done")
    self.LoadingStatus.Text = "Ready"
    if self.LoadingPercent then
        self.LoadingPercent.Text = "100%"
    end
    if self.LoadingStage then
        self.LoadingStage.Text = "ready"
    end
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

    local root = button(self.TabList, {
        BackgroundColor3 = Tokens.Color.Card,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(math.max(82, (#tab.Title * 8) + 22), 24),
        LayoutOrder = tab.Internal and 999 or visibleIndex,
    }, {
        corner(Tokens.Radius.Sm),
        stroke(Tokens.Color.BorderSoft, 0.15, 1),
    })

    local label = text(root, merge(textBase(tab.Title, 13, Tokens.Color.TextMuted, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    root.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button = root
    tab.Label = label
end

function Window:AddTab(config)
    config = config or {}

    local page = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = self.PageHost,
    })
    page.Visible = false
    page.Position = UDim2.fromOffset(12, 0)

    local leftColumn = nil
    local rightColumn = nil

    if config.Full ~= true then
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
        LeftColumn = leftColumn,
        RightColumn = rightColumn,
        NextSectionSide = "Left",
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
            BackgroundColor3 = selected and Tokens.Color.PanelRaised or Tokens.Color.Card,
        }, Tokens.Motion.Fast)

        item.Label.TextColor3 = selected and Tokens.Color.Text or Tokens.Color.TextMuted

        local border = item.Button:FindFirstChildOfClass("UIStroke")
        if border then
            tween(border, {
                Color = selected and Tokens.Color.BorderHot or Tokens.Color.BorderSoft,
                Transparency = selected and 0 or 0.25,
            }, Tokens.Motion.Fast)
        end
    end

    self.ActiveTab = tab
    self.ActiveLabel.Text = string.upper(tab.Title)
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
    local tab = self:AddTab({ Title = "Logs", Internal = true, Full = true })
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
        Font = Enum.Font.Code,
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
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -250, 0, 30),
        Size = UDim2.fromOffset(62, 32),
    }, { corner(Tokens.Radius.Md) })

    local copy = button(toolbar, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "COPY",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -180, 0, 30),
        Size = UDim2.fromOffset(78, 32),
    }, { corner(Tokens.Radius.Md) })

    local clear = button(toolbar, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "CLEAR",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.Code,
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
            Font = Enum.Font.Code,
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
    logList.Position = UDim2.fromOffset(0, 118)
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
    if self.Sidebar then
        self.Sidebar.Visible = not self.Minimized
    end
    self.MinimizeButton.Text = self.Minimized and "+" or "-"
    tween(self.Root, { Size = self.Minimized and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 54) or self.Size }, Tokens.Motion.Base)
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
        BackgroundColor3 = Tokens.Color.ShellBottom,
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

    create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(22, 18),
        Size = UDim2.new(1, -44, 0, 2),
        ZIndex = 91,
        Parent = overlay,
    }, {
        corner(2),
        gradient({ Tokens.Color.Violet, Tokens.Color.Blue, Tokens.Color.Gold }, 0),
    })

    local card = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(462, 194),
        ZIndex = 91,
        Parent = overlay,
    }, {
        corner(Tokens.Radius.Xl),
        stroke(Tokens.Color.BorderHot, 0.15, 1),
        gradient({ Color3.fromRGB(82, 88, 107), Tokens.Color.Panel }, 90),
    })

    local cardStroke = card:FindFirstChildOfClass("UIStroke")

    local cardScale = create("UIScale", {
        Scale = 1,
        Parent = card,
    })

    create("Frame", {
        BackgroundColor3 = Tokens.Color.Violet,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 18),
        Size = UDim2.new(0, 4, 1, -36),
        ZIndex = 92,
        Parent = card,
    }, {
        corner(4),
        gradient({ Tokens.Color.Violet, Tokens.Color.Blue, Tokens.Color.Gold }, 90),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(22, 18),
        Size = UDim2.new(1, -44, 0, 38),
        ZIndex = 92,
        Parent = card,
    })

    text(header, merge(textBase("LARPTER BOOTSTRAP", 16, Tokens.Color.Text, true), {
        Size = UDim2.new(1, -118, 0, 21),
        ZIndex = 93,
    }))

    text(header, merge(textBase("production runtime", 11, Tokens.Color.TextFaint, true), {
        Position = UDim2.fromOffset(0, 22),
        Size = UDim2.new(1, -118, 0, 16),
        ZIndex = 93,
    }))

    local percent = text(header, merge(textBase("0%", 26, Tokens.Color.BlueSoft, true), {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -42, 0, -2),
        Size = UDim2.fromOffset(82, 34),
        TextXAlignment = Enum.TextXAlignment.Right,
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
        Position = UDim2.fromOffset(22, 74),
        Size = UDim2.new(1, -44, 0, 20),
        ZIndex = 92,
    }))

    local stage = text(card, merge(textBase("mounting visual shell", 11, Tokens.Color.TextFaint, true), {
        Position = UDim2.fromOffset(22, 96),
        Size = UDim2.new(1, -44, 0, 18),
        ZIndex = 92,
    }))

    local track = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelSunken,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(22, 126),
        Size = UDim2.new(1, -44, 0, 10),
        ZIndex = 92,
        Parent = card,
    }, {
        corner(5),
        stroke(Tokens.Color.BorderSoft, 0.38, 1),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.03, 1),
        ZIndex = 93,
        Parent = track,
    }, {
        corner(5),
    })

    local fillGradient = gradient({ Tokens.Color.Violet, Tokens.Color.Blue, Tokens.Color.Gold }, 0)
    fillGradient.Offset = Vector2.new(-1, 0)
    fillGradient.Parent = fill

    text(card, merge(textBase("runtime " .. Larpter.Version .. " / duplicate guarded / log ready", 10, Tokens.Color.TextFaint, true), {
        Position = UDim2.fromOffset(22, 153),
        Size = UDim2.new(1, -44, 0, 16),
        ZIndex = 92,
    }))

    return {
        Overlay = overlay,
        Status = status,
        Percent = percent,
        Stage = stage,
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
    local size = config.Size or UDim2.fromOffset(650, 590)

    local root = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Shell,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.54),
        Size = size,
        Parent = gui,
    }, {
        corner(Tokens.Radius.Xl),
        stroke(Tokens.Color.BorderHot, 0.04, 1),
        gradient({ Tokens.Color.ShellTop, Tokens.Color.ShellBottom }, 90),
    })

    local rootScale = create("UIScale", {
        Scale = 0.92,
        Parent = root,
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 52),
        Parent = root,
    })

    create("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 0, 2),
        Parent = header,
    }, {
        corner(2),
        gradient({ Tokens.Color.Blue, Tokens.Color.Violet }, 0),
    })

    local brand = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(10, 13),
        Size = UDim2.fromOffset(28, 28),
        Parent = header,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.05, 1),
    })

    text(brand, merge(textBase("LP", 12, Tokens.Color.BlueSoft, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local title = text(header, merge(textBase(config.Title or Larpter.Name, 17, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(48, 9),
        Size = UDim2.new(1, -310, 0, 20),
    }))

    local subtitle = text(header, merge(textBase(config.Subtitle or "Linoria-style control surface", 11, Tokens.Color.TextFaint), {
        Position = UDim2.fromOffset(48, 28),
        Size = UDim2.new(1, -310, 0, 16),
    }))

    local activeLabel = text(header, merge(textBase("ACTIVE", 11, Tokens.Color.TextMuted, true), {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        BackgroundTransparency = 0.05,
        Position = UDim2.new(1, -214, 0, 12),
        Size = UDim2.fromOffset(112, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Tokens.Radius.Sm).Parent = activeLabel
    stroke(Tokens.Color.Border, 0.18, 1).Parent = activeLabel

    local statusBar = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelSunken,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -214, 0, 37),
        Size = UDim2.fromOffset(112, 11),
        Parent = header,
    }, {
        corner(Tokens.Radius.Sm),
        stroke(Tokens.Color.BorderSoft, 0.32, 1),
    })

    local statusDot = create("Frame", {
        BackgroundColor3 = Tokens.Color.Mint,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(6, 3),
        Size = UDim2.fromOffset(5, 5),
        Parent = statusBar,
    }, {
        corner(3),
    })

    local statusLabel = text(statusBar, merge(textBase("READY", 9, Tokens.Color.TextMuted, true), {
        Position = UDim2.fromOffset(15, -1),
        Size = UDim2.new(1, -18, 1, 2),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local minimize = button(header, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "-",
        TextColor3 = Tokens.Color.Text,
        TextSize = 14,
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -76, 0, 13),
        Size = UDim2.fromOffset(28, 24),
    }, { corner(Tokens.Radius.Md) })

    local close = button(header, {
        BackgroundColor3 = Tokens.Color.PanelRaised,
        Text = "X",
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.Code,
        Position = UDim2.new(1, -40, 0, 13),
        Size = UDim2.fromOffset(28, 24),
    }, { corner(Tokens.Radius.Md) })

    local tabBar = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelSunken,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 56),
        Size = UDim2.new(1, -16, 0, 32),
        Parent = root,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.BorderSoft, 0.18, 1),
        padding(5, 4, 5, 4),
    })

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = tabBar,
    }, {
        list(Enum.FillDirection.Horizontal, 5),
    })

    local contentPanel = create("Frame", {
        BackgroundColor3 = Tokens.Color.PanelSunken,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 94),
        Size = UDim2.new(1, -16, 1, -102),
        Parent = root,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Border, 0.14, 1),
    })

    local pageHost = create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 1, -16),
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
        Body = contentPanel,
        Sidebar = tabBar,
        ContentPanel = contentPanel,
        TabList = tabList,
        PageHost = pageHost,
        NotificationHost = notifications,
        LoadingOverlay = loading.Overlay,
        LoadingStatus = loading.Status,
        LoadingPercent = loading.Percent,
        LoadingStage = loading.Stage,
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

    local minBootTime = tonumber(config.MinBootTime) or 2.7
    local startedAt = os.clock()

    window:_progress(0.08, "Resolving session", 0.22)
    window:_progress(0.22, "Composing shell", 0.28)
    window:_progress(0.42, "Rendering controls", 0.32)
    window:_progress(0.58, "Mounting log console", 0.28)
    window:_buildLogTab()
    window:_progress(0.78, "Binding interactions", 0.32)
    window:Info("LARPTER Premium initialized", {
        version = Larpter.Version,
        maxLogs = window.MaxLogs,
    })
    window:_progress(0.92, "Finalizing motion", 0.28)

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
        Subtitle = "Linoria-inspired control surface",
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
        Title = "Linoria-inspired rebuild",
        Content = "Compact top tabs, two-column groupboxes, animated boot, duplicate guard, and a log-first workflow.",
    })
    overview:AddDivider({ Title = "Runtime" })
    overview:AddParagraph({
        Title = "Boot console",
        Content = "Executor consoles get a single-line animated boot. Roblox Developer Console fallback stays compact.",
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
