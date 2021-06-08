local EnumEnumerator = {
	__gc = function(pedenum)
		if pedenum.destructor and pedenum.handle then
			pedenum.destructor(pedenum.handle)
	  	end
	  	pedenum.destructor = nil
	  	pedenum.handle = nil
	end
}
  
local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
	return coroutine.wrap(function()
		local playerid, id = initFunc()
		if not id or id == 0 then
			disposeFunc(playerid)
			return
		end
		
		local pedenum = {handle = playerid, destructor = disposeFunc}
		setmetatable(pedenum, EnumEnumerator)
		local next = true
		local player
		repeat
			player = false
			for i = 0, 32 do
				if (id == GetPlayerPed(i)) then
				player = true
				end
			end
			if not player then
			coroutine.yield(id)
			end
			next, id = moveFunc(playerid)
		until not next
		pedenum.destructor, pedenum.handle = nil, nil
		disposeFunc(playerid)
	end)
end
  
function pedenumerateObjects()
	return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end
  
function pedenumeratePeds()
	return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end
  
function pedenumerateVehicles()
	return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end
  
function pedenumeratePickups()
	return EnumerateEntities(FindFirstPickup, FindNextPickup, EndFindPickup)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1) 
        for ped in pedenumeratePeds() do
            if DoesEntityExist(ped) then
				for i,model in pairs(Config.peds) do
					if (GetEntityModel(ped) == GetHashKey(model)) then
						veh = GetVehiclePedIsIn(ped, false)
						SetEntityAsNoLongerNeeded(ped)
						SetEntityCoords(ped,10000,10000,10000,1,0,0,1)
						if veh ~= nil then
							SetEntityAsNoLongerNeeded(veh)
							SetEntityCoords(veh,10000,10000,10000,1,0,0,1)
						end
					end
				end
				for i,model in pairs(Config.removeguns) do
					if (GetEntityModel(ped) == GetHashKey(model)) then
						RemoveAllPedWeapons(ped, true)
					end
				end
				for i,model in pairs(Config.nogundrop) do
					if (GetEntityModel(ped) == GetHashKey(model)) then
						SetPedDropsWeaponsWhenDead(ped,false) 
					end
				end
			end
		end
    end
end)

Citizen.CreateThread(function()
    while true do
        SetPedDensityMultiplierThisFrame(Config.amount.peds)
        SetScenarioPedDensityMultiplierThisFrame(Config.amount.peds, Config.amount.peds)
        SetVehicleDensityMultiplierThisFrame(Config.amount.vehicles)
        SetRandomVehicleDensityMultiplierThisFrame(Config.amount.vehicles)
        SetParkedVehicleDensityMultiplierThisFrame(Config.amount.vehicles)
        Citizen.Wait(0)
    end
end)

Citizen.CreateThread(function()
	while true do
	  	Citizen.Wait(1)
	  	-- List of pickup hashes (https://pastebin.com/8EuSv2r1)
	  	RemoveAllPickupsOfType(0xDF711959)  
		RemoveAllPickupsOfType(0xF9AFB48F) 
		RemoveAllPickupsOfType(0xA9355DCD) 
		RemoveAllPickupsOfType(0x2E4C762D) 
		RemoveAllPickupsOfType(0x7E51DB8F)
		RemoveAllPickupsOfType(0x5D95B557) 
		RemoveAllPickupsOfType(0x43AAEAE6) 
		RemoveAllPickupsOfType(0xE5EB8146)
		RemoveAllPickupsOfType(0x6F38E9FB) 
	end
end)

Citizen.CreateThread(function()
	while true do Citizen.Wait(100)
		if IsPedInAnyPoliceVehicle(GetPlayerPed(-1), -1) or IsPedInAnyHeli(GetPlayerPed(-1)) then
			DisablePlayerVehicleRewards(GetPlayerPed(-1))
		end
	end
end)