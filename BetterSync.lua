---
--- Title: BetterSync™
--- Author: superyu'#7167, special thanks to april#0001, gowork88#1556 and Shady#0001
--- Description: BetterSync is a lua Extention for Aimware, it's purpose is to add more configuration to the Anti-Aimbot, it heavily focuses on the desync part.
---

--- Auto updater Variables
local SCRIPT_FILE_NAME = GetScriptName();
local SCRIPT_FILE_ADDR = "https://raw.githubusercontent.com/superyor/BetterSync/master/BetterSync.lua";
local VERSION_FILE_ADDR = "https://raw.githubusercontent.com/superyor/BetterSync/master/version.txt"; --- in case of update i need to update this. (Note by superyu'#7167 "so i don't forget it.")
local VERSION_NUMBER = "3.0b"; --- This too
local version_check_done = false;
local update_downloaded = false;
local update_available = false;

--- Auto Updater GUI Stuff
local BETTERSYNC_UPDATER_TAB = gui.Tab(gui.Reference("Settings"), "bettersync.updater.tab", "Superyu's Autoupdates")
local BETTERSYNC_UPDATER_GROUP = gui.Groupbox(BETTERSYNC_UPDATER_TAB, "Auto Updater for BetterSync™ | v" .. VERSION_NUMBER, 15, 15, 500, 500)
local BETTERSYNC_UPDATER_TEXT = gui.Text(BETTERSYNC_UPDATER_GROUP, "")

--- BetterSync Tab
local BETTERSYNC_TAB = gui.Tab(gui.Reference("Ragebot"), "bettersync.tab", "BetterSync")
local BETTERSYNC_DESYNC_GROUP = gui.Groupbox(gui.Reference("Ragebot", "BetterSync"), "Desync", 15, 15, 240, 325);
local BETTERSYNC_MISC_GROUP = gui.Groupbox(gui.Reference("Ragebot", "BetterSync"), "Misc", 15, 30+(325/2)+15, 240, 100)
local BETTERSYNC_SWAY_GROUP = gui.Groupbox(gui.Reference("Ragebot", "BetterSync"), "Sway", 255+15, 15, 350, 500);

--- Desync GUI Stuff
local BETTERSYNC_ENABLE = gui.Checkbox(BETTERSYNC_DESYNC_GROUP, "rbot.bettersync.enabled", "Enabled", false)
local BETTERSYNC_LBY_MODE = gui.Combobox(BETTERSYNC_DESYNC_GROUP, "rbot.bettersync.lby.mode", "LBY Mode", "Off", "Match", "Invert")
local BETTERSYNC_ANTILBY  = gui.Checkbox(BETTERSYNC_DESYNC_GROUP, "rbot.bettersync.antilby", "Anti-LBY", 0);

--- Fixes GUI Stuff
local BETTERSYNC_JUMPSCOUT = gui.Checkbox(BETTERSYNC_MISC_GROUP, "rbot_bettersync_fixes_jumpscout", "Fix Jumpscout", 0)
local BETTERSYNC_PULSEFAKE = gui.Checkbox(BETTERSYNC_MISC_GROUP, "rbot_bettersync_msc_pulsefake", "Pulsating Fake Chams", 0);

---Sway GUI Stuff
local BETTERSYNC_SWAY_SPEED = gui.Slider(BETTERSYNC_SWAY_GROUP, "rbot_bettersync_sway_speed", "Speed", 5, 1, 15);
local BETTERSYNC_SWAY_RANGE1 = gui.Slider(BETTERSYNC_SWAY_GROUP, "rbot_bettersync_sway_rangestart", "Range Start", -58, -58, 58);
local BETTERSYNC_SWAY_RANGE2 = gui.Slider(BETTERSYNC_SWAY_GROUP, "rbot_bettersync_sway_rangeend", "Range End", 58, -58, 58);
local BETTERSYNC_SWAY_DEADZONE = gui.Slider(BETTERSYNC_SWAY_GROUP, "rbot_bettersync_sway_deadzone", "Deadzone", 0, 0, 58);

--- BetterSync Variables
local pLocal;
local max, min = 0, 0;
local cs, cd = 0, 0;
local cs2, cd2, s = 0, 0, 2;
local offset = 0;
local del = globals.CurTime() + 0.100
local inFreezeTime = false;
local switch = false;
local dx, dy, rx, ry = 0, 0, 0, 0
local lastTickSway = 0;
local lastTickPulse = 0

--- Listeners
client.AllowListener("round_freeze_end")
client.AllowListener("round_start")
--- Helpers
local function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

local function handlePulse()

    if (BETTERSYNC_PULSEFAKE:GetValue()) then

        if globals.TickCount() > lastTickPulse then

            if (cs2 >= 75) then
                cd2 = 1;
            elseif (cs2 <= 0 + s) then
                cd2 = 0;
            end

            if (cd2 == 0) then
                cs2 = cs2 + s;
            elseif (cd2 == 1) then
                cs2 = cs2 - s;
            end

            if cs2 < 0 then cs2 = 0 end
            local r, g, b, a = gui.GetValue("esp.chams.ghost.visible");
            gui.SetValue("esp.chams.ghost.visible", r, g, b, cs2);
            lastTickPulse = globals.TickCount()
        end
    end
end

local function handleDesync()

    local val = 0;

    if globals.TickCount() > lastTickSway then

        local speed = BETTERSYNC_SWAY_SPEED:GetValue() / 2

        if BETTERSYNC_SWAY_RANGE1:GetValue() < BETTERSYNC_SWAY_RANGE2:GetValue() then
            min = BETTERSYNC_SWAY_RANGE1:GetValue()
            max = BETTERSYNC_SWAY_RANGE2:GetValue()
        else
            min = BETTERSYNC_SWAY_RANGE2:GetValue()
            max = BETTERSYNC_SWAY_RANGE1:GetValue()
        end

        if (cs >= max) then
            cd = 1;
        elseif (cs <= min + speed) then
            cd = 0;
        end
        
        if (cd == 0) then
            cs = cs + speed;
        elseif (cd == 1) then
            cs = cs - speed;
        end

        local deadzoneP = BETTERSYNC_SWAY_DEADZONE:GetValue()
        local deadzoneN = deadzoneP * -1

        if cs > 0 then
            if cs < deadzoneP then
                cs = deadzoneN
            end
        end

        if cs < 0 then
            if cs > deadzoneN then
                cs = deadzoneP
            end
        end

        lastTickSway = globals.TickCount()
        val = cs;

        local lby = 0

        if BETTERSYNC_LBY_MODE:GetValue() > 0 then
            if BETTERSYNC_LBY_MODE:GetValue() == 1 then
                lby = val;
            else
                lby = val * -1
            end
        end

        if not inFreezeTime then
            gui.SetValue("rbot.antiaim.base.rotation", val)
            gui.SetValue("rbot.antiaim.left.rotation", val)
            gui.SetValue("rbot.antiaim.right.rotation", val)
            gui.SetValue("rbot.antiaim.base.lby", lby)
            gui.SetValue("rbot.antiaim.left.lby", lby)
            gui.SetValue("rbot.antiaim.right.lby", lby)
        end
    end
end

local function handleVelocity()

    if not pLocal then
        return
    end

    local vel = math.sqrt(pLocal:GetPropFloat( "localdata", "m_vecVelocity[0]" )^2 + pLocal:GetPropFloat( "localdata", "m_vecVelocity[1]" )^2)

    if BETTERSYNC_JUMPSCOUT:GetValue() then
        if vel > 5 then
            gui.SetValue("misc.strafe.enable", 1)
        else
            gui.SetValue("misc.strafe.enable", 0)
        end
    end

    if del < globals.CurTime() then
        switch = not switch
        del = globals.CurTime() + 0.050
    end

    if vel > 3 then
        del = globals.CurTime() + 0.050
    end

end

--- Hooks
local function drawHook()
    pLocal = entities.GetLocalPlayer()

    --- The rest
    handlePulse()
    handleVelocity()
        
    if engine.GetMapName() == "" then
        lastTickPulse = 0;
        lastTickSway = 0;
    end

    if BETTERSYNC_ENABLE:GetValue() then
        handleDesync()
    end

end

local function CreateMoveHook(pCmd)
    
    if not pLocal then
        return
    end

    local vel = math.sqrt(pLocal:GetPropFloat( "localdata", "m_vecVelocity[0]" )^2 + pLocal:GetPropFloat( "localdata", "m_vecVelocity[1]" )^2)

    if vel > 3 then
        return
    end

    if BETTERSYNC_ANTILBY:GetValue() then
        if switch then
            pCmd.SideMove = 2
        else
            pCmd.SideMove = -2
        end
    end
end

local function EventHook(event)

    if event:GetName() == "round_freeze_end" then
        inFreezeTime = false;
    end

    if event:GetName() == "round_start" then
        inFreezeTime = true;
    end
end

--- Callbacks
callbacks.Register( "Draw", drawHook);
callbacks.Register( "CreateMove", CreateMoveHook)
callbacks.Register("FireGameEvent", EventHook)

--- Auto updater by ShadyRetard/Shady#0001
local function handleUpdates()

    if (update_available and not update_downloaded) then
        BETTERSYNC_UPDATER_TEXT:SetText("Update is getting downloaded.")
        local new_version_content = http.Get(SCRIPT_FILE_ADDR);
        local old_script = file.Open(SCRIPT_FILE_NAME, "w");
        old_script:Write(new_version_content);
        old_script:Close();
        update_available = false;
        update_downloaded = true;
    end

    if (update_downloaded) then
        BETTERSYNC_UPDATER_TEXT:SetText("Update available, please reload the script.")
        return;
    end

    if (not version_check_done) then
        version_check_done = true;
        local version = http.Get(VERSION_FILE_ADDR);
        if (version ~= VERSION_NUMBER) then
            update_available = true;
        end
        BETTERSYNC_UPDATER_TEXT:SetText("Your client is up to date. Current Version: v" .. VERSION_NUMBER)
    end
end

callbacks.Register("Draw", handleUpdates)