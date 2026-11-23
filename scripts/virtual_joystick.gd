extends Control
signal direction_changed(value: Vector2)

var _direction := Vector2.ZERO
var _active := false
var _finger_id := -1
var _knob := Vector2.ZERO
const RADIUS := 68.0
const DEAD_ZONE := 0.12

func _ready() -> void:
    custom_minimum_size = Vector2(180, 180)
    mouse_filter = Control.MOUSE_FILTER_STOP
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed and not _active:
            _active = true
            _finger_id = event.index
            _update_stick(event.position)
            accept_event()
        elif not event.pressed and event.index == _finger_id:
            _release_stick()
            accept_event()
    elif event is InputEventScreenDrag and _active and event.index == _finger_id:
        _update_stick(event.position)
        accept_event()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            _active = true
            _update_stick(event.position)
        else:
            _release_stick()
        accept_event()
    elif event is InputEventMouseMotion and _active:
        _update_stick(event.position)
        accept_event()

func _update_stick(point: Vector2) -> void:
    var center := size * 0.5
    var offset := point - center
    if offset.length() > RADIUS:
        offset = offset.normalized() * RADIUS
    _knob = offset
    _direction = offset / RADIUS
    if _direction.length() < DEAD_ZONE:
        _direction = Vector2.ZERO
    direction_changed.emit(_direction)
    queue_redraw()

func _release_stick() -> void:
    _active = false
    _finger_id = -1
    _direction = Vector2.ZERO
    _knob = Vector2.ZERO
    direction_changed.emit(Vector2.ZERO)
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    draw_circle(center, RADIUS + 5.0, Color(0.03, 0.05, 0.07, 0.35))
    draw_circle(center, RADIUS, Color(0.12, 0.16, 0.19, 0.62))
    draw_arc(center, RADIUS, 0.0, TAU, 64, Color(0.85, 0.9, 0.92, 0.7), 3.0)
    draw_circle(center + _knob, 31.0, Color(0.78, 0.84, 0.88, 0.92))
    draw_arc(center + _knob, 31.0, 0.0, TAU, 48, Color(1, 1, 1, 0.9), 2.0)
