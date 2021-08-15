tool
extends Node
const FBIKM_NODE_ID = 9  # THIS NODE'S INDENTIFIER

var backbone_1 : String = "-1"
var backbone_2 : String = "-1"
var backbone_2_correction : String = "-1"
var target_bone_1 : String = "-1"
var target_bone_1_correction : String = "-1"
var target_bone_2 : String = "-1"
var target_bone_2_correction : String = "-1"

var bind_id : int

var b1b2_length : float = 0
var b1t1_length : float = 0
var b1t2_length : float = 0
var b2t1_length : float = 0
var b2t2_length : float = 0
var t1t2_length : float = 0

var b2_correction_length : float = 0
var t1_correction_length : float = 0
var t2_correction_length : float = 0

var _bone_names = "VOID:-1"

func _get( property : String ):
	match property:
		"backbone_1" :
			return backbone_1
		"backbone_2" :
			return backbone_2 
		"target_bone_1" :
			return target_bone_1 
		"target_bone_2" :
			return target_bone_2 
		"backbone_2_correction" :
			return backbone_2_correction
		"target_bone_1_correction" :
			return target_bone_1_correction
		"target_bone_2_correction" :
			return target_bone_2_correction 
		_ :
			return null
func _set( property : String, value ) -> bool:
	match property:
		"backbone_1" :
			backbone_1 = str(value)
			return true
		"backbone_2" :
			backbone_2 = str(value)
			return true
		"target_bone_1" :
			target_bone_1 = str(value)
			return true
		"target_bone_2" :
			target_bone_2 = str(value)
			return true
		"backbone_2_correction" :
			backbone_2_correction = str(value)
			return true
		"target_bone_1_correction" :
			target_bone_1_correction = str(value)
			return true
		"target_bone_2_correction" :
			target_bone_2_correction = str(value)
			return true
		_ :
			return false
func _get_property_list():
	var result = []
	result.push_back({
		"name": "backbone_1",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "backbone_2",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "backbone_2_correction",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "target_bone_1",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "target_bone_1_correction",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "target_bone_2",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "target_bone_2_correction",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	return result

###############################################################################
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()
