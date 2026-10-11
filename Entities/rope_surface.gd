@tool
extends MeshInstance3D
## Draws a continuous rope surface over the editable physics-link chain.
## The RigidBody3D links remain responsible for motion and collision.

@export_range(0.005, 0.05, 0.001) var rope_radius := 0.018
@export_range(3, 16, 1) var radial_segments := 8
@export_range(2, 12, 1) var subdivisions_per_link := 5
@export_range(0.4, 0.8, 0.01) var grip_clearance := 0.68
@export var rope_color := Color(0.43, 0.29, 0.16)
@export var blue_grip_color := Color(0.08, 0.35, 0.95)
@export var white_grip_color := Color(0.95, 0.95, 0.95)

var _rope_material: StandardMaterial3D
var _blue_grip_material: StandardMaterial3D
var _white_grip_material: StandardMaterial3D


func _ready() -> void:
	_rope_material = StandardMaterial3D.new()
	_rope_material.albedo_color = rope_color
	_rope_material.roughness = 0.9
	_blue_grip_material = StandardMaterial3D.new()
	_blue_grip_material.albedo_color = blue_grip_color
	_blue_grip_material.roughness = 0.85
	_white_grip_material = StandardMaterial3D.new()
	_white_grip_material.albedo_color = white_grip_color
	_white_grip_material.roughness = 0.85
	set_process(true)
	_update_rope_mesh()


func _process(_delta: float) -> void:
	_update_rope_mesh()


func _update_rope_mesh() -> void:
	var rope_root := get_parent()
	if not rope_root:
		return

	var points: Array[Vector3] = []
	var grip_indices: Array[int] = []
	var grip_materials: Array[StandardMaterial3D] = []
	var has_bottom_grip := false
	var anchor := rope_root.get_node_or_null("CeilingAnchor") as Node3D
	if anchor:
		points.append(to_local(anchor.global_position))

	for child in rope_root.get_children():
		if child is RigidBody3D:
			var body := child as RigidBody3D
			points.append(to_local(body.global_position))
			if body.name == "RopeGripBlue":
				grip_indices.append(points.size() - 1)
				grip_materials.append(_blue_grip_material)
			elif body.name == "RopeBottomGripWhite":
				grip_indices.append(points.size() - 1)
				grip_materials.append(_white_grip_material)
				has_bottom_grip = true

	if has_bottom_grip and points.size() >= 2:
		var tail_direction := (points[points.size() - 1] - points[points.size() - 2]).normalized()
		points.append(points[points.size() - 1] + tail_direction * 0.108)

	var generated := ArrayMesh.new()
	if points.size() < 2:
		mesh = generated
		return

	var samples: Array[Vector3] = []
	var parameters: Array[float] = []
	for edge in range(points.size() - 1):
		for step in range(subdivisions_per_link):
			var t := float(edge) + float(step) / float(subdivisions_per_link)
			samples.append(_sample_curve(points, t))
			parameters.append(t)
	samples.append(points[points.size() - 1])
	parameters.append(float(points.size() - 1))

	var active_material := _material_at_parameter(
		(parameters[0] + parameters[1]) * 0.5, grip_indices, grip_materials)
	var run: Array[Vector3] = [samples[0]]
	for i in range(samples.size() - 1):
		if i > 0:
			var next_material := _material_at_parameter(
				(parameters[i] + parameters[i + 1]) * 0.5,
				grip_indices,
				grip_materials)
			if next_material != active_material:
				_add_tube_run(generated, run, active_material)
				run = [samples[i]]
				active_material = next_material
		run.append(samples[i + 1])
	_add_tube_run(generated, run, active_material)
	mesh = generated


func _sample_curve(points: Array[Vector3], t: float) -> Vector3:
	var start := mini(int(floor(t)), points.size() - 2)
	var weight := t - float(start)
	var p0 := points[maxi(start - 1, 0)]
	var p1 := points[start]
	var p2 := points[start + 1]
	var p3 := points[mini(start + 2, points.size() - 1)]
	var weight2 := weight * weight
	var weight3 := weight2 * weight
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * weight + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * weight2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * weight3)


func _material_at_parameter(
		parameter: float,
		grip_indices: Array[int],
		grip_materials: Array[StandardMaterial3D]) -> StandardMaterial3D:
	for i in range(grip_indices.size()):
		if grip_materials[i] == _white_grip_material:
			if parameter >= float(grip_indices[i]) - grip_clearance:
				return _white_grip_material
		if absf(parameter - float(grip_indices[i])) < grip_clearance:
			return grip_materials[i]
	return _rope_material


func _add_tube_run(
		target: ArrayMesh,
		centers: Array[Vector3],
		section_material: StandardMaterial3D) -> void:
	if centers.size() < 2:
		return

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in range(centers.size()):
		var before := centers[maxi(i - 1, 0)]
		var after := centers[mini(i + 1, centers.size() - 1)]
		var tangent := (after - before).normalized()
		if tangent.length_squared() < 0.000001:
			tangent = Vector3.DOWN
		var reference := Vector3.RIGHT
		if absf(tangent.dot(reference)) > 0.9:
			reference = Vector3.FORWARD
		var side := tangent.cross(reference).normalized()
		var up := tangent.cross(side).normalized()
		for j in range(radial_segments):
			var angle := TAU * float(j) / float(radial_segments)
			var normal := (side * cos(angle) + up * sin(angle)).normalized()
			vertices.append(centers[i] + normal * rope_radius)
			normals.append(normal)

	for ring in range(centers.size() - 1):
		for side_index in range(radial_segments):
			var next_side := (side_index + 1) % radial_segments
			var a := ring * radial_segments + side_index
			var b := (ring + 1) * radial_segments + side_index
			var c := (ring + 1) * radial_segments + next_side
			var d := ring * radial_segments + next_side
			indices.append_array(PackedInt32Array([a, b, c, a, c, d]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var surface_index := target.get_surface_count()
	target.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	target.surface_set_material(surface_index, section_material)
