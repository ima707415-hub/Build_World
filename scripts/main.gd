extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const WorldScript = preload("res://scripts/world.gd")
const SaveManager = preload("res://scripts/save_manager.gd")

var world: BWWorld
var player: BWPlayer
var inventory := {"wood": 0, "stone": 0, "berries": 0, "fiber": 0, "axe": 0, "workbench": 0}
var inventory_label: Label
var message_label: Label
var world_seed: int = 0

func _ready() -> void:
    randomize()
    world = WorldScript.new()
    add_child(world)
    player = PlayerScript.new()
    player.position = Vector2.ZERO
    add_child(player)
    var camera := Camera2D.new()
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    player.add_child(camera)
    camera.make_current()
    _build_hud()
    _load_game()
    _refresh_inventory()
    _show_message("BuildWorld 1.0 prototype. Explore, gather, craft and save.")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(330, 116)
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
    message_label.position = Vector2(16, 140)
    message_label.add_theme_color_override("font_color", Color("#ffffff"))
    message_label.add_theme_font_size_override("font_size", 16)
    layer.add_child(message_label)

    _add_button(layer, "GATHER", Vector2(16, 192), Vector2(120, 48), _gather)
    _add_button(layer, "CRAFT AXE", Vector2(148, 192), Vector2(120, 48), _craft_axe)
    _add_button(layer, "WORKBENCH", Vector2(280, 192), Vector2(132, 48), _craft_workbench)
    _add_button(layer, "SAVE", Vector2(16, 250), Vector2(120, 44), _save_game)
    _add_button(layer, "NEW WORLD", Vector2(148, 250), Vector2(120, 44), _new_world)

    _add_move_button(layer, "↑", Vector2(110, 0), Vector2.UP)
    _add_move_button(layer, "←", Vector2(54, 54), Vector2.LEFT)
    _add_move_button(layer, "↓", Vector2(110, 54), Vector2.DOWN)
    _add_move_button(layer, "→", Vector2(166, 54), Vector2.RIGHT)

func _add_button(layer: CanvasLayer, caption: String, pos: Vector2, button_size: Vector2, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.position = pos
    button.custom_minimum_size = button_size
    button.pressed.connect(action)
    layer.add_child(button)

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

func _craft_axe() -> void:
    if inventory.wood < 2 or inventory.stone < 1 or inventory.fiber < 1:
        _show_message("Axe needs 2 wood, 1 stone and 1 fiber.")
        return
    inventory.wood -= 2
    inventory.stone -= 1
    inventory.fiber -= 1
    inventory.axe += 1
    _refresh_inventory()
    _show_message("Crafted a basic axe!")

func _craft_workbench() -> void:
    if inventory.wood < 8 or inventory.stone < 4:
        _show_message("Workbench needs 8 wood and 4 stone.")
        return
    inventory.wood -= 8
    inventory.stone -= 4
    inventory.workbench += 1
    _refresh_inventory()
    _show_message("Workbench crafted! More recipes coming soon.")

func _refresh_inventory() -> void:
    inventory_label.text = "Wood: %d  Stone: %d  Berries: %d  Fiber: %d\nAxes: %d  Workbenches: %d" % [inventory.wood, inventory.stone, inventory.berries, inventory.fiber, inventory.axe, inventory.workbench]

func _save_game() -> void:
    var data := {
        "version": 1,
        "seed": world.seed_value,
        "player_x": player.global_position.x,
        "player_y": player.global_position.y,
        "inventory": inventory,
        "resources": world.serialize_resources()
    }
    if SaveManager.save_game(data):
        _show_message("World saved on this device.")
    else:
        _show_message("Save failed. Check device storage permissions.")

func _load_game() -> void:
    var data: Dictionary = SaveManager.load_game()
    if data.is_empty():
        world.generate()
        return
    world_seed = int(data.get("seed", 0))
    world.generate(world_seed)
    var saved_inventory: Variant = data.get("inventory", {})
    if saved_inventory is Dictionary:
        for key in inventory.keys():
            inventory[key] = int(saved_inventory.get(key, 0))
    player.global_position = Vector2(float(data.get("player_x", 0.0)), float(data.get("player_y", 0.0)))
    var saved_resources: Variant = data.get("resources", [])
    if saved_resources is Array:
        world.restore_resources(saved_resources)
    _show_message("Saved world loaded.")

func _new_world() -> void:
    world_seed = randi()
    world.generate(world_seed)
    player.global_position = Vector2.ZERO
    inventory = {"wood": 0, "stone": 0, "berries": 0, "fiber": 0, "axe": 0, "workbench": 0}
    _refresh_inventory()
    _show_message("New world created. Save to keep your progress.")

func _show_message(value: String) -> void:
    message_label.text = value
