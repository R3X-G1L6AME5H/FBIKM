tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here.
	# Add the new type with a name, a parent type, a script and an icon.
	add_custom_type("KinematicsManager", "Node", preload("./scripts/IKManager.gd"), preload("icons/Manager.svg"))
	add_custom_type("KinematicsChain", "Position3D", preload("./scripts/IKChain.gd"), preload("icons/Chain.svg"))
	add_custom_type("KinematicsLookAt", "Position3D", preload("./scripts/IKLookAt.gd"), preload("icons/LookAt.svg"))
	add_custom_type("KinematicsPole", "Position3D", preload("./scripts/IKPole.gd"), preload("icons/Pole.svg"))
	
	add_custom_type("KinematicsExaggerator", "Node", preload("./scripts/IKChain.gd"), preload("icons/Exaggerator.svg"))
	add_custom_type("KinematicsSpringyBones", "Node", preload("./scripts/IKDampedTransform.gd"), preload("icons/SpringyBones.svg"))
	# add_custom_type("KinematicsSolidifier", "Node", load("scripts/IKSolidifier.gd"), preload("icons/SpringyBones.svg"))
	
	add_custom_type("KinematicsBind", "Node", preload("./scripts/IKBind.gd"), preload("icons/Bind.svg"))
	add_custom_type("KinematicsFork", "Node", preload("./scripts/IKForkBind.gd"), preload("icons/ForkBind.svg"))
	
	add_custom_type("Spring", "Position3D", preload("./scripts/Spring.gd"), null)
	# scripts/IKSolidifier.gd

func _exit_tree():
	# Clean-up of the plugin goes here.
	# Always remember to remove it from the engine when deactivated.
	remove_custom_type("KinematicsManager")
	remove_custom_type("KinematicsChain")
	remove_custom_type("KinematicsLookAt")
	remove_custom_type("KinematicsPole")
	remove_custom_type("KinematicsExaggerator")
	remove_custom_type("KinematicsSpringyBones")
	remove_custom_type("KinematicsBind")
	remove_custom_type("KinematicsFork")
	remove_custom_type("Spring")
