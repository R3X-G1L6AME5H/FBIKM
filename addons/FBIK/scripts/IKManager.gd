tool
extends Node
const FBIKM_NODE_ID = 0  # THIS NODE'S INDENTIFIER

## CONSTANTS ###############################################################################################
const VirtualSkeleton = preload("VirtualSkeleton.gd")

### ALL OTHER NODES' IDS
const FBIKM_CHAIN            = 1
const FBIKM_POLE             = 2
const FBIKM_LOOK_AT          = 3
const FBIKM_BIND             = 4
const FBIKM_FORK_BIND        = 5
const FBIKM_EXAGGERATOR      = 6
const FBIKM_SOLIDIFIER       = 7
const FBIKM_DAMPED_TRANSFORM = 8
const FBIKM_CAGE             = 9

const VOID_ID = "-1" ### Add a move dynamic way to do this

var _bone_names_4_children := "VOID:-1"
signal bone_names_obtained(bone_names)

## PARAMETERS ##############################################################################################
export (bool)     var enabled  = false setget _tick_enabled
export (NodePath) var skeleton = null setget _set_skeleton
export (int)      var max_iterations = 5
export (float)    var minimal_distance = 0.01

### Debug ###
var DEBUG_dump_bones = false   # Turn on
var DEBUG_bone_property = ""   # name bone property(position, rotation, etc.); list all by default
var DEBUG_entry_count = -1     # Show N bones; list all by default


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
			_reevaluate_drivers()
		else:
			skeleton = null
			_wipe_drivers()
			virt_skel = null
	else:
		skeleton = path_2_skel
func _tick_enabled( enable : bool ):
	enabled = enable
	if enabled == false and virt_skel != null:
		if DEBUG_dump_bones: virt_skel.cshow(DEBUG_bone_property, DEBUG_entry_count)
		virt_skel.revert()
func _wipe_drivers() -> void:
	_chains.clear()
	_poles.clear()
	_look_ats.clear()
	_binds.clear()
	if virt_skel:
		virt_skel.wipe_modifiers()
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
var _chains            := []   ### Binds and drivers are solved in hiearchycal order
var _poles             := []
var _look_ats          := []
var _binds             := []
var _fork_binds        := []
var _cage_binds        := []
## INIT ####################################################################################################
func _ready():
	if not Engine.editor_hint: ## Execute in game
		if not _build_virtual_skeleton( false ):
			_evaluate_drivers()
			if DEBUG_dump_bones:
				virt_skel.cshow()
func _evaluate_drivers() -> void:
	if virt_skel == null:
		push_error("Tried to evaluate drivers but failed because there was no Skeleton Node assigned.")
		return
	
	for node in self.get_children():
		var type = node.get_script()
		if node.get("FBIKM_NODE_ID") != null:
			match(node.FBIKM_NODE_ID):
				FBIKM_CHAIN:
					_eval_chain_node( node )
				FBIKM_POLE:
					_eval_pole_node( node )
				FBIKM_BIND:
					_eval_bind_node( node )
				FBIKM_FORK_BIND:
					_eval_fork_bind_node( node )
				FBIKM_LOOK_AT:
					_eval_look_at_node( node )
				FBIKM_EXAGGERATOR:
					_eval_exaggerator_node( node )
				FBIKM_SOLIDIFIER:
					_eval_solidifier_node( node )
				FBIKM_DAMPED_TRANSFORM:
					_eval_damped_transform_node( node )
				FBIKM_CAGE:
					_eval_cage_bind_node( node )
func _reevaluate_drivers() -> void:
	_wipe_drivers()
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
func _eval_look_at_node( look_at ):
	if not virt_skel.has_bone(look_at.bone_id):
		push_error( "IK Look-At [" + look_at.name + "] ignored. Couldn't find the bone with id [" + str(look_at.bone_id) + "]." )
		return
	if not virt_skel.has_bone(virt_skel.get_bone_parent(look_at.bone_id)):
		push_error( "IK Look-At [" + look_at.name + "] ignored. Specified bone [" + str(look_at.bone_id) + "] doesn't have a parent. This Look-at cannot be solved." )
		return
	
	self._look_ats.push_back(look_at)
	virt_skel.set_bone_modifier(look_at.bone_id, VirtualSkeleton.MODIFIER.LOOK_AT)
func _eval_exaggerator_node( exaggerator ) -> void:
	if not virt_skel.has_bone(exaggerator.bone_id):
		push_error("IK Exaggerator [" + exaggerator.name + "] ignored. Invalid Bone Id.")
		return
	if not exaggerator.is_connected("multiplier_changed", self, "_on_exaggurator_change"):
		var _trash = exaggerator.connect("multiplier_changed", self, "_on_exaggurator_change")
func _eval_solidifier_node( solidifier ) -> void:
	if not virt_skel.has_bone(solidifier.bone_id):
		push_error("IK Solidifier [" + solidifier.name + "] ignored. Specified bone does not exist.")
		return
	if not virt_skel.get_bone_children(solidifier.bone_id).size():
		push_error("IK Solidifier [" + solidifier.name + "] ignored. The bone specified is a tip.")
		return
	virt_skel.set_bone_modifier(solidifier.bone_id, VirtualSkeleton.MODIFIER.SOLID)
func _eval_damped_transform_node( damped_transform ) -> void:
	if not virt_skel.has_bone(damped_transform.bone_id):
		push_error("IK Damped Transform [" + damped_transform.name + "] ignored. Specified bone does not exist.")
		return
	virt_skel.set_bone_modifier(damped_transform.bone_id, VirtualSkeleton.MODIFIER.DAMPED_TRANSFORM, damped_transform)
func _eval_bind_node( bind ) -> void:
	if not virt_skel.has_bone(bind.bone_1):
		push_error( "IK Bind [" + bind.name + "] ignored. Bone 1 ID [" + bind.bone_1 + "] is invalid." )
		return
	if not virt_skel.has_bone(bind.bone_2):
		push_error( "IK Bind [" + bind.name + "] ignored. Bone 2 ID [" + bind.bone_2 + "] is invalid." )
		return
	if not virt_skel.has_bone(bind.bone_3):
		push_error( "IK Bind [" + bind.name + "] ignored. Bone 3 ID [" + bind.bone_3 + "] is invalid." )
		return
	### Calculate lengths
	bind.length_12 = ( virt_skel.get_bone_position(bind.bone_1) - virt_skel.get_bone_position(bind.bone_2) ).length()
	bind.length_23 = ( virt_skel.get_bone_position(bind.bone_2) - virt_skel.get_bone_position(bind.bone_3) ).length()
	bind.length_31 = ( virt_skel.get_bone_position(bind.bone_3) - virt_skel.get_bone_position(bind.bone_1) ).length()
	
	### Calculate correction bone lengths
	## Pass through binds and find those which share bones 2 & 3, and set their correction to be the adjecent bone
	for b in self._binds:
		### Correction bone 2
		if bind.bone_2 == b.bone_2:
			bind.bone_2_correction_bone = b.bone_3
			bind.lock_correction_bone_2 = true
			b.bone_2_correction_bone = bind.bone_3
			b.lock_correction_bone_2 = true
		elif bind.bone_2 == b.bone_3:
			bind.bone_2_correction_bone = b.bone_2
			bind.lock_correction_bone_2 = true
			b.bone_3_correction_bone = bind.bone_3
			b.lock_correction_bone_3 = true
		### Correction bone 3
		elif bind.bone_3 == b.bone_2:
			bind.bone_3_correction_bone = b.bone_3
			bind.lock_correction_bone_3 = true
			b.bone_2_correction_bone = bind.bone_2
			b.lock_correction_bone_2 = true
		elif bind.bone_3 == b.bone_3:
			bind.bone_3_correction_bone = b.bone_2
			bind.lock_correction_bone_3 = true
			b.bone_3_correction_bone = bind.bone_2
			b.lock_correction_bone_3 = true
	
	if virt_skel.has_bone( bind.bone_1_correction_bone ):
		bind.correction_length_1 = ( virt_skel.get_bone_position(bind.bone_1_correction_bone) - virt_skel.get_bone_position(bind.bone_1) ).length()
	if virt_skel.has_bone( bind.bone_2_correction_bone ):
		bind.correction_length_2 = ( virt_skel.get_bone_position(bind.bone_2_correction_bone) - virt_skel.get_bone_position(bind.bone_2) ).length()
	if virt_skel.has_bone( bind.bone_3_correction_bone ):
		bind.correction_length_3 = ( virt_skel.get_bone_position(bind.bone_3_correction_bone) - virt_skel.get_bone_position(bind.bone_3) ).length()
	
	bind.bind_id = self._binds.size()
	self._binds.push_back(bind)
	virt_skel.set_bone_modifier(VOID_ID, VirtualSkeleton.MODIFIER.BIND, bind)
func _eval_fork_bind_node ( fork_bind ) -> void:
	if not virt_skel.has_bone(fork_bind.bone_target):
		push_error( "IK Fork Bind [" + fork_bind.name + "] ignored. Target Bone ID [" + fork_bind.bone_target + "] is invalid." )
		return
	if not virt_skel.has_bone(fork_bind.bone_1):
		push_error( "IK Fork Bind [" + fork_bind.name + "] ignored. Bone 1 ID [" + fork_bind.bone_1 + "] is invalid." )
		return
	if not virt_skel.has_bone(fork_bind.bone_2):
		push_error( "IK Fork Bind [" + fork_bind.name + "] ignored. Bone 2 ID [" + fork_bind.bone_2 + "] is invalid." )
		return
	if not virt_skel.has_bone(fork_bind.bone_3):
		push_error( "IK Fork Bind [" + fork_bind.name + "] ignored. Bone 3 ID [" + fork_bind.bone_3 + "] is invalid." )
		return
	fork_bind.length_1 = ( virt_skel.get_bone_position(fork_bind.bone_1) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	fork_bind.length_2 = ( virt_skel.get_bone_position(fork_bind.bone_2) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	fork_bind.length_3 = ( virt_skel.get_bone_position(fork_bind.bone_3) - virt_skel.get_bone_position(fork_bind.bone_target) ).length()
	
	fork_bind.bind_id = self._fork_binds.size()
	self._fork_binds.push_back(fork_bind)
	virt_skel.set_bone_modifier(VOID_ID, VirtualSkeleton.MODIFIER.FORK_BIND, fork_bind)
func _eval_cage_bind_node( cage ) -> void:
	if not virt_skel.has_bone(cage.backbone_1):
		push_error( "IK Cage Bind [" + cage.name + "] ignored. Target Bone ID [" + cage.backbone_1 + "] is invalid." )
		return
	if not virt_skel.has_bone(cage.backbone_2):
		push_error( "IK Cage Bind [" + cage.name + "] ignored. Bone 1 ID [" + cage.backbone_2 + "] is invalid." )
		return
	if not virt_skel.has_bone(cage.target_bone_1):
		push_error( "IK Cage Bind [" + cage.name + "] ignored. Bone 2 ID [" + cage.target_bone_1 + "] is invalid." )
		return
	if not virt_skel.has_bone(cage.target_bone_2):
		push_error( "IK Cage Bind [" + cage.name + "] ignored. Bone 3 ID [" + cage.target_bone_2 + "] is invalid." )
		return
	
	cage.b1b2_length = ( virt_skel.get_bone_position(cage.backbone_1) - virt_skel.get_bone_position(cage.backbone_2) ).length()
	cage.b1t1_length = ( virt_skel.get_bone_position(cage.backbone_1) - virt_skel.get_bone_position(cage.target_bone_1) ).length()
	cage.b1t2_length = ( virt_skel.get_bone_position(cage.backbone_1) - virt_skel.get_bone_position(cage.target_bone_2) ).length()
	cage.b2t1_length = ( virt_skel.get_bone_position(cage.backbone_2) - virt_skel.get_bone_position(cage.target_bone_1) ).length()
	cage.b2t2_length = ( virt_skel.get_bone_position(cage.backbone_2) - virt_skel.get_bone_position(cage.target_bone_2) ).length()
	cage.t1t2_length = ( virt_skel.get_bone_position(cage.target_bone_1) - virt_skel.get_bone_position(cage.target_bone_2) ).length()
	
	cage.b2_correction_length = ( virt_skel.get_bone_position(cage.backbone_2) - virt_skel.get_bone_position(cage.backbone_2_correction) ).length()
	cage.t1_correction_length = ( virt_skel.get_bone_position(cage.target_bone_1) - virt_skel.get_bone_position(cage.target_bone_1_correction) ).length()
	cage.t2_correction_length = ( virt_skel.get_bone_position(cage.target_bone_2) - virt_skel.get_bone_position(cage.target_bone_2_correction) ).length()
	
	cage.bind_id = self._cage_binds.size()
	self._cage_binds.push_back(cage)
	virt_skel.set_bone_modifier(VOID_ID, VirtualSkeleton.MODIFIER.CAGE_BIND, cage)
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
		diff += virt_skel.get_bone_position(d.tip_bone_id).distance_squared_to(inverse_transform.xform(d.get_target().origin))
			
	var can_solve : int = self.max_iterations
	while can_solve > 0 and diff > self.minimal_distance * self.minimal_distance * self._chains.size():
		## Solve Backwards
		for d in _chains:
			solve_backwards( d.root_bone_id,
				d.tip_bone_id,
				inverse_transform * d.get_target(),
				d.pull_strength )
			#elif d.FBIKM_NODE_ID == FBIKM_BIND:
			#	solve_bind( d.bone_1, d.bone_2, d.bone_3,
			#				d.bone_2_correction_bone, d.bone_3_correction_bone,
			#				d.get_12_length(), d.get_23_length(), d.get_31_length(),
			#				d.length_c2, d.length_c3)
			#	for b in d._binds_that_share_bones:
			#		solve_bind( b.bone_1, b.bone_2, b.bone_3,
			#					b.bone_2_correction_bone, b.bone_3_correction_bone,
			#					b.get_12_length(), b.get_23_length(), b.get_31_length(),
			#					b.length_c2, b.length_c3)
			#elif d.FBIKM_NODE_ID == FBIKM_FORK_BIND:
			#	solve_fork_bind(d.bone_1, d.bone_2, d.bone_3, d.bone_target,
			#					d.length_1, d.length_2, d.length_3)
		
		## Solve Forwards
		total_pass()
		
		## Measure Distance
		diff = 0
		for d in _chains:
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
		solve_look_at( l.bone_id,
					   inverse_transform.xform(l.get_target().origin),
					   l.look_from,
					   l.get("up-down_spin_override_angle") )
func solve_binds( bone_id : String ) -> void:
	var modifier_flags = virt_skel.get_bone_modifiers(bone_id)
	
	## First - only solve Reverse forks
	if modifier_flags & virt_skel.MODIFIER.FORK_BIND:
		for i in virt_skel.get_bone_fork_bind_ids(bone_id):
			if _fork_binds[i].reverse_fork:
				solve_fork(_fork_binds[i].bone_1, _fork_binds[i].bone_2, _fork_binds[i].bone_3, _fork_binds[i].bone_target, _fork_binds[i].length_1, _fork_binds[i].length_2, _fork_binds[i].length_3, true )
	
	## N/A - the cage shouldn't interact with any other bind, however it works like a complex loop solver so it goes before binds
	if modifier_flags & virt_skel.MODIFIER.CAGE_BIND:
		var c = _cage_binds[virt_skel.get_bone_cage_bind_id(bone_id)]
		solve_loop( c.target_bone_2,            c.backbone_2,            c.target_bone_1,
					c.target_bone_2_correction, c.backbone_2_correction, c.target_bone_1_correction,
					c.t1t2_length,              c.b2t1_length,           c.b1t1_length,
					c.t2_correction_length,     c.b2_correction_length,  c.t1_correction_length)
		
		solve_loop( c.backbone_1,  c.backbone_2,            c.target_bone_1,
					VOID_ID,       c.backbone_2_correction, c.target_bone_1_correction,
					c.b1b2_length, c.b2t1_length,           c.b1t1_length,
					0,             c.b2_correction_length,  c.t1_correction_length)
		
		solve_loop( c.backbone_1,  c.target_bone_1,            c.target_bone_2,
					VOID_ID,       c.target_bone_1_correction, c.target_bone_2_correction,
					c.b1b2_length, c.b1t1_length,           c.t1t2_length,
					0,             c.t1_correction_length,  c.t2_correction_length)
		
		solve_loop( c.backbone_1,  c.target_bone_2,            c.backbone_2,
					VOID_ID,       c.target_bone_2_correction, c.backbone_2_correction,
					c.b1b2_length, c.t1t2_length,           c.b2t1_length,
					0,             c.t2_correction_length,  c.b2_correction_length)
		
		solve_loop( c.target_bone_2,            c.backbone_2,            c.target_bone_1,
					VOID_ID,                    VOID_ID,                 VOID_ID,
					c.t1t2_length,              c.b2t1_length,           c.b1t1_length,
					c.t2_correction_length,     c.b2_correction_length,  c.t1_correction_length)
	
	
	## Second - solve binds
	if modifier_flags & virt_skel.MODIFIER.BIND:
		### TO DO - handle deps
		for i in virt_skel.get_bone_bind_ids(bone_id):
			solve_loop( _binds[i].bone_1,              _binds[i].bone_2,              _binds[i].bone_3,
				_binds[i].bone_1_correction_bone,   _binds[i].bone_2_correction_bone,   _binds[i].bone_3_correction_bone,
				_binds[i].length_12,            _binds[i].length_23,            _binds[i].length_31,
				_binds[i].correction_length_1, _binds[i].correction_length_2, _binds[i].correction_length_3)
			
	## Third - solve all forks as normal forks
	if modifier_flags & virt_skel.MODIFIER.FORK_BIND:
		for i in virt_skel.get_bone_fork_bind_ids(bone_id):
			solve_fork(_fork_binds[i].bone_1, _fork_binds[i].bone_2, _fork_binds[i].bone_3, _fork_binds[i].bone_target, _fork_binds[i].length_1, _fork_binds[i].length_2, _fork_binds[i].length_3, false )
	
	## A WAY TO BACKTRACK AND SOLVE PREVIOUS BINDS IN CASE OF BRANCHING
	#if virt_skel.get_bone_parent(bone_id) != VOID_ID:
	#	if virt_skel.get_bone_modifiers(virt_skel.get_bone_parent(bone_id)) & (VirtualSkeleton.MODIFIER.FORK_BIND | VirtualSkeleton.MODIFIER.BIND):
	#		solve_binds(virt_skel.get_bone_parent(bone_id))
func total_pass():
	for chain in _chains:
		solve_backwards( chain.root_bone_id,
						 chain.tip_bone_id, 
						 Transform(virt_skel.get_bone_rotation(chain.tip_bone_id), virt_skel.get_bone_position(chain.tip_bone_id)),
						 chain.pull_strength )
	for root in virt_skel.roots:
		solve_forwards( root, virt_skel.bones[root].initial_position )

## RESOLVING TOOLS ########################################################################################
func solve_look_at( bone_id : String, target : Vector3, side : int, spin_override : float) -> void:
	var pivot : Vector3 = virt_skel.get_bone_position(virt_skel.get_bone_parent(bone_id))
	var start_dir : Vector3 = virt_skel.get_bone_start_direction(bone_id)
	var target_dir : Vector3 = (target - pivot)
	var rotation : Quat
	var spin_angle : float
	
	if side == 0: # UP
		rotation = from_to_rotation( start_dir, target_dir.normalized() ) * virt_skel.get_bone_start_rotation(virt_skel.get_bone_parent(bone_id))
		spin_angle = deg2rad(spin_override)
	elif side == 1: # DOWN
		rotation = from_to_rotation( start_dir, -target_dir.normalized() ) * virt_skel.get_bone_start_rotation(virt_skel.get_bone_parent(bone_id))
		spin_angle = deg2rad(spin_override)
	else:
		var rot_axis : Vector3 = start_dir.cross(target_dir).normalized()
		var a : float = virt_skel.get_bone_length(bone_id)/2.0
		var b : float = target_dir.length()
		var rot_angle = -acos(clamp(a/b, -1.0, 1.0))
		## Solve bone rotation around the pivot
	
		rotation = from_to_rotation( start_dir, Quat(rot_axis, rot_angle) * target_dir ) * virt_skel.get_bone_start_rotation(virt_skel.get_bone_parent(bone_id))
	
		var sp := Plane(rotation * Vector3.UP, 0.0)
		if side == 4: # FRONT
			spin_angle = signed_angle(rotation * Vector3.FORWARD, sp.project(target_dir.normalized()), sp.normal)
		elif side == 2: # LEFT
			spin_angle = signed_angle(rotation * Vector3.LEFT, sp.project(target_dir), sp.normal)
		elif side == 5: # BACK
			spin_angle = signed_angle(rotation * Vector3.BACK, sp.project(target_dir), sp.normal)
		else:
			spin_angle = signed_angle(rotation * Vector3.RIGHT, sp.project(target_dir), sp.normal)
		
	
	virt_skel.set_bone_rotation( virt_skel.get_bone_parent(bone_id),
		Quat(rotation * Vector3.UP, spin_angle) * rotation )
	
	virt_skel.set_bone_position( bone_id,
								 pivot + (rotation * virt_skel.get_bone_start_direction(bone_id).normalized()) * virt_skel.get_bone_length(bone_id))
func solve_loop( b1_id : String, b2_id : String, b3_id : String, 
				 b1_correction : String, b2_correction : String, b3_correction : String, 
				 b1_b2_length : float, b2_b3_length : float, b3_b1_length : float,
				 b1_correction_length : float, b2_correction_length : float, b3_correction_length : float ):
	### PHASE 1
	## Step 1
	virt_skel.set_bone_position( b2_id, 
		calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
	## Step 2
	virt_skel.set_bone_position( b3_id, 
		calc_next( virt_skel.get_bone_position(b2_id), virt_skel.get_bone_position(b3_id), b2_b3_length ))
	## Step 3
	if b1_correction != VOID_ID:
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
	## b1 correction
	if b1_correction != VOID_ID:
		virt_skel.set_bone_position( b1_id, 
									 calc_next( virt_skel.get_bone_position(b1_correction), virt_skel.get_bone_position(b1_id), b1_correction_length ))
	
	if b2_correction != VOID_ID:
		## Step 7 (same as 1)
		virt_skel.set_bone_position( b2_id, 
									 calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
		## Step 8
		virt_skel.set_bone_position( b2_id, 
									 calc_next( virt_skel.get_bone_position(b2_correction), virt_skel.get_bone_position(b2_id), b2_correction_length ))
	
	if b3_correction != VOID_ID:
		## Step 9 (same 5)
		virt_skel.set_bone_position( b3_id, 
									 calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b3_id), b3_b1_length ))
		## Step 10
		virt_skel.set_bone_position( b3_id, 
									 calc_next( virt_skel.get_bone_position(b3_correction), virt_skel.get_bone_position(b3_id), b3_correction_length ))
	
	### PHASE 4 (CUSTOM)
	## SOLVE CLOCKWISE
	virt_skel.set_bone_position( b2_id, 
								 calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
	virt_skel.set_bone_position( b3_id, 
								 calc_next( virt_skel.get_bone_position(b2_id), virt_skel.get_bone_position(b3_id), b2_b3_length ))
	
	## SOLVE COUNTER CLOCKWISE
	virt_skel.set_bone_position( b3_id, 
								 calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b3_id), b3_b1_length ))
	virt_skel.set_bone_position( b2_id, 
								 calc_next( virt_skel.get_bone_position(b3_id), virt_skel.get_bone_position(b2_id), b2_b3_length ))
	
	virt_skel.set_bone_position( b2_id, 
								 calc_next( virt_skel.get_bone_position(b1_id), virt_skel.get_bone_position(b2_id), b1_b2_length ))
func solve_fork( bone_1_id : String, bone_2_id : String, bone_3_id : String, bone_target_id : String, length_1 : float, length_2 : float, length_3 : float, reverse_fork : bool ) -> void:
	## Correct target // bone 1's position isn't altered
	virt_skel.set_bone_position( bone_target_id, 
								 calc_next( virt_skel.get_bone_position(bone_1_id), virt_skel.get_bone_position(bone_target_id), length_1 ))
	
	if reverse_fork:
		virt_skel.set_bone_position( bone_2_id, 
									 calc_next( virt_skel.get_bone_position(bone_target_id), virt_skel.get_bone_position(bone_2_id), length_2 ))
		virt_skel.set_bone_position( bone_3_id, 
									 calc_next( virt_skel.get_bone_position(bone_target_id), virt_skel.get_bone_position(bone_3_id), length_3 ))
	
	else:
		virt_skel.set_bone_position( bone_target_id, 
									 calc_next( virt_skel.get_bone_position(bone_2_id), virt_skel.get_bone_position(bone_target_id), length_2 ))
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
		start_dir = virt_skel.get_bone_start_direction(current_bone)
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
	
	## UNHANDLED INSTANCE
	if virt_skel.get_bone_modifiers(previous_bone) & (VirtualSkeleton.MODIFIER.BIND | VirtualSkeleton.MODIFIER.FORK_BIND | VirtualSkeleton.MODIFIER.CAGE_BIND):
		solve_binds(previous_bone)
	
	while true:
		## if no more children are queued, exit
		if current_bone == "-1":
			return
		else:
			## CALC CURRENT'S POSITION
			modifier_flags = virt_skel.get_bone_modifiers(current_bone)
			if modifier_flags == VirtualSkeleton.MODIFIER.NONE:
				virt_skel.set_bone_position(current_bone, calc_next(virt_skel.get_bone_position(previous_bone),  virt_skel.get_bone_position(current_bone), virt_skel.get_bone_length(current_bone)))
			
			elif modifier_flags & (VirtualSkeleton.MODIFIER.BIND | VirtualSkeleton.MODIFIER.FORK_BIND | VirtualSkeleton.MODIFIER.CAGE_BIND):
				virt_skel.set_bone_position(current_bone, calc_next(virt_skel.get_bone_position(previous_bone),  virt_skel.get_bone_position(current_bone), virt_skel.get_bone_length(current_bone)))
				solve_binds(current_bone)
			
			if modifier_flags & VirtualSkeleton.MODIFIER.SOLID:
				virt_skel.set_bone_position( current_bone,  virt_skel.get_bone_position(previous_bone) + \
														(
															(virt_skel.get_bone_rotation(virt_skel.get_bone_parent(virt_skel.get_bone_modifier_master(current_bone))) * virt_skel.get_bone_start_direction(current_bone)) \
															* \
															virt_skel.get_bone_length(current_bone)
														)
											)
			
			################################################################################################################################################################
			################################################################################################################################################################
			elif modifier_flags & VirtualSkeleton.MODIFIER.DAMPED_TRANSFORM:
				if virt_skel.get_bone_modifier_master(current_bone) != current_bone:
					var data = virt_skel.get_bone_damped_transform(current_bone) ### Array has 4 elements [stiffness, mass, damping, gravity]
					var target : Vector3 =  virt_skel.get_bone_position(previous_bone) + \
											((virt_skel.get_bone_rotation(virt_skel.get_bone_parent(virt_skel.get_bone_modifier_master(current_bone))) * virt_skel.get_bone_start_direction(current_bone).normalized()) * \
											virt_skel.get_bone_length(current_bone))
					var force : Vector3 = (target - virt_skel.get_bone_position(current_bone)) * data[0] ## Stiffness
					force.y -= data[3] ## Gravity
					var acceleration : Vector3 = force / data[1] ## mass
					var velocity := virt_skel.add_velocity_to_bone( current_bone, acceleration * (1.0 - data[2]) ) ## Damping
					virt_skel.set_bone_position(current_bone, calc_next(virt_skel.get_bone_position(previous_bone), 
																		virt_skel.get_bone_position(current_bone) + velocity + force, 
																		virt_skel.get_bone_length(current_bone) ))
			################################################################################################################################################################
			################################################################################################################################################################
			## CALC OWN ROTATION
			if previous_bone != VOID_ID and not modifier_flags & VirtualSkeleton.MODIFIER.LOOK_AT : # and virt_skel.get_bone_parent(previous_bone) != VOID_ID:
				var rotation := Quat()
				if virt_skel.get_bone_children_count(previous_bone) > 1:
					var wsum := 0.0
					var weight : float
					for c in virt_skel.get_bone_children(previous_bone):
						weight = float(virt_skel.get_bone_weight(c))
						if weight == 0:
							weight = 1
						wsum += weight
						rotation += from_to_rotation( virt_skel.get_bone_start_direction(previous_bone),
													 (virt_skel.get_bone_position(c) - virt_skel.get_bone_position(previous_bone)).normalized()) * weight
					rotation /= wsum
				else:
					rotation = from_to_rotation( virt_skel.get_bone_start_direction(current_bone),
												(virt_skel.get_bone_position(current_bone) - virt_skel.get_bone_position(previous_bone)).normalized())
				virt_skel.set_bone_rotation(previous_bone, rotation * virt_skel.get_bone_start_rotation(previous_bone))
			
			
			## QUEUE UP THE CURRENTS' CHILDREN
			## Push branch on the queue so it can be solved later
			subbase_queue.append_array(virt_skel.get_bone_children(current_bone))
			
		if not subbase_queue.size() == 0:
			## Pop the first item in queue
			current_bone = subbase_queue[0]
			previous_bone = virt_skel.get_bone_parent(current_bone)
			subbase_queue.remove(0)
		else:
			current_bone = "-1"
			## Remove weights so that they do not obstruct future backwards solve
			virt_skel.wipe_weights()
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
		emit_signal("bone_names_obtained", _bone_names_4_children)
