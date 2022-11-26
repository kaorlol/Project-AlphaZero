local NotificationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sw1ndlerScripts/RobloxScripts/main/Notification%20Library/main.lua",true))()
local Network = {}; do
    function Network:Send(Remote, ...)
        local Args = {...}

        local Success, Error = pcall(function()
            Remote:FireServer(unpack(Args))
        end)

        if not Success then
            Remote:FireServer()
        end
    end
    function Network:Invoke(Remote, ...)
        local Args = {...}

        local Success, Error = pcall(function()
            Remote:InvokeServer(unpack(Args))
        end)

        if not Success then
            error(Error)
        end
    end
    function Network:Receive(Remote, Callback)
        Remote.OnClientEvent:Connect(Callback)
    end
    function Network:Notify(Title, Content, Duration)
        NotificationLib:CreateDefaultNotif({
            TweenSpeed = 1,
            Title = Title,
            Text = Content,
            Duration = Duration
        })
    end
    function Network:NotifyPrompt(Title, Content, Duration, Callback)
        NotificationLib:CreatePromptNotif({
            TweenSpeed = 1,
            Title = Title,
            Text = Content,
            Duration = Duration,
            Callback = Callback,
            TrueText = "Yes",
            FalseText = "No"
        })
    end
end
return Network
