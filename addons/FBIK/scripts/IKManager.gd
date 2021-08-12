tool
extends Node

## CONSTANTS ###############################################################################################
const VirtualSkeleton = preload("VirtualSkeleton.gd")
const IKChain = preload("IKChain.gd")
const IKPole = preload("IKPole.gd")
const IKBind = preload("IKBind.gd")
const IKForkBind = preload("IKForkBind.gd")
const IKLookAt = preload("IKLookAt.gd")
const IKExaggerator = preload("IKExaggerator.gd")
const IKSolidifier = preload("IKSolidifier.gd")
const IKDampedTransform = preload("IKDampedTransform.gd")
const VOID_ID = "-1" ### Add a move dynamic way to do this

var _bone_names_4_children := "VOID:-1"
signal bone_names_obtained(bone_names)

## PARAMETERS ##############################################################################################
export (bool)     var enabled  = false setget _tick_enabled
export (NodePath) var skeleton = null setget _set_skeleton
export (int)      var max_iterations = 5
export (float)    var minimal_distance = 0.01
export (bool)     var DEBUG_dump_bones = false
export (String)   var DEBUG_bone_property = ""
export (int)      var DEBUG_entry_count = -1
#### RUNTIME ENVIRONMENT
func _set_skeleton( path_2_skel : NodePath ):
	if Engine.editor_hint:
		## This is where the editor runtime is implemented
		var _temp = get_node_or_null(path_2_skel)
		if _temp is Skeleton:
			skeleton = path_2_skel
			
			_bone_names_4_children = "VOID:-1,"
			var n : int = _temp.get_bone_count()
			for i in range(n):
				_bone_names_4_children += _temp.get_bone_name(i)+":"+str(i)+","
			_bone_names_4_children = _bone_names_4_children.rstrip(",")
			emit_signal("bone_names_obtained", _bone_names_4_children)
			#print(_bone_names_4_children)
			_build_virtual_skeleton( true )
			
			for c in get_children():
				connect_signals( c )
			emit_signal("bone_names_obtained", _bone_names_4_children)
			_evaluate_drivers()
		else:
			skeleton = null
			_wipe_virtual_skeleton()
	else:
		skeleton = path_2_skel
func _tick_enabled( enable : bool ):
	enabled = enable
	if enabled == false and virt_skel != null:
		if DEBUG_dump_bones: virt_skel.cshow(DEBUG_bone_property, DEBUG_entry_count)
		virt_skel.revert()
func _wipe_virtual_skeleton() -> void:
	virt_skel = null
	_chain_count = 0
	_chains.clear()
	_poles.clear()
	_look_ats.clear()
func _build_virtual_skeleton( in_editor : bool ) -> int:
	skel = get_node_or_null(skeleton)
	if skel == null:
		push_error("Skeleton in " + self.name + " never assigned.")
		enabled = false
		return FAILED
	virt_skel = VirtualSkeleton.new(skel, in_editor)
	return OK

## GLOBAL VARIABLES ########################################################################################
var skel : Skeleton
var virt_skel : VirtualSkeleton
var _chain_count = 0
var _chains            := []   ### Binds and drivers are solved in hiearchycal order
var _poles             := []
var _look_ats          := []

## INIT ####################################################################################################
func _ready():
	if not Engine.editor_hint: ## Execute in game
		if not _build_virtual_skeleton( false ):
			_evaluate_drivers()
			if DEBUG_dump_bones:
				virt_skel.cshow()
func _evaluate_drivers() -> void:
	for node in self.get_children():
		var type = node.get_script()
		if type == IKChain:
			_eval_chain_node( node )
			_chain_count += 1
		elif type == IKPole:
			_eval_pole_node( node )
		#elif type == IKBind:
		#	_eval_bind_node( node )
		#elif type == IKForkBind:
		#	_eval_fork_bind_node( node )
		elif type == IKLookAt:
			_eval_look_at_node( node )
		elif type == IKExaggerator:
			_eval_exaggerator_node( node )
		elif node is IKSolidifier:
			_eval_solidifier_node( node )
		elif type == IKDampedTransform:
			_eval_damped_transform_node( node )
func _reevaluate_drivers() -> void:
	_chain_count = 0
	_chains.clear()
	_poles.clear()
	_look_ats.clear()
	_evaluate_drivers()
func _eval_chain_node( chain ) -> void:
	if not virt_skel.has_bone(chain.tip_bone_id):
		push_error( "IK Chain [" + chain.name + "] ignored. Couldn't find the bone with id [" + chain.tip_bone_id + "]." )
		return
	self._chains.push_back(chain)
func _eval_pole_node( pole ) -> void:
	if not virt_skel.has_bone(str(pole.tip_bone_id)):
		push_error( "IK Pole [" + pole.name + "] ignored. Couldn't find the bone with id [" + str(pole.tip_bone_id) + "]." )
		return
	
	if virt_skel.get_bone_parent(str(pole.tip_bone_id)) == "-1" or virt_skel.get_bone_parent(virt_skel.get_bone_parent(str(pole.tip_bone_id))) == "-1":
		push_error( "IK Pole [" + pole.name + "] ignored. Chain too short." )
		return
	
	self._poles.push_back(pole)
func _eval_bind_node( bind : IKBind ) -> void:
	if not virt_skel.has_bone(bind.bone_1) or \
		not virt_skel.has_bone(bind.bone_2) or \
		not virt_skel.has_bone(bind.bone_3):
		push_error( "IK Bind [" + bind.name + "] ignored. Has invalid ids." )
		return
	bind.length_12 = ( virt_skel.get_bone_position(bind.bone_1) - virt_skel.get_bone_position(bind.bone_2) ).length()
	bind.length_23 = ( virt_skel.get_bone_position(bind.bone_2) - virt_skel.get_bone_position(bind.bone_3) ).length()
	bind.length_31 = ( virt_skel.get_bone_position(bind.bone_3) - virt_skel.get_bone_position(bind.bone_1) ).length()
	
	if virt_skel.has_bone( bind.bone_2_correction_bone ):
		bind.length_c2 = ( virt_skel.get_bone_position(bind.bone_2_correction_bone) - virt_skel.get_bone_position(bind.bone_2) ).length()
	
	if virt_skel.has_bone( bind.bone_3_correction_bone ):
		bind.length_c3 = ( virt_skel.get_bone_position(bind.bone_3_correction_bone) - virt_skel.get_bone_position(bind.bone_3) ).length()
	
	_chains.push_back(bind)
func _eval_look_at_node( look_at ):
	if not virt_skel.has_bone(str(look_at.bone_id)):
		push_error( "IK Look-At [" + look_at.name + "] ignored. Couldn't find the bone with id [" + str(look_at.bone_id) + "]." )
		return
	
	self._look_ats.push_back(look_at)
func _eval_exaggerator_node( exaggerator : IKExaggerator ) -> void:
	if not virt_skel.has_bone(exaggerator.bone_id):
		push_error("IK Exaggerator [" + exaggerator.name + "] ignored. Invalid Bone Id.")
		return
	if not exaggerator.is_connected("multiplier_changed", self, "_on_exaggurator_change"):
		var _trash = exaggerator.connect("multiplier_changed", self, "_on_exaggurator_change")
func _eval_solidifier_node( solidifier : IKSolidifier ) -> void:
	if not virt_skel.has_bone(solidifier.bone_id):
		push_error("IK Solidifier [" + solidifier.name + "] ignored. Specified bone does not exist.")
		return
	if not virt_skel.get_bone_children(solidifier.bone_id).size():
		push_error("IK Solidifier [" + solidifier.name + "] ignored. The bone specified is a tip.")
		return
	virt_skel.set_bone_chain_modifier(solidifier.bone_id, VirtualSkeleton.MODIFIER.SOLID)
func _eval_damped_transform_node( damped_transform : IKDampedTransform ) -> void:
	if not virt_skel.has_bone(damped_transform.bone_id):
		push_error("IK Damped Transform [" + damped_transform.name + "] ignored. Specified bone does not exist.")
		return
	virt_skel.set_bone_chain_modifier(damped_transform.bone_id, VirtualSkeleton.MODIFIER.DAMPED_TRANSFORM, damped_transform)
func _eval_fork_bind_node ( fork_bind : IKForkBind ) -> void:
	if not virt_skel.has_bone(fork_bind.bone_1) or \
		not virt_skel.has_bone(fork_bind.bone_2) or \
		not virt_skel.has_bone(fork_bind.bone_3) or \
		not virt_skel.has_bone(fork_bind.bone_target):
		push_error( "IK Fork Bind [" + fork_bind.name + "] ignored. Has invalid ids." )
		return
	fork_bind.length_1 = ( virt_skel.get_bone_position(fork_bind.bone_1) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	fork_bind.length_2 = ( virt_skel.get_bone_position(fork_bind.bone_2) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	fork_bind.length_3 = ( virt_skel.get_bone_position(fork_bind.bone_3) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	_chains.push_back(fork_bind)
## RUNTIME #################################################################################################
func _physics_process(_delta):
	if enabled and skel != null and virt_skel != null:
		var inverse_transform = skel.get_global_transform().affine_inverse() # .scaled( skel.get_global_transform().basis.get_scale() )
		solve_chains  ( inverse_transform )
		solve_poles   ( inverse_transform )
		solve_look_ats( inverse_transform )
		total_pass()
		virt_skel.bake()
func solve_chains( inverse_transform : Transform ) -> void:
	var diff : float = 0
	## No need to solve if distance is closed
	for d in _chains:
		if d.get_script() == IKChain:
			diff += virt_skel.get_bone_position(d.tip_bone_id).distance_squared_to(inverse_transform.xform(d.get_target().origin))
			
	var can_solve : int = self.max_iterations
	while can_solve > 0 and diff > self.minimal_distance * self.minimal_distance * self._chain_count:
		## Solve Backwards
		for d in _chains:
			if d.get_script() == IKChain:
				solve_backwards( d.root_bone_id,
					d.tip_bone_id,
					inverse_transform * d.get_target(),
					d.snap_back_strength )
			#elif d is IKBind:
			#	solve_bind( d.bone_1, d.bone_2, d.bone_3,
			#				d.bone_2_correction_bone, d.bone_3_correction_bone,
			#				d.get_12_length(), d.get_23_length(), d.get_31_length(),
			#				d.length_c2, d.length_c3)
			#	for b in d._binds_that_share_bones:
			#		solve_bind( b.bone_1, b.bone_2, b.bone_3,
			#					b.bone_2_correction_bone, b.bone_3_correction_bone,
			#					b.get_12_length(), b.get_23_length(), b.get_31_length(),
			#					b.length_c2, b.length_c3)
			#elif d is IKForkBind:
			#	solve_fork_bind(d.bone_1, d.bone_2, d.bone_3, d.bone_target,
			#					d.length_1, d.length_2, d.length_3)
		
		## Solve Forwards
		total_pass()
		
		## Measure Distance
		diff = 0
		for d in _chains:
			if d.get_script() == IKChain:
				diff += virt_skel.get_bone_position(d.tip_bone_id).distance_squared_to(inverse_transform.xform(d.get_target().origin))
		can_solve -= 1
func solve_poles( inverse_transform : Transform ) -> void:
	for p in _poles:
		solve_pole( str( p.root_bone_id ),
			str( p.tip_bone_id ),
			inverse_transform.xform(p.get_target().origin),
			p.turn_to)
func solve_look_ats( inverse_transform : Transform ) -> void:
	for l in _look_ats:
		solve_look_at( str(l.bone_id),
			inverse_transform.xform(l.get_target().origin),
				l.look_from )
func total_pass():
	for root in virt_skel.roots:
		solve_forwards( root, virt_skel.bones[root].initial_position )

## RESOLVING TOOLS ########################################################################################
func solve_look_at( bone_id : String, target : Vector3, side : int) -> void:
	var pivot : Vector3 = virt_skel.get_bone_position(virt_skel.get_bone_parent(bone_id))
	var start_dir : Vector3 = virt_skel.get_bone_start_direction(bone_id)
	var target_dir : Vector3 = (target - pivot)
	var rotation : Quat
	
	if side == 0: # UP
		rotation = from_to_rotation( start_dir, target_dir.normalized() )
	elif side == 1: # DOWN
		rotation = from_to_rotation( start_dir, -target_dir.normalized() )
	else:
		var rot_axis : Vector3 = start_dir.cross(target_dir).normalized()
		var a : float = start_dir.length()/2.0
		var b : float = target_dir.length()
		var rot_angle = -acos(clamp(a/b, -1.0, 1.0))
		## Solve bone rotation around the pivot
		rotation = from_to_rotation( start_dir, Quat(rot_axis, rot_angle) * target_dir )
		
		## Spin so that the wanted side is pointed towards the target
		var sp := Plane(rotation * Vector3.UP, 0.0)
		var spin_angle : float
		if side == 4: # FRONT
			spin_angle = signed_angle(rotation * Vector3.FORWARD, sp.project(target_dir), sp.normal)
		elif side == 2: # LEFT
			spin_angle = signed_angle(rotation * Vector3.LEFT, sp.project(target_dir), sp.normal)
		elif side == 5: # BACK
			spin_angle = signed_angle(rotation * Vector3.BACK, sp.project(target_dir), sp.normal)
		else:
			spin_angle = signed_angle(rotation * Vector3.RIGHT, sp.project(target_dir), sp.normal)
		rotation = Quat(sp.normal, spin_angle ) * rotation
	
	virt_skel.set_bone_position( bone_id,
		pivot + (rotation * start_dir) )
	virt_skel.set_bone_rotation( bone_id,
		rotation )
func solve_bind( b1_id : String, b2_id : String, b3_id : String,
	b2_correction : String, b3_correction : String,
	b1_b2_length : float, b2_b3_length : float, b3_b1_length : float,
	b2_correction_length : float, b3_correction_length : float ):
		
	### PHASE 1
	## Step 1
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
	## Step 2
	virt_skel.set_bone_position( b3_id,
		calc_next( virt_skel.get_bone_position(b2_id), virt_skel.get_bone_position(b3_id), b2_b3_length ))
	## Step 3
	virt_skel.set_bone_position( b1_id,
		calc_next( virt_skel.get_bone_position(b3_id), virt_skel.get_bone_position(b1_id), b3_b1_length ))
	## Step 4 (same as 1)
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
		
	### PHASE 2
	## Step 5
	virt_skel.set_bone_position( b3_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b3_id), b3_b1_length ))
	## Step 6
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b3_id), virt_skel.get_bone_position(b2_id), b2_b3_length ))
		
	### PHASE 3  [ TODO: FIX]
	if b2_correction != "-1":
		## Step 7 (same as 1)
		virt_skel.set_bone_position( b2_id,
			calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
		## Step 8
		virt_skel.set_bone_position( b2_id,
			calc_next( virt_skel.get_bone_position(b2_correction), virt_skel.get_bone_position(b2_id), b2_correction_length ))
		
	if b3_correction != "-1":
		## Step 9 (same 5)
		virt_skel.set_bone_position( b3_id,
			calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b3_id), b3_b1_length ))
		## Step 10
		virt_skel.set_bone_position( b3_id,
			calc_next( virt_skel.get_bone_position(b3_correction), virt_skel.get_bone_position(b3_id), b3_correction_length ))
		
	### PHASE 4 (SAME AS PHASE 1)
	## Step 11 (same as 1)
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
	## Step 12 (same as 2)
	virt_skel.set_bone_position( b3_id,
		calc_next( virt_skel.get_bone_position(b2_id), virt_skel.get_bone_position(b3_id), b2_b3_length ))
	## Step 13 (same as 3)
	virt_skel.set_bone_position( b1_id,
		calc_next( virt_skel.get_bone_position(b3_id), virt_skel.get_bone_position(b1_id), b3_b1_length ))
	## Step 14 (same as 1)
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
		
	### PHASE 5 (SAME AS PHASE 2)
	## Step 15 (same as 5)
	virt_skel.set_bone_position( b3_id,
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b3_id), b3_b1_length ))
	## Step 16 (same as 6)
	virt_skel.set_bone_position( b2_id,
		calc_next( virt_skel.get_bone_position(b3_id), virt_skel.get_bone_position(b2_id), b2_b3_length ))
func solve_fork_bind( bone_1_id : String, bone_2_id : String, bone_3_id : String, bone_target_id : String, length_1 : float, length_2 : float, length_3 : float ) -> void:
	## Step 1 - solve the bind on a plane so that all is straight and even
	var plane := Plane((virt_skel.get_bone_position(bone_2_id) - virt_skel.get_bone_position(bone_1_id)).normalized().cross((virt_skel.get_bone_position(bone_3_id) - virt_skel.get_bone_position(bone_1_id)).normalized()), 0)
	plane.d = plane.distance_to(virt_skel.get_bone_position(bone_1_id))
	var projected_target = plane.project(virt_skel.get_bone_position(bone_target_id))
	## Step 2 - correct 1st bone
	virt_skel.set_bone_position( bone_target_id,
		calc_next( virt_skel.get_bone_position(bone_1_id), projected_target, length_1 ))
	## Step 3 - correct 2nd bone
	virt_skel.set_bone_position( bone_target_id,
		calc_next( virt_skel.get_bone_position(bone_2_id), virt_skel.get_bone_position(bone_target_id), length_2 ))
	## Step 4 - correct 3rd bone
	virt_skel.set_bone_position( bone_target_id,
		calc_next( virt_skel.get_bone_position(bone_3_id), virt_skel.get_bone_position(bone_target_id), length_3 ))
func solve_pole( root_id : String, tip_id : String, target : Vector3, side : int ):
	if not virt_skel.has_bone(root_id) and root_id != VOID_ID:
		return
	
	var stop_bone = virt_skel.get_bone_parent(root_id)
	
	var previous_bone = tip_id
	var current_bone = virt_skel.get_bone_parent(previous_bone)
	var next_bone = virt_skel.get_bone_parent(current_bone)
	var rot_quat : Quat
	var start_dir : Vector3
	var target_dir : Vector3
	
	while next_bone != stop_bone and current_bone != root_id:
		var norm : Vector3 = ( virt_skel.get_bone_position(previous_bone) - virt_skel.get_bone_position(next_bone)).normalized()
		var p := Plane( norm, 0 )
		p.d = p.distance_to( virt_skel.get_bone_position(previous_bone) )
		var projP = p.project( target )
		var projV = p.project( virt_skel.get_bone_position(current_bone) )
		var angle = signed_angle(projV - virt_skel.get_bone_position(previous_bone),
			projP  - virt_skel.get_bone_position(previous_bone),
			norm)
		virt_skel.set_bone_position( current_bone, Quat(norm, angle) * ( virt_skel.get_bone_position(current_bone) -  virt_skel.get_bone_position(previous_bone)) +  virt_skel.get_bone_position(previous_bone) )
		
		## Calc bone rotation
		# Point vector Y at the next bone
		start_dir = virt_skel.get_bone_start_direction(current_bone).normalized()
		target_dir = (virt_skel.get_bone_position(next_bone) - virt_skel.get_bone_position(current_bone)).normalized()
		rot_quat = from_to_rotation(start_dir, target_dir)
		
		# Point side vector towards the target
		virt_skel.set_bone_rotation(current_bone, rotate_along_axis(rot_quat, virt_skel.get_bone_position(current_bone), target, side))
		
		previous_bone = current_bone
		current_bone = next_bone
		next_bone = virt_skel.get_bone_parent(next_bone)
func solve_forwards( root_id : String, origin : Vector3) -> void:
	if not virt_skel.has_bone(root_id) and root_id != VOID_ID:
		return
	
	var subbase_queue : PoolStringArray = virt_skel.get_bone_children(root_id)
	var modifier_flags : int
	virt_skel.set_bone_position(root_id, origin)
	var previous_bone := root_id
	var current_bone := subbase_queue[0]
	subbase_queue.remove(0)
	
	while true:
		## if no more children are queued, exit
		if current_bone == "-1":
			return
		else:
			## Remove weights so that they do not obstruct future backwards solve
			virt_skel.wipe_weights( current_bone )
			
			## CALC OWN ROTATION
			if previous_bone != VOID_ID:
				var rotation := from_to_rotation( virt_skel.get_bone_start_direction(current_bone).normalized(),
					(virt_skel.get_bone_position(current_bone) - virt_skel.get_bone_position(previous_bone)).normalized())
				virt_skel.set_bone_rotation(previous_bone, rotation)
			
			## CALC CURRENT'S POSITION
			modifier_flags = virt_skel.get_bone_modifiers(current_bone)
			if modifier_flags == VirtualSkeleton.MODIFIER.SOLID:
				virt_skel.set_bone_position( current_bone,  virt_skel.get_bone_position(previous_bone) + \
					(
						(virt_skel.get_bone_rotation(virt_skel.get_bone_parent(virt_skel.get_bone_modifier_master(current_bone))) * virt_skel.get_bone_start_direction(current_bone).normalized()) \
						* \
						virt_skel.get_bone_length(current_bone)
					)
					)
			elif modifier_flags == VirtualSkeleton.MODIFIER.DAMPED_TRANSFORM:
				var data = virt_skel.get_bone_damped_transform(current_bone) ### Array has 4 elements in order [stiffness, mass, damping, gravity]
				var target : Vector3 = virt_skel.get_bone_position(previous_bone) + ((virt_skel.get_bone_rotation(virt_skel.get_bone_parent(virt_skel.get_bone_modifier_master(current_bone))) * virt_skel.get_bone_start_direction(current_bone).normalized()) * virt_skel.get_bone_length(current_bone))
				var force : Vector3 = (target - virt_skel.get_bone_position(current_bone)) * data[0] ## Stiffness
				force.y -= data[3] ## Gravity
				var acceleration : Vector3 = force / data[1] ## mass
				var velocity := virt_skel.add_velocity_to_bone( current_bone, acceleration * (1.0 - data[2]) ) ## Damping
				virt_skel.set_bone_position(current_bone, calc_next(virt_skel.get_bone_position(previous_bone),
					virt_skel.get_bone_position(current_bone) + velocity + force,
					virt_skel.get_bone_length(current_bone) ))
			else:
				virt_skel.set_bone_position(current_bone, calc_next(virt_skel.get_bone_position(previous_bone),  virt_skel.get_bone_position(current_bone), virt_skel.get_bone_length(current_bone)))
			
			
			## QUEUE UP THE CURRENTS' CHILDREN
			for child_bone in virt_skel.get_bone_children(current_bone):
				## Push branch on the queue so it can be solved later
				subbase_queue.push_back(child_bone)
			
		if not subbase_queue.size() == 0:
			## Pop the first item in queue
			previous_bone = current_bone
			current_bone = subbase_queue[0]
			subbase_queue.remove(0)
		else:
			current_bone = "-1"
func solve_backwards( root_id : String, tip_id : String, target : Transform, weight : float) -> void:
	if not virt_skel.has_bone(tip_id):
		return
	
	if virt_skel.get_bone_children_count(tip_id) == 0:
		virt_skel.set_bone_rotation( tip_id, target.basis.get_rotation_quat() )
	
	var current_bone   := tip_id
	var current_target := target.origin
	var stop_bone = virt_skel.get_bone_parent(root_id)
	while current_bone != stop_bone and virt_skel.get_bone_parent(current_bone) != VOID_ID:
		virt_skel.set_biassed_bone_position(current_bone, current_target, weight) ## current_weight
		current_target = calc_next(virt_skel.get_bone_position(current_bone), virt_skel.get_bone_position(virt_skel.get_bone_parent(current_bone)), virt_skel.get_bone_length(current_bone) )
		current_bone = virt_skel.get_bone_parent(current_bone)
func solve_solidifier( bone_id : String ) -> void:
	var rotation := virt_skel.get_bone_rotation(virt_skel.get_bone_parent(bone_id))
	
	## Iterating through the chain stuff
	var bone_queue : PoolStringArray = []
	var current_bone = bone_id
	while true:
		if virt_skel.get_bone_children_count(current_bone) == 0 and bone_queue.empty():
			return
		else:
			for child in virt_skel.get_bone_children(current_bone):
				bone_queue.push_back(child)
		
		current_bone = bone_queue[0]
		bone_queue.remove(0)
		
		
		virt_skel.set_bone_rotation( current_bone, rotation * virt_skel.get_bone_start_rotation(current_bone) )
## CALCULATORS ############################################################################################
static func signed_angle( from : Vector3, to : Vector3, axis : Vector3 ) -> float:
	var plane = Plane( axis.cross(from), 0 )
	if plane.is_point_over(to):
		return from.angle_to(to)
	else:
		return -from.angle_to(to)
static func calc_next( from : Vector3, to : Vector3, length : float ) -> Vector3:
	return from + ( (to - from).normalized() * length )
static func from_to_rotation(from : Vector3, to : Vector3) -> Quat:
	var k_cos_theta : float = from.dot(to)
	var k : float = sqrt(pow(from.length(), 2.0) * pow(to.length(), 2.0))
	var axis : Vector3 = from.cross(to)
		
	if k_cos_theta == -1:
			# 180 degree rotation around any orthogonal vector
		return Quat(1, 0, 0, 0)
	elif k_cos_theta == 1:
		return Quat(0, 0, 0, 1)
		
	return Quat(axis.x, axis.y, axis.z, k_cos_theta + k).normalized()
static func rotate_along_axis( rotation : Quat, pivot : Vector3, target : Vector3, side : int) -> Quat:
	var p = Plane( rotation * Vector3.UP, 0.0 )
	p.d = p.distance_to(pivot)
	var projP = p.project( target )
	var projV : Vector3
	
	if side == 0: ## FRONT
		projV = p.project( rotation * Vector3.FORWARD + pivot)
	elif side == 1: ## BACK
		projV = p.project( rotation * Vector3.BACK + pivot)
	elif side == 2: ## RIGHT
		projV = p.project( rotation * Vector3.RIGHT + pivot)
	else:
		projV = p.project( rotation * Vector3.LEFT + pivot)
	
	var angle = signed_angle( projV - pivot,
		projP - pivot,
		p.normal )
	return Quat( p.normal, angle ) * rotation
## SIGNALS ################################################################################################
func _on_exaggurator_change(bone_id,  length_multiplier) -> void:
	virt_skel.set_bone_length_multiplier(bone_id, length_multiplier)
func add_child(node: Node, legible_unique_name: bool = false) -> void:
	.add_child(node, legible_unique_name)
	connect_signals( node )
func connect_signals( node ) -> void:
	if node.has_method("_update_parameters"):
		if not is_connected("bone_names_obtained", node, "_update_parameters"):
			self.connect("bone_names_obtained", node, "_update_parameters")
		_reevaluate_drivers()
		emit_signal("bone_names_obtained", _bone_names_4_children)
