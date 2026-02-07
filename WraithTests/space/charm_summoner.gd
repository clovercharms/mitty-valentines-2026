class_name CharmSummoner extends Node3D

    #[Export] private int Amount  { get; set; } = 75 + 1; // 1st gets skipped because of headerline in csv
    #[Export] private int PositionRange { get; set; } = 20;
    #[Export] private float MinDistance { get; set; } = 3.0f;
    
@export var amount : int
@export var position_range : int
@export var min_distance : float

const SPACE_CHARM : PackedScene = preload("res://WraithTests/space/lucky_charm.tscn")

var half_range = position_range / 2

func _ready() -> void:
    print("Summoning charms...")
    
    for i in range(amount):
        var charm = SPACE_CHARM.instantiate()
        charm.position = generate_random_planet_position()
        var marker : Marker3D = Marker3D.new()
        charm.pivoter = marker
        add_child(marker)
        marker.add_child(charm)
        print("added charm to space")

func generate_random_planet_position() -> Vector3:
    var theta = randf_range(0, PI * 2)
    var phi = randf_range(0, PI)
    var radius : float = 25.0
    
    var x : float = radius * sin(theta) * cos(phi)
    var y : float = radius * sin(theta) * sin(phi)
    var z : float = radius * cos(theta)
    
    var final : Vector3 = Vector3(x, y, z)
        
    return final

        #for (int i = 1; i < Amount; i++)
        #{			
            #var charm = LuckyCharm.GenerateInstance();
#
            #charm.CharmName = "Lucky Charm";
#
            #charm.IsDummy = true;
#
            #if (charm.IsDummy) charm.Avatar = charm.BodyTexture;
#
            #charm.Position = MakeRandomPlanetPosition();
            #var marker = new Marker3D();
            #charm.Pivoter = marker;
            #AddChild(marker);
            #marker.AddChild(charm);
            #GD.Print("Added charm");
        #}
    #}
#
    #public static Vector3 MakeRandomPlanetPosition()
    #{
        #var theta = GD.RandRange(0, Math.PI * 2);
        #var phi = GD.RandRange(0, Math.PI); // I"M NOT GREEK!  THE FUCK DOES THIS MEAN? // Theta and phi are traditional variable names for angles in math equations.
        #var radius = 25f;       // WHAT THE FUCK WAS THIS BULLSHIT?! // This was basically rolling the latitude and longitude and then adjusting the location for how big the planet is.
#
        #var x = (float)(radius * Math.Sin(theta) * Math.Cos(phi));
        #var y = (float)(radius * Math.Sin(theta) * Math.Sin(phi));
        #var z = (float)(radius * Math.Cos(theta));
#
        #return new Vector3(x, y, z);
    #}
