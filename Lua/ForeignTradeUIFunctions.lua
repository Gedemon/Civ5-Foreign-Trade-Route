-- Lua UI functions
-- Author: Gedemon
-- DateCreated: 5/1/2012 12:00:39 PM
--------------------------------------------------------------

include("InstanceManager")

-- Tooltip init
function DoInitForeignTradeRoutesTooltips()
	ContextPtr:LookUpControl("/InGame/TopPanel/GoldPerTurn"):SetToolTipCallback( GoldTipforFTRHandler )
end

function UpdateForeignTradeRoutesUI()
	DoInitForeignTradeRoutesTooltips()
	Controls.ForeignIncome:ChangeParent(ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"))
	Controls.ForeignTradeToggle:ChangeParent(ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"))
	Controls.ForeignTradeStack:ChangeParent(ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"))	
	ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"):ReprocessAnchoring()
end


--------------------------------------------------------------
-- Top Panel
--------------------------------------------------------------

local tipControlTable = {};
TTManager:GetTypeControlTable( "TooltipTypeTopPanel", tipControlTable );

-- Gold Tooltip for Foreign Trade Routes
function GoldTipforFTRHandler( control )

	local strText = "";
	local iiPlayer = Game.GetActivePlayer();
	local pPlayer = Players[iiPlayer];
	local pTeam = Teams[pPlayer:GetTeam()];
	local pCity = UI.GetHeadSelectedCity();
	
	local iTotalGold = pPlayer:GetGold();

	local iGoldPerTurnFromOtherPlayers = pPlayer:GetGoldPerTurnFromDiplomacy();
	local iGoldPerTurnToOtherPlayers = 0;
	if (iGoldPerTurnFromOtherPlayers < 0) then
		iGoldPerTurnToOtherPlayers = -iGoldPerTurnFromOtherPlayers;
		iGoldPerTurnFromOtherPlayers = 0;
	end

	local iGoldPerTurnFromReligion = 0
	if bExpansionActive then
		iGoldPerTurnFromReligion = pPlayer:GetGoldPerTurnFromReligion()
	end

	local fGoldPerTurnFromCities = pPlayer:GetGoldFromCitiesTimes100() / 100;
	local fCityConnectionGold = pPlayer:GetCityConnectionGoldTimes100() / 100;	
	local iGoldPerTurnFromForeignTradeRoute = pPlayer:GetForeignTradeRoutesGoldTimes100() / 100

	local fTotalIncome = fGoldPerTurnFromCities + iGoldPerTurnFromOtherPlayers + fCityConnectionGold + iGoldPerTurnFromReligion + iGoldPerTurnFromForeignTradeRoute;

	
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. Locale.ConvertTextKey("TXT_KEY_TP_AVAILABLE_GOLD", iTotalGold);
		strText = strText .. "[NEWLINE][NEWLINE]";
	end
	
	strText = strText .. "[COLOR:150:255:150:255]";
	strText = strText .. "+" .. Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_INCOME", math.floor(fTotalIncome));
	strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_CITY_OUTPUT", fGoldPerTurnFromCities);
	strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_TR", math.floor(fCityConnectionGold));
	if (iGoldPerTurnFromOtherPlayers > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_OTHERS", iGoldPerTurnFromOtherPlayers);
	end
	if (iGoldPerTurnFromForeignTradeRoute > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_FOREIGN_TRADE_ROUTE", iGoldPerTurnFromForeignTradeRoute);
	end
	if (iGoldPerTurnFromReligion > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_FROM_RELIGION", iGoldPerTurnFromReligion);
	end
	strText = strText .. "[/COLOR]";
	
	local iUnitCost = pPlayer:CalculateUnitCost();
	local iUnitSupply = pPlayer:CalculateUnitSupply();
	local iBuildingMaintenance = pPlayer:GetBuildingGoldMaintenance();
	local iImprovementMaintenance = pPlayer:GetImprovementGoldMaintenance();
	local iTotalExpenses = iUnitCost + iUnitSupply + iBuildingMaintenance + iImprovementMaintenance + iGoldPerTurnToOtherPlayers;
	
	strText = strText .. "[NEWLINE]";
	strText = strText .. "[COLOR:255:150:150:255]";
	strText = strText .. "[NEWLINE]-" .. Locale.ConvertTextKey("TXT_KEY_TP_TOTAL_EXPENSES", iTotalExpenses);
	if (iUnitCost ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_UNIT_MAINT", iUnitCost);
	end
	if (iUnitSupply ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_UNIT_SUPPLY", iUnitSupply);
	end
	if (iBuildingMaintenance ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_BUILDING_MAINT", iBuildingMaintenance);
	end
	if (iImprovementMaintenance ~= 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_TILE_MAINT", iImprovementMaintenance);
	end
	if (iGoldPerTurnToOtherPlayers > 0) then
		strText = strText .. "[NEWLINE]  [ICON_BULLET]" .. Locale.ConvertTextKey("TXT_KEY_TP_GOLD_TO_OTHERS", iGoldPerTurnToOtherPlayers);
	end
	strText = strText .. "[/COLOR]";
	
	if (fTotalIncome + iTotalGold < 0) then
		strText = strText .. "[NEWLINE][COLOR:255:60:60:255]" .. Locale.ConvertTextKey("TXT_KEY_TP_LOSING_SCIENCE_FROM_DEFICIT") .. "[/COLOR]";
	end
	
	-- Basic explanation of Happiness
	if (not OptionsManager.IsNoBasicHelp()) then
		strText = strText .. "[NEWLINE][NEWLINE]";
		strText = strText ..  Locale.ConvertTextKey("TXT_KEY_TP_GOLD_EXPLANATION");
	end
	
	--Controls.GoldPerTurn:SetToolTipString(strText);
	
	tipControlTable.TooltipLabel:SetText( strText );
	tipControlTable.TopPanelMouseover:SetHide(false);
    
    -- Autosize tooltip
    tipControlTable.TopPanelMouseover:DoAutoSize();
	
end


--------------------------------------------------------------
-- Economic Overview
--------------------------------------------------------------

-- Update infos when popup are called
function OnEventReceived( popupInfo )	
	if( popupInfo.Type == ButtonPopupTypes.BUTTONPOPUP_ECONOMIC_OVERVIEW ) then
		UpdateForeignTradeList()
	end
end
Events.SerialEventGameMessagePopup.Add( OnEventReceived )

-- Update foreign Trade list
function UpdateForeignTradeList()

	local foreignTradeRoutes = MapModData.ForeignTradeRoutes
	if foreignTradeRoutes == nil then
		return
	end
	
	local player = Players[ Game.GetActivePlayer() ]
	local iPlayer = player:GetID()

    Controls.ForeignTradeIncomeValue:SetText( Locale.ToNumber( player:GetForeignTradeRoutesGoldTimes100(foreignTradeRoutes) / 100, "#.##" ) );
    
	-- Trade income breakdown tooltip
    local iBaseGold = GameDefines.TRADE_ROUTE_BASE_GOLD / 100
    local iGoldPerPop = GameDefines.TRADE_ROUTE_CITY_POP_GOLD_MULTIPLIER / 100
    local iGoldPerOwnCityPop = GameDefines.TRADE_ROUTE_CAPITAL_POP_GOLD_MULTIPLIER/100
    local strTooltip = Locale.ConvertTextKey("TXT_KEY_EO_INCOME_TRADE")
    strTooltip = strTooltip .. "[NEWLINE][NEWLINE]"
    strTooltip = strTooltip .. Locale.ConvertTextKey("TXT_KEY_FOREIGN_TRADE_ROUTE_INCOME_INFO", iBaseGold, iGoldPerPop, iGoldPerOwnCityPop)
    Controls.ForeignTradeIncomeValue:SetToolTipString( strTooltip )


    local bFoundCity = false
    Controls.ForeignTradeStack:DestroyAllChildren()
    for city in player:Cities() do
		
		local cityID = city:GetID()
        local CityIncome = GetCityForeignTradeRouteYield(iPlayer, cityID, foreignTradeRoutes, bDebug)
    
        if( CityIncome > 0 ) then
            bFoundCity = true
    		local instance = {}
            ContextPtr:BuildInstanceForControl( "ForeignTradeEntry", instance, Controls.ForeignTradeStack )
			
            instance.CityName:SetText( city:GetName() );
            instance.ForeignTradeValue:SetText( Locale.ToNumber( CityIncome, "#.##" ) )
			
			-- set tooltip
			local data = foreignTradeRoutes[iPlayer][cityID]
			local otherCityID = data.ID
			local otherPlayer = Players[data.OwnerID]
			local routeType = data.Type
			local otherCity = nil
			if otherPlayer then
				otherCity = otherPlayer:GetCityByID(otherCityID)
			end
			if otherCity then

				local tooltipStr = ""

				local citySize = city:GetPopulation()
				local otherSize = otherCity:GetPopulation()

				local otherCityName = otherCity:GetName()
				local ownCityName = city:GetName()

				local fromOtherSize = GameDefines.TRADE_ROUTE_CITY_POP_GOLD_MULTIPLIER/100*otherSize
				local fromOwnsize = GameDefines.TRADE_ROUTE_CAPITAL_POP_GOLD_MULTIPLIER/100*citySize
				local fromRoute = GameDefines.TRADE_ROUTE_BASE_GOLD/100
				
				tooltipStr = tooltipStr .. routeType .." " .. Locale.ConvertTextKey("TXT_KEY_FOREIGN_TRADE_ROUTE_CITY_INFO", otherCityName,  g_ForeignTradeRatio[routeType] )
				tooltipStr = tooltipStr .. Locale.ConvertTextKey("TXT_KEY_FOREIGN_TRADE_ROUTE_CITY_DETAIL", fromRoute, fromOtherSize, otherSize, otherCityName, fromOwnsize, citySize, ownCityName )

				instance.CityName:SetToolTipString( tooltipStr )
				instance.ForeignTradeValue:SetToolTipString( tooltipStr )
			end
        end
    end
    
    if( bFoundCity ) then
        Controls.ForeignTradeToggle:SetDisabled( false )
        Controls.ForeignTradeToggle:SetAlpha( 1.0 )
    else
        Controls.ForeignTradeToggle:SetDisabled( true )
        Controls.ForeignTradeToggle:SetAlpha( 0.5 )
    end
    Controls.ForeignTradeStack:CalculateSize()
    Controls.ForeignTradeStack:ReprocessAnchoring()
	
    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"):CalculateSize()
    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"):ReprocessAnchoring()
    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldScroll"):CalculateInternalSize()
end

-- Start hidden
Controls.ForeignTradeStack:SetHide( true )

function OnForeignTradeToggle()
    local bWasHidden = Controls.ForeignTradeStack:IsHidden()
    Controls.ForeignTradeStack:SetHide( not bWasHidden )
    if( bWasHidden ) then
        Controls.ForeignTradeToggle:LocalizeAndSetText("TXT_KEY_EO_INCOME_FOREIGN_TRADE_DETAILS_COLLAPSE")
    else
        Controls.ForeignTradeToggle:LocalizeAndSetText("TXT_KEY_EO_INCOME_FOREIGN_TRADE_DETAILS")
    end

    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"):CalculateSize()
    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldStack"):ReprocessAnchoring()
    ContextPtr:LookUpControl("/InGame/EconomicOverview/EconomicGeneralInfo/GoldScroll"):CalculateInternalSize()
end
Controls.ForeignTradeToggle:RegisterCallback( Mouse.eLClick, OnForeignTradeToggle )