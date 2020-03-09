class CfgPatches {
	class AUR_AdvancedUrbanRappelling {
		author 				= "duda123";
		name 				= "Advanced Urban Rappelling";
		url 				= "https://github.com/sethduda/AdvancedUrbanRappelling";
		units[] 			= {
			"AUR_AdvancedUrbanRappelling",
			"AUR_RopeSmallWeight"
		};
		requiredVersion 	= 1.0;
		requiredAddons[] 	= {"A3_Modules_F"};
		weapons[] 			= {
			"AUR_Rappel_Gear",
			"AUR_Rappel_Rope_10",
			"AUR_Rappel_Rope_20",
			"AUR_Rappel_Rope_30",
			"AUR_Rappel_Rope_50",
			"AUR_Rappel_Rope_70"
		};
	};
};
class CfgNetworkMessages {
	class AdvancedUrbanRappellingRemoteExecClient {
		module 			= "AdvancedUrbanRappelling";
		parameters[] 	= {"ARRAY", "STRING", "OBJECT", "BOOL"};
	};
	class AdvancedUrbanRappellingRemoteExecServer {
		module 			= "AdvancedUrbanRappelling";
		parameters[] 	= {"ARRAY", "STRING", "BOOL"};
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
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_GEAR;
		descriptionShort 	= $STR_AUR_RAPPELING_GEAR_DESCR;
		author 				= "vurtual";
		model 				= "A3\Weapons_F\Items\ToolKit";
		picture 			= "\AUR_AdvancedUrbanRappelling\ui\m_harness_ca";
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 8;
		};
	};
	class AUR_Rappel_Rope_10: CBA_MiscItem {
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE_10;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR_10;
		author 				= "vurtual";
		model				= "\A3\Structures_F_Heli\Items\Tools\Rope_01_F.p3d";
		picture 			= "\AUR_AdvancedUrbanRappelling\ui\m_rope_ca";
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 5;
		};
	};
	class AUR_Rappel_Rope_20: AUR_Rappel_Rope_10 {
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE_20;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR_20;
		author 				= "Nico";
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 10;
		};
	};
	class AUR_Rappel_Rope_30: AUR_Rappel_Rope_20 {
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE_30;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR_30;
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 15;
		};
	};
	class AUR_Rappel_Rope_50: AUR_Rappel_Rope_20 {
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE_50;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR_50;
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 25;
		};
	};
	class AUR_Rappel_Rope_70: AUR_Rappel_Rope_20 {
		scope 				= 2;
		displayName 		= $STR_AUR_RAPPELING_ROPE_70;
		descriptionShort 	= $STR_AUR_RAPPELING_ROPE_DESCR_70;
		class ItemInfo: CBA_MiscItem_ItemInfo {
			mass = 35;
		};
	};
};
class Extended_PreInit_EventHandlers {
	class AUR_AdvancedUrbanRappelling {
		init = "call compile preprocessFileLineNumbers '\AUR_AdvancedUrbanRappelling\scripts\XEH_preInit.sqf'"; // CBA_a3 integration
	};
};
class CfgVehicles {
	class Land_Camping_Light_F;
	class AUR_RopeSmallWeight : Land_Camping_Light_F {
		scope		= 2;
		displayname = "Rope weight";
		model		= "\AUR_AdvancedUrbanRappelling\AUR_weightSmall";
	};
};

#include "cfgAnimations.hpp"