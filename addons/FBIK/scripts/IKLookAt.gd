tool
extends Position3D

"""
        FBIKM - Look At
                by Nemo Czanderlitch/Nino Čandrlić
                        @R3X-G1L       (godot assets store)
                        R3X-G1L6AME5H  (github)
        Makes one of the specified bone's sides face this node. Useful in having the head look at something.

"""

const FBIKM_NODE_ID = 3  # THIS NODE'S INDENTIFIER

enum SIDE {UP, DOWN, LEFT, RIGHT, FORWARD, BACK}
var bone_id : String
export (SIDE) var look_from_side = SIDE.UP ## A side of the bone which will turn towards the target


## BOILDERPLATE FOR DROPDOWN MENU ##
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

## updates the dropdown menu
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()

## Returns its transformation (used by IK Manager)
func get_target() -> Transform:
	return self.transform
