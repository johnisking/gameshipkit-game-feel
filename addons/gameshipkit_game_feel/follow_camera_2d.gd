class_name GSKFollowCamera2D
extends Camera2D
## 2D follow camera made with GameShipKit Camera System Builder
## https://gameshipkit.com/tools/camera-system-builder/
## Tune deadzone, smoothing and look ahead in the browser there and copy the values into the inspector.
## Shake and zoom punch are added on top of the HitFeel autoload, so both can run at once.

@export var target: Node2D
@export var deadzone := Vector2(60.0, 90.0)
@export var smooth_time := Vector2(0.18, 0.25) ## seconds to catch up, 0 snaps
@export var look_ahead := 80.0
@export var look_ahead_time := 0.5
@export var look_ahead_vertical := false ## true for top down games
@export var vertical_offset := -40.0
@export var base_zoom := 1.0
@export var platform_lock := true ## only follow up and down after landing
@export var use_bounds := true
@export var bounds := Rect2(0, 0, 4800, 1088) ## level rectangle in world pixels
@export var pixel_snap := false
@export_group("Shake")
@export var trauma_fade := 1.2 ## trauma lost per second
@export var max_offset := 18.0
@export var max_angle_degrees := 2.0
@export var shake_speed := 18.0
@export var zoom_punch := 0.08
var _cam := Vector2.ZERO
var _look := Vector2.ZERO
var _last := Vector2.ZERO
var _trauma := 0.0
var _own_offset := Vector2.ZERO
var _own_rot := 0.0
var _own_zoom := 1.0
var _punch := 0.0
var _time := 0.0
var _noise := FastNoiseLite.new()

func _ready() -> void:
	position_smoothing_enabled = false
	ignore_rotation = false
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	zoom = Vector2.ONE
	if target:
		_last = target.global_position
		_cam = _focus_point()
	global_position = _cam

func _focus_point() -> Vector2:
	return target.global_position + Vector2(0.0, vertical_offset) + _look

func _k(t: float, delta: float) -> float:
	return 1.0 if t <= 0.0 else 1.0 - exp(-delta / t)

func _process(delta: float) -> void:
	if target == null or delta <= 0.0:
		return
	var p := target.global_position
	var vel := (p - _last) / delta
	_last = p
	var want := _look
	if look_ahead_vertical:
		if vel.length() > 10.0:
			want = vel.normalized() * look_ahead
	elif absf(vel.x) > 10.0:
		want = Vector2(signf(vel.x) * look_ahead, 0.0)
	_look = _look.lerp(want, _k(look_ahead_time, delta))
	var f := _focus_point()
	var half := deadzone * 0.5
	var goal := _cam
	if f.x > _cam.x + half.x:
		goal.x = f.x - half.x
	elif f.x < _cam.x - half.x:
		goal.x = f.x + half.x
	var view_half := get_viewport_rect().size / zoom * 0.5
	var follow_y := true
	if platform_lock and target is CharacterBody2D:
		follow_y = (target as CharacterBody2D).is_on_floor() or absf(f.y - _cam.y) > view_half.y * 0.6
	if follow_y:
		if f.y > _cam.y + half.y:
			goal.y = f.y - half.y
		elif f.y < _cam.y - half.y:
			goal.y = f.y + half.y
	_cam.x = lerpf(_cam.x, goal.x, _k(smooth_time.x, delta))
	_cam.y = lerpf(_cam.y, goal.y, _k(smooth_time.y, delta))
	if use_bounds:
		var lim := (get_viewport_rect().size / Vector2(base_zoom, base_zoom)) * 0.5
		_cam.x = bounds.get_center().x if bounds.size.x < lim.x * 2.0 else clampf(_cam.x, bounds.position.x + lim.x, bounds.end.x - lim.x)
		_cam.y = bounds.get_center().y if bounds.size.y < lim.y * 2.0 else clampf(_cam.y, bounds.position.y + lim.y, bounds.end.y - lim.y)
	var pos := _cam
	_time += delta
	_trauma = maxf(0.0, _trauma - trauma_fade * delta)
	_punch = maxf(0.0, _punch - delta * 4.0)
	var s := _trauma * _trauma
	var t := _time * shake_speed
	var off := Vector2(_noise.get_noise_2d(1.0, t), _noise.get_noise_2d(2.0, t)) * max_offset * s
	offset += off - _own_offset
	_own_offset = off
	var rot := deg_to_rad(max_angle_degrees) * s * _noise.get_noise_2d(3.0, t)
	rotation += rot - _own_rot
	_own_rot = rot
	var z := base_zoom * (1.0 + zoom_punch * sin(PI * _punch) * 0.5)
	zoom = zoom / _own_zoom * z
	_own_zoom = z
	if pixel_snap:
		pos = (pos * zoom.x).round() / zoom.x
	global_position = pos

## Call this on hits, explosions and hard landings. 0.3 is a nudge, 1.0 is a big boom.
func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)
	_punch = 1.0
