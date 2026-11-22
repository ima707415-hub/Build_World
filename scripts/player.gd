extends CharacterBody2D
class_name BWPlayer

@export var move_speed: float = 190.0
var touch_direction: Vector2 = Vector2.ZERO

func _physics_process(_delta: float) -> void:
    var direction := Vector2.ZERO
    direction.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
    direction.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    if touch_direction.length() > 0.1:
        direction = touch_direction
    velocity = direction.normalized() * move_speed
    move_and_slide()
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2(0, 3), 13, Color(0.12, 0.10, 0.08, 0.28))
    draw_circle(Vector2.ZERO, 12, Color("#e9b77e"))
    draw_circle(Vector2(0, -3), 8, Color("#f4d1a1"))
    draw_rect(Rect2(-10, 7, 20, 13), Color("#3d6fa8"))
    draw_circle(Vector2(-3, -4), 1.5, Color("#242424"))
    draw_circle(Vector2(3, -4), 1.5, Color("#242424"))
