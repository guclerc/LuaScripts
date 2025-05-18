-- Chargement des périphériques
me = peripheral.find("meBridge")
mon = peripheral.find("monitor")

-- Chargement dynamique de la configuration
function loadConfig()
    local ok, config = pcall(require, "meautocraft_config")
    if ok then
        return config
    else
        print("Erreur de chargement du fichier de configuration.")
        return {}
    end
end

-- Méthode pour afficher du texte centré ou positionné
function CenterT(text, line, txtback, txtcolor, pos, clear)
    monX, monY = mon.getSize()
    mon.setTextColor(txtcolor)
    length = string.len(text)
    dif = math.floor(monX - length)
    x = math.floor(dif / 2)

    if pos == "head" then
        mon.setCursorPos(x + 1, line)
        mon.write(text)
    elseif pos == "left" then
        if clear then clearBox(2, 2 + length, line, line) end
        mon.setCursorPos(2, line)
        mon.write(text)
    elseif pos == "right" then
        if clear then clearBox(monX - length - 8, monX, line, line) end
        mon.setCursorPos(monX - length, line)
        mon.write(text)
    end
end

-- Efface une zone du moniteur
function clearBox(xMin, xMax, yMin, yMax)
    mon.setBackgroundColor(colors.black)
    for xPos = xMin, xMax do
        for yPos = yMin, yMax do
            mon.setCursorPos(xPos, yPos)
            mon.write(" ")
        end
    end
end

-- Préparation de l'affichage initial
function prepareMonitor(label)
    mon.clear()
    CenterT(label, 1, colors.black, colors.white, "head", false)
end

-- Vérifie un item
function checkMe(item)
    local name = item.name
    local label = item.label
    local threshold = tonumber(item.threshold)

    local meItem = me.getItem({ name = name })
    if not meItem then
        print("Introuvable dans le ME : " .. name)
        return
    end

    local amount = tonumber(meItem.amount or 0)
    row = row + 1
    CenterT(label, row, colors.black, colors.lightGray, "left", false)

    if amount < threshold then
        CenterT(amount .. "/" .. threshold, row, colors.black, colors.red, "right", true)

        if not me.isItemCrafting({ name = name }) then
            local toCraft = threshold - amount
            me.craftItem({ name = name, amount = toCraft })
            print("Craft de " .. name .. " x" .. toCraft)
        end
    else
        CenterT(amount .. "/" .. threshold, row, colors.black, colors.green, "right", true)
    end
end

-- Vérifie tous les items
function checkTable(meItems)
    row = 2
    for _, item in ipairs(meItems) do
        checkMe(item)
    end
end

-- Boucle principale
function monitorLoop()
    local label = "Automatic"
    prepareMonitor(label)

    while true do
        local config = loadConfig()
        checkTable(config)
        sleep(1)
    end
end

-- Appel initial
monitorLoop()
