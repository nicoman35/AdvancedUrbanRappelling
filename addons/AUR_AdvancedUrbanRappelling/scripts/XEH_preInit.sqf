[
	"AUR_ADVANCED_RAPPELING_ROPES", 																// internal setting name, should always contain a tag! This will be the global variable which takes the value of the setting.
    "CHECKBOX",																						// setting type
	[format[localize "STR_AUR_ROPES_SETTING"], format[localize "STR_AUR_ROPES_SETTING_TIP"]],		// [setting name, tooltip]
	format[localize "STR_AUR_ADVANCED_RAPPELING_NAME"], 											// pretty name of the category where the setting can be found. Can be stringtable entry.
	false,																							// default value of setting
    true																							// "_isGlobal" flag. Set this to true to always have this setting synchronized between all clients in multiplayer
] call CBA_fnc_addSetting;
