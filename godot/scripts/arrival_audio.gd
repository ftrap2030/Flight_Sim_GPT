extends AudioStreamPlayer
## Small original synthesized sound set; speech uses browser-local voices only.
var enabled := true
var wheels: AudioStreamPlayer
var flaps: AudioStreamPlayer
var touchdown: AudioStreamPlayer
var previous_time := -1.0
var previous_height := -1.0
var previous_flaps := -1.0
var previously_grounded := false
var was_silent := false
var last_callout := ""
var caption_seconds := 0.0
var played_callouts: Array[int] = []
const CALLOUTS := [1000,500,100,50,40,30,20,10]

func _ready() -> void:
	stream = _sound("engine",2.0,true)
	volume_db = -34
	play()
	wheels = _player("wheels",1.0,true)
	flaps = _player("flaps",1.0,true)
	touchdown = _player("touchdown",0.65,false)

func _player(kind: String, duration: float, loop: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = _sound(kind,duration,loop)
	player.volume_db = -60
	add_child(player)
	if loop: player.play()
	return player

func _sound(kind: String, duration: float, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var count := int(duration*22050)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	wav.loop_end = count
	var bytes := PackedByteArray()
	bytes.resize(count*2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 260911+kind.hash()
	var filtered := 0.0
	for i in count:
		filtered = lerpf(filtered,rng.randf_range(-1,1),0.2)
		var t := float(i)/22050.0
		var sample := 0.28*sin(TAU*80*t)+0.08*sin(TAU*240*t)+0.5*filtered
		if kind=="wheels": sample = filtered*0.9+0.09*sin(TAU*36*t)*(0.6+0.4*sin(TAU*8*t))
		elif kind=="flaps": sample = 0.19*sin(TAU*180*t)+0.07*sin(TAU*360*t)+0.2*filtered
		elif kind=="touchdown": sample = (0.7*sin(TAU*48*t)+1.1*filtered)*exp(-t*9)
		var envelope := minf(1,minf(t/0.015,(duration-t)/0.015))
		bytes.encode_s16(i*2,int(clampf(sample*envelope,-1,1)*22000))
	wav.data = bytes
	return wav

func _cancel_voice() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if(window.miamiVoice)window.miamiVoice.cancel();")

func reset_sequence() -> void:
	_cancel_voice()
	played_callouts.clear()
	previous_height = -1
	previous_flaps = -1
	previously_grounded = false
	caption_seconds = 0
	last_callout = ""
	touchdown.stop()

func update_arrival(state: RefCounted, paused: bool) -> void:
	if state.time<previous_time: reset_sequence()
	var dt := maxf(0,state.time-previous_time) if previous_time>=0 else 0.0
	previous_time = state.time
	caption_seconds = maxf(0,caption_seconds-dt)
	var silent := paused or not enabled
	if silent and not was_silent: _cancel_voice()
	was_silent = silent
	stream_paused = silent
	wheels.stream_paused = silent
	flaps.stream_paused = silent
	touchdown.stream_paused = silent
	# Keep a quiet engine idle at the gate; reverse has a deeper, louder layer.
	volume_db = -32+state.reverse_ratio*17+minf(state.speed_ms/75.0,1.0)*3
	pitch_scale = 0.75+state.speed_ms/180.0+state.reverse_ratio*0.3
	wheels.volume_db = lerpf(-60,-22,clampf(state.speed_ms/65.0,0,1)) if state.on_ground() else -60
	wheels.pitch_scale = 0.65+state.speed_ms/75.0
	var moving_flaps: bool = previous_flaps>=0 and absf(state.flap_ratio-previous_flaps)>0.00001
	flaps.volume_db = -26 if moving_flaps else -60
	previous_flaps = state.flap_ratio
	if state.on_ground() and not previously_grounded and not silent:
		touchdown.volume_db = -14
		touchdown.play()
	previously_grounded = state.on_ground()
	var pitch: float = deg_to_rad(state.pitch_deg)
	var height: float = maxf(0,state.height-3.16*cos(pitch)-17.4*sin(pitch))/0.3048
	if previous_height>=0 and not state.on_ground():
		for threshold in CALLOUTS:
			if previous_height>threshold and height<=threshold and threshold not in played_callouts:
				played_callouts.append(threshold)
				if not silent:
					last_callout = str(threshold)
					caption_seconds = 1.5
					if OS.has_feature("web"):
						JavaScriptBridge.eval("if(window.miamiVoice)window.miamiVoice.say("+JSON.stringify(last_callout)+");")
	previous_height = height
