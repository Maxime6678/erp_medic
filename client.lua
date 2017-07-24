------------------------------------------------------------------------------------
--									   Variables
------------------------------------------------------------------------------------

local showHospitalBlip = true

isMedic = false
rank = nil
IsInService = false
pos_player = nil

rank_id = {
	["eleve"] = 1,
	["infirmier"] = 2,
	["medecin"] = 3,
	["medecin-chef"] = 4,
	["directeur"] = 5,
}

pos_medic = {
	hospital = {x = 1151.31, y = -1529.95, z = 34.9904},
	service = {x = 1155.26, y = -1520.82, z = 34.84},
	vehicle = {x = 1140.41, y = -1608.15, z = 34.6939},
	depot = {x = 0, y = 0, z = 0},
}

lang = {
	["blip"] = "Hospital",
	["get_service"] = "Press ~INPUT_CONTEXT~ to start your service",
	["get_service_notif"] = "You have start your service",
	["drop_service"] = "Press ~INPUT_CONTEXT~ to stop your service",
	["drop_service_notif"] = "You have stop your service",
	["get_ambulance"] = "Press ~INPUT_CONTEXT~ to get your ambulance",
	["drop_ambulance"] = "Press ~INPUT_CONTEXT~ to deposit your ambulance",
	["phone_recall"] = "Please re-call in a few seconds",
	["phone_noservice"] = "No doctor in service",
	["phone_notaken"] = "No doctor has taken your call",
	["phone_taken"] = "A doctor has taken your call, he coming soon",
	["phone_gps"] = "Coordinate sent on your GPS ...",
	["phone_incomming_coma"] = "~h~~r~COMA~n~~n~~b~%s ~w~fell into a coma !",
	["phone_incomming"] = "~h~~b~MEDIC~n~~n~~b~%s call a doctor !",
	["phone_reason"] = "~b~Reason: ~w~%s",
	["phone_accept"] = "Press ~h~~g~Y ~w~for accept the call",
	["phone_accepted"] = "%s accepted the call of %s",
	["in_coma"] = "You are in coma !",
	["in_ko"] = "You are KO !",
	["key_call"] = "Press ~g~E ~w~for call an ambulance",
	["key_respawn"] = "Press ~r~X ~w~for respawn",
	['res'] = 'You have been resuscitated',
}

------------------------------------------------------------------------------------
--								 Basic Check & Functions
------------------------------------------------------------------------------------

local debug = false

AddEventHandler("playerSpawned", function()
	TriggerServerEvent("erp:checkIsMedic")
	debug = true
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	if not debug then
		TriggerServerEvent("erp:checkIsMedic")
	end
end)

RegisterNetEvent("erp:setMedic")
AddEventHandler("erp:setMedic", function(i, r)
	isMedic = tonumber(i)
	rank = r
end)

Citizen.CreateThread(function()
	if showHospitalBlip then
		local hospital_blip = AddBlipForCoord(pos_medic.hospital.x, pos_medic.hospital.y, pos_medic.hospital.z)
		SetBlipSprite(hospital_blip, 416)
		SetBlipAsShortRange(hospital_blip, true)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(lang["blip"])
		EndTextCommandSetBlipName(hospital_blip)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		pos_player = GetEntityCoords(GetPlayerPed(-1), false)
	end
end)

function IsInVehicle()
	return IsPedSittingInAnyVehicle(GetPlayerPed(-1))
end

function drawNotification(text)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(text)
	DrawNotification(false, false)
end

function getUniforme()
	SetPedComponentVariation(GetPlayerPed(-1), 11, 13, 3, 2)
	SetPedComponentVariation(GetPlayerPed(-1), 8, 15, 0, 2)
	SetPedComponentVariation(GetPlayerPed(-1), 4, 9, 3, 2)
	SetPedComponentVariation(GetPlayerPed(-1), 3, 92, 0, 2)
	SetPedComponentVariation(GetPlayerPed(-1), 6, 25, 0, 2)
end

function getAmbulance()
    local vehicle = GetHashKey("ambulance")
 
    RequestModel(vehicle)
 
    while not HasModelLoaded(vehicle) do
        Wait(1)
    end
 
    local spawned_car = CreateVehicle(vehicle, pos_player.x, pos_player.y, pos_player.z, 0.0, true, false)
    SetVehicleHasBeenOwnedByPlayer(spawned_car, true)
    local pid = NetworkGetNetworkIdFromEntity(spawned_car)
    SetNetworkIdCanMigrate(pid, true)
    SetVehicleOnGroundProperly(spawned_car)
    SetPedIntoVehicle(myPed, spawned_car, -1)
    SetModelAsNoLongerNeeded(vehicle)
    local plate = createPlateFromJob()
    SetVehicleNumberPlateText(spawned_car, "MEDIC")
    SetEntityAsMissionEntity(spawned_car, true, true)
end

function dropAmbulance()
	local ped = GetPlayerPed(-1)
 
    if (DoesEntityExist(ped) and not IsEntityDead(ped)) then
        local pos = GetEntityCoords(ped)
 
        if (IsInVehicle()) then
            local vehicle = GetVehiclePedIsIn(ped, false)
 
            if IsVehicleModel(vehicle, GetHashKey(model, _r)) then
                if (GetPedInVehicleSeat( vehicle, -1 ) == ped) then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(vehicle))
                end
            end
        end
    end
end

------------------------------------------------------------------------------------
--							   Hospital Positions & Markers
------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	Citizen.Wait(500)
	while true do
		Citizen.Wait(0)
		if isMedic == 1 then

			-- Draw marker
			if (Vdist(pos_medic.hospital.x, pos_medic.hospital.y, pos_medic.hospital.z, pos_player.x, pos_player.y, pos_player.z) < 70.0) then
				DrawMarker(1, pos_medic.service.x, pos_medic.service.y, pos_medic.service.z - 1, 0, 0, 0, 0, 0, 0, 2.0001, 2.0001, 0.6000, 0, 155, 255, 200, 0, 0, 0, 0)
				DrawMarker(1, pos_medic.vehicle.x, pos_medic.vehicle.y, pos_medic.vehicle.z - 1, 0, 0, 0, 0, 0, 0, 2.0001, 2.0001, 0.6000, 0, 155, 255, 200, 0, 0, 0, 0)
				DrawMarker(1, pos_medic.depot.x, pos_medic.depot.y, pos_medic.depot.z - 1, 0, 0, 0, 0, 0, 0, 3.0001, 3.0001, 0.6000, 241, 196, 15, 200, 0, 0, 0, 0) -- rgb(241, 196, 15)
			end

			-- Service
			if (Vdist(mineur_pos.vetement.x, mineur_pos.vetement.y, mineur_pos.vetement.z, pos_player.x, pos_player.y, pos_player.z) < 4.0) then
				if not IsInService then
					DisplayHelpText(lang["get_service"])
					if IsControlJustReleased(1, 38) then
						getUniforme()
						IsInService = true
						TriggerServerEvent("erp:ServiceMedicOn")
						drawNotification(lang["get_service_notif"])
					end
				else
					DisplayHelpText(lang["drop_service"])
					if IsControlJustReleased(1, 38) then
						TriggerServerEvent("skin_customization:SpawnPlayer")
						IsInService = false
						TriggerServerEvent("erp:ServiceMedicOff")
						drawNotification(lang["drop_service_notif"])
					end
				end
			end

			-- Vehicle spawn
			if (Vdist(pos_medic.vehicle.x, pos_medic.vehicle.y, pos_medic.vehicle.z, pos_player.x, pos_player.y, pos_player.z) < 4.0) then
				DisplayHelpText(lang["get_ambulance"])
				if IsControlJustReleased(1, 38) then
					getAmbulance()
				end
			end

			-- Vehicle depot
			if (Vdist(pos_medic.depot.x, pos_medic.depot.y, pos_medic.depot.z, pos_player.x, pos_player.y, pos_player.z) < 6.0) then
				dropAmbulance()
			end

		end
	end
end)

------------------------------------------------------------------------------------
--								   Call System
------------------------------------------------------------------------------------

local haveCall = false
local haveTarget = false
local caller = {}

Citizen.CreateThread(function()
	Citizen.Wait(500)
    while true do
        Citizen.Wait(0)

        if not haveTarget then
            if IsControlJustPressed(1, 246) and haveCall then
            	drawNotification(lang["phone_gps"])
                TriggerServerEvent("erp:getCallMedic")
                caller.blip = AddBlipForCoord(caller.pos.x, caller.pos.y, caller.pos.z)
                SetBlipRoute(caller.blip, true)
                haveTarget = true
                haveCall = false
            end
        end

        if haveTarget then
            DrawMarker(1, caller.pos.x, caller.pos.y, caller.pos.z, 0, 0, 0, 0, 0, 0, 2.001, 2.0001, 0.5001, 0, 155, 255, 200, 0, 0, 0, 0)
            local playerPos = GetEntityCoords(GetPlayerPed(-1), true)
            if Vdist(caller.pos.x, caller.pos.y, caller.pos.z, playerPos.x, playerPos.y, playerPos.z) < 2.0 then
                RemoveBlip(caller.blip)
                haveTarget = false
            end
        end

    end
end)

RegisterNetEvent('erp:callMedicResponce')
AddEventHandler('erp:callMedicResponce', function(c)
	if c == 0 then
		drawNotification(lang["phone_recall"])
	elseif c == 1 then
		drawNotification(lang["phone_noservice"])
	elseif c == 2 then
		drawNotification(lang["phone_notaken"])
	elseif c == 3 then
		drawNotification(lang["phone_taken"])
	end
end)

RegisterNetEvent('erp:callIncomingComaMedic')
AddEventHandler('erp:callIncomingComaMedic', function(c, p)
    if not haveTarget then
        drawNotification(string.format(lang["phone_incomming_coma"], c))
        drawNotification(lang["phone_accept"])
        caller.pos = p
        haveCall = true
        SetTimeout(15000, function()
        	haveCall = false
		end)
    end
end)

RegisterNetEvent("erp:callIncomingMedic")
AddEventHandler("erp:callIncomingMedic", function(c, r, p)
	if not haveTarget then
        drawNotification(string.format(lang["phone_incomming"], c))
        drawNotification(string.format(lang["phone_reason"], r))
        drawNotification(lang["phone_accept"])
        caller.pos = p
        haveCall = true
        SetTimeout(15000, function()
        	haveCall = false
		end)
    end
end)

RegisterNetEvent('erp:callMedicTaken')
AddEventHandler('erp:callMedicTaken', function(c, p)
	haveCall = false
	drawNotification(string.format(lang["phone_accepted"], p, c))
end)
