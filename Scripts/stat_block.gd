class_name StatBlock extends Resource

signal damage_taken(amount: int)
signal damage_healed(amount: int)

# editor settings
# one "heart" is 4 subhearts.  So 4 health is one heart.
# Mitty should gain health in increments of 4, enemies can be whatever
@export var max_health = 4
@export var base_damage = 4 # One "heart" of damage as a base.
@export var speed_modifier = 1.0 # Directly modifies left and right speed, but not jump speed.
@export var damage_resist = 0 # Lowers damage directly.  Minimum 1 damage.

# game-only settings
var current_health : float = max_health
var is_dead = false

func on_instantiation():
    set_health(max_health)

func set_health(amount: int):
    var final_health = min(max_health, amount)
    current_health = final_health
    if current_health > 0:
        is_dead = false
    else:
        is_dead = true
    emit_changed()

func take_damage(amount: int):
    var final_damage = max(1, amount - damage_resist)
    current_health -= final_damage
    damage_taken.emit(final_damage)
    
    if (current_health <= 0):
        current_health = 0
        is_dead = true
    # visual logic sent to model and UI
    emit_changed()

func heal(amount: int):
    var final_heal = min(max_health - current_health, amount)
    current_health += final_heal
    damage_healed.emit(final_heal)
    #visual logic sent to model and UI
    emit_changed()
