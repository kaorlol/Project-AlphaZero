local Network = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua")))();
local Players = game:GetService("Players");
local LocalPlayer = Players.LocalPlayer;
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait();
local Humanoid = Character:WaitForChild("Humanoid");
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart");
local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");
local Camera = workspace.CurrentCamera;

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	Humanoid = Char:WaitForChild("Humanoid")
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

function WorldToPoint(Position)
    local Vector,_ = Camera:WorldToViewportPoint(Position);
    local NewVector = Vector2.new(Vector.X, Vector.Y);
    return NewVector;
end

local Pathfinding = {}; do
    function Pathfinding:MoveTo(Position, Wait)
        local Start;

        if Humanoid.RigType == Enum.HumanoidRigType.R15 then
            Start = Character.UpperTorso or Character.Torso;
        elseif Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            Start = HumanoidRootPart;
        end

        local Path = PathfindingService:FindPathAsync(Start.Position, Position);
        local Waypoints = Path:GetWaypoints();

        if #Waypoints == 0 then
            Network:TeleportTo(CFrame.new(Position));
        end

        for Waypoint = 1, #Waypoints do
            if Waypoints[Waypoint].Action == Enum.PathWaypointAction.Jump then
                Humanoid.Jump = true;
                Humanoid:MoveTo(Waypoints[Waypoint + 1].Position)

                if Wait then
                    Humanoid.MoveToFinished:Wait();
                end
            else
                Humanoid:MoveTo(Waypoints[Waypoint].Position);

                if Wait then
                    Humanoid.MoveToFinished:Wait();
                end
            end
        end
    end;

    function Pathfinding:TweenTo(Position, Wait)
        local Start;

        if Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
            Start = Character.UpperTorso or Character.Torso;
        elseif Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            Start = HumanoidRootPart;
        end

        local Path = PathfindingService:FindPathAsync(Start.Position + Vector3.new(0, 3, 0), Position);
        local Waypoints = Path:GetWaypoints();

        if #Waypoints == 0 then
            Network:TeleportTo(CFrame.new(Position));
        end

        for Waypoint = 1, #Waypoints do
            local LongWaypoint;
            if Waypoints[Waypoint + 5] then
                LongWaypoint = Waypoints[Waypoint + 5].Position;
            else
                LongWaypoint = Waypoints[Waypoint].Position;
            end


            local Distance = (LongWaypoint - Start.Position).Magnitude;
            local TweenInfo = TweenInfo.new(Distance / Humanoid.WalkSpeed, Enum.EasingStyle.Linear);
            local Tween = TweenService:Create(HumanoidRootPart, TweenInfo, {CFrame = CFrame.new(LongWaypoint + Vector3.new(0, 3, 0))});
            Tween:Play();

            if Wait then
                Tween.Completed:Wait();
            end
        end
    end;

    function Pathfinding:DrawPath(Position, Toggle)
        local LoopToggle = Toggle;
        if Toggle then
            local Start;

            if Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
                Start = Character.UpperTorso or Character.Torso;
            elseif Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
                Start = HumanoidRootPart;
            end

            local Path = PathfindingService:FindPathAsync(Start.Position, Position);
            local Waypoints = Path:GetWaypoints();

            if #Waypoints == 0 then
                print("No path found");
                return;
            end

            local Lines = {}

            for Waypoint = 1, #Waypoints do
                local Line = Drawing.new("Line");

                Line.Visible = true;

                Line.From = WorldToPoint(Waypoints[Waypoint].Position);

                local LineTo;
                if Waypoints[Waypoint + 1] then
                    LineTo = Waypoints[Waypoint + 1].Position;
                else
                    LineTo = Position;
                end

                Line.To = WorldToPoint(LineTo);

                Line.Color = Color3.fromRGB(255, 255, 255);
                Line.Thickness = 2;
                Line.Transparency = 1;

                table.insert(Lines, {
                    Line = Line,
                    To = LineTo,
                    From = Waypoints[Waypoint].Position
                });
            end;

            task.spawn(function()
                while LoopToggle do task.wait()
                    for _, Line in next, Lines do
                        local _, OnScreen = Camera:WorldToViewportPoint(Line.From);
                        local Distance = (HumanoidRootPart.Position - Position).Magnitude;

                        if OnScreen then
                            Line.Line.Visible = true;
                        else
                            Line.Line.Visible = false;
                        end

                        if Distance <= 5 then
                            for _, Line in next, Lines do
                                Line.Line:Destroy();
                            end
                            table.clear(Lines);
                        end

                        if #Lines > 0 then
                            local LastUpdate = tick();
                            if tick() - LastUpdate >= 60 then
                                for _, Line in next, Lines do
                                    Line.Line:Destroy();
                                end
                                table.clear(Lines);
                            end
                        end

                        Line.Line.From = WorldToPoint(Line.From);
                        Line.Line.To = WorldToPoint(Line.To);
                    end
                end
            end)
        end
    end;
end
return Pathfinding