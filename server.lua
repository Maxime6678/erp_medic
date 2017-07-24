require "resources/mysql-async/lib/MySQL"

------------------------------------------------------------------------------------
--									 Basic Event
------------------------------------------------------------------------------------

RegisterServerEvent("erp:checkIsMedic")
AddEventHandler("erp:checkIsMedic", function()
	local user_id = getPlayerID(source)
	MySQL.Async.fetchAll("SELECT * FROM medic WHERE identifier = @user_id", {["@user_id"] = user_id}, function(result)
		if result[1] ~= nil then
			TriggerClientEvent("erp:setMedic", source, 1, result[1].rank)
		else
			TriggerClientEvent("erp:setMedic", source, 0, nil)
		end
	end)
end)

RegisterServerEvent("erp:removeMoneyOnDeath")
AddEventHandler("erp:removeMoneyOnDeath", function()
	TriggerEvent('es:getPlayerFromId', source, function(user)
	user:removeMoney(tonumber(user.money))
	end)
end)

local emergency = {}

RegisterServerEvent("erp:addEmergency")
AddEventHandler("erp:addEmergency", function(p)
	emergency[source] = p
end)

RegisterServerEvent("erp:delEmergency")
AddEventHandler("erp:delEmergency", function(p)
	emergency[source] = nil
end)

------------------------------------------------------------------------------------
--									Service System
------------------------------------------------------------------------------------

local PlayersInService = {}

RegisterServerEvent('erp:ServiceMedicOn')
AddEventHandler('erp:ServiceMedicOn', function()
	if not PlayersInService[source] then
		PlayersInService[source] = GetPlayerName(source)
	end
end)

RegisterServerEvent('erp:ServiceMedicOff')
AddEventHandler('erp:ServiceMedicOff', function()
	if PlayersInService[source] then
		PlayersInService[source] = nil
	end
end)

AddEventHandler('playerDropped', function()
  	if PlayersInService[source] then
		PlayersInService[source] = nil
	end
end)

RegisterServerEvent("erp:hasOnlineMedic")
AddEventHandler("erp:hasOnlineMedic", function(b)
	if #PlayersInService ~= 0 then
		b(true)
	else
		b(false)
	end
end)

------------------------------------------------------------------------------------
--								   Call System
------------------------------------------------------------------------------------

local TargetInCall = nil
local IsInCall = false

RegisterServerEvent('erp:callComaMedic')
AddEventHandler('erp:callComaMedic', function(p)
	if IsInCall then
		TriggerClientEvent('erp:callMedicResponce', source, 0)
	else
		TargetInCall = source
		IsInCall = true

		local i = 0
		for k,v in pairs(PlayersInService) do
			TriggerClientEvent('erp:callIncomingComaMedic', k, GetPlayerName(source), p)
			i = i + 1
		end

		if i == 0 then
			TriggerClientEvent('erp:callMedicResponce', source, 1)
			IsInCall = false
		end

		SetTimeout(15000, function()
	        if IsInCall then
	            TriggerClientEvent("erp:callMedicResponce", TargetInCall, 2)
	        end
	        IsInCall = false
	    end)
	end
end)

RegisterServerEvent('erp:callMedic')
AddEventHandler('erp:callMedic', function(r, p)
	if IsInCall then
		TriggerClientEvent('erp:callMedicResponce', source, 0)
	else
		TargetInCall = source
		IsInCall = true

		local i = 0
		for k,v in pairs(PlayersInService) do
			TriggerClientEvent('erp:callIncomingMedic', k, GetPlayerName(source), r, p)
			i = i + 1
		end

		if i == 0 then
			TriggerClientEvent('erp:callMedicResponce', source, 1)
			IsInCall = false
		end

		SetTimeout(15000, function()
	        if IsInCall then
	            TriggerClientEvent("erp:callMedicResponce", TargetInCall, 2)
	        end
	        IsInCall = false
	    end)
	end
end)

RegisterServerEvent("erp:getCallMedic")
AddEventHandler("erp:getCallMedic", function()
    IsInCall = false

    for k, v in pairs(PlayersInService) do
        TriggerClientEvent("erp:callMedicTaken", k, GetPlayerName(TargetInCall), GetPlayerName(source))
    end

    TriggerClientEvent("erp:callMedicResponce", TargetInCall, 3)
end)

------------------------------------------------------------------------------------
--									Functions
------------------------------------------------------------------------------------

function hasEmergency(id)
	if emergency[id] ~= nil then
		return true
	else
		return false
	end
end

function getPlayerID(source)
    local identifiers = GetPlayerIdentifiers(source)
    local player = getIdentifiant(identifiers)
    return player
end

function getIdentifiant(id)
    for _, v in ipairs(id) do
        return v
    end
end