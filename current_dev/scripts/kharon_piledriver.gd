extends Node3D

const STRIDE := 5.8
const YAW := 0.38
const TURN := Basis(Vector3.UP, YAW)
var chassis: Node3D
var ram: Node3D
var upper: Array[Node3D] = []
var lower: Array[Node3D] = []
var shoes: Array[Node3D] = []
var foot_lifts := PackedFloat32Array()
var ground_height: Callable
var ram_tip := Vector3.ZERO

func _ready() -> void:
	chassis = FleetArt.model("kharon_driver_chassis", "ground")
	ram = FleetArt.model("kharon_driver_ram", "ground")
	add_child(chassis)
	add_child(ram)
	for i in 4:
		var thigh := FleetArt.model("kharon_driver_thigh", "ground")
		var shin := FleetArt.model("kharon_driver_shin", "ground")
		var shoe := FleetArt.model("kharon_driver_shoe", "ground")
		add_child(thigh)
		add_child(shin)
		add_child(shoe)
		upper.append(thigh)
		lower.append(shin)
		shoes.append(shoe)
		foot_lifts.append(0.0)

func _pose_link(link: Node3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	link.transform = Transform3D(Basis.looking_at(delta.normalized()) * Basis.from_scale(Vector3(1,1,delta.length()/5.0)), a)

func advance(age: float) -> void:
	# Each planted foot stays at its last world-space foothold until the next stride.
	# The two diagonal pairs alternate; at the strike the chassis arrests its lateral motion.
	var walk_x := -17.0 * (1.0-smoothstep(-0.24,1.96,age)) + 24.0*smoothstep(3.25,5.8,age)
	var squash := smoothstep(2.30,2.50,age)*(1.0-smoothstep(2.53,3.16,age))
	var floor_y := float(ground_height.call(walk_x,0))
	var body_position := Vector3(walk_x, floor_y + 7.7 + 0.25*cos(walk_x*TAU/STRIDE) - squash*1.35,0)
	var pitch := -0.10*squash + 0.035*sin(walk_x*TAU/STRIDE)
	chassis.transform = Transform3D(TURN * Basis(Vector3.RIGHT,pitch),body_position)
	# The crosshead pulls back for a full second, then fires the striped ram at the lock point.
	var tip_y := 2.2 + 2.65*smoothstep(0.55,1.86,age)
	tip_y *= 1.0 - smoothstep(2.18,2.5,age)
	tip_y += 2.7*smoothstep(2.78,3.65,age)
	ram_tip = Vector3(walk_x,floor_y+tip_y,0)
	ram.transform = Transform3D(TURN,ram_tip)
	for i in 4:
		var side := -1.0 if i<2 else 1.0
		var fore := -1.0 if i%2==0 else 1.0
		var phase_offset := 0.5 if i in [0,3] else 0.0
		var stride := walk_x/STRIDE + phase_offset
		var step := fposmod(stride,1)
		var swing := clampf((step-0.53)/0.47,0,1)
		var planted_x := (floorf(stride) - phase_offset + smoothstep(0,1,swing))*STRIDE
		var foot := TURN * Vector3(side*6.4,0,fore*4.08)
		foot.x += planted_x
		foot_lifts[i] = sin(swing*PI)*1.05
		foot.y = float(ground_height.call(foot.x,foot.z)) + foot_lifts[i] + 0.04
		shoes[i].transform = Transform3D(TURN * Basis(Vector3.RIGHT,-0.16*sin(swing*TAU)), foot)
		var hip := chassis.transform * Vector3(side*3.76,-0.35,fore*2.35)
		var ankle := foot + Vector3.UP*0.85
		var span := ankle - hip
		var length := span.length()
		var axis := span / length
		var outside := TURN * Vector3(side,0,fore*0.20)
		var bend := (outside - axis * outside.dot(axis)).normalized()
		# Two-link inverse kinematics hold the large radial knees outboard beneath the armor.
		var half := length * 0.5
		var reach := maxf(5.45,half+0.05)
		var knee := hip + axis*half + bend*sqrt(reach*reach-half*half)
		_pose_link(upper[i],hip,knee)
		_pose_link(lower[i],knee,ankle)
