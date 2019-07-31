class PaintApp
  attr_accessor :inputs, :game, :outputs, :grid, :args, :state
  
  def tick
    defaults
    render
    print_title
    add_grid
    check_click
    draw_buttons
  end

  def defaults
    game.tileCords    ||= []
    game.tileQuantity ||= 6
    game.tileSize     ||= 50
    game.tileSelected ||= 3

    game.tempX ||= 50;
    game.tempY ||= 500;
    
    determineTileCords unless game.tempX == 0
  end

  def determineTileCords
    game.tempCounter ||= 1
    game.tileQuantity.times do
      game.tileCords += [[game.tempX, game.tempY, game.tempCounter]]
      game.tempX += 75
      game.tempCounter += 1
      if game.tempX > 200
        game.tempX = 50
        game.tempY -= 75
      end
    end
    game.tempX = 0
  end

  def render
    outputs.sprites += game.tileCords.map do
      |x, y, order|
      [x, y, game.tileSize, game.tileSize, 'sprites/image' + order.to_s + ".png"]
    end

  end

  def print_title
    outputs.labels << [ 640, 700, 'Paint!', 0, 1 ]
    outputs.lines << horizontal_seperator(660, 0, 1280)
  end

  def horizontal_seperator y, x, x2
    [x, y, x2, y, 150, 150, 150]
  end

  def vertical_seperator x, y, y2
    [x, y, x, y2, 150, 150, 150]
  end

  def add_grid
    x, y, h, w = 640 - 500/2, 640 - 500, 500, 500
    lines_h = 31
    lines_v = 31
    
    game.grid_border ||= [ x, y, h, w ]
    game.grid_lines ||= draw_grid(x, y, h, w, lines_h, lines_v)
    game.filled_squares ||= []

    outputs.lines.concat game.grid_lines      
    outputs.borders << game.grid_border
    outputs.sprites.concat game.filled_squares
  end

  def draw_grid x, y, h, w, lines_h, lines_v
    grid = []    

    curr_y = y #start at the bottom of the box
    dist_y = h / (lines_h + 1)
    lines_h.times do
      curr_y += dist_y
      grid << horizontal_seperator(curr_y, x, x + w - 1)
    end
    
    curr_x = x #now start at the left of the box
    dist_x = w / (lines_v + 1)
    lines_v.times do 
      curr_x += dist_x
      grid << vertical_seperator(curr_x, y + 1, y  + h)
    end

    game.paint_grid ||= {"x" => x, "y" => y, "h" => h, "w" => w, "lines_h" => lines_h,
                   "lines_y" => lines_v, "dist_x" => dist_x,
                   "dist_y" => dist_y }

    return grid
  end

  def check_click
    if inputs.mouse.down #is mouse up or down?
      game.mouse_held = true
    elsif inputs.mouse.up
      game.mouse_held = false
      game.mouse_dragging = false
    end

    if game.mouse_held &&    #mouse needs to be down
       !inputs.mouse.click &&     #must not be first click
       ((inputs.mouse.previous_click.point.x - inputs.mouse.position.x).abs > 15) # Need to move 15 pixels before "drag" 
      game.mouse_dragging = true
    end
    
    if ((inputs.mouse.click) && (inputs.mouse.click.point.inside_rect? game.grid_border))
      search_lines(inputs.mouse.click.point, :click)

    elsif ((game.mouse_dragging) && (inputs.mouse.position.inside_rect? game.grid_border))
      search_lines(inputs.mouse.position, :drag)
    end

  end

  def search_lines (point, input_type)
    point.x -= game.paint_grid["x"]
    point.y -= game.paint_grid["y"]

    point.x = (point.x / game.paint_grid["dist_x"]).floor * game.paint_grid["dist_x"]
    point.y = (point.y / game.paint_grid["dist_y"]).floor * game.paint_grid["dist_y"]

    point.x += game.paint_grid["x"]
    point.y += game.paint_grid["y"]

    grid_box = [ point.x, point.y, game.paint_grid["dist_x"].ceil, game.paint_grid["dist_y"].ceil,
                 "sprites/image" + game.tileSelected.to_s + ".png"]

    if input_type == :click
      if game.filled_squares.include? grid_box
        game.filled_squares.delete grid_box
      else      
        game.filled_squares << grid_box
      end
    elsif input_type == :drag
      unless game.filled_squares.include? grid_box
         game.filled_squares << grid_box
      end
    end
  end

  def draw_buttons
    x, y, w, h = 390, 50, 240, 50
    game.clear_button        ||= game.new_entity(:button_with_fade)
    game.clear_button.label  ||= [x + w.half, y + h.half + 10, "clear", 0, 1]
    game.clear_button.border ||= [x, y, w, h]

    if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(game.clear_button.border)
      game.clear_button.clicked_at = inputs.mouse.click.created_at
      game.filled_squares.clear
      inputs.mouse.previous_click = nil
    end

    outputs.labels << game.clear_button.label
    outputs.borders << game.clear_button.border

    if game.clear_button.clicked_at
      outputs.solids << [x, y, w, h, 0, 180, 80, 255 * game.clear_button.clicked_at.ease(0.25.seconds, :flip)]
    end

    x, y = 650, 50
    game.export_button        ||= game.new_entity(:button_with_fade)
    game.export_button.label  ||= [x + w.half, y + h.half + 10, "export", 0, 1]
    game.export_button.border ||= [x, y, w, h]

    if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(game.export_button.border)
      game.export_button.clicked_at = inputs.mouse.click.created_at
      $dragon.root.take_screenshot = true #Not sure if this works !!
      inputs.mouse.previous_click = nil
    end

    outputs.labels << game.export_button.label
    outputs.borders << game.export_button.border

    if game.export_button.clicked_at
      outputs.solids << [x, y, w, h, 0, 180, 80, 255 * game.export_button.clicked_at.ease(0.25.seconds, :flip)]
    end


  end
end

$paint_app = PaintApp.new

def tick args
  $paint_app.inputs = args.inputs
  $paint_app.game = args.game
  $paint_app.grid = args.grid
  $paint_app.args = args
  $paint_app.outputs = args.outputs
  $paint_app.state = args.state
  $paint_app.tick
end
