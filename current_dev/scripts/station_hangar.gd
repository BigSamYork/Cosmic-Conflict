class_name StationHangar
extends Node3D

var parked_ships: Array[Node3D] = []
var radar_domes: Array[Node3D] = []
var marine_radars: Array[Node3D] = []
var gun_heads: Array[Node3D] = []
var age: float = 0.0

func _ready() -> void:
	add_child(EncounterArt.station())
	var factories: Array[Callable] = [EncounterArt.light_fighter, EncounterArt.strike_fighter, EncounterArt.delta_fighter, EncounterArt.escort_gunship]
	for side in [-1.0, 1.0]:
		for row in range(4):
			var design: int = (row + (1 if side > 0 else 0)) % factories.size()
			var ship: Node3D = factories[design].call()
			ship.name = "ParkedShip%d" % parked_ships.size()
			ship.set_meta("design", design)
			var bay: Vector3 = EncounterArt.PARKING_BAYS[row]
			ship.position = Vector3(side * bay.x, bay.y, bay.z)
			ship.rotation.y = side * PI * 0.1
			var gear := GeometryBatch.new()
			for x in [-1.2, 1.2]:
				for z in [-1.4, 1.4]:
					gear.box(Vector3(x, -1.7, z), Vector3(0.3, 1.4, 0.3), EncounterArt.HULL)
					gear.box(Vector3(x, -2.35, z), Vector3(0.9, 0.1, 0.8), EncounterArt.GOLD)
			ship.add_child(gear.build())
			add_child(ship)
			parked_ships.append(ship)
	for i in range(6):
		var angle: float = i * TAU / 6 + PI / 12
		var mount := Node3D.new()
		mount.position = Vector3(cos(angle) * 126, 4 + sin(angle) * 126, 94)
		mount.rotation.z = angle - PI / 2
		add_child(mount)
		var dome := GeometryBatch.new()
		var meridians := PackedVector3Array()
		for arc in range(12):
			var longitude: float = arc * TAU / 12
			for step in range(8):
				var a: float = step * PI / 16
				var b: float = (step + 1) * PI / 16
				meridians.append_array(PackedVector3Array([Vector3(cos(longitude) * cos(a) * 6, sin(a) * 6, sin(longitude) * cos(a) * 6), Vector3(cos(longitude) * cos(b) * 6, sin(b) * 6, sin(longitude) * cos(b) * 6)]))
		for line in range(0, meridians.size(), 2):
			dome.line(meridians[line], meridians[line + 1], EncounterArt.HULL)
		dome.box(Vector3(0, -0.5, 0), Vector3(13, 1, 13), EncounterArt.GOLD)
		mount.add_child(dome.build())
		var rotor := GeometryBatch.new()
		rotor.box(Vector3(0, 2.5, 0), Vector3(9, 0.8, 1.5), VectorArt.CYAN)
		rotor.line(Vector3(0, 0, 0), Vector3(0, 5.5, 0), EncounterArt.GOLD)
		var scanner: Node3D = rotor.build()
		mount.add_child(scanner)
		radar_domes.append(scanner)
	for i in range(4):
		var angle: float = i * TAU / 4
		var mount := Node3D.new()
		mount.position = Vector3(cos(angle) * 125, 4 + sin(angle) * 125, 90)
		mount.rotation.z = angle - PI / 2
		add_child(mount)
		var tower := GeometryBatch.new()
		tower.box(Vector3.ZERO, Vector3(8, 2, 8), EncounterArt.HULL)
		tower.truss(Vector3.ZERO, Vector3(0, 14, 0), 2.0, EncounterArt.HULL, 7)
		for side in [-1.0, 1.0]:
			tower.line(Vector3(side * 3, 0, 0), Vector3(0, 11, 0), EncounterArt.GOLD)
		mount.add_child(tower.build())
		for level in range(2):
			var antenna := GeometryBatch.new()
			antenna.box(Vector3.ZERO, Vector3(14 if level == 0 else 9, 0.9, 1.6), VectorArt.CYAN)
			for slot in range(7):
				antenna.box(Vector3((slot - 3) * (1.7 if level == 0 else 1.1), 0.7, 0), Vector3(0.3, 1.3, 0.5), EncounterArt.GOLD)
			var scanner: Node3D = antenna.build()
			scanner.position.y = 10 + level * 4
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
	for i in range(radar_domes.size()):
		radar_domes[i].rotation.y = age * (0.55 + i * 0.07)
	for i in range(marine_radars.size()):
		marine_radars[i].rotation.y = age * (1.0 if i % 2 == 0 else -0.7) + i
	for i in range(gun_heads.size()):
		gun_heads[i].rotation = Vector3(0.85 + sin(age * 0.35 + i) * 0.25, sin(age * 0.25 + i) * 0.8, 0)
