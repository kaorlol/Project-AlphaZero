local Client = {
    Github = "https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Supported%20Games/",
    Games = {
        ["8069117419"] = "Demon%20Soul%20Simulator";
    },
}

function GetGame()
    for PlaceId, GameName in next, Client.Games do
        if tostring(game.PlaceId) == PlaceId then
            return GameName
        end
    end
end

function LoadScript()
    local GameName = GetGame()
    if GameName then
        local Success, Error = pcall(function()
            loadstring(game:HttpGet(string.format("%s%s%s", Client.Github, GameName, ".lua")))()
        end)
        if not Success then
            warn(string.format('Failed to load script for game: "%s", Error: %s', string.gsub(GameName, "%%20", " "), Error))
        end
    else
        warn("AlphaZero does not support this game, loading universal script...")
        loadstring(game:HttpGet(string.format("%s%s", Client.Github, "Universal.lua")))()
    end
end

LoadScript()