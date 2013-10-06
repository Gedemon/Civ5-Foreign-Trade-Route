--------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------
-- Foreign Trade Routes Mod
-- Author: Gedemon
-- DateCreated: 5/17/2011 10:50:50 PM
----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

print("---------------------------------------------------------------------------------------------------------------")
print("-------------------------------- Foreign Trade Routes script started... ---------------------------------------")
print("---------------------------------------------------------------------------------------------------------------")

local bWaitBeforeInitialize = true

--------------------------------------------------------------
-- Mod related initialization (before include)
--------------------------------------------------------------
local DynHistModID = "97837c72-d198-49d2-accd-31101cfc048a"
local bDynHist = false
local unsortedInstalledMods = Modding.GetInstalledMods()
for key, modInfo in pairs(unsortedInstalledMods) do
	if modInfo.Enabled then
		if (modInfo.Name) then
			if ( modInfo.ID == DynHistModID) then
				bDynHist = true
			end
		end
	end
end


--------------------------------------------------------------
-- DLC related initialization (before include)
--------------------------------------------------------------

bExpansionActive = ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY) 


--------------------------------------------------------------
-- use mod data to save / load data between game initialisation phases
--------------------------------------------------------------
local DynHistModVersion = Modding.GetLatestInstalledModVersion(DynHistModID)
modUserData = Modding.OpenUserData(DynHistModID, DynHistModVersion) -- global

--------------------------------------------------------------
-- saveutils
--------------------------------------------------------------
WARN_NOT_SHARED = false
include( "ShareData.lua" )
include( "SaveUtils" )
MY_MOD_NAME = DynHistModID -- To share data between all DynHist mod components

----------------------------------------------------------------------------------------------------------------------------
-- Common Includes
----------------------------------------------------------------------------------------------------------------------------

include ("ForeignTradeDefines") -- Always first
include ("ForeignTradeUtils")
include ("ForeignTradeDebug")
include ("ForeignTradeConnections")
include ("ForeignTradeFunctions")
include ("ForeignTradeUIFunctions")

----------------------------------------------------------------------------------------------------------------------------
-- Initializing functions...
----------------------------------------------------------------------------------------------------------------------------


-- functions to call at beginning of each turn
function OnNewTurn ()
	UpdateTradeRoutes()
	AddForeignTradeRoutesGold()
end
Events.ActivePlayerTurnStart.Add( OnNewTurn )

-- functions to call at end of each turn
function OnEndTurn ()
end
Events.ActivePlayerTurnEnd.Add( OnEndTurn )

-- functions to call at end of 1st turn
function OnFirstTurnEnd()
	Dprint ("End of First turn detected, calling OnFirstTurnEnd() ...")
	local iValue = LoadData("ForeignTradeFirstTurnEnded", 0)
	if (iValue ~= 1) then
		Dprint (" - First call...")
		--
		SaveData("ForeignTradeFirstTurnEnded", 1)
	else
		Dprint (" - Already called, do nothing...")
	end
	Events.ActivePlayerTurnEnd.Remove(OnFirstTurnEnd)
end

-- functions to call ASAP after loading this file when game is launched for the first time
function OnFirstTurn ()
	Dprint ("ForeignTradeMain.lua loaded, initializing for new game  ...")
	--
	InitializePlayerFunctions()
	--GameEvents.GetScenarioDiploModifier1.Add(OpenBorderBonus)
	GameEvents.GetScenarioDiploModifier2.Add(OpenBorderMalus)
end

-- functions to call ASAP after loading a saved game
function OnLoading ()
	Dprint ("ForeignTradeMain.lua loaded, initializing for saved game ...")
	--
	InitializePlayerFunctions()
	--GameEvents.GetScenarioDiploModifier1.Add(OpenBorderBonus)
	GameEvents.GetScenarioDiploModifier2.Add(OpenBorderMalus)
end

-- functions to call after game initialization (DoM screen button "Begin your journey" appears)
function OnGameInit ()
	local iValue = LoadData("ForeignTradeFinalInitDone", 0)
	if (iValue ~= 1) then
		Dprint ("Game is initialized, calling OnGameInit() for ForeignTrade...")
		--
		SaveData("ForeignTradeFinalInitDone", 1)
	else
		Dprint ("Game is initialized, calling OnGameInit() for ForeignTrade ...")
		--
	end
end

-- functions to call after entering game (DoM screen button pushed)
function OnEnterGame ()
	--
	UpdateForeignTradeRoutesUI()
end

-- Initialize when RedMain is loaded
if ( bWaitBeforeInitialize ) then
	bWaitBeforeInitialize = false	
	local iValue = LoadData("ForeignTradeInitDone", 0)
	if (iValue ~= 1) then	
		--
		Events.ActivePlayerTurnEnd.Add(OnFirstTurnEnd)
		OnFirstTurn ()
		SaveData("ForeignTradeInitDone", 1)
	else
		OnLoading()
	end
end

Events.SequenceGameInitComplete.Add( OnGameInit )
Events.LoadScreenClose.Add( OnEnterGame )

----------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

print("---------------------------------------------------------------------------------------------------------------")
print("-------------------------------- Foreign Trade Routes Script : loaded ! ---------------------------------------")
print("---------------------------------------------------------------------------------------------------------------")