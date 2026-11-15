extends Node2D

@export var starting_lives: int = 3
@export var wall_thickness: float = 20.0
@export var wall_color: Color = Color.WHITE
@export var background_color: Color = Color(0.08, 0.08, 0.12)

@onready var ball: Ball = $Ball
@onready var paddle: Paddle = $Paddle

var screen_size: Vector2
var score: int = 0
var lives: int = 0
var is_game_over: bool = false

var hud_label: Label
var message_label: Label


func _ready() -> void:
	screen_size = get_viewport_rect().size
	_create_walls()
	_create_hud()

	ball.missed.connect(_on_ball_missed)
	ball.paddle_hit.connect(_on_ball_paddle_hit)

	# Paddle sits near the bottom, centered
	paddle.position = Vector2(screen_size.x * 0.5, screen_size.y - 40.0)

	_start_new_game()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), background_color)
	for wall_rect in _get_wall_rects():
		draw_rect(wall_rect, wall_color)


# Top, left, and right walls. The bottom is open so the ball can fall past the paddle.
func _get_wall_rects() -> Array:
	var t := wall_thickness
	var w := screen_size.x
	var h := screen_size.y
	return [
		Rect2(-t, -t, w + t * 2.0, t),  # top wall
		Rect2(-t, 0.0, t, h),           # left wall
		Rect2(w, 0.0, t, h),            # right wall
	]


func _create_walls() -> void:
	for wall_rect in _get_wall_rects():
		var wall := StaticBody2D.new()
		wall.position = wall_rect.get_center()
		var shape := RectangleShape2D.new()
		shape.size = wall_rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		wall.add_child(collider)
		add_child(wall)


func _create_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)

	hud_label = Label.new()
	hud_label.position = Vector2(30.0, 20.0)
	hud_label.add_theme_font_size_override("font_size", 28)
	hud.add_child(hud_label)

	message_label = Label.new()
	message_label.position = Vector2(0.0, screen_size.y * 0.5 - 60.0)
	message_label.size = Vector2(screen_size.x, 120.0)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 36)
	message_label.visible = false
	hud.add_child(message_label)


func _start_new_game() -> void:
	score = 0
	lives = starting_lives
	is_game_over = false
	message_label.visible = false
	paddle.set_physics_process(true)
	_update_hud()
	_serve_ball()


func _serve_ball() -> void:
	ball.serve(screen_size * 0.5)


func _on_ball_missed() -> void:
	lives -= 1
	if lives <= 0:
		_end_game()
	else:
		_serve_ball()
	_update_hud()


func _on_ball_paddle_hit() -> void:
	score += 1
	_update_hud()


func _end_game() -> void:
	is_game_over = true
	ball.stop()
	paddle.set_physics_process(false)
	message_label.text = "GAME OVER\nScore: %d\nPress ENTER to play again" % score
	message_label.visible = true


func _update_hud() -> void:
	hud_label.text = "Score: %d    Lives: %d" % [score, lives]


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over and event.is_action_pressed("ui_accept"):
		_start_new_game()
