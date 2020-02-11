class CfgPatches {
	class AUR_AdvancedUrbanRappelling {
		author 			= "duda123";
		name 			= "Advanced Urban Rappelling";
		url 			= "https://github.com/sethduda/AdvancedUrbanRappelling";
		units[] 		= {"AUR_AdvancedUrbanRappelling"};
		requiredVersion 	= 1.0;
		requiredAddons[] 	= {"A3_Modules_F"};
		weapons[] 		= {
			"AUR_Rappel_Gear",
			"AUR_Rappel_Rope"
		};
	};
};
class CfgNetworkMessages {
	class AdvancedUrbanRappellingRemoteExecClient {
		module 		= "AdvancedUrbanRappelling";
		parameters[] 	= {"ARRAY","STRING","OBJECT","BOOL"};
	};
	class AdvancedUrbanRappellingRemoteExecServer {
		module 		= "AdvancedUrbanRappelling";
		parameters[] 	= {"ARRAY","STRING","BOOL"};
	};
};
class CfgFunctions {
	class SA {
		class AdvancedUrbanRappelling {
			file = "\AUR_AdvancedUrbanRappelling\functions";
			class advancedUrbanRappellingInit {
				postInit = 1;
			};
		};
	};
};
class CfgSounds {
	class AUR_Rappel_Loop {
		name 		= "AUR_Rappel_Loop";
		sound[] 	= {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_Loop.ogg", db+5, 1};
		titles[] 	= {0, ""};
	};
	class AUR_Rappel_Start {
		name 		= "AUR_Rappel_Start";
		sound[]		= {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_Start.ogg", db+10, 1};
		titles[] 	= {0, ""};
	};
	class AUR_Rappel_End {
		name 		= "AUR_Rappel_End";
		sound[]		= {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_End.ogg", db+10, 1};
		titles[] 	= {0, ""};
	};
};
class CfgWeapons {
	class CBA_MiscItem;
	class CBA_MiscItem_ItemInfo;
	class AUR_Rappel_Gear: CBA_MiscItem {
		scope 			= 2;
		displayName 		= $STR_AUR_RAPPELING_GEAR;
		descriptionShort 	= $STR_AUR_RAPPELING_GEAR_DESCR;
		author 			= "vurtual";
		model 			= "A3\Weapons_F\Items\ToolKit";
		picture 		= "\AUR_AdvancedUrbanRappelling\ui\m_harness_ca";
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 8;
		};
	};
	class AUR_Rappel_Rope: CBA_MiscItem {
		scope 			= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR;
		author 			= "vurtual";
		model			= "\A3\Structures_F_Heli\Items\Tools\Rope_01_F.p3d";
		picture 		= "\AUR_AdvancedUrbanRappelling\ui\m_rope_ca";
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 5;
		};
	};
};
class Extended_PreInit_EventHandlers {
	Test1 = call compile preprocessFileLineNumbers "\AUR_AdvancedUrbanRappelling\scripts\XEH_preInit.sqf"; // CBA_a3 integration
};
#include "cfgAnimations.hpp"
