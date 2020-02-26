/*
The MIT License (MIT)

Copyright (c) 2016 Seth Duda

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

if (!isServer) exitWith {};

AUR_Advanced_Urban_Rappelling_Install = {

	if (!isNil "AUR_RAPPELLING_INIT") exitWith {};		// Prevent advanced urban rappelling from installing twice
	AUR_RAPPELLING_INIT = true;

	diag_log "Advanced Urban Rappelling Loading...";

	AUR_Has_Addon_Animations_Installed = {
		(count getText (configFile / "CfgMovesBasic" / "ManActions" / "AUR_01")) > 0;
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Has_EM_Animations_Installed = {
		(count getText (configFile / "CfgMovesBasic" / "ManActions" / "babe_em_jump_pst")) > 0;
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Has_Addon_Sounds_Installed = {
		private _config = getArray (configFile / "CfgSounds" / "AUR_Rappel_Start" / "sound");
		private _configMission = getArray (missionConfigFile / "CfgSounds" / "AUR_Rappel_Start" / "sound");
		(count _config > 0 || count _configMission > 0);
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Play_Rappelling_Sounds_Global = {
		_this remoteExec ["AUR_Play_Rappelling_Sounds", 0];
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Play_Rappelling_Sounds = {
		params ["_player", "_rappelDevice", "_rappelAncor"];
		if (!hasInterface || !(call AUR_Has_Addon_Sounds_Installed)) exitWith {};
		if (player distance _player < 15) then {
			[_player, "AUR_Rappel_Start"] call AUR_Play_3D_Sound;
			[_rappelDevice, "AUR_Rappel_Loop"] call AUR_Play_3D_Sound;
		};
		_this spawn {
			params ["_player", "_rappelDevice", "_rappelAncor"];
			private _lastDistanceFromAnchor = _rappelDevice distance _rappelAncor;
			while {_player getVariable ["AUR_Is_Rappelling", false]} do {
				private _distanceFromAnchor = _rappelDevice distance _rappelAncor;
				if (_distanceFromAnchor > _lastDistanceFromAnchor + 0.1 && player distance _player < 15) then {
					[_player, "AUR_Rappel_Loop"] call AUR_Play_3D_Sound;
					sleep 0.2;
					[_rappelDevice, "AUR_Rappel_Loop"] call AUR_Play_3D_Sound;
				};
				sleep 0.9;
				_lastDistanceFromAnchor = _distanceFromAnchor;
			};
		};
		_this spawn {
			params ["_player"];
			while {_player getVariable ["AUR_Is_Rappelling", false]} do {
				sleep 0.1;
			};
			if (player distance _player < 15) then {
				[_player, "AUR_Rappel_End"] call AUR_Play_3D_Sound;
			};
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Play_3D_Sound = {
		params ["_soundSource", "_className"];
		private _config = getArray (configFile / "CfgSounds" / _className / "sound");
		if (count _config > 0) exitWith {
			_soundSource say3D _className;
		};
		private _configMission = getArray (missionConfigFile / "CfgSounds" / _className / "sound");
		if (count _configMission > 0) exitWith {
			_soundSource say3D _className;
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	
	/*
		Description:
		Finds the nearest rappel point within 1.5m of the specified player.
		
		Parameter(s):
		_this select 0: OBJECT - The rappelling unit
		_this select 1: STRING - Search type - "FAST_EXISTS_CHECK" or "POSITION". If FAST_EXISTS_CHECK, this function
			does a quicker search for rappel points and return 1 if a possible rappel point is found, otherwise 0.
			If POSITION, the function will return the rappel position and direction in an array, or empty array if
			no position is found.
			
		Returns: 
		Number or Array (see above)
	*/
	AUR_Find_Nearby_Rappel_Point = {
		params ["_unit", ["_searchType", "FAST_EXISTS_CHECK"]];
		private _unitPosition = getPosASL _unit;
		private _intersectionRadius = 1.5;
		private _intersectionDistance = 4;
		private _intersectionTests = 40;
		if (_searchType == "FAST_EXISTS_CHECK") then {_intersectionTests = 8};
		private _lastIntersectStartASL = [];
		private _lastIntersectionIntersected = false;
		private _edges = [];
		private _edge = [];
		private _fastExistsEdgeFound = false;
				
		for "_i" from 0 to _intersectionTests do {					// Search for nearby edges
			private  _x = cos ((360 / _intersectionTests) * _i);
			private  _y = sin ((360 / _intersectionTests) * _i);
			private _directionUnitVector = vectorNormalized [_x, _y, 0];
			private _intersectStartASL = _unitPosition vectorAdd (_directionUnitVector vectorMultiply _intersectionRadius) vectorAdd [0, 0, 1.5];
			private _intersectEndASL = _intersectStartASL vectorAdd [0, 0, -5];
			private _surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 1];
			if (_searchType == "FAST_EXISTS_CHECK") then {
				if (count _surfaces == 0) exitWith {_fastExistsEdgeFound = true};
			} else {
				if (count _surfaces > 0) then {
					if (!_lastIntersectionIntersected && _i != 0) then {
						// Moved from edge to no edge (edge end)
						_edge pushBack _lastIntersectStartASL;
						_edges pushBack _edge;
					};
					_lastIntersectionIntersected = true;
				} else {
					if (_lastIntersectionIntersected && _i != 0) then {
						// Moved from no edge to edge (edge start)
						_edge = [_intersectStartASL];
						if (_i == _intersectionTests) then {
							_edges pushBack _edge;
						};
					};
					_lastIntersectionIntersected = false;
				};
				_lastIntersectStartASL = _intersectStartASL;
			};
		};
		
		if (_searchType == "FAST_EXISTS_CHECK") exitWith {_fastExistsEdgeFound};
				
		if (count _edge == 1) then {								// If edges found, return nearest edge
			private _firstEdge = _edges deleteAt 0;
			_edges deleteAt (count _edges - 1);
			_edges pushBack (_edge + _firstEdge);
		};
		
		private _largestEdgeDistance = 0;
		private _largestEdge = [];
		{
			private _edgeDistance = (_x select 0) distance (_x select 1);
			if (_edgeDistance > _largestEdgeDistance) then {
				_largestEdgeDistance = _edgeDistance;
				_largestEdge = _x;
			};
		} forEach _edges;
		
		if (count _largestEdge > 0) then {
			private _edgeStart = (_largestEdge select 0);
			_edgeStart set [2, getPosASL _unit select 2];
			private _edgeEnd = (_largestEdge select 1);
			_edgeEnd set [2, getPosASL _unit select 2];
			private _edgeMiddle = _edgeStart vectorAdd ((_edgeEnd vectorDiff _edgeStart) vectorMultiply 0.5);
			private _edgeDirection = vectorNormalized ((_edgeStart vectorFromTo _edgeEnd) vectorCrossProduct [0, 0, 1]);
			
			// Check to see if there's a surface we can attach the rope to (so it doesn't hang in the air)
			_unitPositionASL = getPosASL _unit;
			private _intersectStartASL = _unitPositionASL vectorAdd ((_unitPositionASL vectorFromTo _edgeStart) vectorMultiply (_intersectionRadius));
			_intersectEndASL = _intersectStartASL vectorAdd ((_intersectStartASL vectorFromTo _unitPositionASL) vectorMultiply (_intersectionRadius * 2)) vectorAdd [0, 0, -0.5];
			_surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 1, "FIRE", "NONE"];
			if (count _surfaces > 0) then {
				_edgeStart = (_surfaces select 0) select 0;
			};
			
			_intersectStartASL = _unitPositionASL vectorAdd ((_unitPositionASL vectorFromTo _edgeEnd) vectorMultiply (_intersectionRadius));
			_intersectEndASL = _intersectStartASL vectorAdd ((_intersectStartASL vectorFromTo _unitPositionASL) vectorMultiply (_intersectionRadius * 2)) vectorAdd [0, 0, -0.5];
			_surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 1, "FIRE", "NONE"];
			if (count _surfaces > 0) then {
				_edgeEnd = (_surfaces select 0) select 0;
			};
			
			_intersectStartASL = _unitPositionASL vectorAdd ((_unitPositionASL vectorFromTo _edgeMiddle) vectorMultiply (_intersectionRadius));
			_intersectEndASL = _intersectStartASL vectorAdd ((_intersectStartASL vectorFromTo _unitPositionASL) vectorMultiply (_intersectionRadius * 2)) vectorAdd [0, 0, -0.5];
			_surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 1, "FIRE", "NONE"];
			if (count _surfaces > 0) then {
				_edgeMiddle = (_surfaces select 0) select 0;
			};
			
			// Check to make sure there's an opening for rappelling (to stop people from rappelling through a wall)
			_intersectStartASL = _unitPosition vectorAdd [0, 0, 1.5];
			_intersectEndASL = _intersectStartASL vectorAdd (_edgeDirection vectorMultiply 4);
			_surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 1, "FIRE", "NONE"];
			if (count _surfaces > 0) exitWith {[]};
		
			[_edgeMiddle, _edgeDirection, [_edgeStart, _edgeEnd, _edgeMiddle]];
		} else {
			[];
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappellng_Ropes = [				// [name of rope item, length in m]
		["AUR_Rappel_Rope_10", 10],
		["ACE_rope12", 12],
		["ACE_rope15", 15],
		["ACE_rope18", 18],
		["AUR_Rappel_Rope_20", 20],
		["ACE_rope27", 27],
		["AUR_Rappel_Rope_30", 30],
		["ACE_rope36", 36],
		["AUR_Rappel_Rope_50", 50],
		["AUR_Rappel_Rope_70", 70]
	];

	AUR_Rappel_Action = {
		params ["_player"];	
		if ([_player] call AUR_Rappel_Action_Check) then {
			private _rappelPoint = [_player, "POSITION"] call AUR_Find_Nearby_Rappel_Point;
			if (count _rappelPoint > 0) then {
				_player setVariable ["AUR_Rappelling_Last_Started_Time", diag_tickTime];
				_player setVariable ["AUR_Rappelling_Last_Rappel_Point", _rappelPoint];				
				diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel_Action) _rappelPoint ASL: ", (ASLtoAGL (_rappelPoint select 0)) select 2];
				diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel_Action) player ASL to agl: ", [_player] call AUR_Get_Unit_Height_Above_Ground];
				// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel_Action) rappel point middle ASL: ", getPos (_rappelPoint select 0) select 2, ", player ASL to agl: ", [_player] call AUR_Get_Unit_Height_Above_Ground];
				// private _ropeLength = ([_player] call AUR_Get_Unit_Height_Above_Ground) * 1.3;
				private _ropeLength = ([_player] call AUR_Get_Unit_Height_Above_Ground) + ((([_player] call AUR_Get_Unit_Height_Above_Ground) / 10) min 5);  // get a length of required height plus a length of 10% or 5 meter, dependent on which is smaller
				diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel_Action) _ropeLength wanted: ", _ropeLength];
				if (AUR_ADVANCED_RAPPELING_ITEMS_NEEDED) then {
					private _totalLength = 0;
					{
						private _rope = _x select 0;
						private _length = _x select 1;
						_totalLength = _totalLength + (({_x == _rope} count items player) * _length);
						if (_totalLength >= _ropeLength) exitWith {};
					} forEach AUR_Rappellng_Ropes;
					// _ropeLength = (_ropeLength + 3) min (_totalLength + 3);
					_ropeLength = _ropeLength min _totalLength;
				};
				[_player, _rappelPoint select 0, _rappelPoint select 1, _ropeLength] call AUR_Rappel;
			} else {
				[[format[localize "STR_COULD_NOT_ATTACH_ROPE"], false], "AUR_Hint", _player] call AUR_RemoteExec;
			};
		} else {
			[[format[localize "STR_COULD_NOT_ATTACH_ROPE"], false], "AUR_Hint", _player] call AUR_RemoteExec;
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Get_Unit_Height_Above_Ground = {
		params ["_unit"];
		(ASLtoAGL (getPosASL _unit)) select 2;
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_Action_Check = {
		params ["_unit"];
		if (AUR_ADVANCED_RAPPELING_ITEMS_NEEDED && (!("AUR_Rappel_Gear" in (items _unit)) || !([_unit] call AUR_Rappel_Rope_Check))) exitWith {false};
		if (_unit getVariable ["AUR_Is_Rappelling", false]) exitWith {false};
		if (vehicle _unit != _unit) exitWith {false};
		if (([_unit] call AUR_Get_Unit_Height_Above_Ground) < 4) exitWith {false};
		if !([_unit, "FAST_EXISTS_CHECK"] call AUR_Find_Nearby_Rappel_Point) exitWith {false};
		if (count ([_unit, "POSITION"] call AUR_Find_Nearby_Rappel_Point) == 0) exitWith {false};
		true
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_Rope_Check = {
		params ["_unit"];
		private _rope = false;
		{if (_x select 0 in (items _unit)) exitWith {_rope = true}} forEach AUR_Rappellng_Ropes;
		_rope
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	
	AUR_Rappel_Climb_To_Top_Action = {
		params ["_player"];
		_player setVariable ["AUR_Climb_To_Top", true];
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_Climb_To_Top_Action_Check = {
		params ["_player"];
		if !(_player getVariable ["AUR_Is_Rappelling", false]) exitWith {false};
		private _topRope = player getVariable ["AUR_Rappel_Rope_Top", nil];
		if (isNil "_topRope") exitWith {false};
		if (ropeLength _topRope > 1) exitWith {false};
		true
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_Detach_Action = {
		params ["_player"];
		_player setVariable ["AUR_Detach_Rope", true];
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_Detach_Action_Check = {
		params ["_player"];
		if !(_player getVariable ["AUR_Is_Rappelling", false]) exitWith {false};
		true
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Get_AI_Units_Ready_To_Rappel = {
		params ["_player"];
		if (leader _player != _player) exitWith {[]};
		private _hasAiUnits = false;
		{
			if (!isPlayer _x) exitWith {
				_hasAiUnits = true;
			};
		} forEach units _player;
		if (!_hasAiUnits) exitWith {[]};
		private _canRappel = [_player] call AUR_Rappel_Action_Check;
		private _isRappelling = _player getVariable ["AUR_Is_Rappelling", false];
		private _didRappel = (diag_tickTime - (_player getVariable ["AUR_Rappelling_Last_Started_Time", 0])) < 300;
		private _aiUnitsReady = [];
		if (_canRappel || _isRappelling || _didRappel) then {
			private _rappelPoint = _player getVariable ["AUR_Rappelling_Last_Rappel_Point", []];
			private _rappelPosition = [0, 0, 0];
			if(count _rappelPoint > 0) then {
				_rappelPosition = ASLToATL (_rappelPoint select 0);
			};
			if (_canRappel) then {
				_rappelPosition = getPosATL _player;
			};
			{
				if (!isPlayer _x && 
					_rappelPosition distance _x < 15 && 
					abs ((_rappelPosition select 2) - ((getPosATL _x) select 2)) < 4 && 
					not (_x getVariable ["AUR_Is_Rappelling",false]) && 
					alive _x && vehicle _x == _x &&
					(!AUR_ADVANCED_RAPPELING_ITEMS_NEEDED || (AUR_ADVANCED_RAPPELING_ITEMS_NEEDED && "AUR_Rappel_Gear" in (items _x) && ([_x] call AUR_Rappel_Rope_Check)))) then {
					_aiUnitsReady pushBack _x;
				};
			} forEach units _player;
		};
		_aiUnitsReady
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_AI_Units_Action = {
		params ["_player"];
		private _aiUnits = [_player] call AUR_Get_AI_Units_Ready_To_Rappel;
		private _rappelPoint = _player getVariable ["AUR_Rappelling_Last_Rappel_Point", []];
		if ([_player] call AUR_Rappel_Action_Check) then {
			_rappelPoint = [_player, "POSITION"] call AUR_Find_Nearby_Rappel_Point;	
		};
		private _index = 0;
		private _allRappelPoints = _rappelPoint select 2;
		if (count _rappelPoint > 0) then {
			{
				if (!(_x getVariable ["AUR_Is_Rappelling", false])) then {
					private _ropeLength = 60;
					if (AUR_ADVANCED_RAPPELING_ITEMS_NEEDED) then {
						private _unit = _x;
						private _totalLength = 0;
						{
							private _rope = _x select 0;
							private _length = _x select 1;
							_totalLength = _totalLength + (({_x == _rope} count items _unit) * _length);
						} forEach AUR_Rappellng_Ropes;
						_ropeLength = _ropeLength min _totalLength;						
						// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel_AI_Units_Action) _unit: ", _x, ", _ropeLength: ", _ropeLength, ", _totalLength: ", _totalLength];
					};
					[_x, _allRappelPoints select (_index mod 3), _rappelPoint select 1, _ropeLength] spawn AUR_Rappel;
					sleep 5;
				};
				_index = _index + 1;
			} forEach (_aiUnits);
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel_AI_Units_Action_Check = {
		params ["_player"];
		if (leader _player != _player) exitWith {false};
		private _hasAiUnits = false;
		{
			if (!isPlayer _x) exitWith {_hasAiUnits = true};
		} forEach units _player;
		if (!_hasAiUnits) exitWith {false};
		if ((count ([_player] call AUR_Get_AI_Units_Ready_To_Rappel)) == 0) exitWith {false};
		true
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Rappel = {
		params ["_unit", "_rappelPoint", "_rappelDirection", "_ropeLength"];
		_unit setVariable ["AUR_Is_Rappelling", true, true];
		
		diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11%12%13", time, "s  (AUR_Rappel START) unit ", _unit, ", _ropeLength: ", _ropeLength];
								
		private _unitPreRappelPosition = getPosASL _unit;
		private _unitStartPosition = _rappelPoint vectorAdd (_rappelDirection vectorMultiply 2);			// Start player rappelling 2m out from the rappel point
		_unitStartPosition set [2, getPosASL _unit select 2];
		_unit setPosWorld _unitStartPosition;
		private _anchor = createVehicle ["Land_Can_V2_F", _unit, [], 0, "CAN_COLLIDE"];					// Create anchor for rope (at rappel point)
		hideObject _anchor;
		_anchor enableSimulation false;
		_anchor allowDamage false;
		[[_anchor], "AUR_Hide_Object_Global"] call AUR_RemoteExecServer;
		private _vehicle = "B_static_AA_F";
		if (isClass(configfile >> "CfgPatches" >> "ace_main")) then {_vehicle = "ACE_O_T_SpottingScope"};	// ACE v3.12.6 compatibility
		private _rappelDevice = createVehicle [_vehicle, _unit, [], 0, "CAN_COLLIDE"];					// Create rappel device (attached to player)
		hideObject _rappelDevice;
		_rappelDevice setPosWorld _unitStartPosition;
		_rappelDevice allowDamage false;
		[[_rappelDevice], "AUR_Hide_Object_Global"] call AUR_RemoteExecServer;
		
		[[_unit, _rappelDevice, _anchor], "AUR_Play_Rappelling_Sounds_Global"] call AUR_RemoteExecServer;
		private _rope2 = ropeCreate [_rappelDevice, [-0.15, 0, 0], _ropeLength - 1];
		_rope2 allowDamage false;
		private _rope1 = ropeCreate [_rappelDevice, [0,0.15,0], _anchor, [0, 0, 0], 1];
		_rope1 allowDamage false;		
		_anchor setPosWorld _rappelPoint;

		_unit setVariable ["AUR_Rappel_Rope_Top", _rope1];
		_unit setVariable ["AUR_Rappel_Rope_Bottom", _rope2];
		_unit setVariable ["AUR_Rappel_Rope_Length", _ropeLength];

		[_unit] spawn AUR_Enable_Rappelling_Animation;
		_unit setVectorDir (_rappelDirection vectorMultiply -1);											// Make player face the wall they're rappelling on
		
		private _gravityAccelerationVec = [0, 0, -9.8];
		private _velocityVec = [0, 0, 0];
		private _lastTime = diag_tickTime;
		private _lastPosition = AGLtoASL (_rappelDevice modelToWorldVisual [0, 0, 0]);
		private _decendRopeKeyDownHandler = -1;
		private _ropeKeyUpHandler = -1;
		if (_unit == player) then {	
			_decendRopeKeyDownHandler = (findDisplay 46) displayAddEventHandler ["KeyDown", {
				if (_this select 1 in (actionKeys "MoveBack")) then {
					private _ropeLength = player getVariable ["AUR_Rappel_Rope_Length", 100];
					private _topRope = player getVariable ["AUR_Rappel_Rope_Top", nil];
					if (!isNil "_topRope") then {
						if ((ropeLength _topRope) + 2 < _ropeLength)  then {
							private _sinkRate = AUR_ADVANCED_RAPPELING_VELOCITY * 2;
							if (_sinkRate > 6) then {_sinkRate = 6};
							
							// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11%12%13", time, "s  (AUR_Rappel) (player): ", _unit, ", length toprope: ", ropeLength _topRope, ", _sinkRate: ", _sinkRate, ", 3. arg: ", ((ropeLength _topRope) + (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) min _ropeLength];
							
							ropeUnwind [_topRope, _sinkRate, ((ropeLength _topRope) + (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) min _ropeLength];
							private _bottomRope = player getVariable ["AUR_Rappel_Rope_Bottom", nil];
							if (!isNil "_bottomRope") then {
								ropeUnwind [_bottomRope, _sinkRate, ((ropeLength _bottomRope) - (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) max 0];
										
								// diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11%12%13", time, "s  (AUR_Rappel) (player) length _bottomRope: ", ropeLength _bottomRope, ", 3. arg: ", ((ropeLength _bottomRope) - (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) max 0];
								
							};
						};
					};
				};
				if (_this select 1 in (actionKeys "MoveForward")) then {
					private _ropeLength = player getVariable ["AUR_Rappel_Rope_Length", 100];
					private _topRope = player getVariable ["AUR_Rappel_Rope_Top", nil];
					if (!isNil "_topRope") then {
						private _climbVelocity = AUR_ADVANCED_RAPPELING_VELOCITY / 10;
						if (_climbVelocity > 0.2) then {_climbVelocity = 0.2};
						private _climbRate = AUR_ADVANCED_RAPPELING_VELOCITY;
						if (_climbRate > 2) then {_climbRate = 2};
						ropeUnwind [_topRope, _climbRate, ((ropeLength _topRope) - _climbVelocity) min _ropeLength];
						private _bottomRope = player getVariable ["AUR_Rappel_Rope_Bottom", nil];
						if (!isNil "_bottomRope") then {
							ropeUnwind [ _bottomRope, _climbRate, ((ropeLength _bottomRope) + _climbVelocity) max 0];
						};
					};
				};
				if (_this select 1 in (actionKeys "Turbo") && player getVariable ["AUR_JUMP_PRESSED_START", 0] == 0) then {
					player setVariable ["AUR_JUMP_PRESSED_START", diag_tickTime];
				};
				
				if (_this select 1 in (actionKeys "TurnRight")) then {
					player setVariable ["AUR_RIGHT_DOWN", true];
				};
				if (_this select 1 in (actionKeys "TurnLeft")) then {
					player setVariable ["AUR_LEFT_DOWN", true];
				};
			}];
			_ropeKeyUpHandler = (findDisplay 46) displayAddEventHandler ["KeyUp", {
				if (_this select 1 in (actionKeys "Turbo")) then {
					player setVariable ["AUR_JUMP_PRESSED", true];
					player setVariable ["AUR_JUMP_PRESSED_TIME", diag_tickTime - (player getVariable ["AUR_JUMP_PRESSED_START", diag_tickTime])];
					player setVariable ["AUR_JUMP_PRESSED_START", 0];	
				};
				if (_this select 1 in (actionKeys "TurnRight")) then {
					player setVariable ["AUR_RIGHT_DOWN", false];
				};
				if (_this select 1 in (actionKeys "TurnLeft")) then {
					player setVariable ["AUR_LEFT_DOWN", false];
				};
			}];
		} else {
			// [_rope1, _rope2] spawn {
				// params ["_rope1", "_rope2"];
				// sleep 1;
				// private _randomSpeedFactor = ((random 10) - 5) / 10;
				// private _sinkRate = AUR_ADVANCED_RAPPELING_VELOCITY * 2;
				// if (_sinkRate > 6) then {_sinkRate = 6};
				// ropeUnwind [_rope1, _sinkRate + _randomSpeedFactor, (ropeLength _rope1) + (ropeLength _rope2)];
				// ropeUnwind [_rope2, _sinkRate + _randomSpeedFactor, 0];
			// };
			
			[_unit] spawn {
				params ["_unit"];
				sleep 1;
				private _ropeLength = _unit getVariable ["AUR_Rappel_Rope_Length", 100];													// get rope length of rope in unit's inventory
				private _topRope = _unit getVariable ["AUR_Rappel_Rope_Top", nil];
				private _bottomRope = _unit getVariable ["AUR_Rappel_Rope_Bottom", nil];
				private _randomSpeedFactor = ((random 10) - 5) / 10;																		// + / - 0.5 m / s random speed add
				private _sinkRate = AUR_ADVANCED_RAPPELING_VELOCITY * 2;																	// set sink rate in meter per second dependent on CBA slider setting
				if (_sinkRate > 6) then {_sinkRate = 6};																					// do not allow super human velocities
				_sinkRate = _sinkRate + _randomSpeedFactor;
				// while {!isNil "_topRope" && (ropeLength _topRope) + 3 < _ropeLength && (ropeLength _bottomRope) > 3} do {					// rappel down AI unit, until rope end or less than 3 m above bottom
				while {!isNil "_topRope" && (ropeLength _topRope) + 3 < _ropeLength && (ropeLength _bottomRope) > 3 && (position _unit select 2) > 2} do {					// rappel down AI unit, until rope end or less than 3 m above bottom
					ropeUnwind [_topRope, _sinkRate, ((ropeLength _topRope) + (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) min _ropeLength];
					// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Rappel) _unit: ", _unit, ", length topRope: ", ropeLength _topRope, ", length bottomRope: ", ropeLength _bottomRope];
					if (!isNil "_bottomRope") then {
						ropeUnwind [_bottomRope, _sinkRate, ((ropeLength _bottomRope) - (AUR_ADVANCED_RAPPELING_VELOCITY / 10)) max 0];
					};
					sleep 0.04;
				};
				// if (([_unit] call AUR_Get_Unit_Height_Above_Ground) < 3) exitWith {_unit setVariable ["AUR_Detach_Rope", true]};			// detach AI unit from rope, if it's height above ground is 3 m or less, then leave spawn loop
				if ((position _unit select 2) < 3) exitWith {_unit setVariable ["AUR_Detach_Rope", true]};			// detach AI unit from rope, if it's height above the surface is 3 m or less, then leave spawn loop
				sleep 3;
				// _unit groupChat format[localize "STR_ROPE_TOO_SHORT", str _ropeLength];
				_unit groupChat format[localize "STR_ROPE_TOO_SHORT", _ropeLength];															// AI omplains about rope too short
				sleep 3;
				while {!isNil "_topRope"} do {																								// after a short pause, AI unit will climb back up
					private _climbVelocity = AUR_ADVANCED_RAPPELING_VELOCITY / 10;
					if (_climbVelocity > 0.2) then {_climbVelocity = 0.2};
					private _climbRate = AUR_ADVANCED_RAPPELING_VELOCITY;
					if (_climbRate > 2) then {_climbRate = 2};
					ropeUnwind [_topRope, _climbRate, ((ropeLength _topRope) - _climbVelocity) min _ropeLength];
					if (!isNil "_bottomRope") then {
						ropeUnwind [_bottomRope, _climbRate, ((ropeLength _bottomRope) + _climbVelocity) max 0];
					};
					if ((ropeLength _topRope) <= 1) exitWith {
						sleep 1;
						_unit setVariable ["AUR_Climb_To_Top", true];																		// set true, once AI reaches top, then leave spawn loop
					};
					sleep 0.04;
				};
			};
		};

		private _walkingOnWallForce = [0, 0, 0];
		private _lastAiJumpTime = diag_tickTime;

		// while {true} do {
		while {alive _unit && vehicle _unit == _unit && ropeLength _rope2 > 1 && !(_unit getVariable ["AUR_Climb_To_Top", false]) && !(_unit getVariable ["AUR_Detach_Rope", false])} do {
			private _currentTime = diag_tickTime;
			private _timeSinceLastUpdate = _currentTime - _lastTime;
			_lastTime = _currentTime;
			if (_timeSinceLastUpdate > 1) then {
				_timeSinceLastUpdate = 0;
			};

			private _environmentWindVelocity = wind;
			private _unitWindVelocity = _velocityVec vectorMultiply -1;
			private _totalWindVelocity = _environmentWindVelocity vectorAdd _unitWindVelocity;
			private _totalWindForce = _totalWindVelocity vectorMultiply (9.8 / 53);

			private _accelerationVec = _gravityAccelerationVec vectorAdd _totalWindForce vectorAdd _walkingOnWallForce;
			_velocityVec = _velocityVec vectorAdd (_accelerationVec vectorMultiply _timeSinceLastUpdate);
			private _newPosition = _lastPosition vectorAdd (_velocityVec vectorMultiply _timeSinceLastUpdate);

			if (_newPosition distance _rappelPoint > ((ropeLength _rope1) + 1)) then {
				_newPosition = (_rappelPoint) vectorAdd ((vectorNormalized ((_rappelPoint) vectorFromTo _newPosition)) vectorMultiply ((ropeLength _rope1) + 1));
				private _surfaceVector = (vectorNormalized (_newPosition vectorFromTo (_rappelPoint)));
				_velocityVec = _velocityVec vectorAdd ((_surfaceVector vectorMultiply (_velocityVec vectorDotProduct _surfaceVector)) vectorMultiply -1);
			};

			private _radius = 0.85;
			private _intersectionTests = 10;
			for "_i" from 0 to _intersectionTests do {
				private _axis1 = cos ((360 / _intersectionTests) * _i);
				private _axis2 = sin ((360 / _intersectionTests) * _i);
				{
					private _directionUnitVector = vectorNormalized _x;
					private _intersectStartASL = _newPosition;
					private _intersectEndASL = _newPosition vectorAdd (_directionUnitVector vectorMultiply _radius);
					private _surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 10, "FIRE", "NONE"];
					{
						_x params ["_intersectionPositionASL", "_surfaceNormal", "_intersectionObject"];
						private _objectFileName = str _intersectionObject;
						if ((_objectFileName find "rope") == -1 && not (_intersectionObject isKindOf "RopeSegment") && (_objectFileName find " t_") == -1 && (_objectFileName find " b_") == -1) then {
							if (_newPosition distance _intersectionPositionASL < 1) then {
								_newPosition = _intersectionPositionASL vectorAdd ((vectorNormalized (_intersectEndASL vectorFromTo _intersectStartASL)) vectorMultiply (_radius));
							};
							_velocityVec = _velocityVec vectorAdd (( _surfaceNormal vectorMultiply (_velocityVec vectorDotProduct _surfaceNormal)) vectorMultiply -1);
						};
					} forEach _surfaces;
				} forEach [[_axis1, _axis2, 0], [_axis1, 0, _axis2], [0, _axis1, _axis2]];
			};

			private _jumpPressed = _unit getVariable ["AUR_JUMP_PRESSED", false];
			private _jumpPressedTime = _unit getVariable ["AUR_JUMP_PRESSED_TIME", 0];
			private _leftDown = _unit getVariable ["AUR_LEFT_DOWN", false];
			private _rightDown = _unit getVariable ["AUR_RIGHT_DOWN", false];

			if (_unit != player) then {			// Simulate AI jumping off wall randomly
				if (diag_tickTime - _lastAiJumpTime > (random 30) max 5) then {
					_jumpPressed = true;
					_jumpPressedTime = 0;
					_lastAiJumpTime = diag_tickTime;
				};
			};

			if (_jumpPressed || _leftDown || _rightDown) then {
				_intersectStartASL = _newPosition;
				_intersectEndASL = _intersectStartASL vectorAdd (vectorDir _unit vectorMultiply (_radius + 0.3));
				_surfaces = lineIntersectsSurfaces [_intersectStartASL, _intersectEndASL, _unit, objNull, true, 10, "GEOM", "NONE"];	// Get the surface normal of the surface the player is hanging against
				_isAgainstSurface = false;
				{
					_x params ["_intersectionPositionASL", "_surfaceNormal", "_intersectionObject"];
					_objectFileName = str _intersectionObject;
					if((_objectFileName find "rope") == -1 && not (_intersectionObject isKindOf "RopeSegment") && (_objectFileName find " t_") == -1 && (_objectFileName find " b_") == -1 ) exitWith {
						_isAgainstSurface = true;
					};
				} forEach _surfaces;

				if (_isAgainstSurface) then {
					if (_jumpPressed) then {
						_jumpForce = ((( 1.5 min _jumpPressedTime ) / 1.5) * 4.5) max 2.5;
						_velocityVec = _velocityVec vectorAdd (vectorDir _unit vectorMultiply (_jumpForce * -1));
						_unit setVariable ["AUR_JUMP_PRESSED", false];
					};
					if (_rightDown) then {
						_walkingOnWallForce = (vectorNormalized ((vectorDir _unit) vectorCrossProduct [0, 0, 1])) vectorMultiply 1;
					};
					if (_leftDown) then {
						_walkingOnWallForce = (vectorNormalized ((vectorDir _unit) vectorCrossProduct [0, 0, -1])) vectorMultiply 1;
					};
					if (_rightDown && _leftDown) then {
						_walkingOnWallForce = [0, 0, 0];
					}
				} else {
					_unit setVariable ["AUR_JUMP_PRESSED", false];
				};
			} else {
				_walkingOnWallForce = [0, 0, 0];
			};

			_rappelDevice setPosWorld (_newPosition vectorAdd (_velocityVec vectorMultiply 0.1));
			_rappelDevice setVectorDir (vectorDir _unit); 
			_unit setPosWorld (_newPosition vectorAdd [0, 0, -0.6]);
			_unit setVelocity [0, 0, 0];

			_lastPosition = _newPosition;
			_topRope = _unit getVariable ["AUR_Rappel_Rope_Top", nil];
			if (!isNil "_topRope" && AUR_ADVANCED_RAPPELING_ITEMS_NEEDED && (_ropeLength < ((ropeLength _topRope) -5))) then {
				_unit setVariable ["AUR_Detach_Rope", true];
			};

			// if (!alive _unit || vehicle _unit != _unit || ropeLength _rope2 <= 1 || _unit getVariable ["AUR_Climb_To_Top", false] || _unit getVariable ["AUR_Detach_Rope", false]) exitWith {};
			sleep 0.01;
		};

		if (ropeLength _rope2 > 1 && alive _unit && vehicle _unit == _unit && not (_unit getVariable ["AUR_Climb_To_Top", false])) then {		
			_unitStartASLIntersect = getPosASL _unit;
			_unitEndASLIntersect = [_unitStartASLIntersect select 0, _unitStartASLIntersect select 1, (_unitStartASLIntersect select 2) - 5];
			_surfaces = lineIntersectsSurfaces [_unitStartASLIntersect, _unitEndASLIntersect, _unit, objNull, true, 10];
			_intersectionASL = [];
			{
				scopeName "surfaceLoop";
				_intersectionObject = _x select 2;
				_objectFileName = str _intersectionObject;
				if ((_objectFileName find " t_") == -1 && (_objectFileName find " b_") == -1) then {
					_intersectionASL = _x select 0;
					breakOut "surfaceLoop";
				};
			} forEach _surfaces;
			
			if (count _intersectionASL != 0) then {
				_unit allowDamage false;
				_unit setPosASL _intersectionASL;
			};		

			if (_unit getVariable ["AUR_Detach_Rope", false]) then {
				if (count _intersectionASL == 0) then {
					_unit allowDamage true;		// Player detached from rope. Don't prevent damage if we didn't find a position on the ground
				};	
			};
		};
		
		if (_unit getVariable ["AUR_Climb_To_Top", false]) then {
			ropeDestroy _rope1;
			deleteVehicle _anchor;
			ropeDestroy _rope2;
			deleteVehicle _rappelDevice;
			// _unit allowDamage false;
			// _unit setPosASL _unitPreRappelPosition;
			_unit setPosASL [getPosASL _unit select 0, getPosASL _unit select 1, (getPosASL _unit select 2) + 1];
			if (call AUR_Has_EM_Animations_Installed) then {			
				[_unit, true] call babe_em_fnc_detect;
				// sleep 3;
				// ropeDestroy _rope1;
				// deleteVehicle _anchor;
				// ropeDestroy _rope2;
				// deleteVehicle _rappelDevice;
			} else {
				_unit allowDamage false;
				_unit setPosASL _unitPreRappelPosition;
				sleep 0.1;
				_unit allowDamage true;
			};
		} else {
			detach _rappelDevice;
			ropeDestroy _rope1;
			ropeDestroy _rope2;
			_rappelDevice ropeDetach _rope1;
			// sleep 5;
			deleteVehicle _rappelDevice;
			// deleteVehicle _rappelDevice;
			_rope1 = ropeCreate [_anchor, [0,0,-0.1], position _unit, _ropeLength];
			// _rope1 = ropeCreate [_rappelDevice, [0,0.15,0], _anchor, [0, 0, -0.1], _ropeLength];
			// _rope1 = ropeCreate [_anchor, [0, 0, -0.1], _rappelDevice, [0,0.15,0], _ropeLength];
			diag_log formatText ["%1%2%3%4%5%6%7%8%9%10%11%12%13", time, "s  (AUR_Rappel END) unit ", _unit, ", created new rope, _ropeLength: ", _ropeLength];
			// [_rappelDevice] ropeAttachTo _rope1;
			
			
		};
		
		// if (_unit getVariable ["AUR_Climb_To_Top", false]) then {
			// ropeDestroy _rope1;
			// deleteVehicle _anchor;
			// ropeDestroy _rope2;
			// deleteVehicle _rappelDevice;
		// } else {
			// ropeDestroy _rope2;
			// _rappelDevice ropeDetach _rope1;
			// detach _rappelDevice;
		// };
		
		if (AUR_ADVANCED_RAPPELING_REMOVE_ROPES && AUR_ADVANCED_RAPPELING_ITEMS_NEEDED) then {							// If activated via CBA, once rappeling unit arrives at the bottom, this section will delete ropes from units inventory, and pile up those ropes at upper starting point
			_topRope = _unit getVariable ["AUR_Rappel_Rope_Top", nil];
			if (!isNil "_topRope") then {
				if (((getPosASL _unit select 2) + 1) < (_unitPreRappelPosition select 2)) then {
					private _neededLength = ceil(ropeLength _topRope - 3);
					if (_neededLength <= 0) exitWith {};	
					_ropePile = "groundWeaponHolder" createVehicle _unitPreRappelPosition;
					_ropePile setPosASL _unitPreRappelPosition;
					private _unitRopes = [];
					private _ropeLengths = [];
					{
						private _rope = _x select 0;
						private _length = _x select 1;
						if (({_x == _rope} count items _unit) > 0) then {
							_unitRopes pushBack _rope;
							_ropeLengths pushBack _length;
						};
					} forEach AUR_Rappellng_Ropes;																		// build arrays containing unit's rappelling ropes and respective lengths 
					while {_neededLength > 0} do {
						private _index = [_ropeLengths, _neededLength] call AUR_Get_Shortest_Required_Rope_Length;		// let's remove ropes somewhat intelligent
						private _rope = _unitRopes select _index;
						_unit removeItem _rope;
						_ropePile addItemCargoGlobal [_rope, 1];
						private _length = _ropeLengths select _index;
						_neededLength = _neededLength - _length;
						if (!(_rope in (items _unit))) then {
							_unitRopes deleteAt _index;
							_ropeLengths deleteAt _index;
						};
					};
				};
			};
		};
		
		// ropeDestroy _rope1;
		// deleteVehicle _anchor;
		// ropeDestroy _rope2;
		// deleteVehicle _rappelDevice;
		
		_unit setVariable ["AUR_Is_Rappelling", nil, true];
		_unit setVariable ["AUR_Rappel_Rope_Top", nil];
		_unit setVariable ["AUR_Rappel_Rope_Bottom", nil];
		_unit setVariable ["AUR_Rappel_Rope_Length", nil];
		_unit setVariable ["AUR_Climb_To_Top", nil];
		_unit setVariable ["AUR_Detach_Rope", nil];
		_unit setVariable ["AUR_Animation_Move", nil, true];

		if (_decendRopeKeyDownHandler != -1) then {			
			(findDisplay 46) displayRemoveEventHandler ["KeyDown", _decendRopeKeyDownHandler];
		};

		sleep 2;
		_unit allowDamage true;
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Get_Shortest_Required_Rope_Length = { 			// get the shortest rope, that is required for the needed length 
		params ["_ropeLengths", "_neededLength"];
		private _index = (count _ropeLengths) - 1;
		{
			if (_x >= _neededLength) exitWith {_index = _forEachIndex};
		} forEach _ropeLengths;	
		_index
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Enable_Rappelling_Animation_Global = {
		params ["_player"];
		[_player, true] remoteExec ["AUR_Enable_Rappelling_Animation", 0];
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Current_Weapon_Type_Selected = {
		params ["_player"];
		if (currentWeapon _player == handgunWeapon _player) exitWith {"HANDGUN"};
		if (currentWeapon _player == primaryWeapon _player) exitWith {"PRIMARY"};
		if (currentWeapon _player == secondaryWeapon _player) exitWith {"SECONDARY"};
		"OTHER";
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Enable_Rappelling_Animation = {
		params ["_player", ["_globalExec", false]];
		if (local _player && _globalExec) exitWith {};
		if (local _player && !_globalExec) then {
			[[_player], "AUR_Enable_Rappelling_Animation_Global"] call AUR_RemoteExecServer;
		};
		// if (_player != player) then {
			// _player enableSimulation false;
		// };
		if (call AUR_Has_Addon_Animations_Installed) then {		
			if ([_player] call AUR_Current_Weapon_Type_Selected == "HANDGUN") then {
				if (local _player) then {
					_player switchMove "AUR_01_Idle_Pistol";
					_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_Pistol_No_Actions", true];
				} else {
					_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_Pistol_No_Actions"];			
				};
			} else {
				if (local _player) then {
					_player switchMove "AUR_01_Idle";
					_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_No_Actions", true];
				} else {
					_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_No_Actions"];
				};
			};
			if !(local _player) then {		// Temp work around to avoid seeing other player as standing		
				_player switchMove "AUR_01_Idle_No_Actions";
				sleep 1;
				_player switchMove "AUR_01_Idle_No_Actions";
				sleep 1;
				_player switchMove "AUR_01_Idle_No_Actions";
				sleep 1;
				_player switchMove "AUR_01_Idle_No_Actions";
			};
		} else {
			if (local _player) then {
				_player switchMove "HubSittingChairC_idle1";
				_player setVariable ["AUR_Animation_Move", "HubSittingChairC_idle1", true];
			} else {
				_player setVariable ["AUR_Animation_Move", "HubSittingChairC_idle1"];		
			};
		};
		// diag_log formatText ["%1%2%3%4%5%6%7", time, "s  (AUR_Enable_Rappelling_Animation) local _player: ", local _player];
		private _animationEventHandler = -1;
		if (local _player) then {
			_animationEventHandler = _player addEventHandler ["AnimChanged", {
				params ["_player", "_animation"];
				if (call AUR_Has_Addon_Animations_Installed) then {
					if ((toLower _animation) find "aur_" < 0) then {
						if ([_player] call AUR_Current_Weapon_Type_Selected == "HANDGUN") then {
							_player switchMove "AUR_01_Aim_Pistol";
							_player setVariable ["AUR_Animation_Move", "AUR_01_Aim_Pistol_No_Actions", true];
						} else {
							_player switchMove "AUR_01_Aim";
							_player setVariable ["AUR_Animation_Move", "AUR_01_Aim_No_Actions", true];
						};
					} else {
						if (toLower _animation == "aur_01_aim") then {
							_player setVariable ["AUR_Animation_Move", "AUR_01_Aim_No_Actions", true];
						};
						if (toLower _animation == "aur_01_idle") then {
							_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_No_Actions", true];
						};
						if (toLower _animation == "aur_01_aim_pistol") then {
							_player setVariable ["AUR_Animation_Move", "AUR_01_Aim_Pistol_No_Actions", true];
						};
						if (toLower _animation == "aur_01_idle_pistol") then {
							_player setVariable ["AUR_Animation_Move", "AUR_01_Idle_Pistol_No_Actions", true];
						};
					};
				} else {
					_player switchMove "HubSittingChairC_idle1";
					_player setVariable ["AUR_Animation_Move", "HubSittingChairC_idle1", true];
				};
			}];
		};
		
		if (!local _player) then {
			[_player] spawn {
				params ["_player"];
				while {_player getVariable ["AUR_Is_Rappelling", false]} do {
					private _currentState = toLower animationState _player;
					private _newState = toLower (_player getVariable ["AUR_Animation_Move", ""]);
					if !(call AUR_Has_Addon_Animations_Installed) then {
						_newState = "HubSittingChairC_idle1";
					};
					if (_currentState != _newState) then {
						_player switchMove _newState;
						_player switchGesture "";
						sleep 1;
						_player switchMove _newState;
						_player switchGesture "";
					};
					sleep 0.1;
				};			
			};
		};
		
		waitUntil {!(_player getVariable ["AUR_Is_Rappelling", false])};
		
		if (_animationEventHandler != -1) then {
			_player removeEventHandler ["AnimChanged", _animationEventHandler];
		};
		
		_player switchMove "";	
		_player enableSimulation true;		
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Hint = {
		params ["_msg", ["_isSuccess", true]];
		if (!isNil "ExileClient_gui_notification_event_addNotification") then {
			if (_isSuccess) then {
				["Success", [_msg]] call ExileClient_gui_notification_event_addNotification; 
			} else {
				["Whoops", [_msg]] call ExileClient_gui_notification_event_addNotification; 
			};
		} else {
			hint _msg;
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Hide_Object_Global = {
		params ["_obj"];
		if (_obj isKindOf "Land_Can_V2_F" || _obj isKindOf "B_static_AA_F" || _obj isKindOf "ACE_O_T_SpottingScope") then {
			hideObjectGlobal _obj;
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Add_Player_Actions = {
		params ["_player"];
		[_player] call AUR_Change_Player_Action;
		_player addAction [format[localize "STR_AUR_RAPPEL_AI"], { 
			[player] call AUR_Rappel_AI_Units_Action;
		}, nil, 0, false, true, "", "[player] call AUR_Rappel_AI_Units_Action_Check"];
		_player addAction [format[localize "STR_AUR_CLIMB_TO"], { 
			[player] call AUR_Rappel_Climb_To_Top_Action;
		}, nil, 0, false, true, "", "[player] call AUR_Rappel_Climb_To_Top_Action_Check"];
		_player addAction [format[localize "STR_AUR_RAPPEL_DETACH"], { 
			[player] call AUR_Rappel_Detach_Action;
		}, nil, 0, false, true, "", "[player] call AUR_Rappel_Detach_Action_Check"];
		_player addEventHandler ["Respawn", {
			player setVariable ["AUR_Actions_Loaded", false];
		}];	
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_Change_Player_Action = {
		params ["_player"];
		private ["_actionID"];
		if (!isNil {_player getVariable "AUR_Rappel_Action_actionID"}) then {
			_actionID = _player getVariable "AUR_Rappel_Action_actionID";
			_player removeAction _actionID;
		};
		if (AUR_ADVANCED_RAPPELING_NEW_ACTION) then {
			_actionID = [_player,
			format[localize "STR_AUR_RAPPEL_SELF"],
			"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
			"\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
			"[player] call AUR_Rappel_Action_Check",
			"[player] call AUR_Rappel_Action_Check",
			{},
			{},
			{[player, vehicle player] spawn AUR_Rappel_Action;},
			{},
			nil,
			round AUR_ADVANCED_RAPPELING_NEW_ACTION_TIME,
			0,
			false,
			false] call BIS_fnc_holdActionAdd;
		} else {
			_actionID = _player addAction [format[localize "STR_AUR_RAPPEL_SELF"], { 
				[player, vehicle player] call AUR_Rappel_Action;
			}, nil, 0, false, true, "", "[player] call AUR_Rappel_Action_Check"];
		};
		_player setVariable ["AUR_Rappel_Action_actionID", _actionID, false];
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	if (!isDedicated) then {
		[] spawn {
			while {true} do {
				if (!isNull player && isPlayer player) then {
					if !(player getVariable ["AUR_Actions_Loaded", false]) then {
						[player] call AUR_Add_Player_Actions;
						player setVariable ["AUR_Actions_Loaded", true];
					};
				};
				sleep 5;
			};
		};
	};

	AUR_RemoteExec = {
		params ["_params", "_functionName", "_target", ["_isCall", false]];
		if (!isNil "ExileClient_system_network_send") then {
			["AdvancedUrbanRappellingRemoteExecClient", [_params, _functionName, _target, _isCall]] call ExileClient_system_network_send;
		} else {
			if (_isCall) then {
				_params remoteExecCall [_functionName, _target];
			} else {
				_params remoteExec [_functionName, _target];
			};
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	AUR_RemoteExecServer = {
		params ["_params", "_functionName", ["_isCall", false]];
		if (!isNil "ExileClient_system_network_send") then {
			["AdvancedUrbanRappellingRemoteExecServer", [_params, _functionName, _isCall]] call ExileClient_system_network_send;
		} else {
			if (_isCall) then {
				_params remoteExecCall [_functionName, 2];
			} else {
				_params remoteExec [_functionName, 2];
			};
		};
	};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	if (isServer) then {	// what is this bullshit? if if wasnt server, this section would never be executed? See line 13? // Adds support for exile network calls (Only used when running exile) 
		AUR_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS = ["AUR_Enable_Rappelling_Animation_Global", "AUR_Hide_Object_Global", "AUR_Play_Rappelling_Sounds_Global"];
		ExileServer_AdvancedUrbanRappelling_network_AdvancedUrbanRappellingRemoteExecServer = {
			params ["_sessionId", "_messageParameters", ["_isCall", false]];
			_messageParameters params ["_params", "_functionName"];
			if (_functionName in AUR_SUPPORTED_REMOTEEXECSERVER_FUNCTIONS) then {
				if (_isCall) then {
					_params call (missionNamespace getVariable [_functionName, {}]);
				} else {
					_params spawn (missionNamespace getVariable [_functionName, {}]);
				};
			};
		};
		
		AUR_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS = ["AUR_Hint"];
		ExileServer_AdvancedUrbanRappelling_network_AdvancedUrbanRappellingRemoteExecClient = {
			params ["_sessionId", "_messageParameters"];
			_messageParameters params ["_params", "_functionName", "_target", ["_isCall", false]];
			if (_functionName in AUR_SUPPORTED_REMOTEEXECCLIENT_FUNCTIONS) then {
				if (_isCall) then {
					_params remoteExecCall [_functionName, _target];
				} else {
					_params remoteExec [_functionName, _target];
				};
			};
		};	
	};

	diag_log "Advanced Urban Rappelling Loaded";
};	// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

publicVariable "AUR_Advanced_Urban_Rappelling_Install";
[] call AUR_Advanced_Urban_Rappelling_Install;
remoteExecCall ["AUR_Advanced_Urban_Rappelling_Install", -2, true];	// Install Advanced Urban Rappelling on all clients (plus JIP)