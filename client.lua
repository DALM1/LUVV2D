local socket = require("socket")

local font, chatLog, inputText, connected, chatRooms, currentRoom, username
local server
local awaitingUsername = true
local threadSelected = false

local backspaceHeld = false
local backspaceTimer = 0

local gifFrames = {}
local gifFrameCount = 8
local gifCurrentFrame = 1

function love.load()
    love.window.setTitle("LUVV")
    love.window.setMode(800, 600, {resizable=false})

    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {}
    inputText = ""
    chatRooms = {"General", "Group 1", "Private - User1"}
    currentRoom = "General"

    for i = 1, gifFrameCount do
        gifFrames[i] = love.graphics.newImage("gif_frame_" .. i .. ".png")
    end

    server = socket.connect("127.0.0.1", 12345)
    if server then
        connected = true
        table.insert(chatLog, "LUV > Connecté au serveur Entrez votre nom d'utilisateur pour commencer.")
    else
        connected = false
        table.insert(chatLog, "Échec de la connexion au serveur.")
    end

    server:settimeout(0)
end

function love.update(dt)
    if backspaceHeld then
        backspaceTimer = backspaceTimer + dt
        if backspaceTimer > 0.1 then
            inputText = inputText:sub(1, #inputText - 1)
            backspaceTimer = 0
        end
    end

    if connected then
        local message, err = server:receive()
        if message then
            if pcall(function() return message:match(".*") end) then
                table.insert(chatLog, message)
            end
        end
    end
end

function love.textinput(t)
    inputText = inputText .. t
    gifCurrentFrame = (gifCurrentFrame % gifFrameCount) + 1
end

function love.keypressed(key)
    if key == "backspace" then
        backspaceHeld = true
        inputText = inputText:sub(1, #inputText - 1)
    elseif key == "return" and inputText ~= "" then
        if awaitingUsername then
            username = inputText
            sendToServer("/username " .. username)
            table.insert(chatLog, "Nom d'utilisateur défini : " .. username)
            awaitingUsername = false
        elseif not threadSelected then
            sendToServer("/join " .. inputText)
            table.insert(chatLog, "Rejoint le thread : " .. inputText)
            currentRoom = inputText
            threadSelected = true
        else
            sendMessage(inputText)
        end
        inputText = ""
    end
end

function love.keyreleased(key)
    if key == "backspace" then
        backspaceHeld = false
    end
end

function sendMessage(message)
    if connected and threadSelected then
        local fullMessage = username .. ": " .. message
        sendToServer("/msg " .. currentRoom .. " " .. fullMessage)
        table.insert(chatLog, fullMessage)
    end
end

function sendToServer(message)
    if connected then
        server:send(message .. "\n")
    end
end

function love.draw()
    drawAnimatedBackground()
    drawChatRoomUI()
end

function drawAnimatedBackground()
    love.graphics.clear(0, 0, 0)
    love.graphics.draw(gifFrames[gifCurrentFrame], 0, 0, 0, love.graphics.getWidth() / gifFrames[gifCurrentFrame]:getWidth(), love.graphics.getHeight() / gifFrames[gifCurrentFrame]:getHeight())
end

function drawChatRoomUI()
    love.graphics.setColor(0.2, 0.2, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 800, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Thread: " .. currentRoom, 10, 10, 780, "center")

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
    love.graphics.line(15 + #inputText * font:getWidth("a") / 3, 550, 15 + #inputText * font:getWidth("a") / 3, 590)
end
