class_name TestingHeartCircle extends Control

@onready var filled : float = 1.0

func fill(amount):
    filled = amount
    queue_redraw()

func _draw():
    var center: Vector2 = Vector2(25, 25)
    var radius: float = 25
    var color: Color = Color.BLUE
    var sides: int = 64 # Number of points for smoothness, adjust as needed
    
    draw_circle(center, radius + 5, Color.BLACK)
    draw_partial_circle(center, radius, color, filled, sides)  
    
func draw_partial_circle(center: Vector2, radius: float, color: Color, fill_percent: float, sides: int):
    var points_arc: PackedVector2Array = []
    points_arc.append(center) # Start from the center
    
    # Calculate the angle range based on the fill percentage
    var angle_from: float = 0.0
    var angle_to: float = TAU * fill_percent # TAU is 2 * PI, a full circle

    for i in range(sides + 1):
        var angle_point: float = angle_from + i * (angle_to - angle_from) / sides
        # Use cos and sin to find points on the circumference
        var x: float = center.x + radius * cos(angle_point)
        var y: float = center.y + radius * sin(angle_point)
        points_arc.push_back(Vector2(x, y))
        
    # The draw_colored_polygon function automatically closes the shape if needed, 
    # but the points already form a closed sector (center to arc points to center)
    draw_colored_polygon(points_arc, color) # Use draw_colored_polygon for simplicity
