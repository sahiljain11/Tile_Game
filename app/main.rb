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
    game.tileSelected ||= 1
    game.tempX        ||= 50
    game.tempY        ||= 500
    game.speed        ||= 4
    
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
    outputs.labels << [640, 700, 'Paint!', 7, 1]
    outputs.lines << horizontal_seperator(660, 0, 1280)
    outputs.labels << [1050, 500, 'Current:', 3, 1]
    outputs.sprites << [1110, 474, game.tileSize / 2, game.tileSize / 2, 'sprites/image' + game.tileSelected.to_s + ".png"]
  end

  def horizontal_seperator y, x, x2
    [x, y, x2, y, 150, 150, 150]
  end

  def vertical_seperator x, y, y2
    [x, y, x, y2, 150, 150, 150]
  end

  def add_grid
    x, y, h, w = 640 - 500/2, 640 - 500, 500, 500
    lines_h = 50
    lines_v = 50
    
    game.grid_border    ||= [ x, y, h, w ]
    game.centerX        ||= x + (w / 2)
    game.centerY        ||= y + (h / 2)
    #game.centerLimitsX  ||= [(x / 2) + (w / 2), (x / 2) + w]
    #game.centerLimitsY  ||= [y / 2]
    game.grid_lines     ||= draw_grid(x / 2, y / 2, h + y, w + x, lines_h, lines_v)  
    game.filled_squares ||= []

    outputs.lines.concat game.grid_lines      
    outputs.borders << game.grid_border
    #outputs.sprites.concat game.filled_squares
    game.filled_squares.map do
      |x, y, w, h, sprite|
      if x > game.centerX - game.grid_border[3] / 2 && x < game.centerX + game.grid_border[3] / 2 &&
         y > game.centerY - game.grid_border[2] / 2 && y < game.centerX + game.grid_border[2] / 2
        outputs.sprites << [x, y, w, h, sprite]
      end
    end
  end

  def draw_grid x, y, h, w, lines_h, lines_v
    grid = []

    curr_y = y #start at the bottom of the box
    dist_y = h / (lines_h + 1)
    lines_h.times do
      curr_y += dist_y
      grid << horizontal_seperator(curr_y, game.grid_border[0], w) unless
        curr_y < game.centerY - game.grid_border[2] / 2 ||
        curr_y > game.centerY + game.grid_border[2] / 2
    end
    
    curr_x = x #now start at the left of the box
    dist_x = w / (lines_v + 1)
    lines_v.times do 
      curr_x += dist_x
      grid << vertical_seperator(curr_x, game.grid_border[1], h) unless
        curr_x < game.centerX - game.grid_border[3] / 2 ||
        curr_x > game.centerX + game.grid_border[3] / 2
    end

    game.paint_grid ||= {"x" => x, "y" => y, "h" => h, "w" => w, "lines_h" => lines_h,
                   "lines_y" => lines_v, "dist_x" => dist_x,
                   "dist_y" => dist_y }

    return grid
  end

  def check_click
    if inputs.keyboard.key_down.r
      $dragon.reset
    end
    if inputs.mouse.down #is mouse up or down?
      game.mouse_held = true
      if inputs.mouse.position.x < game.grid_border[0]
        game.tileCords.map do
          |x, y, order|
          if inputs.mouse.position.x >= x && inputs.mouse.position.x <= x + game.tileSize &&
             inputs.mouse.position.y >= y && inputs.mouse.position.y <= y + game.tileSize
            game.tileSelected = order
          end
        end
      end
    elsif inputs.mouse.up
      game.mouse_held = false
      game.mouse_dragging = false
    end

    if game.mouse_held &&    #mouse needs to be down
       !inputs.mouse.click &&     #must not be first click
       ((inputs.mouse.previous_click.point.x - inputs.mouse.position.x).abs > 15 ||
        (inputs.mouse.previous_click.point.y - inputs.mouse.position.y).abs > 15) # Need to move 15 pixels before "drag" 
      game.mouse_dragging = true
    end
    
    if ((inputs.mouse.click) && (inputs.mouse.click.point.inside_rect? game.grid_border))
      search_lines(inputs.mouse.click.point, :click)

    elsif ((game.mouse_dragging) && (inputs.mouse.position.inside_rect? game.grid_border))
      search_lines(inputs.mouse.position, :drag)
    end

    game.centerX += game.speed if inputs.keyboard.key_held.d
    game.centerX -= game.speed if inputs.keyboard.key_held.a
    game.centerY += game.speed if inputs.keyboard.key_held.w
    game.centerY -= game.speed if inputs.keyboard.key_held.s

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
    game.clear_button.label  ||= [x + w.half, y + h.half + 10, "Clear", 0, 1]
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
    game.export_button.label  ||= [x + w.half, y + h.half + 10, "Export", 0, 1]
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
