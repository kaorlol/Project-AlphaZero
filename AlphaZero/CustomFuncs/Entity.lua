local Request = (syn and syn.request) or request or http_Request or (http and http.request)
getgenv().Entity = nil

local EntityLib = {}; do
    function EntityLib:Require(Url)
        local Response = Request({
            Url = Url,
            Method = "GET",
        })
        if Response.StatusCode == 200 then
            return Response.Body
        end
    end
    function EntityLib:Run(Code)
        local func, err = loadstring(Code)
        if not typeof(func) == 'function' then
            return error("Failed to run code, error: " .. tostring(err))
        end
        return func()
    end
    function EntityLib:IsAlive(Player, StateCheck)
        local _, ent
        pcall(function()
            if not Player then
                return Entity.isAlive
            end
            _, ent = Entity.getEntityFromPlayer(Player)
        end)
        return ((not StateCheck) or ent and ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and ent
    end
end
Entity = EntityLib:Run(EntityLib:Require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true))
Entity.fullEntityRefresh()
return EntityLib