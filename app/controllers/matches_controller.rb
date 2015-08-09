class MatchesController < ApplicationController
  respond_to :html

  def index
    @matches = Match.all
  end

  def show
    @match = Match.find(match_params.fetch(:id))
  end

  def new
    @match = Match.new
    @users = User.all
  end

  def create
    @match = Match.create(match_params)
    respond_with @match
  end

  private

  def match_params
    params.permit(:id, :black_user_id, :white_user_id)
  end
end
