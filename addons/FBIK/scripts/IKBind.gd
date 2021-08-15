tool
extends Node
const FBIKM_NODE_ID = 4  # THIS NODE'S INDENTIFIER



var bind_id : int

var bone_1 : String = "-1"
var bone_1_correction_bone : String = "-1"
var bone_2 : String = "-1"
var bone_2_correction_bone : String = "-1"
var bone_3 : String = "-1"
var bone_3_correction_bone : String = "-1"

export (float, 0.05, 2.0) var length_23_multiplier = 1.0
## EDITOR VARIABLES ###################################################
export var lock_correction_bone_2 := false setget _lock_correction_2
export var lock_correction_bone_3 := false setget _lock_correction_3

var length_12 : float = 0
var length_23 : float = 0
var length_31 : float = 0
var correction_length_1 : float = 0
var correction_length_2 : float = 0
var correction_length_3 : float = 0


var _bone_names = "VOID:-1"
func _lock_correction_2(value):
	lock_correction_bone_2 = value
	property_list_changed_notify()

func _lock_correction_3(value):
	lock_correction_bone_3 = value
	property_list_changed_notify()


func _get( property : String ):
	match property:
		"bone_1" :
			return bone_1
		"bone_1_correction_bone" :
			return bone_1_correction_bone
		"bone_2" :
			return bone_2 
		"bone_2_correction_bone" :
			return bone_2_correction_bone 
		"bone_3" :
			return bone_3 
		"bone_3_correction_bone" :
			return bone_3_correction_bone 
		_ :
			return null
func _set( property : String, value ) -> bool:
	match property:
		"bone_1" :
			bone_1 = str(value)
			return true
		"bone_1_correction_bone" :
			bone_1_correction_bone = str(value)
			return true
		"bone_2" :
			bone_2 = str(value)
			return true
		"bone_2_correction_bone" :
			bone_2_correction_bone = str(value)
			return true
		"bone_3" :
			bone_3 = str(value)
			return true
		"bone_3_correction_bone" :
			bone_3_correction_bone = str(value)
			return true
		_ :
			return false
func _get_property_list():
	var result = []
	result.push_back({
			"name": "bone_1",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _bone_names
	})
	result.push_back({
		"name": "bone_1_correction_bone",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
			"name": "bone_2",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _bone_names
	})
	result.push_back({
		"name": "bone_2_correction_bone",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	if lock_correction_bone_2:
		result[ result.size() - 1]["hint_string"] = "LOCKED:-1"
		
	result.push_back({
		"name": "bone_3",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "bone_3_correction_bone",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	if lock_correction_bone_3:
		result[ result.size() - 1]["hint_string"] = "LOCKED:-1"
		
	return result

###############################################################################
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()
