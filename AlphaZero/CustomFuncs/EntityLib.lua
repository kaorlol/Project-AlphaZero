local Request = (syn and syn.request) or request or http_Request or (http and http.request)
local Entity = nil;

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

    function EntityLib:IsAlive(Player, StateCheck)
        if not Player then
            return Entity.isAlive;
        end

        local _, Ent = Entity.getEntityFromPlayer(Player)

        return ((not StateCheck) or Ent and Ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and Ent;
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
end

Entity = EntityLib:Run(EntityLib:Require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true))
Entity.fullEntityRefresh()
return Entity, EntityLib