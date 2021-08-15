extends Reference

enum MODIFIER {
	NONE = 0,
	BIND = 1,
	FORK_BIND = 2,
	CAGE_BIND = 4,
	# BIND_SLAVE,
	SOLID = 8,
	DAMPED_TRANSFORM = 16,
	LOOK_AT = 32
	#BALL_AND_SOCKET = 32,
	#HINGE = 64,
	#TWIST = 128
	
}

var bones := Dictionary()
var skel : Skeleton
var roots := PoolStringArray([])

### INIT
func _init( skeleton : Skeleton, build_with_initial_transform : bool ):
	skel = skeleton
	for id in range(skeleton.get_bone_count()):
		add_bone( str(id), 
					str(skeleton.get_bone_parent(id)),
					skeleton.get_bone_global_pose(id),
					build_with_initial_transform )
	
	## Put all bones whose parent is -1 in a solving queue 
	var bone_queue := PoolStringArray([])
	for root in roots:
		bone_queue.append_array( PoolStringArray(self.get_bone_children(root)))
	
	var current_bone = bone_queue[0]
	bone_queue.remove(0)
	
	while true: 
		var num_of_children = self.get_bone_children_count(current_bone)
		if num_of_children == 0:
			## Leaf node
			bones[current_bone].start_direction = self.get_bone_position(current_bone) - self.get_bone_position(self.get_bone_parent(current_bone))
			
			if bone_queue.size() == 0:
				break
			
			## Pop the first item in queue
			current_bone = bone_queue[0]
			bone_queue.remove(0)
		
		else:
			## Inside Chain
			for child_bone in self.get_bone_children(current_bone):
				## Push branch on the queue so it can be solved later
				bone_queue.push_back(child_bone)
			
			bones[current_bone].start_direction = self.get_bone_position(current_bone) - self.get_bone_position(self.get_bone_parent(current_bone))
			## Pop the first item in queue
			current_bone = bone_queue[0]
			bone_queue.remove(0)
func add_bone( bone_id : String, parent_id : String, transform : Transform, build_with_initial_transform : bool) -> void:
	var direction := Vector3.ZERO
	var preexisting_children := []
	
	## If a parent exists, imediately solve the distance from it
	## to child, as well as link them
	if bones.has(parent_id):
		direction =  transform.origin - bones[ parent_id ].position
		bones[ parent_id ].children.push_back( bone_id )
	
	## Check if this bone is a parent to any of the existing nodes
	for bone in bones.keys():
		if bones[ bone ].parent == bone_id:
			preexisting_children.push_back( bone )
			bones[ bone ].start_direction = bones[bone].position - transform.origin
			bones[ bone ].length = bones[ bone ].start_direction.length()
	
	## Add the bone
	bones[ bone_id ] = {
		### Tree data
		parent                 = parent_id, 
		children               = preexisting_children,
		### Solve position data
		position               = transform.origin,
		length                 = direction.length(),
		length_multiplier      = 1.0,
		### Solve rotation data
		rotation               = transform.basis.get_rotation_quat(),
		start_rotation         = transform.basis.get_rotation_quat(),
		start_direction        = direction.normalized(),
		### Solve Subbase data
		weighted_vector_sum    = Vector3.ZERO,
		weight_sum             = 0.0,
		### Constraint data
		modifier_flags         = MODIFIER.NONE,
		
		### Added automatically by neccessity
		# modifier_master        = ""             // used to find the base rotation on solidifier & damped transform
		# velocity               = Vector3.ZERO   // used by damped transform
		# damped_transform       = [ stiffness, mass, damping, gravity ] // static variables which control the damped transform
	}
	
	## Add initial bone position for runtime purpuses
	if build_with_initial_transform:
		bones[ bone_id ].init_tr = transform
	
	## Check if bone is the root
	if parent_id == "-1":
		roots.push_back(bone_id)
		bones[ str(bone_id) ].initial_position = transform.origin
func set_bone_modifier(bone_id : String, modifier : int, node = null) -> void:
	if modifier == MODIFIER.LOOK_AT:
		bones[bone_id].modifier_flags |= MODIFIER.LOOK_AT
	
	elif modifier == MODIFIER.BIND:
		if node != null:
			bones[node.bones[0]].modifier_flags |= MODIFIER.BIND
			#bones[node.bones[1]].modifier_flags |= MODIFIER.BIND_SLAVE
			#bones[node.bones[2]].modifier_flags |= MODIFIER.BIND_SLAVE
		
			## Later make the bind_idss appendable for interlinking binds
			if not bones[node.bones[0]].has("bind_ids"):
				bones[node.bones[0]].bind_ids = []
			#if not bones[node.bones[1]].has("bind_ids"):
			#	bones[node.bones[1]].bind_ids = []
			#if not bones[node.bones[2]].has("bind_ids"):
			#	bones[node.bones[2]].bind_ids = []
			
			bones[node.bones[0]].bind_ids.push_back(node.bind_id)
			#bones[node.bones[1]].bind_ids.push_back(node.bind_id)
			#bones[node.bones[2]].bind_ids.push_back(node.bind_id)
		
	elif modifier == MODIFIER.FORK_BIND:
		if node != null:
			bones[node.bone_1].modifier_flags |= MODIFIER.FORK_BIND
			#bones[node.bone_2].modifier_flags |= MODIFIER.BIND_SLAVE
			#bones[node.bone_3].modifier_flags |= MODIFIER.BIND_SLAVE
			#bones[node.bone_target].modifier_flags |= MODIFIER.BIND_SLAVE
			
			if not bones[node.bone_1].has("fork_bind_ids"):
				bones[node.bone_1].fork_bind_ids = []
			#if not bones[node.bone_2].has("fork_bind_ids"):
			#	bones[node.bone_2].fork_bind_ids = []
			#if not bones[node.bone_3].has("fork_bind_ids"):
			#	bones[node.bone_3].fork_bind_ids = []
			#if not bones[node.bone_target].has("fork_bind_ids"):
			#	bones[node.bone_target].fork_bind_ids = []
			
			bones[node.bone_1].fork_bind_ids.push_back(node.bind_id)
			#bones[node.bone_2].fork_bind_ids.push_back(node.bind_id)
			#bones[node.bone_3].fork_bind_ids.push_back(node.bind_id)
			#bones[node.bone_target].fork_bind_ids.push_back(node.bind_id)
	
	elif modifier == MODIFIER.CAGE_BIND:
		if node != null:
			bones[node.backbone_1].modifier_flags |= MODIFIER.CAGE_BIND
			
			bones[node.backbone_1].cage_bind_id = node.bind_id
	
	else:
		var bone_queue : PoolStringArray = []
		var current_bone = bone_id
		while true:
			if current_bone == "-1":
				break
			else:
				for child in bones[current_bone].children:
					bone_queue.push_back(child)
			
			bones[current_bone].modifier_flags |= modifier
			bones[current_bone].modifier_master = bone_id
			if modifier & MODIFIER.DAMPED_TRANSFORM and node != null:
				bones[current_bone].velocity = Vector3.ZERO
				update_bone_damped_transform(current_bone, node)
			
			if bones[current_bone].children.size() != 0:
				current_bone = bone_queue[0]
				bone_queue.remove(0)
			else:
				current_bone = "-1"

### DESTRUCTOR
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# destructor logic
		skel.clear_bones_global_pose_override()
		bones.clear()

### WRITE VIRTUAL SKELETON TO REAL SKELETON
func bake() -> void:
	for bone_id in bones.keys():
			var new_pose = Transform()
			 ## Works on serial joints but a modification is needed for subbases
			new_pose.origin = bones[bone_id].position
			new_pose.basis  = Basis(bones[bone_id].rotation)
			skel.set_bone_global_pose_override( int(bone_id), new_pose, 1.0, true )
func revert() -> void:
	skel.clear_bones_global_pose_override()

### GETTERS #####################################################################################################
## Navigating stuff
func get_bone_parent( bone_id : String ) -> String:
	if bones.has(bone_id):
		return bones[bone_id].parent
	else:
		return "-1"
func get_bone_children_count( bone_id : String ) -> int:
	return bones[bone_id].children.size()
func get_bone_children( bone_id : String ) -> Array:
	return bones[bone_id].children
## Solving stuff
func get_bone_position( bone_id : String ) -> Vector3:
	return bones[bone_id].position
func get_bone_rotation( bone_id : String ) -> Quat:
	return bones[bone_id].rotation
func get_bone_length( bone_id : String ) -> float:
	return bones[bone_id].length * bones[bone_id].length_multiplier
func get_bone_weight( bone_id : String ) -> float:
	return bones[bone_id].weight_sum
func get_bone_start_direction( bone_id : String ) -> Vector3:
	return bones[bone_id].start_direction
func get_bone_start_rotation( bone_id : String ) -> Quat:
	return bones[bone_id].start_rotation
func has_bone( bone_id : String ) -> bool:
	return bones.has(bone_id)
## Modifier stuff
func get_bone_modifiers( bone_id : String ) -> int:
	return bones[bone_id].modifier_flags
func get_bone_modifier_master( bone_id : String ) -> String:
	return bones[bone_id].modifier_master
func get_bone_damped_transform( bone_id : String ) -> Array:
	return bones[bone_id].damped_transform
func get_bone_bind_ids( bone_id : String ) -> PoolIntArray:
	return bones[bone_id].bind_ids
func get_bone_fork_bind_ids( bone_id : String ) -> PoolIntArray:
	return bones[bone_id].fork_bind_ids
func get_bone_cage_bind_id( bone_id : String ) -> int:
	return bones[bone_id].cage_bind_id
### SETTERS #####################################################################################################
func set_bone_position( bone_id : String, position : Vector3 ) -> void:
	bones[bone_id].position = position
func set_biassed_bone_position( bone_id : String, position : Vector3, weight : float ):
	bones[bone_id].weight_sum += weight
	bones[bone_id].weighted_vector_sum += position * weight
	bones[bone_id].position = bones[bone_id].weighted_vector_sum / bones[bone_id].weight_sum
func set_bone_rotation( bone_id : String, rotation : Quat ) -> void:
	bones[bone_id].rotation = rotation
## Modifier Stuff
func set_bone_length_multiplier(bone_id : String, multiplier : float) -> void:
	bones[bone_id].length_multiplier = multiplier
func add_velocity_to_bone(bone_id : String, velocity : Vector3) -> Vector3:
	bones[bone_id].velocity += velocity
	return bones[bone_id].velocity
func update_bone_damped_transform( bone_id : String, node ) -> void:
	bones[bone_id].damped_transform = []
	
	if bones[bones[bone_id].parent].has("damped_transform"):
		bones[bone_id].damped_transform.push_back( clamp(bones[bones[bone_id].parent].damped_transform[0] * node.stiffness_passed_down, 0.0, 1.0))
		bones[bone_id].damped_transform.push_back( clamp(bones[bones[bone_id].parent].damped_transform[1] * node.damping_passed_down, 0.0, 1.0))
		bones[bone_id].damped_transform.push_back( clamp(bones[bones[bone_id].parent].damped_transform[2] * node.mass_passed_down, 0.0, 1.0))
	
	else:
		bones[bone_id].damped_transform.push_back(node.stiffness)
		bones[bone_id].damped_transform.push_back(node.damping)
		bones[bone_id].damped_transform.push_back(node.mass)
	bones[bone_id].damped_transform.push_back(node.gravity)
	
	"""
	if bones[bones[bone_id].parent].has("damped_transform"):
		bones[bone_id].damped_transform.push_back(bones[bones[bone_id].parent].damped_transform[0] * node.StiffnessPassedDown)
		bones[bone_id].damped_transform.push_back(bones[bones[bone_id].parent].damped_transform[1] * node.DampingPassedDown)
		bones[bone_id].damped_transform.push_back(bones[bones[bone_id].parent].damped_transform[2] * node.MassPassedDown)
	else:
		bones[bone_id].damped_transform.push_back(node.Stiffness)
		bones[bone_id].damped_transform.push_back(node.Damping)
		bones[bone_id].damped_transform.push_back(node.Mass)
	bones[bone_id].damped_transform.push_back(node.Gravity)
	"""

### CLEAN UP ####################################################################################################
func wipe_weights() -> void:
	for bone in bones.keys():
		bones[bone].weight_sum = 0
		bones[bone].weighted_vector_sum = Vector3.ZERO
func wipe_modifiers() -> void:
	for bone in bones.values():
		if bone.modifier_flags == MODIFIER.NONE:
			continue
		if bone.modifier_flags & MODIFIER.BIND:
			bone.erase("bind_ids")
		if bone.modifier_flags & MODIFIER.FORK_BIND:
			bone.erase("fork_bone_id")
		if bone.modifier_flags & MODIFIER.SOLID:
			bone.erase("modifier_master")
		if bone.modifier_flags & MODIFIER.DAMPED_TRANSFORM:
			bone.erase("modifier_master")
			bone.erase("velocity")
			bone.erase("damped_transform")
		bone.modifier_flags = MODIFIER.NONE
### DEBUG ######################################################################################################
func cshow( properties : String = "parent,children", N : int = -1 ):
	var props : PoolStringArray = properties.split(",")
	for i in bones.keys():
		if N == 0:
			break
		prints("##", skel.get_bone_name(int(i)).to_upper(), "####################################")
		for prop in props:
			if bones[i].has(prop):
				print( "\t\t\t" + prop + " - ", bones[i][prop])
		N -= 1
