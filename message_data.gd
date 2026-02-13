class_name MessageData extends Resource

var message_id : int

func add_message_to_game() -> void:
    var gb = GameBase.get_singleton()
    message_id = gb.current_message_id
    gb.current_message_id += 1
    print("message id: ", message_id)
