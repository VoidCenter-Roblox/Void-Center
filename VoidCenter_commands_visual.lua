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
local Notify           = _VC.Notify
local FindPlayer       = _VC.FindPlayer
local PStr             = _VC.PStr
local Reg              = _VC.Reg
local RefreshActive    = _VC.RefreshActive
local Screen           = _VC.Screen
local vcUsers          = _VC.vcUsers
local IsVoidUser       = _VC.IsVoidUser
local IsWhitelisted    = _VC.IsWhitelisted

local nametagBill = nil
Reg("nametag", {"nt"}, "Set a custom tag above your head  e.g. nametag cool guy | nametag off", false, function(a)
    if nametagBill then pcall(function() nametagBill:Destroy() end) nametagBill = nil end
    local text = table.concat(a, " ")
    if text == "" or text:lower() == "off" then
        Notify("Nametag", "Removed", "info") return
    end
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then Notify("Nametag", "No character", "error") return end
    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 200, 0, 30)
    bill.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
    bill.AlwaysOnTop = true
    bill.LightInfluence = 0
    bill.MaxDistance = 0
    bill.Parent = root
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = text
    lbl.TextColor3 = C.AcctBr
    lbl.TextSize = 14
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    lbl.Parent = bill
    nametagBill = bill
    -- Rebuild on respawn
    LP.CharacterAdded:Connect(function(char)
        if not nametagBill then return end
        task.wait(1)
        local r2 = char:FindFirstChild("HumanoidRootPart")
        if r2 then bill.Parent = r2 end
    end)
    Notify("Nametag", "Set to: "..text, "success")
end)

local hitboxOn = false
local hitboxConn = nil
local origSizes = {}
Reg("hitbox", {"hb"}, "Expand your hitbox  e.g. hitbox 10 | hitbox off", false, function(a)
    if hitboxOn or (a[1] and a[1]:lower() == "off") then
        hitboxOn = false
        Config.ActiveCmds["Hitbox"] = nil RefreshActive()
        if hitboxConn then hitboxConn:Disconnect() hitboxConn = nil end
        local c = LP.Character
        if c then
            for part, sz in pairs(origSizes) do
                pcall(function() part.Size = sz end)
            end
        end
        origSizes = {}
        Notify("Hitbox", "Restored", "info") return
    end
    local size = tonumber(a[1]) or 8
    local c = LP.Character
    if not c then Notify("Hitbox", "No character", "error") return end
    hitboxOn = true
    Config.ActiveCmds["Hitbox"] = true RefreshActive()
    local function applyHitbox(char)
        origSizes = {}
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                origSizes[p] = p.Size
                pcall(function() p.Size = Vector3.new(size, size, size) end)
            end
        end
    end
    applyHitbox(c)
    hitboxConn = LP.CharacterAdded:Connect(function(char)
        if not hitboxOn then return end
        task.wait(0.5) applyHitbox(char)
    end)
    Notify("Hitbox", "Size set to "..size, "success")
end)

local bigheadOn = false
Reg("bighead", {"bh"}, "Toggle big head", false, function()
    local c = LP.Character
    if not c then return end
    local head = c:FindFirstChild("Head")
    if not head then return end
    if bigheadOn then
        bigheadOn = false
        Config.ActiveCmds["BigHead"] = nil RefreshActive()
        pcall(function() head.Size = Vector3.new(2,2,2) end)
        Notify("BigHead", "Off", "info")
    else
        bigheadOn = true
        Config.ActiveCmds["BigHead"] = true RefreshActive()
        pcall(function() head.Size = Vector3.new(8,8,8) end)
        Notify("BigHead", "On", "success")
    end
end)

local invisOn = false
Reg("invisible", {"invis","inv"}, "Toggle invisibility", false, function()
    local c = LP.Character
    if not c then return end
    if invisOn then
        invisOn = false
        Config.ActiveCmds["Invisible"] = nil RefreshActive()
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                pcall(function() p.Transparency = p:IsA("Decal") and 0 or 0 end)
            end
        end
        -- Force re-render by briefly unequipping
        Notify("Invisible", "Visible again", "info")
    else
        invisOn = true
        Config.ActiveCmds["Invisible"] = true RefreshActive()
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                pcall(function() p.Transparency = 1 end)
            end
        end
        Notify("Invisible", "You are now invisible", "success")
    end
end)

Reg("reach", {"rc"}, "Set tool reach distance  e.g. reach 20 | reach off", false, function(a)
    if a[1] and a[1]:lower() == "off" then
        local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
        if tool then
            local handle = tool:FindFirstChild("Handle")
            if handle then pcall(function() handle.Size = Vector3.new(1,1,1) end) end
        end
        Notify("Reach", "Reset", "info") return
    end
    local dist = tonumber(a[1]) or 15
    local tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
    if not tool then Notify("Reach", "Equip a tool first", "warning") return end
    local handle = tool:FindFirstChild("Handle")
    if handle then
        pcall(function() handle.Size = Vector3.new(dist, dist, dist) end)
        Notify("Reach", "Reach set to "..dist, "success")
    else
        Notify("Reach", "Tool has no handle", "error")
    end
end)

Reg("zoom", {"zm"}, "Set max camera zoom  e.g. zoom 100 | zoom off", false, function(a)
    if a[1] and a[1]:lower() == "off" then
        pcall(function() LP.CameraMaxZoomDistance = 400 end)
        Notify("Zoom", "Reset to default", "info") return
    end
    local dist = tonumber(a[1]) or 100
    pcall(function() LP.CameraMaxZoomDistance = dist end)
    Notify("Zoom", "Max zoom set to "..dist, "success")
end)

local tpOn = false
Reg("thirdperson", {"tp3","3p"}, "Lock camera to third person", false, function()
    if tpOn then
        tpOn = false
        Config.ActiveCmds["ThirdPerson"] = nil RefreshActive()
        pcall(function()
            LP.CameraMinZoomDistance = 0.5
            LP.CameraMaxZoomDistance = 400
        end)
        Notify("ThirdPerson", "Off", "info")
    else
        tpOn = true
        Config.ActiveCmds["ThirdPerson"] = true RefreshActive()
        pcall(function()
            LP.CameraMinZoomDistance = 10
            LP.CameraMaxZoomDistance = 10
        end)
        Notify("ThirdPerson", "Locked to third person", "success")
    end
end)

local trailOn = false
local trailObj = nil
Reg("trail", {"tr"}, "Toggle movement trail", false, function()
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    local head = c and c:FindFirstChild("Head")
    if not root or not head then Notify("Trail", "No character", "error") return end
    if trailOn then
        trailOn = false
        Config.ActiveCmds["Trail"] = nil RefreshActive()
        if trailObj then pcall(function() trailObj:Destroy() end) trailObj = nil end
        Notify("Trail", "Off", "info")
    else
        trailOn = true
        Config.ActiveCmds["Trail"] = true RefreshActive()
        local a0 = Instance.new("Attachment", root)
        local a1 = Instance.new("Attachment", head)
        local trail = Instance.new("Trail")
        trail.Attachment0 = a0
        trail.Attachment1 = a1
        trail.Lifetime = 0.5
        trail.MinLength = 0
        trail.FaceCamera = true
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(140,45,255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,200,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,80,180)),
        })
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        trail.Parent = root
        trailObj = trail
        Notify("Trail", "On", "success")
    end
end)

local rainbowOn = false
local rainbowConn = nil
Reg("rainbow", {"rb"}, "Toggle rainbow character colors", false, function()
    if rainbowOn then
        rainbowOn = false
        Config.ActiveCmds["Rainbow"] = nil RefreshActive()
        if rainbowConn then rainbowConn:Disconnect() rainbowConn = nil end
        Notify("Rainbow", "Off", "info")
    else
        rainbowOn = true
        Config.ActiveCmds["Rainbow"] = true RefreshActive()
        local hue = 0
        rainbowConn = RunService.Heartbeat:Connect(function(dt)
            if not rainbowOn then return end
            hue = (hue + dt * 0.3) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            local c = LP.Character
            if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then
                    pcall(function() p.Color = col end)
                end
            end
        end)
        Notify("Rainbow", "On", "success")
    end
end)

local ghostOn = false
Reg("ghost", {"gh"}, "Toggle ghost mode (semi-transparent, no collisions)", false, function()
    local c = LP.Character
    if not c then return end
    if ghostOn then
        ghostOn = false
        Config.ActiveCmds["Ghost"] = nil RefreshActive()
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function()
                    p.Transparency = p.Name == "HumanoidRootPart" and 1 or 0
                    p.CanCollide = p.Name ~= "HumanoidRootPart"
                end)
            end
        end
        Notify("Ghost", "Off", "info")
    else
        ghostOn = true
        Config.ActiveCmds["Ghost"] = true RefreshActive()
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                pcall(function()
                    p.Transparency = 0.6
                    p.CanCollide = false
                end)
            end
        end
        Notify("Ghost", "On - semi-transparent and no collisions", "success")
    end
end)

Reg("hat", {"accessory"}, "Equip any hat by asset ID  e.g. hat 1365767", false, function(a)
    local id = tonumber(a[1])
    if not id then Notify("Hat", "Usage: hat <assetId>", "warning") return end
    local ok, err = pcall(function()
        local ins = game:GetService("InsertService")
        local model = ins:LoadAsset(id)
        local hat = model:FindFirstChildOfClass("Accessory")
            or model:FindFirstChildOfClass("Hat")
            or model:FindFirstChild("Handle") and model
        if not hat then model:Destroy() Notify("Hat", "No accessory found in asset "..id, "error") return end
        hat.Parent = LP.Character
        model:Destroy()
        Notify("Hat", "Equipped asset "..id, "success")
    end)
    if not ok then Notify("Hat", "Failed: "..tostring(err), "error") end
end)

Reg("find", {"where","loc"}, "Show a player's location  e.g. find Player1", false, function(a)
    local t = FindPlayer(a[1])
    if not t then Notify("Find", "Player not found: "..(a[1] or "?"), "error") return end
    local root = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
    if not root then Notify("Find", PStr(t).." has no character", "error") return end
    local p = root.Position
    Notify("Find  "..t.Name,
        string.format("X: %.1f  Y: %.1f  Z: %.1f", p.X, p.Y, p.Z),
        "info", 6)
end)

Reg("players", {"list","who"}, "List all players in the server", false, function()
    local lines = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local ping = ""
        pcall(function()
            ping = "  "..math.floor(p:GetNetworkPing()*1000).."ms"
        end)
        local tag = p == LP and " (you)" or ""
        table.insert(lines, p.DisplayName.." @"..p.Name..ping..tag)
    end
    Notify("Players ("..#lines..")", table.concat(lines, "\n"), "info", 8)
end)

Reg("copyfit", {"cf","outfit"}, "Copy another player's outfit  e.g. copyfit Player1", false, function(a)
    local t = FindPlayer(a[1])
    if not t then Notify("CopyFit", "Player not found: "..(a[1] or "?"), "error") return end
    local ok, err = pcall(function()
        local desc = Players:GetCharacterAppearanceAsync(t.UserId)
        local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ApplyDescription(desc)
            Notify("CopyFit", "Copied outfit from "..t.DisplayName, "success", 4)
        end
    end)
    if not ok then Notify("CopyFit", "Failed: "..tostring(err), "error") end
end)

Reg("unequip", {"ue","drop"}, "Unequip all tools", false, function()
    local c = LP.Character
    if not c then return end
    local bp = LP:FindFirstChildOfClass("Backpack")
    local count = 0
    for _, tool in ipairs(c:GetChildren()) do
        if tool:IsA("Tool") then
            pcall(function()
                tool.Parent = bp or c
                count = count + 1
            end)
        end
    end
    Notify("Unequip", "Unequipped "..count.." tool(s)", "info")
end)

