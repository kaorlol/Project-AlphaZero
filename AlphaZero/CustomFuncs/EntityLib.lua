local Request = (syn and syn.request) or request or http_Request or (http and http.request)
local Entity = nil;
local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");
local Camera = workspace.CurrentCamera;
local Lines = {};

local function WorldToPoint(Position)
    local Vector,_ = Camera:WorldToViewportPoint(Position);
    local NewVector = Vector2.new(Vector.X, Vector.Y);
    return NewVector;
end

local EntityLib = {}; do
    function EntityLib:Require(Url)
        local Response = Request({
            Url = Url;
            Method = "GET";
        })

        if Response.StatusCode == 200 then
            return Response.Body;
        end
    end;

    function EntityLib:Run(Code)
        local Function, Error = loadstring(Code)

        if not typeof(Function) == "function" then
            return error(string.format("Failed to run code, error: %s", tostring(Error)))
        end

        return Function()
    end;

    function EntityLib:GetCodes(Url)
        local Codes = {};
        local Success, Response = pcall(Request, {
            Url = Url;
            Method = "GET";
        })

        if Success then
            for Code in Response.Body:gmatch("<strong>(.-)</strong>") do
                if not Code:find(" ") then
                    table.insert(Codes, Code)
                end
            end
        end

        return Codes
    end

    function EntityLib:GetPlayerNames()
        local PlayerNames = {};

        for _, Player in next, Entity.entityList do
            table.insert(PlayerNames, Player.Player.Name);
        end

        return PlayerNames;
    end;

    function EntityLib:IsAlive(Thing, StateCheck)
        if not Thing then
            return Entity.isAlive;
        end

        if StateCheck == nil then
            StateCheck = true;
        end

        if table.find(self:GetPlayerNames(), Thing.Name) then
            local _, Ent = Entity.getEntityFromPlayer(Thing);

            return ((not StateCheck) or Ent and Ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Ent;
        else
            return ((not StateCheck) or Thing and Thing.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Thing;
        end
    end;

    function EntityLib:GetEnemyColor(IsEnemy)
        if IsEnemy then
            return Color3.new(1, 0.427450, 0.427450);
        end

        return Color3.new(0.470588, 1, 0.470588);
    end;

    function EntityLib:GetColorFromEntity(Ent, Health, UseTeamColor, Custom, Rainbow, Color)
        if Health then
            return Color3.fromHSV(Ent.Humanoid.Health / Ent.Humanoid.MaxHealth, 1, 1);
        end

        if Ent.Team and Ent.Team.TeamColor.Color and UseTeamColor then
            return Ent.Team.TeamColor.Color
        end

        if Custom then
            return Color
        end

        if Rainbow then
            return Color3.fromHSV(os.clock() % 5 / 5, 1, 1)
        end

        return self:GetEnemyColor(Ent.Targetable)
    end;

    function EntityLib:TeleportTo(Position)
        Entity.character.HumanoidRootPart.CFrame = CFrame.new(Position)
    end;

    function EntityLib:MoveTo(Position, Wait)
        local Path = PathfindingService:FindPathAsync(Entity.character.HumanoidRootPart.Position, Position);
        local Waypoints = Path:GetWaypoints();

        if Path.Status ~= Enum.PathStatus.Success then
            return self:TeleportTo(Position);
        end

        for Waypoint = 1, #Waypoints do
            if Waypoints[Waypoint].Action == Enum.PathWaypointAction.Jump then
                Entity.character.Humanoid.Jump = true;
                Entity.character.Humanoid:MoveTo(Waypoints[Waypoint + 1].Position)

                if Wait then
                    Entity.character.Humanoid.MoveToFinished:Wait();
                end
            else
                Entity.character.Humanoid:MoveTo(Waypoints[Waypoint].Position);

                if Wait then
                    Entity.character.Humanoid.MoveToFinished:Wait();
                end
            end
        end

        if Path.Status == Enum.PathStatus.Success then
            for _, Line in next, Lines do
                Line:Destroy();
            end
            table.clear(Lines);
        end
    end;

    function EntityLib:TweenTo(Position, Time)
        local Tween = TweenService:Create(Entity.character.HumanoidRootPart, TweenInfo.new(Time, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(Position);
        })
        local StabilizerTween = TweenService:Create(Entity.character.HumanoidRootPart, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {
            CFrame = CFrame.new(Position);
        })

        Tween:Play();
        Tween.Completed:Connect(function()
            Entity.character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0);
            StabilizerTween:Play();
        end)

        StabilizerTween.Completed:Connect(function()
            Entity.character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0);
        end)
    end

    function EntityLib:DrawPath(Position, Toggle)
        local LoopToggle = Toggle;
        if Toggle then
            local Path = PathfindingService:FindPathAsync(Entity.character.HumanoidRootPart.Position, Position);
            local Waypoints = Path:GetWaypoints();

            if #Waypoints == 0 then
                return;
            end

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

                Line.Color = Color3.new(1, 1, 1);
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

                        if OnScreen then
                            Line.Line.Visible = true;
                        else
                            Line.Line.Visible = false;
                        end

                        Line.Line.From = WorldToPoint(Line.From);
                        Line.Line.To = WorldToPoint(Line.To);
                        Line.Line.Color = Color3.new(1, 1, 1);
                    end
                end
            end)
        end
    end;
end

Entity = EntityLib:Run(EntityLib:Require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true));
Entity.fullEntityRefresh();

return Entity, EntityLib;
