tool
extends Node
const FBIKM_NODE_ID = 7  # THIS NODE'S INDENTIFIER

"""
        FBIKM - Solidifier
                by Nemo Czanderlitch/Nino Čandrlić
                        @R3X-G1L       (godot assets store)
                        R3X-G1L6AME5H  (github)
		Stiffens all the bones that come after it.
"""


var bone_id : String = "-1"


## BOILERPLATE FOR DROPDOWN MENU
var _bone_names = "VOID:-1"
func _get( property : String ):
	match property:
		"bone_id" :
			return bone_id
		_ :
			return null
func _set( property : String, value ) -> bool:
	match property:
		"bone_id" :
			bone_id = str(value)
			return true
		_ :
			return false
func _get_property_list():
	var result = []
	result.push_back({
			"name": "bone_id",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _bone_names
	})
	return result
###############################################################################

func _ready():
	if Engine.editor_hint:
		if get_parent().get("FBIKM_NODE_ID") == 0:  ## This is KinematicsManager's ID
			get_parent().connect("bone_names_obtained", self, "_update_parameters") ## recieve a update on available bones


## update the dropdown menu
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()
