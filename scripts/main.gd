extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const WorldScript = preload("res://scripts/world.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const CreatureScript = preload("res://scripts/creature.gd")
const JoystickScript = preload("res://scripts/virtual_joystick.gd")

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
    _spawn_creatures()
    _refresh_inventory()
    _show_message("Добро пожаловать в BuildWorld!")

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var ui := Control.new()
    ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.mouse_filter = Control.MOUSE_FILTER_PASS
    layer.add_child(ui)

    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(310, 92)
    ui.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var heading := Label.new()
    heading.text = "BUILDWORLD"
    heading.add_theme_font_size_override("font_size", 20)
    column.add_child(heading)
    inventory_label = Label.new()
    column.add_child(inventory_label)

    message_label = Label.new()
    message_label.position = Vector2(16, 118)
    message_label.add_theme_color_override("font_color", Color("#ffffff"))
    message_label.add_theme_font_size_override("font_size", 16)
    message_label.add_theme_color_override("font_shadow_color", Color("#202020"))
    message_label.add_theme_constant_override("shadow_offset_x", 2)
    message_label.add_theme_constant_override("shadow_offset_y", 2)
    ui.add_child(message_label)

    var joystick: Control = JoystickScript.new()
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.position = Vector2(22, -205)
    joystick.custom_minimum_size = Vector2(180, 180)
    joystick.direction_changed.connect(func(value: Vector2): player.touch_direction = value)
    ui.add_child(joystick)

    var actions := VBoxContainer.new()
    actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    actions.position = Vector2(-166, -204)
    actions.add_theme_constant_override("separation", 8)
    ui.add_child(actions)
    _add_action_button(actions, "СОБРАТЬ", _gather)
    _add_action_button(actions, "СОЗДАТЬ ТОПОР", _craft_axe)
    _add_action_button(actions, "ВЕРСТАК", _craft_workbench)
    _add_action_button(actions, "СОХРАНИТЬ", _save_game)
    _add_action_button(actions, "НОВЫЙ МИР", _new_world)

func _add_action_button(parent: VBoxContainer, caption: String, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(150, 38)
    button.pressed.connect(action)
    parent.add_child(button)

func _gather() -> void:
    var kind := world.gather_near(player.global_position, 72.0)
    if kind == "":
        _show_message("Рядом нет ресурсов. Исследуй мир!")
        return
    match kind:
        "tree": inventory.wood += 1
        "stone": inventory.stone += 1
        "berry": inventory.berries += 1
        "fiber": inventory.fiber += 1
    _refresh_inventory()
    var names := {"tree": "дерево", "stone": "камень", "berry": "ягоды", "fiber": "волокно"}
    _show_message("Собрано: " + names.get(kind, kind))

func _spawn_creatures() -> void:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var creature_types := ["rabbit", "rabbit", "rabbit", "boar", "slime", "slime"]
    for creature_type in creature_types:
        var creature: BWCreature = CreatureScript.new()
        creature.setup(creature_type, player, rng.randi())
        creature.position = Vector2(rng.randf_range(-500.0, 500.0), rng.randf_range(-350.0, 350.0))
        add_child(creature)

func _craft_axe() -> void:
    if inventory.wood < 2 or inventory.stone < 1 or inventory.fiber < 1:
        _show_message("Для топора нужно: 2 дерева, 1 камень и 1 волокно.")
        return
    inventory.wood -= 2
    inventory.stone -= 1
    inventory.fiber -= 1
    inventory.axe += 1
    _refresh_inventory()
    _show_message("Создан простой топор!")

func _craft_workbench() -> void:
    if inventory.wood < 8 or inventory.stone < 4:
        _show_message("Для верстака нужно: 8 дерева и 4 камня.")
        return
    inventory.wood -= 8
    inventory.stone -= 4
    inventory.workbench += 1
    _refresh_inventory()
    _show_message("Верстак создан!")

func _refresh_inventory() -> void:
    inventory_label.text = "Дерево: %d  Камень: %d\nЯгоды: %d  Волокно: %d\nТопоры: %d  Верстаки: %d" % [inventory.wood, inventory.stone, inventory.berries, inventory.fiber, inventory.axe, inventory.workbench]

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
        _show_message("Мир сохранён на этом устройстве.")
    else:
        _show_message("Не удалось сохранить мир.")

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
    _show_message("Сохранённый мир загружен.")

func _new_world() -> void:
    world_seed = randi()
    world.generate(world_seed)
    player.global_position = Vector2.ZERO
    inventory = {"wood": 0, "stone": 0, "berries": 0, "fiber": 0, "axe": 0, "workbench": 0}
    _refresh_inventory()
    _show_message("Создан новый мир.")

func _show_message(value: String) -> void:
    message_label.text = value
