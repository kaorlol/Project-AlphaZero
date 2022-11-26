local Request = (syn and syn.request) or request or http_Request or (http and http.request)
function Require(Url)
    local Response = Request({
        Url = Url,
        Method = "GET",
    })
    if Response.StatusCode == 200 then
        return Response.Body
    end
end

Require("https://raw.githubusercontent.com/Sw1ndlerScripts/RobloxScripts/main/Notification%20Library/main.lua")