local Network = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua")))();
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

local Pathfinding = {}; do
    function Pathfinding:MoveTo(Position, Wait)
        local Start;

        if Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            Start = Character.UpperTorso
        else
            Start = Character.Torso
        end

        local Path = PathfindingService:FindPathAsync(Start.Position, Position);
        local Waypoints = Path:GetWaypoints();

        if #Waypoints == 0 then
            Network:TeleportTo(CFrame.new(Position))
        end

        for Waypoint = 1, #Waypoints do
            if Waypoints[Waypoint].Action == Enum.PathWaypointAction.Jump then
                Humanoid.Jump = true
                Humanoid:MoveTo(Waypoints[Waypoint + 1].Position)
                
                if Wait then
                    Humanoid.MoveToFinished:Wait()
                end
            else
                Humanoid:MoveTo(Waypoints[Waypoint].Position)
                
                if Wait then
                    Humanoid.MoveToFinished:Wait()
                end
            end
        end
    end;

    function Pathfinding:TweenTo(Positions, Wait)
        local Start;

        if Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            Start = Character.UpperTorso
        else
            Start = Character.Torso
        end

        local Path = PathfindingService:FindPathAsync(Start.Position, Positions);
        local Waypoints = Path:GetWaypoints();

        if #Waypoints == 0 then
            Network:TeleportTo(CFrame.new(Position))
        end

        for Waypoint = 1, #Waypoints do
            local TweenInfo = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local Tween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CFrame.new(Waypoints[Waypoint].Position)})
            Tween:Play()

            if Wait then
                Tween.Completed:Wait()
            end
        end
    end;

    function Pathfinding:DrawPath(Positions)
        local Start;

        if Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            Start = Character.UpperTorso
        else
            Start = Character.Torso
        end

        local Path = PathfindingService:FindPathAsync(Start.Position, Positions);
        local Waypoints = Path:GetWaypoints();

        for Waypoint = 1, #Waypoints do
            local Part = Instance.new("Part")
            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(1, 1, 1)
            Part.Position = Waypoints[Waypoint].Position
            Part.Parent = workspace
        end
    end;
end
return Pathfinding