local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local PathfindingService = game:GetService("PathfindingService");

local Pathfinding = {}; do
    function Pathfinding:MoveTo(Positions, Wait)
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

    function Pathfinding:TweenTo(Positions, Time, Wait)
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
            local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            local Tween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CFrame.new(Waypoints[Waypoint].Position)})
            Tween:Play()

            if Wait then
                Tween.Completed:Wait()
            end
        end
    end;

    function Pathfinding:DrawPath()
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
