local _VC = getgenv()._VC
local LP             = _VC.LP
local RunService     = _VC.RunService
local UserInputService = _VC.UserInputService
local TweenService   = _VC.TweenService
local C              = _VC.C
local N              = _VC.N
local TF             = _VC.TF
local TM             = _VC.TM
local TS             = _VC.TS
local TSI            = _VC.TSI
local Tween          = _VC.Tween
local Corner         = _VC.Corner
local Stroke         = _VC.Stroke
local Pad            = _VC.Pad
local Config         = _VC.Config
local IsPremium      = _VC.IsPremium
local Screen         = _VC.Screen
local Notify         = _VC.Notify
local RefreshActive  = _VC.RefreshActive
local ExecCmd        = _VC.ExecCmd
local Registry       = _VC.Registry
local PrefLbl        = _VC.PrefLbl

task.spawn(function()
    -- Black hole outer glow ring
    local bhOuter = N("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(60, 0, 100),
        BackgroundTransparency = 0.3,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 0, 0, 0),
        ZIndex                 = 9001,
    }, Screen)
    N("UICorner", {CornerRadius = UDim.new(1, 0)}, bhOuter)

    -- Black hole middle ring
    local bhMid = N("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(120, 20, 200),
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 0, 0, 0),
        ZIndex                 = 9002,
    }, Screen)
    N("UICorner", {CornerRadius = UDim.new(1, 0)}, bhMid)

    -- Black hole core (pure black)
    local bhCore = N("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 0, 0, 0),
        ZIndex                 = 9003,
    }, Screen)
    N("UICorner", {CornerRadius = UDim.new(1, 0)}, bhCore)

    -- Accent rotation ring (simulates accretion disc)
    local bhRing = N("Frame", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 220, 0, 220),
        ZIndex                 = 9002,
    }, Screen)
    N("UICorner", {CornerRadius = UDim.new(1, 0)}, bhRing)
    N("UIStroke", {
        Color     = Color3.fromRGB(160, 40, 255),
        Thickness = 3,
        Transparency = 1,
    }, bhRing)

    -- VOID CENTER title
    local title = N("TextLabel", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 0),
        Size                   = UDim2.new(0, 500, 0, 60),
        Font                   = Enum.Font.GothamBold,
        Text                   = "VOID CENTER",
        TextColor3             = Color3.fromRGB(200, 150, 255),
        TextSize               = 0,
        TextTransparency       = 1,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3       = Color3.fromRGB(140, 45, 255),
        ZIndex                 = 9005,
    }, Screen)

    -- Subtitle
    local sub = N("TextLabel", {
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 50),
        Size                   = UDim2.new(0, 400, 0, 30),
        Font                   = Enum.Font.Gotham,
        Text                   = "v3.0.0",
        TextColor3             = Color3.fromRGB(140, 100, 200),
        TextSize               = 14,
        TextTransparency       = 1,
        ZIndex                 = 9005,
    }, Screen)

    -- Phase 1: Black hole expands in
    Tween(bhOuter, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 220, 0, 220)})
    task.wait(0.1)
    Tween(bhMid, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 160, 0, 160)})
    task.wait(0.1)
    Tween(bhCore, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 100, 0, 100)})
    task.wait(0.1)

    -- Phase 2: Ring stroke fades in
    local ringStroke = bhRing:FindFirstChildOfClass("UIStroke")
    if ringStroke then
        Tween(ringStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad),
            {Transparency = 0})
    end

    -- Phase 3: Title fades and grows in
    Tween(title, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextSize = 42, TextTransparency = 0})
    Tween(sub, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0})
    task.wait(0.7)

    -- Phase 4: Spin ring and warp title into black hole
    -- Rotate ring (simulate spin by oscillating size)
    task.spawn(function()
        local t = 0
        local spinConn
        spinConn = RunService.Heartbeat:Connect(function(dt)
            t = t + dt * 2
            if bhRing and bhRing.Parent then
                bhRing.Size = UDim2.new(0, 220 + math.sin(t) * 10, 0, 220 + math.cos(t) * 10)
            else
                spinConn:Disconnect()
            end
        end)
        task.wait(1.8)
        if spinConn then spinConn:Disconnect() end
    end)

    task.wait(0.5)

    -- Phase 5: Title shrinks and fades into the black hole center
    Tween(title, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {TextSize = 4, TextTransparency = 1,
         Position = UDim2.new(0.5, 0, 0.5, 0)})
    Tween(sub, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {TextTransparency = 1})
    task.wait(0.8)

    -- Phase 6: Black hole collapses
    Tween(bhRing, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)})
    Tween(bhOuter, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)})
    task.wait(0.1)
    Tween(bhMid, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)})
    task.wait(0.1)
    Tween(bhCore, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Size = UDim2.new(0, 0, 0, 0)})
    task.wait(0.4)

    -- Clean up
    pcall(function()
        bhOuter:Destroy()
        bhMid:Destroy()
        bhCore:Destroy()
        bhRing:Destroy()
        title:Destroy()
        sub:Destroy()
    end)
end)

local NHolder = N("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -316, 0, 48),
    Size     = UDim2.new(0, 300, 1, -64),
    ZIndex   = 500,
}, Screen)
N("UIListLayout", {
    SortOrder         = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
    Padding           = UDim.new(0, 6),
}, NHolder)

local nid = 0
local function Notify(title, body, kind, dur)
    kind = kind or "info"
    dur  = dur  or 6
    nid  = nid + 1
    local accent = kind == "success" and C.Green
                or kind == "warning" and C.Yellow
                or kind == "error"   and C.Red
                or kind == "gold"    and C.Gold
                or C.Accent
    local icon = kind == "success" and "+"
              or kind == "warning" and "!"
              or kind == "error"   and "x"
              or kind == "gold"    and "*"
              or "-"

    -- fixed height: 76px total - no AutomaticSize, no ClipsDescendants
    local card = N("Frame", {
        BackgroundColor3 = Color3.fromRGB(11, 3, 22),
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 76),
        LayoutOrder      = nid,
        Position         = UDim2.new(1.15, 0, 0, 0),
    }, NHolder)
    Corner(10, card)
    Stroke(accent, 1, card)

    -- Left colour bar
    local bar3 = N("Frame", {
        BackgroundColor3 = accent, BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
    }, card)
    Corner(10, bar3)

    -- Icon pill
    local ipill = N("Frame", {
        BackgroundColor3 = accent, BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 12),
        Size     = UDim2.new(0, 22, 0, 22),
    }, card)
    Corner(11, ipill)
    N("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1,0,1,0),
        Font = Enum.Font.GothamBold, Text = icon,
        TextColor3 = accent, TextSize = 12,
    }, ipill)

    -- Title
    N("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 42, 0, 10), Size = UDim2.new(1, -78, 0, 22),
        Font = Enum.Font.GothamBold, Text = title,
        TextColor3 = C.Text, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    -- Body
    N("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 34), Size = UDim2.new(1, -18, 0, 28),
        Font = Enum.Font.Gotham, Text = body,
        TextColor3 = Color3.fromRGB(175, 155, 210), TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, TextTruncate = Enum.TextTruncate.AtEnd,
    }, card)

    -- Dismiss button
    local xBtn = N("TextButton", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -26, 0, 6), Size = UDim2.new(0, 20, 0, 20),
        Font = Enum.Font.GothamBold, Text = "X",
        TextColor3 = Color3.fromRGB(100, 80, 130), TextSize = 10,
    }, card)

    -- Progress track (fixed position at bottom of fixed-height card)
    local track = N("Frame", {
        BackgroundColor3 = Color3.fromRGB(28, 12, 50), BorderSizePixel = 0,
        Position = UDim2.new(0, 3, 1, -4), Size = UDim2.new(1, -6, 0, 3),
    }, card)
    Corner(2, track)
    local prog = N("Frame", {
        BackgroundColor3 = accent, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
    }, track)
    Corner(2, prog)

    -- Animate in with bounce
    Tween(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, 0, 0, 0)})
    Tween(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)})
    -- Pulse the icon pill on arrival
    task.spawn(function()
        task.wait(0.1)
        Tween(ipill, TweenInfo.new(0.15, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 0.2})
        task.wait(0.15)
        Tween(ipill, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
            {BackgroundTransparency = 0.72})
    end)

    local alive = true
    local function dismiss()
        if not alive then return end
        alive = false
        Tween(card, TM, {Position = UDim2.new(1.15, 0, 0, 0)})
        task.delay(0.35, function() pcall(function() card:Destroy() end) end)
    end
    xBtn.MouseButton1Click:Connect(dismiss)
    task.delay(dur, dismiss)
end

-- HUD WIDGET  (draggable pill, auto-resizes to content)
-- Uses AutomaticSize so every section is exactly as wide as
-- its text — nothing ever gets cut off.

-- Outer frame: height fixed at 28, width grows automatically
local Panel = N("Frame", {
    Name                   = "VCHud",
    BackgroundColor3       = C.Panel,
    BackgroundTransparency = 1,  -- start invisible
    BorderSizePixel        = 0,
    Position               = UDim2.new(0.5, 0, 0, -40),  -- start above screen center
    AnchorPoint            = Vector2.new(0.5, 0),
    Size                   = UDim2.new(0, 0, 0, 28),
    AutomaticSize          = Enum.AutomaticSize.X,
    ZIndex                 = 200,
    Active                 = true,
}, Screen)
Corner(8, Panel)
Stroke(C.Accent, 1, Panel)

-- Animate HUD sliding down into place after startup finishes
task.delay(3.5, function()
    Tween(Panel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position               = UDim2.new(0.5, 0, 0, 8),
        BackgroundTransparency = 0.12,
    })
end)

-- Horizontal list layout — each child sits side by side
local PList = N("UIListLayout", {
    FillDirection  = Enum.FillDirection.Horizontal,
    SortOrder      = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding        = UDim.new(0, 0),
}, Panel)

-- Helper: one section (label that auto-sizes to its text)
local function PSection(text, color, bold, order)
    local f = N("Frame", {
        BackgroundTransparency = 1,
        Size           = UDim2.new(0, 0, 1, 0),
        AutomaticSize  = Enum.AutomaticSize.X,
        LayoutOrder    = order,
        ZIndex         = 201,
    }, Panel)
    local lbl = N("TextLabel", {
        BackgroundTransparency = 1,
        Size          = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        Font          = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text          = text,
        TextColor3    = color or C.TextDim,
        TextSize      = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex        = 202,
    }, f)
    -- Padding inside each section
    N("UIPadding", {
        PaddingLeft  = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, f)
    return lbl
end

-- Helper: thin vertical divider between sections
local function PDivider(order)
    N("Frame", {
        BackgroundColor3       = C.Accent,
        BackgroundTransparency = 0.55,
        BorderSizePixel        = 0,
        Size                   = UDim2.new(0, 1, 0.7, 0),
        LayoutOrder            = order,
        ZIndex                 = 202,
    }, Panel)
end

--  VOID CENTER  |  FPS  |  PING  |  TIER  [|  active...]
PSection("VOID CENTER", C.AcctBr, true, 1)
PDivider(2)
local LblFPS  = PSection("FPS --",  C.TextDim, false, 3)
PDivider(4)
local LblPing = PSection("-- ms",   C.TextDim, false, 5)
PDivider(6)
local LblTier = PSection(
    IsPremium() and "PREMIUM" or "FREE",
    IsPremium() and C.Gold    or C.AcctDk,
    true, 7)

-- Active commands section — hidden when nothing is active
local DivActive = N("Frame", {
    BackgroundColor3       = C.Accent,
    BackgroundTransparency = 0.55,
    BorderSizePixel        = 0,
    Size                   = UDim2.new(0, 1, 0.7, 0),
    LayoutOrder            = 8,
    ZIndex                 = 202,
    Visible                = false,
}, Panel)
local LblActive = N("TextLabel", {
    BackgroundTransparency = 1,
    Size          = UDim2.new(0, 0, 1, 0),
    AutomaticSize = Enum.AutomaticSize.X,
    Font          = Enum.Font.Gotham,
    Text          = "",
    TextColor3    = C.AcctBr,
    TextSize      = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder   = 9,
    ZIndex        = 202,
}, Panel)
N("UIPadding", {
    PaddingLeft  = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
}, LblActive)

-- Drag
local dragging, dragStart, startPos
Panel.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true dragStart = inp.Position startPos = Panel.Position
    end
end)
Panel.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType ~= Enum.UserInputType.MouseMovement
    and inp.UserInputType ~= Enum.UserInputType.Touch then return end
    local d = inp.Position - dragStart
    Panel.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + d.X,
        startPos.Y.Scale, startPos.Y.Offset + d.Y)
end)

-- FPS counter
local fpsBuf = {}
RunService.Heartbeat:Connect(function(dt)
    table.insert(fpsBuf, dt)
    if #fpsBuf > 20 then table.remove(fpsBuf, 1) end
    local s = 0
    for _, v in ipairs(fpsBuf) do s = s + v end
    local fps = math.floor(1 / (s / #fpsBuf))
    LblFPS.Text       = "FPS "..fps
    LblFPS.TextColor3 = fps >= 50 and C.Green or (fps >= 30 and C.Yellow or C.Red)
end)

-- Ping counter
task.spawn(function()
    while task.wait(3) do
        pcall(function()
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            LblPing.Text       = ping.."ms"
            LblPing.TextColor3 = ping < 80 and C.Green or (ping < 160 and C.Yellow or C.Red)
        end)
    end
end)

-- Active commands display — shows/hides the extra section
local function RefreshActive()
    local list = {}
    for k in pairs(Config.ActiveCmds) do table.insert(list, k) end
    table.sort(list)
    if #list == 0 then
        LblActive.Text      = ""
        DivActive.Visible   = false
    else
        LblActive.Text      = table.concat(list, "  |  ")
        DivActive.Visible   = true
        -- Pulse active text colour briefly to signal change
        Tween(LblActive, TweenInfo.new(0.1, Enum.EasingStyle.Quad),
            {TextColor3 = Color3.fromRGB(255, 255, 255)})
        task.delay(0.1, function()
            Tween(LblActive, TweenInfo.new(0.3, Enum.EasingStyle.Quad),
                {TextColor3 = C.AcctBr})
        end)
    end
end

