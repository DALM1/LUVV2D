local socket = require("socket")

local font, chatLog, inputText, connected, chatRooms, currentRoom, username
local server

local gifFrames = {}
local gifFrameCount = 8
local gifCurrentFrame = 1

local backspaceHeld = false
local backspaceTimer = 0

function love.load()
    love.window.setTitle("LUVV")
    love.window.setMode(800, 600, {resizable=false})

    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {}
    inputText = ""
    chatRooms = {"General", "Group 1", "Private - User1"}
    currentRoom = 1
    username = "Moi"

    for i = 1, gifFrameCount do
        gifFrames[i] = love.graphics.newImage("gif_frame_" .. i .. ".png")
    end

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
            if not message:find(username .. ":") then
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
        sendMessage(inputText)
        inputText = ""
    elseif key == "tab" then
        currentRoom = currentRoom % #chatRooms + 1
    end
end

function love.keyreleased(key)
    if key == "backspace" then
        backspaceHeld = false
    end
end

function sendMessage(message)
    if connected then
        local fullMessage = username .. ": " .. message
        server:send(fullMessage .. "\n")
        table.insert(chatLog, fullMessage)
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
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", 0, 0, 800, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Thread " .. chatRooms[currentRoom], 10, 10, 780, "center")

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
