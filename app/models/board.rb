class Board < ActiveRecord::Base
  belongs_to :match
  delegate :state, to: :presenter
  has_many :moves

  def play_move(x:, y:, color:, user:)
    move = Move.new(x: x, y: y, color: color, user: user)
    return "color same as last" if color_same_as_last_move?(color)
    return "position occupied" if position_occupied?(x:x, y:y)
    moves << move
    capture_surrounded_groups
    return "no error: #{moves.count} moves"
  end

  def position_occupied?(x:, y:)
    moves.where(x:x, y:y).count > 0
  end

  def position(x:, y:)
    moves.where(x:x, y:y).first
  end

  def color_same_as_last_move?(color)
    return false if moves.empty? || !match.joined?

    last_move.color == color.to_s
  end

  def last_move
    moves.order("created_at ASC").last
  end

  def capture_surrounded_groups
    presenter.components_adjacent_to_last_move.each do |component|
    end
  end

  def presenter
    @presenter ||= BoardPresenter.new(self)
  end
end

