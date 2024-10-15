-- Variables globales pour l'interface utilisateur
local font, chatLog, inputText, chatRooms, currentRoom

function love.load()
    -- Paramètres de la fenêtre
    love.window.setTitle("Futuristic Sci-Fi Chat")
    love.window.setMode(800, 600, {resizable=false})

    -- Chargement des polices et initialisation des variables
    font = love.graphics.newFont(14)
    love.graphics.setFont(font)

    chatLog = {
        "General: Bienvenue dans le chat !",
        "You: Salut, comment ça va ?",
        "Group 1: Ça va bien, et toi ?"
    }  -- Historique des messages simulé
    inputText = ""  -- Texte que l'utilisateur tape
    chatRooms = {"General", "Group 1", "Private - User1"}  -- Différents salons de chat
    currentRoom = 1  -- Salle de chat actuelle (par défaut "General")

    -- Effet d'animation pour le fond
    backgroundEffect = {time = 0}
end

function love.update(dt)
    -- Mise à jour de l'effet de fond
    backgroundEffect.time = backgroundEffect.time + dt
end

function love.textinput(t)
    -- Ajoute le texte tapé par l'utilisateur au message en cours de saisie
    inputText = inputText .. t
end

function love.keypressed(key)
    if key == "backspace" then
        -- Supprimer un caractère (gestion du backspace)
        inputText = inputText:sub(1, #inputText - 1)
    elseif key == "return" then
        -- Simuler l'envoi d'un message en appuyant sur "Entrée"
        table.insert(chatLog, "You: " .. inputText)
        inputText = ""
    elseif key == "tab" then
        -- Basculer entre les différentes salles de chat en appuyant sur "Tab"
        currentRoom = currentRoom % #chatRooms + 1
    end
end

function love.draw()
    -- Dessiner le fond futuriste
    drawFuturisticBackground()

    -- Dessiner l'interface utilisateur du chat
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

    -- Boîte de saisie
    love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
    love.graphics.rectangle("fill", 10, 550, 780, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(inputText, 15, 560)
end
