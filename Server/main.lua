ESX                = nil

local copsonline = 0

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('npchostage:attach')
AddEventHandler('npchostage:attach', function(source, target)
    TriggerClientEvent('npchostage:attach', -1, source, target)
end)

RegisterServerEvent('npchostage:deattach')
AddEventHandler('npchostage:deattach', function(source, target)
    TriggerClientEvent('npchostage:deattach', -1, source, target)
end)

RegisterServerEvent('npchostage:hostage')
AddEventHandler('npchostage:hostage', function(source, target)
	TriggerClientEvent('npchostage:grabhostage', -1, source, target)
end)

RegisterServerEvent('npchostage:freehostage')
AddEventHandler('npchostage:freehostage', function(source, target)
	TriggerClientEvent('npchostage:throwhostage', -1, source, target)
end)

RegisterServerEvent('npchostage:toggletrunkin')
AddEventHandler('npchostage:toggletrunkin', function(target, source)
	TriggerClientEvent('npchostage:putintrunk', -1, target, source)
end)

RegisterServerEvent('npchostage:toggletrunkout')
AddEventHandler('npchostage:toggletrunkout', function(target, source)
	TriggerClientEvent('npchostage:takeouttrunk', -1, target, source)
end)

RegisterServerEvent('npchostage:togvehiclein')
AddEventHandler('npchostage:togvehiclein', function(target, source)
	TriggerClientEvent('npchostage:putInVehicle', -1, target, source)
end)

RegisterServerEvent('npchostage:togvehicleout')
AddEventHandler('npchostage:togvehicleout', function(target, source)
	TriggerClientEvent('npchostage:OutVehicle', -1, target, source)
end)

function CountCops()
    local xPlayers = ESX.GetPlayers()
    copsonline = 0
    for i=1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if xPlayer.job.name == 'police' then
            copsonline = copsonline + 1
        end
    end
    TriggerClientEvent('npchostage:copsonline', -1, copsonline)
    SetTimeout(60000, CountCops)
end
CountCops()