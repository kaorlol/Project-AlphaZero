getgenv().settings = {
    autoPlay = {
        enabled = false,
        maxCombo = 0,
        holdNoteVariation = 0
    }
}
    

plr = game:GetService("Players").LocalPlayer

function smallRandom(lowest, highest, zeros)
    local zeros = zeros or 100
    local num = math.random(lowest * zeros, highest * zeros)
    return num / zeros
end

function getCombo()
    local player = getSide()
    if player == "Right" then
        player = "P2"
    else
        player = "P1"
    end
    stats = plr.PlayerGui.GameGui.Stats.Health[player .. "Stats"].Text
end

function getStats(side)
    local player = side or getSide()
    
    if player == "Right" then
        player = "P2"
    else
        player = "P1"
    end
    local stats = plr.PlayerGui.GameGui.Stats.Health[player .. "Stats"].Text
    local stats = string.split(stats, "|")
    
    local score = string.match(stats[2], "%d+")
    local misses = string.match(stats[3], "%d+")
    local combo = string.match(stats[4], "%d+")
    
    return {
        ["Combo"] = tonumber(combo),
        ['Misses'] = tonumber(misses),
        ['Score'] = tonumber(score)
    }
end

function getSide()
    for i,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ObjectValue") and tostring(v.Value) == game.Players.LocalPlayer.Name then
            if v.Name == "Player2" then
                return "Right"
            else
                return "Left"
            end
        end
    end
end

function autoPlay()
    task.spawn(function()
        while settings.autoPlay.enabled and task.wait() do
            if plr.PlayerGui:FindFirstChild("GameGui") then
                side = getSide()
                for i,v in pairs(plr.PlayerGui.GameGui["Notes" .. side].Notes:GetChildren()) do
                    if v:IsA("Frame") then
                        task.spawn(function()
                            repeat
                                for _, note in pairs(v:GetChildren()) do
                                    if note.AbsolutePosition.Y < 30 then
                        
                                        local playNote
                                        if settings.autoPlay.maxCombo ~= 0 and getStats(side).Combo >= settings.autoPlay.maxCombo then
                                            playNote = false
                                        else
                                            playNote = true
                                        end
                                        
                                        if playNote then
                                            game.VirtualInputManager:SendKeyEvent(1, tostring(v), 0, game)
                                            
                                            if note:FindFirstChild("Hold") then
                                                task.wait(note.Hold.Time.Value - smallRandom(0, settings.autoPlay.holdNoteVariation))
                                            else
                                                repeat task.wait() until note.Parent ~= v
                                            end
                                            game.VirtualInputManager:SendKeyEvent(0, tostring(v), 0, game)
                                        end
                        
                                    end
                                end
                                task.wait()
                            until plr.PlayerGui:FindFirstChild("GameGui") == nil or settings.autoPlay.enabled == false
                        end)
                    end
                end
                repeat task.wait() until plr.PlayerGui:FindFirstChild("GameGui") == nil or settings.autoPlay.enabled == false
            end
        end
    end)
end


local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
local Window = Rayfield:CreateWindow({
    Name = "Lemon Funky'",
    LoadingTitle = "Lemon Funky'",
    LoadingSubtitle = "By: Sw1ndler#7733",
    Discord = {
        Enabled = true,
        Invite = "JdzPVMNFwY",
        RememberJoins = false,
     },
    ConfigurationSaving = {
      Enabled = true,
      FolderName = "Alpha Zero", -- Create a custom folder for your hub/game
      FileName = "Lemon Funky"
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

Main:CreateSection("Legit")

Main:CreateSlider({
    Name = "Max Combo (set to zero for inf)",
    Range = {0, 800},
    Increment = 10,
    Suffix = "notes",
    CurrentValue = 0,
    Flag = "Max Combo",
    Callback = function(Value)
        settings.autoPlay.maxCombo = Value
    end
})

Main:CreateSlider({
    Name = "Release hold notes earlier",
    Range = {0, 1},
    Increment = 0.1,
    Suffix = "up to this many seconds",
    CurrentValue = 0,
    Flag = "Hold Note Miss",
    Callback = function(Value)
        settings.autoPlay.holdNoteVariation = Value
    end
})





