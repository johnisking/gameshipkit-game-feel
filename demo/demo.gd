extends Node2D
## GameShipKit Game Feel demo. Move with WASD or the arrow keys.
## Space hits the closest enemy (light, heavy and crit in turn). Left click shoots toward the mouse.
## Number keys 1 to 4 pick the gun: pistol, smg, shotgun, sniper.

const SPEED := 260.0
const GUNS := ["pistol", "smg", "shotgun", "sniper"]
const TIERS := ["light", "heavy", "crit"]

var player: Node2D
var enemies: Array[Polygon2D] = []
var gun := 0
var combo := 0
var _cooldown := 0.0
var _space_was_down := false
var _hud: Label


func _ready() -> void:
	player = Node2D.new()
	player.add_child(_box(Vector2(36, 36), Color(0.36, 0.75, 1.0)))
	add_child(player)
	var cam := GSKFollowCamera2D.new()
	cam.target = player
	cam.use_bounds = false
	add_child(cam)
	cam.make_current()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 8:
		var e := _box(Vector2(44, 44), Color(1.0, 0.42, 0.36))
		e.position = Vector2(rng.randf_range(-420, 420), rng.randf_range(-260, 260))
		add_child(e)
		enemies.append(e)
	var layer := CanvasLayer.new()
	add_child(layer)
	_hud = Label.new()
	_hud.position = Vector2(16, 12)
	layer.add_child(_hud)


func _box(size: Vector2, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var h := size * 0.5
	p.polygon = PackedVector2Array([Vector2(-h.x, -h.y), Vector2(h.x, -h.y), Vector2(h.x, h.y), Vector2(-h.x, h.y)])
	p.color = color
	return p


func _process(delta: float) -> void:
	var move := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	player.position += move.normalized() * SPEED * delta
	for k in 4:
		if Input.is_physical_key_pressed(KEY_1 + k):
			gun = k
	var space := Input.is_physical_key_pressed(KEY_SPACE)
	if space and not _space_was_down:
		melee()
	_space_was_down = space
	_cooldown -= delta
	var w: Dictionary = HitFeel.WEAPONS[GUNS[gun]]
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _cooldown <= 0.0:
		shoot()
		_cooldown = 1.0 / maxf(0.5, float(w.get("fire_rate", 4.0)))
	_hud.text = "WASD move · Space hit · Click shoot · 1-4 gun: %s" % GUNS[gun]
	queue_redraw()


func _closest(from: Vector2, max_dist: float, dir := Vector2.ZERO) -> Polygon2D:
	var best: Polygon2D = null
	var best_d := max_dist
	for e in enemies:
		var to := e.position - from
		if dir != Vector2.ZERO and to.normalized().dot(dir) < 0.94:
			continue
		if to.length() < best_d:
			best_d = to.length()
			best = e
	return best


func melee() -> void:
	var e := _closest(player.position, 140.0)
	var tier: String = TIERS[combo % TIERS.size()]
	combo += 1
	if e:
		HitFeel.hit(e, e.position - player.position, tier, [12, 28, 64][TIERS.find(tier)])


func shoot() -> void:
	var aim := (get_global_mouse_position() - player.position).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2.RIGHT
	var muzzle := player.position + aim * 26.0
	HitFeel.shoot(muzzle, aim, GUNS[gun])
	var e := _closest(player.position, 900.0, aim)
	if e:
		HitFeel.hit(e, aim, GUNS[gun], [6, 4, 3, 40][gun])


func _draw() -> void:
	var c := Color(1, 1, 1, 0.06)
	for x in range(-1200, 1201, 80):
		draw_line(Vector2(x, -800), Vector2(x, 800), c)
	for y in range(-800, 801, 80):
		draw_line(Vector2(-1200, y), Vector2(1200, y), c)
