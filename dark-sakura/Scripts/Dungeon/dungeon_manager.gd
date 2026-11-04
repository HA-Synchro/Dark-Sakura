extends Node3D
class_name DungeonManager

signal seal_status_updated(collected_count: int, total_count: int)
signal sanctum_unlocked
signal game_won

@export var required_seals: int = 2
var collected_seals: int = 0
var is_victory: bool = false

@onready var gate: Node3D = get_node_or_null("Gate")
@onready var objective_label: Label = get_node_or_null("ObjectiveHUD/MarginContainer/ObjectiveLabel")
@onready var banner_label: Label = get_node_or_null("ObjectiveHUD/CenterContainer/BannerLabel")
@onready var petal_rune: OmniLight3D = get_node_or_null("GateRunePetal")
@onready var blood_rune: OmniLight3D = get_node_or_null("GateRuneBlood")
@onready var objective_hud: CanvasLayer = get_node_or_null("ObjectiveHUD")

const SFX_SEAL = preload("res://Audio/SFX/seal_pickup.wav")
const SFX_AMBIENT_DRONE = preload("res://Audio/SFX/ambient_drone.wav")
const SCENE_PAUSE_MENU = preload("res://Scenes/UI/pause_menu.tscn")

var _victory_screen: Control
var _portal_root: Node3D

func _ready() -> void:
	_setup_ambient_drone()
	_setup_pause_menu()
	_setup_victory_ui()
	_update_objective_text()
	
	if banner_label:
		banner_label.modulate.a = 0.0
	
	# Connect seals
	for seal in get_tree().get_nodes_in_group("seals"):
		if seal.has_signal("seal_collected"):
			seal.seal_collected.connect(_on_seal_collected)
	
	# Connect boss
	var boss = find_child("EnemyAberration", true, false)
	if boss and boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)

func _setup_ambient_drone() -> void:
	var existing = get_node_or_null("AmbientDrone")
	if not existing:
		var drone := AudioStreamPlayer.new()
		drone.name = "AmbientDrone"
		drone.stream = SFX_AMBIENT_DRONE
		drone.volume_db = -5.0
		drone.autoplay = true
		drone.bus = "Master"
		add_child(drone)
		drone.play()

func _setup_pause_menu() -> void:
	var existing = get_node_or_null("PauseMenu")
	if not existing:
		var pm = SCENE_PAUSE_MENU.instantiate()
		pm.name = "PauseMenu"
		add_child(pm)

func _setup_victory_ui() -> void:
	if not objective_hud:
		return
	
	_victory_screen = Control.new()
	_victory_screen.name = "VictoryScreen"
	_victory_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_victory_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_screen.visible = false
	_victory_screen.modulate.a = 0.0
	objective_hud.add_child(_victory_screen)
	
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color(0.04, 0.01, 0.03, 0.88)
	_victory_screen.add_child(bg)
	
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_victory_screen.add_child(center)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)
	
	var title := Label.new()
	title.text = "SANCTUM PURGED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.65, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)
	
	var subtitle := Label.new()
	subtitle.text = "THE PARASITIC GOD IS SHATTERED\nYOU ESCAPED THE DARK SAKURA"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.92, 0.85, 0.88, 1.0))
	subtitle.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	subtitle.add_theme_constant_override("shadow_offset_x", 2)
	subtitle.add_theme_constant_override("shadow_offset_y", 2)
	subtitle.add_theme_font_size_override("font_size", 18)
	vbox.add_child(subtitle)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	vbox.add_child(spacer)
	
	var restart := Label.new()
	restart.text = "[ R ]  PLAY AGAIN  •  [ M ]  MAIN MENU"
	restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	restart.add_theme_color_override("font_shadow_color", Color(0.2, 0.1, 0.0, 0.95))
	restart.add_theme_constant_override("shadow_offset_x", 2)
	restart.add_theme_constant_override("shadow_offset_y", 2)
	restart.add_theme_font_size_override("font_size", 22)
	vbox.add_child(restart)

func _unhandled_input(event: InputEvent) -> void:
	if is_victory:
		if (event is InputEventKey and event.pressed and (event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)) or Input.is_action_just_pressed("reload"):
			get_tree().reload_current_scene()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_M:
			get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")

func _on_boss_died() -> void:
	_show_banner("THE ROOT EXECUTIONER IS SLAIN!")
	if objective_label:
		objective_label.text = "SANCTUM PURGED\nEnter the Radiant Torii Portal to escape!"
	_spawn_escape_portal()

func _spawn_escape_portal() -> void:
	if _portal_root:
		return
	
	_portal_root = Node3D.new()
	_portal_root.name = "SanctumEscapePortal"
	_portal_root.position = Vector3(0.0, 0.0, -82.0)
	add_child(_portal_root)
	
	# Portal Beacon Light
	var beacon := OmniLight3D.new()
	beacon.light_color = Color(1.0, 0.35, 0.75, 1.0)
	beacon.light_energy = 5.0
	beacon.omni_range = 14.0
	beacon.position = Vector3(0.0, 2.0, 0.0)
	_portal_root.add_child(beacon)
	
	# Radiant Pillar mesh
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.4
	cyl.bottom_radius = 1.4
	cyl.height = 4.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.4, 0.7, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	mesh_inst.position = Vector3(0.0, 2.0, 0.0)
	_portal_root.add_child(mesh_inst)
	
	# Trigger Area
	var area := Area3D.new()
	area.name = "EscapeArea"
	area.collision_layer = 0
	area.collision_mask = 1 # Player layer
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 2.2
	shape.height = 4.0
	col.shape = shape
	col.position = Vector3(0.0, 2.0, 0.0)
	area.add_child(col)
	_portal_root.add_child(area)
	
	area.body_entered.connect(_on_escape_area_entered)

func _on_escape_area_entered(body: Node) -> void:
	if is_victory:
		return
	if body.is_in_group("player") or body.name == "Player":
		_trigger_victory()

func _trigger_victory() -> void:
	is_victory = true
	emit_signal("game_won")
	
	# Sound chime
	var aud := AudioStreamPlayer.new()
	aud.stream = SFX_SEAL
	aud.volume_db = 2.0
	add_child(aud)
	aud.play()
	
	_show_banner("ESCAPED THE DARK SAKURA!")
	
	if _victory_screen:
		_victory_screen.visible = true
		_victory_screen.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_victory_screen, "modulate:a", 1.0, 1.2)

func _on_seal_collected(seal_name: String) -> void:
	collected_seals += 1
	if "Petal" in seal_name and petal_rune:
		petal_rune.light_energy = 3.5
	elif "Blood" in seal_name and blood_rune:
		blood_rune.light_energy = 3.5

	# Play ethereal seal pickup chime
	var aud = AudioStreamPlayer.new()
	aud.stream = SFX_SEAL
	aud.volume_db = 1.0
	add_child(aud)
	aud.play()
	aud.finished.connect(aud.queue_free)

	_show_banner("ACQUIRED: " + seal_name.to_upper())
	emit_signal("seal_status_updated", collected_seals, required_seals)
	_update_objective_text()
	
	if collected_seals >= required_seals:
		_unlock_sanctum()

func _update_objective_text() -> void:
	if not objective_label:
		return
	if collected_seals < required_seals:
		objective_label.text = "CURSED SEALS: %d / %d\n• West: Catacombs of Thorns\n• East: Flooded Shrine" % [collected_seals, required_seals]
	else:
		objective_label.text = "THE GREAT GATE IS OPEN\nEnter the Bloom Sanctum to escape!"

func _unlock_sanctum() -> void:
	emit_signal("sanctum_unlocked")
	_show_banner("THE GREAT GATE HAS SHATTERED!")
	if gate:
		var tween := create_tween()
		tween.tween_property(gate, "position:y", 6.0, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _show_banner(text: String) -> void:
	if not banner_label:
		return
	banner_label.text = text
	var tween := create_tween()
	tween.tween_property(banner_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(banner_label, "modulate:a", 0.0, 0.5)
