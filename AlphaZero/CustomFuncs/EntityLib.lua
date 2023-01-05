local Request = (syn and syn.request) or request or http_Request or (http and http.request)
local Entity = nil;
local PathfindingService = game:GetService("PathfindingService");
local TweenService = game:GetService("TweenService");

local EntityLib = {}; do
    function EntityLib:Require(Url)
        local Response = Request({
            Url = Url;
            Method = "GET";
        })

        if Response.StatusCode == 200 then
            return Response.Body;
        end
    end

    function EntityLib:Run(Code)
        local Function, Error = loadstring(Code)

        if not typeof(Function) == "function" then
            return error(string.format("Failed to run code, error: %s", tostring(Error)))
        end

        return Function()
    end

    function EntityLib:GetPlayerNames()
        local PlayerNames = {};

        for _, Player in next, Entity.entityList do
            table.insert(PlayerNames, Player.Player.Name);
        end

        return PlayerNames;
    end

    function EntityLib:IsAlive(Thing, StateCheck)
        if table.find(self:GetPlayerNames(), Thing.Name) then
            if not Thing then
                return Entity.isAlive;
            end

            local _, Ent = Entity.getEntityFromPlayer(Thing)

            return ((not StateCheck) or Ent and Ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Ent;
        else
            if not Thing then
                return false;
            end

            return ((not StateCheck) or Thing and Thing.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Thing;
        end
    end

    function EntityLib:GetEnemyColor(IsEnemy)
        if IsEnemy then
            return Color3.new(1, 0.427450, 0.427450);
        end

        return Color3.new(0.470588, 1, 0.470588);
    end

    function EntityLib:GetColorFromEntity(Ent, UseTeamColor, Custom, Rainbow, Color)
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
    end

    function EntityLib:TeleportTo(Position)
        Entity.character.HumanoidRootPart.CFrame = CFrame.new(Position)
    end

    function EntityLib:MoveTo(Position, Wait)
        local Path = PathfindingService:FindPathAsync(Entity.character.HumanoidRootPart.Position, Position);
        local Waypoints = Path:GetWaypoints();

        if #Waypoints == 0 then
            self:TeleportTo(Position);
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
end

Entity = EntityLib:Run(EntityLib:Require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true));
Entity.fullEntityRefresh();

return Entity, EntityLib;