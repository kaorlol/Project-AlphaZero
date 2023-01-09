if not game:IsLoaded() then
    game.Loaded:Wait()
end

local WaitCache = {};
local function GetChild(ChildName, Parent, Timeout)
    local Key = Parent:GetDebugId(99999) .. ChildName;

    if not WaitCache[Key] then
        WaitCache[Key] = Parent:FindFirstChild(ChildName) or Parent:WaitForChild(ChildName, Timeout);
    end

    return WaitCache[Key];
end

local Entity, EntityFuncs = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/EntityLib.lua")))();
local Network = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua")))();
local LocalPlayer = game:GetService("Players").LocalPlayer;
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Remotes = GetChild("Remotes", ReplicatedStorage);
local Server = GetChild("Server", Remotes);
local JoinNewGameOnEnd = true;
local JoinTP = false;

local function AttackArgs()
    local Arguments = {
        "MobAttack",
        {};
    };

    for _, Mob in next, workspace.Client.Mobs:GetChildren() do
        Arguments[2][Mob.Name] = true;
    end

    return Arguments;
end

local function GetClosestMobFromEnd()
    local ClosestMob, ClosestDistance = nil, math.huge;

    for _, Mob in next, workspace.Client.Mobs:GetChildren() do
        local Distance = (Mob.HumanoidRootPart.Position - workspace.Server.PointsMob["105"].Position).Magnitude;

        if Distance < ClosestDistance then
            ClosestDistance = Distance;
            ClosestMob = Mob;
        end
    end

    return ClosestMob;
end

if game.PlaceId == 11884594868 then
    local TeleportButton = GetChild("TextButton", LocalPlayer.PlayerGui.UI.RightButtons["Game Teleport"]);
    firesignal(TeleportButton.MouseButton1Click)

    local function GetOpenRoom()
        local HighestPlayers = 0;
        local HighestRoom = nil;

        for _, Room in next, workspace.Client.Rooms:GetChildren() do
            local Players = tonumber(GetChild("UID", Room:WaitForChild("UI_Interface").Frame.PlayersFrame).Text:split("/")[1]);
            if Players > HighestPlayers then
                HighestPlayers = Players;
                HighestRoom = Room;
            end
        end

        return HighestRoom;
    end
    task.wait(1)
    EntityFuncs:MoveTo(GetOpenRoom().Position + Vector3.new(-5, -5, 0), true);
    task.wait(1)
    local InteractButton = GetChild("TextButton", LocalPlayer.PlayerGui.UI.Client.Modules.InteractSettings.InteractFrame.Frame);
    firesignal(InteractButton.MouseButton1Click)
    task.wait(1)
    Network:Send(Server, {
        "MapSelect",
        "Demon Slayer"
    });
else
    task.spawn(function()
        while true do task.wait()
            task.spawn(function()
                local TeleportBack = GetChild("TeleportBack", LocalPlayer.PlayerGui.UI.CenterFrame);
                if not JoinTP then
                    EntityFuncs:MoveTo(GetChild("8", workspace.Server.PointsMob).Position, true);
                    JoinTP = true;
                end

                if JoinNewGameOnEnd and TeleportBack.Visible then
                    firesignal(GetChild("TextButton", TeleportBack.Teleport).MouseButton1Click);
                elseif not JoinNewGameOnEnd and TeleportBack.Visible then
                    firesignal(GetChild("TextButton", TeleportBack.Close).MouseButton1Click);
                end
            end)

            local ClosestMobFromEnd = GetClosestMobFromEnd();

            Network:Send(Server, AttackArgs());

            if ClosestMobFromEnd then
                local Distance = (ClosestMobFromEnd.HumanoidRootPart.Position - Entity.character.HumanoidRootPart.Position).Magnitude;

                if Distance <= 25 then
                    EntityFuncs:MoveTo(ClosestMobFromEnd.HumanoidRootPart.Position, false);
                else
                    EntityFuncs:MoveTo(ClosestMobFromEnd.HumanoidRootPart.Position, true);
                end
            end
        end
    end)
end

Network:QueueOnTeleport([[
    loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Supported%20Games/Anime%20Defense%20Simulator.lua")))();
]])

-- local AnimationHandler = getsenv(workspace.Uvxtq.Animate)

-- AnimationHandler.playAnimation("walk", 0.1, Entity.character.Humanoid);