tool
extends Spatial

"""
	FBIKM - Spring
		by Nemo Czanderlitch/Nino Čandrlić
			@R3X-G1L       (godot assets store)
			R3X-G1L6AME5H  (github)
	A simple script to spice up the Inverse Solver Animations. It is ment to be applied to Chain's
    target node. Given that the IK solver strictly follows its target, the movement looks very
	mechanical. If the target were to be a bit bouncy, the IK would be a bit more lively as well.
	This is the purpuse of this script.
"""


export (NodePath) var constrained_node = null
export (float, 0.005, 1.0) var stiffness = 0.25
export (float, 0.005, 1.0) var mass = 0.9
export (float, 0.005, 1.0) var damping = 0.75
export (float, 0.0, 1.0)   var gravity = 0

export (bool) var solve_rotations = false
export (float, 0.005, 1.0) var rotation_stiffness = 1
export (float, 0.005, 1.0) var rotation_damping = 1


## these are the spring values; the offsets form the actual target position, dictated by physics.
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
	## Set the dynamic (spring) values
	dynamicPos = self.transform.origin
	dynamicRot = self.transform.basis.get_rotation_quat()

func _physics_process(delta):
	## Apply the new transform to target
	if constrained_node != null:
		get_node(constrained_node).transform = spring( self.transform )

###########################################################################################################
func spring( target : Transform ) -> Transform:
	## Springy momentum physics
	force = (target.origin - dynamicPos) * stiffness
	force.y -= gravity / 10.0
	acc = force / mass
	vel += acc * (1 - damping)
	dynamicPos += vel + force

	## Springy rotations
	if solve_rotations:
		rot_force = (target.basis.get_rotation_quat() - dynamicRot) * rotation_stiffness
		rot_acc = rot_force / mass
		rot_vel = rot_acc * (1 - rotation_damping)
		dynamicRot += rot_force + rot_vel
	
	return Transform(dynamicRot, dynamicPos)


#### Refference (I suck at physics)
#### ##############################
# https://www.youtube.com/watch?v=KLjTU0yKS00
# https://wiki.unity3d.com/index.php/JiggleBone
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.2/manual/constraints/MultiRotationConstraint.html
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.3/manual/constraints/MultiPositionConstraint.html
# https://docs.unity3d.com/Packages/com.unity.animation.rigging@0.2/manual/constraints/MultiAimConstraint.html
