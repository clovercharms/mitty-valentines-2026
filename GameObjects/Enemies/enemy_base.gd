class_name EnemyBase extends CharacterBody2D

@export var stats : StatBlock

func damage_player(player: MittyPlayer):
    if (player == null):
        return
    if (!player.damage_timer.is_stopped()):
        return
    
    player.stats.take_damage(stats.base_damage)
