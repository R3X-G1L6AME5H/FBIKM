tool
extends Position3D


"""
	FBIKM - Chain
   		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)

	This node HAS to be a child of a FBIKM node to work. This node itself is the target.

	Name "Chain" comes from the fact that it solves for a set of connected bones; they solve a part of a skeleton;
    you can imagine your arm as a chain of two bones: elbow, and forearm. It begins its solving process from the tip
	bone, and continues up the tree structure until it reaches the user specified root bone, or a bone without a parent.

	Because FBIKM allows for multi chain solving, each chain has its individual target, and the pull force. When two
	chains pull at one another, priority is decided by by this value.
"""


const FBIKM_NODE_ID = 1  # THIS NODE'S INDENTIFIER

var tip_bone_id : String = "-1"
var root_bone_id : String = "-1"
export (float, 0.005, 1.0) var pull_strength = 1

## BOILERPLATE FOR DROPDOWN MENUS ##
var _bone_names = "VOID:-1"

func _get(property : String):
	match property:
		"tip_bone_id" :
			return tip_bone_id
		"root_bone_id" :
			return root_bone_id 
		_ :
			return null

func _set( property : String, value) -> bool:
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

## INIT ###########################################################################
func _ready():
	if Engine.editor_hint:
		if get_parent().get("FBIKM_NODE_ID") == 0:  ## This is KinematicsManager's ID
			## This way the parent notifies this node whenever there is a change in the bone structure
			get_parent().connect("bone_names_obtained", self, "_update_parameters")

## Update the dropdown menu
func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()

## Return current position (used by the solver)
func get_target() -> Transform:
	return self.transform
