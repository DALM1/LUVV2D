local socket = require("socket")

local font, chatLog, inputText, connected, currentThread, username
local server
local awaitingUsername = true
local threadSelected = false
local clipboardText = ""
local cursorPosition = 0

local backspaceHeld = false
local backspaceTimer = 0

local gifFrames = {}
local gifFrameCount = 8
local gifCurrentFrame = 1

function string:split(sep)
    local fields = {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

function love.load()
    love.window.setTitle("LUVV")
    love.window.setMode(800, 600, {resizable=false})

    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {}
    inputText = ""
    currentThread = "General"
    username = ""

    for i = 1, gifFrameCount do
        gifFrames[i] = love.graphics.newImage("gif_frame_" .. i .. ".png")
    end

    server = socket.connect("127.0.0.1", 12345)
    if server then
        connected = true
        table.insert(chatLog, "LUVV > Connecté au serveur - Entrez votre nom d'utilisateur avec /username [votre_nom].")
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
            if cursorPosition > 0 then
                inputText = inputText:sub(1, cursorPosition - 1) .. inputText:sub(cursorPosition + 1)
                cursorPosition = cursorPosition - 1
            end
            backspaceTimer = 0
        end
    end

    if connected then
        local message, err = server:receive()
        if message then
            table.insert(chatLog, message)
        end
    end
end

function love.textinput(t)
    inputText = inputText:sub(1, cursorPosition) .. t .. inputText:sub(cursorPosition + 1)
    cursorPosition = cursorPosition + 1
end

function love.keypressed(key)
    if key == "backspace" then
        backspaceHeld = true
        if cursorPosition > 0 then
            inputText = inputText:sub(1, cursorPosition - 1) .. inputText:sub(cursorPosition + 1)
            cursorPosition = cursorPosition - 1
        end
    elseif key == "return" and inputText ~= "" then
        if awaitingUsername then
            if inputText:sub(1, 9) == "/username" then
                username = inputText:sub(11)
                table.insert(chatLog, "Nom d'utilisateur défini : " .. username)
                awaitingUsername = false
                inputText = ""
                cursorPosition = 0
            else
                table.insert(chatLog, "Veuillez définir un nom d'utilisateur avec /username [votre_nom]")
            end
        elseif not threadSelected then
            if inputText:sub(1, 5) == "/join" then
                local params = inputText:sub(7):split(" ")
                currentThread = params[1]
                table.insert(chatLog, "Rejoint le thread : " .. currentThread)
                sendMessage("/join " .. currentThread)
                threadSelected = true
                inputText = ""
                cursorPosition = 0
            else
                table.insert(chatLog, "Veuillez rejoindre un thread avec /join [nom_du_thread]")
            end
        else
            sendMessage(inputText)
            inputText = ""
            cursorPosition = 0
        end
    elseif key == "left" and cursorPosition > 0 then
        cursorPosition = cursorPosition - 1
    elseif key == "right" and cursorPosition < #inputText then
        cursorPosition = cursorPosition + 1
    elseif key == "v" and love.keyboard.isDown("lctrl", "rctrl") then
        clipboardText = love.system.getClipboardText()
        inputText = inputText:sub(1, cursorPosition) .. clipboardText .. inputText:sub(cursorPosition + 1)
        cursorPosition = cursorPosition + #clipboardText
    end
end

function love.keyreleased(key)
    if key == "backspace" then
        backspaceHeld = false
    end
end

function sendMessage(message)
    if connected then
        local fullMessage = "/msg " .. currentThread .. " /username " .. username .. ": " .. message
        server:send(fullMessage .. "\n")
        table.insert(chatLog, username .. ": " .. message)
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
    love.graphics.printf("Thread: " .. currentThread, 10, 10, 780, "center")

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
    love.graphics.line(15 + cursorPosition * font:getWidth("a") / 2, 550, 15 + cursorPosition * font:getWidth("a") / 2, 590)
end
