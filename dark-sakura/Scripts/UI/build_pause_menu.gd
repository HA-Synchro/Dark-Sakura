extends SceneTree

const OUTPUT_PATH = "res://Scenes/UI/pause_menu.tscn"

func _init() -> void:
	print("Building Pause Menu Scene with High-Readability Modals...")
	var err = build_pause_menu()
	if err == OK:
		print("Successfully created Pause Menu scene at: ", OUTPUT_PATH)
	else:
		printerr("Failed to build Pause Menu scene! Error: ", err)
	quit(err)

func build_pause_menu() -> Error:
	var root := CanvasLayer.new()
	root.name = "PauseMenu"
	root.layer = 10 # Below PSXPostProcess (15) so in-game pause buttons receive PSX shader!
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	
	var script = load("res://Scripts/UI/pause_menu.gd")
	if script:
		root.set_script(script)

	var main_ctrl := Control.new()
	main_ctrl.name = "MainControl"
	main_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(main_ctrl)
	main_ctrl.owner = root

	# Dark Translucent Backdrop
	var bg := ColorRect.new()
	bg.name = "DarkBackdrop"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color(0.03, 0.008, 0.02, 0.82)
	main_ctrl.add_child(bg)
	bg.owner = root

	# Margin Container
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
	left_col.add_theme_constant_override("separation", 20)
	hbox.add_child(left_col)
	left_col.owner = root

	# Title Block Container
	var title_box := VBoxContainer.new()
	title_box.name = "TitleBox"
	title_box.add_theme_constant_override("separation", 2)
	left_col.add_child(title_box)
	title_box.owner = root

	var lbl_sub := Label.new()
	lbl_sub.name = "LabelSub"
	lbl_sub.text = "D A R K   S A K U R A"
	lbl_sub.add_theme_font_size_override("font_size", 14)
	lbl_sub.add_theme_color_override("font_color", Color(0.75, 0.45, 0.60, 0.9))
	title_box.add_child(lbl_sub)
	lbl_sub.owner = root

	var lbl_pause := Label.new()
	lbl_pause.name = "LabelPause"
	lbl_pause.text = "PAUSED"
	lbl_pause.add_theme_font_size_override("font_size", 46)
	lbl_pause.add_theme_color_override("font_color", Color(1.0, 0.16, 0.43, 1.0))
	lbl_pause.add_theme_color_override("font_shadow_color", Color(0.25, 0.02, 0.1, 0.95))
	lbl_pause.add_theme_constant_override("shadow_offset_x", 3)
	lbl_pause.add_theme_constant_override("shadow_offset_y", 3)
	title_box.add_child(lbl_pause)
	lbl_pause.owner = root

	var lbl_desc := Label.new()
	lbl_desc.name = "LabelDesc"
	lbl_desc.text = "Expedition suspended in the roots."
	lbl_desc.add_theme_font_size_override("font_size", 15)
	lbl_desc.add_theme_color_override("font_color", Color(0.65, 0.52, 0.58, 1.0))
	title_box.add_child(lbl_desc)
	lbl_desc.owner = root

	# Divider line
	var divider := ColorRect.new()
	divider.name = "TitleDivider"
	divider.custom_minimum_size = Vector2(0, 3)
	divider.color = Color(1.0, 0.16, 0.43, 0.8)
	left_col.add_child(divider)
	divider.owner = root

	# Buttons Container (Rendered under PSX effect!)
	var btn_vbox := VBoxContainer.new()
	btn_vbox.name = "ButtonList"
	btn_vbox.add_theme_constant_override("separation", 12)
	left_col.add_child(btn_vbox)
	btn_vbox.owner = root

	var btn_resume := Button.new()
	btn_resume.name = "BtnResume"
	btn_resume.text = "•  RESUME EXPEDITION"
	btn_vbox.add_child(btn_resume)
	btn_resume.owner = root

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

	var btn_retry := Button.new()
	btn_retry.name = "BtnRetry"
	btn_retry.text = "•  RETRY FROM SANCTUARY"
	btn_vbox.add_child(btn_retry)
	btn_retry.owner = root

	var btn_quit := Button.new()
	btn_quit.name = "BtnQuit"
	btn_quit.text = "•  QUIT TO MAIN MENU"
	btn_vbox.add_child(btn_quit)
	btn_quit.owner = root

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_col.add_child(spacer)
	spacer.owner = root

	# Navigation Tip
	var lbl_tip := Label.new()
	lbl_tip.name = "LabelTip"
	lbl_tip.text = "[ ESC ] RESUME  •  [ ARROWS / MOUSE ] NAVIGATE"
	lbl_tip.add_theme_font_size_override("font_size", 13)
	lbl_tip.add_theme_color_override("font_color", Color(0.65, 0.48, 0.55, 0.85))
	left_col.add_child(lbl_tip)
	lbl_tip.owner = root

	# =========================================================================
	# Modal CanvasLayer (LAYER 25 - Crisp & Readable above PSXPostProcess 15)
	# =========================================================================
	var modal_layer := CanvasLayer.new()
	modal_layer.name = "ModalLayer"
	modal_layer.layer = 25
	modal_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(modal_layer)
	modal_layer.owner = root

	var modal_center := CenterContainer.new()
	modal_center.name = "ModalCenter"
	modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_layer.add_child(modal_center)
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
