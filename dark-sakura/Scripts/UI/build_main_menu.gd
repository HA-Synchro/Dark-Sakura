extends SceneTree

const SCENE_FLOOR = "res://Models/PSX_Dungeon/Models/FloorTile/floor_tile.tscn"
const SCENE_ARCH = "res://Models/PSX_Dungeon/Models/Arch/arch.tscn"
const SCENE_PILLAR = "res://Models/PSX_Dungeon/Models/Pillar/pillar.tscn"
const SCENE_PILLAR_RUIN = "res://Models/PSX_Dungeon/Models/PillarRuin/pillar_ruin.tscn"
const SCENE_SKULL_WALL = "res://Models/PSX_Dungeon/Models/SkullWall/skull_wall.tscn"
const SCENE_CANDLE = "res://Models/PSX_Dungeon/Models/Candle/candle.tscn"
const SCENE_CHANDELIER = "res://Models/PSX_Dungeon/Models/Chandlier/chandelier.tscn"
const SCENE_WORLD_ENV = "res://Scenes/Environment/dark_sakura_world.tscn"
const SCENE_POST_PROCESS = "res://Scenes/Environment/psx_post_process.tscn"
const SCENE_PETALS = "res://Scenes/Effects/sakura_petals.tscn"

const OUTPUT_PATH = "res://Scenes/UI/main_menu.tscn"

func _init() -> void:
	print("Building Main Menu Scene with High-Readability Modals...")
	var err = build_menu()
	if err == OK:
		print("Successfully created Main Menu scene at: ", OUTPUT_PATH)
	else:
		printerr("Failed to build Main Menu scene! Error: ", err)
	quit(err)

func build_menu() -> Error:
	var root := Node3D.new()
	root.name = "MainMenu"
	var script = load("res://Scripts/UI/main_menu.gd")
	if script:
		root.set_script(script)

	# 1. Environment & World
	var env_scn = load(SCENE_WORLD_ENV)
	if env_scn:
		var env = env_scn.instantiate()
		root.add_child(env)
		env.owner = root

	var petals_scn = load(SCENE_PETALS)
	if petals_scn:
		var petals = petals_scn.instantiate()
		petals.position = Vector3(0, 4.0, -2.0)
		root.add_child(petals)
		petals.owner = root

	# 2. Camera3D
	var camera := Camera3D.new()
	camera.name = "MenuCamera"
	camera.position = Vector3(0.0, 1.45, 2.2)
	camera.fov = 75.0
	camera.current = true
	root.add_child(camera)
	camera.owner = root

	# 3. 3D Diorama Geometry
	var diorama := Node3D.new()
	diorama.name = "Diorama"
	root.add_child(diorama)
	diorama.owner = root

	var scn_floor = load(SCENE_FLOOR)
	var scn_arch = load(SCENE_ARCH)
	var scn_pillar = load(SCENE_PILLAR)
	var scn_pillar_ruin = load(SCENE_PILLAR_RUIN)
	var scn_skull_wall = load(SCENE_SKULL_WALL)
	var scn_candle = load(SCENE_CANDLE)
	var scn_chandelier = load(SCENE_CHANDELIER)

	# Floor 5x5 tiles
	var floor_parent := Node3D.new()
	floor_parent.name = "Floor"
	diorama.add_child(floor_parent)
	floor_parent.owner = root
	for gx in range(-2, 3):
		for gz in range(-3, 2):
			var fl = scn_floor.instantiate()
			fl.position = Vector3(gx * 4.0, 0.0, gz * 4.0)
			floor_parent.add_child(fl)
			fl.owner = root

	# Center Torii / Ancient Arch at (0, 0, -6)
	var arch = scn_arch.instantiate()
	arch.position = Vector3(0.0, 0.0, -6.0)
	diorama.add_child(arch)
	arch.owner = root

	# Flanking Skull Walls
	var sw_left = scn_skull_wall.instantiate()
	sw_left.position = Vector3(-4.0, 0.0, -6.0)
	diorama.add_child(sw_left)
	sw_left.owner = root

	var sw_right = scn_skull_wall.instantiate()
	sw_right.position = Vector3(4.0, 0.0, -6.0)
	diorama.add_child(sw_right)
	sw_right.owner = root

	# Pillars
	var p_l1 = scn_pillar.instantiate()
	p_l1.position = Vector3(-2.2, 0.0, -3.5)
	diorama.add_child(p_l1)
	p_l1.owner = root

	var p_r1 = scn_pillar.instantiate()
	p_r1.position = Vector3(2.2, 0.0, -3.5)
	diorama.add_child(p_r1)
	p_r1.owner = root

	var p_l2 = scn_pillar_ruin.instantiate()
	p_l2.position = Vector3(-4.5, 0.0, -1.0)
	diorama.add_child(p_l2)
	p_l2.owner = root

	var p_r2 = scn_pillar_ruin.instantiate()
	p_r2.position = Vector3(4.5, 0.0, -1.0)
	diorama.add_child(p_r2)
	p_r2.owner = root

	# Candles
	var c_l = scn_candle.instantiate()
	c_l.position = Vector3(-1.4, 0.0, -1.8)
	diorama.add_child(c_l)
	c_l.owner = root

	var c_l_light := OmniLight3D.new()
	c_l_light.name = "CandleLightLeft"
	c_l_light.light_color = Color(1.0, 0.55, 0.3)
	c_l_light.light_energy = 1.4
	c_l_light.omni_range = 6.0
	c_l_light.position = Vector3(-1.4, 0.8, -1.8)
	diorama.add_child(c_l_light)
	c_l_light.owner = root

	var c_r = scn_candle.instantiate()
	c_r.position = Vector3(1.4, 0.0, -1.8)
	diorama.add_child(c_r)
	c_r.owner = root

	var c_r_light := OmniLight3D.new()
	c_r_light.name = "CandleLightRight"
	c_r_light.light_color = Color(1.0, 0.55, 0.3)
	c_r_light.light_energy = 1.4
	c_r_light.omni_range = 6.0
	c_r_light.position = Vector3(1.4, 0.8, -1.8)
	diorama.add_child(c_r_light)
	c_r_light.owner = root

	# Overhead Chandelier
	var ch = scn_chandelier.instantiate()
	ch.position = Vector3(0.0, 3.4, -4.0)
	diorama.add_child(ch)
	ch.owner = root

	var ch_light := OmniLight3D.new()
	ch_light.name = "ChandelierLight"
	ch_light.light_color = Color(1.0, 0.35, 0.65)
	ch_light.light_energy = 2.2
	ch_light.omni_range = 10.0
	ch_light.position = Vector3(0.0, 3.0, -4.0)
	diorama.add_child(ch_light)
	ch_light.owner = root

	# Central Floating Cursed Blossom Rune
	var rune_root := Node3D.new()
	rune_root.name = "FloatingRune"
	rune_root.position = Vector3(0.0, 1.8, -6.0)
	diorama.add_child(rune_root)
	rune_root.owner = root

	var rune_mesh := MeshInstance3D.new()
	rune_mesh.name = "RuneCore"
	var prism := BoxMesh.new()
	prism.size = Vector3(0.4, 0.4, 0.4)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rune_mat.albedo_color = Color(1.0, 0.15, 0.55, 1.0)
	rune_mesh.mesh = prism
	rune_mesh.material_override = rune_mat
	rune_root.add_child(rune_mesh)
	rune_mesh.owner = root

	var rune_light := OmniLight3D.new()
	rune_light.name = "RuneLight"
	rune_light.light_color = Color(1.0, 0.2, 0.65, 1.0)
	rune_light.light_energy = 3.6
	rune_light.omni_range = 14.0
	rune_root.add_child(rune_light)
	rune_light.owner = root

	# =========================================================================
	# 4. MenuUI CanvasLayer (LAYER 10 - BELOW Layer 15 PSXPostProcess)
	# All menu buttons and footers receive the authentic PSX effect!
	# =========================================================================
	var menu_ui := CanvasLayer.new()
	menu_ui.name = "MenuUI"
	menu_ui.layer = 10
	root.add_child(menu_ui)
	menu_ui.owner = root

	var main_ctrl := Control.new()
	main_ctrl.name = "MainControl"
	main_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_ui.add_child(main_ctrl)
	main_ctrl.owner = root

	# Screen Edge Vignette / Gradient for UI readability
	var ui_grad := ColorRect.new()
	ui_grad.name = "UIGradient"
	ui_grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_grad.color = Color(0.02, 0.005, 0.015, 0.35)
	main_ctrl.add_child(ui_grad)
	ui_grad.owner = root

	# Margin Container holding the Left Column UI
	var margin := MarginContainer.new()
	margin.name = "UIMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 64)
	margin.add_theme_constant_override("margin_top", 54)
	margin.add_theme_constant_override("margin_right", 64)
	margin.add_theme_constant_override("margin_bottom", 54)
	main_ctrl.add_child(margin)
	margin.owner = root

	var hbox := HBoxContainer.new()
	hbox.name = "MainHBox"
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(hbox)
	hbox.owner = root

	# Left Column
	var left_col := VBoxContainer.new()
	left_col.name = "LeftColumn"
	left_col.custom_minimum_size = Vector2(460, 0)
	left_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_theme_constant_override("separation", 24)
	hbox.add_child(left_col)
	left_col.owner = root

	# Top Spacer reserving space for Title above
	var title_spacer := Control.new()
	title_spacer.name = "TitleSpacer"
	title_spacer.custom_minimum_size = Vector2(0, 150)
	title_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_child(title_spacer)
	title_spacer.owner = root

	# Divider line
	var divider := ColorRect.new()
	divider.name = "TitleDivider"
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(1.0, 0.16, 0.43, 0.8)
	left_col.add_child(divider)
	divider.owner = root

	# Buttons Container (Rendered under PSX post-process!)
	var btn_vbox := VBoxContainer.new()
	btn_vbox.name = "ButtonList"
	btn_vbox.add_theme_constant_override("separation", 14)
	left_col.add_child(btn_vbox)
	btn_vbox.owner = root

	var btn_start := Button.new()
	btn_start.name = "BtnStart"
	btn_start.text = "•  ENTER THE LABYRINTH"
	btn_vbox.add_child(btn_start)
	btn_start.owner = root

	var btn_guide := Button.new()
	btn_guide.name = "BtnGuide"
	btn_guide.text = "•  HOW TO SURVIVE"
	btn_vbox.add_child(btn_guide)
	btn_guide.owner = root

	var btn_settings := Button.new()
	btn_settings.name = "BtnSettings"
	btn_settings.text = "•  SETTINGS"
	btn_vbox.add_child(btn_settings)
	btn_settings.owner = root

	var btn_quit := Button.new()
	btn_quit.name = "BtnQuit"
	btn_quit.text = "•  ABANDON SANITY"
	btn_vbox.add_child(btn_quit)
	btn_quit.owner = root

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_child(spacer)
	spacer.owner = root

	# Footer
	var lbl_version := Label.new()
	lbl_version.name = "LabelVersion"
	lbl_version.text = "v1.0.0 • PSX RETRO FPS HORROR • GODOT 4.7"
	lbl_version.add_theme_font_size_override("font_size", 13)
	lbl_version.add_theme_color_override("font_color", Color(0.65, 0.48, 0.55, 0.85))
	left_col.add_child(lbl_version)
	lbl_version.owner = root

	# Fullscreen Transition Fade Overlay
	var fade_overlay := ColorRect.new()
	fade_overlay.name = "FadeOverlay"
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	main_ctrl.add_child(fade_overlay)
	fade_overlay.owner = root

	# =========================================================================
	# 5. PSX Post-Process Layer (LAYER 15)
	# Captures 3D scene + MenuUI (Layer 10) and applies Bayer dither & pixelation!
	# =========================================================================
	var pp_scn = load(SCENE_POST_PROCESS)
	if pp_scn:
		var pp = pp_scn.instantiate()
		root.add_child(pp)
		pp.owner = root

	# =========================================================================
	# 6. TitleUI CanvasLayer (LAYER 25 - ABOVE PSXPostProcess)
	# Renders the Title & Information Modals crisp, smooth, and easily readable!
	# =========================================================================
	var title_ui := CanvasLayer.new()
	title_ui.name = "TitleUI"
	title_ui.layer = 25
	root.add_child(title_ui)
	title_ui.owner = root

	var title_ctrl := Control.new()
	title_ctrl.name = "TitleControl"
	title_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_ui.add_child(title_ctrl)
	title_ctrl.owner = root

	var title_margin := MarginContainer.new()
	title_margin.name = "TitleMargin"
	title_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_margin.add_theme_constant_override("margin_left", 64)
	title_margin.add_theme_constant_override("margin_top", 54)
	title_ctrl.add_child(title_margin)
	title_margin.owner = root

	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override("separation", 2)
	title_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_margin.add_child(title_box)
	title_box.owner = root

	var lbl_dark := Label.new()
	lbl_dark.name = "LabelDark"
	lbl_dark.text = "DARK"
	lbl_dark.add_theme_font_size_override("font_size", 48)
	lbl_dark.add_theme_color_override("font_color", Color(0.94, 0.90, 0.92, 1.0))
	lbl_dark.add_theme_color_override("font_shadow_color", Color(0.2, 0.02, 0.08, 0.95))
	lbl_dark.add_theme_constant_override("shadow_offset_x", 3)
	lbl_dark.add_theme_constant_override("shadow_offset_y", 3)
	title_box.add_child(lbl_dark)
	lbl_dark.owner = root

	var lbl_sakura := Label.new()
	lbl_sakura.name = "LabelSakura"
	lbl_sakura.text = "SAKURA"
	lbl_sakura.add_theme_font_size_override("font_size", 56)
	lbl_sakura.add_theme_color_override("font_color", Color(1.0, 0.16, 0.43, 1.0))
	lbl_sakura.add_theme_color_override("font_shadow_color", Color(0.4, 0.02, 0.15, 0.9))
	lbl_sakura.add_theme_constant_override("shadow_offset_x", 4)
	lbl_sakura.add_theme_constant_override("shadow_offset_y", 4)
	title_box.add_child(lbl_sakura)
	lbl_sakura.owner = root

	var lbl_tagline := Label.new()
	lbl_tagline.name = "LabelTagline"
	lbl_tagline.text = "\"The petals don't fall. They hunt.\""
	lbl_tagline.add_theme_font_size_override("font_size", 16)
	lbl_tagline.add_theme_color_override("font_color", Color(0.72, 0.52, 0.62, 1.0))
	lbl_tagline.add_theme_color_override("font_shadow_color", Color(0.05, 0.01, 0.03, 0.9))
	lbl_tagline.add_theme_constant_override("shadow_offset_x", 1)
	lbl_tagline.add_theme_constant_override("shadow_offset_y", 1)
	title_box.add_child(lbl_tagline)
	lbl_tagline.owner = root

	# Modals Container placed inside TitleUI (Layer 25 - high clarity, crystal clear reading!)
	var modal_center := CenterContainer.new()
	modal_center.name = "ModalCenter"
	modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_ctrl.add_child(modal_center)
	modal_center.owner = root

	# Survival Guide Modal Panel
	var modal_guide := PanelContainer.new()
	modal_guide.name = "ModalGuide"
	modal_guide.visible = false
	modal_guide.custom_minimum_size = Vector2(660, 500)
	modal_center.add_child(modal_guide)
	modal_guide.owner = root

	# Settings Modal Panel
	var modal_settings := PanelContainer.new()
	modal_settings.name = "ModalSettings"
	modal_settings.visible = false
	modal_settings.custom_minimum_size = Vector2(500, 380)
	modal_center.add_child(modal_settings)
	modal_settings.owner = root

	var packed := PackedScene.new()
	packed.pack(root)
	return ResourceSaver.save(packed, OUTPUT_PATH)
