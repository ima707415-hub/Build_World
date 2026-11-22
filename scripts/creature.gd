extends Node2D
class_name BWCreature

var kind: String = "rabbit"
var target: Node2D
var speed: float = 38.0
var wander_direction := Vector2.ZERO
var change_direction_time := 0.0
var rng := RandomNumberGenerator.new()

func setup(creature_kind: String, player: Node2D, random_seed: int) -> void:
    kind = creature_kind
    target = player
    rng.seed = random_seed
    match kind:
        "rabbit": speed = 52.0
        "boar": speed = 34.0
        "slime": speed = 25.0

func _process(delta: float) -> void:
    if not is_instance_valid(target):
        return
    change_direction_time -= delta
    var distance := global_position.distance_to(target.global_position)
    var direction := wander_direction
    if kind == "rabbit" and distance < 150.0:
        direction = (global_position - target.global_position).normalized()
    elif kind == "boar" and distance < 190.0:
        direction = (target.global_position - global_position).normalized()
    elif kind == "slime" and distance < 120.0:
        direction = (target.global_position - global_position).normalized()
    elif change_direction_time <= 0.0:
        wander_direction = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
        direction = wander_direction
        change_direction_time = rng.randf_range(1.2, 3.5)
    global_position += direction * speed * delta
    queue_redraw()

func _draw() -> void:
    match kind:
        "rabbit":
            draw_circle(Vector2(0, 2), 9, Color("#eee5d5"))
            draw_circle(Vector2(-4, -8), 3, Color("#eee5d5"))
            draw_circle(Vector2(4, -8), 3, Color("#eee5d5"))
            draw_circle(Vector2(3, -1), 1.3, Color("#292929"))
        "boar":
            draw_circle(Vector2.ZERO, 11, Color("#76513a"))
            draw_circle(Vector2(10, 1), 5, Color("#9b7052"))
            draw_circle(Vector2(12, 0), 1.5, Color("#242424"))
        "slime":
            draw_circle(Vector2.ZERO, 10, Color("#8bd46c"))
            draw_circle(Vector2(-3, -2), 1.5, Color("#25452a"))
            draw_circle(Vector2(3, -2), 1.5, Color("#25452a"))
