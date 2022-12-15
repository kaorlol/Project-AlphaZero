if gethui then
    syn.protect_gui = gethui
end

local Network = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/CustomFuncs/Network.lua"))()
local Client = {
    Github = "https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/Supported%20Games/",
    Games = loadstring(game:HttpGet(("https://raw.githubusercontent.com/Uvxtq/Project-AlphaZero/main/AlphaZero/StoredGames.lua")))(),
    SupportedExploits = {
        "Synapse X";
        "Script-Ware";
        "Krnl";
    }
}

local MarketplaceService = game:GetService("MarketplaceService")
local ProductName = MarketplaceService:GetProductInfo(game.PlaceId).Name

function LoadScript()
    local GameName = nil;
    for PlaceId, GamesName in next, Client.Games do
        if tostring(game.PlaceId) == PlaceId then
            GameName = GamesName
            break;
        end
    end
    if GameName then
        local Success, Error = pcall(function()
            loadstring(game:HttpGet(string.format("%s%s%s", Client.Github, GameName, ".lua")))()
        end)
        if not Success then
            error(string.format('Failed to load script for game: "%s", Error: %s', string.gsub(GameName, "%%20", " "), Error))
        end
    else
        Network:Notify("Unsupported Game", string.format("%s is not Supported", ProductName), 5)
        task.wait(1.5)
        Network:NotifyPrompt("Universal", "Would you like to load the universal script?", 30, function(Value)
            if Value then
                loadstring(game:HttpGet(string.format("%s%s", Client.Github, "Universal.lua")))()
            end
        end)
    end
end

task.spawn(function()
    for _, Exploit in next, Client.SupportedExploits do
        if identifyexecutor() == Exploit then
            LoadScript()
            break;
        end
    end
end)