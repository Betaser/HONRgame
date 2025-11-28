class_name FrogSpawner extends Node

var start_time: float
var spawn_rate: float
var wave_spawn_locs: Array[Vector2]

var frogs: Array[Frog]
var level_ref: WeakRef = null

var spawn_areas: Array[CollisionShape2D]

func get_level() -> TestLevel:
	return get_parent()

signal initialized

func init(_start_time: float, _wave_spawn_locs: Array[Vector2], _frogs: Array[Frog], _level: TestLevel, _spawn_rate: float = 1.0) -> void:
	wave_spawn_locs = _wave_spawn_locs
	start_time = _start_time
	frogs = _frogs
	spawn_rate = _spawn_rate

	level_ref = weakref(_level)

	spawn_areas = []
	for child in get_children():
		if child is Area2D:
			var collision_shape := child.get_child(0) as CollisionShape2D
			spawn_areas.append(collision_shape)

	initialized.emit()

func _process(delta: float) -> void:
	# _process can be called before the custom init function runs in TestLevel
	if spawn_areas.size() == 0:
		return
	
	var n_spawns := int(start_time / spawn_rate)

	if n_spawns > frogs.size() - 1 && frogs.size() < 7:
		var spawn_loc := wave_spawn_locs[n_spawns % len(wave_spawn_locs)] * get_level().size

		# Choose the spawn area that's closest
		var shortest := INF
		var spawn_area: CollisionShape2D = null
		for area in spawn_areas:
			var dist := (area.position - spawn_loc).length()
			if dist < shortest:
				shortest = dist
				spawn_area = area

		# Let's have the original spawn location of frogs be determined by some fixed points?

		var frog := get_level().ref_frog.duplicate()
		frog.visible = true
		get_level().add_child(frog)
		frog.start_leap = true
		# IT IS GIVEN NORMALIZED
		frog.wavespawner_loc = spawn_loc

		# For debugging purposes, place frog at random location
		var offset := Vector2.from_angle(randf_range(0, 2 * PI)) * randf_range(0, spawn_area.shape.radius)
		var pos := offset + spawn_area.position

		frog.position = pos

		frogs.append(frog)
		# spawn_frog(spawn_loc)

	start_time += delta
