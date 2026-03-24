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

local function SendChat(msg)
    local sent = false
    pcall(function()
        local tcs = game:GetService("TextChatService")
        if tcs.ChatVersion == Enum.ChatVersion.TextChatService then
            local ch = tcs.TextChannels:FindFirstChild("RBXGeneral")
            if ch then ch:SendAsync(msg) sent = true end
        end
    end)
    if not sent then pcall(function()
        local ev  = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local sr  = ev and ev:FindFirstChild("SayMessageRequest")
        if sr then sr:FireServer(msg, "All") end
    end) end
end

-- Premium user types .control <player> in chat to start.
-- Their script reads WASD and sends .ctrlmove x z signals every 0.1s.
-- .release ends it on the target's side.
local controlTarget   = nil
local controlConn     = nil
local controlChatConn = nil

-- Listen for .control and .release typed in chat by THIS premium user
local function StartControlListener()
    local function onMsg(msg)
        if not IsPremium() then return end
        local clean = msg:match("^%S+:%s*(.+)$") or msg
        if clean:sub(1,1) ~= "." then return end
        local words = {}
        for w in clean:sub(2):gmatch("%S+") do table.insert(words, w) end
        local cmd = (words[1] or ""):lower()

        if cmd == "control" or cmd == "ctrl" then
            local targetName = words[2]
            if not targetName then return end
            local t = FindPlayer(targetName)
            if not t then Notify("Control", "Player not found: "..targetName, "error") return end
            -- Stop any existing control loop
            if controlConn then controlConn:Disconnect() controlConn = nil end
            controlTarget = t
            Config.ActiveCmds["Controlling"] = t.Name RefreshActive()
            Notify("Control", "Controlling "..t.DisplayName.."  |  .release to stop", "warning", 5)
            -- Start WASD loop — sends a chat signal every 0.15s (throttled)
            controlConn = task.spawn(function()
                while controlTarget do
                    local x, z = 0, 0
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up)    then z = z - 1 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down)  then z = z + 1 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)  then x = x - 1 end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then x = x + 1 end
                    SendChat(".ctrlmove "..controlTarget.Name.." "..x.." "..z)
                    task.wait(0.15)
                end
            end)

        elseif cmd == "release" then
            -- Setting controlTarget to nil stops the task.spawn loop naturally
            controlTarget = nil
            controlConn   = nil
            Config.ActiveCmds["Controlling"] = nil RefreshActive()
            Notify("Control", "Control released", "info", 3)
        end
    end

    -- Hook both chat systems
    pcall(function()
        local tcs = game:GetService("TextChatService")
        tcs.MessageReceived:Connect(function(msg)
            if msg.TextSource and msg.TextSource.UserId == LP.UserId then
                onMsg(msg.Text)
            end
        end)
    end)
    LP.Chatted:Connect(onMsg)
end

if IsPremium() then
    StartControlListener()
end

-- .spin <player>  — handled in detection.lua via dot-command
-- We just register it here so it shows in help
Reg("spin_info", {}, "Premium: .spin <player> in chat", true, function()
    Notify("Spin [P]", "Type .spin <player> in Roblox chat", "gold")
end)

Reg("explode_info", {}, "Premium: .explode <player> in chat", true, function()
    Notify("Explode [P]", "Type .explode <player> in Roblox chat", "gold")
end)

Reg("follow_info", {}, "Premium: .follow <player> / .unfollow in chat", true, function()
    Notify("Follow [P]", "Type .follow <player> in Roblox chat", "gold")
end)

Reg("tp2me_info", {}, "Premium: .tp2me <player> / .tp2me <player> stop in chat", true, function()
    Notify("TP2Me [P]", "Type .tp2me <player> in Roblox chat", "gold")
end)

local loopTpOn     = false
local loopTpTarget = nil

Reg("looptp", {"ltp"}, "Loop teleport to a player  e.g. looptp Player1 | looptp stop", false, function(a)
    if not a[1] or a[1]:lower() == "stop" then
        loopTpOn     = false
        loopTpTarget = nil
        Config.ActiveCmds["LoopTP"] = nil
        RefreshActive()
        Notify("LoopTP", "Stopped", "info")
        return
    end
    local t = FindPlayer(a[1])
    if not t then Notify("LoopTP", "Player not found: "..(a[1] or "?"), "error") return end
    loopTpOn     = true
    loopTpTarget = t
    Config.ActiveCmds["LoopTP"] = t.Name
    RefreshActive()
    Notify("LoopTP", "Looping to "..t.DisplayName.."  |  looptp stop to cancel", "success", 4)
    task.spawn(function()
        while loopTpOn and loopTpTarget do
            pcall(function()
                local r  = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                local tr = loopTpTarget.Character and loopTpTarget.Character:FindFirstChild("HumanoidRootPart")
                if r and tr then
                    r.CFrame = tr.CFrame * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3))
                end
            end)
            task.wait(0.1)
        end
    end)
end)

local vspamOn   = false
local vspamConn = nil

Reg("voidspam", {"vs"}, "Toggle void spam", false, function()
    if vspamOn then
        vspamOn = false
        Config.ActiveCmds["VoidSpam"] = nil
        RefreshActive()
        if vspamConn then vspamConn:Disconnect() vspamConn = nil end
        -- Restore camera
        pcall(function()
            local cam = workspace.CurrentCamera
            cam.CameraType = Enum.CameraType.Custom
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then cam.CameraSubject = hum end
        end)
        Notify("Void Spam", "Off", "info")
        return
    end
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not r then Notify("Void Spam", "No character", "error") return end
    vspamOn = true
    Config.ActiveCmds["VoidSpam"] = true
    RefreshActive()
    Notify("Void Spam", "On  —  type again to stop", "success")

    -- Lock camera to character so it stays on the map while body flickers
    local cam = workspace.CurrentCamera
    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    cam.CameraType    = Enum.CameraType.Custom
    if hum then cam.CameraSubject = hum end

    local inVoid = false
    local savedCF = r.CFrame

    vspamConn = RunService.Heartbeat:Connect(function()
        if not vspamOn then return end
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if inVoid then
            -- Return to saved position so humanoid can process movement
            root.CFrame = savedCF
            inVoid = false
        else
            -- Save where we are (includes any movement made while visible)
            savedCF = root.CFrame
            root.CFrame = CFrame.new(savedCF.X, -1e4, savedCF.Z)
            inVoid = true
        end
    end)
end)

-- Constantly resets health to max and zeroes out any knockback
-- velocity every heartbeat — taken from sniper bot health logic
local immortalOn   = false
local immortalConn = nil

Reg("immortal", {"imm"}, "Toggle immortal mode (constant max health + zero knockback)", false, function()
    if immortalOn then
        immortalOn = false
        Config.ActiveCmds["Immortal"] = nil
        RefreshActive()
        if immortalConn then immortalConn:Disconnect() immortalConn = nil end
        Notify("Immortal", "Off", "info")
        return
    end
    immortalOn = true
    Config.ActiveCmds["Immortal"] = true
    RefreshActive()
    Notify("Immortal", "On  —  health locked to max, knockback zeroed", "success")
    immortalConn = RunService.Heartbeat:Connect(function()
        if not immortalOn then return end
        local c   = LP.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not c or not hum then return end
        -- Lock health to max
        if hum.Health > 0 then
            hum.Health = hum.MaxHealth
        end
        -- Zero out any fling/knockback velocity
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > 50 then
                hrp.AssemblyLinearVelocity  = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end)

local orbitOn    = false
local orbitParts = {}
local orbitConn  = nil

local function StopOrbit()
    orbitOn = false
    Config.ActiveCmds["Orbit"] = nil
    RefreshActive()
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

Reg("orbit", {"orb"}, "Pull nearby objects into orbit  e.g. orbit 30 | orbit off", false, function(a)
    if orbitOn or (a[1] and a[1]:lower() == "off") then
        StopOrbit() return
    end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then Notify("Orbit", "No character", "error") return end

    local radius    = tonumber(a[1]) or 30
    local collected = 0

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj.Anchored then
            local isChar = false
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character and obj:IsDescendantOf(p.Character) then
                    isChar = true break
                end
            end
            if not isChar then
                local dist = (obj.Position - root.Position).Magnitude
                if dist <= radius then
                    local bp = Instance.new("BodyPosition")
                    bp.Name      = "VCOrbitBP"
                    bp.MaxForce  = Vector3.new(1e5, 1e5, 1e5)
                    bp.Position  = obj.Position
                    bp.P         = 1e4
                    bp.D         = 500
                    bp.Parent    = obj
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

    if collected == 0 then
        Notify("Orbit", "No objects found within "..radius.." studs", "warning") return
    end

    orbitOn = true
    Config.ActiveCmds["Orbit"] = true
    RefreshActive()
    Notify("Orbit", collected.." objects orbiting  |  orbit off to stop", "success", 4)

    local scanTimer = 0
    orbitConn = RunService.Heartbeat:Connect(function(dt)
        if not orbitOn then return end
        local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not r then return end
        local center = r.Position + Vector3.new(0, 2, 0)

        -- Pick up new objects every 2s as you walk around
        scanTimer = scanTimer + dt
        if scanTimer >= 2 then
            scanTimer = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj.Anchored then
                    local already = false
                    for _, d in ipairs(orbitParts) do
                        if d.part == obj then already = true break end
                    end
                    if not already then
                        local isChar = false
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p.Character and obj:IsDescendantOf(p.Character) then
                                isChar = true break
                            end
                        end
                        if not isChar then
                            local dist = (obj.Position - center).Magnitude
                            if dist <= radius then
                                local bp = Instance.new("BodyPosition")
                                bp.Name     = "VCOrbitBP"
                                bp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                                bp.Position = obj.Position
                                bp.P        = 1e4
                                bp.D        = 500
                                bp.Parent   = obj
                                table.insert(orbitParts, {
                                    part   = obj,
                                    angle  = math.random() * math.pi * 2,
                                    radius = math.random(12, 16),
                                    height = math.random(-2, 3),
                                    speed  = math.random(80, 150) / 100,
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
                    table.remove(orbitParts, i)
                    return
                end
                data.angle = data.angle + dt * data.speed
                local target = center + Vector3.new(
                    math.cos(data.angle) * data.radius,
                    data.height,
                    math.sin(data.angle) * data.radius
                )
                data.part:FindFirstChild("VCOrbitBP").Position = target
            end)
        end

        if #orbitParts == 0 then StopOrbit() end
    end)
end)
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

LP.CharacterAdded:Connect(function()
    task.wait(1)
    if godOn then godOn = false task.wait(0.3) StartGod() end
    if immortalOn then
        if immortalConn then immortalConn:Disconnect() immortalConn = nil end
        immortalConn = RunService.Heartbeat:Connect(function()
            if not immortalOn then return end
            local c   = LP.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            if not c or not hum then return end
            if hum.Health > 0 then hum.Health = hum.MaxHealth end
            if hrp then
                local vel = hrp.AssemblyLinearVelocity
                if vel.Magnitude > 50 then
                    hrp.AssemblyLinearVelocity  = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end)
    end
    if vspamOn then
        if vspamConn then vspamConn:Disconnect() vspamConn = nil end
        local inVoid2, savedCF2 = false, CFrame.new()
        vspamConn = RunService.Heartbeat:Connect(function()
            if not vspamOn then return end
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if inVoid2 then
                root.CFrame = savedCF2
                inVoid2 = false
            else
                savedCF2 = root.CFrame
                root.CFrame = CFrame.new(savedCF2.X, -1e4, savedCF2.Z)
                inVoid2 = true
            end
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
    if ijOn then
        if ijConn then ijConn:Disconnect() ijConn = nil end
        ijConn = UserInputService.JumpRequest:Connect(function()
            if not ijOn then return end
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    end
end)
