class MatchesController < ApplicationController
  respond_to :html
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @websocket_url = websocket_url
    @matches = Match.all.order("id DESC")
  end

  def show
    @websocket_url = websocket_url
    @match = Match.find(params['id'])
    @width = @match.board_size*50
  end

  def new
    @match = Match.new
    @users = User.all
  end

  def create
    @match = Match.create(black_user: black_user, white_user: white_user)
    @match.create_board(board_size)
    respond_with @match, location: -> { match_path(@match) }
  end

  def update
    @match = Match.find_by(id: params['id'])
    if @match.joined?
      flash[:error] = "Match has already been joined by another player"
    else
      @match.update_attributes(white_user_id: current_user.id)
      @match.save
    end

    respond_with @match
  end

  private

  def black_user
    current_user
  end

  def white_user
    white_user = User.find_by(id: white_user_id)
    white_user = current_user if white_user.blank?

    white_user
  end

  def white_user_id
    params['match'] && params['match']['white_user_id']
  end

  def board_size
    params['match']['board_size'].to_i
  end

  def websocket_url
    return "goga.me/websocket" if Rails.env.production?

    "#{request.host_with_port}/websocket"
  end
end

