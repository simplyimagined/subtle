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

  describe "verify_guess/2" do
    test "garbage input" do
      puzzle = Puzzle.new("paper")
      assert {:error, :invalid_arguments} == Puzzle.verify_guess(puzzle, 12345)
    end

    test "wrong guess length" do
      puzzle = Puzzle.new("paper")
      assert {:error, :invalid_length} == Puzzle.verify_guess(puzzle, "abc")
      assert {:error, :invalid_length} == Puzzle.verify_guess(puzzle, "abcdefg")
    end

    test "game over" do
      puzzle = Map.put(Puzzle.new("paper"), :state, :game_over)
      assert {:error, :game_over} == Puzzle.verify_guess(puzzle, "guess")
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
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert puzzle.state == :game_over
    end

    test "guessing after game finished" do
      puzzle = %Puzzle{state: :game_over, answer: "paper", guesses: []}
      assert {:error, :game_over} = Puzzle.make_guess(puzzle, "guess")
    end

    test "too long of a guess" do
      puzzle = Puzzle.new("paper")
      assert {:error, :invalid_length} =
        Puzzle.make_guess(puzzle, "really long guess")
    end

    test "garbage input instead of guess" do
      puzzle = Puzzle.new("paper")
      assert {:error, :baby_dont_hurt_me} = Puzzle.make_guess(puzzle, 123)
    end
  end

  describe "test guess counts" do
    test "guesses_remaining? and guesses_remaining" do
      puzzle = Puzzle.new("paper")
      assert Puzzle.guesses_remaining?(puzzle) == true
      assert Puzzle.guesses_remaining(puzzle) == puzzle.max_guesses

      # make all the guesses (minus one)
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert Puzzle.guesses_remaining?(puzzle) == true
      assert Puzzle.guesses_remaining(puzzle) == 1

      # make last guess
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert Puzzle.guesses_remaining?(puzzle) == false
      assert Puzzle.guesses_remaining(puzzle) == 0
    end

    test "last_guess?" do
      puzzle = Puzzle.new("paper")
      assert Puzzle.last_guess?(puzzle) == false

      # make all the guesses (minus one)
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert Puzzle.last_guess?(puzzle) == true

      # test one more
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      assert Puzzle.last_guess?(puzzle) == true
    end
  end

  describe "normalized_guesses and empty_guesses" do
    test "new puzzle" do
      puzzle = Puzzle.new("paper")
      assert Enum.count(Puzzle.empty_guesses(puzzle)) == puzzle.max_guesses
      assert Enum.count(Puzzle.normalized_guesses(puzzle)) == puzzle.max_guesses
    end

    test "partial puzzle" do
      puzzle = Puzzle.new("paper")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")

      assert Enum.count(Puzzle.empty_guesses(puzzle)) == puzzle.max_guesses - 2
      assert Enum.count(Puzzle.normalized_guesses(puzzle)) == puzzle.max_guesses
    end

    test "full puzzle" do
      puzzle = Puzzle.new("paper")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
      {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")

      assert Enum.count(Puzzle.empty_guesses(puzzle)) == 0
      assert Enum.count(Puzzle.normalized_guesses(puzzle)) == puzzle.max_guesses
    end
  end

end
