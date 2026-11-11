extends Node
## GameShipKit Hit Feel Designer · melee: Arcade action · shooter: Arcade shooter
## https://gameshipkit.com/tools/hit-feel-designer/
## Godot 4.2+. The GameShipKit Game Feel plugin adds this script as an autoload named HitFeel.
## Tune every value in your browser at https://gameshipkit.com/tools/hit-feel-designer/ and paste the new constants here.
## Melee hit:  HitFeel.hit($Enemy/Sprite2D, (enemy.global_position - global_position), "heavy", 42)
##   target: the CanvasItem that flashes and gets pushed. dir: the direction of the hit.
##   tier: "light", "heavy", "crit" or a weapon name. damage: the number to pop up (-1 for none).
## Shooting:   HitFeel.shoot($Gun/Muzzle.global_position, aim_direction, "shotgun")  when the gun fires,
##             HitFeel.hit(enemy_sprite, bullet_direction, "shotgun", 8)  when your bullet hits.
##   Weapons: "pistol", "smg", "shotgun", "sniper". WEAPONS also has fire rate, pellets and spread for your gun code.
## If your enemy has a method apply_knockback(force: Vector2) it is called instead of the visual push.
## hit_*.wav and shot_*.wav next to this script are played by themselves.

@export var camera: Camera2D           ## leave empty to use the current Camera2D
@export_range(0.0, 1.0) var intensity := 1.0   ## tie this to a "screen shake" option in your menu
@export var reduce_flashing := false   ## turns off screen flash and impact frames
@export var damage_numbers := true

const TIERS := {
	"light": {"hit_stop": 0.045, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.25, "zoom_punch": 0.01,
		"flash": 0.06, "knockback": 12.0, "squash": 0.15, "sparks": 10, "spark_speed": 340.0, "shockwave": 0.0,
		"screen_flash": 0.0, "impact_frame": 0.0, "number_size": 18, "rumble": 0.2, "rumble_time": 0.05},
	"heavy": {"hit_stop": 0.095, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.5, "zoom_punch": 0.035,
		"flash": 0.09, "knockback": 30.0, "squash": 0.25, "sparks": 20, "spark_speed": 440.0, "shockwave": 70.0,
		"screen_flash": 0.06, "impact_frame": 0.0, "number_size": 24, "rumble": 0.5, "rumble_time": 0.11},
	"crit": {"hit_stop": 0.14, "slow_motion": 0.3, "slow_scale": 0.35, "trauma": 0.75, "zoom_punch": 0.06,
		"flash": 0.11, "knockback": 48.0, "squash": 0.32, "sparks": 32, "spark_speed": 520.0, "shockwave": 110.0,
		"screen_flash": 0.2, "impact_frame": 0.0, "number_size": 34, "rumble": 0.8, "rumble_time": 0.18},
	"pistol": {"hit_stop": 0.012, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.0, "zoom_punch": 0.0,
		"flash": 0.045, "knockback": 6.0, "squash": 0.05, "sparks": 6, "spark_speed": 280.0, "shockwave": 0.0,
		"screen_flash": 0.0, "impact_frame": 0.0, "number_size": 16, "rumble": 0.0, "rumble_time": 0.04},
	"smg": {"hit_stop": 0.0, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.0, "zoom_punch": 0.0,
		"flash": 0.03, "knockback": 3.0, "squash": 0.03, "sparks": 3, "spark_speed": 280.0, "shockwave": 0.0,
		"screen_flash": 0.0, "impact_frame": 0.0, "number_size": 13, "rumble": 0.0, "rumble_time": 0.03},
	"shotgun": {"hit_stop": 0.045, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.0, "zoom_punch": 0.02,
		"flash": 0.07, "knockback": 26.0, "squash": 0.2, "sparks": 14, "spark_speed": 380.0, "shockwave": 0.0,
		"screen_flash": 0.0, "impact_frame": 0.0, "number_size": 20, "rumble": 0.0, "rumble_time": 0.12},
	"sniper": {"hit_stop": 0.09, "slow_motion": 0.0, "slow_scale": 1.0, "trauma": 0.0, "zoom_punch": 0.04,
		"flash": 0.09, "knockback": 30.0, "squash": 0.2, "sparks": 18, "spark_speed": 500.0, "shockwave": 70.0,
		"screen_flash": 0.0, "impact_frame": 0.0, "number_size": 28, "rumble": 0.0, "rumble_time": 0.14},
}
const WEAPONS := {
	"pistol": {"fire_rate": 5.0, "automatic": false, "pellets": 1, "spread_degrees": 1.5, "bullet_speed": 2200.0,
		"camera_kick": 5.0, "shot_trauma": 0.12, "muzzle_flash": 26.0, "shell_casings": true, "hit_marker": true,
		"rumble": 0.2, "rumble_time": 0.04},
	"smg": {"fire_rate": 12.0, "automatic": true, "pellets": 1, "spread_degrees": 4.0, "bullet_speed": 2200.0,
		"camera_kick": 2.5, "shot_trauma": 0.07, "muzzle_flash": 20.0, "shell_casings": true, "hit_marker": true,
		"rumble": 0.15, "rumble_time": 0.03},
	"shotgun": {"fire_rate": 1.4, "automatic": false, "pellets": 8, "spread_degrees": 9.0, "bullet_speed": 1800.0,
		"camera_kick": 14.0, "shot_trauma": 0.4, "muzzle_flash": 44.0, "shell_casings": true, "hit_marker": true,
		"rumble": 0.6, "rumble_time": 0.12},
	"sniper": {"fire_rate": 0.8, "automatic": false, "pellets": 1, "spread_degrees": 0.0, "bullet_speed": 4000.0,
		"camera_kick": 18.0, "shot_trauma": 0.45, "muzzle_flash": 52.0, "shell_casings": true, "hit_marker": true,
		"rumble": 0.7, "rumble_time": 0.14},
}
const SHAKE_MAX_OFFSET := 14.0
const SHAKE_MAX_ANGLE := 1.5
const SHAKE_SPEED := 22.0
const SHAKE_FADE := 1.6
const SHAKE_DIRECTION_BIAS := 0.5
const PIXEL_SNAP := false
const SPARK_COLOR := Color(1.0, 0.827, 0.42)
const PITCH_VARIATION := 0.08

const FLASH_SHADER := """shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);
void fragment() {
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash);
}"""
const IMPACT_SHADER := """shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform bool dark = true;
void fragment() {
	float l = dot(texture(screen_tex, SCREEN_UV).rgb, vec3(0.299, 0.587, 0.114));
	float s = step(0.35, l);
	COLOR = vec4(vec3(dark ? s : 1.0 - s), 1.0);
}"""

var _trauma := 0.0
var _dir := Vector2.RIGHT
var _punch := 0.0
var _clock := 0.0
var _last_us := 0
var _freeze_until := 0
var _slow_until := 0
var _slow_len := 0.0
var _slow_scale := 1.0
var _owns_time := false
var _cam_offset := Vector2.ZERO
var _cam_rot := 0.0
var _cam_zoom := 1.0
var _cam: Camera2D
var _noise := FastNoiseLite.new()
var _flash_shader := Shader.new()
var _flashes := []   # {node, mat, until, old_modulate}
var _knocks := []    # {node, push, squash, t, off, mul}
var _numbers := []   # {label, t}
var _rings := []     # {node, t, size}
var _sounds := {}
var _layer: CanvasLayer
var _screen: ColorRect
var _impact: ColorRect
var _impact_until := 0
var _impact_start := 0
var _kick := Vector2.ZERO
var _timed := []     # {node, until}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_us = Time.get_ticks_usec()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_flash_shader.code = FLASH_SHADER
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_impact = ColorRect.new()
	_impact.set_anchors_preset(Control.PRESET_FULL_RECT)
	_impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var im := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = IMPACT_SHADER
	im.shader = sh
	_impact.material = im
	_impact.visible = false
	_layer.add_child(_impact)
	_screen = ColorRect.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.color = Color(1, 1, 1, 0)
	_layer.add_child(_screen)
	var dir: String = get_script().resource_path.get_base_dir() + "/sounds"
	for t in TIERS:
		_load_sound(dir, "hit_" + t)
	for w in WEAPONS:
		_load_sound(dir, "shot_" + w)

func _load_sound(dir: String, sound_name: String) -> void:
	var p := dir.path_join(sound_name + ".wav")
	if ResourceLoader.exists(p):
		_sounds[sound_name] = load(p)

## Plays every effect of one hit tier on the target.
func hit(target: Node, dir := Vector2.RIGHT, tier := "light", damage := -1) -> void:
	var p: Dictionary = TIERS.get(tier, TIERS["light"])
	dir = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	var pos := Vector2.ZERO
	var node2d := target as Node2D
	if node2d:
		pos = node2d.global_position
	play_sound("hit_" + tier)
	add_trauma(p.trauma, dir)
	_punch = max(_punch, p.zoom_punch * intensity)
	if target is CanvasItem and p.flash > 0.0:
		flash(target as CanvasItem, p.flash)
	if node2d:
		if target.has_method("apply_knockback"):
			target.call("apply_knockback", dir * p.knockback)
		elif p.knockback > 0.0 or p.squash > 0.0:
			_knocks.append({"node": node2d, "push": dir * p.knockback, "squash": p.squash, "t": 0.0, "off": Vector2.ZERO, "mul": Vector2.ONE})
		if p.sparks > 0:
			sparks(pos, dir, p.sparks, p.spark_speed)
		if p.shockwave > 0.0:
			shockwave(pos, p.shockwave)
		if damage_numbers and damage >= 0:
			damage_number(pos, damage, tier == "crit" or tier == "sniper", p.number_size)
		if WEAPONS.has(tier) and WEAPONS[tier].hit_marker:
			hit_marker(pos - dir * 20.0)
	if not reduce_flashing:
		if p.screen_flash > 0.0:
			_screen.color.a = max(_screen.color.a, p.screen_flash)
		if p.impact_frame > 0.0:
			_impact_start = Time.get_ticks_msec()
			_impact_until = _impact_start + int(p.impact_frame * 1000.0)
	if p.rumble > 0.0:
		for id in Input.get_connected_joypads():
			Input.start_joy_vibration(id, p.rumble * 0.7, p.rumble, p.rumble_time)
	if p.slow_motion > 0.0:
		slow_motion(p.slow_scale, p.slow_motion, p.hit_stop)
	if p.hit_stop > 0.0:
		hit_stop(p.hit_stop)

## Plays the firing effects of a weapon: sound, camera kick, shake, muzzle flash, shell and rumble.
## Move your own bullets. When one hits, call hit(target, dir, weapon, damage).
func shoot(muzzle: Vector2, dir := Vector2.RIGHT, weapon := "pistol") -> void:
	var w: Dictionary = WEAPONS.get(weapon, WEAPONS["pistol"])
	dir = dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	play_sound("shot_" + weapon)
	add_trauma(w.shot_trauma, -dir)
	_kick += -dir * w.camera_kick * intensity
	if w.muzzle_flash > 0.0:
		muzzle_flash(muzzle, dir, w.muzzle_flash)
	if w.shell_casings:
		shell(muzzle, dir)
	if w.rumble > 0.0:
		for id in Input.get_connected_joypads():
			Input.start_joy_vibration(id, w.rumble * 0.7, w.rumble, w.rumble_time)

func muzzle_flash(pos: Vector2, dir: Vector2, size: float) -> void:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 10:
		var a := TAU * i / 10.0
		var r := size * (1.4 if i == 0 else (0.35 if i % 2 == 1 else 0.55))
		pts.append(Vector2(cos(a) * r, sin(a) * r * 0.7))
	p.polygon = pts
	p.color = Color(1.0, 0.84, 0.43, 0.95)
	p.z_index = 102
	_world().add_child(p)
	p.global_position = pos
	p.rotation = dir.angle()
	_timed.append({"node": p, "until": Time.get_ticks_msec() + 50})

func shell(pos: Vector2, dir: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 1
	p.lifetime = 1.0
	p.direction = Vector2(-dir.x, -1.5).normalized()
	p.spread = 15.0
	p.gravity = Vector2(0, 1100)
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 260.0
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 3.0
	p.color = Color(0.89, 0.7, 0.24)
	p.z_index = 100
	_world().add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

func hit_marker(pos: Vector2) -> void:
	var n := Node2D.new()
	for d in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		var l := Line2D.new()
		l.width = 2.5
		l.default_color = Color.WHITE
		l.points = PackedVector2Array([d * 4.0, d * 9.0])
		n.add_child(l)
	n.z_index = 103
	_world().add_child(n)
	n.global_position = pos
	_timed.append({"node": n, "until": Time.get_ticks_msec() + 180})

func hit_stop(seconds: float) -> void:
	_freeze_until = max(_freeze_until, Time.get_ticks_msec() + int(seconds * 1000.0))

func slow_motion(time_scale: float, seconds: float, delay := 0.0) -> void:
	_slow_scale = time_scale
	_slow_len = seconds
	_slow_until = Time.get_ticks_msec() + int((delay + seconds) * 1000.0)

func add_trauma(amount: float, dir := Vector2.ZERO) -> void:
	_trauma = min(1.0, _trauma + amount * intensity)
	if dir != Vector2.ZERO:
		_dir = dir.normalized()

func flash(item: CanvasItem, seconds: float) -> void:
	for e in _flashes:
		if e.node == item:
			e.until = Time.get_ticks_msec() + int(seconds * 1000.0)
			return
	var f := {"node": item, "until": Time.get_ticks_msec() + int(seconds * 1000.0), "mat": null, "old": item.modulate}
	if item.material == null or (item.material is ShaderMaterial and (item.material as ShaderMaterial).shader == _flash_shader):
		if item.material == null:
			var m := ShaderMaterial.new()
			m.shader = _flash_shader
			item.material = m
		f.mat = item.material
		f.mat.set_shader_parameter("flash", 1.0)
	else:
		item.modulate = Color(4, 4, 4, item.modulate.a)   # the item has its own material: brighten instead
	_flashes.append(f)

func sparks(pos: Vector2, dir: Vector2, amount: int, speed: float) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = max(1, amount)
	p.lifetime = 0.4
	p.direction = dir
	p.spread = 40.0
	p.gravity = Vector2(0, 600)
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.damping_min = speed * 0.8
	p.damping_max = speed * 1.6
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = SPARK_COLOR
	p.z_index = 100
	_world().add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

func shockwave(pos: Vector2, radius: float) -> void:
	var r := Line2D.new()
	r.width = 5.0
	r.default_color = Color(1, 1, 1, 0.8)
	r.z_index = 99
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a) * 0.75))
	r.points = pts
	_world().add_child(r)
	r.global_position = pos
	r.scale = Vector2.ONE
	_rings.append({"node": r, "t": 0.0, "size": radius})

func damage_number(pos: Vector2, value: int, crit: bool, size: int) -> void:
	var l := Label.new()
	l.text = str(value) + ("!" if crit else "")
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(1, 0.36, 0.36) if crit else Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", max(4, size / 4))
	l.z_index = 101
	_world().add_child(l)
	l.reset_size()
	l.pivot_offset = l.size / 2.0
	l.global_position = pos + Vector2(randf_range(-10, 10), -size * 3.0) - l.size / 2.0
	_numbers.append({"label": l, "t": 0.0, "y": l.position.y})

func play_sound(sound_name: String) -> void:
	if not _sounds.has(sound_name):
		return
	var a := AudioStreamPlayer.new()
	a.stream = _sounds[sound_name]
	a.pitch_scale = 1.0 + randf_range(-PITCH_VARIATION, PITCH_VARIATION)
	add_child(a)
	a.play()
	a.finished.connect(a.queue_free)

func _world() -> Node:
	var s := get_tree().current_scene
	return s if s else get_tree().root

func _process(_delta: float) -> void:
	var now_us := Time.get_ticks_usec()
	var dt: float = minf(0.05, (now_us - _last_us) / 1000000.0)
	_last_us = now_us
	var now := Time.get_ticks_msec()
	# time: hit stop, then slow motion that eases back at the end
	var ts := 1.0
	if now < _slow_until:
		var left := (_slow_until - now) / 1000.0
		ts = lerp(1.0, _slow_scale, clamp(left / max(_slow_len * 0.3, 0.001), 0.0, 1.0))
	if now < _freeze_until:
		ts = 0.0
	if ts < 1.0:
		Engine.time_scale = ts
		_owns_time = true
	elif _owns_time:
		Engine.time_scale = 1.0
		_owns_time = false
	var gdt := dt * ts
	_shake(dt)
	# flashes run on real time
	for f in _flashes.duplicate():
		if not is_instance_valid(f.node) or now >= f.until:
			if is_instance_valid(f.node):
				if f.mat:
					f.mat.set_shader_parameter("flash", 0.0)
				else:
					f.node.modulate = f.old
			_flashes.erase(f)
	# knockback and squash freeze with the game
	for k in _knocks.duplicate():
		if not is_instance_valid(k.node):
			_knocks.erase(k)
			continue
		k.t += gdt
		var a := 0.07
		var b := 0.35
		var push := 0.0
		if k.t < a:
			push = 1.0 - pow(1.0 - k.t / a, 3.0)
		elif k.t < a + b:
			var x: float = (k.t - a) / b
			push = 1.0 - (4.0 * x * x * x if x < 0.5 else 1.0 - pow(-2.0 * x + 2.0, 3.0) / 2.0)
		var off: Vector2 = k.push * push
		var s: float = exp(-7.0 * k.t) * cos(26.0 * k.t) * k.squash if k.t < 0.6 else 0.0
		var mul := Vector2(1.0 + s, 1.0 - s)
		k.node.position += off - k.off
		k.node.scale = k.node.scale / k.mul * mul
		k.off = off
		k.mul = mul
		if k.t >= max(a + b, 0.6):
			_knocks.erase(k)
	for r in _rings.duplicate():
		r.t += gdt
		var q: float = r.t / 0.28
		if q >= 1.0 or not is_instance_valid(r.node):
			if is_instance_valid(r.node):
				r.node.queue_free()
			_rings.erase(r)
			continue
		r.node.scale = Vector2.ONE * r.size * (1.0 - pow(1.0 - q, 3.0))
		r.node.width = (6.0 * (1.0 - q) + 1.0) / max(r.node.scale.x, 0.01)
		r.node.default_color.a = (1.0 - q) * 0.8
	for n in _numbers.duplicate():
		n.t += gdt
		var l: Label = n.label
		if not is_instance_valid(l) or n.t >= 0.9:
			if is_instance_valid(l):
				l.queue_free()
			_numbers.erase(n)
			continue
		var pop: float = 1.7 - 0.7 * (n.t / 0.1) if n.t < 0.1 else 1.0
		l.scale = Vector2.ONE * pop
		l.position.y = n.y - 52.0 * (1.0 - pow(1.0 - min(1.0, n.t / 0.9), 3.0))
		l.modulate.a = 1.0 if n.t < 0.6 else 1.0 - (n.t - 0.6) / 0.3
	for e in _timed.duplicate():
		if not is_instance_valid(e.node) or now >= e.until:
			if is_instance_valid(e.node):
				e.node.queue_free()
			_timed.erase(e)
	_screen.color.a *= exp(-22.0 * dt)
	if now < _impact_until:
		_impact.visible = true
		(_impact.material as ShaderMaterial).set_shader_parameter("dark", now - _impact_start < (_impact_until - _impact_start) / 2)
	else:
		_impact.visible = false

func _shake(dt: float) -> void:
	var cam := camera if is_instance_valid(camera) else get_viewport().get_camera_2d()
	if cam != _cam:
		_cam = cam
		_cam_offset = Vector2.ZERO
		_cam_rot = 0.0
		_cam_zoom = 1.0
	if cam == null:
		return
	_trauma = max(0.0, _trauma - SHAKE_FADE * dt)
	_punch *= exp(-12.0 * dt)
	_clock += dt
	var tr := _trauma * _trauma
	var off := Vector2.ZERO
	var rot := 0.0
	if tr > 0.0:
		var t := _clock * SHAKE_SPEED
		var rand_dir := Vector2(_noise.get_noise_2d(t, 13.0), _noise.get_noise_2d(t, 79.0))
		var kick := _dir * absf(_noise.get_noise_2d(t, 42.0)) * 1.6
		off = rand_dir.lerp(kick, SHAKE_DIRECTION_BIAS) * SHAKE_MAX_OFFSET * tr
		rot = deg_to_rad(SHAKE_MAX_ANGLE) * _noise.get_noise_2d(t, 111.0) * tr
	off += _kick
	_kick *= exp(-16.0 * dt)
	if PIXEL_SNAP:
		off = off.round()
		rot = 0.0
	cam.offset += off - _cam_offset
	_cam_offset = off
	if not cam.ignore_rotation:
		cam.rotation += rot - _cam_rot
		_cam_rot = rot
	var z := 1.0 + _punch
	cam.zoom = cam.zoom / _cam_zoom * z
	_cam_zoom = z
