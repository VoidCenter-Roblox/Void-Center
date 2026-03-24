local _VC = getgenv()._VC
local LP               = _VC.LP
local Players          = _VC.Players
local RunService       = _VC.RunService
local UserInputService = _VC.UserInputService
local Config           = _VC.Config
local IsPremium        = _VC.IsPremium
local FindPlayer       = _VC.FindPlayer
local PStr             = _VC.PStr
local Reg              = _VC.Reg

local function Notify(...)        return _VC.Notify(...)        end
local function RefreshActive(...) return _VC.RefreshActive(...) end

-- GOTO
Reg("goto", {"tp","go"}, "Teleport to a player  e.g. goto Player1", false, function(a)
    local t = FindPlayer(a[1])
    if not t then Notify("Goto", "Not found: "..(a[1] or "?"), "error") return end
    local mr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr = t.Character  and t.Character:FindFirstChild("HumanoidRootPart")
    if mr and tr then
        mr.CFrame = tr.CFrame + Vector3.new(3,0,0)
        Notify("Goto", "--> "..PStr(t), "success")
    else
        Notify("Goto", "Target has no character", "error")
    end
end)

-- WALKSPEED / speed <number> sets speed, speed alone resets
Reg("walkspeed", {"ws","speed"}, "Set walk speed  e.g. speed 30  |  speed to reset", false, function(a)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local n = tonumber(a[1])
    if n then
        h.WalkSpeed = n
        Notify("Speed", "Walk speed -> "..n, "success")
    else
        h.WalkSpeed = 16
        Notify("Speed", "Reset to 16", "info")
    end
end)

-- JUMPPOWER / jump <number> sets power, jump alone resets
Reg("jumppower", {"jp","jump"}, "Set jump power  e.g. jump 80  |  jump to reset", false, function(a)
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if not h then return end
    local n = tonumber(a[1])
    if n then
        h.JumpPower = n
        Notify("Jump", "Jump power -> "..n, "success")
    else
        h.JumpPower = 50
        Notify("Jump", "Reset to 50", "info")
    end
end)

-- RESETSTATS
Reg("resetstats", {"rss"}, "Reset speed and jump to default", false, function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = 16
        h.JumpPower = 50
        Notify("ResetStats", "Speed and jump reset to default", "info")
    end
end)

-- SAFE PLATFORM
local safePlatform = nil
local SAFE_POS     = Vector3.new(0, 5000, 0)

local function BuildSafePlatform()
    local existing = workspace:FindFirstChild("VoidSafePlatform")
    if existing then safePlatform = existing return end
    local model = Instance.new("Model")
    model.Name = "VoidSafePlatform"
    local floor = Instance.new("Part")
    floor.Name      = "Floor"
    floor.Size      = Vector3.new(60, 2, 60)
    floor.Position  = SAFE_POS
    floor.Anchored  = true
    floor.CanCollide = true
    floor.Material  = Enum.Material.SmoothPlastic
    floor.Color     = Color3.fromRGB(80, 0, 120)
    floor.Parent    = model
    local border = Instance.new("Part")
    border.Name      = "Border"
    border.Size      = Vector3.new(64, 1, 64)
    border.Position  = SAFE_POS - Vector3.new(0, 0.5, 0)
    border.Anchored  = true
    border.CanCollide = false
    border.Material  = Enum.Material.SmoothPlastic
    border.Color     = Color3.fromRGB(10, 0, 20)
    border.Parent    = model
    local light = Instance.new("SurfaceLight")
    light.Brightness = 3
    light.Color      = Color3.fromRGB(150, 0, 255)
    light.Range      = 40
    light.Face       = Enum.NormalId.Top
    light.Parent     = floor
    local sign = Instance.new("Part")
    sign.Name     = "Sign"
    sign.Size     = Vector3.new(8, 3, 0.5)
    sign.Position = SAFE_POS + Vector3.new(0, 2.5, -28)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color    = Color3.fromRGB(30, 0, 60)
    sign.Parent   = model
    local sg  = Instance.new("SurfaceGui") sg.Face = Enum.NormalId.Front sg.Parent = sign
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0) lbl.BackgroundColor3 = Color3.fromRGB(30,0,60)
    lbl.TextColor3 = Color3.fromRGB(200,100,255) lbl.Font = Enum.Font.GothamBold
    lbl.Text = "  VoidCenter Safe Zone  " lbl.TextScaled = true lbl.Parent = sg
    model.Parent = workspace model.PrimaryPart = floor safePlatform = model
end

local safeReturnCF = nil
Reg("safe", {"sz"}, "Teleport to safe platform  |  type again to return", false, function()
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end
    local atSafe = math.abs(r.Position.Y - SAFE_POS.Y) < 200
    if atSafe and safeReturnCF then
        r.CFrame = safeReturnCF
        safeReturnCF = nil
        Notify("Safe Zone", "Returned to previous location", "info", 3)
    else
        safeReturnCF = r.CFrame
        BuildSafePlatform()
        r.CFrame = CFrame.new(SAFE_POS + Vector3.new(math.random(-20,20), 4, math.random(-20,20)))
        Notify("Safe Zone", "At safe platform  |  type safe again to return", "success", 4)
    end
end)

-- RESET
Reg("reset", {"rme","r"}, "Reset your character", false, function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 Notify("Reset", "Resetting...", "info", 2) end
end)

-- ANTI AFK
Reg("antiafk", {"aafk"}, "Toggle anti-AFK", false, function()
    if Config.ActiveCmds["AntiAFK"] then
        Config.ActiveCmds["AntiAFK"] = nil
        RefreshActive()
        Notify("Anti-AFK", "Disabled", "info")
    else
        Config.ActiveCmds["AntiAFK"] = true
        RefreshActive()
        Notify("Anti-AFK", "Enabled", "success")
        task.spawn(function()
            local VU = game:GetService("VirtualUser")
            while Config.ActiveCmds["AntiAFK"] do
                task.wait(60)
                if Config.ActiveCmds["AntiAFK"] then
                    pcall(function() VU:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
                    task.wait(1)
                    pcall(function() VU:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
                end
            end
        end)
    end
end)

-- ANTI FLING
local aflConn = nil
Reg("antifling", {"afl"}, "Toggle anti-fling", false, function()
    if Config.ActiveCmds["AntiFling"] then
        Config.ActiveCmds["AntiFling"] = nil
        if aflConn then aflConn:Disconnect() aflConn = nil end
        RefreshActive()
        pcall(function()
            local chr = LP.Character
            if chr then
                for _, p in ipairs(chr:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end)
        Notify("Anti-Fling", "Disabled", "info")
    else
        Config.ActiveCmds["AntiFling"] = true
        RefreshActive()
        Notify("Anti-Fling", "Enabled", "success")
        aflConn = RunService.Stepped:Connect(function()
            pcall(function()
                local chr = LP.Character
                if not chr then return end
                for _, p in ipairs(chr:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        end)
    end
end)

-- ANTI VOID
Reg("antivoid", {"av"}, "Toggle anti-void", false, function()
    if Config.ActiveCmds["AntiVoid"] then
        Config.ActiveCmds["AntiVoid"] = nil
        RefreshActive()
        Notify("Anti-Void", "Disabled", "info")
    else
        Config.ActiveCmds["AntiVoid"] = true
        RefreshActive()
        local voidKillY = -500
        pcall(function() voidKillY = workspace.FallenPartsDestroyHeight end)
        local triggerY = voidKillY + 30
        local safeY    = 100
        pcall(function()
            local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r then safeY = math.max(r.Position.Y + 10, 10) end
        end)
        Notify("Anti-Void", "Enabled  (trigger Y < "..math.floor(triggerY)..")", "success")
        local cooldown = false
        task.spawn(function()
            while Config.ActiveCmds["AntiVoid"] do
                task.wait(0.04)
                pcall(function()
                    local chr = LP.Character
                    local r   = chr and chr:FindFirstChild("HumanoidRootPart")
                    local h   = chr and chr:FindFirstChildOfClass("Humanoid")
                    if not r or not h or cooldown then return end
                    if h.Health <= 0 then return end
                    if r.Position.Y < triggerY then
                        cooldown = true
                        h.Health = h.MaxHealth
                        r.CFrame = CFrame.new(r.Position.X, safeY, r.Position.Z)
                        Notify("Anti-Void", "Saved!", "success", 3)
                        task.wait(1.5)
                        cooldown = false
                        pcall(function()
                            local chr2 = LP.Character
                            local r2   = chr2 and chr2:FindFirstChild("HumanoidRootPart")
                            if r2 then safeY = math.max(r2.Position.Y + 10, 10) end
                        end)
                    end
                end)
            end
        end)
    end
end)

-- SPECTATE
Reg("spectate", {"spec","view"}, "Spectate a player  e.g. spectate Player1  |  spectate stop", false, function(a)
    local cam = workspace.CurrentCamera
    if not a[1] or a[1]:lower() == "stop" then
        cam.CameraType    = Enum.CameraType.Custom
        cam.CameraSubject = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        Config.ActiveCmds["Spectating"] = nil
        RefreshActive()
        Notify("Spectate", "Camera restored", "info", 3)
        return
    end
    local t  = FindPlayer(a[1])
    if not t then Notify("Spectate", "Player not found: "..(a[1] or "?"), "error") return end
    if t == LP then Notify("Spectate", "Can't spectate yourself", "warning") return end
    local th = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
    if not th then Notify("Spectate", PStr(t).." has no character", "error") return end
    cam.CameraType    = Enum.CameraType.Custom
    cam.CameraSubject = th
    Config.ActiveCmds["Spectating"] = true
    RefreshActive()
    Notify("Spectate", "Viewing "..PStr(t).."  |  spectate stop to exit", "success", 4)
    t.CharacterAdded:Connect(function(char)
        if not Config.ActiveCmds["Spectating"] then return end
        task.wait(0.5)
        local newHum = char:FindFirstChildOfClass("Humanoid")
        if newHum then cam.CameraSubject = newHum end
    end)
end)

-- REJOIN
Reg("rejoin", {"rj"}, "Rejoin the current game", false, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)

-- LOOPTP
local loopTpOn     = false
local loopTpTarget = nil

Reg("looptp", {"ltp"}, "Loop teleport to a player  e.g. looptp Player1  |  looptp stop", false, function(a)
    if not a[1] or a[1]:lower() == "stop" then
        loopTpOn = false loopTpTarget = nil
        Config.ActiveCmds["LoopTP"] = nil RefreshActive()
        Notify("LoopTP", "Stopped", "info") return
    end
    local t = FindPlayer(a[1])
    if not t then Notify("LoopTP", "Player not found: "..(a[1] or "?"), "error") return end
    loopTpOn = true loopTpTarget = t
    Config.ActiveCmds["LoopTP"] = t.Name RefreshActive()
    Notify("LoopTP", "Looping to "..t.DisplayName.."  |  looptp stop to cancel", "success", 4)
    task.spawn(function()
        while loopTpOn and loopTpTarget do
            pcall(function()
                local r  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local tr = loopTpTarget.Character and loopTpTarget.Character:FindFirstChild("HumanoidRootPart")
                if r and tr then
                    r.CFrame = tr.CFrame * CFrame.new(math.random(-3,3), 0, math.random(-3,3))
                end
            end)
            task.wait(0.1)
        end
    end)
end)

-- INFINITE JUMP
local ijOn   = false
local ijConn = nil
Reg("infinitejump", {"ij"}, "Toggle infinite jump", false, function()
    if ijOn then
        ijOn = false
        Config.ActiveCmds["InfJump"] = nil RefreshActive()
        if ijConn then ijConn:Disconnect() ijConn = nil end
        Notify("Infinite Jump", "Off", "info")
    else
        ijOn = true
        Config.ActiveCmds["InfJump"] = true RefreshActive()
        ijConn = UserInputService.JumpRequest:Connect(function()
            if not ijOn then return end
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
        Notify("Infinite Jump", "On  —  hold Space to keep jumping", "success")
    end
end)

-- ORBIT
local orbitOn    = false
local orbitParts = {}
local orbitConn  = nil

local function StopOrbit()
    orbitOn = false
    Config.ActiveCmds["Orbit"] = nil RefreshActive()
    if orbitConn then orbitConn:Disconnect() orbitConn = nil end
    for _, data in ipairs(orbitParts) do
        pcall(function()
            local bp = data.part:FindFirstChild("VCOrbitBP")
            if bp then bp:Destroy() end
        end)
    end
    orbitParts = {}
    Notify("Orbit", "Off", "info")
end

Reg("orbit", {"orb"}, "Pull nearby objects into orbit  e.g. orbit 30  |  orbit off", false, function(a)
    if orbitOn or (a[1] and a[1]:lower() == "off") then StopOrbit() return end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then Notify("Orbit", "No character", "error") return end
    local radius    = tonumber(a[1]) or 30
    local collected = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            local isChar = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and obj:IsDescendantOf(p.Character) then isChar = true break end
            end
            if not isChar then
                local dist = (obj.Position - root.Position).Magnitude
                if dist <= radius then
                    local bp = Instance.new("BodyPosition")
                    bp.Name = "VCOrbitBP" bp.MaxForce = Vector3.new(1e5,1e5,1e5)
                    bp.Position = obj.Position bp.P = 1e4 bp.D = 500 bp.Parent = obj
                    table.insert(orbitParts, {
                        part   = obj,
                        angle  = math.random() * math.pi * 2,
                        radius = math.random(12, 16),
                        height = math.random(-2, 3),
                        speed  = math.random(80, 150) / 100,
                    })
                    collected = collected + 1
                end
            end
        end
    end
    if collected == 0 then Notify("Orbit", "No objects found within "..radius.." studs", "warning") return end
    orbitOn = true Config.ActiveCmds["Orbit"] = true RefreshActive()
    Notify("Orbit", collected.." objects orbiting  |  orbit off to stop", "success", 4)
    local scanTimer = 0
    orbitConn = RunService.Heartbeat:Connect(function(dt)
        if not orbitOn then return end
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local center = r.Position + Vector3.new(0, 2, 0)
        scanTimer = scanTimer + dt
        if scanTimer >= 2 then
            scanTimer = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Anchored then
                    local already = false
                    for _, d in ipairs(orbitParts) do if d.part == obj then already = true break end end
                    if not already then
                        local isChar = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character and obj:IsDescendantOf(p.Character) then isChar = true break end
                        end
                        if not isChar then
                            local dist = (obj.Position - center).Magnitude
                            if dist <= radius then
                                local bp = Instance.new("BodyPosition")
                                bp.Name = "VCOrbitBP" bp.MaxForce = Vector3.new(1e5,1e5,1e5)
                                bp.Position = obj.Position bp.P = 1e4 bp.D = 500 bp.Parent = obj
                                table.insert(orbitParts, {
                                    part = obj, angle = math.random()*math.pi*2,
                                    radius = math.random(12,16), height = math.random(-2,3),
                                    speed = math.random(80,150)/100,
                                })
                            end
                        end
                    end
                end
            end
        end
        for i = #orbitParts, 1, -1 do
            local data = orbitParts[i]
            pcall(function()
                if not data.part or not data.part.Parent or data.part.Anchored then
                    local bp = data.part and data.part:FindFirstChild("VCOrbitBP")
                    if bp then bp:Destroy() end
                    table.remove(orbitParts, i) return
                end
                data.angle = data.angle + dt * data.speed
                local target = center + Vector3.new(
                    math.cos(data.angle) * data.radius,
                    data.height,
                    math.sin(data.angle) * data.radius)
                local bp = data.part:FindFirstChild("VCOrbitBP")
                if bp then bp.Position = target end
            end)
        end
        if #orbitParts == 0 then StopOrbit() end
    end)
end)

-- HELP
Reg("help", {"cmds","commands"}, "List all commands", false, function()
    Notify("Commands",
        "fly / noclip / esp / goto / safe / reset\nwalkspeed / jumppower / resetstats\nantiafk / antifling / antivoid\nspectate / rejoin / looptp / infinitejump / orbit",
        "info", 10)
    if IsPremium() then
        task.wait(0.5)
        Notify("Premium (type in Roblox chat)",
            ".fling .bring .bringall .freeze .unfreeze\n.kill .kick .unkick .chat .spin\n.explode .follow .unfollow .tp2me .untp2me",
            "gold", 10)
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if ijOn then
        if ijConn then ijConn:Disconnect() ijConn = nil end
        ijConn = UserInputService.JumpRequest:Connect(function()
            if not ijOn then return end
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
    if loopTpOn and loopTpTarget then
        task.spawn(function()
            while loopTpOn and loopTpTarget do
                pcall(function()
                    local r  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    local tr = loopTpTarget.Character and loopTpTarget.Character:FindFirstChild("HumanoidRootPart")
                    if r and tr then
                        r.CFrame = tr.CFrame * CFrame.new(math.random(-3,3), 0, math.random(-3,3))
                    end
                end)
                task.wait(0.1)
            end
        end)
    end
end)
