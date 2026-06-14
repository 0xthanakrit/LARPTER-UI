--[[
    LARPTER Premium UI
    Single-file Roblox UI framework with polished matte-black/blue styling,
    duplicate-load protection, smooth boot, and a built-in log console.
]]

local Larpter = {
    Name = "LARPTER Premium",
    Version = "2.0.0",
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

local LocalPlayer = Players.LocalPlayer

local Tokens = {
    Color = {
        Ink = Color3.fromRGB(3, 4, 7),
        Ink2 = Color3.fromRGB(6, 8, 13),
        Ink3 = Color3.fromRGB(10, 13, 21),
        Panel = Color3.fromRGB(12, 15, 23),
        Panel2 = Color3.fromRGB(16, 20, 30),
        Panel3 = Color3.fromRGB(22, 28, 41),
        Card = Color3.fromRGB(13, 16, 25),
        CardHover = Color3.fromRGB(20, 26, 39),
        Stroke = Color3.fromRGB(36, 49, 76),
        StrokeBright = Color3.fromRGB(62, 91, 145),
        Blue = Color3.fromRGB(45, 132, 255),
        Blue2 = Color3.fromRGB(122, 181, 255),
        Blue3 = Color3.fromRGB(18, 52, 104),
        Text = Color3.fromRGB(238, 244, 255),
        Text2 = Color3.fromRGB(148, 162, 185),
        Text3 = Color3.fromRGB(82, 96, 121),
        Red = Color3.fromRGB(255, 83, 112),
        Amber = Color3.fromRGB(255, 193, 93),
        Violet = Color3.fromRGB(137, 166, 255),
    },
    Radius = {
        Sm = 6,
        Md = 8,
        Lg = 12,
        Xl = 16,
    },
    Motion = {
        Fast = 0.12,
        Base = 0.2,
        Slow = 0.34,
    },
}

local Levels = {
    info = { Label = "INFO", Color = Tokens.Color.Blue },
    success = { Label = "OK", Color = Tokens.Color.Blue2 },
    warn = { Label = "WARN", Color = Tokens.Color.Amber },
    error = { Label = "ERR", Color = Tokens.Color.Red },
    debug = { Label = "DBG", Color = Tokens.Color.Violet },
}

local LevelOrder = { "info", "success", "warn", "error", "debug" }

local function getState()
    local env = _G

    if type(getgenv) == "function" then
        local ok, genv = pcall(getgenv)
        if ok and type(genv) == "table" then
            env = genv
        end
    end

    env[STATE_KEY] = env[STATE_KEY] or {
        ActiveWindow = nil,
    }

    return env[STATE_KEY]
end

local function noop() end

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

local function tween(object, props, duration, style, direction)
    local info = TweenInfo.new(
        duration or Tokens.Motion.Base,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local instance = TweenService:Create(object, info, props)
    instance:Play()
    return instance
end

local function new(className, props, children)
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
    return new("UICorner", {
        CornerRadius = UDim.new(0, radius or Tokens.Radius.Md),
    })
end

local function stroke(color, transparency, thickness)
    return new("UIStroke", {
        Color = color or Tokens.Color.Stroke,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
    })
end

local function padding(left, top, right, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
    })
end

local function list(direction, gap)
    return new("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, gap or 8),
    })
end

local function gradient(a, b, c)
    local points = {
        ColorSequenceKeypoint.new(0, a),
        ColorSequenceKeypoint.new(1, b),
    }

    if c then
        points = {
            ColorSequenceKeypoint.new(0, a),
            ColorSequenceKeypoint.new(0.58, b),
            ColorSequenceKeypoint.new(1, c),
        }
    end

    return new("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new(points),
    })
end

local function textProps(text, size, color, bold)
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

local function makeText(parent, props)
    return new("TextLabel", merge(textProps(), merge(props, {
        Parent = parent,
    })))
end

local function makeButton(parent, props, children)
    return new("TextButton", merge({
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        Parent = parent,
    }, props or {}), children)
end

local function makeScroll(parent)
    local scroll = new("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Tokens.Color.StrokeBright,
        Size = UDim2.fromScale(1, 1),
        Parent = parent,
    }, {
        padding(0, 0, 6, 0),
        list(Enum.FillDirection.Vertical, 12),
    })

    return scroll
end

local function normalizeKeyCode(value, fallback)
    fallback = fallback or Enum.KeyCode.RightShift

    if typeof(value) == "EnumItem" then
        return value
    end

    if type(value) == "string" then
        local ok, keyCode = pcall(function()
            return Enum.KeyCode[value]
        end)

        if ok and keyCode then
            return keyCode
        end
    end

    return fallback
end

local function getParent()
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

local function protect(gui)
    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        pcall(syn.protect_gui, gui)
    elseif type(protectgui) == "function" then
        pcall(protectgui, gui)
    end
end

local function formatMeta(meta)
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

local Bin = {}
Bin.__index = Bin

function Bin.new()
    return setmetatable({
        Items = {},
    }, Bin)
end

function Bin:Add(item)
    self.Items[#self.Items + 1] = item
    return item
end

function Bin:Clean()
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

local function hoverable(frame, normal, hover, border)
    local borderStroke = border

    frame.MouseEnter:Connect(function()
        tween(frame, {
            BackgroundColor3 = hover,
        }, Tokens.Motion.Fast)

        if borderStroke then
            tween(borderStroke, {
                Color = Tokens.Color.StrokeBright,
                Transparency = 0.1,
            }, Tokens.Motion.Fast)
        end
    end)

    frame.MouseLeave:Connect(function()
        tween(frame, {
            BackgroundColor3 = normal,
        }, Tokens.Motion.Fast)

        if borderStroke then
            tween(borderStroke, {
                Color = Tokens.Color.Stroke,
                Transparency = 0.24,
            }, Tokens.Motion.Fast)
        end
    end)
end

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

local Section = {}
Section.__index = Section

local function componentShell(section, config, height)
    config = config or {}

    local root = new("Frame", {
        Active = true,
        BackgroundColor3 = Tokens.Color.Card,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height or 64),
        Parent = section.Content,
    }, {
        corner(Tokens.Radius.Md),
    })

    local rootStroke = stroke(Tokens.Color.Stroke, 0.24, 1)
    rootStroke.Parent = root
    hoverable(root, Tokens.Color.Card, Tokens.Color.CardHover, rootStroke)

    new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue3,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.new(0, 3, 1, -24),
        Parent = root,
    }, {
        corner(4),
    })

    local title = makeText(root, merge(textProps(config.Title or "Untitled", 13, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(17, 11),
        Size = UDim2.new(1, -210, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    local description = makeText(root, merge(textProps(config.Description or "", 12, Tokens.Color.Text2), {
        Position = UDim2.fromOffset(17, 34),
        Size = UDim2.new(1, -210, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = config.Description ~= nil and config.Description ~= "",
    }))

    local object = {
        Root = root,
        TitleLabel = title,
        DescriptionLabel = description,
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

    local root = new("Frame", {
        BackgroundColor3 = Tokens.Color.Card,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.Content,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Stroke, 0.25, 1),
        padding(14, 13, 14, 13),
        list(Enum.FillDirection.Vertical, 6),
    })

    local title = makeText(root, merge(textProps(config.Title or "Notice", 13, Tokens.Color.Text, true), {
        Size = UDim2.new(1, 0, 0, 18),
        TextWrapped = true,
    }))

    local body = makeText(root, merge(textProps(config.Content or config.Description or "", 12, Tokens.Color.Text2), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
    }))

    local object = { Root = root, TitleLabel = title, ContentLabel = body }

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

function Section:AddButton(config)
    config = config or {}

    local item = componentShell(self, config, 64)
    local busy = false

    local button = makeButton(item.Root, {
        BackgroundColor3 = Tokens.Color.Blue,
        Text = string.upper(config.ButtonText or "Run"),
        TextColor3 = Tokens.Color.Ink,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(86, 32),
        Position = UDim2.new(1, -102, 0.5, -16),
    }, {
        corner(Tokens.Radius.Md),
        gradient(Tokens.Color.Blue, Tokens.Color.Blue2),
    })

    button.MouseButton1Click:Connect(function()
        if busy then
            return
        end

        busy = true
        tween(button, { Size = UDim2.fromOffset(82, 30), Position = UDim2.new(1, -100, 0.5, -15) }, 0.08)
        safeCall(config.Callback or noop)

        task.delay(tonumber(config.Cooldown) or 0.18, function()
            if button and button.Parent then
                busy = false
                tween(button, { Size = UDim2.fromOffset(86, 32), Position = UDim2.new(1, -102, 0.5, -16) }, 0.12)
            end
        end)
    end)

    item.Button = button
    return item
end

function Section:AddToggle(config)
    config = config or {}

    local item = componentShell(self, config, 64)
    local value = config.Default == true

    local track = makeButton(item.Root, {
        BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.Panel3,
        Size = UDim2.fromOffset(50, 26),
        Position = UDim2.new(1, -66, 0.5, -13),
    }, {
        corner(13),
        stroke(Tokens.Color.Stroke, 0.3, 1),
    })

    local knob = new("Frame", {
        BackgroundColor3 = Tokens.Color.Text,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(20, 20),
        Position = value and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3),
        Parent = track,
    }, {
        corner(10),
    })

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = nextValue == true
        tween(track, { BackgroundColor3 = value and Tokens.Color.Blue or Tokens.Color.Panel3 }, Tokens.Motion.Base)
        tween(knob, { Position = value and UDim2.fromOffset(27, 3) or UDim2.fromOffset(3, 3) }, Tokens.Motion.Base)

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

    local minValue = tonumber(config.Min) or 0
    local maxValue = tonumber(config.Max) or 100
    local decimals = tonumber(config.Rounding) or 0
    local suffix = config.Suffix or ""
    local value = clamp(tonumber(config.Default) or minValue, minValue, maxValue)

    local item = componentShell(self, config, 78)
    item.TitleLabel.Size = UDim2.new(1, -240, 0, 18)
    item.DescriptionLabel.Size = UDim2.new(1, -240, 0, 18)

    local valueLabel = makeText(item.Root, merge(textProps("", 12, Tokens.Color.Blue2, true), {
        Position = UDim2.new(1, -104, 0, 12),
        Size = UDim2.fromOffset(88, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
    }))

    local track = makeButton(item.Root, {
        BackgroundColor3 = Tokens.Color.Panel3,
        Size = UDim2.new(1, -34, 0, 8),
        Position = UDim2.new(0, 17, 1, -22),
    }, {
        corner(4),
    })

    local fill = new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1),
        Parent = track,
    }, {
        corner(4),
        gradient(Tokens.Color.Blue, Tokens.Color.Blue2),
    })

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Text,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromScale(0, 0.5),
        Parent = track,
    }, {
        corner(8),
        stroke(Tokens.Color.Blue, 0, 2),
    })

    local dragging = false

    local function alphaFromValue(nextValue)
        if minValue == maxValue then
            return 0
        end

        return clamp((nextValue - minValue) / (maxValue - minValue), 0, 1)
    end

    local function redraw()
        local alpha = alphaFromValue(value)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = tostring(value) .. suffix
    end

    local function setFromX(x)
        local alpha = clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        item:SetValue(minValue + (maxValue - minValue) * alpha)
    end

    function item:GetValue()
        return value
    end

    function item:SetValue(nextValue, silent)
        value = clamp(round(tonumber(nextValue) or minValue, decimals), minValue, maxValue)
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

    self.Window.Bin:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end))

    self.Window.Bin:Add(UserInputService.InputEnded:Connect(function(input)
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

    local item = componentShell(self, config, 64)
    item.Root.ClipsDescendants = true

    local display = makeButton(item.Root, {
        BackgroundColor3 = Tokens.Color.Panel3,
        Text = asString(selected),
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.fromOffset(170, 32),
        Position = UDim2.new(1, -186, 0, 16),
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 28, 0),
    })

    local arrow = makeText(item.Root, merge(textProps("v", 12, Tokens.Color.Text2, true), {
        Size = UDim2.fromOffset(18, 20),
        Position = UDim2.new(1, -42, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local menu = new("Frame", {
        BackgroundColor3 = Tokens.Color.Panel2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, -34, 0, 0),
        Position = UDim2.fromOffset(17, 64),
        Visible = false,
        Parent = item.Root,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Stroke, 0.25, 1),
        padding(6, 6, 6, 6),
        list(Enum.FillDirection.Vertical, 5),
    })

    local function rebuild()
        for _, button in ipairs(optionButtons) do
            button:Destroy()
        end

        optionButtons = {}

        for _, optionValue in ipairs(values) do
            local isSelected = optionValue == selected
            local button = makeButton(menu, {
                BackgroundColor3 = isSelected and Tokens.Color.Blue3 or Tokens.Color.Panel2,
                Text = asString(optionValue),
                TextColor3 = isSelected and Tokens.Color.Blue2 or Tokens.Color.Text,
                TextSize = 12,
                Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Size = UDim2.new(1, 0, 0, 28),
            }, {
                corner(Tokens.Radius.Sm),
                padding(9, 0, 9, 0),
            })

            button.MouseButton1Click:Connect(function()
                item:SetValue(optionValue)
                item:SetOpen(false)
            end)

            optionButtons[#optionButtons + 1] = button
        end
    end

    function item:SetOpen(nextOpen)
        opened = nextOpen == true
        menu.Visible = true
        arrow.Text = opened and "^" or "v"

        local menuHeight = opened and math.min(#values * 33 + 12, 178) or 0
        tween(item.Root, { Size = UDim2.new(1, 0, 0, opened and 74 + menuHeight or 64) }, Tokens.Motion.Base)
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

    local item = componentShell(self, config, 64)
    local value = asString(config.Default)

    local input = new("TextBox", {
        ClearTextOnFocus = false,
        Text = value,
        PlaceholderText = config.Placeholder or "Type...",
        TextColor3 = Tokens.Color.Text,
        PlaceholderColor3 = Tokens.Color.Text3,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Tokens.Color.Panel3,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(174, 32),
        Position = UDim2.new(1, -190, 0.5, -16),
        Parent = item.Root,
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 10, 0),
        stroke(Tokens.Color.Stroke, 0.25, 1),
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
        tween(input, { BackgroundColor3 = Tokens.Color.Panel3 }, Tokens.Motion.Fast)
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

    local item = componentShell(self, config, 64)
    local keyCode = normalizeKeyCode(config.Default, Enum.KeyCode.RightShift)
    local mode = config.Mode or "Toggle"
    local listening = false
    local toggled = false

    local button = makeButton(item.Root, {
        BackgroundColor3 = Tokens.Color.Panel3,
        Text = keyCode.Name,
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(124, 32),
        Position = UDim2.new(1, -140, 0.5, -16),
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Stroke, 0.25, 1),
    })

    local function setKey(nextKey)
        keyCode = nextKey
        button.Text = keyCode.Name
        safeCall(config.ChangedCallback or noop, keyCode)
    end

    function item:GetValue()
        return keyCode
    end

    function item:SetValue(nextValue)
        setKey(normalizeKeyCode(nextValue, keyCode))
    end

    button.MouseButton1Click:Connect(function()
        listening = true
        button.Text = "Press key"
    end)

    self.Window.Bin:Add(UserInputService.InputBegan:Connect(function(input, processed)
        if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if listening then
            listening = false
            setKey(input.KeyCode)
            return
        end

        if input.KeyCode == keyCode then
            if mode == "Hold" then
                safeCall(config.Callback or noop, true)
            else
                toggled = not toggled
                safeCall(config.Callback or noop, toggled)
            end
        end
    end))

    self.Window.Bin:Add(UserInputService.InputEnded:Connect(function(input)
        if mode == "Hold" and input.KeyCode == keyCode then
            safeCall(config.Callback or noop, false)
        end
    end))

    item.Button = button
    return item
end

function Tab:AddSection(title)
    local root = new("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.Page,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Stroke, 0.28, 1),
        padding(13, 13, 13, 13),
        list(Enum.FillDirection.Vertical, 11),
    })

    local header = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Parent = root,
    })

    makeText(header, merge(textProps(string.upper(title or "Section"), 12, Tokens.Color.Blue2, true), {
        Size = UDim2.new(1, -90, 1, 0),
    }))

    makeText(header, merge(textProps("SYSTEM", 10, Tokens.Color.Text3, true), {
        Size = UDim2.fromOffset(70, 20),
        Position = UDim2.new(1, -70, 0, 2),
        TextXAlignment = Enum.TextXAlignment.Right,
    }))

    local section = setmetatable({
        Window = self.Window,
        Tab = self,
        Root = root,
        Content = root,
    }, Section)

    return section
end

for _, methodName in ipairs({
    "AddParagraph",
    "AddButton",
    "AddToggle",
    "AddSlider",
    "AddDropdown",
    "AddInput",
    "AddKeybind",
}) do
    Tab[methodName] = function(self, ...)
        return Section[methodName](resolveSection(self), ...)
    end
end

function Window:_setLoading(progress, message)
    if self.Destroyed or not self.Loading then
        return
    end

    progress = clamp(progress or 0, 0, 1)

    if message then
        self.LoadingStatus.Text = message
    end

    tween(self.LoadingFill, { Size = UDim2.fromScale(progress, 1) }, Tokens.Motion.Base)
end

function Window:_finishLoading()
    if self.Destroyed or not self.Loading then
        return
    end

    self:_setLoading(1, "Ready")
    tween(self.Scale, { Scale = 1 }, Tokens.Motion.Slow, Enum.EasingStyle.Back)
    tween(self.Root, { GroupTransparency = 0 }, Tokens.Motion.Slow)

    task.delay(0.28, function()
        if self.Destroyed or not self.Loading then
            return
        end

        tween(self.Loading, { GroupTransparency = 1 }, Tokens.Motion.Base)

        task.delay(0.24, function()
            if self.Loading then
                self.Loading:Destroy()
                self.Loading = nil
            end
        end)
    end)
end

function Window:_makeTabButton(tab)
    local visibleIndex = 0

    for _, item in ipairs(self.Tabs) do
        if not item.Internal then
            visibleIndex = visibleIndex + 1
        end
    end

    local badgeText = tab.Internal and "LG" or string.format("%02d", visibleIndex)

    local button = makeButton(self.TabList, {
        BackgroundColor3 = Tokens.Color.Card,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 44),
        LayoutOrder = tab.Internal and 999 or visibleIndex,
    }, {
        corner(Tokens.Radius.Md),
    })

    local rail = new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 12),
        Size = UDim2.fromOffset(3, 20),
        Parent = button,
    }, {
        corner(4),
    })

    local badge = makeText(button, merge(textProps(badgeText, 10, Tokens.Color.Text3, true), {
        BackgroundColor3 = Tokens.Color.Panel2,
        BackgroundTransparency = 0.2,
        Position = UDim2.fromOffset(11, 10),
        Size = UDim2.fromOffset(30, 24),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Tokens.Radius.Sm).Parent = badge

    local label = makeText(button, merge(textProps(tab.Title, 13, Tokens.Color.Text2, true), {
        Position = UDim2.fromOffset(50, 0),
        Size = UDim2.new(1, -58, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
    }))

    button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, { BackgroundTransparency = 0.3 }, Tokens.Motion.Fast)
        end
    end)

    button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, { BackgroundTransparency = 1 }, Tokens.Motion.Fast)
        end
    end)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button = button
    tab.Badge = badge
    tab.Rail = rail
    tab.Label = label
end

function Window:AddTab(config)
    config = config or {}

    local page = makeScroll(self.PageHost)
    page.Visible = false
    page.Position = UDim2.fromOffset(10, 0)

    local tab = setmetatable({
        Window = self,
        Title = config.Title or "Tab",
        Internal = config.Internal == true,
        Page = page,
        DefaultSection = nil,
    }, Tab)

    self.Tabs[#self.Tabs + 1] = tab
    self:_makeTabButton(tab)

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
            item.Page.Position = UDim2.fromOffset(10, 0)
            tween(item.Page, { Position = UDim2.fromOffset(0, 0) }, Tokens.Motion.Base)
        else
            item.Page.Visible = false
        end

        tween(item.Button, {
            BackgroundColor3 = selected and Tokens.Color.CardHover or Tokens.Color.Card,
            BackgroundTransparency = selected and 0.02 or 1,
        }, Tokens.Motion.Fast)
        tween(item.Rail, { BackgroundTransparency = selected and 0 or 1 }, Tokens.Motion.Fast)

        item.Label.TextColor3 = selected and Tokens.Color.Text or Tokens.Color.Text2
        item.Badge.TextColor3 = selected and Tokens.Color.Ink or Tokens.Color.Text3
        item.Badge.BackgroundColor3 = selected and Tokens.Color.Blue or Tokens.Color.Panel2
        item.Badge.BackgroundTransparency = selected and 0 or 0.2
    end

    self.ActiveTab = tab
    self.ActiveLabel.Text = "ACTIVE  " .. string.upper(tab.Title)
end

function Window:_createLogRow(entry)
    local style = Levels[entry.Level] or Levels.info

    local row = new("Frame", {
        BackgroundColor3 = Tokens.Color.Card,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = self.LogList,
    }, {
        corner(Tokens.Radius.Md),
        stroke(Tokens.Color.Stroke, 0.28, 1),
        padding(11, 9, 11, 9),
        list(Enum.FillDirection.Vertical, 6),
    })

    local top = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = row,
    })

    local levelBadge = makeText(top, merge(textProps(style.Label, 10, Tokens.Color.Ink, true), {
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(56, 18),
        Position = UDim2.fromOffset(0, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(Tokens.Radius.Sm).Parent = levelBadge

    makeText(top, merge(textProps(entry.Time, 11, Tokens.Color.Text3, true), {
        Position = UDim2.fromOffset(66, 0),
        Size = UDim2.fromOffset(90, 20),
    }))

    makeText(row, merge(textProps(entry.Message, 12, Tokens.Color.Text), {
        Font = Enum.Font.Code,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
    }))

    local metaText = formatMeta(entry.Meta)
    makeText(row, merge(textProps(metaText, 11, Tokens.Color.Text3), {
        Font = Enum.Font.Code,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        Visible = metaText ~= "",
    }))

    entry.Row = row
    return row
end

function Window:_refreshLogs()
    if not self.LogList then
        return
    end

    local query = string.lower(self.LogSearch or "")

    for _, entry in ipairs(self.LogEntries) do
        local visibleLevel = self.LogFilters[entry.Level] == true
        local text = string.lower(entry.Message .. " " .. formatMeta(entry.Meta))
        local visibleSearch = query == "" or string.find(text, query, 1, true) ~= nil

        if entry.Row then
            entry.Row.Visible = visibleLevel and visibleSearch
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

    local toolbar = new("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 104),
        Parent = tab.Page,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Stroke, 0.28, 1),
        padding(12, 12, 12, 12),
    })

    makeText(toolbar, merge(textProps("LOG CONSOLE", 12, Tokens.Color.Blue2, true), {
        Size = UDim2.new(1, -240, 0, 18),
    }))

    local search = new("TextBox", {
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search logs",
        TextColor3 = Tokens.Color.Text,
        PlaceholderColor3 = Tokens.Color.Text3,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Tokens.Color.Panel3,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(0, 30),
        Size = UDim2.new(1, -238, 0, 32),
        Parent = toolbar,
    }, {
        corner(Tokens.Radius.Md),
        padding(10, 0, 10, 0),
        stroke(Tokens.Color.Stroke, 0.28, 1),
    })

    local auto = makeButton(toolbar, {
        BackgroundColor3 = Tokens.Color.Blue,
        Text = "AUTO",
        TextColor3 = Tokens.Color.Ink,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(58, 32),
        Position = UDim2.new(1, -238, 0, 30),
    }, { corner(Tokens.Radius.Md) })

    local copy = makeButton(toolbar, {
        BackgroundColor3 = Tokens.Color.Panel3,
        Text = "COPY",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(76, 32),
        Position = UDim2.new(1, -172, 0, 30),
    }, { corner(Tokens.Radius.Md) })

    local clear = makeButton(toolbar, {
        BackgroundColor3 = Tokens.Color.Panel3,
        Text = "CLEAR",
        TextColor3 = Tokens.Color.Text,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(84, 32),
        Position = UDim2.new(1, -88, 0, 30),
    }, { corner(Tokens.Radius.Md) })

    local filters = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.fromOffset(0, 68),
        Parent = toolbar,
    }, {
        list(Enum.FillDirection.Horizontal, 6),
    })

    for _, level in ipairs(LevelOrder) do
        local style = Levels[level]
        local button = makeButton(filters, {
            BackgroundColor3 = style.Color,
            Text = style.Label,
            TextColor3 = Tokens.Color.Ink,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Size = UDim2.fromOffset(58, 26),
        }, { corner(Tokens.Radius.Sm) })

        button.MouseButton1Click:Connect(function()
            self.LogFilters[level] = not self.LogFilters[level]
            button.BackgroundColor3 = self.LogFilters[level] and style.Color or Tokens.Color.Panel3
            button.TextColor3 = self.LogFilters[level] and Tokens.Color.Ink or Tokens.Color.Text3
            self:_refreshLogs()
        end)
    end

    local listFrame = makeScroll(tab.Page)
    listFrame.Size = UDim2.new(1, 0, 1, -116)

    self.LogList = listFrame
    self.LogSearchBox = search

    search:GetPropertyChangedSignal("Text"):Connect(function()
        self.LogSearch = search.Text
        self:_refreshLogs()
    end)

    auto.MouseButton1Click:Connect(function()
        self.AutoScrollLogs = not self.AutoScrollLogs
        auto.BackgroundColor3 = self.AutoScrollLogs and Tokens.Color.Blue or Tokens.Color.Panel3
        auto.TextColor3 = self.AutoScrollLogs and Tokens.Color.Ink or Tokens.Color.Text3
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

    if not Levels[level] then
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
        self:_createLogRow(entry)
    end

    while #self.LogEntries > self.MaxLogs do
        local old = table.remove(self.LogEntries, 1)

        if old and old.Row then
            old.Row:Destroy()
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

    local text = string.format("[%s] [%s] %s", entry.Time, string.upper(entry.Level), entry.Message)
    local meta = formatMeta(entry.Meta)

    if meta ~= "" then
        text = text .. " | " .. meta
    end

    if type(setclipboard) == "function" then
        setclipboard(text)
        self:Success("Latest log copied")
        return true
    end

    self:Warn("Clipboard API unavailable")
    return false
end

function Window:Notify(config)
    if self.Destroyed then
        return nil
    end

    config = config or {}
    local level = string.lower(config.Level or "info")
    local style = Levels[level] or Levels.info

    local card = new("CanvasGroup", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        GroupTransparency = 1,
        Parent = self.Notifications,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.StrokeBright, 0.25, 1),
        padding(12, 10, 12, 10),
        list(Enum.FillDirection.Horizontal, 9),
    })

    new("Frame", {
        BackgroundColor3 = style.Color,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(3, 44),
        Parent = card,
    }, {
        corner(4),
    })

    local stack = new("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -12, 0, 0),
        Parent = card,
    }, {
        list(Enum.FillDirection.Vertical, 3),
    })

    makeText(stack, merge(textProps(config.Title or self.Title, 12, Tokens.Color.Text, true), {
        Size = UDim2.new(1, 0, 0, 16),
    }))

    makeText(stack, merge(textProps(config.Content or "", 12, Tokens.Color.Text2), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
    }))

    tween(card, { GroupTransparency = 0 }, Tokens.Motion.Base)

    task.delay(tonumber(config.Duration) or 3, function()
        if card and card.Parent then
            tween(card, { GroupTransparency = 1 }, Tokens.Motion.Base)

            task.delay(Tokens.Motion.Base, function()
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
    self.Bin:Clean()

    if self.Gui then
        self.Gui:Destroy()
    end

    local state = getState()

    if state.ActiveWindow == self then
        state.ActiveWindow = nil
    end
end

local function buildLoading(root)
    local overlay = new("CanvasGroup", {
        BackgroundColor3 = Tokens.Color.Ink,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 80,
        Parent = root,
    }, {
        corner(Tokens.Radius.Xl),
    })

    local card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 154),
        ZIndex = 81,
        Parent = overlay,
    }, {
        corner(Tokens.Radius.Xl),
        stroke(Tokens.Color.StrokeBright, 0.12, 1),
        padding(18, 16, 18, 16),
        list(Enum.FillDirection.Vertical, 9),
    })

    makeText(card, merge(textProps("LARPTER PREMIUM", 16, Tokens.Color.Text, true), {
        Size = UDim2.new(1, 0, 0, 22),
        ZIndex = 82,
    }))

    local status = makeText(card, merge(textProps("Preparing interface", 12, Tokens.Color.Text2), {
        Size = UDim2.new(1, 0, 0, 18),
        ZIndex = 82,
    }))

    local track = new("Frame", {
        BackgroundColor3 = Tokens.Color.Panel3,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 8),
        ZIndex = 82,
        Parent = card,
    }, {
        corner(4),
    })

    local fill = new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(0.08, 1),
        ZIndex = 83,
        Parent = track,
    }, {
        corner(4),
        gradient(Tokens.Color.Blue, Tokens.Color.Blue2),
    })

    makeText(card, merge(textProps("duplicate safe / log ready / smooth boot", 10, Tokens.Color.Text3, true), {
        Size = UDim2.new(1, 0, 0, 16),
        ZIndex = 82,
    }))

    return overlay, status, fill
end

local function buildWindow(config)
    config = config or {}

    local parent = getParent()
    assert(parent, "LARPTER Premium could not find a GUI parent")

    local gui = new("ScreenGui", {
        Name = config.Name or "LARPTERPremium",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = parent,
    })
    protect(gui)

    local bin = Bin.new()
    local tabWidth = config.TabWidth or 188
    local size = config.Size or UDim2.fromOffset(800, 548)

    local root = new("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Tokens.Color.Ink,
        BorderSizePixel = 0,
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        Parent = gui,
    }, {
        corner(Tokens.Radius.Xl),
        stroke(Tokens.Color.StrokeBright, 0.08, 1),
        new("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Tokens.Color.Ink3),
                ColorSequenceKeypoint.new(1, Tokens.Color.Ink),
            }),
        }),
    })

    local scale = new("UIScale", {
        Scale = 0.96,
        Parent = root,
    })

    local header = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 84),
        Parent = root,
    })

    new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -28, 0, 2),
        Position = UDim2.fromOffset(14, 0),
        Parent = header,
    }, {
        corner(2),
        gradient(Tokens.Color.Blue, Tokens.Color.Blue2, Color3.fromRGB(26, 70, 160)),
    })

    local mark = new("Frame", {
        BackgroundColor3 = Tokens.Color.Blue,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(18, 19),
        Size = UDim2.fromOffset(42, 42),
        Parent = header,
    }, {
        corner(Tokens.Radius.Lg),
        gradient(Tokens.Color.Blue, Color3.fromRGB(26, 70, 160)),
    })

    makeText(mark, merge(textProps("LP", 14, Tokens.Color.Ink, true), {
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local title = makeText(header, merge(textProps(config.Title or Larpter.Name, 17, Tokens.Color.Text, true), {
        Position = UDim2.fromOffset(74, 16),
        Size = UDim2.new(1, -390, 0, 24),
    }))

    local subtitle = makeText(header, merge(textProps(config.Subtitle or "Matte black control surface", 12, Tokens.Color.Text2), {
        Position = UDim2.fromOffset(74, 42),
        Size = UDim2.new(1, -410, 0, 18),
    }))

    local activeLabel = makeText(header, merge(textProps("ACTIVE", 11, Tokens.Color.Text2, true), {
        BackgroundColor3 = Tokens.Color.Panel2,
        BackgroundTransparency = 0.06,
        Position = UDim2.new(1, -316, 0, 26),
        Size = UDim2.fromOffset(174, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))
    corner(15).Parent = activeLabel
    stroke(Tokens.Color.Stroke, 0.35, 1).Parent = activeLabel

    local min = makeButton(header, {
        BackgroundColor3 = Tokens.Color.Panel2,
        Text = "-",
        TextColor3 = Tokens.Color.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -90, 0, 26),
        Size = UDim2.fromOffset(34, 30),
    }, { corner(Tokens.Radius.Md) })

    local close = makeButton(header, {
        BackgroundColor3 = Tokens.Color.Panel2,
        Text = "X",
        TextColor3 = Tokens.Color.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Position = UDim2.new(1, -46, 0, 26),
        Size = UDim2.fromOffset(34, 30),
    }, { corner(Tokens.Radius.Md) })

    local body = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 90),
        Size = UDim2.new(1, -28, 1, -104),
        Parent = root,
    })

    local sidebar = new("Frame", {
        BackgroundColor3 = Tokens.Color.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, tabWidth, 1, 0),
        Parent = body,
    }, {
        corner(Tokens.Radius.Lg),
        stroke(Tokens.Color.Stroke, 0.22, 1),
        padding(10, 10, 10, 10),
    })

    makeText(sidebar, merge(textProps("NAVIGATION", 10, Tokens.Color.Text3, true), {
        Size = UDim2.new(1, 0, 0, 18),
    }))

    local tabList = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 26),
        Size = UDim2.new(1, 0, 1, -54),
        Parent = sidebar,
    }, {
        list(Enum.FillDirection.Vertical, 7),
    })

    makeText(sidebar, merge(textProps("LARPTER UI  /  v" .. Larpter.Version, 10, Tokens.Color.Text3, true), {
        Position = UDim2.new(0, 0, 1, -22),
        Size = UDim2.new(1, 0, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
    }))

    local pageHost = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, tabWidth + 14, 0, 0),
        Size = UDim2.new(1, -tabWidth - 14, 1, 0),
        Parent = body,
    })

    local notifications = new("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.fromOffset(326, 430),
        Parent = gui,
    }, {
        list(Enum.FillDirection.Vertical, 8),
    })
    notifications.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local loading, loadingStatus, loadingFill = buildLoading(root)

    local window = setmetatable({
        Gui = gui,
        Root = root,
        Scale = scale,
        Header = header,
        Body = body,
        Sidebar = sidebar,
        TabList = tabList,
        PageHost = pageHost,
        Notifications = notifications,
        Loading = loading,
        LoadingStatus = loadingStatus,
        LoadingFill = loadingFill,
        MinimizeButton = min,
        CloseButton = close,
        ActiveLabel = activeLabel,
        TitleLabel = title,
        SubtitleLabel = subtitle,
        Title = config.Title or Larpter.Name,
        Size = size,
        MinimizeKey = normalizeKeyCode(config.MinimizeKey, Enum.KeyCode.LeftControl),
        MaxLogs = tonumber(config.MaxLogs) or 250,
        AutoScrollLogs = true,
        LogSearch = "",
        LogEntries = {},
        LogFilters = {},
        Tabs = {},
        ActiveTab = nil,
        Destroyed = false,
        Minimized = false,
        Bin = bin,
    }, Window)

    for _, level in ipairs(LevelOrder) do
        window.LogFilters[level] = true
    end

    window:_setLoading(0.22, "Mounting shell")

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    local function updateDrag(input)
        local delta = input.Position - dragStart
        root.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    bin:Add(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = root.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    bin:Add(header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    bin:Add(UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updateDrag(input)
        end
    end))

    bin:Add(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window.MinimizeKey then
            window:Toggle()
        end
    end))

    min.MouseButton1Click:Connect(function()
        window:SetMinimized(not window.Minimized)
    end)

    close.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    window:_setLoading(0.54, "Preparing log console")
    window:_buildLogTab()
    window:_setLoading(0.78, "Binding components")
    window:Info("LARPTER Premium initialized", {
        version = Larpter.Version,
        maxLogs = window.MaxLogs,
    })
    window:_finishLoading()

    return window
end

function Larpter:CreateWindow(config)
    config = config or {}

    local state = getState()
    local active = state.ActiveWindow
    local preventDuplicate = config.PreventDuplicate ~= false

    if active and not active.Destroyed and active.Gui and active.Gui.Parent then
        if config.ForceReload == true then
            active:Destroy()
        elseif preventDuplicate then
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

function Larpter:CreateDemo()
    local window = self:CreateWindow({
        Title = "LARPTER Premium",
        Subtitle = "React-style Roblox control surface",
        MaxLogs = 200,
    })

    local dashboard = window:AddTab({ Title = "Dashboard" })

    local overview = dashboard:AddSection("Overview")
    overview:AddParagraph({
        Title = "Matte black. Electric blue. Log-first.",
        Content = "A rebuilt component system with duplicate protection, smooth boot, polished controls, and a first-class console.",
    })

    local actions = dashboard:AddSection("Quick Actions")
    actions:AddButton({
        Title = "Write success log",
        Description = "Adds a styled entry to the console",
        Callback = function()
            window:Success("Demo action completed", { source = "button" })
            window:Notify({
                Title = "Action complete",
                Content = "A success log was added.",
                Level = "success",
            })
        end,
    })

    actions:AddToggle({
        Title = "Enable module",
        Description = "Smooth toggle with callback logging",
        Default = false,
        Callback = function(value)
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
