-- Debug
-- Author: Gedemon
-- DateCreated: 1/30/2011
--------------------------------------------------------------


print("Loading Foreign Trade Debug Functions...")
print("-------------------------------------")

-- list object attribute
function ListAttrib(object)
	print("Attributes:")
	for k, v in pairs(getmetatable(object).__index) do print(k) end
	print("End attributes.");
end

-- Add to event to get parameters
function Listen(...)

	print(unpack({...}))

end

-- list all civs
function ListAllCivs()
	print ("+++++++++++++++++++")
	print ("---- civ list -----")
	for iPlayer = 0, GameDefines.MAX_PLAYERS do
		local player = Players[iPlayer]
		if player ~= nil then
			local str = "- " .. iPlayer .. " - "
			if player:IsMinorCiv() then
				local minorCivType = player:GetMinorCivType();
				local civInfo = GameInfo.MinorCivilizations[minorCivType];
				local minorName = Locale.ConvertTextKey( civInfo.Description ) 
				str = str .. "Minor civ " .. minorName .. " (" .. minorCivType ..") - "
			else
				local majorCivType = player:GetCivilizationType();
				local civInfo = GameInfo.Civilizations[majorCivType]
				local majorName = Locale.ConvertTextKey( civInfo.Description )  
				str = str .. "Major civ " .. majorName .. " (" .. majorCivType ..") - "
			end
			if player:IsAlive() then
				str = str .. " alive - "
			end
			print (str)
		end
	end
	print ("+++++++++++++++++++")
end


