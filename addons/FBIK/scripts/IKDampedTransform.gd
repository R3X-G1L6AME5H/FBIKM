tool
extends Node
const FBIKM_NODE_ID = 8  # THIS NODE'S INDENTIFIER


var bone_id : String = "-1"
var _bone_names = "VOID:-1"

export (float, 0.005, 1.0) var stiffness = 0.1 # setget _set_stiffness
export (float, 0.005, 1.0) var damping = 0.75 # setget _set_damping
export (float) var mass = 0.9 # setget _set_mass
export (float) var gravity = 0

export (float, 0.005, 2.0) var stiffness_passed_down = 1 # setget _set_stiffness_passed_down
export (float, 0.005, 2.0) var damping_passed_down = 1 # setget _set_damping_passed_down
export (float, 0.005, 2.0) var mass_passed_down = 1 # setget _set_mass_passed_down

###############################################################################
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
"""
func _set_stiffness(val) -> void:
	Stiffness = val
	update_stiffness_array()
func _set_stiffness_passed_down(val) -> void:
	StiffnessPassedDown = val
	update_stiffness_array()
func _set_mass(val) -> void:
	Mass = val
	update_mass_array()
func _set_mass_passed_down(val) -> void:
	MassPassedDown = val
	update_mass_array()
func _set_damping(val) -> void:
	Damping = val
	update_damping_array()
func _set_damping_passed_down(val) -> void:
	DampingPassedDown = val
	update_damping_array()
"""
###############################################################################
func _ready():
	if Engine.editor_hint:
		if get_parent().get("FBIKM_NODE_ID") == 0:  ## This is KinematicsManager's ID
			get_parent().connect("bone_names_obtained", self, "_update_parameters")


func _update_parameters( bone_names : String ) -> void:
	self._bone_names = bone_names
	property_list_changed_notify()

