extends Control



func _ready() -> void:
    var text = $Label.text
    $Label.text = scramble_text(text)
    
const CHARACTERS := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !@#$%^&*()"

func scramble_text(text : String) -> String:
    var result : String = ""
    var chars = CHARACTERS.length()
    
    for i in range(text.length()):
        var index = randi_range(0, chars - 1)
        result += CHARACTERS[index]
        
    return result
