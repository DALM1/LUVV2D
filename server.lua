package.path = package.path .. ";/opt/homebrew/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?/init.lua"
package.cpath = package.cpath .. ";/opt/homebrew/lib/lua/5.4/?.so"

local socket = require("socket")

local server = socket.bind("*", 12345)
local clients = {}

server:settimeout(0)

print("Serveur démarré et en écoute sur le port 12345")

local function broadcast(message)
    for i, client in ipairs(clients) do
        client:send(message .. "\n")
    end
end

while true do
    local client = server:accept()
    if client then
        client:settimeout(0)
        table.insert(clients, client)
        print("Nouveau client connecté")
        broadcast("Un nouveau client s'est connecté.")
    end

    for i, client in ipairs(clients) do
        local message, err = client:receive()
        if message then
            print("Message reçu : " .. message)
            broadcast(message)
        elseif err == "closed" then
            print("Client déconnecté")
            table.remove(clients, i)
        end
    end

    socket.sleep(0.01)
end
