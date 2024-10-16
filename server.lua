package.path = package.path .. ";/opt/homebrew/share/lua/5.4/?.lua;/opt/homebrew/share/lua/5.4/?/init.lua"
package.cpath = package.cpath .. ";/opt/homebrew/lib/lua/5.4/?.so"

local socket = require("socket")

local server = socket.bind("*", 12345)
local clients = {}
local threads = {}

server:settimeout(0)

print("Server listening lightning fast on port 12345")

local function broadcast(thread, message)
    if threads[thread] then
        for _, client in ipairs(threads[thread].clients) do
            client:send(message .. "\n")
        end
    end
end

while true do
    local client = server:accept()
    if client then
        client:settimeout(0)
        table.insert(clients, client)
        print("Nouveau client connecté")
        client:send("LUVV > Veuillez définir votre nom d'utilisateur avec /username [votre_nom].\n")
    end

    for i, client in ipairs(clients) do
        local message, err = client:receive()
        if message then
            print("Message reçu : " .. message)

            local command, thread, password, content = message:match("^/join (%S+) (%S*) /username (.*)")
            if command == "/join" then
                if not threads[thread] then
                    threads[thread] = {password = password, clients = {}}
                    client:send("Thread " .. thread .. " créé avec succès.\n")
                elseif threads[thread].password ~= password then
                    client:send("Mot de passe incorrect pour le thread " .. thread .. ".\n")
                else
                    client:send("Rejoint le thread " .. thread .. ".\n")
                end

                table.insert(threads[thread].clients, client)
            else
                command, thread, content = message:match("^/msg (%S+) /username (%S+): (.*)")
                if command == "/msg" then
                    broadcast(thread, content)
                end
            end
        elseif err == "closed" then
            print("Client déconnecté")
            table.remove(clients, i)
        end
    end

    socket.sleep(0.01)
end
