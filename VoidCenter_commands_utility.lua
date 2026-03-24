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

Reg("goto", {"tp","go"}, "Teleport to player  e.g. goto Player1 or goto DisplayName", false, function(a)
    local t = FindPlayer(a[1])
    if not t then Notify("Goto","Not found: "..(a[1] or "?"),"error") return end
    local mr = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tr = t.Character  and t.Character:FindFirstChild("HumanoidRootPart")
    if mr and tr then
        mr.CFrame = tr.CFrame + Vector3.new(3,0,0)
        Notify("Goto","--> "..PStr(t),"success")
    else
        Notify("Goto","Target has no character","error")
    end
end)

Reg("walkspeed", {"ws","speed"}, "Set your walk speed  e.g. walkspeed 30", false, function(a)
    local n = tonumber(a[1]) or 16
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = n Notify("WalkSpeed","Speed -> "..n,"success") end
end)

Reg("jumppower", {"jp"}, "Set your jump power  e.g. jumppower 80", false, function(a)
    local n = tonumber(a[1]) or 50
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = n Notify("JumpPower","Power -> "..n,"success") end
end)

Reg("resetstats", {"rss"}, "Reset your speed and jump to default", false, function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = 16
        h.JumpPower = 50
        Notify(" ResetStats","Speed & jump reset to default","info")
    end
end)

-- Safe platform - built once, shared between all VC users who use the command
local safePlatform = nil
local SAFE_POS     = Vector3.new(0, 5000, 0)

local function BuildSafePlatform()
    -- Check if it already exists in Workspace
    local existing = workspace:FindFirstChild("VoidSafePlatform")
    if existing then safePlatform = existing return end

    local model = Instance.new("Model")
    model.Name = "VoidSafePlatform"

    -- Main floor - large purple platform
    local floor = Instance.new("Part")
    floor.Name          = "Floor"
    floor.Size          = Vector3.new(60, 2, 60)
    floor.Position      = SAFE_POS
    floor.Anchored      = true
    floor.CanCollide    = true
    floor.Material      = Enum.Material.SmoothPlastic
    floor.Color         = Color3.fromRGB(80, 0, 120)    -- deep purple
    floor.Parent        = model

    -- Black border trim around edge
    local border = Instance.new("Part")
    border.Name       = "Border"
    border.Size       = Vector3.new(64, 1, 64)
    border.Position   = SAFE_POS - Vector3.new(0, 0.5, 0)
    border.Anchored   = true
    border.CanCollide = false
    border.Material   = Enum.Material.SmoothPlastic
    border.Color      = Color3.fromRGB(10, 0, 20)       -- near black
    border.Parent     = model

    -- Glowing purple surface light
    local light = Instance.new("SurfaceLight")
    light.Brightness = 3
    light.Color      = Color3.fromRGB(150, 0, 255)
    light.Range      = 40
    light.Face       = Enum.NormalId.Top
    light.Parent     = floor

    -- Small sign
    local sign = Instance.new("Part")
    sign.Name     = "Sign"
    sign.Size     = Vector3.new(8, 3, 0.5)
    sign.Position = SAFE_POS + Vector3.new(0, 2.5, -28)
    sign.Anchored = true
    sign.CanCollide = false
    sign.Material = Enum.Material.SmoothPlastic
    sign.Color    = Color3.fromRGB(30, 0, 60)
    sign.Parent   = model

    local sg = Instance.new("SurfaceGui")
    sg.Face   = Enum.NormalId.Front
    sg.Parent = sign
    local lbl = Instance.new("TextLabel")
    lbl.Size                 = UDim2.new(1,0,1,0)
    lbl.BackgroundColor3     = Color3.fromRGB(30,0,60)
    lbl.TextColor3           = Color3.fromRGB(200,100,255)
    lbl.Font                 = Enum.Font.GothamBold
    lbl.Text                 = "  VoidCenter Safe Zone  "
    lbl.TextScaled           = true
    lbl.Parent               = sg

    model.Parent    = workspace
    model.PrimaryPart = floor
    safePlatform    = model
end

local safeReturnCF = nil  -- stores position before going to safe zone

Reg("safe", {"sz"}, "Teleport to safe platform  |  type again to return", false, function()
    local r = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not r then return end

    local atSafe = math.abs(r.Position.Y - SAFE_POS.Y) < 200

    if atSafe and safeReturnCF then
        -- Already at safe zone — teleport back to where we came from
        r.CFrame = safeReturnCF
        safeReturnCF = nil
        Notify("Safe Zone", "Returned to previous location", "info", 3)
    else
        -- Save current position then go to safe zone
        safeReturnCF = r.CFrame
        BuildSafePlatform()
        r.CFrame = CFrame.new(SAFE_POS + Vector3.new(math.random(-20,20), 4, math.random(-20,20)))
        Notify("Safe Zone", "At safe platform  |  type 'safe' again to return", "success", 4)
    end
end)

Reg("reset", {"rme","r"}, "Reset your own character", false, function()
    local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if h then
        h.Health = 0
        Notify("Reset","Resetting your character...","info",2)
    end
end)

Reg("antiafk", {"aafk"}, "Toggle anti-AFK (prevents auto-kick)", false, function()
    if Config.ActiveCmds["AntiAFK"] then
        Config.ActiveCmds["AntiAFK"] = nil
        RefreshActive()
        Notify("Anti-AFK","Disabled","info")
    else
        Config.ActiveCmds["AntiAFK"] = true
        RefreshActive()
        Notify("Anti-AFK","Enabled - you will not be kicked for AFK","success")
        task.spawn(function()
            local VirtualUser = game:GetService("VirtualUser")
            while Config.ActiveCmds["AntiAFK"] do
                task.wait(60)
                if Config.ActiveCmds["AntiAFK"] then
                    pcall(function() VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
                    task.wait(1)
                    pcall(function() VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end)
                end
            end
        end)
    end
end)

local aflConn  -- stored so we can disconnect cleanly
Reg("antifling", {"afl"}, "Toggle anti-fling - others phase through you", false, function()
    if Config.ActiveCmds["AntiFling"] then
        Config.ActiveCmds["AntiFling"] = nil
        if aflConn then aflConn:Disconnect() aflConn = nil end
        RefreshActive()
        -- Only restore CanCollide if noclip is NOT also running
        -- (noclip manages its own CanCollide via its own connection)
        if not ncOn then
            pcall(function()
                local chr = LP.Character
                if chr then
                    for _, p in ipairs(chr:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = true end
                    end
                end
            end)
        end
        Notify("Anti-Fling", "Disabled", "info")
    else
        -- TURN ON - use RunService.Stepped (same as noclip) for consistency
        Config.ActiveCmds["AntiFling"] = true
        RefreshActive()
        Notify("Anti-Fling", "Enabled - players phase through you", "success")
        aflConn = RunService.Stepped:Connect(function()
            pcall(function()
                local chr = LP.Character
                if not chr then return end
                for _, p in ipairs(chr:GetDescendants()) do
                    -- Disable collision on ALL parts including HRP -
                    -- HRP is the handle exploiters grab to fling you
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end)
        end)
    end
end)

Reg("antivoid", {"av"}, "Toggle anti-void protection", false, function()
    if Config.ActiveCmds["AntiVoid"] then
        Config.ActiveCmds["AntiVoid"] = nil
        RefreshActive()
        Notify("Anti-Void", "Disabled", "info")
    else
        Config.ActiveCmds["AntiVoid"] = true
        RefreshActive()

        -- Read the game's actual void kill height. Every Roblox game has this property.
        -- We trigger 30 studs above it so we always save before the void kills us.
        local voidKillY = -500
        pcall(function()
            voidKillY = workspace.FallenPartsDestroyHeight
        end)
        local triggerY = voidKillY + 30   -- save 30 studs before death line

        -- Where to teleport back to: record a safe Y on the ground when enabled.
        local safeY = 100
        pcall(function()
            local chr = LP.Character
            local r   = chr and chr:FindFirstChild("HumanoidRootPart")
            if r then safeY = math.max(r.Position.Y + 10, 10) end
        end)

        Notify("Anti-Void", "Enabled  (trigger: Y < "..math.floor(triggerY)..")", "success")

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
                        cooldown  = true
                        h.Health  = h.MaxHealth
                        r.CFrame  = CFrame.new(r.Position.X, safeY, r.Position.Z)
                        Notify("Anti-Void", "Saved!", "success", 3)
                        task.wait(1.5)
                        cooldown = false
                        -- Update safeY after each save in case map has changed
                        pcall(function()
                            local chr2 = LP.Character
                            local r2 = chr2 and chr2:FindFirstChild("HumanoidRootPart")
                            if r2 then safeY = math.max(r2.Position.Y + 10, 10) end
                        end)
                    end
                end)
            end
        end)
    end
end)

Reg("spectate", {"spec","view"}, "Spectate a player  e.g. spectate Player1 | spectate stop", false, function(a)
    if not a[1] or a[1]:lower() == "stop" then
        -- Exit spectate: restore camera
        local cam = workspace.CurrentCamera
        cam.CameraType = Enum.CameraType.Custom
        cam.CameraSubject = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        Config.ActiveCmds["Spectating"] = nil
        RefreshActive()
        Notify("Spectate","Camera restored","info",3)
        return
    end
    local t = FindPlayer(a[1])
    if not t then Notify("Spectate","Player not found: "..(a[1] or "?"),"error") return end
    if t == LP then Notify("Spectate","Can't spectate yourself","warning") return end
    local th = t.Character and t.Character:FindFirstChildOfClass("Humanoid")
    if not th then Notify("Spectate",PStr(t).." has no character","error") return end
    local cam = workspace.CurrentCamera
    cam.CameraType    = Enum.CameraType.Custom
    cam.CameraSubject = th
    Config.ActiveCmds["Spectating"] = true
    RefreshActive()
    Notify("Spectate","Now viewing "..PStr(t).."\nType 'spectate stop' to exit","success",4)
    -- Auto-follow if they respawn
    t.CharacterAdded:Connect(function(char)
        if not Config.ActiveCmds["Spectating"] then return end
        task.wait(0.5)
        local newHum = char:FindFirstChildOfClass("Humanoid")
        if newHum then cam.CameraSubject = newHum end
    end)
end)

Reg("rejoin", {"rj"}, "Rejoin the current game", false, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)

Reg("help", {"cmds","commands"}, "List all commands", false, function()
    Notify("Utility",
        "fly / flyspeed / noclip / esp / goto / safe / reset\nwalkspeed / jumppower / resetstats / rejoin / spectate",
        "info", 8)
    task.wait(0.5)
    Notify("Visual",
        "trail / rainbow / ghost / invisible / bighead / nametag",
        "info", 8)
    task.wait(0.5)
    Notify("Combat & Tools",
        "hitbox / reach / zoom / thirdperson / hat / unequip",
        "info", 8)
    task.wait(0.5)
    Notify("Info",
        "find / players / copyfit / antiafk / antifling / antivoid",
        "info", 8)
    task.wait(0.5)
    if IsPremium() then
        Notify("Premium [P]  (type in Roblox chat)",
            ".fling .bring .bringall .freeze .unfreeze\n.kill .kick .unkick .spin .explode\n.follow .unfollow .tp2me .untp2me .chat",
            "gold", 10)
    else
        Notify("Premium",
            "Get whitelisted for Premium to unlock troll commands.",
            "gold", 6)
    end
end)

