plr = game:GetService("Players").LocalPlayer

getgenv().settings = {
    autoPlay = {
        enabled = false
    }
}

function getSide()
    side = plr.File.CurrentPlayer.Value
    if tostring(side) == 'Player2' then
        return '2'
    elseif tostring(side) == 'Player1' then
        return '1'
    end
    return nil
end

arrowNotes = {
    ["Arrow1"] = 'A',
    ["Arrow2"] = 'S',
    ["Arrow3"] = 'W',
    ["Arrow4"] = 'D'
}

playedNotes = {}

function autoPlay()
    task.spawn(function()
        while settings.autoPlay.enabled and task.wait() do
            playedNotes = {}
            while plr.File.CurrentPlayer.Value and task.wait() do 
                local side = getSide()
                if side then
                    for _,v in pairs(plr.PlayerGui.Main.MatchFrame['KeySync' .. side]:GetChildren()) do
                        local frame = v.Notes
                        for _, note in pairs(frame:GetChildren()) do
                            local distance = (note.AbsolutePosition - v.AbsolutePosition).magnitude
                            if distance < 30 then
                                local curParent = note.Parent
                                game.VirtualInputManager:SendKeyEvent(1, arrowNotes[v.Name], 0, game)
                                repeat task.wait() until curParent ~= note.Parent
                                game.VirtualInputManager:SendKeyEvent(0, arrowNotes[v.Name], 0, game)
                                
                            end
                        end
                    end
                end
                if settings.autoPlay.enabled == false then break end;
            end
        end
    end)
end

local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
    Name = "Lemon Funky'",
    LoadingTitle = "Lemon Funky'",
    LoadingSubtitle = "By: Sw1ndler#7733 & Kaoru~#6438",
    Discord = {
        Enabled = true,
        Invite = "JdzPVMNFwY",
        RememberJoins = true,
     },
    ConfigurationSaving = {
      Enabled = true,
      FolderName = "Alpha Zero", -- Create a custom folder for your hub/game
      FileName = "Basically FNF: Remix"
   },
})

Main = Window:CreateTab("Main")

Main:CreateSection("Autoplay")

Main:CreateToggle({
    Name = 'Autoplay Songs',
    Callback = function(value)
        settings.autoPlay.enabled = value
        if value then
            autoPlay()
        end
    end
})
