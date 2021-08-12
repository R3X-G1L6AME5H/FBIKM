tool
extends Node

var bone_1 : String = "-1"
var bone_2 : String = "-1"
var bone_3 : String = "-1"
var bone_target : String = "-1"

var length_1 : float = 0
var length_2 : float = 0
var length_3 : float = 0
var _bone_names = "VOID:-1"

func _get( property : String ):
	match property:
		"bone_1" :
			return bone_1
		"bone_2" :
			return bone_2 
		"bone_3" :
			return bone_3 
		"bone_target" :
			return bone_target 
		_ :
			return null
func _set( property : String, value ) -> bool:
	match property:
		"bone_1" :
			bone_1 = str(value)
			return true
		"bone_2" :
			bone_2 = str(value)
			return true
		"bone_3" :
			bone_3 = str(value)
			return true
		"bone_target" :
			bone_target = str(value)
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
		"name": "bone_2",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "bone_3",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	result.push_back({
		"name": "bone_target",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _bone_names
	})
	return result

###############################################################################
func _ready():
	if Engine.editor_hint:
		var IKManager = load("res://P4/IKManager.gd")
		if get_parent() is IKManager:
			var _trash = get_parent().connect("bone_names_obtained", self, "_update_parameters")
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()
