ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

local playergang
playerLoaded = false

hpstarted = false
hpcoords = nil
hpblip = nil
finish = false
lootblock = false
Leader, Second, Third = {}, {}, {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    Citizen.Wait(2000)
    playerLoaded = true
    ESX.TriggerServerCallback('trp-hp:getplayergang', function(returnval)
        playerGang = returnval
    end)
    ESX.TriggerServerCallback('trp-hp:ifstart', function(result, coord_x, coord_y, coord_z)
        if result then
            hpstarted = true
            hpcoords = vector3(coord_x, coord_y, coord_z)
            hpblip = AddBlipForCoord(coord_x, coord_y, coord_z)
            SetBlipSprite(hpblip,  164)
            SetBlipColour(hpblip,  0)
            SetBlipScale(hpblip, 0.9)
            SetBlipDisplay(hpblip, 4)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString('- Hardpoint')
            EndTextCommandSetBlipName(hpblip)
        else
            RemoveBlip(hpblip)
            playerGang = nil
            playerLoaded = false
            hpstarted = false
            hpcoords = nil
            hpblip = nil
            Leader, Second, Third = {}, {}, {}
            RemoveBlip(hpblip)
        end
    end)
end)



RegisterNetEvent('trp-hp:SyncLeaderBoard')
AddEventHandler('trp-hp:SyncLeaderBoard', function(Table)
    if Table then 
        local index = 1
        for k,v in pairs(Table) do 
            if index == 1 then
                index = index+1
                Leader = v
            elseif index == 2 then 
                index = index+1
                Second = v
            elseif index == 3 then
                index = index+1
                Third = v
            else
                return
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10 * 60 * 1000)
        playerLoaded = true
        ESX.TriggerServerCallback('trp-hp:getplayergang', function(returnval)
            playerGang = returnval
        end)
    end
end)

RegisterNetEvent('trp-hp:client:hpstart')
AddEventHandler('trp-hp:client:hpstart', function(coord_x, coord_y, coord_z)
    hpstarted = true
    hpcoords = vector3(coord_x, coord_y, coord_z)
    hpblip = AddBlipForCoord(coord_x, coord_y, coord_z)
    SetBlipSprite(hpblip,  164)
    SetBlipColour(hpblip,  0)
    SetBlipScale(hpblip, 0.9)
    SetBlipDisplay(hpblip, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('- Hardpoint')
    EndTextCommandSetBlipName(hpblip)
    while true do
        wait = 1000
        local Players = GetPlayerPed(-1)
        local PlayerCoords = GetEntityCoords(Players)
        local plycrds = vector3(PlayerCoords['x'], PlayerCoords['y'], PlayerCoords['z'])
        local Distance = #(plycrds - hpcoords)
        if hpstarted and playerLoaded and playerGang then
            if Distance < 1000.0 then
                wait = 0
                if Distance < 800.0 then
                    DrawMarker(1, hpcoords.x, hpcoords.y, hpcoords.z+50.0, 0.0, 0.0, 0.0, 0, 180.0, 0.0, 50.0, 50.0, 100.0, 255, 0, 0, 150, false, true, 2, false, false, false, false)
                end
                if Distance < 25.0 then
                    lootblock = true
                else
                    lootblock = false
                end
            end
        end
        Citizen.Wait(wait)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if hpstarted then
            if lootblock then
                TriggerEvent('viber:hpzoneactive')
            else
                TriggerEvent('viber:hpzonedeactive')
            end
        end
    end
end)

CreateThread(function()
	while true do
		if lootblock then
			ExecuteThread()
		else
			Wait(1000)
		end
		Wait(0)
	end
end)

local alreadydeath = false
function ExecuteThread()
	local myPed = PlayerPedId()
	if IsEntityDead(myPed) then
		local killerPed = GetPedSourceOfDeath(myPed)
		if IsEntityAPed(killerPed) and IsPedAPlayer(killerPed) and not alreadydeath then
			alreadydeath = true
			local player = NetworkGetPlayerIndexFromPed(killerPed)
			local sourceKiller = GetPlayerServerId(player)
            print(sourceKiller)
			TriggerServerEvent('almez-hardpoint:AddStatistics', sourceKiller)
		end
    else
        alreadydeath = false
	end
end


KILLSTREAK = 0
RegisterNetEvent('almez-hardpoint:UpdateKillstreak', function(killCount)
    KILLSTREAK = killCount
end)

Citizen.CreateThread(function()
	while true do
        wait = 1000
        local Players = PlayerPedId()
        local PlayerCoords = GetEntityCoords(Players)
        if hpstarted and playerLoaded and playerGang then
            local Distance = #(PlayerCoords - hpcoords)
            if Distance < 300.0 then
                wait = 0
                if Distance < 100.0 then
                    if Leader?.label then
                        Gui.DrawBar('~r~1st', Leader.label .. " - " .. Leader.points, 5, {r=255,b=255,g=255,a=255}, true)
                        Gui.DrawBar('~y~2nd', Second.label .. " - " .. Second.points, 4, {r=255,b=255,g=255,a=255}, true)
                        Gui.DrawBar('~b~3th', Third.label .. " - " .. Third.points, 3, {r=255,b=255,g=255,a=255}, true)
                        Gui.DrawBar('~w~KILLSTREAK', KILLSTREAK, 2, {r=255,b=255,g=255,a=255}, true)
                        Gui.DrawBar('~w~KILL REWARD', "$"..(KILLSTREAK + 1) * 5000, 1, {r=255,b=255,g=255,a=255}, true)
                    end
                end
            else
                wait = 1000
            end
        end
        Citizen.Wait(wait)
	end
end)

RegisterNetEvent('trp-hp:client:hpfinish')
AddEventHandler('trp-hp:client:hpfinish', function()
    RemoveBlip(hpblip)
    playerGang = nil
    playerLoaded = false
    hpstarted = false
    hpcoords = nil
    hpblip = nil
    Leader, Second, Third = {}, {}, {}
    finish = true
end)


AddEventHandler('onClientResourceStop', function (resourceName)
    print('The resource ' .. resourceName .. ' has been stopped on the client.')
  end)