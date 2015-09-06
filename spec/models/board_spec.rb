require 'rails_helper'

RSpec.describe Board, type: :model do
  let(:blank) { Move.colors["blank"] }
  let(:black) { Move.colors["black"] }
  let(:white) { Move.colors["white"] }
  let(:black_user) { FactoryGirl.create(:user) }
  let(:white_user) { FactoryGirl.create(:user) }
  let(:match) { FactoryGirl.create(:match, black_user: black_user, white_user: white_user) }
  before { match.create_board(9) }
  subject(:board) { match.board }

  it "has a match" do
    expect(board.match).to be_a(Match)
  end

  describe "#play_move" do

    it "allows non-overlapping moves alternating by color" do
      board.play_move(x: 1, y: 1, color: :black, user: black_user)
      board.play_move(x: 1, y: 2, color: :white, user: white_user)
      board.play_move(x: 2, y: 2, color: :black, user: black_user)
      expect(board.moves.count).to eq(3)
      expect(board.moves.last.x).to eq(2)
    end

    context "when one user tries to play twice in row" do
      it "does not allow the move" do
        expect(board.match.white_user_id).to_not eq(board.match.black_user_id)
        board.play_move(x: 1, y: 1, color: :black, user: black_user)
        board.play_move(x: 1, y: 2, color: :black, user: black_user)
        expect(board.moves.count).to eq(1)
        expect(board.moves.last.y).to eq(1)
      end
    end

    context "when one user tries to play on an occupied position" do

      it "does not allow the move" do
        board.play_move(x: 1, y: 1, color: :black, user: black_user)
        board.play_move(x: 1, y: 1, color: :white, user: white_user)
        expect(board.moves.count).to eq(1)
        expect(board.moves.last.color).to eq("black")
      end

      context "when a position used to be occupied (after a capture)" do

        it "allows the move" do
          board.play_move(x: 1, y: 1, color: :black, user: black_user)
          board.capture_moves_at([Point.new(1,1,black)])

          expect {
            board.play_move(x: 1, y: 1, color: :white, user: white_user)
          }.to change(board.moves, :count).by(1)
        end

      end
    end

    context "capturing" do

      before do
        board.play_move(x: 4, y: 5, color: :black, user: black_user)
        board.play_move(x: 5, y: 5, color: :white, user: white_user)
        board.play_move(x: 9, y: 4, color: :black, user: black_user)
        board.play_move(x: 4, y: 4, color: :white, user: white_user)
        board.play_move(x: 8, y: 4, color: :black, user: black_user)
        board.play_move(x: 3, y: 5, color: :white, user: white_user)
        board.play_move(x: 8, y: 5, color: :black, user: black_user)
      end

      it "captures a single piece" do
        board.play_move(x: 4, y: 6, color: :white, user: white_user)
        expect(board.state.to_a).to eq(
          [[0,0,0,0,0,0,0,0,0],
           [0,0,0,0,0,0,0,0,0],
           [0,0,0,0,0,0,0,0,0],
           [0,0,0,2,0,0,0,1,1],
           [0,0,2,0,2,0,0,1,0],
           [0,0,0,2,0,0,0,0,0],
           [0,0,0,0,0,0,0,0,0],
           [0,0,0,0,0,0,0,0,0],
           [0,0,0,0,0,0,0,0,0]]
        )
      end

      it "does not allow self-capture" do
        board.play_move(x: 4, y: 6, color: :white, user: white_user)
        expect {
          board.play_move(x: 4, y: 5, color: :black, user: black_user)
        }.to_not change(board.moves, :count)
      end

      it "allows self-surrounding" do
        board.play_move(x: 4, y: 6, color: :white, user: white_user)
        board.play_move(x: 1, y: 1, color: :black, user: black_user)
        expect(board.last_move.color).to eq("black")
        expect {
          board.play_move(x: 4, y: 5, color: :white, user: white_user)
        }.to change(board.moves, :count).by(1)
      end

    end

  end

  describe "#capture_moves_at" do
    let(:points) { [
      Point.new(3,4, black),
      Point.new(3,5, black),
      Point.new(4,5, black),
    ] }

    before do
      board.play_move(x: 4, y: 5, color: :black, user: black_user)
      board.play_move(x: 5, y: 5, color: :white, user: white_user)
      board.play_move(x: 3, y: 4, color: :black, user: black_user)
      board.play_move(x: 4, y: 4, color: :white, user: white_user)
      board.play_move(x: 3, y: 5, color: :black, user: black_user)
    end

    it "creates a move for each of the moves at the given points" do
      expect {
        board.capture_moves_at(points)
      }.to change(board.moves, :count).by(3)
    end

    it "creates blank move for each of the moves at the given points" do
      blank_moves = board.moves.where(color: blank)
      expect {
        board.capture_moves_at(points)
      }.to change(blank_moves, :count).by(3)
    end

    it "sets the points to blank" do
      initial_state_at_points = points.map { |p| board.state.get(p.x,p.y) }
      board.capture_moves_at(points)
      final_state_at_points = points.map { |p| board.state.get(p.x,p.y) }
      expect(initial_state_at_points).to eq([black, black, black])
      expect(final_state_at_points).to eq([blank, blank, blank])
    end
  end

end

