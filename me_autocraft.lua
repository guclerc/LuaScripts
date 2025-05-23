-- CraftAuto : https://github.com/guclerc/LuaScripts/blob/main/me_autocraft.lua
-- Inspiré de SirEndii : https://github.com/SirEndii/Lua-Projects

--////-- Global
configChanged = true

--////-- Ecrans

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

-- Recupere un fluide
function getFluid(name)
    local fluids = me.listFluid()
    for _, fluid in ipairs(fluids) do
        if fluid.name == name then
            return fluid
        end
    end
    return nil
end

-- Vérifie un item
function checkMe(item)
    local name = item.name
    local label = item.label
    local threshold = tonumber(item.threshold)
    local isFluid = item.isFluid or false

    local meItem
    if isFluid then
        meItem = getFluid(name)
    else
        meItem = me.getItem({ name = name })
    end
    if not meItem then
        print("Introuvable dans le ME : " .. name)
        return
    end

    row = row + 1

    local labelColor = item.isFluid and colors.lightBlue or colors.lightGray
    CenterT(label, row, colors.black, labelColor, "left", false)

    local amount = tonumber(meItem.amount or 0)
    if amount < threshold then
        local toCraft = threshold - amount
        if isFluid then
            CenterT(amount/1000 .. "B/" .. threshold/1000 .. "B", row, colors.black, colors.red, "right", true)
            if not me.isFluidCrafting({ name = name }) then
                me.craftFluid({ name = name, count = toCraft })
                print("Commande de " .. toCraft .. " " .. name)
            end
        else
            CenterT(amount .. "/" .. threshold, row, colors.black, colors.red, "right", true)
            if not me.isItemCrafting({ name = name }) then
                me.craftItem({ name = name, amount = toCraft })
                print("Commande de " .. toCraft .. " " .. name)
            end
        end
        
    else
        if isFluid then
            CenterT(amount/1000 .. "B/" .. threshold/1000 .. "B", row, colors.black, colors.green, "right", true)
        else
            CenterT(amount .. "/" .. threshold, row, colors.black, colors.green, "right", true)
        end
    end
end

-- Vérifie tous les items
function checkTable(meItems)
    row = 2
    for _, item in ipairs(meItems) do
        checkMe(item)
    end
end

-- Boucle monitor
function monitorLoop()
    local label = "Craft Auto -- Kaza"
    prepareMonitor(label)
    local config = nil

    while true do
        if configChanged then
            prepareMonitor(label)
            config = loadConfig()
            configChanged = false
        end
        checkTable(config)
        sleep(1)
    end
end


--////-- Interface
function saveConfig(config)
    local sortedConfig = config
    table.sort(config, function(a, b)
        return string.lower(a.label) < string.lower(b.label)
    end)
    local file = fs.open("meautocraft_config.lua", "w")
    file.write("return " .. textutils.serialize(sortedConfig))
    file.close()
    configChanged = true
end

function loadConfig()
    local ok, config = pcall(require, "meautocraft_config")
    if ok then return config else return {} end
end

function normalizeLabel(str)
    -- Remplace les underscores par des espaces
    str = string.gsub(str, "_", " ")
    -- Met en majuscule la première lettre de chaque mot
    return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
end

-- Cherche un item en config
function findItem(config, label)
    label = string.lower(label)
    for i, item in ipairs(config) do
        if string.lower(item.label) == label then
            return i, item
        end
    end
    return nil, nil
end

-- Affichage du help
function help()
    print("Commandes : quit (q), add (a), addFluid (af), delete (d), threshold (t), name (n), label (l), get (g)")
end

-- Boucle d'interface pc
function commandLoop()
    help()
    while true do
        term.write("> ")
        local input = read()
        local args = {}
        for word in string.gmatch(input, "%S+") do table.insert(args, word) end
        local cmd = string.lower(args[1] or "")
        

        if cmd == "quit" or cmd == "q" then
            print("Arret du programme.")
            break
        end

        local config = loadConfig()
        if cmd == "add" or cmd == "a" then
            local label, name, threshold = normalizeLabel(args[2]), args[3], tonumber(args[4])
            if label and name and threshold then
                table.insert(config, { label = label, name = name, threshold = threshold })
                saveConfig(config)
                print("Ajout item : " .. label)
            else
                print("Usage : add <label> <name> <threshold>")
            end
            elseif cmd == "addfluid" or cmd == "af" then
                local label, name, threshold = normalizeLabel(args[2]), args[3], tonumber(args[4])
                if label and name and threshold then
                    table.insert(config, { label = label, name = name, threshold = threshold*1000, isFluid = true })
                    saveConfig(config)
                    print("Ajout fluide : " .. label)
                else
                    print("Usage : addfluid <label> <name> <threshold>")
                end


        elseif cmd == "delete" or cmd == "d" then
            local label = normalizeLabel(args[2])
            local index = label and findItem(config, label)
            if index then
                table.remove(config, index)
                saveConfig(config)
                print("Supprime : " .. label)
            else
                print("Introuvable : " .. (label or ""))
            end

        elseif cmd == "threshold" or cmd == "t" then
            local label, newThreshold = normalizeLabel(args[2]), tonumber(args[3])
            local index, item = findItem(config, label)
            if item and newThreshold then
                local isFluid = item.isFluid or false
                if isFluid then
                    newThreshold = newThreshold*1000
                end
                item.threshold = newThreshold
                config[index] = item
                saveConfig(config)
                print("Nouveau seuil pour " .. item.label .. ": " .. newThreshold)
            else
                print("Usage : threshold <label> <new threshold>")
            end

        elseif cmd == "name" or cmd == "n" then
            local label, newName = normalizeLabel(args[2]), args[3]
            local index, item = findItem(config, label)
            if item and newName then
                item.name = newName
                config[index] = item
                saveConfig(config)
                print("Nouveau nom pour " .. item.label .. ": " .. newName)
            else
                print("Usage : name <label> <new item name>")
            end

        elseif cmd == "label" or cmd == "l" then
            local oldLabel, newLabel = normalizeLabel(args[2]), normalizeLabel(args[3])
            local index, item = findItem(config, oldLabel)
            if item and newLabel then
                item.label = newLabel
                config[index] = item
                saveConfig(config)
                print("Label mis a jour : " .. newLabel)
            else
                print("Usage : label <ancien_label> <nouveau_label>")
            end

        elseif cmd == "get" or cmd == "g" then
            local label = normalizeLabel(args[2])
            local _, item = findItem(config, label)
            if item then
                print("Label: " .. item.label)
                print("Name: " .. item.name)
                print("Threshold: " .. item.threshold)
                print("Fluide: " .. tostring(item.isFluid or false))
            else
                print("Introuvable : " .. (label or ""))
            end

        else
            print("Commande introuvable")
            help()
        end
    end
end

--////-- Lancement en parallèle
parallel.waitForAny(monitorLoop, commandLoop)