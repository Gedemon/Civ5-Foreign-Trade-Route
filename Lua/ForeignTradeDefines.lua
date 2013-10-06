-- Defines
-- Author: Gedemon
-- DateCreated: 1/29/2011
----------------------------------------------------------------------------------------------------------------------------

print("Loading Foreign Trade Defines...")
print("-------------------------------------")


-------------------------------------------------------------------------------------------------------
-- Initialize for SaveUtils
-------------------------------------------------------------------------------------------------------

PLAYER_SAVE_SLOT = 0 -- Player slot used by saveutils
DEFAULT_SAVE_KEY = "1,0" -- "0,0" used by HSD -- "1,1" used by Revolution -- "0,1" by Cultural Diffusion

-------------------------------------------------------------------------------------------------------
-- Debug
-------------------------------------------------------------------------------------------------------
USE_CUSTOM_OPTION = true -- will use the option value selected in setup screen, set to false to debug and force use of defines values
DEBUG_FOREIGN_TRADE = true -- will print debug text in console & lua.log
DEBUG_PERFORMANCE = true -- display running time of some functions


----------------------------------------------------------------------------------------------------------------------------
-- Global Data Tables
----------------------------------------------------------------------------------------------------------------------------

MapModData.ForeignTradeRoutes = MapModData.ForeignTradeRoutes or {}

-- Ratio applied to trade route income by type of road.
-- Check in UpdateTradeRoutes() should be done in descending order (try to find the best route first)
g_ForeignTradeRatio = {
	["Ocean"] = 125,
	["Road"] = 100,
	["Coastal"] = 75,
	["River"] = 50,
}

