tool
extends Position3D
const FBKIM_NODE_ID = 2  # THIS NODE'S INDENTIFIER


enum SIDE {FORWARD, BACKWARD, LEFT, RIGHT}

var tip_bone_id : String = "-1"
var root_bone_id : String = "-1"
export (SIDE) var turn_to = SIDE.FORWARD
var _bone_names = "VOID:-1"

func _get( property : String ):
	match property:
		"tip_bone_id" :
			return tip_bone_id
		"root_bone_id" :
			return root_bone_id 
		_ :
			return null
func _set( property : String, value ) -> bool:
	match property:
		"tip_bone_id" :
			tip_bone_id = str(value)
			return true
		"root_bone_id" :
			root_bone_id = str(value)
			return true
		_ :
			return false
func _get_property_list():
	var result = []
	result.push_back({
			"name": "tip_bone_id",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _bone_names
	})
	result.push_back({
			"name": "root_bone_id",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_DEFAULT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _bone_names
	})
	return result

###############################################################################
func _ready():
	if Engine.editor_hint:
		if get_parent().get("FBKIM_NODE_ID") == 0:  ## This is KinematicsManager's ID
			get_parent().connect("bone_names_obtained", self, "_update_parameters")

func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()

func get_target() -> Transform:
	return self.transform
