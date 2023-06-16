defmodule Subtle.PuzzleTest do
  use ExUnit.Case, async: true
  alias Subtle.Puzzle

  describe "make new puzzle" do
    test "new puzzle for 'paper'" do
      puzzle = Puzzle.new("paper")
      assert puzzle.state == :playing
      assert puzzle.answer == "paper"
    end
  end

  describe "make_guess/2" do
    test "test correct guess 'paper' for 'paper'" do
      {:ok, puzzle} =
        Puzzle.new("paper")
        |> Puzzle.make_guess("paper")
      assert puzzle.state == :game_won
      assert puzzle.guesses ==
        [
          %Subtle.Guess{
            guess: "paper",
            results: [
              {"p", :correct},
              {"a", :correct},
              {"p", :correct},
              {"e", :correct},
              {"r", :correct}
            ]
          }
        ]
    end

    test "test wrong guess 'apple' for 'paper'" do
      {:ok, puzzle} =
        Puzzle.new("paper")
        |> Puzzle.make_guess("apple")
      assert puzzle.state == :playing
      assert puzzle.guesses ==
        [
          %Subtle.Guess{
            guess: "apple",
            results: [
              {"a", :wrong_position},
              {"p", :wrong_position},
              {"p", :correct},
              {"l", :wrong_letter},
              {"e", :wrong_position}
            ]
          }
        ]
    end

    test "test too many guesses" do
      puzzle = Puzzle.new("paper")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert puzzle.state == :game_over
    end

    test "guessing after game finished" do
      puzzle = %Puzzle{state: :game_over, answer: "paper", guesses: []}
      assert Puzzle.make_guess(puzzle, "guess") ==
        {:error, puzzle, :game_over}
    end

    test "garbage input instead of guess" do
      assert Puzzle.make_guess(nil, 123) ==
        {:error, nil, :game_over}
    end

    test "too long of a guess" do
      puzzle = Puzzle.new("paper")
      assert Puzzle.make_guess(puzzle, "really long guess") ==
        {:error, puzzle, :invalid_length}
    end
  end
end
