local NotificationLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Sw1ndlerScripts/RobloxScripts/main/Notification%20Library/main.lua"))()
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(Char)
	Character = Char
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

local Network = {}; do
    function Network:Send(Remote, ...)
        local Args = {...}

        local Success, Error = pcall(function()
            Remote:FireServer(unpack(Args))
        end)

        if not Success then
            error(Error)
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
    function Network:TeleportTo(CFrame)
        HumanoidRootPart.CFrame = CFrame
    end
    function Network:SendInvite(DiscordID)
        local Settings = {
			InviteCode = DiscordID
		}
		
		local HttpService = game:GetService("HttpService")
		local RequestFunction
		
		if syn and syn.request then
			RequestFunction = syn.request
		elseif request then
			RequestFunction = request
		elseif http and http.request then
			RequestFunction = http.request
		elseif http_request then
			RequestFunction = http_request
		end
		
		local DiscordApiUrl = "http://127.0.0.1:%s/rpc?v=1"
		
		if not RequestFunction then
			return self:Notify("Error", "Failed to find a request function", 5)
		end
		
		for i = 6453, 6464 do
			local DiscordInviteRequest = function()
				local Request = RequestFunction({
					Url = string.format(DiscordApiUrl, tostring(i)),
					Method = "POST",
					Body = HttpService:JSONEncode({
						nonce = HttpService:GenerateGUID(false),
						args = {
							invite = {code = Settings.InviteCode},
							code = Settings.InviteCode
						},
						cmd = "INVITE_BROWSER"
					}),
					Headers = {
						["Origin"] = "https://discord.com",
						["Content-Type"] = "application/json"
					}
				})
			end
			task.spawn(DiscordInviteRequest)
		end
    end
    function Network:QueueOnTeleport(Code)
        if identifyexecutor() == "Synapse X" then
            pcall(function()
                syn.queue_on_teleport(Code);
            end)
        else
            local _, RetryError = pcall(function()
                queue_on_teleport(Code);
            end)

            if RetryError then
                self:Notify("Error", "Failed to queue teleport, retrying...", 5)

                local _, Error = pcall(function()
                    queue_on_teleport(Code);
                end)

                if Error then
                    self:Notify("Error", "Failed to queue teleport.", 5)
                    warn(string.format("Failed to queue teleport: %s", Error))
                end
            end
        end
    end
    function Network:ServerHop()
        local TeleportService = game:GetService("TeleportService");
        local ServerData = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Dsc&limit=100")).data;

        local c = 0;
        for i = 1, #ServerData do
            local Server = ServerData[i - c];
            if not Server.playing then
                table.remove(ServerData, i - c);
                c += 1;
            end
        end

        local function Shuffle(tInput)
            local tReturn = {};

            for i = #tInput, 1, -1 do
                local j = math.random(i);
                tInput[i], tInput[j] = tInput[j], tInput[i];
                table.insert(tReturn, tInput[i]);
            end

            return tReturn;
        end

        ServerData = Shuffle(ServerData);

        local function ServerHop(Data, Failed)
            Failed = Failed or {};
            for _, Server in next, Data do
                local Id = Server.id;
                if not Failed[Id] and Id ~= game.JobId then
                    if Server.playing < Server.maxPlayers then
                        local Connection; Connection = TeleportService.TeleportInitFailed:Connect(function(Player, TeleportResult, ErrorMessage)
                            self:Notify("Error", string.format("Failed to teleport to server: %s", ErrorMessage), 5);

                            Connection:Disconnect();
                            Failed[Id] = true;
                            ServerHop(Data, Failed);
                        end)
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, Id);
                        break;
                    end
                end
            end
        end

        ServerHop(ServerData)
    end
end
return Network