extends Node3D
class_name MainMenu

const SFX_AMBIENT_DRONE = preload("res://Audio/SFX/ambient_drone.wav")
const SFX_HOVER = preload("res://Audio/SFX/gun_empty.wav")
const SFX_SELECT = preload("res://Audio/SFX/seal_pickup.wav")
const SFX_START = preload("res://Audio/SFX/gun_shoot.wav")

const SCENE_DUNGEON = "res://Scenes/Dungeon/dungeon.tscn"

# 3D Node references
@onready var camera: Camera3D = $MenuCamera
@onready var diorama: Node3D = $Diorama
@onready var floating_rune: Node3D = get_node_or_null("Diorama/FloatingRune")
@onready var rune_light: OmniLight3D = get_node_or_null("Diorama/FloatingRune/RuneLight")
@onready var candle_l_light: OmniLight3D = get_node_or_null("Diorama/CandleLightLeft")
@onready var candle_r_light: OmniLight3D = get_node_or_null("Diorama/CandleLightRight")
@onready var psx_post_process: CanvasLayer = get_node_or_null("PSXPostProcess")

# UI References
@onready var btn_start: Button = $MenuUI/MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnStart
@onready var btn_guide: Button = $MenuUI/MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnGuide
@onready var btn_settings: Button = $MenuUI/MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnSettings
@onready var btn_quit: Button = $MenuUI/MainControl/UIMargin/MainHBox/LeftColumn/ButtonList/BtnQuit
@onready var title_ui: CanvasLayer = get_node_or_null("TitleUI")
@onready var lbl_sakura: Label = get_node_or_null("TitleUI/TitleControl/TitleMargin/TitleBox/LabelSakura")
@onready var lbl_dark: Label = get_node_or_null("TitleUI/TitleControl/TitleMargin/TitleBox/LabelDark")
@onready var title_box: VBoxContainer = get_node_or_null("TitleUI/TitleControl/TitleMargin/TitleBox")
@onready var fade_overlay: ColorRect = $MenuUI/MainControl/FadeOverlay
@onready var modal_guide: PanelContainer = get_node_or_null("TitleUI/TitleControl/ModalCenter/ModalGuide")
@onready var modal_settings: PanelContainer = get_node_or_null("TitleUI/TitleControl/ModalCenter/ModalSettings")
@onready var left_column: VBoxContainer = $MenuUI/MainControl/UIMargin/MainHBox/LeftColumn

# Audio Players
var _bgm_player: AudioStreamPlayer
var _sfx_hover: AudioStreamPlayer
var _sfx_select: AudioStreamPlayer
var _sfx_start: AudioStreamPlayer

# Animation state
var _sway_time: float = 0.0
var _mouse_norm: Vector2 = Vector2(0.5, 0.5)
var _glitch_timer: float = 4.0
var _is_starting: bool = false
var _button_original_x: Dictionary = {}
var _button_raw_labels: Dictionary = {}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_audio()
	_style_buttons()
	_setup_guide_modal()
	_setup_settings_modal()
	
	# Connect buttons
	_connect_button(btn_start, _on_start_pressed)
	_connect_button(btn_guide, _on_guide_pressed)
	_connect_button(btn_settings, _on_settings_pressed)
	_connect_button(btn_quit, _on_quit_pressed)
	
	# Initial focus for keyboard/gamepad navigation
	if btn_start:
		btn_start.grab_focus()
	
	# Initial screen fade in
	if fade_overlay:
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _setup_audio() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = SFX_AMBIENT_DRONE
	_bgm_player.volume_db = -5.0
	_bgm_player.autoplay = true
	_bgm_player.bus = "Master"
	add_child(_bgm_player)
	_bgm_player.play()
	
	_sfx_hover = AudioStreamPlayer.new()
	_sfx_hover.stream = SFX_HOVER
	_sfx_hover.volume_db = -4.0
	_sfx_hover.pitch_scale = 1.35
	add_child(_sfx_hover)
	
	_sfx_select = AudioStreamPlayer.new()
	_sfx_select.stream = SFX_SELECT
	_sfx_select.volume_db = 1.0
	add_child(_sfx_select)
	
	_sfx_start = AudioStreamPlayer.new()
	_sfx_start.stream = SFX_START
	_sfx_start.volume_db = 2.0
	add_child(_sfx_start)

func _strip_indicator(text: String) -> String:
	if text.begins_with("▶  ") or text.begins_with("•  "):
		return text.substr(3)
	elif text.begins_with("▶ ") or text.begins_with("• "):
		return text.substr(2)
	elif text.begins_with("▶") or text.begins_with("•"):
		return text.substr(1).strip_edges()
	return text

func _style_button(btn: Button, font_size: int = 19) -> void:
	if not btn:
		return
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.015, 0.035, 0.9)
	style_normal.border_color = Color(0.55, 0.12, 0.28, 0.75)
	style_normal.border_width_left = 5
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.content_margin_left = 18
	style_normal.content_margin_right = 18
	style_normal.content_margin_top = 10
	style_normal.content_margin_bottom = 10

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.25, 0.04, 0.14, 0.95)
	style_hover.border_color = Color(1.0, 0.18, 0.44, 1.0)
	style_hover.border_width_left = 8
	style_hover.border_width_top = 1
	style_hover.border_width_right = 1
	style_hover.border_width_bottom = 1
	style_hover.corner_radius_top_left = 2
	style_hover.corner_radius_top_right = 2
	style_hover.corner_radius_bottom_right = 2
	style_hover.corner_radius_bottom_left = 2
	style_hover.content_margin_left = 22
	style_hover.content_margin_right = 18
	style_hover.content_margin_top = 10
	style_hover.content_margin_bottom = 10
	style_hover.shadow_color = Color(1.0, 0.15, 0.42, 0.45)
	style_hover.shadow_size = 8

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.85, 0.16, 0.45, 1.0)
	style_pressed.border_color = Color(1.0, 1.0, 1.0, 1.0)
	style_pressed.border_width_left = 8
	style_pressed.border_width_top = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_bottom = 2
	style_pressed.content_margin_left = 22
	style_pressed.content_margin_right = 18
	style_pressed.content_margin_top = 10
	style_pressed.content_margin_bottom = 10

	var style_focus = style_hover.duplicate()

	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.add_theme_stylebox_override("focus", style_focus)
	btn.add_theme_color_override("font_color", Color(0.9, 0.84, 0.87, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.0, 0.05, 1.0))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _style_buttons() -> void:
	for btn in [btn_start, btn_guide, btn_settings, btn_quit]:
		_style_button(btn, 20)

func _connect_button(btn: Button, callback: Callable) -> void:
	if not btn:
		return
	if callback.is_valid():
		btn.pressed.connect(callback)
	btn.mouse_entered.connect(_on_button_hovered.bind(btn))
	btn.focus_entered.connect(_on_button_hovered.bind(btn))
	btn.mouse_exited.connect(_on_button_unhovered.bind(btn))
	btn.focus_exited.connect(_on_button_unhovered.bind(btn))

func _on_button_hovered(btn: Button) -> void:
	if _is_starting or not btn:
		return
	if _sfx_hover:
		_sfx_hover.pitch_scale = randf_range(1.3, 1.45)
		_sfx_hover.play()
	
	var clean = _strip_indicator(btn.text)
	if not clean.is_empty():
		btn.text = "▶  " + clean
	
	# Indent slide animation (+12px to the right)
	var tween := create_tween()
	tween.tween_property(btn, "position:x", 12.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_button_unhovered(btn: Button) -> void:
	if _is_starting or not btn:
		return
	var clean = _strip_indicator(btn.text)
	if not clean.is_empty():
		btn.text = "•  " + clean
	
	# Return slide animation
	var tween := create_tween()
	tween.tween_property(btn, "position:x", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var vp_size = get_viewport().get_visible_rect().size
		_mouse_norm = event.position / vp_size

func _process(delta: float) -> void:
	_sway_time += delta
	
	# 1. 3D Camera Ambient Drift & Mouse Parallax
	if camera and not _is_starting:
		var sway_x = sin(_sway_time * 0.4) * 0.22
		var sway_y = 1.45 + cos(_sway_time * 0.3) * 0.08
		var sway_rot_y = sin(_sway_time * 0.22) * deg_to_rad(2.0)
		
		var mouse_parallax_x = -(_mouse_norm.x - 0.5) * deg_to_rad(4.5)
		var mouse_parallax_y = -(_mouse_norm.y - 0.5) * deg_to_rad(3.0)
		
		camera.position.x = lerp(camera.position.x, sway_x, delta * 2.0)
		camera.position.y = lerp(camera.position.y, sway_y, delta * 2.0)
		camera.rotation.y = lerp(camera.rotation.y, sway_rot_y + mouse_parallax_x, delta * 2.5)
		camera.rotation.x = lerp(camera.rotation.x, mouse_parallax_y, delta * 2.5)

	# 2. Floating Cursed Blossom Rune Rotation & Breathing
	if floating_rune:
		floating_rune.rotate_y(delta * 0.6)
		floating_rune.position.y = 1.8 + sin(_sway_time * 1.8) * 0.12
	if rune_light:
		rune_light.light_energy = 3.4 + sin(_sway_time * 2.2) * 1.0

	# 3. Candle Flickering
	if candle_l_light:
		candle_l_light.light_energy = 1.3 + sin(_sway_time * 12.0) * 0.15 + cos(_sway_time * 7.5) * 0.1
	if candle_r_light:
		candle_r_light.light_energy = 1.3 + cos(_sway_time * 11.0) * 0.15 + sin(_sway_time * 8.5) * 0.1

	# 4. Title Text Neon Breathing
	if lbl_sakura:
		var pulse = (sin(_sway_time * 2.5) + 1.0) * 0.5
		lbl_sakura.modulate = Color(1.0, 0.2, 0.48).lerp(Color(1.0, 0.55, 0.75), pulse)

	# 5. Periodic Analog Glitch
	_glitch_timer -= delta
	if _glitch_timer <= 0.0:
		_trigger_title_glitch()
		_glitch_timer = randf_range(3.5, 6.0)

func _trigger_title_glitch() -> void:
	if not title_box:
		return
	var orig_x = title_box.position.x
	var tween := create_tween()
	# Fast twitch
	tween.tween_property(title_box, "position:x", orig_x + randf_range(-6.0, 6.0), 0.04)
	tween.parallel().tween_property(lbl_sakura, "modulate", Color(0.4, 1.0, 0.9), 0.04) # Chromatic shift
	tween.tween_property(title_box, "position:x", orig_x, 0.05)
	tween.parallel().tween_property(lbl_sakura, "modulate", Color(1.0, 0.2, 0.48), 0.05)

# --- Button Handlers ---

func _on_start_pressed() -> void:
	if _is_starting:
		return
	_is_starting = true
	
	_sfx_start.play()
	_sfx_select.play()
	
	# Disable buttons
	btn_start.disabled = true
	btn_guide.disabled = true
	btn_settings.disabled = true
	btn_quit.disabled = true
	
	# Cinematic camera plunge forward through the arch into the fog
	var tween := create_tween()
	tween.set_parallel(true)
	if camera:
		tween.tween_property(camera, "position:z", -4.5, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(camera, "fov", 95.0, 1.4)
	
	# Fade UI to transparency
	if left_column:
		tween.tween_property(left_column, "modulate:a", 0.0, 0.6)
	if title_ui:
		tween.tween_property(title_ui, "modulate:a", 0.0, 0.6)
	
	# Fade screen to black
	if fade_overlay:
		tween.tween_property(fade_overlay, "color", Color(0.0, 0.0, 0.0, 1.0), 1.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	await tween.finished
	get_tree().change_scene_to_file(SCENE_DUNGEON)

func _on_guide_pressed() -> void:
	_sfx_select.play()
	if modal_guide:
		modal_guide.visible = true
		modal_guide.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(modal_guide, "modulate:a", 1.0, 0.2)
	if modal_settings:
		modal_settings.visible = false

func _on_settings_pressed() -> void:
	_sfx_select.play()
	if modal_settings:
		modal_settings.visible = true
		modal_settings.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(modal_settings, "modulate:a", 1.0, 0.2)
	if modal_guide:
		modal_guide.visible = false

func _on_quit_pressed() -> void:
	_sfx_select.play()
	if fade_overlay:
		var tween := create_tween()
		tween.tween_property(fade_overlay, "color:a", 1.0, 0.5)
		await tween.finished
	get_tree().quit()

# --- Modal Setups ---

func _setup_guide_modal() -> void:
	if not modal_guide:
		return
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.012, 0.03, 0.98)
	panel_style.border_color = Color(1.0, 0.22, 0.48, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_style.shadow_size = 16
	modal_guide.add_theme_stylebox_override("panel", panel_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	modal_guide.add_child(vbox)
	
	var title := Label.new()
	title.text = "ARCHIVAL SURVIVAL NOTES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.65, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)
	
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 3)
	div.color = Color(1.0, 0.2, 0.45, 0.85)
	vbox.add_child(div)
	
	var content := RichTextLabel.new()
	content.bbcode_enabled = true
	content.fit_content = true
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.text = """[b][color=#FF457E]▸ KINETIC ARENA MOVEMENT[/color][/b]
  [color=#FFE066][b]W A S D[/b][/color]   [color=#F4ECF0]Sprint across stone corridors (6.5 m/s)[/color]
  [color=#FFE066][b]SHIFT[/b][/color]     [color=#F4ECF0]Dash / Dodge burst with temporary invulnerability[/color]
  [color=#FFE066][b]CTRL[/b][/color]      [color=#F4ECF0]Low slide under lunges while maintaining speed[/color]
  [color=#FFE066][b]SPACE[/b][/color]     [color=#F4ECF0]Jump / Bunnyhop across ground shockwaves[/color]

[b][color=#FF457E]▸ WEAPON: SAKURA-9 SERVICE CANNON[/color][/b]
  [color=#FFE066][b]LMB[/b][/color]       [color=#F4ECF0]Heavy .308 caliber gunshot (Aim for the head!)[/color]
  [color=#FFE066][b]RMB[/b][/color]       [color=#F4ECF0]Aim Down Sights for pinpoint reticle precision[/color]
  [color=#FFE066][b]R[/b][/color]         [color=#F4ECF0]Tactical / Empty Reload (7-round magazine)[/color]
  [color=#FFE066][b]F[/b][/color]         [color=#F4ECF0]Boot Kick Melee (Knocks back & interrupts windups)[/color]

[b][color=#FF457E]▸ HARVEST & EXPEDITION OBJECTIVE[/color][/b]
  [color=#FF77AA][b]Pink Embers[/b][/color]     [color=#F4ECF0]Restore +15 Health ticks on fallen foes[/color]
  [color=#D070FF][b]Purple Crystals[/b][/color] [color=#F4ECF0]Rare Ammo drops (+7 bullets with low-ammo pity)[/color]
  [color=#FFE066][b]The Seals[/b][/color]       [color=#F4ECF0]Break West & East Seals to shatter the Great Gate, then purge the Root Executioner in the Bloom Sanctum![/color]"""
	content.add_theme_font_size_override("normal_font_size", 16)
	content.add_theme_font_size_override("bold_font_size", 17)
	content.add_theme_constant_override("line_separation", 4)
	vbox.add_child(content)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)
	
	var close_btn := Button.new()
	close_btn.text = "•  RETURN TO SANCTUARY"
	close_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(func():
		_sfx_hover.play()
		modal_guide.visible = false
		btn_guide.grab_focus()
	)
	_connect_button(close_btn, func(): pass)
	vbox.add_child(close_btn)

func _setup_settings_modal() -> void:
	if not modal_settings:
		return
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.012, 0.03, 0.98)
	panel_style.border_color = Color(1.0, 0.22, 0.48, 1.0)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.content_margin_left = 32
	panel_style.content_margin_right = 32
	panel_style.content_margin_top = 28
	panel_style.content_margin_bottom = 28
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.85)
	panel_style.shadow_size = 16
	modal_settings.add_theme_stylebox_override("panel", panel_style)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	modal_settings.add_child(vbox)
	
	var title := Label.new()
	title.text = "SETTINGS & SYSTEM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.65, 1.0))
	title.add_theme_color_override("font_shadow_color", Color(0.18, 0.02, 0.08, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	vbox.add_child(title)
	
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 3)
	div.color = Color(1.0, 0.2, 0.45, 0.85)
	vbox.add_child(div)
	
	# Master Volume Slider
	var vol_box := VBoxContainer.new()
	var vol_lbl := Label.new()
	vol_lbl.text = "MASTER VOLUME: 100%"
	vol_lbl.add_theme_font_size_override("font_size", 17)
	vol_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.92, 1.0))
	vol_box.add_child(vol_lbl)
	
	var vol_slider := HSlider.new()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = 1.0
	vol_slider.value_changed.connect(func(val: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(val) if val > 0.01 else -80.0)
		vol_lbl.text = "MASTER VOLUME: %d%%" % int(val * 100.0)
	)
	vol_box.add_child(vol_slider)
	vbox.add_child(vol_box)
	
	# Fullscreen Toggle Button
	var fs_btn := Button.new()
	fs_btn.text = "•  DISPLAY MODE: FULLSCREEN"
	fs_btn.pressed.connect(func():
		_sfx_hover.play()
		var mode = DisplayServer.window_get_mode()
		var label := ""
		if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			label = "DISPLAY MODE: WINDOWED"
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			label = "DISPLAY MODE: FULLSCREEN"
		fs_btn.text = "▶  " + label
	)
	_style_button(fs_btn, 18)
	_connect_button(fs_btn, func(): pass)
	vbox.add_child(fs_btn)
	
	# PSX Post-Processing Toggle
	var psx_btn := Button.new()
	psx_btn.text = "•  PSX SHADER PIPELINE: ENABLED"
	psx_btn.pressed.connect(func():
		_sfx_hover.play()
		if psx_post_process:
			psx_post_process.visible = not psx_post_process.visible
			var state = "ENABLED" if psx_post_process.visible else "DISABLED"
			psx_btn.text = "▶  PSX SHADER PIPELINE: " + state
	)
	_style_button(psx_btn, 18)
	_connect_button(psx_btn, func(): pass)
	vbox.add_child(psx_btn)
	
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)
	
	# Return Button
	var close_btn := Button.new()
	close_btn.text = "•  RETURN TO SANCTUARY"
	close_btn.pressed.connect(func():
		_sfx_hover.play()
		modal_settings.visible = false
		btn_settings.grab_focus()
	)
	_style_button(close_btn, 19)
	close_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_connect_button(close_btn, func(): pass)
	vbox.add_child(close_btn)
