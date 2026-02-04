class_name EnemyBase extends CharacterBody2D

@export var stats : StatBlock

func damage_player(player: MittyPlayer):
    if (player == null):
        return
    
    player.stats.take_damage(stats.base_damage)
