extends AudioStreamPlayer
## Original lightweight synthesized engine/reverser loop; no external assets.
var enabled := true

func _ready() -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 44100
	var bytes := PackedByteArray()
	bytes.resize(88200)
	var rng := RandomNumberGenerator.new()
	rng.seed = 260911
	var filtered := 0.0
	for i in 44100:
		filtered = lerpf(filtered,rng.randf_range(-1,1),0.24)
		var t := float(i)/22050.0
		var sample := 0.32*sin(TAU*80*t)+0.1*sin(TAU*160*t)+0.5*filtered
		bytes.encode_s16(i*2,int(sample*22000))
	wav.data = bytes
	stream = wav
	volume_db = -36
	play()

func update_arrival(state: RefCounted, paused: bool) -> void:
	stream_paused = paused or not enabled or state.phase=="PARKED"
	volume_db = lerpf(-33,-12,state.reverse_ratio)
	pitch_scale = 0.7+state.speed_ms/120.0+state.reverse_ratio*0.5
