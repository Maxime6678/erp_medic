------------------------------------------------------------------------------------
--									   Variables
------------------------------------------------------------------------------------

local isDead = false
local isKO = false
local previousPos = nil
local canCallAmbulance = false
local canRespawn = false

------------------------------------------------------------------------------------
--								    KO & Death Screen
------------------------------------------------------------------------------------

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	while true do
		Citizen.Wait(0)
		isDead = IsEntityDead(GetPlayerPed(-1))

		if isKO and previousPos ~= pos_player then
			isKO = false
		end

		if (GetEntityHealth(GetPlayerPed(-1)) < 120 and not isDead and not isKO) then
			--if (IsPedInMeleeCombat(GetPlayerPed(-1))) then
			SetPlayerKO(PlayerId(), GetPlayerPed(-1))
			--end
		end

		previousPos = pos_player
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	while true do
		Citizen.Wait(0)

		if IsEntityDead(PlayerPedId()) then
			StartScreenEffect("DeathFailOut", 0, 0)
			ShakeGameplayCam("DEATH_FAIL_IN_EFFECT_SHAKE", 1.0)

			local scaleform = RequestScaleformMovie("MP_BIG_MESSAGE_FREEMODE")

			if HasScaleformMovieLoaded(scaleform) then
				Citizen.Wait(0)

				PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
				BeginTextComponent("STRING")
				AddTextComponentString(lang["in_coma"])
				EndTextComponent()
				PopScaleformMovieFunctionVoid()

				Citizen.Wait(500)

				while IsEntityDead(PlayerPedId()) do
				DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
				Citizen.Wait(0)
			end

			StopScreenEffect("DeathFailOut")
		end
		end
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	while true do
		Citizen.Wait(0)

		-- Call Ambulance
		if canCallAmbulance and isDead then
			if IsControlJustPressed(1, 38) then
				local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
            	TriggerServerEvent("erp:callComaMedic", {x=plyPos.x,y=plyPos.y,z=plyPos.z})
			end
		end

		-- Respawn key
		if canRespawn and isDead then
			if IsControlJustPressed(1, 73) then
				RespawnPlayer()
				canRespawn = false
				canCallAmbulance = false
			end
		end
	end
end)

Citizen.CreateThread(function()
	Citizen.Wait(2000)
	while true do
		Citizen.Wait(0)
		if IsInService then
			local players = GetPlayers()

			for _,v in ipairs(players) do
				if v ~= PlayerId() then
					if IsEntityDead(v) then
						local playerCoords = GetEntityCoords(GetPlayerPed(-1), false)
						local targetCoords = GetEntityCoords(GetPlayerPed(v), false)

						if Vdist(targetCoords.x, targetCoords.y, targetCoords.z, playerCoords.x, playerCoords.y, playerCoords.z) < 1.0 then

						end
					end
				end
			end
		end
	end
end)

------------------------------------------------------------------------------------
--									Functions
------------------------------------------------------------------------------------

AddEventHandler("playerSpawned", function(spawn)
    exports.spawnmanager:setAutoSpawn(false)
end)

AddEventHandler('baseevents:onPlayerDied', function(playerId, reasonID)
    SetPlayerComa()
end)

AddEventHandler('baseevents:onPlayerKilled', function(playerId, playerKill, reasonID)
    SetPlayerComa()
end)

RegisterNetEvent('erp:resurectPlayer')
AddEventHandler('erp:resurectPlayer', function()
	if IsEntityDead(GetPlayerPed(-1)) then
		drawNotification(lang["res"])

		ResurrectPed(GetPlayerPed(-1))
		ClearPedBloodDamage(GetPlayerPed(-1))
		ResetPedVisibleDamage(GetPlayerPed(-1))
		SetEntityHealth(GetPlayerPed(-1), GetPedMaxHealth(GetPlayerPed(-1))/2)
		ClearPedTasksImmediately(GetPlayerPed(-1))
	end
end)

------------------------------------------------------------------------------------
--									Functions
------------------------------------------------------------------------------------

function SetPlayerKO()
  isKO = true
  drawNotification(lang["in_ko"])
  SetPedToRagdoll(GetPlayerPed(-1), 6000, 6000, 0, 0, 0, 0)
end

function RespawnPlayer()
	TriggerServerEvent('erp:removeMoneyOnDeath')
	TriggerServerEvent("item:reset")
	TriggerServerEvent("skin_customization:SpawnPlayer")
	RemoveAllPedWeapons(GetPlayerPed(-1), true)
	ClearPedBloodDamage(GetPlayerPed(-1))
	ResetPedVisibleDamage(GetPlayerPed(-1))
	NetworkResurrectLocalPlayer(357.757, -597.202, 28.6314, true, true, false)
end

function SetPlayerComa()
	TriggerServerEvent("erp:hasOnlineMedic", b)
	if b then
		drawNotification(lang["key_call"])
		canCallAmbulance = true
	end
	drawNotification(lang["key_respawn"])
	canRespawn = true
end

function GetPlayers()
    local players = {}

    for i = 0, 31 do
        if NetworkIsPlayerActive(i) then
            table.insert(players, i)
        end
    end

    return players
end
