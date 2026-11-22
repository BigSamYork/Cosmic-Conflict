class_name StationHangar
extends Node3D

var parked_ships: Array[Node3D] = []
var radar_domes: Array[Node3D] = []
var marine_radars: Array[Node3D] = []
var gun_heads: Array[Node3D] = []
var lifts: Array[AnimationPlayer] = []
var age: float = 0.0

func _ready() -> void:
	add_child(EncounterArt.station())
	var factories: Array[Callable] = [EncounterArt.light_fighter, EncounterArt.strike_fighter, EncounterArt.delta_fighter, EncounterArt.escort_gunship]
	for side in [-1.0, 1.0]:
		for row in range(4):
			var design: int = (row + (1 if side > 0 else 0)) % factories.size()
			var ship: Node3D = factories[design].call()
			ship.get_child(0).set_instance_shader_parameter("parked", true)
			ship.name = "ParkedShip%d" % parked_ships.size()
			ship.set_meta("design", design)
			var bay: Vector3 = EncounterArt.PARKING_BAYS[row]
			ship.position = Vector3(side * bay.x, bay.y, bay.z)
			ship.rotation.y = side * PI * 0.1
			ship.add_child(FleetArt.model("landing_gear", "ground"))
			add_child(ship)
			parked_ships.append(ship)
		var service_light := OmniLight3D.new()
		service_light.position = Vector3(side * 31, 11, -55)
		service_light.light_color = Color("#9bc9d9") if side < 0 else Color("#f2bd82")
		service_light.light_energy = 1.65
		service_light.omni_range = 34.0
		add_child(service_light)
		var hoist := SurfaceRig.model("cargo_gantry")
		hoist.position = Vector3(side * 30, 22.7, -32 if side > 0 else -59)
		add_child(hoist)
		lifts.append(SurfaceRig.start(hoist, &"Transfer", 2.1 if side < 0 else 0.0))
	for i in range(6):
		var angle: float = i * TAU / 6 + PI / 12
		var mount := Node3D.new()
		mount.position = Vector3(cos(angle) * 126, 4 + sin(angle) * 126, 94)
		mount.rotation.z = angle - PI / 2
		add_child(mount)
		var pedestal := FleetArt.model("radar_pedestal", "ground")
		pedestal.scale = Vector3(0.95, 0.34, 0.95)
		mount.add_child(pedestal)
		var scanner := FleetArt.model("survey_dish", "ground")
		scanner.position.y = 4.4
		mount.add_child(scanner)
		radar_domes.append(scanner)
	for i in range(4):
		var angle: float = i * TAU / 4
		var mount := Node3D.new()
		mount.position = Vector3(cos(angle) * 125, 4 + sin(angle) * 125, 90)
		mount.rotation.z = angle - PI / 2
		add_child(mount)
		mount.add_child(EncounterArt.radar_mast(15.0, false))
		for level in range(2):
			var scanner := FleetArt.model("fleet_dish", "ground")
			scanner.scale = Vector3.ONE * (0.61 if level == 0 else 0.78)
			scanner.position = Vector3(2.5 if level == 0 else 0.0, 8.0 if level == 0 else 15.0, 0)
			mount.add_child(scanner)
			marine_radars.append(scanner)
	for i in range(8):
		var angle: float = (i + 0.25) * TAU / 8
		var mount := Node3D.new()
		mount.position = Vector3(cos(angle) * 113, 4 + sin(angle) * 113, 90)
		mount.rotation.x = PI * 0.5
		add_child(mount)
		mount.add_child(VectorArt.turret_base())
		var head: Node3D = VectorArt.turret_head()
		head.position.y = 2
		mount.add_child(head)
		gun_heads.append(head)
	advance(0.0)

func advance(delta: float) -> void:
	age += delta
	for lift in lifts:
		lift.advance(delta)
	for i in range(radar_domes.size()):
		radar_domes[i].rotation.y = age * (0.55 + i * 0.07)
	for i in range(marine_radars.size()):
		marine_radars[i].rotation.y = age * (1.0 if i % 2 == 0 else -0.7) + i
	for i in range(gun_heads.size()):
		gun_heads[i].rotation = Vector3(0.85 + sin(age * 0.35 + i) * 0.25, sin(age * 0.25 + i) * 0.8, 0)
