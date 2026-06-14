--[[
    LARPTER Premium UI Foundation
    A self-contained Roblox Lua UI kit with a built-in log console.

    Basic usage:

    local Larpter = loadstring(game:HttpGet(".../larpter_premium.lua"))()
    local Window = Larpter:CreateWindow({
        Title = "LARPTER Premium",
        Subtitle = "Control panel",
    })

    local Main = Window:AddTab({ Title = "Main" })
    Main:AddButton({
        Title = "Run action",
        Description = "Example callback",
        Callback = function()
            Window:Success("Action finished")
        end,
    })

    Window:Info("UI ready")
]]

local Larpter = {
    Version = "1.0.0",
    Name = "LARPTER Premium",
}

local Services = setmetatable({}, {
    __index = function(self, serviceName)
        local service = game:GetService(serviceName)
        rawset(self, serviceName, service)
        return service
    end,
})

local Players = Services.Players
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService

local LocalPlayer = Players.LocalPlayer

local Theme = {
    Background = Color3.fromRGB(8, 10, 14),
    Surface = Color3.fromRGB(15, 18, 24),
    SurfaceHigh = Color3.fromRGB(22, 27, 35),
    SurfaceLift = Color3.fromRGB(28, 34, 43),
    Border = Color3.fromRGB(54, 66, 79),
    BorderSoft = Color3.fromRGB(37, 45, 55),
    Accent = Color3.fromRGB(26, 221, 178),
    AccentAlt = Color3.fromRGB(70, 165, 255),
    Text = Color3.fromRGB(239, 246, 255),
    SubText = Color3.fromRGB(150, 163, 178),
    Muted = Color3.fromRGB(94, 109, 126),
    Danger = Color3.fromRGB(255, 91, 107),
    Warning = Color3.fromRGB(255, 193, 92),
    Success = Color3.fromRGB(57, 217, 138),
    Debug = Color3.fromRGB(172, 139, 255),
}

local LogLevelStyles = {
    info = { Label = "INFO", Color = Theme.AccentAlt },
    success = { Label = "OK", Color = Theme.Success },
    warn = { Label = "WARN", Color = Theme.Warning },
    error = { Label = "ERR", Color = Theme.Danger },
    debug = { Label = "DBG", Color = Theme.Debug },
}

local DefaultLogLevels = { "info", "success", "warn", "error", "debug" }

local function noop() end

local function safeCallback(callback, ...)
    if type(callback) ~= "function" then
        return true
    end

    local ok, result = pcall(callback, ...)
    if not ok then
        warn("[LARPTER Premium] Callback error: " .. tostring(result))
    end

    return ok, result
end

local function shallowMerge(base, patch)
    local result = {}

    for key, value in pairs(base or {}) do
        result[key] = value
    end

    for key, value in pairs(patch or {}) do
        result[key] = value
    end

    return result
end

local function clamp(number, minValue, maxValue)
    if number < minValue then
        return minValue
    end

    if number > maxValue then
        return maxValue
    end

    return number
end

local function roundTo(value, decimals)
    decimals = decimals or 0

    if decimals <= 0 then
        return math.floor(value + 0.5)
    end

    local factor = 10 ^ decimals
    return math.floor(value * factor + 0.5) / factor
end

local function arrayContains(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end

    return false
end

local function create(instanceType, properties, children)
    local object = Instance.new(instanceType)
    properties = properties or {}

    for key, value in pairs(properties) do
        if key ~= "Parent" then
            object[key] = value
        end
    end

    for _, child in ipairs(children or {}) do
        child.Parent = object
    end

    if properties.Parent then
        object.Parent = properties.Parent
    end

    return object
end

local function corner(radius)
    return create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
    })
end

local function stroke(color, transparency, thickness)
    return create("UIStroke", {
        Color = color or Theme.Border,
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

local function listLayout(direction, paddingPixels)
    return create("UIListLayout", {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, paddingPixels or 8),
    })
end

local function makeText(text, size, color, weight)
    return {
        Text = text or "",
        TextSize = size or 13,
        TextColor3 = color or Theme.Text,
        Font = weight == "bold" and Enum.Font.GothamBold or Enum.Font.Gotham,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
    }
end

local function tween(object, properties, duration, easingStyle, easingDirection)
    local info = TweenInfo.new(
        duration or 0.18,
        easingStyle or Enum.EasingStyle.Quint,
        easingDirection or Enum.EasingDirection.Out
    )
    local createdTween = TweenService:Create(object, info, properties)
    createdTween:Play()
    return createdTween
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
    local protector = nil

    if type(syn) == "table" and type(syn.protect_gui) == "function" then
        protector = syn.protect_gui
    elseif type(protectgui) == "function" then
        protector = protectgui
    end

    if protector then
        pcall(protector, gui)
    end
end

local function safeString(value)
    if value == nil then
        return ""
    end

    return tostring(value)
end

local function stringifyMeta(meta)
    if meta == nil then
        return ""
    end

    if type(meta) ~= "table" then
        return tostring(meta)
    end

    local parts = {}
    local count = 0

    for key, value in pairs(meta) do
        count = count + 1
        parts[#parts + 1] = tostring(key) .. "=" .. tostring(value)

        if count >= 8 then
            parts[#parts + 1] = "..."
            break
        end
    end

    return table.concat(parts, "  ")
end

local function normalizeKeyCode(value, fallback)
    fallback = fallback or Enum.KeyCode.LeftControl

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

local function setButtonState(button, enabled)
    if enabled then
        tween(button, {
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.06,
        }, 0.16)
    else
        tween(button, {
            BackgroundColor3 = Theme.SurfaceLift,
            BackgroundTransparency = 0.18,
        }, 0.16)
    end
end

local function bindButtonFeedback(button, normalColor, hoverColor, pressColor)
    normalColor = normalColor or Theme.SurfaceHigh
    hoverColor = hoverColor or Theme.SurfaceLift
    pressColor = pressColor or Theme.Accent

    button.MouseEnter:Connect(function()
        tween(button, {
            BackgroundColor3 = hoverColor,
        }, 0.12)
    end)

    button.MouseLeave:Connect(function()
        tween(button, {
            BackgroundColor3 = normalColor,
        }, 0.12)
    end)

    button.MouseButton1Down:Connect(function()
        tween(button, {
            BackgroundColor3 = pressColor,
        }, 0.08)
    end)

    button.MouseButton1Up:Connect(function()
        tween(button, {
            BackgroundColor3 = hoverColor,
        }, 0.08)
    end)
end

local WindowMethods = {}
WindowMethods.__index = WindowMethods

local TabMethods = {}
TabMethods.__index = TabMethods

local SectionMethods = {}
SectionMethods.__index = SectionMethods

local function createComponentBase(parent, config, height)
    config = config or {}

    local root = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, height or 58),
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.25, 1),
    })

    local title = create("TextLabel", shallowMerge(makeText(config.Title or "Untitled", 13, Theme.Text, "bold"), {
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -150, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = root,
    }))

    local description = create("TextLabel", shallowMerge(makeText(config.Description or "", 12, Theme.SubText), {
        Position = UDim2.fromOffset(12, 28),
        Size = UDim2.new(1, -150, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = config.Description ~= nil and config.Description ~= "",
        Parent = root,
    }))

    local object = {
        Root = root,
        TitleLabel = title,
        DescriptionLabel = description,
    }

    function object:SetTitle(value)
        self.TitleLabel.Text = safeString(value)
    end

    function object:SetDescription(value)
        value = safeString(value)
        self.DescriptionLabel.Text = value
        self.DescriptionLabel.Visible = value ~= ""
    end

    function object:Destroy()
        self.Root:Destroy()
    end

    return object
end

local function makeSection(host, title)
    local root = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = host.Content,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.45, 1),
        padding(10, 10, 10, 10),
        listLayout(Enum.FillDirection.Vertical, 8),
    })

    local label = create("TextLabel", shallowMerge(makeText(title or "Section", 12, Theme.SubText, "bold"), {
        Size = UDim2.new(1, 0, 0, 18),
        Text = string.upper(title or "Section"),
        Parent = root,
    }))

    local section = setmetatable({
        Window = host.Window,
        Tab = host.Tab or host,
        Root = root,
        Label = label,
        Content = root,
    }, SectionMethods)

    return section
end

local function getComponentHost(host)
    if getmetatable(host) == SectionMethods then
        return host
    end

    if getmetatable(host) == TabMethods then
        if not host.DefaultSection then
            host.DefaultSection = makeSection(host, "Controls")
        end

        return host.DefaultSection
    end

    return host
end

function SectionMethods:AddButton(config)
    local host = getComponentHost(self)
    config = config or {}

    local base = createComponentBase(host.Content, config, 56)
    local button = create("TextButton", {
        AutoButtonColor = false,
        Text = "Run",
        TextColor3 = Theme.Background,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.02,
        Size = UDim2.fromOffset(78, 30),
        Position = UDim2.new(1, -92, 0.5, -15),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(7),
    })

    bindButtonFeedback(button, Theme.Accent, Theme.AccentAlt, Theme.Success)

    button.MouseButton1Click:Connect(function()
        safeCallback(config.Callback or noop)
    end)

    base.Button = button
    return base
end

function SectionMethods:AddToggle(config)
    local host = getComponentHost(self)
    config = config or {}

    local base = createComponentBase(host.Content, config, 58)
    local state = config.Default == true

    local switch = create("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLift,
        BackgroundTransparency = state and 0.04 or 0.18,
        Size = UDim2.fromOffset(46, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(12),
        stroke(Theme.BorderSoft, 0.35, 1),
    })

    local knob = create("Frame", {
        BackgroundColor3 = Theme.Text,
        Size = UDim2.fromOffset(18, 18),
        Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3),
        BorderSizePixel = 0,
        Parent = switch,
    }, {
        corner(9),
    })

    function base:GetValue()
        return state
    end

    function base:SetValue(value, silent)
        state = value == true

        tween(switch, {
            BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLift,
            BackgroundTransparency = state and 0.04 or 0.18,
        }, 0.14)

        tween(knob, {
            Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3),
        }, 0.14)

        if not silent then
            safeCallback(config.Callback or noop, state)
        end
    end

    switch.MouseButton1Click:Connect(function()
        base:SetValue(not state)
    end)

    base.Switch = switch
    base.Knob = knob
    return base
end

function SectionMethods:AddSlider(config)
    local host = getComponentHost(self)
    config = config or {}

    local minValue = tonumber(config.Min) or 0
    local maxValue = tonumber(config.Max) or 100
    local decimals = tonumber(config.Rounding) or 0
    local value = clamp(tonumber(config.Default) or minValue, minValue, maxValue)
    local suffix = config.Suffix or ""

    local base = createComponentBase(host.Content, config, 68)
    base.TitleLabel.Size = UDim2.new(1, -210, 0, 18)
    base.DescriptionLabel.Size = UDim2.new(1, -210, 0, 18)

    local valueLabel = create("TextLabel", shallowMerge(makeText("", 12, Theme.SubText, "bold"), {
        Size = UDim2.fromOffset(70, 18),
        Position = UDim2.new(1, -84, 0, 9),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = base.Root,
    }))

    local track = create("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.1,
        Size = UDim2.new(1, -24, 0, 8),
        Position = UDim2.new(0, 12, 1, -20),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(4),
    })

    local fill = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size = UDim2.fromScale(0, 1),
        BorderSizePixel = 0,
        Parent = track,
    }, {
        corner(4),
    })

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Text,
        Size = UDim2.fromOffset(16, 16),
        Position = UDim2.fromScale(0, 0.5),
        BorderSizePixel = 0,
        Parent = track,
    }, {
        corner(8),
        stroke(Theme.Accent, 0.15, 2),
    })

    local dragging = false

    local function valueToAlpha(nextValue)
        if maxValue == minValue then
            return 0
        end

        return clamp((nextValue - minValue) / (maxValue - minValue), 0, 1)
    end

    local function updateVisual(nextValue)
        local alpha = valueToAlpha(nextValue)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = tostring(nextValue) .. suffix
    end

    local function setFromPosition(xPosition, silent)
        local alpha = clamp((xPosition - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local nextValue = roundTo(minValue + (maxValue - minValue) * alpha, decimals)
        base:SetValue(nextValue, silent)
    end

    function base:GetValue()
        return value
    end

    function base:SetValue(nextValue, silent)
        value = clamp(roundTo(tonumber(nextValue) or minValue, decimals), minValue, maxValue)
        updateVisual(value)

        if not silent then
            safeCallback(config.Callback or noop, value)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromPosition(input.Position.X)
        end
    end)

    local changedConnection = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromPosition(input.Position.X)
        end
    end)

    local endedConnection = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    if host.Window then
        host.Window:_addConnection(changedConnection)
        host.Window:_addConnection(endedConnection)
    end

    base:SetValue(value, true)
    return base
end

function SectionMethods:AddDropdown(config)
    local host = getComponentHost(self)
    config = config or {}

    local values = config.Values or {}
    local selected = config.Default or values[1]
    local opened = false

    local base = createComponentBase(host.Content, config, 58)
    base.Root.ClipsDescendants = true

    local display = create("TextButton", {
        AutoButtonColor = false,
        Text = safeString(selected),
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.13,
        Size = UDim2.fromOffset(150, 30),
        Position = UDim2.new(1, -164, 0, 14),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(7),
        padding(10, 0, 28, 0),
    })

    local arrow = create("TextLabel", shallowMerge(makeText("v", 12, Theme.SubText, "bold"), {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -26, 0, 20),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = base.Root,
    }))

    local list = create("Frame", {
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.04,
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.fromOffset(12, 58),
        Visible = false,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.35, 1),
        padding(6, 6, 6, 6),
        listLayout(Enum.FillDirection.Vertical, 4),
    })

    local optionButtons = {}

    local function setOpen(nextState)
        opened = nextState == true
        list.Visible = true

        local targetHeight = opened and math.min(#values * 30 + 12, 162) or 0
        tween(base.Root, {
            Size = UDim2.new(1, 0, 0, opened and (64 + targetHeight) or 58),
        }, 0.18)
        tween(list, {
            Size = UDim2.new(1, -24, 0, targetHeight),
        }, 0.18)
        arrow.Text = opened and "^" or "v"

        if not opened then
            task.delay(0.18, function()
                if not opened and list then
                    list.Visible = false
                end
            end)
        end
    end

    local function rebuildOptions()
        for _, button in ipairs(optionButtons) do
            button:Destroy()
        end

        optionButtons = {}

        for _, optionValue in ipairs(values) do
            local optionButton = create("TextButton", {
                AutoButtonColor = false,
                Text = safeString(optionValue),
                TextColor3 = optionValue == selected and Theme.Accent or Theme.Text,
                TextSize = 12,
                Font = optionValue == selected and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                BackgroundColor3 = optionValue == selected and Theme.SurfaceHigh or Theme.SurfaceLift,
                BackgroundTransparency = optionValue == selected and 0.02 or 0.22,
                Size = UDim2.new(1, 0, 0, 26),
                BorderSizePixel = 0,
                Parent = list,
            }, {
                corner(6),
                padding(8, 0, 8, 0),
            })

            bindButtonFeedback(optionButton, optionButton.BackgroundColor3, Theme.SurfaceHigh, Theme.Accent)

            optionButton.MouseButton1Click:Connect(function()
                base:SetValue(optionValue)
                setOpen(false)
            end)

            optionButtons[#optionButtons + 1] = optionButton
        end
    end

    function base:GetValue()
        return selected
    end

    function base:SetValue(nextValue, silent)
        selected = nextValue
        display.Text = safeString(selected)
        rebuildOptions()

        if not silent then
            safeCallback(config.Callback or noop, selected)
        end
    end

    function base:SetValues(nextValues)
        values = nextValues or {}
        if not arrayContains(values, selected) then
            selected = values[1]
            display.Text = safeString(selected)
        end
        rebuildOptions()
    end

    display.MouseButton1Click:Connect(function()
        setOpen(not opened)
    end)

    rebuildOptions()
    return base
end

function SectionMethods:AddInput(config)
    local host = getComponentHost(self)
    config = config or {}

    local base = createComponentBase(host.Content, config, 58)
    local value = safeString(config.Default)

    local box = create("TextBox", {
        ClearTextOnFocus = false,
        Text = value,
        PlaceholderText = config.Placeholder or "Type...",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.13,
        Size = UDim2.fromOffset(160, 30),
        Position = UDim2.new(1, -174, 0.5, -15),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(7),
        stroke(Theme.BorderSoft, 0.35, 1),
        padding(9, 0, 9, 0),
    })

    function base:GetValue()
        return value
    end

    function base:SetValue(nextValue, silent)
        nextValue = safeString(nextValue)

        if config.MaxLength and #nextValue > config.MaxLength then
            nextValue = string.sub(nextValue, 1, config.MaxLength)
        end

        if config.Numeric and nextValue ~= "" and tonumber(nextValue) == nil then
            nextValue = value
        end

        value = nextValue
        box.Text = value

        if not silent then
            safeCallback(config.Callback or noop, value)
        end
    end

    box.Focused:Connect(function()
        tween(box, {
            BackgroundTransparency = 0.04,
        }, 0.12)
    end)

    box.FocusLost:Connect(function()
        tween(box, {
            BackgroundTransparency = 0.13,
        }, 0.12)
        base:SetValue(box.Text)
    end)

    if not config.Finished then
        box:GetPropertyChangedSignal("Text"):Connect(function()
            if box:IsFocused() then
                base:SetValue(box.Text)
            end
        end)
    end

    base.Input = box
    return base
end

function SectionMethods:AddKeybind(config)
    local host = getComponentHost(self)
    config = config or {}

    local base = createComponentBase(host.Content, config, 58)
    local keyCode = normalizeKeyCode(config.Default, Enum.KeyCode.RightShift)
    local listening = false
    local mode = config.Mode or "Toggle"
    local toggled = false

    local keyButton = create("TextButton", {
        AutoButtonColor = false,
        Text = keyCode.Name,
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.13,
        Size = UDim2.fromOffset(112, 30),
        Position = UDim2.new(1, -126, 0.5, -15),
        BorderSizePixel = 0,
        Parent = base.Root,
    }, {
        corner(7),
        stroke(Theme.BorderSoft, 0.35, 1),
    })

    bindButtonFeedback(keyButton, Theme.SurfaceLift, Theme.SurfaceHigh, Theme.Accent)

    local function setKey(nextKey)
        keyCode = nextKey
        keyButton.Text = keyCode.Name
        safeCallback(config.ChangedCallback or noop, keyCode)
    end

    function base:GetValue()
        return keyCode
    end

    function base:SetValue(nextValue)
        setKey(normalizeKeyCode(nextValue, keyCode))
    end

    keyButton.MouseButton1Click:Connect(function()
        listening = true
        keyButton.Text = "Press key"
    end)

    local beganConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end

        if listening then
            listening = false
            setKey(input.KeyCode)
            return
        end

        if input.KeyCode == keyCode then
            if mode == "Hold" then
                safeCallback(config.Callback or noop, true)
            else
                toggled = not toggled
                safeCallback(config.Callback or noop, toggled)
            end
        end
    end)

    local endedConnection = UserInputService.InputEnded:Connect(function(input)
        if mode == "Hold" and input.KeyCode == keyCode then
            safeCallback(config.Callback or noop, false)
        end
    end)

    if host.Window then
        host.Window:_addConnection(beganConnection)
        host.Window:_addConnection(endedConnection)
    end

    base.Button = keyButton
    return base
end

function TabMethods:AddSection(title)
    return makeSection(self, title)
end

function TabMethods:AddButton(config)
    return SectionMethods.AddButton(self, config)
end

function TabMethods:AddToggle(config)
    return SectionMethods.AddToggle(self, config)
end

function TabMethods:AddSlider(config)
    return SectionMethods.AddSlider(self, config)
end

function TabMethods:AddDropdown(config)
    return SectionMethods.AddDropdown(self, config)
end

function TabMethods:AddInput(config)
    return SectionMethods.AddInput(self, config)
end

function TabMethods:AddKeybind(config)
    return SectionMethods.AddKeybind(self, config)
end

function WindowMethods:_addConnection(connection)
    self._connections[#self._connections + 1] = connection
    return connection
end

function WindowMethods:_makeTabButton(tab)
    local button = create("TextButton", {
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = Theme.SurfaceHigh,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36),
        BorderSizePixel = 0,
        Parent = self.TabList,
    }, {
        corner(8),
    })

    local accent = create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.fromOffset(0, 10),
        BorderSizePixel = 0,
        Parent = button,
    }, {
        corner(2),
    })

    local label = create("TextLabel", shallowMerge(makeText(tab.Title, 13, Theme.SubText, "bold"), {
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = button,
    }))

    button.MouseEnter:Connect(function()
        if self.SelectedTab ~= tab then
            tween(button, {
                BackgroundTransparency = 0.34,
            }, 0.14)
        end
    end)

    button.MouseLeave:Connect(function()
        if self.SelectedTab ~= tab then
            tween(button, {
                BackgroundTransparency = 1,
            }, 0.14)
        end
    end)

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)

    tab.Button = button
    tab.ButtonLabel = label
    tab.ButtonAccent = accent
end

function WindowMethods:AddTab(config)
    config = config or {}

    local tab = setmetatable({
        Window = self,
        Title = config.Title or "Tab",
        Icon = config.Icon,
        Internal = config.Internal == true,
        DefaultSection = nil,
    }, TabMethods)

    local page = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        Parent = self.PageHolder,
    }, {
        padding(0, 0, 6, 0),
        listLayout(Enum.FillDirection.Vertical, 10),
    })

    tab.Page = page
    tab.Content = page

    self.Tabs[#self.Tabs + 1] = tab
    self:_makeTabButton(tab)

    if not self.SelectedTab or (self.SelectedTab == self.LogTab and not tab.Internal) then
        self:SelectTab(tab)
    end

    return tab
end

function WindowMethods:SelectTab(tab)
    if type(tab) == "number" then
        tab = self.Tabs[tab]
    end

    if not tab or self.SelectedTab == tab then
        return
    end

    for _, item in ipairs(self.Tabs) do
        local selected = item == tab
        item.Page.Visible = selected

        tween(item.Button, {
            BackgroundTransparency = selected and 0.18 or 1,
            BackgroundColor3 = selected and Theme.SurfaceLift or Theme.SurfaceHigh,
        }, 0.16)

        tween(item.ButtonAccent, {
            BackgroundTransparency = selected and 0 or 1,
        }, 0.16)

        item.ButtonLabel.TextColor3 = selected and Theme.Text or Theme.SubText
    end

    self.SelectedTab = tab
    self.HeaderTabLabel.Text = tab.Title
end

function WindowMethods:_createLogRow(entry)
    local style = LogLevelStyles[entry.Level] or LogLevelStyles.info

    local row = create("Frame", {
        BackgroundColor3 = Theme.SurfaceHigh,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = self.LogList,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.42, 1),
        padding(10, 8, 10, 8),
        listLayout(Enum.FillDirection.Vertical, 4),
    })

    local topLine = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Parent = row,
    })

    create("TextLabel", shallowMerge(makeText(entry.Time, 11, Theme.Muted, "bold"), {
        Size = UDim2.fromOffset(70, 20),
        Parent = topLine,
    }))

    create("TextLabel", {
        Text = style.Label,
        TextColor3 = Theme.Background,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        BackgroundColor3 = style.Color,
        BackgroundTransparency = 0,
        Size = UDim2.fromOffset(52, 18),
        Position = UDim2.fromOffset(76, 1),
        BorderSizePixel = 0,
        Parent = topLine,
    }, {
        corner(5),
    })

    local message = create("TextLabel", shallowMerge(makeText(entry.Message, 12, Theme.Text), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        Parent = row,
    }))

    local metaText = stringifyMeta(entry.Meta)
    local meta = create("TextLabel", shallowMerge(makeText(metaText, 11, Theme.Muted), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        Visible = metaText ~= "",
        Parent = row,
    }))

    entry.Row = row
    entry.MessageLabel = message
    entry.MetaLabel = meta

    return row
end

function WindowMethods:_refreshLogs()
    if not self.LogList then
        return
    end

    local search = string.lower(self.LogSearch or "")

    for _, entry in ipairs(self.LogEntries) do
        local levelAllowed = self.LogFilters[entry.Level] == true
        local haystack = string.lower(entry.Message .. " " .. stringifyMeta(entry.Meta))
        local searchAllowed = search == "" or string.find(haystack, search, 1, true) ~= nil

        if entry.Row then
            entry.Row.Visible = levelAllowed and searchAllowed
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

function WindowMethods:_buildLogTab()
    local tab = self:AddTab({ Title = "Logs", Internal = true })
    self.LogTab = tab

    local toolbar = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(1, 0, 0, 94),
        BorderSizePixel = 0,
        Parent = tab.Content,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.42, 1),
        padding(10, 10, 10, 10),
    })

    create("TextLabel", shallowMerge(makeText("LOG CONSOLE", 12, Theme.SubText, "bold"), {
        Size = UDim2.new(1, -220, 0, 18),
        Parent = toolbar,
    }))

    local searchBox = create("TextBox", {
        ClearTextOnFocus = false,
        Text = "",
        PlaceholderText = "Search logs",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.12,
        Size = UDim2.new(1, -230, 0, 30),
        Position = UDim2.fromOffset(0, 28),
        BorderSizePixel = 0,
        Parent = toolbar,
    }, {
        corner(7),
        padding(9, 0, 9, 0),
        stroke(Theme.BorderSoft, 0.45, 1),
    })

    local clearButton = create("TextButton", {
        AutoButtonColor = false,
        Text = "Clear",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.15,
        Size = UDim2.fromOffset(68, 30),
        Position = UDim2.new(1, -68, 0, 28),
        BorderSizePixel = 0,
        Parent = toolbar,
    }, {
        corner(7),
    })

    local copyButton = create("TextButton", {
        AutoButtonColor = false,
        Text = "Copy latest",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.SurfaceLift,
        BackgroundTransparency = 0.15,
        Size = UDim2.fromOffset(96, 30),
        Position = UDim2.new(1, -174, 0, 28),
        BorderSizePixel = 0,
        Parent = toolbar,
    }, {
        corner(7),
    })

    local autoButton = create("TextButton", {
        AutoButtonColor = false,
        Text = "Auto",
        TextColor3 = Theme.Background,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.06,
        Size = UDim2.fromOffset(48, 30),
        Position = UDim2.new(1, -230, 0, 28),
        BorderSizePixel = 0,
        Parent = toolbar,
    }, {
        corner(7),
    })

    bindButtonFeedback(clearButton, Theme.SurfaceLift, Theme.SurfaceHigh, Theme.Danger)
    bindButtonFeedback(copyButton, Theme.SurfaceLift, Theme.SurfaceHigh, Theme.AccentAlt)

    local filterHolder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.fromOffset(0, 62),
        Parent = toolbar,
    }, {
        listLayout(Enum.FillDirection.Horizontal, 6),
    })

    local filterButtons = {}

    for _, level in ipairs(DefaultLogLevels) do
        local style = LogLevelStyles[level]
        local button = create("TextButton", {
            AutoButtonColor = false,
            Text = style.Label,
            TextColor3 = Theme.Background,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            BackgroundColor3 = style.Color,
            BackgroundTransparency = 0.05,
            Size = UDim2.fromOffset(54, 24),
            BorderSizePixel = 0,
            Parent = filterHolder,
        }, {
            corner(6),
        })

        button.MouseButton1Click:Connect(function()
            self.LogFilters[level] = not self.LogFilters[level]
            setButtonState(button, self.LogFilters[level])

            if self.LogFilters[level] then
                button.BackgroundColor3 = style.Color
                button.TextColor3 = Theme.Background
            else
                button.TextColor3 = Theme.SubText
            end

            self:_refreshLogs()
        end)

        filterButtons[level] = button
    end

    local list = create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 1, -104),
        Parent = tab.Content,
    }, {
        padding(0, 0, 6, 0),
        listLayout(Enum.FillDirection.Vertical, 8),
    })

    self.LogList = list
    self.LogSearchBox = searchBox
    self.LogFilterButtons = filterButtons

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        self.LogSearch = searchBox.Text
        self:_refreshLogs()
    end)

    clearButton.MouseButton1Click:Connect(function()
        self:ClearLogs()
    end)

    copyButton.MouseButton1Click:Connect(function()
        self:CopyLatestLog()
    end)

    autoButton.MouseButton1Click:Connect(function()
        self.AutoScrollLogs = not self.AutoScrollLogs
        setButtonState(autoButton, self.AutoScrollLogs)
        autoButton.TextColor3 = self.AutoScrollLogs and Theme.Background or Theme.SubText
    end)
end

function WindowMethods:Log(level, message, meta)
    level = string.lower(safeString(level ~= nil and level or "info"))

    if not LogLevelStyles[level] then
        level = "info"
    end

    local entry = {
        Level = level,
        Message = safeString(message),
        Meta = meta,
        Time = os.date("%H:%M:%S"),
    }

    self.LogEntries[#self.LogEntries + 1] = entry

    if self.LogList then
        self:_createLogRow(entry)
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

function WindowMethods:Info(message, meta)
    return self:Log("info", message, meta)
end

function WindowMethods:Success(message, meta)
    return self:Log("success", message, meta)
end

function WindowMethods:Warn(message, meta)
    return self:Log("warn", message, meta)
end

function WindowMethods:Error(message, meta)
    return self:Log("error", message, meta)
end

function WindowMethods:Debug(message, meta)
    return self:Log("debug", message, meta)
end

function WindowMethods:ClearLogs()
    for _, entry in ipairs(self.LogEntries) do
        if entry.Row then
            entry.Row:Destroy()
        end
    end

    self.LogEntries = {}
end

function WindowMethods:CopyLatestLog()
    local entry = self.LogEntries[#self.LogEntries]

    if not entry then
        self:Warn("No log entry to copy")
        return false
    end

    local text = string.format("[%s] [%s] %s", entry.Time, string.upper(entry.Level), entry.Message)
    local metaText = stringifyMeta(entry.Meta)

    if metaText ~= "" then
        text = text .. " | " .. metaText
    end

    if type(setclipboard) == "function" then
        setclipboard(text)
        self:Success("Latest log copied")
        return true
    end

    self:Warn("Clipboard API unavailable")
    return false
end

function WindowMethods:Notify(config)
    config = config or {}

    local level = string.lower(config.Level or "info")
    local style = LogLevelStyles[level] or LogLevelStyles.info
    local duration = tonumber(config.Duration) or 3

    local card = create("CanvasGroup", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.04,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = self.NotificationList,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.28, 1),
        padding(12, 10, 12, 10),
        listLayout(Enum.FillDirection.Horizontal, 8),
    })

    create("Frame", {
        BackgroundColor3 = style.Color,
        Size = UDim2.fromOffset(3, 44),
        BorderSizePixel = 0,
        Parent = card,
    }, {
        corner(2),
    })

    local content = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -12, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = card,
    }, {
        listLayout(Enum.FillDirection.Vertical, 3),
    })

    create("TextLabel", shallowMerge(makeText(config.Title or self.Title, 12, Theme.Text, "bold"), {
        Size = UDim2.new(1, 0, 0, 16),
        Parent = content,
    }))

    create("TextLabel", shallowMerge(makeText(config.Content or "", 12, Theme.SubText), {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        TextWrapped = true,
        Parent = content,
    }))

    card.GroupTransparency = 1
    tween(card, {
        GroupTransparency = 0,
    }, 0.18)

    task.delay(duration, function()
        if card and card.Parent then
            tween(card, {
                GroupTransparency = 1,
            }, 0.18)

            task.delay(0.2, function()
                if card and card.Parent then
                    card:Destroy()
                end
            end)
        end
    end)

    return card
end

function WindowMethods:SetMinimized(minimized)
    self.Minimized = minimized == true
    self.Body.Visible = not self.Minimized

    tween(self.Root, {
        Size = self.Minimized and UDim2.new(self.Size.X.Scale, self.Size.X.Offset, 0, 58) or self.Size,
    }, 0.2)

    self.MinimizeButton.Text = self.Minimized and "+" or "-"
end

function WindowMethods:Toggle()
    self.Root.Visible = not self.Root.Visible
end

function WindowMethods:Destroy()
    for _, connection in ipairs(self._connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    if self.Gui then
        self.Gui:Destroy()
    end
end

local function makeWindow(config)
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

    local size = config.Size or UDim2.fromOffset(680, 480)
    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = gui,
    }, {
        corner(10),
        stroke(Theme.Border, 0.08, 1),
        create("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 23, 30)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 14)),
            }),
        }),
    })

    local header = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 58),
        Parent = root,
    })

    create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 58, 0, 3),
        Position = UDim2.fromOffset(18, 56),
        BorderSizePixel = 0,
        Parent = header,
    }, {
        corner(2),
    })

    local title = create("TextLabel", shallowMerge(makeText(config.Title or Larpter.Name, 16, Theme.Text, "bold"), {
        Position = UDim2.fromOffset(18, 8),
        Size = UDim2.new(1, -180, 0, 22),
        Parent = header,
    }))

    local subtitle = create("TextLabel", shallowMerge(makeText(config.Subtitle or "Premium control surface", 12, Theme.SubText), {
        Position = UDim2.fromOffset(18, 30),
        Size = UDim2.new(1, -220, 0, 18),
        Parent = header,
    }))

    local activeTabLabel = create("TextLabel", shallowMerge(makeText("", 11, Theme.Muted, "bold"), {
        Size = UDim2.fromOffset(140, 22),
        Position = UDim2.new(1, -260, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = header,
    }))

    local minimizeButton = create("TextButton", {
        AutoButtonColor = false,
        Text = "-",
        TextColor3 = Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.SurfaceHigh,
        BackgroundTransparency = 0.12,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -76, 0, 14),
        BorderSizePixel = 0,
        Parent = header,
    }, {
        corner(7),
    })

    local closeButton = create("TextButton", {
        AutoButtonColor = false,
        Text = "X",
        TextColor3 = Theme.Text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = Theme.SurfaceHigh,
        BackgroundTransparency = 0.12,
        Size = UDim2.fromOffset(32, 30),
        Position = UDim2.new(1, -38, 0, 14),
        BorderSizePixel = 0,
        Parent = header,
    }, {
        corner(7),
    })

    bindButtonFeedback(minimizeButton, Theme.SurfaceHigh, Theme.SurfaceLift, Theme.Accent)
    bindButtonFeedback(closeButton, Theme.SurfaceHigh, Theme.SurfaceLift, Theme.Danger)

    local body = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -24, 1, -74),
        Position = UDim2.fromOffset(12, 64),
        Parent = root,
    })

    local sidebar = create("Frame", {
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(0, config.TabWidth or 154, 1, 0),
        BorderSizePixel = 0,
        Parent = body,
    }, {
        corner(8),
        stroke(Theme.BorderSoft, 0.38, 1),
        padding(8, 8, 8, 8),
    })

    local tabList = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = sidebar,
    }, {
        listLayout(Enum.FillDirection.Vertical, 6),
    })

    local pageHolder = create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(config.TabWidth or 154) - 12, 1, 0),
        Position = UDim2.new(0, (config.TabWidth or 154) + 12, 0, 0),
        Parent = body,
    })

    local notificationList = create("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Size = UDim2.fromOffset(310, 420),
        Position = UDim2.new(1, -16, 1, -16),
        Parent = gui,
    }, {
        listLayout(Enum.FillDirection.Vertical, 8),
    })

    notificationList.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom

    local window = setmetatable({
        Gui = gui,
        Root = root,
        Header = header,
        Body = body,
        Sidebar = sidebar,
        TabList = tabList,
        PageHolder = pageHolder,
        NotificationList = notificationList,
        Title = config.Title or Larpter.Name,
        Subtitle = subtitle,
        TitleLabel = title,
        HeaderTabLabel = activeTabLabel,
        MinimizeButton = minimizeButton,
        CloseButton = closeButton,
        Size = size,
        Minimized = false,
        MinimizeKey = normalizeKeyCode(config.MinimizeKey, Enum.KeyCode.LeftControl),
        Tabs = {},
        SelectedTab = nil,
        LogEntries = {},
        MaxLogs = tonumber(config.MaxLogs) or 250,
        LogFilters = {},
        LogSearch = "",
        AutoScrollLogs = true,
        _connections = {},
    }, WindowMethods)

    for _, level in ipairs(DefaultLogLevels) do
        window.LogFilters[level] = true
    end

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    local function updateDrag(input)
        local delta = input.Position - dragStart
        local target = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )

        root.Position = target
    end

    window:_addConnection(header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = root.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end))

    window:_addConnection(header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    window:_addConnection(UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            updateDrag(input)
        end
    end))

    window:_addConnection(UserInputService.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == window.MinimizeKey then
            window:Toggle()
        end
    end))

    minimizeButton.MouseButton1Click:Connect(function()
        window:SetMinimized(not window.Minimized)
    end)

    closeButton.MouseButton1Click:Connect(function()
        window:Destroy()
    end)

    window:_buildLogTab()
    window:Info("LARPTER Premium initialized", {
        version = Larpter.Version,
        maxLogs = window.MaxLogs,
    })

    return window
end

function Larpter:CreateWindow(config)
    return makeWindow(config)
end

function Larpter:CreateDemo()
    local window = self:CreateWindow({
        Title = "LARPTER Premium",
        Subtitle = "Demo control surface",
        MaxLogs = 200,
    })

    local dashboard = window:AddTab({ Title = "Dashboard" })
    local actions = dashboard:AddSection("Quick actions")

    actions:AddButton({
        Title = "Write success log",
        Description = "Adds a sample success entry",
        Callback = function()
            window:Success("Demo action completed", {
                source = "button",
            })
            window:Notify({
                Title = "LARPTER Premium",
                Content = "Demo action completed",
                Level = "success",
            })
        end,
    })

    actions:AddToggle({
        Title = "Enable feature",
        Description = "Example toggle state",
        Default = false,
        Callback = function(value)
            window:Info("Feature toggled", {
                enabled = value,
            })
        end,
    })

    actions:AddSlider({
        Title = "Power",
        Description = "Example numeric control",
        Min = 0,
        Max = 100,
        Default = 50,
        Rounding = 0,
        Suffix = "%",
        Callback = function(value)
            window:Debug("Power changed", {
                value = value,
            })
        end,
    })

    local controls = window:AddTab({ Title = "Controls" })
    local form = controls:AddSection("Form controls")

    form:AddDropdown({
        Title = "Mode",
        Description = "Single-select dropdown",
        Values = { "Balanced", "Fast", "Safe" },
        Default = "Balanced",
        Callback = function(value)
            window:Info("Mode selected", {
                mode = value,
            })
        end,
    })

    form:AddInput({
        Title = "Nickname",
        Description = "Text input example",
        Placeholder = "Enter name",
        Callback = function(value)
            window:Info("Input changed", {
                value = value,
            })
        end,
    })

    form:AddKeybind({
        Title = "Demo keybind",
        Description = "Press to trigger a callback",
        Default = Enum.KeyCode.RightShift,
        Callback = function(value)
            window:Warn("Keybind triggered", {
                state = value,
            })
        end,
    })

    window:SelectTab(dashboard)
    window:Success("Demo scaffold ready")

    return window
end

if getgenv then
    getgenv().LarpterPremium = Larpter
end

return Larpter
