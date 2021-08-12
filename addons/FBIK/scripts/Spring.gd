tool
extends Spatial

export (NodePath) var constrained_node = null
export (float, 0.005, 1.0) var stiffness = 0.25
export (float, 0.005, 1.0) var mass = 0.9
export (float, 0.005, 1.0) var damping = 0.75
export (float, 0.0, 1.0) var gravity = 0

export (bool) var solve_rotations = false
export (float, 0.005, 1.0) var rotation_stiffness = 1
export (float, 0.005, 1.0) var rotation_damping = 1

var dynamicPos : Vector3
var force : Vector3
var acc : Vector3
var vel : Vector3

var dynamicRot : Quat
var rot_force : Quat
var rot_acc : Quat
var rot_vel : Quat

###########################################################################################################
func _ready():
	dynamicPos = self.transform.origin
	dynamicRot = self.transform.basis.get_rotation_quat()

func _physics_process(delta):
	if constrained_node != null:
		get_node(constrained_node).transform = spring( self.transform )

###########################################################################################################
func spring( target : Transform ) -> Transform:
	force = (target.origin - dynamicPos) * stiffness
	force.y -= gravity / 10.0
	acc = force / mass
	vel += acc * (1 - damping)
	dynamicPos += vel + force
	
	if solve_rotations:
		rot_force = (target.basis.get_rotation_quat() - dynamicRot) * rotation_stiffness
		rot_acc = rot_force / mass
		rot_vel = rot_acc * (1 - rotation_damping)
		dynamicRot += rot_force + rot_vel
	
	return Transform(dynamicRot, dynamicPos)

# https://www.youtube.com/watch?v=KLjTU0yKS00
# https://wiki.unity3d.com/index.php/JiggleBone
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.2/manual/constraints/MultiRotationConstraint.html
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.3/manual/constraints/MultiPositionConstraint.html
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.2/manual/constraints/MultiAimConstraint.html
