local socket = require("socket")

local server = socket.bind("*", 12345)
local clients = {}
local threads = {}

server:settimeout(0)

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
        client:send("LUVV > Veuillez définir votre nom d'utilisateur avec /username [votre_nom].\n")
    end

    for i, client in ipairs(clients) do
        local message, err = client:receive()
        if message then
            local command, thread, content = message:match("^/msg (%S+) /username (%S+): (.*)")
            if command == "/msg" then
                local formattedMessage = "[" .. thread .. "] " .. content
                broadcast(thread, formattedMessage)
            elseif message:match("^/join") then
                local thread = message:match("^/join (%S+)")
                if not threads[thread] then
                    threads[thread] = {clients = {}}
                    client:send("Thread " .. thread .. " créé avec succès.\n")
                else
                    client:send("Rejoint le thread " .. thread .. ".\n")
                end
                table.insert(threads[thread].clients, client)
            end
        elseif err == "closed" then
            table.remove(clients, i)
        end
    end

    socket.sleep(0.01)
end
