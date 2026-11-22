extends RefCounted
class_name BWSaveManager

const SAVE_PATH := "user://buildworld_save.json"

static func save_game(data: Dictionary) -> bool:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Could not open save file for writing.")
        return false
    file.store_string(JSON.stringify(data))
    file.close()
    return true

static func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    if parsed is Dictionary:
        return parsed
    return {}
