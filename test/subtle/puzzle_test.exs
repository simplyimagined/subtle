defmodule Subtle.PuzzleTest do
  use ExUnit.Case, async: true
  alias Subtle.Puzzle

  describe "letter_counts/1" do
    test "letter counts for input 'paper'" do
      assert Puzzle.letter_counts("paper") ==
        %{"a" => 1, "e" => 1, "p" => 2, "r" => 1}
    end

    test "letter counts for input 'zebra'" do
      assert Puzzle.letter_counts("zebra") ==
        %{"a" => 1, "b" => 1, "e" => 1, "r" => 1, "z" => 1}
    end
  end

  describe "reduce_letter_count/2" do
    test "reduce count for p in pizza" do
      pizza_counts = Puzzle.letter_counts("pizza")
      assert Puzzle.reduce_letter_count(pizza_counts, "p") ==
        %{"a" => 1, "i" => 1, "p" => 0, "z" => 2}
    end

    test "reduce count for e in pizza" do
      pizza_counts = Puzzle.letter_counts("pizza")
      assert Puzzle.reduce_letter_count(pizza_counts, "e") ==
        %{"a" => 1, "i" => 1, "p" => 1, "z" => 2}
    end

    test "reduce count for z in pizza several times" do
      pizza_counts = Puzzle.letter_counts("pizza")
      new_counts =
        Puzzle.reduce_letter_count(pizza_counts, "z")
        |> Puzzle.reduce_letter_count("z")
        |> Puzzle.reduce_letter_count("z")
      assert new_counts == %{"a" => 1, "i" => 1, "p" => 1, "z" => 0}
    end
  end

  describe "compare_letter_pair/1" do
    test "when letters match" do
      assert Puzzle.compare_letter_pair({"a", "a"}) == {"a", :correct}
    end

    test "when letters don't match" do
      assert Puzzle.compare_letter_pair({"z", "a"}) == {"z", :miss}
    end

    test "when input is wrong" do
      assert Puzzle.compare_letter_pair({:foo, "a"}) == {:foo, :miss}
    end
  end

  describe "process_letter_pair/2" do
    test "when letter matches" do
      counts = Puzzle.letter_counts("pizza")
      assert Puzzle.process_letter_pair({"z", "z"}, counts) ==
        {{"z", :correct}, %{"a" => 1, "i" => 1, "p" => 1, "z" => 1}}
    end

    test "when letter doesn't match but is in answer" do
      counts = Puzzle.letter_counts("pizza")
      assert Puzzle.process_letter_pair({"a", "z"}, counts) ==
        {{"a", :wrong_position}, %{"a" => 0, "i" => 1, "p" => 1, "z" => 2}}
    end

    test "when letter isn't in answer" do
      counts = Puzzle.letter_counts("pizza")
      assert Puzzle.process_letter_pair({"q", "z"}, counts) ==
        {{"q", :wrong_letter}, %{"a" => 1, "i" => 1, "p" => 1, "z" => 2}}
    end
  end

  describe "compare_letters/2" do
    test "compare apple and paper" do
      assert Puzzle.compare_letters("apple", "paper") ==
        [
          {"a", :wrong_position},
          {"p", :wrong_position},
          {"p", :correct},
          {"l", :wrong_letter},
          {"e", :wrong_position}
        ]
    end

    test "compare apple and tuple" do
      assert Puzzle.compare_letters("apple", "tuple") ==
        [
          {"a", :wrong_letter},
          {"p", :wrong_position},
          {"p", :correct},
          {"l", :correct},
          {"e", :correct}
        ]
    end
  end

  describe "guess_word/2" do
    test "guess apple for apple" do
      assert Puzzle.guess_word("apple", "apple") == {:ok, :correct}
    end

    test "guess apple for paper" do
      assert Puzzle.guess_word("apple", "paper") ==
        {:ok,
          [
            {"a", :wrong_position},
            {"p", :wrong_position},
            {"p", :correct},
            {"l", :wrong_letter},
            {"e", :wrong_position}
          ]}
    end

    test "mismatched word length" do
      assert Puzzle.guess_word("audacious", "pizza") == {:error, :invalid_length}
    end

    test "invalid inputs" do
      assert Puzzle.guess_word(100, "pizza") == {:error, :invalid_arguments}
    end
  end
end
