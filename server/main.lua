ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

GangsTable = {}
HpTable = {started = false, coords = nil}

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    local data_gangs = MySQL.Sync.fetchAll('SELECT * FROM gangs', {})
    for k,v in pairs(data_gangs) do GangsTable[v.name] = {name = v.name, label = v.label, points = 0} end
end)

-- RegisterCommand('testhp', function(source)
--     StartEvent()
-- end)

StartEvent = function()
    if not HpTable.started then
        HpTable.started = true
        local sans = 11
        if sans >= 10 then
            HpTable.coords = vector3(1099.44, 67.75, 80.89)
            TriggerClientEvent('trp-hp:client:hpstart', -1, HpTable.coords['x'], HpTable.coords['y'], HpTable.coords['z'])
        elseif sans >= 5 and sans < 10 then
            HpTable.coords = vector3(1714.13, -1638.86, 112.49)
            TriggerClientEvent('trp-hp:client:hpstart', -1, HpTable.coords['x'], HpTable.coords['y'], HpTable.coords['z'])
        else
            HpTable.coords = vector3(-1163.31, -1760.58, 3.95)
            TriggerClientEvent('trp-hp:client:hpstart', -1, HpTable.coords['x'], HpTable.coords['y'], HpTable.coords['z'])
        end
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
        chatMessage(-1, "[^1Hardpoint^0]", Config.Announces['1'].text)
    end
end

FinishEvent = function()
    GangsTable = {}
    HpTable.started = false
    TriggerClientEvent('trp-hp:client:hpfinish', -1)
    local data_gangs = MySQL.Sync.fetchAll('SELECT * FROM gangs', {})
    for k,v in pairs(data_gangs) do GangsTable[v.name] = {name = v.name, label = v.label, points = 0} end
    HpTable = {started = false, coords = nil}
    playerGangs = {}
end

Citizen.CreateThread(function()
    while true do 
        Citizen.Wait(2700000)
        StartEvent()
    end
end)

playerGangs = {}
Citizen.CreateThread(function()
    while true do
        Wait(2000)
        local Players = ESX.GetPlayers()
        local currentGangs = {}
        local insideGangs = {}
        if HpTable.started then
            local inLoop = true
            for i = 1, #Players do
                local PlayerIdentifier = ESX.GetIdentifier(Players[i]) 
                local playerCoords = GetEntityCoords(GetPlayerPed(Players[i]))
                local dist = #(playerCoords - vector3(HpTable.coords.x, HpTable.coords.y, HpTable.coords.z))
                if dist < 25 then 
                    local gang = false
                    if playerGangs[Players[i]] then
                        gang = playerGangs[Players[i]]
                    else
                        local playerQuery = MySQL.Sync.fetchAll('SELECT gang FROM users WHERE identifier = ?', {PlayerIdentifier})
                        gang = playerQuery[1].gang
                        playerGangs[Players[i]] = gang
                    end
                    if gang and not insideGangs[gang] then
                        MySQL.Async.fetchScalar('SELECT is_dead FROM users WHERE identifier = @identifier', {
                            ['@identifier'] = PlayerIdentifier
                        }, function(isDead)
                            if not isDead then
                                table.insert(currentGangs, gang)
                                insideGangs[gang] = true
                            end
                        end)
                    end
                end
                if i == #Players then inLoop = false end
            end
            repeat Wait(100) until(not inLoop)
            if #currentGangs == 1 then
                if GangsTable[currentGangs[1]] then
                    GangsTable[currentGangs[1]].points = GangsTable[currentGangs[1]].points + 1
                    if GangsTable[currentGangs[1]].points == 50 then 
                        chatMessage(-1, "[^1Hardpoint^0]", GangsTable[currentGangs[1]].label..' Gang reached 50 points!')
                    elseif GangsTable[currentGangs[1]].points == 100 then 
                        chatMessage(-1, "[^1Hardpoint^0]", GangsTable[currentGangs[1]].label..' Gang reached 100 points!')
                    elseif GangsTable[currentGangs[1]].points == 150 then 
                        chatMessage(-1, "[^1Hardpoint^0]", GangsTable[currentGangs[1]].label..' Gang reached 150 points!')
                    elseif GangsTable[currentGangs[1]].points == 200 then 
                        chatMessage(-1, "[^1Hardpoint^0]", 'Hardpoint won by '..GangsTable[currentGangs[1]].label..' Gang ! REWARDED | MONEY : $1,200,000  ITEMS | 4x APPISTOLS')
                        FinishEvent()
                        MySQL.Async.execute('UPDATE gangs SET wins = wins + 1 WHERE name = @name', {
                            ['@name'] = GangsTable[currentGangs[1]].name
                        }, function() end)
                        print(GangsTable[currentGangs[1]].name, Config.Reward_Item, Config.Reward_Item_Count, Config.Reward_Money)
                        TriggerEvent('esx_gangs:hp-reward', GangsTable[currentGangs[1]].name, Config.Reward_Item, Config.Reward_Item_Count, Config.Reward_Money)
                    end
                end
            end
            local sortTable = {}
            for k,v in pairs(GangsTable) do 
                table.insert(sortTable, v)
            end
            table.sort(sortTable, function(a,b) return a.points > b.points end)
            TriggerClientEvent('trp-hp:SyncLeaderBoard', -1, sortTable)
            currentGangs = {}
        end
    end
end)

local KillCounts = {}
RegisterServerEvent('almez-hardpoint:AddStatistics', function(killer)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    print("hp", source, killer)
    if xPlayer then 
        local targetPly = ESX.GetPlayerFromId(killer)
        if targetPly then 
            KillCounts[killer] = KillCounts[killer] and KillCounts[killer] + 1 or 1
            targetPly.addMoney(KillCounts[killer] * 5000)
            TriggerClientEvent('almez-hardpoint:UpdateKillstreak', killer, KillCounts[killer])
            MySQL.Sync.execute("UPDATE users SET dzkills=dzkills + 1 WHERE identifier=@identifier", {['@identifier'] = targetPly.identifier})
        end
        KillCounts[src] = 0
        TriggerClientEvent('almez-hardpoint:UpdateKillstreak', src, KillCounts[src])
    end
end)

ESX.RegisterServerCallback('trp-hp:getplayergang', function(source, cb) 
    local PlayerIdentifier = ESX.GetIdentifier(source) 
    local playerQuery = MySQL.Sync.fetchAll('SELECT gang FROM users WHERE identifier = ?', {PlayerIdentifier})
    local gang = playerQuery[1].gang
    cb(gang)
end)

ESX.RegisterServerCallback('trp-hp:ifstart', function(source, cb) 
    if HpTable.started then
        TriggerClientEvent('trp-hp:client:hpstart', source, HpTable.coords.x, HpTable.coords.y, HpTable.coords.z)
        cb(true, HpTable.coords.x, HpTable.coords.y, HpTable.coords.z)
    else
        cb(false)
    end
end)

function chatMessage(target, author, msg)
    TriggerClientEvent('chat:addMessage', target, {
        args = { author, msg }
    })
end

AddEventHandler('onResourceStop', function(resourceName)
    print('The resource ' .. resourceName .. ' was stopped.')
  end)