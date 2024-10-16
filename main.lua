local socket = require("socket")

-- Variables pour l'interface utilisateur et le réseau
local font, chatLog, inputText, connected, chatRooms, currentRoom, username
local server  -- Connexion au serveur
local backgroundEffect = {time = 0, color = {0.1, 0.5, 1}}  -- Animation de fond

-- Gestion du backspace pour suppression continue
local backspaceHeld = false
local backspaceTimer = 0

-- Variables pour le fond animé
local gifFrames = {}  -- Tableau contenant les frames du GIF
local gifFrameCount = 8  -- Nombre d'images du GIF
local gifCurrentFrame = 1
local gifFrameTime = 0.1  -- Durée entre les frames du GIF
local gifTimer = 0

function love.load()
    -- Paramètres de la fenêtre
    love.window.setTitle("Futuristic Neon Chat")
    love.window.setMode(800, 600, {resizable=false})

    -- Initialisation des polices et des variables de l'interface
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {}  -- Historique des messages
    inputText = ""  -- Texte en cours de saisie
    chatRooms = {"General", "Group 1", "Private - User1"}  -- Différents salons de chat
    currentRoom = 1  -- Salle de chat actuelle
    username = "Moi"  -- Le nom d'utilisateur peut être personnalisé ici

    -- Charger les frames du GIF
    for i = 1, gifFrameCount do
        gifFrames[i] = love.graphics.newImage("gif_frame_" .. i .. ".png")  -- Assurez-vous que ces images existent
    end

    -- Connexion au serveur (adresse locale)
    server = socket.connect("127.0.0.1", 12345)
    if server then
        connected = true
        table.insert(chatLog, "Connecté au serveur !")
    else
        connected = false
        table.insert(chatLog, "Échec de la connexion au serveur.")
    end

    server:settimeout(0)  -- Mode non-bloquant pour la réception des messages
end

function love.update(dt)
    -- Mise à jour de l'effet de fond et de l'animation GIF
    backgroundEffect.time = backgroundEffect.time + dt
    gifTimer = gifTimer + dt
    if gifTimer >= gifFrameTime then
        gifTimer = 0
        gifCurrentFrame = (gifCurrentFrame % gifFrameCount) + 1
    end

    -- Récupérer les messages du serveur
    if connected then
        local message, err = server:receive()
        if message then
            -- Si le message n'a pas été envoyé par soi-même, on l'ajoute au chatLog
            if not message:find(username .. ":") then
                table.insert(chatLog, message)
            end
        end
    end

    -- Gestion du backspace pour suppression continue
    if backspaceHeld then
        backspaceTimer = backspaceTimer + dt
        if backspaceTimer > 0.1 then  -- Ajuster ce délai pour une suppression plus rapide ou plus lente
            inputText = inputText:sub(1, #inputText - 1)
            backspaceTimer = 0
        end
    end
end

function love.textinput(t)
    -- Ajoute le texte tapé par l'utilisateur au message en cours de saisie
    inputText = inputText .. t
    -- Changer la couleur du fond à chaque frappe
    backgroundEffect.color = {
        math.random(),  -- Couleur rouge aléatoire
        math.random(),  -- Couleur verte aléatoire
        math.random()   -- Couleur bleue aléatoire
    }
end

function love.keypressed(key)
    if key == "backspace" then
        -- Commence la suppression continue lorsque backspace est maintenu
        backspaceHeld = true
        inputText = inputText:sub(1, #inputText - 1)
    elseif key == "return" and inputText ~= "" then
        -- Envoyer le message lorsque "Entrée" est pressé
        sendMessage(inputText)
        inputText = ""
    elseif key == "tab" then
        -- Basculer entre les différentes salles de chat avec "Tab"
        currentRoom = currentRoom % #chatRooms + 1
    end
end

function love.keyreleased(key)
    if key == "backspace" then
        -- Arrête la suppression continue lorsque la touche est relâchée
        backspaceHeld = false
    end
end

function sendMessage(message)
    -- Envoie un message au serveur avec le nom d'utilisateur et l'ajoute à l'historique local
    if connected then
        local fullMessage = username .. ": " .. message
        server:send(fullMessage .. "\n")
        table.insert(chatLog, fullMessage)
    end
end

function love.draw()
    -- Dessiner le fond animé
    drawAnimatedBackground()

    -- Dessiner l'interface utilisateur du chat
    drawChatRoomUI()
end

function drawAnimatedBackground()
    -- Dessine la frame actuelle du GIF en fond
    love.graphics.clear(0, 0, 0)
    love.graphics.draw(gifFrames[gifCurrentFrame], 0, 0, 0, love.graphics.getWidth() / gifFrames[gifCurrentFrame]:getWidth(), love.graphics.getHeight() / gifFrames[gifCurrentFrame]:getHeight())
end

function drawChatRoomUI()
    -- En-tête de la salle de chat
    love.graphics.setColor(0.1, 0.9, 0.9, 1)
    love.graphics.rectangle("fill", 0, 0, 800, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Room: " .. chatRooms[currentRoom], 10, 10, 780, "center")

    -- Afficher les messages du chat
    local y = 50
    for i = 1, #chatLog do
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.print(chatLog[i], 10, y)
        y = y + 20
    end

    -- Boîte de saisie de texte
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 10, 550, 780, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(inputText, 15, 560)
end
