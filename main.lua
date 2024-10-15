local socket = require("socket")

local font, chatLog, inputText, chatRooms, currentRoom, backgroundEffect, server, connected

function love.load()
    love.window.setTitle("Futuristic Neon Chat")
    love.window.setMode(800, 600, {resizable=false})

    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {}
    inputText = ""
    chatRooms = {"General", "Group 1", "Private - User1"}
    currentRoom = 1

    backgroundEffect = {time = 0}

    server = socket.connect("127.0.0.1", 12345)
    if server then
        connected = true
        table.insert(chatLog, "Connecté au serveur !")
    else
        connected = false
        table.insert(chatLog, "Échec de la connexion au serveur.")
    end
    server:settimeout(0)
end

function love.update(dt)
    backgroundEffect.time = backgroundEffect.time + dt

    if connected then
        local message, err = server:receive()
        if message then
            table.insert(chatLog, chatRooms[currentRoom] .. "> " .. message)
        end
    end
end

function love.textinput(t)
    inputText = inputText .. t
end

function love.keypressed(key)
    if key == "backspace" then
        inputText = inputText:sub(1, #inputText - 1)
    elseif key == "return" and inputText ~= "" then
        sendMessage(inputText)
        inputText = ""
    elseif key == "tab" then
        currentRoom = currentRoom % #chatRooms + 1
    end
end

function sendMessage(message)
    if connected then
        server:send(chatRooms[currentRoom] .. "> " .. message .. "\n")
        table.insert(chatLog, "Moi: " .. message)
    end
end

function love.draw()
    drawFuturisticBackground()

    drawChatRoomUI()
end

function drawFuturisticBackground()
    love.graphics.clear(0, 0, 0)
    for x = 0, love.graphics.getWidth(), 50 do
        for y = 0, love.graphics.getHeight(), 50 do
            local offset = (x + y) / 10 + backgroundEffect.time * 50
            local alpha = math.sin(offset) * 0.5 + 0.5
            love.graphics.setColor(0.1, 0.5, 1, alpha)
            love.graphics.rectangle("fill", x, y, 48, 48)
        end
    end
end

function drawChatRoomUI()
    love.graphics.setColor(0.1, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", 0, 0, 800, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Room: " .. chatRooms[currentRoom], 10, 10, 780, "center")

    local y = 50
    for i = 1, #chatLog do
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(chatLog[i], 10, y)
        y = y + 20
    end

    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 10, 550, 780, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(inputText, 15, 560)
end
