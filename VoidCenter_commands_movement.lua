local _VC = getgenv()._VC
local LP               = _VC.LP
local Players          = _VC.Players
local RunService       = _VC.RunService
local UserInputService = _VC.UserInputService
local TweenService     = _VC.TweenService
local MarketplaceService = _VC.MarketplaceService
local Debris           = _VC.Debris
local Camera           = _VC.Camera
local C                = _VC.C
local TF               = _VC.TF
local TM               = _VC.TM
local N                = _VC.N
local Tween            = _VC.Tween
local Corner           = _VC.Corner
local Stroke           = _VC.Stroke
local Pad              = _VC.Pad
local Config           = _VC.Config
local IsPremium        = _VC.IsPremium
local freeIds          = _VC.freeIds
local premIds          = _VC.premIds
local FindPlayer       = _VC.FindPlayer
local PStr             = _VC.PStr
local Reg              = _VC.Reg
local Screen           = _VC.Screen
local vcUsers          = _VC.vcUsers
local IsVoidUser       = _VC.IsVoidUser
local IsWhitelisted    = _VC.IsWhitelisted

-- Use _VC.Notify and _VC.RefreshActive so we always get the
-- real GUI version after ui.lua loads, not the stub
local function Notify(...)        return _VC.Notify(...)        end
local function RefreshActive(...) return _VC.RefreshActive(...) end

local flyOn   = false
local flyBV   = nil
local flyBG   = nil
local flyConn = nil

local function StopFly()
    if not flyOn then return end
    flyOn = false
    Config.ActiveCmds["Fly"] = nil
    RefreshActive()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    pcall(function() if flyBV and flyBV.Parent then flyBV:Destroy() end end) flyBV = nil
    pcall(function() if flyBG and flyBG.Parent then flyBG:Destroy() end end) flyBG = nil
    pcall(function()
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end)
    Notify("Fly", "Landed", "info")
end

local function StartFly()
    if flyOn then StopFly() return end
    local c    = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local hum  = c and c:FindFirstChildOfClass("Humanoid")
    if not root or not hum then Notify("Fly", "No character", "error") return end

    flyOn = true
    Config.ActiveCmds["Fly"] = true
    RefreshActive()
    hum.PlatformStand = true

    -- BodyGyro locks your character's rotation to the camera
    flyBG             = Instance.new("BodyGyro", root)
    flyBG.P           = 9e4
    flyBG.MaxTorque   = Vector3.new(9e9, 9e9, 9e9)
    flyBG.CFrame      = root.CFrame

    -- BodyVelocity moves you in the direction you're looking
    flyBV             = Instance.new("BodyVelocity", root)
    flyBV.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
    flyBV.Velocity    = Vector3.zero

    flyConn = RunService.RenderStepped:Connect(function()
        local chr = LP.Character
        if not chr then return end
        local rt  = chr:FindFirstChild("HumanoidRootPart")
        if not rt or not flyBV or not flyBV.Parent then return end

        local cam   = workspace.CurrentCamera
        local speed = Config.FlySpeed
        local move  = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)
        or UserInputService:IsKeyDown(Enum.KeyCode.ButtonA) then
            move = move + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
        or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            move = move - Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then speed = speed * 2.5 end

        flyBV.Velocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
        flyBG.CFrame   = cam.CFrame  -- character faces where you look
    end)

    Notify("Fly", "WASD to move  Space/Ctrl up-down  E to boost  fly again to land", "success")
end

Reg("fly",      {"f"},  "Toggle fly", false, function() StartFly() end)
Reg("flyspeed", {"fs"}, "Set fly speed  e.g. flyspeed 80", false, function(a)
    local n = tonumber(a[1])
    if n and n > 0 then
        Config.FlySpeed = n
        Notify("Fly", "Speed set to " .. n, "success")
    else
        Notify("Fly", "Usage: flyspeed <number>", "warning")
    end
end)

local ncOn   = false
local ncConn

local function StopNoclip()
    if not ncOn then return end
    ncOn = false
    Config.ActiveCmds["Noclip"] = nil
    RefreshActive()
    if ncConn then ncConn:Disconnect() ncConn = nil end
    local c = LP.Character
    if c then
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = true end
        end
    end
    Notify("Noclip","Collision restored","info")
end

local function StartNoclip()
    if ncOn then StopNoclip() return end
    ncOn = true
    Config.ActiveCmds["Noclip"] = true
    RefreshActive()
    ncConn = RunService.Stepped:Connect(function()
        if not ncOn then return end
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
    Notify("Noclip","Phase through walls - run again to stop","success")
end

Reg("noclip", {"nc"}, "Toggle noclip / phase through walls", false, function() StartNoclip() end)

-- ESP - always maintains all players, auto-updates
local espOn   = false
local espData = {}   -- [player] = { hl, bill, hconn }

local function RemoveESPFor(player)
    if espData[player] then
        pcall(function() espData[player].hl:Destroy()   end)
        pcall(function() espData[player].bill:Destroy() end)
        if espData[player].hconn then
            pcall(function() espData[player].hconn:Disconnect() end)
        end
        espData[player] = nil
    end
end

local function BuildESPFor(player)
    if player == LP then return end
    RemoveESPFor(player)

    local c    = player.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if not c or not root then return end

    -- Box highlight
    local hl = Instance.new("Highlight")
    hl.FillColor           = Color3.fromRGB(55,0,110)
    hl.OutlineColor        = Color3.fromRGB(160,50,255)
    hl.FillTransparency    = 0.80
    hl.OutlineTransparency = 0.0
    hl.Adornee             = c
    hl.Parent              = c

    -- Names + health billboard
    local bill = Instance.new("BillboardGui")
    bill.Name         = "VESP_"..player.Name
    bill.Size         = UDim2.new(0,200,0,68)
    bill.StudsOffset  = Vector3.new(0,3.5,0)
    bill.AlwaysOnTop  = true
    bill.Parent       = root

    N("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,28),
        Font = Enum.Font.GothamBold,
        Text = player.DisplayName,
        TextColor3 = Color3.fromRGB(215,165,255),
        TextSize = 20,
        TextStrokeTransparency = 0.2, TextStrokeColor3 = C.Black,
    }, bill)
    N("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0,0,0,27), Size = UDim2.new(1,0,0,20),
        Font = Enum.Font.Gotham, Text = "@"..player.Name,
        TextColor3 = Color3.fromRGB(185,135,255), TextSize = 16,
        TextStrokeTransparency = 0.3, TextStrokeColor3 = C.Black,
    }, bill)

    -- Health bar
    local hbg = N("Frame", {
        BackgroundColor3 = Color3.fromRGB(18,0,36), BorderSizePixel = 0,
        Position = UDim2.new(1,6,0.06,0), Size = UDim2.new(0,5,0.88,0),
    }, bill)
    Corner(4, hbg)
    local hfill = N("Frame", {
        AnchorPoint = Vector2.new(0,1),
        BackgroundColor3 = Color3.fromRGB(120,40,255), BorderSizePixel = 0,
        Position = UDim2.new(0,0,1,0), Size = UDim2.new(1,0,1,0),
    }, hbg)
    Corner(4, hfill)

    local hum   = c:FindFirstChildOfClass("Humanoid")
    local hconn = nil
    if hum then
        local function UpdateHP(hp)
            if not espData[player] then return end
            local pct = math.clamp(hp / math.max(hum.MaxHealth,1), 0, 1)
            Tween(hfill, TF, {
                Size             = UDim2.new(1,0,pct,0),
                Position         = UDim2.new(0,0,1-pct,0),
                BackgroundColor3 = Color3.fromRGB(
                    math.floor(255*(1-pct)),
                    math.floor(180*pct),
                    math.floor(255*pct)
                ),
            })
        end
        UpdateHP(hum.Health)
        hconn = hum.HealthChanged:Connect(UpdateHP)
    end

    espData[player] = {hl = hl, bill = bill, hconn = hconn}
end

task.spawn(function()
    while true do
        task.wait(1.5)
        if not espOn then continue end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local c    = p.Character
            local root = c and c:FindFirstChild("HumanoidRootPart")

            if not c or not root then
                RemoveESPFor(p)
            elseif not espData[p]
                or not espData[p].hl
                or not espData[p].hl.Parent
                or espData[p].hl.Adornee ~= c then
                task.spawn(BuildESPFor, p)
            end
        end
        -- Remove entries for players who left
        for p in pairs(espData) do
            if not p or not p.Parent then
                RemoveESPFor(p)
            end
        end
    end
end)

-- Instant rebuild on character spawn
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1.2)
        if espOn then BuildESPFor(p) end
    end)
end)
Players.PlayerRemoving:Connect(function(p) RemoveESPFor(p) end)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then
        p.CharacterAdded:Connect(function()
            task.wait(1.2)
            if espOn then BuildESPFor(p) end
        end)
    end
end

local function EnableESP()
    espOn = true
    Config.ActiveCmds["ESP"] = true
    RefreshActive()
    -- Spawn each build separately so instance creation doesn't freeze the game
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(BuildESPFor, p)
    end
    Notify("ESP","Tracking "..tostring(#Players:GetPlayers()-1).." player(s) - auto-updates","success")
end

local function DisableESP()
    espOn = false
    Config.ActiveCmds["ESP"] = nil
    RefreshActive()
    for p in pairs(espData) do RemoveESPFor(p) end
    Notify("ESP","Disabled","info")
end

Reg("esp", {"e"}, "Toggle ESP (box - names - health - auto-updates)", false, function()
    if espOn then DisableESP() else EnableESP() end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if flyOn then flyOn = false task.wait(0.2) StartFly() end
    if ncOn  then ncOn  = false task.wait(0.1) StartNoclip() end
    if espOn then
        task.wait(1.2)
        for _, p in ipairs(Players:GetPlayers()) do task.spawn(BuildESPFor, p) end
    end
end)
