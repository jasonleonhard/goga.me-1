class BoardPresenter
  attr_reader :board
  delegate :size, to: :board, prefix: true
  delegate :moves, to: :board

  def initialize(board)
    @board = board
  end

  # The state of the board is computed from the moves. All moves are processed
  # in chronological order, with captures represented as a sequence of moves 
  # with :empty color, this allows for the entire game to be replayed, as we
  # don't store the state, we recompute it from the individual moves.
  def state
    State.new(board_size, moves)
  end

  def components_adjacent_to_last_move
    point = Point.from_move(board.last_move)
    inverted_neighbors = state.neighbors(point, false)
    Set.new(inverted_neighbors.map { |n| find_component_containing(n) })
  end

  def find_component_containing(u)
    # do a BFS from u
    reached = [u]
    searched = Set.new

    while !reached.empty?
      v = reached.shift
      # neighbors of v not in (S U R) add to R
      state.neighbors(v).each do |neighbor|
        if !reached.include?(neighbor) && !searched.include?(neighbor)
          reached.append(neighbor)
        end
      end
      searched.add(v)
    end

    Component.new(searched)
  end

  def to_a
    moves.map(&:to_h)
  end

  class Point < Struct.new(:x, :y, :color)
    def self.from_move(move)
      point = new(move.x, move.y, Move.colors[move.color])
    end
  end

  class Component < Set

    def initialize(state, *args)
      @state = state
      super
      self
    end

  end

  class State
    attr_reader :size, :moves

    def initialize(size, moves)
      @moves = moves
      @size = size
      @locations = 1.upto(size).map { |i|
        1.upto(size).map {|j|
          Move.colors["blank"]
        }
      }
      moves.each do |move|
        set(move.x, move.y, Move.colors[move.color])
      end
    end

    def get(x,y)
      @locations[y-1][x-1]
    end

    def set(x,y,value)
      @locations[y-1][x-1] = value
    end

    def liberties(point)
      return 0 if point.color == Move.colors["blank"]
      (4 + 1) - (neighbors(point).count + neighbors(point, false).count)
    end

    def total_liberties(component)
      retval = 0
      component.each do |point|
        retval += liberties(point)
      end
      retval
    end


    # find all neighbors of a point v
    def neighbors(v, same_color = true)
      x = v.x
      y = v.y

      Set.new([
              Point.new(x, y, get(x, y)),
              Point.new(x, y-1, get(x, y-1)),
              Point.new(x, y+1, get(x, y+1)),
              Point.new(x-1, y, get(x-1, y)),
              Point.new(x+1, y, get(x+1, y))
      ].select { |p|
        p.color != 0 && x.in?(1..size) && y.in?(1..size)
      }.select { |p| same_color ? (p.color == v.color) : (p.color != v.color) })
    end

    def to_a
      @locations
    end

    def to_s
      output = "  " + (1.upto(size)).map(&:to_s).join(" ")
      to_a.each_with_index do |row, i|
        output << "\n"
        output << (i+1).to_s.ljust(2, ' ')
        output << row.inspect.gsub(/(,|\]|\[)/, "").gsub(/0/, ".")
      end
      output << "\n"
    end
  end
end
