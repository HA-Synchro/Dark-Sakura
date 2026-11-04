extends SceneTree

const SCENE_FLOOR = "res://Models/PSX_Dungeon/Models/FloorTile/floor_tile.tscn"
const SCENE_WALL_STONE = "res://Models/PSX_Dungeon/Models/Wall/wall_stone.tscn"
const SCENE_WALL_BRICK = "res://Models/PSX_Dungeon/Models/WallBrick/wall_brick.tscn"
const SCENE_WALL_RUIN = "res://Models/PSX_Dungeon/Models/WallRuin/wall_ruin.tscn"
const SCENE_SKULL_WALL = "res://Models/PSX_Dungeon/Models/SkullWall/skull_wall.tscn"
const SCENE_ARCH = "res://Models/PSX_Dungeon/Models/Arch/arch.tscn"
const SCENE_ARCH_ROOF = "res://Models/PSX_Dungeon/Models/ArchRoof/arch_roof.tscn"
const SCENE_PILLAR = "res://Models/PSX_Dungeon/Models/Pillar/pillar.tscn"
const SCENE_PILLAR_RUIN = "res://Models/PSX_Dungeon/Models/PillarRuin/pillar_ruin.tscn"
const SCENE_BARREL = "res://Models/PSX_Dungeon/Models/Barrel/barrel.tscn"
const SCENE_CRATE = "res://Models/PSX_Dungeon/Models/Crate/crate.tscn"
const SCENE_CANDLE = "res://Models/PSX_Dungeon/Models/Candle/candle.tscn"
const SCENE_CHANDELIER = "res://Models/PSX_Dungeon/Models/Chandlier/chandelier.tscn"
const SCENE_CHEST = "res://Models/PSX_Dungeon/Models/Chest/chest.tscn"

const SCENE_PLAYER = "res://Scenes/Player/player.tscn"
const SCENE_SEAL = "res://Scenes/Gameplay/seal_pickup.tscn"
const SCENE_CHONCHON = "res://Scenes/Enemies/enemy_chonchon.tscn"
const SCENE_WRAPPER = "res://Scenes/Enemies/enemy_wrapper.tscn"
const SCENE_ABERRATION = "res://Scenes/Enemies/enemy_aberration.tscn"
const SCENE_WORLD_ENV = "res://Scenes/Environment/dark_sakura_world.tscn"
const SCENE_POST_PROCESS = "res://Scenes/Environment/psx_post_process.tscn"
const SCENE_PETALS = "res://Scenes/Effects/sakura_petals.tscn"
const SCENE_PAUSE_MENU = "res://Scenes/UI/pause_menu.tscn"

const OUTPUT_PATH = "res://Scenes/Dungeon/dungeon.tscn"

func _init() -> void:
	print("Starting Dungeon generation: Big Labyrinth Map (Narrow Winding Paths & Landmark Rooms)...")
	var err = generate_dungeon()
	if err == OK:
		print("Successfully generated and saved labyrinth dungeon to: ", OUTPUT_PATH)
	else:
		printerr("Failed to generate dungeon! Error: ", err)
	quit(err)

func generate_dungeon() -> Error:
	var root := Node3D.new()
	root.name = "Dungeon"
	var dm_script = load("res://Scripts/Dungeon/dungeon_manager.gd")
	if dm_script:
		root.set_script(dm_script)

	# 1. Environment & Post-processing
	var env_scn = load(SCENE_WORLD_ENV)
	if env_scn:
		var env_inst = env_scn.instantiate()
		root.add_child(env_inst)
		env_inst.owner = root

	var pp_scn = load(SCENE_POST_PROCESS)
	if pp_scn:
		var pp_inst = pp_scn.instantiate()
		root.add_child(pp_inst)
		pp_inst.owner = root

	var petals_scn = load(SCENE_PETALS)
	if petals_scn:
		var petals_inst = petals_scn.instantiate()
		root.add_child(petals_inst)
		petals_inst.owner = root

	var pm_scn = load(SCENE_PAUSE_MENU)
	if pm_scn:
		var pm_inst = pm_scn.instantiate()
		root.add_child(pm_inst)
		pm_inst.owner = root

	# 2. Objective HUD
	var hud := CanvasLayer.new()
	hud.name = "ObjectiveHUD"
	hud.layer = 5
	root.add_child(hud)
	hud.owner = root

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.offset_left = 32
	margin.offset_top = 32
	hud.add_child(margin)
	margin.owner = root

	var obj_label := Label.new()
	obj_label.name = "ObjectiveLabel"
	obj_label.text = "CURSED SEALS: 0 / 2\n• West: Catacombs of Thorns\n• East: Flooded Shrine"
	obj_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.85, 1.0))
	obj_label.add_theme_color_override("font_shadow_color", Color(0.15, 0.02, 0.08, 0.9))
	obj_label.add_theme_constant_override("shadow_offset_x", 2)
	obj_label.add_theme_constant_override("shadow_offset_y", 2)
	obj_label.add_theme_font_size_override("font_size", 16)
	margin.add_child(obj_label)
	obj_label.owner = root

	var center := CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_CENTER_TOP)
	center.offset_top = 80
	hud.add_child(center)
	center.owner = root

	var banner_label := Label.new()
	banner_label.name = "BannerLabel"
	banner_label.text = ""
	banner_label.modulate.a = 0.0
	banner_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.55, 1.0))
	banner_label.add_theme_color_override("font_shadow_color", Color(0.1, 0.0, 0.05, 0.95))
	banner_label.add_theme_constant_override("shadow_offset_x", 3)
	banner_label.add_theme_constant_override("shadow_offset_y", 3)
	banner_label.add_theme_font_size_override("font_size", 26)
	center.add_child(banner_label)
	banner_label.owner = root

	# 3. Hierarchy Containers
	var floor_container := Node3D.new()
	floor_container.name = "Floor"
	root.add_child(floor_container)
	floor_container.owner = root

	var roof_container := Node3D.new()
	roof_container.name = "Roof"
	root.add_child(roof_container)
	roof_container.owner = root

	var walls_container := Node3D.new()
	walls_container.name = "Walls"
	root.add_child(walls_container)
	walls_container.owner = root

	var doors_container := Node3D.new()
	doors_container.name = "Doorways"
	root.add_child(doors_container)
	doors_container.owner = root

	var pillars_container := Node3D.new()
	pillars_container.name = "Pillars"
	root.add_child(pillars_container)
	pillars_container.owner = root

	var props_container := Node3D.new()
	props_container.name = "Props"
	root.add_child(props_container)
	props_container.owner = root

	var pickups_container := Node3D.new()
	pickups_container.name = "Pickups"
	root.add_child(pickups_container)
	pickups_container.owner = root

	var enemies_container := Node3D.new()
	enemies_container.name = "Enemies"
	root.add_child(enemies_container)
	enemies_container.owner = root

	# Preload scene resources
	var scn_floor = load(SCENE_FLOOR)
	var scn_wall_stone = load(SCENE_WALL_STONE)
	var scn_wall_brick = load(SCENE_WALL_BRICK)
	var scn_wall_ruin = load(SCENE_WALL_RUIN)
	var scn_skull_wall = load(SCENE_SKULL_WALL)
	var scn_arch = load(SCENE_ARCH)
	var scn_arch_roof = load(SCENE_ARCH_ROOF)
	var scn_pillar = load(SCENE_PILLAR)
	var scn_pillar_ruin = load(SCENE_PILLAR_RUIN)
	var scn_barrel = load(SCENE_BARREL)
	var scn_crate = load(SCENE_CRATE)
	var scn_candle = load(SCENE_CANDLE)
	var scn_chandelier = load(SCENE_CHANDELIER)
	var scn_chest = load(SCENE_CHEST)

	# 4. Build Grid Cells: Big Labyrinth Map (Narrow Winding Paths & Few Big Rooms)
	var cells: Dictionary = {} # Vector2i -> true

	# --- ROOM 1: Awakening Chamber (4x4 starting crypt) ---
	for gx in range(-2, 2):
		for gz in range(16, 20):
			cells[Vector2i(gx, gz)] = true

	# --- PATH 1: South Labyrinth (Winding Narrow Corridor, 1 tile wide) ---
	# Corridor north from Awakening exit (0, 16)
	cells[Vector2i(0, 15)] = true
	cells[Vector2i(0, 14)] = true
	# Turns East
	for gx in range(1, 5):
		cells[Vector2i(gx, 14)] = true
	cells[Vector2i(5, 14)] = true # Dead-end alcove
	# Turns North
	cells[Vector2i(4, 13)] = true
	cells[Vector2i(4, 12)] = true
	cells[Vector2i(4, 11)] = true
	# Turns West
	for gx in range(-3, 4):
		cells[Vector2i(gx, 11)] = true
	cells[Vector2i(-4, 11)] = true # Ambush corner alcove
	# Turns North
	for gz in range(7, 11):
		cells[Vector2i(-3, gz)] = true
	# Turns East
	for gx in range(-2, 3):
		cells[Vector2i(gx, 7)] = true
	# Turns North
	for gz in range(3, 7):
		cells[Vector2i(2, gz)] = true
	# Turns West into Hub
	cells[Vector2i(1, 3)] = true
	cells[Vector2i(0, 3)] = true

	# --- ROOM 2: Central Hub (5x5 Crossing of Thorns) ---
	for gx in range(-2, 3):
		for gz in range(-2, 3):
			cells[Vector2i(gx, gz)] = true

	# --- PATH 2: West Labyrinth (The Catacombs of Thorns, 1 tile wide) ---
	# From Hub west exit (-2, 0)
	cells[Vector2i(-3, 0)] = true
	cells[Vector2i(-4, 0)] = true
	cells[Vector2i(-5, 0)] = true
	# Turns North
	for gz in range(-4, 0):
		cells[Vector2i(-5, gz)] = true
	cells[Vector2i(-5, -5)] = true # Ruined ossuary alcove
	# Turns West
	for gx in range(-9, -5):
		cells[Vector2i(gx, -4)] = true
	# Turns South
	for gz in range(-3, 5):
		cells[Vector2i(-9, gz)] = true
	cells[Vector2i(-8, 2)] = true # Side crypt niche
	# Turns West
	for gx in range(-13, -9):
		cells[Vector2i(gx, 4)] = true
	# Turns North
	for gz in range(0, 4):
		cells[Vector2i(-13, gz)] = true
	# Turns West into Crypt
	cells[Vector2i(-14, 0)] = true

	# --- ROOM 3: Catacombs Deep Tomb (5x5 West Sanctuary) ---
	for gx in range(-19, -14):
		for gz in range(-2, 3):
			cells[Vector2i(gx, gz)] = true

	# --- PATH 3: East Labyrinth (The Flooded Passages, 1 tile wide) ---
	# From Hub east exit (2, 0)
	cells[Vector2i(3, 0)] = true
	cells[Vector2i(4, 0)] = true
	cells[Vector2i(5, 0)] = true
	# Turns South
	for gz in range(1, 5):
		cells[Vector2i(5, gz)] = true
	cells[Vector2i(5, 5)] = true # Sunken alcove
	# Turns East
	for gx in range(6, 10):
		cells[Vector2i(gx, 4)] = true
	# Turns North
	for gz in range(-4, 4):
		cells[Vector2i(9, gz)] = true
	cells[Vector2i(10, -2)] = true # Side shrine niche
	# Turns East
	for gx in range(10, 14):
		cells[Vector2i(gx, -4)] = true
	# Turns South
	for gz in range(-3, 1):
		cells[Vector2i(13, gz)] = true
	# Turns East into Shrine
	cells[Vector2i(14, 0)] = true

	# --- ROOM 4: Flooded Shrine Vault (5x5 East Sanctuary) ---
	for gx in range(15, 20):
		for gz in range(-2, 3):
			cells[Vector2i(gx, gz)] = true

	# --- PATH 4: North Path (The Path of Ancient Roots, 1 tile wide beyond Gate) ---
	# From Great Gate (0, -2)
	cells[Vector2i(0, -3)] = true
	cells[Vector2i(0, -4)] = true
	cells[Vector2i(0, -5)] = true
	# Turns West
	for gx in range(-4, 0):
		cells[Vector2i(gx, -5)] = true
	# Turns North
	cells[Vector2i(-4, -6)] = true
	cells[Vector2i(-4, -7)] = true
	cells[Vector2i(-4, -8)] = true
	# Turns East
	for gx in range(-3, 5):
		cells[Vector2i(gx, -8)] = true
	# Turns North
	cells[Vector2i(4, -9)] = true
	cells[Vector2i(4, -10)] = true
	cells[Vector2i(4, -11)] = true
	# Turns West into Arena
	cells[Vector2i(3, -11)] = true
	cells[Vector2i(2, -11)] = true
	cells[Vector2i(1, -11)] = true
	cells[Vector2i(0, -11)] = true
	cells[Vector2i(0, -12)] = true
	cells[Vector2i(0, -13)] = true

	# --- ROOM 5: The Bloom Sanctum Boss Arena (7x8 Colosseum) ---
	for gx in range(-3, 4):
		for gz in range(-21, -13):
			cells[Vector2i(gx, gz)] = true

	print("Total dungeon cells defined: %d (Narrow Paths: ~122, 5 Major Rooms: ~147)" % cells.size())

	# 5. Place Floor Tiles
	var tile_idx := 0
	for cell in cells.keys():
		tile_idx += 1
		var inst: Node3D = scn_floor.instantiate()
		inst.name = "Floor_%d_%d" % [cell.x, cell.y]
		floor_container.add_child(inst)
		inst.owner = root
		inst.position = Vector3(cell.x * 4.0, 0.0, cell.y * 4.0)

	print("Placed %d floor tiles." % tile_idx)

	# 5b. Place Roof Tiles
	var roof_idx := 0
	for cell in cells.keys():
		roof_idx += 1
		var r_inst: Node3D = scn_arch_roof.instantiate()
		r_inst.name = "Roof_%d_%d" % [cell.x, cell.y]
		roof_container.add_child(r_inst)
		r_inst.owner = root
		r_inst.position = Vector3(cell.x * 4.0, 4.0, cell.y * 4.0)

	print("Placed %d roof tiles." % roof_idx)

	# 6. Place Outer Walls (Lower Y=0.0 and Upper Y=4.0 to enclose vaulted roof)
	var wall_idx := 0
	for cell in cells.keys():
		var cx: int = cell.x
		var cz: int = cell.y
		var wx: float = cx * 4.0
		var wz: float = cz * 4.0

		var get_wall_scn = func(gx: int, gz: int, seed_val: int) -> PackedScene:
			if gx <= -4:
				return scn_skull_wall if (seed_val % 2 == 0) else scn_wall_ruin
			elif gx >= 4:
				return scn_wall_brick
			elif gz <= -8:
				return scn_wall_brick if (seed_val % 3 == 0) else scn_wall_stone
			else:
				return scn_wall_stone

		# North neighbor (cz - 1)
		if not cells.has(Vector2i(cx, cz - 1)):
			wall_idx += 1
			var scn = get_wall_scn.call(cx, cz, cx * 7 + cz * 13)
			var w: Node3D = scn.instantiate()
			w.name = "Wall_N_%d_%d" % [cx, cz]
			walls_container.add_child(w)
			w.owner = root
			w.position = Vector3(wx, 0.0, wz - 2.0)
			w.rotation_degrees = Vector3(0, 0, 0)

			var w_up: Node3D = scn.instantiate()
			w_up.name = "Wall_N_Up_%d_%d" % [cx, cz]
			walls_container.add_child(w_up)
			w_up.owner = root
			w_up.position = Vector3(wx, 4.0, wz - 2.0)
			w_up.rotation_degrees = Vector3(0, 0, 0)

		# South neighbor (cz + 1)
		if not cells.has(Vector2i(cx, cz + 1)):
			wall_idx += 1
			var scn = get_wall_scn.call(cx, cz, cx * 11 + cz * 17)
			var w: Node3D = scn.instantiate()
			w.name = "Wall_S_%d_%d" % [cx, cz]
			walls_container.add_child(w)
			w.owner = root
			w.position = Vector3(wx, 0.0, wz + 2.0)
			w.rotation_degrees = Vector3(0, 180, 0)

			var w_up: Node3D = scn.instantiate()
			w_up.name = "Wall_S_Up_%d_%d" % [cx, cz]
			walls_container.add_child(w_up)
			w_up.owner = root
			w_up.position = Vector3(wx, 4.0, wz + 2.0)
			w_up.rotation_degrees = Vector3(0, 180, 0)

		# West neighbor (cx - 1)
		if not cells.has(Vector2i(cx - 1, cz)):
			wall_idx += 1
			var scn = get_wall_scn.call(cx, cz, cx * 19 + cz * 23)
			var w: Node3D = scn.instantiate()
			w.name = "Wall_W_%d_%d" % [cx, cz]
			walls_container.add_child(w)
			w.owner = root
			w.position = Vector3(wx - 2.0, 0.0, wz)
			w.rotation_degrees = Vector3(0, 90, 0)

			var w_up: Node3D = scn.instantiate()
			w_up.name = "Wall_W_Up_%d_%d" % [cx, cz]
			walls_container.add_child(w_up)
			w_up.owner = root
			w_up.position = Vector3(wx - 2.0, 4.0, wz)
			w_up.rotation_degrees = Vector3(0, 90, 0)

		# East neighbor (cx + 1)
		if not cells.has(Vector2i(cx + 1, cz)):
			wall_idx += 1
			var scn = get_wall_scn.call(cx, cz, cx * 29 + cz * 31)
			var w: Node3D = scn.instantiate()
			w.name = "Wall_E_%d_%d" % [cx, cz]
			walls_container.add_child(w)
			w.owner = root
			w.position = Vector3(wx + 2.0, 0.0, wz)
			w.rotation_degrees = Vector3(0, -90, 0)

			var w_up: Node3D = scn.instantiate()
			w_up.name = "Wall_E_Up_%d_%d" % [cx, cz]
			walls_container.add_child(w_up)
			w_up.owner = root
			w_up.position = Vector3(wx + 2.0, 4.0, wz)
			w_up.rotation_degrees = Vector3(0, -90, 0)

	print("Placed %d boundary walls (lower + upper)." % (wall_idx * 2))

	# 7. Place Doorway Arches at Landmark Room Entrances
	var doorways = [
		{"pos": Vector3(0.0, 0, 62.0), "rot": 0.0, "name": "Arch_Awakening_Exit"},
		{"pos": Vector3(0.0, 0, 10.0), "rot": 0.0, "name": "Arch_Hub_South"},
		{"pos": Vector3(-10.0, 0, 0.0), "rot": 90.0, "name": "Arch_Hub_West"},
		{"pos": Vector3(-58.0, 0, 0.0), "rot": 90.0, "name": "Arch_Catacombs_Entry"},
		{"pos": Vector3(10.0, 0, 0.0), "rot": -90.0, "name": "Arch_Hub_East"},
		{"pos": Vector3(58.0, 0, 0.0), "rot": -90.0, "name": "Arch_Shrine_Entry"},
		{"pos": Vector3(0.0, 0, -54.0), "rot": 0.0, "name": "Arch_Sanctum_Entry"}
	]

	for d in doorways:
		var arch: Node3D = scn_arch.instantiate()
		arch.name = d.name
		doors_container.add_child(arch)
		arch.owner = root
		arch.position = d.pos
		arch.rotation_degrees = Vector3(0, d.rot, 0)

	# 8. The Great Gate (North Door of Central Hub at Z = -10.0)
	var gate_arch: Node3D = scn_arch.instantiate()
	gate_arch.name = "Arch_GreatGate"
	doors_container.add_child(gate_arch)
	gate_arch.owner = root
	gate_arch.position = Vector3(0.0, 0, -10.0)
	gate_arch.rotation_degrees = Vector3(0, 0, 0)

	var gate_node := Node3D.new()
	gate_node.name = "Gate"
	gate_node.position = Vector3(0.0, 0, -10.0)
	root.add_child(gate_node)
	gate_node.owner = root

	var portcullis_body := StaticBody3D.new()
	portcullis_body.name = "Portcullis"
	gate_node.add_child(portcullis_body)
	portcullis_body.owner = root

	var port_col := CollisionShape3D.new()
	port_col.name = "CollisionShape3D"
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(3.8, 3.8, 0.4)
	port_col.shape = box_shape
	port_col.position = Vector3(0, 1.9, 0)
	portcullis_body.add_child(port_col)
	port_col.owner = root

	var port_mesh := MeshInstance3D.new()
	port_mesh.name = "PortcullisMesh"
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(3.8, 3.8, 0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.08, 0.14, 1.0)
	mat.roughness = 0.85
	mat.metallic = 0.7
	bmesh.material = mat
	port_mesh.mesh = bmesh
	port_mesh.position = Vector3(0, 1.9, 0)
	portcullis_body.add_child(port_mesh)
	port_mesh.owner = root

	# Rune lights for the Great Gate
	var petal_rune_light := OmniLight3D.new()
	petal_rune_light.name = "GateRunePetal"
	petal_rune_light.position = Vector3(-2.4, 1.8, -9.6)
	petal_rune_light.light_color = Color(1.0, 0.25, 0.7, 1.0)
	petal_rune_light.light_energy = 0.2
	petal_rune_light.omni_range = 5.0
	root.add_child(petal_rune_light)
	petal_rune_light.owner = root

	var blood_rune_light := OmniLight3D.new()
	blood_rune_light.name = "GateRuneBlood"
	blood_rune_light.position = Vector3(2.4, 1.8, -9.6)
	blood_rune_light.light_color = Color(1.0, 0.12, 0.25, 1.0)
	blood_rune_light.light_energy = 0.2
	blood_rune_light.omni_range = 5.0
	root.add_child(blood_rune_light)
	blood_rune_light.owner = root

	# 9. Pillars (Atmospheric Accents in Landmark Rooms)
	var pillar_data = [
		# Awakening Chamber
		{"pos": Vector3(-4.0, 0, 68.0), "type": "pillar"},
		{"pos": Vector3(4.0, 0, 68.0), "type": "pillar"},
		# Central Hub (Pillars)
		{"pos": Vector3(-6.0, 0, -6.0), "type": "pillar"},
		{"pos": Vector3(6.0, 0, -6.0), "type": "pillar"},
		{"pos": Vector3(-6.0, 0, 6.0), "type": "pillar"},
		{"pos": Vector3(6.0, 0, 6.0), "type": "pillar"},
		# Catacombs Deep Tomb (Ruined Pillars)
		{"pos": Vector3(-64.0, 0, -6.0), "type": "ruin"},
		{"pos": Vector3(-64.0, 0, 6.0), "type": "ruin"},
		{"pos": Vector3(-72.0, 0, -6.0), "type": "ruin"},
		{"pos": Vector3(-72.0, 0, 6.0), "type": "ruin"},
		# Flooded Shrine Vault (Pillars)
		{"pos": Vector3(64.0, 0, -6.0), "type": "pillar"},
		{"pos": Vector3(64.0, 0, 6.0), "type": "pillar"},
		{"pos": Vector3(72.0, 0, -6.0), "type": "pillar"},
		{"pos": Vector3(72.0, 0, 6.0), "type": "pillar"},
		# The Bloom Sanctum Arena (Torchlit Colonnade)
		{"pos": Vector3(-8.0, 0, -58.0), "type": "bloom"},
		{"pos": Vector3(8.0, 0, -58.0), "type": "bloom"},
		{"pos": Vector3(-8.0, 0, -66.0), "type": "bloom"},
		{"pos": Vector3(8.0, 0, -66.0), "type": "bloom"},
		{"pos": Vector3(-8.0, 0, -74.0), "type": "bloom"},
		{"pos": Vector3(8.0, 0, -74.0), "type": "bloom"},
		{"pos": Vector3(-4.0, 0, -80.0), "type": "bloom"},
		{"pos": Vector3(4.0, 0, -80.0), "type": "bloom"}
	]

	var pil_idx := 0
	for pd in pillar_data:
		pil_idx += 1
		var is_ruin: bool = (pd.type == "ruin")
		var p_inst: Node3D = (scn_pillar_ruin if is_ruin else scn_pillar).instantiate()
		p_inst.name = "Pillar_%d" % pil_idx
		pillars_container.add_child(p_inst)
		p_inst.owner = root
		p_inst.position = pd.pos

		if pd.type == "bloom":
			var torch := OmniLight3D.new()
			torch.name = "TorchLight"
			torch.position = Vector3(0, 3.5, 0)
			torch.light_color = Color(1.0, 0.28, 0.65, 1.0)
			torch.light_energy = 2.2
			torch.omni_range = 14.0
			p_inst.add_child(torch)
			torch.owner = root

	print("Placed %d pillars." % pil_idx)

	# 10. Chandeliers
	# Central Hub Chandelier
	var ch_inst: Node3D = scn_chandelier.instantiate()
	ch_inst.name = "HubChandelier"
	props_container.add_child(ch_inst)
	ch_inst.owner = root
	ch_inst.position = Vector3(0.0, 4.6, 0.0)

	var ch_light := OmniLight3D.new()
	ch_light.name = "ChandelierLight"
	ch_light.position = Vector3(0, 0.2, 0)
	ch_light.light_color = Color(1.0, 0.72, 0.45, 1.0)
	ch_light.light_energy = 2.5
	ch_light.omni_range = 22.0
	ch_inst.add_child(ch_light)
	ch_light.owner = root

	# Bloom Sanctum Chandelier
	var bs_ch: Node3D = scn_chandelier.instantiate()
	bs_ch.name = "SanctumChandelier"
	props_container.add_child(bs_ch)
	bs_ch.owner = root
	bs_ch.position = Vector3(0.0, 4.6, -70.0)

	var bs_light := OmniLight3D.new()
	bs_light.name = "SanctumLight"
	bs_light.position = Vector3(0, 0.2, 0)
	bs_light.light_color = Color(1.0, 0.35, 0.7, 1.0)
	bs_light.light_energy = 3.5
	bs_light.omni_range = 28.0
	bs_ch.add_child(bs_light)
	bs_light.owner = root

	# 11. Props & Atmospheric Candles
	# Awakening Chamber Props
	var barrel1: Node3D = scn_barrel.instantiate()
	barrel1.name = "AwakeningBarrel1"
	props_container.add_child(barrel1)
	barrel1.owner = root
	barrel1.position = Vector3(-6.0, 0.0, 74.0)

	var crate1: Node3D = scn_crate.instantiate()
	crate1.name = "AwakeningCrate1"
	props_container.add_child(crate1)
	crate1.owner = root
	crate1.position = Vector3(6.0, 0.0, 74.0)

	var candle1: Node3D = scn_candle.instantiate()
	candle1.name = "AwakeningCandle1"
	props_container.add_child(candle1)
	candle1.owner = root
	candle1.position = Vector3(6.0, 1.6, 74.0)

	var clight1 := OmniLight3D.new()
	clight1.name = "CandleLight"
	clight1.position = Vector3(0, 0.5, 0)
	clight1.light_color = Color(1.0, 0.65, 0.35, 1.0)
	clight1.light_energy = 1.6
	clight1.omni_range = 8.0
	candle1.add_child(clight1)
	clight1.owner = root

	# Narrow Path Candles (Atmospheric Guidance along twists and turns)
	var path_candles = [
		{"pos": Vector3(16.0, 0.0, 56.0), "name": "Candle_SouthTurn1"},
		{"pos": Vector3(-12.0, 0.0, 44.0), "name": "Candle_SouthCorner"},
		{"pos": Vector3(8.0, 0.0, 14.0), "name": "Candle_HubSouthApproach"},
		{"pos": Vector3(-20.0, 0.0, -16.0), "name": "Candle_WestTurn1"},
		{"pos": Vector3(-36.0, 0.0, 16.0), "name": "Candle_WestAlcove"},
		{"pos": Vector3(-52.0, 0.0, 0.0), "name": "Candle_CatacombsDoor"},
		{"pos": Vector3(20.0, 0.0, 16.0), "name": "Candle_EastTurn1"},
		{"pos": Vector3(36.0, 0.0, -16.0), "name": "Candle_EastAlcove"},
		{"pos": Vector3(52.0, 0.0, 0.0), "name": "Candle_ShrineDoor"},
		{"pos": Vector3(-16.0, 0.0, -20.0), "name": "Candle_NorthTurn1"},
		{"pos": Vector3(16.0, 0.0, -32.0), "name": "Candle_NorthTurn2"},
		{"pos": Vector3(0.0, 0.0, -50.0), "name": "Candle_SanctumGateApproach"}
	]

	for pc in path_candles:
		var c_inst: Node3D = scn_candle.instantiate()
		c_inst.name = pc.name
		props_container.add_child(c_inst)
		c_inst.owner = root
		c_inst.position = pc.pos

		var cl := OmniLight3D.new()
		cl.name = "CandleLight"
		cl.position = Vector3(0, 0.5, 0)
		cl.light_color = Color(1.0, 0.55, 0.38, 1.0)
		cl.light_energy = 1.5
		cl.omni_range = 8.0
		c_inst.add_child(cl)
		cl.owner = root

	# Catacombs Altar & Pedestal
	var catacombs_pedestal := MeshInstance3D.new()
	catacombs_pedestal.name = "CatacombsPedestal"
	var ped_mesh := CylinderMesh.new()
	ped_mesh.top_radius = 1.0
	ped_mesh.bottom_radius = 1.2
	ped_mesh.height = 0.5
	catacombs_pedestal.mesh = ped_mesh
	catacombs_pedestal.position = Vector3(-68.0, 0.25, 0.0)
	props_container.add_child(catacombs_pedestal)
	catacombs_pedestal.owner = root

	var catacombs_candle: Node3D = scn_candle.instantiate()
	catacombs_candle.name = "CatacombsCandle"
	props_container.add_child(catacombs_candle)
	catacombs_candle.owner = root
	catacombs_candle.position = Vector3(-68.0, 0.5, 1.5)

	var clight_cat := OmniLight3D.new()
	clight_cat.name = "CandleLight"
	clight_cat.position = Vector3(0, 0.5, 0)
	clight_cat.light_color = Color(1.0, 0.25, 0.7, 1.0)
	clight_cat.light_energy = 2.4
	clight_cat.omni_range = 12.0
	catacombs_candle.add_child(clight_cat)
	clight_cat.owner = root

	# Flooded Shrine Altar, Chest & Candles
	var shrine_pedestal := MeshInstance3D.new()
	shrine_pedestal.name = "ShrinePedestal"
	shrine_pedestal.mesh = ped_mesh
	shrine_pedestal.position = Vector3(68.0, 0.25, 0.0)
	props_container.add_child(shrine_pedestal)
	shrine_pedestal.owner = root

	var chest_inst: Node3D = scn_chest.instantiate()
	chest_inst.name = "ShrineChest"
	props_container.add_child(chest_inst)
	chest_inst.owner = root
	chest_inst.position = Vector3(64.0, 0.0, 5.0)
	chest_inst.rotation_degrees = Vector3(0, 180, 0)

	var shrine_candle: Node3D = scn_candle.instantiate()
	shrine_candle.name = "ShrineCandle"
	props_container.add_child(shrine_candle)
	shrine_candle.owner = root
	shrine_candle.position = Vector3(68.0, 0.5, 1.5)

	var clight_shr := OmniLight3D.new()
	clight_shr.name = "CandleLight"
	clight_shr.position = Vector3(0, 0.5, 0)
	clight_shr.light_color = Color(1.0, 0.15, 0.3, 1.0)
	clight_shr.light_energy = 2.4
	clight_shr.omni_range = 12.0
	shrine_candle.add_child(clight_shr)
	clight_shr.owner = root

	# Bloom Sanctum Center Altar
	var sanctum_altar := MeshInstance3D.new()
	sanctum_altar.name = "SanctumAltar"
	var altar_box := BoxMesh.new()
	altar_box.size = Vector3(4.0, 0.4, 4.0)
	sanctum_altar.mesh = altar_box
	sanctum_altar.position = Vector3(0.0, 0.2, -70.0)
	props_container.add_child(sanctum_altar)
	sanctum_altar.owner = root

	var sanctum_aura := OmniLight3D.new()
	sanctum_aura.name = "SanctumAuraLight"
	sanctum_aura.position = Vector3(0.0, 2.5, -70.0)
	sanctum_aura.light_color = Color(1.0, 0.2, 0.6, 1.0)
	sanctum_aura.light_energy = 4.2
	sanctum_aura.omni_range = 22.0
	props_container.add_child(sanctum_aura)
	sanctum_aura.owner = root

	# 12. Interactive Pickups
	var scn_seal_pickup = load(SCENE_SEAL)
	if scn_seal_pickup:
		# Seal of Petals (West Catacombs Deep Tomb)
		var seal_petals: Area3D = scn_seal_pickup.instantiate()
		seal_petals.name = "SealOfPetals"
		seal_petals.set("seal_name", "Seal of Petals")
		seal_petals.set("glow_color", Color(1.0, 0.25, 0.7, 1.0))
		pickups_container.add_child(seal_petals)
		seal_petals.owner = root
		seal_petals.position = Vector3(-68.0, 0.6, 0.0)
		seal_petals.add_to_group("seals")

		# Seal of Blood (East Flooded Shrine Vault)
		var seal_blood: Area3D = scn_seal_pickup.instantiate()
		seal_blood.name = "SealOfBlood"
		seal_blood.set("seal_name", "Seal of Blood")
		seal_blood.set("glow_color", Color(1.0, 0.12, 0.25, 1.0))
		pickups_container.add_child(seal_blood)
		seal_blood.owner = root
		seal_blood.position = Vector3(68.0, 0.6, 0.0)
		seal_blood.add_to_group("seals")

		print("Placed 2 Seal Pickups in group 'seals'.")

	# 13. Place Enlarged Enemies tactically across narrow choke points and chambers
	var scn_chonchon = load(SCENE_CHONCHON)
	var scn_wrapper = load(SCENE_WRAPPER)
	var scn_aberration = load(SCENE_ABERRATION)

	var enemy_spawns = [
		# South Labyrinth (Narrow Hall Ambush & Corners)
		{"scene": scn_chonchon, "name": "Chonchon_SouthHall1", "pos": Vector3(16.0, 1.6, 56.0), "rot": 0.0},
		{"scene": scn_chonchon, "name": "Chonchon_SouthCorner", "pos": Vector3(-16.0, 1.6, 44.0), "rot": 45.0},
		{"scene": scn_wrapper, "name": "Wrapper_SouthStalker", "pos": Vector3(8.0, 0.1, 16.0), "rot": 180.0},

		# Central Hub
		{"scene": scn_chonchon, "name": "Chonchon_Hub1", "pos": Vector3(-4.0, 1.8, -4.0), "rot": 45.0},
		{"scene": scn_chonchon, "name": "Chonchon_Hub2", "pos": Vector3(4.0, 1.8, 4.0), "rot": 180.0},
		{"scene": scn_wrapper, "name": "Wrapper_HubGateProwler", "pos": Vector3(0.0, 0.1, -4.0), "rot": 0.0},

		# West Labyrinth & Catacombs Tomb
		{"scene": scn_wrapper, "name": "Wrapper_WestOssuary", "pos": Vector3(-20.0, 0.1, -16.0), "rot": 90.0},
		{"scene": scn_chonchon, "name": "Chonchon_WestCorridor", "pos": Vector3(-36.0, 1.6, -16.0), "rot": 90.0},
		{"scene": scn_wrapper, "name": "Wrapper_WestTunnelGuard", "pos": Vector3(-32.0, 0.1, 8.0), "rot": 0.0},
		{"scene": scn_chonchon, "name": "Chonchon_CryptEntry", "pos": Vector3(-52.0, 1.6, 0.0), "rot": 90.0},
		{"scene": scn_chonchon, "name": "Chonchon_Crypt1", "pos": Vector3(-64.0, 1.8, -4.0), "rot": 45.0},
		{"scene": scn_chonchon, "name": "Chonchon_Crypt2", "pos": Vector3(-64.0, 1.8, 4.0), "rot": 135.0},
		{"scene": scn_wrapper, "name": "Wrapper_SealPetalGuard", "pos": Vector3(-66.0, 0.1, 0.0), "rot": 90.0},

		# East Labyrinth & Flooded Shrine Vault
		{"scene": scn_wrapper, "name": "Wrapper_EastFlooded", "pos": Vector3(20.0, 0.1, 16.0), "rot": -90.0},
		{"scene": scn_chonchon, "name": "Chonchon_EastCorridor", "pos": Vector3(36.0, 1.6, 16.0), "rot": -90.0},
		{"scene": scn_wrapper, "name": "Wrapper_EastTunnelGuard", "pos": Vector3(40.0, 0.1, -8.0), "rot": 180.0},
		{"scene": scn_chonchon, "name": "Chonchon_ShrineEntry", "pos": Vector3(52.0, 1.6, 0.0), "rot": -90.0},
		{"scene": scn_chonchon, "name": "Chonchon_Shrine1", "pos": Vector3(64.0, 1.8, -4.0), "rot": -45.0},
		{"scene": scn_chonchon, "name": "Chonchon_Shrine2", "pos": Vector3(64.0, 1.8, 4.0), "rot": -135.0},
		{"scene": scn_wrapper, "name": "Wrapper_SealBloodGuard", "pos": Vector3(66.0, 0.1, 0.0), "rot": -90.0},

		# North Path of Roots
		{"scene": scn_chonchon, "name": "Chonchon_RootPath1", "pos": Vector3(-16.0, 1.6, -20.0), "rot": 45.0},
		{"scene": scn_wrapper, "name": "Wrapper_RootCorner", "pos": Vector3(16.0, 0.1, -32.0), "rot": 0.0},
		{"scene": scn_chonchon, "name": "Chonchon_SanctumThreshold", "pos": Vector3(0.0, 1.6, -48.0), "rot": 0.0},

		# The Bloom Sanctum (Finale Arena)
		{"scene": scn_aberration, "name": "EnemyAberration", "pos": Vector3(0.0, 0.1, -74.0), "rot": 0.0},
		{"scene": scn_chonchon, "name": "Chonchon_Sanctum1", "pos": Vector3(-8.0, 1.8, -64.0), "rot": 45.0},
		{"scene": scn_chonchon, "name": "Chonchon_Sanctum2", "pos": Vector3(8.0, 1.8, -64.0), "rot": -45.0},
		{"scene": scn_chonchon, "name": "Chonchon_Sanctum3", "pos": Vector3(-8.0, 1.8, -76.0), "rot": 135.0},
		{"scene": scn_chonchon, "name": "Chonchon_Sanctum4", "pos": Vector3(8.0, 1.8, -76.0), "rot": -135.0},
		{"scene": scn_wrapper, "name": "Wrapper_Sanctum1", "pos": Vector3(-5.0, 0.1, -70.0), "rot": 0.0},
		{"scene": scn_wrapper, "name": "Wrapper_Sanctum2", "pos": Vector3(5.0, 0.1, -70.0), "rot": 0.0}
	]

	for espawn in enemy_spawns:
		if espawn.scene:
			var e_inst: CharacterBody3D = espawn.scene.instantiate()
			e_inst.name = espawn.name
			enemies_container.add_child(e_inst)
			e_inst.owner = root
			e_inst.position = espawn.pos
			e_inst.rotation_degrees = Vector3(0, espawn.rot, 0)

	print("Placed %d enlarged enemies across the labyrinth and chambers." % enemy_spawns.size())

	# 14. Player Spawn (In Awakening Crypt facing North toward labyrinth)
	var scn_player = load(SCENE_PLAYER)
	if scn_player:
		var player_inst: CharacterBody3D = scn_player.instantiate()
		player_inst.name = "Player"
		root.add_child(player_inst)
		player_inst.owner = root
		player_inst.position = Vector3(0.0, 0.5, 70.0)
		player_inst.rotation_degrees = Vector3(0, 180, 0)
		print("Placed Player at (0, 0.5, 70) facing North.")

	# 15. Save Packed Scene
	var packed := PackedScene.new()
	var pack_err = packed.pack(root)
	if pack_err != OK:
		printerr("Failed to pack scene! Error: ", pack_err)
		return pack_err

	var save_err = ResourceSaver.save(packed, OUTPUT_PATH)
	return save_err
