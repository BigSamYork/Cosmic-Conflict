class_name XyloField
extends FrostField

enum Kind { ACID, SPORES }
const ACID_DAMAGE: float = 18.0
var kind: Kind = Kind.ACID

func _ready() -> void:
	var batch := GeometryBatch.new()
	var points := PackedVector3Array()
	for i in range(32):
		var angle: float = i * TAU / 32
		points.append(Vector3(cos(angle) * RADIUS, 0.15, sin(angle) * RADIUS))
	batch.outline(points, XyloArt.ACID if kind == Kind.ACID else XyloArt.LEAF)
	for i in range(6):
		var angle: float = i * TAU / 6
		batch.ellipsoid(Vector3(cos(angle) * 2.5, 0.2, sin(angle) * 2.5), Vector3(0.7, 0.5, 0.7), XyloArt.LEAF, 4, 6)
	ring = batch.build()
	add_child(ring)
	plume = XyloArt.acid_plume() if kind == Kind.ACID else XyloArt.spore_plume()
	add_child(plume)
	_update_visual()
