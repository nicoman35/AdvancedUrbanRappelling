class CfgPatches
{
	class AUR_AdvancedUrbanRappelling
	{
		author = "duda123";
		name = "Advanced Urban Rappelling";
		url = "https://github.com/sethduda/AdvancedUrbanRappelling";
		units[] = {"AUR_AdvancedUrbanRappelling"};
		requiredVersion = 1.0;
		requiredAddons[] = {"A3_Modules_F"};
		weapons[] = {"AUR_Rappel_Gear","AUR_Rappel_Rope"};
	};
};

class CfgNetworkMessages
{
	
	class AdvancedUrbanRappellingRemoteExecClient
	{
		module = "AdvancedUrbanRappelling";
		parameters[] = {"ARRAY","STRING","OBJECT","BOOL"};
	};
	
	class AdvancedUrbanRappellingRemoteExecServer
	{
		module = "AdvancedUrbanRappelling";
		parameters[] = {"ARRAY","STRING","BOOL"};
	};
	
};

class CfgFunctions 
{
	class SA
	{
		class AdvancedUrbanRappelling
		{
			file = "\AUR_AdvancedUrbanRappelling\functions";
			class advancedUrbanRappellingInit
			{
				postInit=1;
			};
		};
	};
};

class CfgSounds
{
	class AUR_Rappel_Loop
	{
		name = "AUR_Rappel_Loop";
		sound[] = {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_Loop.ogg", db+5, 1};
		titles[] = {0,""};
	};
	class AUR_Rappel_Start
	{
		name = "AUR_Rappel_Start";
		sound[] = {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_Start.ogg", db+10, 1};
		titles[] = {0,""};
	};
	class AUR_Rappel_End
	{
		name = "AUR_Rappel_End";
		sound[] = {"\AUR_AdvancedUrbanRappelling\sounds\AUR_Rappel_End.ogg", db+10, 1};
		titles[] = {0,""};
	};
};
class CfgWeapons {
	class ItemCore;
	class InventoryItem_Base_F;
	class AUR_Rappel_Gear: ItemCore {
		scope = 2;
		type=4096;
		detectRange = -1;
		simulation = "ItemMineDetector";
		displayName = "Rappelling Gear";
		author = "vurtual";
		model = "A3\Weapons_F\Items\ToolKit";
		descriptionShort = "Essential rappelling gear, including harness, for urban rappelling.";
		class ItemInfo: InventoryItem_Base_F {
			mass = 8;
			};
	};
	class AUR_Rappel_Rope: ItemCore {
		scope = 2;
		type=4096;
		detectRange = -1;
		simulation = "ItemMineDetector";
		displayName = "Rappelling Rope";
		author = "vurtual";
		model = "\A3\Structures_F_Heli\Items\Tools\Rope_01_F.p3d";
		descriptionShort = "10m rope - required to rappel down buildings.";
		class ItemInfo: InventoryItem_Base_F {
			mass = 5;
			};
	};
};
#include "cfgAnimations.hpp"
