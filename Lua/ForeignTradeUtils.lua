-- Utils
-- Author: Gedemon
-- DateCreated: 1/29/2011
--------------------------------------------------------------

print("Loading Foreign Trade Utils Functions...")
print("-------------------------------------")

-- Output debug text
function Dprint ( str, bOutput )
  if bOutput == nil then
    bOutput = true
  end
  if ( DEBUG_FOREIGN_TRADE and bOutput ) then
    print (str)
  end
end

--------------------------------------------------------------
-- Math functions 
--------------------------------------------------------------

function Round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function Shuffle(t)
  local n = #t
 
  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
 
  return t
end

function GetSize(t)

	if type(t) ~= "table" then
		return 1 
	end

	local n = #t 
	if n == 0 then
		for k, v in pairs(t) do
			n = n + 1
		end
	end 
	return n
end

--------------------------------------------------------------
-- Map functions 
--------------------------------------------------------------

--	here (x,y) = (0,0) is bottom left of map in Worldbuilder.
function GetPlot (x,y)
	local plot = Map:GetPlotXY(y,x)
	return plot
end

-- return a key string used in saved table refering to a plot position (can't save object in table...)
function GetPlotKey ( plot )
	-- set the key string used in TerritoryMap
	local x = plot:GetX()
	local y = plot:GetY()
	local plotKey = x..","..y
	return plotKey
end

-- return the plot refered by the key string
function GetPlotXYFromKey ( plotKey )
	local pos = string.find(plotKey, ",")
	local x = string.sub(plotKey, 1 , pos -1)
	local y = string.sub(plotKey, pos +1)
	return x, y
end

-- return the plot refered by the key string
function GetPlotFromKey ( plotKey )
	local pos = string.find(plotKey, ",")
	local x = string.sub(plotKey, 1 , pos -1)
	local y = string.sub(plotKey, pos +1)
	local plot = Map:GetPlotXY(y,x)
	return plot
end

--------------------------------------------------------------
-- Database functions 
--------------------------------------------------------------

-- update localized text
function SetText ( str, tag )
	-- in case of language change mid-game :
	local query = "UPDATE Language_en_US SET Text = '".. str .."' WHERE Tag = '".. tag .."'"
	for result in DB.Query(query) do
	end
	-- that's the table used ingame :
	local query = "UPDATE LocalizedText SET Text = '".. str .."' WHERE Tag = '".. tag .."'"
	for result in DB.Query(query) do
	end
end

-- return the first iPlayer using this CivilizationID or MinorcivID
function GetiPlayerFromCivID (id, bIsMinor, bReportError)
	if ( bIsMinor ) then
		for player_num = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1, 1 do
			local player = Players[player_num]
			if ( id == player:GetMinorCivType() ) then
				return player_num
			end
		end
	else
		for player_num = 0, GameDefines.MAX_MAJOR_CIVS-1 do
			local player = Players[player_num]
			if ( id == player:GetCivilizationType() ) then
				return player_num
			end
		end
	end
	if (id) then 
		Dprint ("WARNING : can't find Player ID for civ ID = " .. id , bReportError) 
	else	
		Dprint ("WARNING : civID is NILL or FALSE", bReportError) 
	end
	return false
end

-- return Civ type ID for iPlayer
function GetCivIDFromiPlayer (iPlayer, bReportError)
	if (iPlayer ~= -1) then
		if iPlayer <= GameDefines.MAX_MAJOR_CIVS-1 then
			local civID = Players[iPlayer]:GetCivilizationType()
			if (civID ~= -1) then
				return civID
			else
				Dprint ("WARNING : no major civ for iPlayer = " .. iPlayer , bReportError) 
				return false
			end
		else 
			local civID = Players[iPlayer]:GetMinorCivType()
			if (civID ~= -1) then
				return civID
			else
				Dprint ("WARNING : no minor civ for iPlayer = " .. iPlayer, bReportError) 
				return false
			end
		end
	else
		Dprint ("WARNING : trying to find CivType for iPlayer = -1", bReportError) 
		return false
	end
end

function GetCivTypeFromiPlayer(iPlayer)
	local player = Players[iPlayer]
	local civID = GetCivIDFromiPlayer(iPlayer, true)
	local type
	if (player:IsMinorCiv()) then
		type = GameInfo.MinorCivilizations[civID].Type
	else
		type = GameInfo.Civilizations[civID].Type
	end
	return type
end

--------------------------------------------------------------
-- Save/Load 
--------------------------------------------------------------


function LoadData( name, defaultValue, key )
	local startTime = os.clock()
	local plotKey = key or DEFAULT_SAVE_KEY
	local pPlot = GetPlotFromKey ( plotKey )
	if pPlot then
		local value = load( pPlot, name ) or defaultValue
		local endTime = os.clock()
		local totalTime = endTime - startTime
		Dprint ("LoadData() used " .. tostring(totalTime) .. " sec to retrieve " .. tostring(name) .. " from plot " .. tostring(plotKey) .. " (#entries = " .. tostring(GetSize(value)) ..")", DEBUG_PERFORMANCE)
		return value
	else
		Dprint("ERROR: trying to load script data from invalid plot (" .. tostring(plotKey) .."), data = " .. tostring(name))
		return nil
	end
end
function SaveData( name, value, key )
	local startTime = os.clock()
	local plotKey = key or DEFAULT_SAVE_KEY
	local pPlot = GetPlotFromKey ( plotKey )	
	if pPlot then
		save( pPlot, name, value )
		local endTime = os.clock()
		local totalTime = endTime - startTime
		Dprint ("SaveData() used " .. tostring(totalTime) .. " sec to store " .. tostring(name) .. " in plot " .. tostring(plotKey) .. " (#entries = " .. tostring(GetSize(value)) ..")", DEBUG_PERFORMANCE)
	else
		Dprint("ERROR: trying to save script data to invalid plot (" .. tostring(plotKey) .."), data = " .. tostring(name) .. " value = " .. tostring(value))
	end
end

function LoadModdingData( name, defaultValue)
	local startTime = os.clock()
	local savedData = Modding.OpenSaveData()
	local value = savedData.GetValue(name) or defaultValue
	local endTime = os.clock()
	local totalTime = endTime - startTime
	Dprint ("LoadData() used " .. totalTime .. " sec for " .. name, DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
	return value
end
function SaveModdingData( name, value )
	startTime = os.clock()
	local savedData = Modding.OpenSaveData()
	savedData.SetValue(name, value)
	endTime = os.clock()
	totalTime = endTime - startTime
	Dprint ("SaveData() used " .. totalTime .. " sec for " .. name, DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
end

