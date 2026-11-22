extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const WorldScript = preload("res://scripts/world.gd")

var world: BWWorld
var player: BWPlayer
var inventory := {"wood": 0, "stone": 0, "berries": 0, "fiber": 0}
var inventory_label: Label
var message_label: Label

func _ready() -> void:
    randomize()
    world = WorldScript.new()
    add_child(world)
    world.generate()
    player = PlayerScript.new()
    player.position = Vector2.ZERO
    add_child(player)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    player.add_child(camera)
    camera.make_current()
    _build_hud()
    _refresh_inventory()
    _show_message("Welcome to BuildWorld! Move with WASD / arrows. Tap GATHER near a resource.")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(300, 92)
    layer.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "BUILDWORLD  |  SURVIVAL"
    heading.add_theme_font_size_override("font_size", 18)
    column.add_child(heading)
    inventory_label = Label.new()
    column.add_child(inventory_label)
    message_label = Label.new()
    message_label.position = Vector2(16, 118)
    message_label.add_theme_color_override("font_color", Color("#ffffff"))
    message_label.add_theme_font_size_override("font_size", 16)
    layer.add_child(message_label)
    var gather_button := Button.new()
    gather_button.text = "GATHER"
    gather_button.position = Vector2(16, 176)
    gather_button.custom_minimum_size = Vector2(116, 48)
    gather_button.pressed.connect(_gather)
    layer.add_child(gather_button)
    _add_move_button(layer, "↑", Vector2(110, 0), Vector2.UP)
    _add_move_button(layer, "←", Vector2(54, 54), Vector2.LEFT)
    _add_move_button(layer, "↓", Vector2(110, 54), Vector2.DOWN)
    _add_move_button(layer, "→", Vector2(166, 54), Vector2.RIGHT)

func _add_move_button(layer: CanvasLayer, caption: String, offset: Vector2, direction: Vector2) -> void:
    var button := Button.new()
    button.text = caption
    button.position = Vector2(16, 520) + offset
    button.custom_minimum_size = Vector2(50, 50)
    button.button_down.connect(func(): player.touch_direction = direction)
    button.button_up.connect(func(): player.touch_direction = Vector2.ZERO)
    layer.add_child(button)

func _gather() -> void:
    var kind := world.gather_near(player.global_position, 72.0)
    if kind == "":
        _show_message("No resource nearby. Explore the world!")
        return
    match kind:
        "tree": inventory.wood += 1
        "stone": inventory.stone += 1
        "berry": inventory.berries += 1
        "fiber": inventory.fiber += 1
    _refresh_inventory()
    _show_message("Collected: " + kind)

func _refresh_inventory() -> void:
    inventory_label.text = "Wood: %d   Stone: %d\nBerries: %d   Fiber: %d" % [inventory.wood, inventory.stone, inventory.berries, inventory.fiber]

func _show_message(value: String) -> void:
    message_label.text = value
