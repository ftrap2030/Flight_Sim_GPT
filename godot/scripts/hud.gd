extends CanvasLayer
const INK := Color("e5f0ee")
const DIM := Color("94adaa")
const MINT := Color("a9e2c4")
var app: Node3D
var status: Label
var telemetry: Label
var toast: Label
var pause_button: Button
var record_button: Button
var info_panel: PanelContainer
var quality_select: OptionButton
var lighting_select: OptionButton
var cloud_select: OptionButton
var callout_caption: Label
var gate_select: OptionButton
var arrival_status: Label
var auto_button: Button
var brake_button: Button
var camera_buttons: Array[Button] = []
var timer := 0.0
var notice_seconds := 0.0

func _ready() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme := Theme.new()
	theme.default_font_size = 17
	for state in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("263b3f") if state=="hover" else Color("15272b")
		if state=="pressed": style.bg_color = Color("355b52")
		style.set_corner_radius_all(6)
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		if state=="focus":
			style.set_border_width_all(2)
			style.border_color = MINT
		for type_name in ["Button","OptionButton"]:
			theme.set_stylebox(state,type_name,style)
			theme.set_color("font_color",type_name,INK)
	root.theme = theme
	var heading_back := Panel.new()
	heading_back.position = Vector2(22,20)
	heading_back.size = Vector2(595,88)
	heading_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading_back.add_theme_stylebox_override("panel",_panel_style())
	root.add_child(heading_back)
	var title := Label.new()
	title.text = "MIAMI  /  ARRIVAL"
	title.add_theme_font_size_override("font_size",32)
	title.add_theme_color_override("font_color",INK)
	title.position = Vector2(34,28)
	root.add_child(title)
	status = _label("KMIA · RUNWAY 26R",15,DIM)
	status.position = Vector2(36,73)
	root.add_child(status)
	var tag := _label("COCKPIT + MIAMI   •   VISUAL UPDATE",14,MINT)
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tag.position = Vector2(-392,34)
	root.add_child(tag)
	info_panel = PanelContainer.new()
	info_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	info_panel.position = Vector2(-314,116)
	info_panel.custom_minimum_size = Vector2(280,0)
	info_panel.add_theme_stylebox_override("panel",_panel_style())
	root.add_child(info_panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation",12)
	info_panel.add_child(info)
	info.add_child(_label("PERFORMANCE",14,MINT))
	telemetry = _label("",16,INK)
	info.add_child(telemetry)
	info.add_child(_label("Engine counters ≠ total Mac RAM",12,DIM))
	record_button = _button("Record benchmark  [B]",app.toggle_benchmark)
	info.add_child(record_button)
	info.add_child(_button("Download last report" if OS.has_feature("web") else "Open reports folder",app.open_benchmark_folder))
	var cap := CheckButton.new()
	cap.text = "Limit to 30 FPS"
	cap.button_pressed = true
	cap.toggled.connect(func(enabled: bool): app.set_frame_limit(enabled))
	info.add_child(cap)
	var arrival_panel := PanelContainer.new()
	arrival_panel.position = Vector2(22,148)
	arrival_panel.custom_minimum_size = Vector2(405,0)
	arrival_panel.add_theme_stylebox_override("panel",_panel_style())
	root.add_child(arrival_panel)
	var flight := VBoxContainer.new()
	flight.add_theme_constant_override("separation",9)
	arrival_panel.add_child(flight)
	flight.add_child(_label("ARRIVAL / GATE",14,MINT))
	var gate_names: Array = []
	for i in 10: gate_names.append("Gate A%d" % (i+1))
	gate_select = _options(flight,"DESTINATION",gate_names,app.select_gate)
	gate_select.select(app.arrival.gate_index)
	arrival_status = _label("",16,INK)
	flight.add_child(arrival_status)
	flight.add_child(_button("Jump to short final  [L]",app.short_final))
	var speed_row := HBoxContainer.new()
	speed_row.add_child(_button("Slower",app.taxi_speed_change.bind(-1.5)))
	speed_row.add_child(_button("Faster",app.taxi_speed_change.bind(1.5)))
	flight.add_child(speed_row)
	auto_button = _button("Auto taxi  [G]",app.toggle_auto_taxi)
	flight.add_child(auto_button)
	brake_button = _button("Parking brake  [P]",app.toggle_parking_brake)
	flight.add_child(brake_button)
	flight.add_child(_label("W / S: taxi speed · Hold X: brake\nSteering follows the mint route",14,DIM))
	var sound := CheckButton.new()
	sound.text = "Sound + altitude callouts"
	sound.button_pressed = true
	sound.toggled.connect(func(enabled: bool): app.arrival_audio.enabled = enabled)
	flight.add_child(sound)
	var tray := PanelContainer.new()
	tray.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tray.offset_left = 24
	tray.offset_right = -24
	tray.offset_top = -106
	tray.offset_bottom = -20
	tray.add_theme_stylebox_override("panel",_panel_style())
	root.add_child(tray)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	tray.add_child(row)
	var camera_group := VBoxContainer.new()
	camera_group.add_child(_label("CAMERA",11,DIM))
	var camera_row := HBoxContainer.new()
	camera_row.add_theme_constant_override("separation",4)
	for i in 3:
		var button := _button(["Cockpit  1","Wing  2","Chase  3"][i],app.select_view.bind(i))
		button.toggle_mode = true
		camera_row.add_child(button)
		camera_buttons.append(button)
	camera_group.add_child(camera_row)
	row.add_child(camera_group)
	lighting_select = _options(row,"LIGHT",["Golden hour","Daylight","Blue hour"],app.set_lighting)
	cloud_select = _options(row,"SKY",["Scattered","Clear","Cloudy"],app.set_weather)
	quality_select = _options(row,"DETAIL",["Low","Balanced","High"],app.set_quality)
	quality_select.select(1)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var flight_controls := VBoxContainer.new()
	flight_controls.add_child(_label("ARRIVAL",11,DIM))
	var controls := HBoxContainer.new()
	pause_button = _button("Pause  [Space]",app.toggle_pause)
	controls.add_child(pause_button)
	controls.add_child(_button("Restart  [R]",app.restart))
	flight_controls.add_child(controls)
	row.add_child(flight_controls)
	var help := _label("Right-drag to look • Wheel to zoom • F1 telemetry • H hide interface • Esc release mouse",14,INK)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(36,-133)
	root.add_child(help)
	toast = _label("",17,MINT)
	toast.position = Vector2(36,107)
	root.add_child(toast)
	callout_caption = _label("",28,MINT)
	callout_caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	callout_caption.position = Vector2(-90,-180)
	root.add_child(callout_caption)
	update_buttons()

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.8))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	return button

func _options(parent: Node, title: String, options: Array, callback: Callable) -> OptionButton:
	var group := VBoxContainer.new()
	group.add_child(_label(title,11,DIM))
	var select := OptionButton.new()
	for text in options: select.add_item(text)
	select.item_selected.connect(callback)
	group.add_child(select)
	parent.add_child(group)
	return select

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.06,0.07,0.94)
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.border_color = Color(0.45,0.68,0.61,0.22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

func _process(delta: float) -> void:
	callout_caption.text = app.arrival_audio.last_callout+" FT" if app.arrival_audio.caption_seconds>0 else ""
	timer += delta
	notice_seconds = maxf(0,notice_seconds-delta)
	if notice_seconds==0: toast.text = ""
	if timer<0.25 or app==null: return
	timer = 0
	status.text = "KMIA · 26R → A%d    /    %s    /    %d KT" % [app.arrival.gate_index+1,"PAUSED" if app.paused else app.arrival.phase,int(app.arrival.speed_ms*1.94384)]
	gate_select.disabled = app.arrival.phase in ["TAXI","PARKED"]
	var taxi_ready: bool = app.arrival.phase in ["TAXI READY","TAXI"]
	auto_button.disabled = not taxi_ready
	brake_button.disabled = not taxi_ready
	auto_button.text = "Stop auto taxi  [G]" if app.arrival.auto_taxi else "Auto taxi  [G]"
	brake_button.text = "Release parking brake  [P]" if app.arrival.parking_brake else "Set parking brake  [P]"
	var guide := "Landing is assisted. Choose your gate."
	if app.arrival.phase=="ROLLOUT": guide = "Reverse thrust + automatic braking"
	elif taxi_ready:
		guide = "W to taxi, or G for auto taxi"
		if app.arrival.phase=="TAXI": guide = "%.0f m to stand · target %d kt" % [app.arrival.taxi_remaining,int((7.7 if app.arrival.auto_taxi else app.arrival.taxi_target_ms)*1.94384)]
		if app.arrival.parking_brake: guide = "Parking brake set — press P to release"
	elif app.arrival.phase=="PARKED": guide = "Gate reached · parking brake set"
	arrival_status.text = "%s\nFlaps %d%% · Spoilers %d%%" % [guide,int(app.arrival.flap_ratio*100),int(app.arrival.spoiler_ratio*100)]
	telemetry.text = "%d FPS   ·   %.1f ms\nEngine alloc.   %.0f MiB\nRender alloc.   %.0f MiB\nDraw calls       %d\nInternal scale   %d%%" % [Engine.get_frames_per_second(),1000.0/maxf(Engine.get_frames_per_second(),1),float(Performance.get_monitor(Performance.MEMORY_STATIC))/1048576,float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))/1048576,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),int(app.render_scale*100)]
	if app.benchmark.active: record_button.text = "Stop & save  •  %ds" % int(app.benchmark.seconds)
	else: record_button.text = "Record benchmark  [B]"

func update_buttons() -> void:
	for i in camera_buttons.size(): camera_buttons[i].set_pressed_no_signal(app.view_index==i)
	if pause_button: pause_button.text = "Resume  [Space]" if app.paused else "Pause  [Space]"

func notify(text: String) -> void:
	toast.text = text
	notice_seconds = 8.0
