class_name SimpleHitbox extends Area2D

@export var damage: int = 1
@export var hitBehavior: hitType = hitType.ONCE_PER
@export var damageOverTimeInterval: float = 1

enum hitType { REPEATED, FIRST, ONCE_PER, OVER_TIME }

@export var damageCause: Node = null
var alreadyHit: Array = []
var canHit: bool = true
var isEnabled: bool = true
var dotList: Dictionary = {} # Node2D : float

func setEnabled(enabled: bool):
    isEnabled = enabled

func applyDamage(body: Node2D):
    var health: IHealth = body.get_node("Health")
    if(health):
        health.damage(damage, damageCause)

func _on_body_entered(body: Node2D) -> void:
    print("body entered ", get_parent().name, " hitbox: ", body.name)
    if(hitBehavior == hitType.OVER_TIME):
        #print("added ", body.name, " to DOT list")
        dotList[body] = damageOverTimeInterval
        if not isEnabled:
            # prepare to deal damage as soon as the hitbox is enabled
            dotList[body] = 0
    
    if(not canHit or not isEnabled):
        return
    
    #print(name, " hit ", body.name)
    
    var health: IHealth = body.get_node("Health")
    if(health == null):
        return
    
    if(hitBehavior == hitType.ONCE_PER):
        if(alreadyHit.has(body)):
            return
        alreadyHit.append(body)
    
    health.damage(damage, damageCause)
    
    if(hitBehavior == hitType.FIRST):
        canHit = false
        disconnect("body_entered", self._on_body_entered)

func _on_body_exited(body: Node2D) -> void:
    if hitBehavior == hitType.OVER_TIME:
        dotList.erase(body)

func _process(delta: float) -> void:
    if not isEnabled or hitBehavior != hitType.OVER_TIME:
        return
    for i in dotList:
        dotList[i] -= delta
        if dotList[i] <= 0:
            #print("applying DOT to ", i.name)
            applyDamage(i)
            dotList[i] = damageOverTimeInterval
