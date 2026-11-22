extends Node2D
class_name BWWorld

const TILE := 32
const WORLD_SIZE := 96
var seed_value: int = 0
var noise := FastNoiseLite.new()
var resources: Array[Dictionary] = []

func generate(world_seed: int = -1) -> void:
    seed_value = world_seed if world_seed >= 0 else randi()
    noise.seed = seed_value
    noise.frequency = 0.035
    noise.fractal_octaves = 3
    resources.clear()
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    for y in range(-WORLD_SIZE / 2, WORLD_SIZE / 2):
        for x in range(-WORLD_SIZE / 2, WORLD_SIZE / 2):
            if rng.randf() < 0.012:
                var kind := ["tree", "stone", "berry", "fiber"][rng.randi_range(0, 3)]
                resources.append({"kind": kind, "position": Vector2((x + 0.5) * TILE, (y + 0.5) * TILE)})
    queue_redraw()

func biome_at(x: int, y: int) -> String:
    var n := noise.get_noise_2d(x, y)
    if n < -0.38:
        return "water"
    if n > 0.42:
        return "forest"
    if noise.get_noise_2d(x + 900, y - 400) > 0.25:
        return "dry"
    return "grass"

func _draw() -> void:
    for y in range(-WORLD_SIZE / 2, WORLD_SIZE / 2):
        for x in range(-WORLD_SIZE / 2, WORLD_SIZE / 2):
            var biome := biome_at(x, y)
            var tile_color := Color("#75a95b")
            match biome:
                "water": tile_color = Color("#397fae")
                "forest": tile_color = Color("#4e8749")
                "dry": tile_color = Color("#b9a36b")
            var rect := Rect2(Vector2(x * TILE, y * TILE), Vector2(TILE, TILE))
            draw_rect(rect, tile_color)
            draw_rect(rect, tile_color.darkened(0.08), false, 1.0)
    for item in resources:
        var p: Vector2 = item.position
        match item.kind:
            "tree":
                draw_rect(Rect2(p + Vector2(-4, 0), Vector2(8, 17)), Color("#76502e"))
                draw_circle(p + Vector2(0, -5), 13, Color("#245f35"))
                draw_circle(p + Vector2(-6, -8), 7, Color("#327c40"))
            "stone":
                draw_circle(p, 10, Color("#858b91"))
                draw_circle(p + Vector2(-3, -3), 3, Color("#aeb4b8"))
            "berry":
                draw_circle(p, 8, Color("#347c39"))
                draw_circle(p + Vector2(-3, -3), 2, Color("#bd334e"))
                draw_circle(p + Vector2(4, -1), 2, Color("#bd334e"))
            "fiber":
                draw_line(p + Vector2(-7, 7), p + Vector2(0, -9), Color("#d5c66c"), 3)
                draw_line(p + Vector2(0, 7), p + Vector2(5, -8), Color("#b7b85b"), 3)

func gather_near(world_position: Vector2, reach: float = 58.0) -> String:
    var nearest_index := -1
    var nearest_distance := reach
    for i in range(resources.size()):
        var distance: float = world_position.distance_to(resources[i].position)
        if distance < nearest_distance:
            nearest_distance = distance
            nearest_index = i
    if nearest_index == -1:
        return ""
    var item: Dictionary = resources[nearest_index]
    resources.remove_at(nearest_index)
    queue_redraw()
    return String(item.kind)

func serialize_resources() -> Array:
    var output: Array = []
    for item in resources:
        var p: Vector2 = item.position
        output.append({"kind": String(item.kind), "x": p.x, "y": p.y})
    return output

func restore_resources(saved: Array) -> void:
    resources.clear()
    for item in saved:
        if item is Dictionary and item.has("kind") and item.has("x") and item.has("y"):
            resources.append({"kind": String(item.kind), "position": Vector2(float(item.x), float(item.y))})
    queue_redraw()
