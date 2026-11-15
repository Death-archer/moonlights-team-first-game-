class_name Paddle
extends CharacterBody2D

@export var width: float = 120.0
@export var height: float = 16.0
@export var speed: float = 500.0
@export var color: Color = Color.WHITE

var screen_width: float = 800.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING  # no gravity or floor logic
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, height)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	screen_width = get_viewport_rect().size.x
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-width * 0.5, -height * 0.5, width, height), color)


func _physics_process(_delta: float) -> void:
	# Input.get_axis returns -1 (left arrow), 0 (no key), or +1 (right arrow)
	var direction := Input.get_axis("ui_left", "ui_right")
	velocity = Vector2(direction * speed, 0.0)
	move_and_slide()
	# Safety clamp so the paddle never leaves the play area
	position.x = clampf(position.x, width * 0.5, screen_width - width * 0.5)
