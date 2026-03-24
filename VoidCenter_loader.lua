local BASE_URL = ""

local function Alert(msg)
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "VCAlert"
        sg.ResetOnSpawn = false
        local ok, cg = pcall(function() return game:GetService("CoreGui") end)
        sg.Parent = ok and cg or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local lbl = Instance.new("TextLabel")
        lbl.Size             = UDim2.new(0, 420, 0, 44)
        lbl.Position         = UDim2.new(0.5, -210, 0.04, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(14, 0, 30)
        lbl.TextColor3       = Color3.fromRGB(255, 80, 80)
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextSize         = 13
        lbl.TextWrapped      = true
        lbl.Text             = msg
        lbl.BorderSizePixel  = 0
        lbl.Parent           = sg
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
        game:GetService("Debris"):AddItem(sg, 10)
    end)
    warn(msg)
end

if BASE_URL == "" then
    Alert("[VoidCenter] BASE_URL is empty — set it to your GitHub raw URL.")
    return
end
if BASE_URL:sub(-1) ~= "/" then
    Alert("[VoidCenter] BASE_URL must end with a /")
    return
end

local function Load(file)
    local url = BASE_URL .. file
    local rawCode
    local ok1, err1 = pcall(function() rawCode = game:HttpGet(url) end)
    if not ok1 then
        Alert("[VoidCenter] Could not download " .. file .. "\n" .. tostring(err1))
        return false
    end
    if not rawCode or rawCode == "" then
        Alert("[VoidCenter] " .. file .. " was empty.")
        return false
    end
    local fn, err2 = loadstring(rawCode)
    if not fn then
        Alert("[VoidCenter] Syntax error in " .. file .. ":\n" .. tostring(err2))
        return false
    end
    local ok3, err3 = pcall(fn)
    if not ok3 then
        Alert("[VoidCenter] Runtime error in " .. file .. ":\n" .. tostring(err3))
        return false
    end
    return true
end

if not Load("VoidCenter_core.lua") then return end

if getgenv()._VC_BLOCKED then
    getgenv()._VC_BLOCKED = nil
    return
end

local files = {
    "VoidCenter_detection.lua",
    "VoidCenter_commands_movement.lua",
    "VoidCenter_commands_utility.lua",
    "VoidCenter_commands_visual.lua",
    "VoidCenter_commands_combat.lua",
    "VoidCenter_commands_premium.lua",
    "VoidCenter_ui.lua",
    "VoidCenter_gui.lua",
}

for _, file in ipairs(files) do
    if not Load(file) then return end
end
