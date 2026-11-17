extends Node
## 音频管理：BGM 单实例 + SFX 临时池。
## M0 只立骨架；音频资源在 M4 统一铺设。播放接口按 res:// 路径直传。

var _bgm: AudioStreamPlayer
var _current_bgm := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bgm = AudioStreamPlayer.new()
	_bgm.bus = &"Master"
	add_child(_bgm)


func play_bgm(stream_path: String, volume_db := 0.0) -> void:
	if _current_bgm == stream_path and _bgm.playing:
		return
	var stream := load(stream_path) as AudioStream
	if stream == null:
		push_warning("BGM 不存在: %s" % stream_path)
		return
	_bgm.stream = stream
	_bgm.volume_db = volume_db
	_bgm.play()
	_current_bgm = stream_path


func stop_bgm() -> void:
	_bgm.stop()
	_current_bgm = ""


func play_sfx(stream_path: String, volume_db := 0.0) -> void:
	var stream := load(stream_path) as AudioStream
	if stream == null:
		push_warning("SFX 不存在: %s" % stream_path)
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.bus = &"Master"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
