class_name RuinFall
extends FallingIce

func support_model() -> Node3D:
	var side: float = signf(lane.x)
	var model := FleetArt.model("ruin_corbel", "ground")
	model.scale.x = side
	var origin: Vector3 = FlightState.rail_point(travel)
	model.position = Vector3(origin.x + lane.x, 0, origin.z)
	return model

func falling_model() -> Node3D:
	return FleetArt.model("ruin_keystone", "ground")
