class_name Ball
extends CharacterBody2D

signal missed       # emitted when the ball falls past the bottom of the screen
signal paddle_hit   # emitted every time the paddle hits the ball

@export_group("Look")
@export var ball_texture: Texture2D            # drag your own image here
@export var ball_color: Color = Color.WHITE    # used only when no image is set

@export_group("Size and Speed")
@export var radius: float = 12.0
@export var start_speed: float = 350.0
@export var speed_up_per_hit: float = 15.0
@export var max_speed: float = 700.0
@export var max_bounce_angle: float = 60.0     # degrees; sharper bounce at paddle edges
@export var random_angle: float = 5.0          # degrees of random extra bounce per paddle hit


func _ready() -> void:
	# Build the collision shape in code so it always matches the radius
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)


func _draw() -> void:
	var draw_area := Rect2(-radius, -radius, radius * 2.0, radius * 2.0)
	if ball_texture != null:
		draw_texture_rect(ball_texture, draw_area, false)
	else:
		draw_circle(Vector2.ZERO, radius, ball_color)


func serve(start_position: Vector2) -> void:
	global_position = start_position
	# Random launch: straight up, tilted between -50 and +50 degrees
	var direction := Vector2.UP.rotated(deg_to_rad(randf_range(-50.0, 50.0)))
	velocity = direction * start_speed
	visible = true
	queue_redraw()
	set_physics_process(true)


func stop() -> void:
	velocity = Vector2.ZERO
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		var normal := collision.get_normal()
		var hit_paddle := collision.get_collider() as Paddle
		if hit_paddle != null:
			_bounce_off_paddle(hit_paddle)
		else:
			velocity = velocity.bounce(normal)  # walls: simple reflection
		# Keep moving with the leftover distance so motion isn't lost
		move_and_collide(collision.get_remainder().bounce(normal))

	# Ball fell past the bottom of the screen
	if global_position.y > get_viewport_rect().size.y + radius:
		missed.emit()


func _bounce_off_paddle(paddle: Paddle) -> void:
	var half_width := paddle.width * 0.5
	# -1 = far left edge of paddle, 0 = center, +1 = far right edge
	var hit_offset := clampf((global_position.x - paddle.global_position.x) / half_width, -1.0, 1.0)
	var bounce_angle := hit_offset * deg_to_rad(max_bounce_angle)
	bounce_angle += deg_to_rad(randf_range(-random_angle, random_angle))
	var new_speed := minf(velocity.length() + speed_up_per_hit, max_speed)
	velocity = Vector2.UP.rotated(bounce_angle) * new_speed
	paddle_hit.emit()
