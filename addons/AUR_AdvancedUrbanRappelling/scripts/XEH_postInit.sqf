// #include "script_component.hpp"
// #include "\a3\editor_f\Data\Scripts\dikCodes.h"

[
	format[localize "STR_AUR_ADVANCED_RAPPELING_NAME"],															// name of mod
	"AUR_allInOne_key",																							// id of the key action
	[format[localize "STR_AUR_RAPPEL_UNRAPPEL_HOTKEY"], format[localize "STR_AUR_RAPPEL_UNRAPPEL_HOTKEY_TIP"]],	// [name of key bind action, tool tip]
	{
		if ([player] call AUR_Rappel_Attach_Action_Check) exitWith {[player] spawn AUR_Rappel_Attach_Action};	// try to attach to already existing rope first
		if ([player] call AUR_Rappel_Action_Check) exitWith {[player] spawn AUR_Rappel_Action};					// rappel, if possible
		if ([player] call AUR_Rappel_Detach_Action_Check) then {[player] spawn AUR_Rappel_Detach_Action};		// detach from rope, if rappelling
	},																											// code, which is executed on key down
	{false},																									// code, which is executed on key up
	[
		19,																										// the key, which has to be hit, in order to start action
		[true, false, false]																					// additional key, which has to be pressed [shift, ctrl, alt]
	]																											// default key bind	in the format [DIK, [shift, ctrl, alt]]
] call CBA_fnc_addKeybind;

[
	format[localize "STR_AUR_ADVANCED_RAPPELING_NAME"],															// name of mod
	"AUR_detachRope_key",																						// id of the key action
	[format[localize "STR_AUR_DETACH_ROPE"], format[localize "STR_AUR_DETACH_ROPE_TIP"]],						// [name of key bind action, tool tip]
	{
		if ([player] call AUR_Detach_Rope_Action_Check) then {[player] spawn AUR_Detach_Rope_Action};
	},																											// code, which is executed on key press
	{false},																									// code, which is executed on key up
	[
		19,																										// the key, which has to be hit, in order to start action
		[false, true, false]																					// additional key, which has to be pressed [shift, ctrl, alt]
	]																											// default key bind	in the format [DIK, [shift, ctrl, alt]]
] call CBA_fnc_addKeybind;