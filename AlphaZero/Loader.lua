local Client = {
    Gitub = "",
    Games = {
        
    },
}

for PlaceId, GameName in next, Client.Games do
    if game.PlaceId == PlaceId then
        loadstring(game:HttpGetAsync(Client.Gitub .. GameName .. ".lua"))()
    end
end