local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local PlayerData              = {}
local IsHostageCuffed = false
local IsHostageKneeling = false
local IsHostageGrabbed = false
local PlayerHasHostage = false
local IsPlayerShielding = false
local HostageInVehicle = false
local HostageInTrunk = false
local HostageHasBagOn = false
local IsPlayerShielding = false
local HostageIsRobbed = false
local HostageAlert = true
local blipHostageTime = 5
local copsonline = 0
local peds = {}
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

Animation = function(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

GetPedInDirection = function(coordFrom, coordTo)
    local rayHandle = CastRayPointToPoint(coordFrom.x, coordFrom.y, coordFrom.z, coordTo.x, coordTo.y, coordTo.z, 12, GetPlayerPed(-1 ), 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for i = 1, #peds do
			hostage = peds[i]
			ClearPedSecondaryTask(hostage)
			SetEnableHandcuffs(hostage, false)
			DisablePlayerFiring(hostage, false)
			SetPedCanPlayGestureAnims(hostage, true)
			FreezeEntityPosition(hostage, false)
			DeleteEntity(hostage)
			IsHostageCuffed = false
			IsHostageKneeling = false
			IsHostageGrabbed = false
			PlayerHasHostage = false
			IsPlayerShielding = false
			HostageInTrunk = false
			IsPlayerShielding = false
			HostageIsRobbed = false
		end
	end
end)

RegisterNetEvent('npchostage:copsonline')
AddEventHandler('npchostage:copsonline', function(copsNumber)
    copsonline = copsNumber
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if IsControlJustPressed(0, 51) then
            player = GetPlayerPed(-1)
			_ , NPC = GetEntityPlayerIsFreeAimingAt(PlayerId())
			if GetEntityType(NPC) == 1 and GetPedType(NPC) ~= 28 and copsonline >= Config.CopsNeeded then 
				distanceToNPC = GetDistanceBetweenCoords(GetEntityCoords(player), GetEntityCoords(NPC))
				if distanceToNPC <= 15 then
					if not IsPedDeadOrDying(NPC) then
						RequestAnimDict("mp_arresting")
						Animation( "random@arrests" )
						Animation( "random@arrests@busted" )
						if IsPedInAnyVehicle(NPC) then
							if not PlayerHasHostage then
								SetBlockingOfNonTemporaryEvents(NPC, true)
								if IsPedStopped(NPC) then
									randomact = math.random(1,10)
									if randomact > 6 then
										PlayAmbientSpeech1(NPC, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									elseif randomact > 3 then
										exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.outofvehicle, type = "error", timeout = 5000})
										TaskLeaveAnyVehicle(NPC)
										Citizen.Wait(1500)
										TriggerEvent("npchostage:hostagesurrender")
										PlayAmbientSpeech1(NPC, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									end	
								else
									randomact = math.random(1,10)
									if randomact > 6 then
										PlayAmbientSpeech1(NPC, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									elseif randomact > 3 then
										exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.outofvehicle2, type = "error", timeout = 5000})
										TaskLeaveAnyVehicle(NPC)
										repeat
										Citizen.Wait(100)
										until IsPedStopped(NPC)
										TriggerEvent("npchostage:hostagesurrender")
										PlayAmbientSpeech1(NPC, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									end
								end
							else
								ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
								exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.failed, type = "error", timeout = 5000})
							end
						elseif IsPedOnFoot(NPC) then
							if PlayerHasHostage == false then
								if IsHostageKneeling ==false then
									randomact = math.random(1,10)
									if randomact > 6 then
										PlayAmbientSpeech1(NPC, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									elseif randomact > 3 then
										TriggerEvent("npchostage:hostagesurrender")
										PlayAmbientSpeech1(NPC, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
									end
								end
							else
								ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
								exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.failed, type = "error", timeout = 5000})
							end
						end
					end
				end
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
      	if IsControlPressed(6, Keys["G"]) and IsControlPressed(0 , Keys['LEFTSHIFT']) then
			ESX.UI.Menu.CloseAll()
			local elements = {}
			if IsHostageCuffed == false then
				table.insert(elements, {label = Config.msgs.cuff, value = 'handcuff'})
			else
				table.insert(elements, {label = Config.msgs.uncuff, value = 'handcuff'})
			end
			if IsHostageGrabbed == false then
				table.insert(elements, {label = Config.msgs.drag, value = 'drag'})
			else
				table.insert(elements, {label = Config.msgs.letsGo, value = 'drag'})
			end
			if IsPlayerShielding == false then
				table.insert(elements, {label = Config.msgs.bodyShield, value = 'shield'})
			else
				table.insert(elements, {label = Config.msgs.letsGo, value = 'shield'})
			end
			if HostageInVehicle == false then
				table.insert(elements, {label = Config.msgs.putInVehicle, value = 'vehicleseat'})
			else
				table.insert(elements, {label = Config.msgs.takeOutVehicle, value = 'vehicleseat'})
			end
			if HostageInTrunk == false then
				table.insert(elements, {label = Config.msgs.putInTrunk, value = 'vehicletrunk'})
			else
				table.insert(elements, {label = Config.msgs.takeOutTrunk, value = 'vehicletrunk'})
			end
	      	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'menuName',{
	        	title = Config.msgs.title,
	          	align = 'top-right',
	          	elements = elements
	        },
			function(data, menu)
				local player = GetPlayerPed(-1)
				if data.current.value == 'handcuff' then
					TriggerEvent('npchostage:handcuff')
				end
				if data.current.value == 'drag' then
					if IsEntityPlayingAnim(hostage, "mp_arresting", "idle", 3) then
						TriggerEvent('npchostage:togglegrab')
					else 
						ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
						exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.uncuffedHostage, type = "error", timeout = 5000})
					end
				end
				if data.current.value == 'shield' then
					if IsEntityPlayingAnim(hostage, "mp_arresting", "idle", 3) then
						TriggerEvent('npchostage:toglehostage')
					else 
						ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
						exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.uncuffedHostage, type = "error", timeout = 5000})
					end
				end
				if data.current.value == 'vehicleseat' then
					if IsEntityPlayingAnim(hostage, "mp_arresting", "idle", 3) then
						TriggerEvent('npchostage:togglevehicle')
					else 
						ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
						exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.uncuffedHostage, type = "error", timeout = 5000})
					end
				end
				if data.current.value == 'vehicletrunk' then
					TriggerEvent('npchostage:toggletrunk')
				end
				menu.close()
			end,function(data, menu)
				menu.close()
			end) 
	    end
	end
end)

RegisterNetEvent('npchostage:handcuff')
AddEventHandler('npchostage:handcuff', function()	
	Citizen.CreateThread(function()
		Citizen.Wait(100)
		for i = 1, #peds do
			hostage = peds[i]
			if DoesEntityExist(hostage) then
				if IsHostageCuffed == false then
					local player = GetPlayerPed(-1)
					local playerGroupId = GetPedGroupIndex(player)
					TaskPlayAnim(player, "mp_arresting", "a_uncuff", 8.0, -8, -1, 49, 0, 0, 0, 0)
					AttachEntityToEntity(hostage, player, 11816, 0, 0.3, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
					Citizen.Wait(2000)
					DetachEntity(hostage, true, false)
					ClearPedSecondaryTask(player)
					TaskPlayAnim( hostage, "random@arrests@busted", "exit", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
					Citizen.Wait(1000)
					TaskPlayAnim( hostage, "random@arrests", "kneeling_arrest_get_up", 8.0, 1.0, -1, 128, 0, 0, 0, 0 )
					Citizen.Wait(800)
					TaskPlayAnim(hostage, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
					PlayAmbientSpeech1(hostage, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
					SetPedAsGroupMember(hostage, playerGroupId)
					SetEnableHandcuffs(hostage, true)
					IsHostageCuffed = true
					PlayerHasHostage = true
					HostageTaken = true
				else
					TaskPlayAnim(player, "mp_arresting", "a_uncuff", 8.0, -8, -1, 49, 0, 0, 0, 0)
					PlayAmbientSpeech1(hostage, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
					Citizen.Wait (2000)
					RemovePedFromGroup(hostage)
					DetachEntity(hostage, true, false)
					ClearPedSecondaryTask(hostage)
					ClearPedSecondaryTask(player)
					ClearPedTasks(hostage)
					SetPedCanRagdoll(hostage, true) 
					SetBlockingOfNonTemporaryEvents(hostage, false) 
					SetEnableHandcuffs(hostage, false)
					DisablePlayerFiring(hostage, false)
					SetPedCanPlayGestureAnims(hostage, true)
					FreezeEntityPosition(hostage, false)
					PlayerHasHostage = false
					IsHostageCuffed = false
					IsHostageKneeling = false
					IsHostageGrabbed = false
					PlayerHasHostage = false
					IsPlayerShielding = false
					HostageInTrunk = false
					IsPlayerShielding = false
				end
			else
				ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07)
				exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.closer, type = "error", timeout = 5000})
			end
		end
	end)
end)

RegisterNetEvent('npchostage:togglegrab')
AddEventHandler('npchostage:togglegrab', function()
	local player = GetPlayerPed(-1)
	for i = 1, #peds do
		hostage = peds[i]
		if IsHostageGrabbed == false then
			TriggerServerEvent('npchostage:attach', player, hostage)
			IsHostageGrabbed = true
			exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.hostageStruggling, type = "error", timeout = 5000})
		elseif IsHostageGrabbed == true then
			TriggerServerEvent('npchostage:deattach', player, hostage)
			IsHostageGrabbed = false
		end
	end
end)

RegisterNetEvent('npchostage:attach')
AddEventHandler('npchostage:attach', function(source, target)
	AttachEntityToEntity(target, source, 11816, -0.3, 0.4, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
	SetBlockingOfNonTemporaryEvents(target, true)
end)

RegisterNetEvent('npchostage:deattach')
AddEventHandler('npchostage:deattach', function(source, target)
	DetachEntity(hostage, true, false)
	SetBlockingOfNonTemporaryEvents(target, true)
end)

RegisterNetEvent('npchostage:toglehostage')
AddEventHandler('npchostage:toglehostage', function()
	local player = GetPlayerPed(-1)
	for i = 1, #peds do
		hostage = peds[i]
		if IsPedArmed(player, 7) then
			if not IsPedInAnyVehicle(player) then   
				if IsPlayerShielding == false then
					Animation('missprologueig_4@hold_head_base')
					Citizen.Wait(2000)
					TriggerServerEvent('npchostage:hostage', player, hostage)
					PlayAmbientSpeech1(hostage, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
					IsPlayerShielding = true
				elseif IsPlayerShielding == true then
					TriggerServerEvent('npchostage:freehostage', player, hostage)
					IsPlayerShielding = false
				end
			end
		end
	end
end)

RegisterNetEvent('npchostage:grabhostage')
AddEventHandler('npchostage:grabhostage', function(source, target)
	AttachEntityToEntity(target, source, 11816, -0.13, 0.30, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 20, false)
	PlayAmbientSpeech1(target, "GENERIC_INSULT_HIGH", "GENERIC_FRIGHTENED_HIGH")
	TaskPlayAnim(source, 'missprologueig_4@hold_head_base', 'hold_head_loop_base_guard', 8.0, -8, -1, 49, 0, 0, 0, 0)
end)

RegisterNetEvent('npchostage:throwhostage')
AddEventHandler('npchostage:throwhostage', function(source, target)
	ClearPedTasksImmediately(source)
	ClearPedTasksImmediately(target)
	DetachEntity(target, true, false)
	DetachEntity(source, true, false)
	TaskPlayAnim(target, "mp_arresting", "idle", 8.0, -8, -1, 49, 0, 0, 0, 0)
	PlayAmbientSpeech1(target, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_NORMAL_CLEAR")
end)

RegisterNetEvent('npchostage:togglevehicle')
AddEventHandler('npchostage:togglevehicle', function()
	local player = GetPlayerPed(-1)
	for i = 1, #peds do
		hostage = peds[i]
		if not IsPedInAnyVehicle(player) then   
			if HostageInVehicle == false then
				TriggerServerEvent('npchostage:togvehiclein', hostage, player)
				HostageInVehicle = true
			elseif HostageInVehicle == true then
				TriggerServerEvent('npchostage:togvehicleout', hostage)
				HostageInVehicle = false
			end
		end
	end
end)

RegisterNetEvent('npchostage:putInVehicle')
AddEventHandler('npchostage:putInVehicle', function(target, source)
	local coords = GetEntityCoords(source)
	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle = GetClosestVehicle(coords.x,  coords.y,  coords.z,  5.0,  0,  71)
		if DoesEntityExist(vehicle) then
			local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
			local freeSeat = nil
			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle,  i) then
					freeSeat = i
					break
				end
			end
			if freeSeat ~= nil then
				Citizen.Wait(0)
				TaskWarpPedIntoVehicle(target,  vehicle,  freeSeat)
				Citizen.Wait(300)
				SetPedConfigFlag(target, 292, true)
			end
		end
	end
end)

RegisterNetEvent('npchostage:OutVehicle')
AddEventHandler('npchostage:OutVehicle', function(target)
	Citizen.Wait(200)
	SetPedConfigFlag(target, 292, false)
	Citizen.CreateThread(function()
		for n =0, GetVehicleMaxNumberOfPassengers(GetVehiclePedIsIn(target,true)),1 do
			Citizen.Wait(0)
			SetPedConfigFlag(GetPedInVehicleSeat(GetVehiclePedIsIn(target,true),n),292,false)
			TaskLeaveAnyVehicle(GetPedInVehicleSeat(GetVehiclePedIsIn(target,true),n))
			Citizen.Wait(100)
			SetPedConfigFlag(GetPedInVehicleSeat(GetVehiclePedIsIn(target,true),n),292,false)
		end
	end)
end)

RegisterNetEvent('npchostage:toggletrunk')
AddEventHandler('npchostage:toggletrunk', function()
	local player = GetPlayerPed(-1)
	for i = 1, #peds do
		hostage = peds[i]
		if IsPedArmed(player, 7) then
			if not IsPedInAnyVehicle(player) then   
				if HostageInTrunk == false then
					if IsEntityPlayingAnim(hostage, "mp_arresting", "idle", 3) then
						Citizen.Wait(2000)
						TriggerServerEvent('npchostage:toggletrunkin', hostage, player)
					else 
						ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07) 
						exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.hostageNotCuffed, type = "error", timeout = 5000})
					end
				elseif HostageInTrunk == true then
					if IsEntityPlayingAnim(hostage, "timetable@floyd@cryingonbed@base", "base", 3) then
						TriggerServerEvent('npchostage:toggletrunkout', hostage, player)
					else
						ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.07) 
						exports.pNotify:SendNotification({layout = "centerLeft", text = Config.msgs.hostageNotInTruck, type = "error", timeout = 5000})
					end
				end
			end
		end
	end
end)

RegisterNetEvent('npchostage:putintrunk')
AddEventHandler('npchostage:putintrunk', function(target, source)
	local playercoords = GetEntityCoords(source)
	if IsAnyVehicleNearPoint(playercoords.x, playercoords.y, playercoords.z, 5.0) then
		local vehicle = GetClosestVehicle(playercoords.x,  playercoords.y,  playercoords.z,  5.0,  0,  71)
		if DoesEntityExist(vehicle) then
			local trunk = GetEntityBoneIndexByName(vehicle, 'boot')
			if trunk ~= -1 then
				local coords = GetWorldPositionOfEntityBone(vehicle, trunk)
				if DoesEntityExist(target) then
					DetachEntity(target, true, false)
					Citizen.Wait(0)
					ClearPedSecondaryTask(target)
					SetCarBootOpen(vehicle)
					Wait(350)
					local offsetXYZ, offsetZ = tonumber('-'..GetDistanceBetweenCoords(GetEntityCoords(vehicle), coords, true)), coords.z - GetEntityCoords(vehicle).z
					AttachEntityToEntity(target, vehicle, -1, vector3(0.0, offsetXYZ, offsetZ), vector3(360.0, 360.0, 360.0), false, false, false, true, 20, true)	
					Animation('timetable@floyd@cryingonbed@base')
					TaskPlayAnim(target, 'timetable@floyd@cryingonbed@base', 'base', 8.0, -8.0, -1, 1, 0, false, false, false)
					Wait(1500)
					SetPedConfigFlag(target, 292, true)						
					SetVehicleDoorShut(vehicle, 5)
					HostageInTrunk = true
				end
			end
			Wait(0)
		end
	end
end)

RegisterNetEvent('npchostage:takeouttrunk')
AddEventHandler('npchostage:takeouttrunk', function(target, source)
	Citizen.CreateThread(function()
		local playercoords = GetEntityCoords(source)
		local vehicle = GetClosestVehicle(playercoords.x,  playercoords.y,  playercoords.z,  5.0,  0,  71)
		SetPedConfigFlag(target, 292, false)
		SetCarBootOpen(vehicle)
		SetEntityCollision(target, true, true)
		Wait(750)
		DetachEntity(target, true, true)
		SetEntityVisible(target, true, false)
		ClearPedTasks(target)
		SetEntityCoords(target, GetOffsetFromEntityInWorldCoords(source, 1.0, 0.0, -0.75))
		Wait(250)
		SetVehicleDoorShut(vehicle, 5)
		HostageInTrunk = false
	end)
end)

RegisterNetEvent('npchostage:hostagesurrender')
AddEventHandler('npchostage:hostagesurrender', function()
	Citizen.CreateThread(function()
		local hostage = NPC
		SetBlockingOfNonTemporaryEvents(hostage, true) 
		SetPedCanRagdoll(hostage, true) 
		TaskPlayAnim(hostage, "random@arrests", "idle_2_hands_up", 8.0, 2.0, -1, 2, 0, 0, 0, 0 )
		Citizen.Wait (4000)
		TaskPlayAnim(hostage, "random@arrests", "kneeling_arrest_idle", 8.0, 2.0, -1, 2, 0, 0, 0, 0 )
		GetWeaponObjectFromPed(hostage,false)
		RemoveAllPedWeapons(hostage)
		TaskPlayAnim(hostage, "random@arrests@busted", "enter", 8.0, 3.0, -1, 2, 0, 0, 0, 0 )
		Citizen.Wait (500)
		TaskPlayAnim(hostage, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0 )
		randomact = math.random(1,10)
		table.insert(peds, hostage)
	end)
end)

Citizen.CreateThread(function() 
	for i = 1, #peds do
		hostage = peds[i]
		Citizen.Wait(1000)
		distanceToPed = GetDistanceBetweenCoords(GetPlayerPed(-1), hostage)
		if IsPedInAnyVehicle(player) then
			for i=0,GetGroupSize(GetPlayerGroup(player)),1 do
				Citizen.Wait(0)
				if IsVehicleSeatFree(GetVehiclePedIsIn(player),1) then
					TaskEnterVehicle(GetPedAsGroupMember(GetPlayerGroup(player),i), GetVehiclePedIsIn(player), -1, 1, 2.0, 1, 0)
				else
					TaskEnterVehicle(GetPedAsGroupMember(GetPlayerGroup(player),i), GetVehiclePedIsIn(player), -1, 2, 2.0, 3, 0)
				end
			end
		end
	end
end)

Citizen.CreateThread( function()
    while true do
        Wait(0)
        local player = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, player.x, player.y, player.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
		DecorSetInt(GetPlayerPed(-1), "Kidnapper", 2)
		if HostageTaken then
			if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					local sex = nil
					if skin.sex == 0 then
						sex = "male"
					else
						sex = "female"
					end
					TriggerServerEvent('HostageInProgressPos', player.x, player.y, player.z)
					if s2 == 0 then
						TriggerServerEvent('HostageInProgressS1', street1, sex)
					elseif s2 ~= 0 then
						TriggerServerEvent("HostageInProgress", street1, street2, sex)
					end
				end)
				Wait(3000)
			else
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					local sex = nil
					if skin.sex == 0 then
						sex = "male"
					else
						sex = "female"
					end
					TriggerServerEvent('HostageInProgressPos', player.x, player.y, player.z)
					if s2 == 0 then
						TriggerServerEvent('HostageInProgressS1', street1, sex)
					elseif s2 ~= 0 then
						TriggerServerEvent("HostageInProgress", street1, street2, sex)
					end
				end)
				Wait(3000)
			end
		end
    end
end)