-- Lua Foreign Trade Functions
-- Author: Gedemon
-- DateCreated: 7/20/2011 5:21:31 AM
--------------------------------------------------------------


print("Loading Foreign Trade functions...")
print("-------------------------------------")


--------------------------------------------------------------
--------------------------------------------------------------

-- check if path is blocked for RouteConnections
function PathBlocked(pPlot, pPlayer)
	if ( pPlot == nil or pPlayer == nil) then
		Dprint ("WARNING : CanPass() called with a nil argument")
		return true
	end

	local ownerID = pPlot:GetOwner()
	local iPlayer = pPlayer:GetID()

	if ( ownerID == iPlayer or ownerID == -1 ) then
		return false
	end

	local pOwner = Players [ ownerID ]

	if ( pPlayer:GetTeam() == pOwner:GetTeam() or pOwner:IsAllies(iPlayer) or pOwner:IsFriends(iPlayer) ) then
		return false
	end

	--local team1 = Teams [ pPlayer:GetTeam() ]
	local plotTeam = Teams [ pOwner:GetTeam() ]
	if plotTeam:IsAllowsOpenBordersToTeam( pPlayer:GetTeam() ) then
		return false
	end

	return true -- return true if the path is blocked...
end

-- check if river path is blocked for RouteConnections
function RiverPathBlocked(destPlot, player, plot)
	if ( destPlot == nil or player == nil or plot == nil) then
		Dprint ("WARNING : CanPass() called with a nil argument for RiverPathBlocked()")
		return true -- there's nothing here : blocked
	end

	local direction = GetDirection(plot, destPlot)
	if not plot:IsRiverConnection(direction) then
		return true -- no river connection : blocked
	end

	local ownerID = destPlot:GetOwner()
	local iPlayer = player:GetID()

	if ( ownerID == iPlayer or ownerID == -1 ) then
		return false
	end

	local owner = Players [ ownerID ]

	if ( player:GetTeam() == owner:GetTeam() or owner:IsAllies(iPlayer) or owner:IsFriends(iPlayer) ) then
		return false
	end

	--local team1 = Teams [ pPlayer:GetTeam() ]
	local plotTeam = Teams [ owner:GetTeam() ]
	if plotTeam:IsAllowsOpenBordersToTeam( player:GetTeam() ) then
		return false
	end

	return true -- return true if the path is blocked...
end

function GetDirection (plot1, plot2)
	if plot1 == nil or plot2 == nil then
		return nil
	end
	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot1:GetX(), plot1:GetY(), direction)
		if adjacentPlot == plot2 then
			return direction
		end
	end
	return nil
end

--------------------------------------------------------------
--------------------------------------------------------------

function GetCityForeignTradeRouteYield(iPlayer, cityID, foreignTradeRoutes, bDebug)
	local bDebug = bDebug or false
	local player = Players[iPlayer]
	local city = player:GetCityByID(cityID)
	local gold = 0
	Dprint (" - Calculate trade route for " .. city:GetName(), bDebug)
	local data = foreignTradeRoutes[iPlayer][cityID]
	if data then
		-- {OwnerID = destination.Player:GetID(), ID = destination.City:GetID(), Type = routeType}
		local otherPlayer = Players[data.OwnerID]
		local otherCity = otherPlayer:GetCityByID(data.ID)
		Dprint ("   - route open with " .. otherCity:GetName(), bDebug)
		local ratio = g_ForeignTradeRatio[data.Type]

		local citySize = city:GetPopulation()
		local otherSize = otherCity:GetPopulation()

		-- using vanilla formula...
		local yield =	(GameDefines.TRADE_ROUTE_CITY_POP_GOLD_MULTIPLIER/100*otherSize)
					  + (GameDefines.TRADE_ROUTE_CAPITAL_POP_GOLD_MULTIPLIER/100*citySize)
					  + (GameDefines.TRADE_ROUTE_BASE_GOLD/100) 

		-- apply ratio from route type...
		gold = yield * ratio / 100

	end
	Dprint ("     - Gold yield =  " .. gold, bDebug)
	return gold
end

function AddForeignTradeRoutesGold()

	local bDebug = true

	Dprint ("------------------ ", bDebug)
	Dprint ("Adding gold from Foreign Trade Routes...", bDebug)

	local foreignTradeRoutes = MapModData.ForeignTradeRoutes
	
	if foreignTradeRoutes then
		for iPlayer = 0, GameDefines.MAX_PLAYERS do
			local player= Players[iPlayer]
			local gold = GetForeignTradeRoutesGold(player, foreignTradeRoutes, bDebug)
			if gold ~= 0 then
				player:ChangeGold(gold)
			end
		end
	else
		Dprint (" - WARNING : can't load foreignTradeRoutes table", bDebug)
	end
end

function UpdateTradeRoutes()
	local startTime = os.clock()
	local bDebug = true

	Dprint ("------------------ ", bDebug)
	Dprint ("Listing cities for Foreign Trade Routes...", bDebug)

	local foreignTradeRoutes =  {} -- initialise each time UpdateTradeRoutes is called
	local availableCities = {}

	-- first find available cities for trade routes
	for iPlayer = 0, GameDefines.MAX_PLAYERS do
		local player= Players[iPlayer]
		if player and player:IsAlive() and player:GetNumCities() > 0 then
			Dprint (" - Create trade Routes entry for ".. player:GetName(), bDebug)
			foreignTradeRoutes[iPlayer] = {}
			local teamTech = Teams[player:GetTeam()]:GetTeamTechs()
			local bHasSailing = teamTech:HasTech(GameInfoTypes["TECH_SAILING"])
			local bHasOptic = teamTech:HasTech(GameInfoTypes["TECH_OPTICS"])
			local bHasAstronomy = teamTech:HasTech(GameInfoTypes["TECH_ASTRONOMY"])
			for city in player:Cities() do
				local cityID = city:GetID()
				local cityPlot = city:Plot()
				local bHasHarbor = city:GetNumBuilding(GameInfo.Buildings.BUILDING_HARBOR.ID) > 0
				local bHasLightHouse = city:GetNumBuilding(GameInfo.Buildings.BUILDING_LIGHTHOUSE.ID) > 0
				local bIsNearRiver = cityPlot:IsRiver()
				Dprint ("   - Mark ".. city:GetName() .. " available for trade route", bDebug)
				table.insert(availableCities, {
					City = city,
					Player = player,
					Size = city:GetPopulation(),
					HasHarbor = bHasHarbor,
					IsNearRiver = bIsNearRiver,
					Connected = false,
					NoRoutes = false,
					HasSailing = bHasSailing,
					HasLightHouse = bHasLightHouse,
					HasOptic = bHasOptic,
					HasAstronomy = bHasAstronomy,
				})
			end			
		end
	end

	-- Now connect available cities	
	Dprint ("------------------------------------------------------------------------------------------------------------", bDebug)
	Dprint ("Creating Foreign Trade Routes...", bDebug)
	table.sort(availableCities, function(a,b) return a.Size > b.Size end) -- sort by size, biggest cities choose routes first
	for originID, origin in pairs(availableCities) do
		if not origin.Connected then			
			Dprint ("-----------------------------------------------", bDebug)
			Dprint (" - Searching trade route for ".. origin.City:GetName(), bDebug)
			local bConnected = false
			local routeType = nil
			for destID, destination in pairs(availableCities) do
				local originiPlayer = origin.City:GetOwner()
				local destinationiPlayer = destination.City:GetOwner()

				local originTeam = Teams [ Players[originiPlayer]:GetTeam() ]
				local destinationTeam = Teams [ Players[destinationiPlayer]:GetTeam() ]
				local bOpenBorder = originTeam:IsAllowsOpenBordersToTeam( destinationTeam:GetID() )  
									or destinationTeam:IsAllowsOpenBordersToTeam( originTeam:GetID() ) 
									or Players[originiPlayer]:IsPlayerHasOpenBorders(destinationiPlayer)
									or Players[destinationiPlayer]:IsPlayerHasOpenBorders(originiPlayer) 

				if (originiPlayer ~= destinationiPlayer)
				   and not destination.Connected -- don't check if already connected
				   and not destination.NoRoutes -- don't check if already tested
				   and bOpenBorder -- need open border
				   and not bConnected then
					-- Search oceanic route first (more gain)
					if (origin.HasHarbor and destination.HasHarbor) -- Harbours needed in both cities
						   and (origin.HasAstronomy or destination.HasAstronomy) -- but astronomy tech needed in only one
					       and isPlotConnected(origin.Player, origin.City:Plot(), destination.City:Plot(), "Ocean", false, false, PathBlocked) then
						Dprint ("   - Found Maritime trade route to ".. destination.City:GetName(), bDebug)
						bConnected = true
						routeType = "Ocean"
					-- then road route
					elseif isPlotConnected(origin.Player, origin.City:Plot(), destination.City:Plot(), "Road", false, false, PathBlocked) then
						Dprint ("   - Found Road trade route to ".. destination.City:GetName(), bDebug)
						bConnected = true
						routeType = "Road"
					-- then coastal route 
					elseif (origin.HasHarbor or origin.HasLightHouse) and (destination.HasHarbor or destination.HasLightHouse) -- Harbours or LightHouse needed in both cities
						   and (origin.HasOptic or destination.HasOptic) -- but optic tech needed in only one
					       and isPlotConnected(origin.Player, origin.City:Plot(), destination.City:Plot(), "Coastal", false, false, PathBlocked) then
						Dprint ("   - Found Coastal trade route to ".. destination.City:GetName(), bDebug)
						bConnected = true
						routeType = "Coastal"
					-- then river route 
					elseif (origin.HasSailing or destination.HasSailing) -- only one side need the sailing tech
						   and isPlotConnected(origin.Player, origin.City:Plot(), destination.City:Plot(), "River", false, false, PathBlocked) then
						   --and isPlotConnected(origin.Player, origin.City:Plot(), destination.City:Plot(), "Land", false, false, RiverPathBlocked) then
						Dprint ("   - Found River trade route to ".. destination.City:GetName(), bDebug)
						bConnected = true
						routeType = "River"
					end

					if bConnected then
						
						foreignTradeRoutes[origin.Player:GetID()][origin.City:GetID()] = {OwnerID = destination.Player:GetID(), ID = destination.City:GetID(), Type = routeType}
						
						-- to do : allow asymetric connection ? (example : one way open border...)
						-- if isPlotConnected(destination.Player, origin.City:Plot(), destination.City:Plot(), "Ocean", false, false, PathBlocked) then
							availableCities[destID].Connected = true
							foreignTradeRoutes[destination.Player:GetID()][destination.City:GetID()] = {OwnerID = origin.Player:GetID(), ID = origin.City:GetID(), Type = routeType}
						--end
					end
				--[[
				elseif (originiPlayer ~= destinationiPlayer) and not bConnected then -- for debugging
					if destination.Connected then
						Dprint ("   - No route searched to ".. destination.City:GetName() ..", destination already connected to another city...", bDebug)
					elseif destination.NoRoutes then
						Dprint ("   - No route searched to ".. destination.City:GetName() ..", destination already tested and had no routes...", bDebug)
					elseif not (Players[originiPlayer]:IsPlayerHasOpenBorders(destinationiPlayer) or Players[destinationiPlayer]:IsPlayerHasOpenBorders(originiPlayer)) then
						Dprint ("   - No route searched to ".. destination.City:GetName() ..", neither civs have open border...", bDebug)
					end --]]
				end
			end
			availableCities[originID].Connected = bConnected
			availableCities[originID].NoRoutes = not bConnected
		end
	end

	MapModData.ForeignTradeRoutes = foreignTradeRoutes

	local endTime = os.clock()
	local totalTime = endTime - startTime
	Dprint ("UpdateTradeRoutes() used " .. totalTime .. " sec", DEBUG_PERFORMANCE)
	Dprint("-------------------------------------", DEBUG_PERFORMANCE)
end


--------------------------------------------------------------
--------------------------------------------------------------

function GetForeignTradeRoutesGoldTimes100(player, foreignTradeRoutes, bDebug) -- foreignTradeRoutes and bDebug are optional
	if foreignTradeRoutes == nil then
		foreignTradeRoutes = MapModData.ForeignTradeRoutes
	end
	return Round (GetForeignTradeRoutesGold(player, foreignTradeRoutes, bDebug)*100)
end

function GetForeignTradeRoutesGold(player, foreignTradeRoutes, bDebug) -- foreignTradeRoutes and bDebug are optional

	local bDebug = bDebug or false

	if foreignTradeRoutes == nil then
		foreignTradeRoutes = MapModData.ForeignTradeRoutes
	end

	if (player == nil) or (foreignTradeRoutes == nil) or (not player:IsAlive()) or player:IsBarbarian() then
		return 0
	end
	
	local iPlayer = player:GetID()
	local gold = 0
	Dprint ("------------------ ", bDebug)
	Dprint ("Calculating gold income from Foreign Trade Routes for " .. player:GetName(), bDebug)

	local connectedCities = foreignTradeRoutes[iPlayer]
	if connectedCities and player:GetNumCities() > 0 then
		for cityID, data in pairs (connectedCities) do
			gold = gold + GetCityForeignTradeRouteYield(iPlayer, cityID, foreignTradeRoutes, bDebug)
		end			
		Dprint ("      - Total gold = " .. gold, bDebug)
	end
	return gold
end

function NewCalculateGoldRate(self)
	local goldRate = self:OldCalculateGoldRate()
	if not MapModData.ForeignTradeRoutes then
		return goldRate
	end
	local foreignTradeRoutes = MapModData.ForeignTradeRoutes
	local gold = GetForeignTradeRoutesGoldTimes100(self, foreignTradeRoutes)/100
	return goldRate + gold
end

function NewCalculateGoldRateTimes100(self)
	local goldRate = self:OldCalculateGoldRateTimes100()
	if not MapModData.ForeignTradeRoutes then
		return goldRate
	end
	local foreignTradeRoutes = MapModData.ForeignTradeRoutes
	local gold = GetForeignTradeRoutesGoldTimes100(self, foreignTradeRoutes)
	return goldRate + gold
end

function NewCalculateGrossGoldTimes100(self)
	local goldRate = self:OldCalculateGrossGoldTimes100()
	if not MapModData.ForeignTradeRoutes then
		return goldRate
	end
	local foreignTradeRoutes = MapModData.ForeignTradeRoutes
	local gold = GetForeignTradeRoutesGoldTimes100(self, foreignTradeRoutes)
	return goldRate + gold
end

function InitializePlayerFunctions()

	local bDebug = true
	Dprint ("------------------ ", bDebug)
	Dprint ("Updating player metatable... ", bDebug)

	-- update player functions...
	local p = getmetatable(Players[0]).__index
	-- save old functions
	if not p.OldCalculateGoldRate then
		p.OldCalculateGoldRate = p.CalculateGoldRate
		p.OldCalculateGoldRateTimes100 = p.CalculateGoldRateTimes100
		p.OldCalculateGrossGoldTimes100 = p.CalculateGrossGoldTimes100
	end
	-- set replacement
	p.CalculateGoldRate = NewCalculateGoldRate
	p.CalculateGoldRateTimes100 = NewCalculateGoldRateTimes100
	p.CalculateGrossGoldTimes100 = NewCalculateGrossGoldTimes100
	-- set new functions
	p.GetForeignTradeRoutesGoldTimes100 = GetForeignTradeRoutesGoldTimes100
	p.GetForeignTradeRoutesGold = GetForeignTradeRoutesGold

	Events.SerialEventGameDataDirty()
end

function OpenBorderBonus(iPlayer1, iPlayer2)
	local player1 = Players[iPlayer1]
	local player2 = Players[iPlayer2]

	local iTeam1 = player1:GetTeam()

	local team1 = Teams [ iTeam1 ]
	local team2 = Teams [ player2:GetTeam() ]

	if team2:IsAllowsOpenBordersToTeam( iTeam1 ) then
		return -20
	else
		return 0
	end
end


function OpenBorderMalus(iPlayer1, iPlayer2)
	local player1 = Players[iPlayer1]
	local player2 = Players[iPlayer2]
	
	local team1 = Teams [ player1:GetTeam() ]
	local team2 = Teams [ player2:GetTeam() ]

	local malus = 0

	for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1 do
		local player = Players[iPlayer]
		local iTeam = player:GetTeam()

		if (iPlayer ~= iPlayer1 and iPlayer ~= iPlayer2)
		   and team2:IsAllowsOpenBordersToTeam( iTeam )
		   and (player1:IsDenouncedPlayer( iPlayer ) or player:IsDenouncedPlayer( iPlayer1 ) or	team1:IsAtWar(iTeam))		
		then
			malus = malus + 5
		end
	end
	return malus
end