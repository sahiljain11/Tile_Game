class PaintApp
  attr_accessor :inputs, :state, :outputs, :grid, :args
  
  def tick
    defaults
    render
    check_click
    draw_buttons
  end

  def defaults
    state.tileCords      ||= []
    state.tileQuantity   ||= 6
    state.tileSize       ||= 50
    state.tileSelected   ||= 1
    state.tempX          ||= 50
    state.tempY          ||= 500
    state.speed          ||= 4
    state.centerX        ||= 4000
    state.centerY        ||= 4000
    state.originalCenter ||= [state.centerX, state.centerY]
    state.gridSize       ||= 1600
    state.lineQuantity   ||= 50
    state.increment      ||= state.gridSize / state.lineQuantity
    state.gridX          ||= []
    state.gridY          ||= []
    state.filled_squares ||= []
    state.grid_border    ||= [390, 140, 500, 500]

    get_grid unless state.tempX == 0
    determineTileCords unless state.tempX == 0
    state.tempX = 0
  end

  def determineTileCords
    state.tempCounter ||= 1
    state.tileQuantity.times do
      state.tileCords += [[state.tempX, state.tempY, state.tempCounter]]
      state.tempX += 75
      state.tempCounter += 1
      if state.tempX > 200
        state.tempX = 50
        state.tempY -= 75
      end
    end
  end

  def render
    outputs.sprites << state.tileCords.map do
      |x, y, order|
      [x, y, state.tileSize, state.tileSize, 'sprites/image' + order.to_s + ".png"]
    end
    outputs.solids << [0, 0, 1280, 720, 255, 255, 255]
    add_grid
    print_title
  end

  def print_title
    outputs.labels << [640, 700, 'Paint!', 7, 1]
    outputs.lines << horizontal_seperator(660, 0, 1280)
    outputs.labels << [1050, 500, 'Current:', 3, 1]
    outputs.sprites << [1110, 474, state.tileSize / 2, state.tileSize / 2, 'sprites/image' + state.tileSelected.to_s + ".png"]
  end

  def horizontal_seperator y, x, x2
    [x, y, x2, y, 150, 150, 150]
  end
  
  def add_grid 
    outputs.borders << state.grid_border
    temp = 0
    state.gridX.map do
      |x|
      temp += 1
      if x >= state.centerX - (state.grid_border[2] / 2) && x <= state.centerX + (state.grid_border[2] / 2)
        delta = state.centerX - 640
        outputs.lines << [x - delta, state.grid_border[1], x - delta, state.grid_border[1] + state.grid_border[2], 150, 150, 150]
      end
    end
    temp = 0
    state.gridY.map do
      |y|
      temp += 1
      if y >= state.centerY - (state.grid_border[3] / 2) && y <= state.centerY + (state.grid_border[3] / 2)
        delta = state.centerY - 393
        outputs.lines << [state.grid_border[0], y - delta, state.grid_border[0] + state.grid_border[3], y - delta, 150, 150, 150]
      end
    end

    state.filled_squares.map do
      |x, y, w, h, sprite|
      if x >= state.centerX - (state.grid_border[2] / 2) - 17 && x <= state.centerX + (state.grid_border[2] / 2) &&
         y >= state.centerY - (state.grid_border[3] / 2) && y <= state.centerY + (state.grid_border[3] / 2) + 25
        outputs.sprites << [x - state.centerX + 630, y - state.centerY + 360, w, h, sprite]
      end
    end
    outputs.primitives << [state.grid_border[0] - state.increment,
                           state.grid_border[1] - state.increment, state.increment, state.grid_border[3] + (state.increment * 2),
                           255, 255, 255].solid
 
    outputs.primitives << [state.grid_border[0] + state.grid_border[2],
                           state.grid_border[1] - state.increment, state.increment, state.grid_border[3] + (state.increment * 2),
                           255, 255, 255].solid
 
    outputs.primitives << [state.grid_border[0] - state.increment, state.grid_border[1] - state.increment,
                           state.grid_border[2] + (2 * state.increment), state.increment, 255, 255, 255].solid
 
    outputs.primitives << [state.grid_border[0] - state.increment, state.grid_border[1] + state.grid_border[3],
                           state.grid_border[2] + (2 * state.increment), state.increment, 255, 255, 255].solid

  end

  def get_grid
    curr_x = state.centerX - (state.gridSize / 2)
    deltaX = state.gridSize / state.lineQuantity
    (state.lineQuantity + 2).times do
      state.gridX << curr_x
      curr_x += deltaX
    end

    curr_y = state.centerY - (state.gridSize / 2)
    deltaY = state.gridSize / state.lineQuantity
    (state.lineQuantity + 2).times do
      state.gridY << curr_y
      curr_y += deltaY
    end
    
  end

  def check_click
    if inputs.keyboard.key_down.r
      $dragon.reset
    end
    if inputs.mouse.down #is mouse up or down?
      state.mouse_held = true
      if inputs.mouse.position.x < state.grid_border[0]
        state.tileCords.map do
          |x, y, order|
          if inputs.mouse.position.x >= x && inputs.mouse.position.x <= x + state.tileSize &&
             inputs.mouse.position.y >= y && inputs.mouse.position.y <= y + state.tileSize
            state.tileSelected = order
          end
        end
      end
    elsif inputs.mouse.up
      state.mouse_held = false
      state.mouse_dragging = false
    end

    if state.mouse_held &&    #mouse needs to be down
       !inputs.mouse.click &&     #must not be first click
       ((inputs.mouse.previous_click.point.x - inputs.mouse.position.x).abs > 15 ||
        (inputs.mouse.previous_click.point.y - inputs.mouse.position.y).abs > 15) # Need to move 15 pixels before "drag" 
      state.mouse_dragging = true
    end
    
    if ((inputs.mouse.click) && (inputs.mouse.click.point.inside_rect? state.grid_border))
      search_lines(inputs.mouse.click.point, :click)

    elsif ((state.mouse_dragging) && (inputs.mouse.position.inside_rect? state.grid_border))
      search_lines(inputs.mouse.position, :drag)
    end

    state.centerX += state.speed if inputs.keyboard.key_held.d &&
                                  (state.centerX + state.speed) < state.originalCenter[0] + (state.gridSize / 2) - (state.grid_border[2] / 2)
    state.centerX -= state.speed if inputs.keyboard.key_held.a &&
                                  (state.centerX - state.speed) > state.originalCenter[0] - (state.gridSize / 2) + (state.grid_border[2] / 2)
    state.centerY += state.speed if inputs.keyboard.key_held.w &&
                                  (state.centerY + state.speed) < state.originalCenter[1] + (state.gridSize / 2) - (state.grid_border[3] / 2)
    state.centerY -= state.speed if inputs.keyboard.key_held.s &&
                                  (state.centerY - state.speed) > state.originalCenter[1] - (state.gridSize / 2) + (state.grid_border[3] / 2)
  end

  def search_lines (point, input_type)
    point.x += state.centerX - 630
    point.y += state.centerY - 360
    findX = 0
    findY = 0
    increment = state.gridSize / state.lineQuantity
    
    state.gridX.map do
      |x|
      findX = x + 10 if point.x < (x + 10) && findX == 0
    end

    state.gridY.map do
      |y|
      findY = y if point.y < (y) && findY == 0
    end
    grid_box = [findX - (increment.ceil), findY - (increment.ceil), increment.ceil, increment.ceil,
                "sprites/image" + state.tileSelected.to_s + ".png"]

    if input_type == :click
      if state.filled_squares.include? grid_box
        state.filled_squares.delete grid_box
      else      
        state.filled_squares << grid_box
      end
    elsif input_type == :drag
      unless state.filled_squares.include? grid_box
         state.filled_squares << grid_box
      end
    end
  end

  def draw_buttons
    x, y, w, h = 390, 50, 240, 50
    state.clear_button        ||= state.new_entity(:button_with_fade)
    state.clear_button.label  ||= [x + w.half, y + h.half + 10, "Clear", 0, 1]
    state.clear_button.border ||= [x, y, w, h]

    if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.clear_button.border)
      state.clear_button.clicked_at = inputs.mouse.click.created_at
      state.filled_squares.clear
      inputs.mouse.previous_click = nil
    end

    outputs.labels << state.clear_button.label
    outputs.borders << state.clear_button.border

    if state.clear_button.clicked_at
      outputs.solids << [x, y, w, h, 0, 180, 80, 255 * state.clear_button.clicked_at.ease(0.25.seconds, :flip)]
    end

    x, y = 650, 50
    state.export_button        ||= state.new_entity(:button_with_fade)
    state.export_button.label  ||= [x + w.half, y + h.half + 10, "Export", 0, 1]
    state.export_button.border ||= [x, y, w, h]

    if inputs.mouse.click && inputs.mouse.click.point.inside_rect?(state.export_button.border)
      state.export_button.clicked_at = inputs.mouse.click.created_at
      $dragon.root.take_screenshot = true #Not sure if this works !!
      inputs.mouse.previous_click = nil
    end

    outputs.labels << state.export_button.label
    outputs.borders << state.export_button.border

    if state.export_button.clicked_at
      outputs.solids << [x, y, w, h, 0, 180, 80, 255 * state.export_button.clicked_at.ease(0.25.seconds, :flip)]
    end


  end
end

$paint_app = PaintApp.new

def tick args
  $paint_app.inputs = args.inputs
  $paint_app.grid = args.grid
  $paint_app.args = args
  $paint_app.outputs = args.outputs
  $paint_app.state = args.state
  $paint_app.tick
end
