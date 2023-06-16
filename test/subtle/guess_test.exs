defmodule Subtle.GuessTest do
  use ExUnit.Case, async: true
  alias Subtle.Guess

  describe "letter_counts/1" do
    test "letter counts for input 'paper'" do
      assert Guess.letter_counts("paper") ==
        %{"a" => 1, "e" => 1, "p" => 2, "r" => 1}
    end

    test "letter counts for input 'zebra'" do
      assert Guess.letter_counts("zebra") ==
        %{"a" => 1, "b" => 1, "e" => 1, "r" => 1, "z" => 1}
    end
  end

  describe "reduce_letter_count/2" do
    test "reduce count for p in pizza" do
      pizza_counts = Guess.letter_counts("pizza")
      assert Guess.reduce_letter_count(pizza_counts, "p") ==
        %{"a" => 1, "i" => 1, "p" => 0, "z" => 2}
    end

    test "reduce count for e in pizza" do
      pizza_counts = Guess.letter_counts("pizza")
      assert Guess.reduce_letter_count(pizza_counts, "e") ==
        %{"a" => 1, "i" => 1, "p" => 1, "z" => 2}
    end

    test "reduce count for z in pizza several times" do
      pizza_counts = Guess.letter_counts("pizza")
      new_counts =
        Guess.reduce_letter_count(pizza_counts, "z")
        |> Guess.reduce_letter_count("z")
        |> Guess.reduce_letter_count("z")
      assert new_counts == %{"a" => 1, "i" => 1, "p" => 1, "z" => 0}
    end
  end

  describe "process_letter_pair/2" do
    test "when letter matches" do
      counts = Guess.letter_counts("pizza")
      assert Guess.process_letter_pair({"z", "z"}, counts) ==
        {{"z", :correct}, %{"a" => 1, "i" => 1, "p" => 1, "z" => 1}}
    end

    test "when letter doesn't match but is in answer" do
      counts = Guess.letter_counts("pizza")
      assert Guess.process_letter_pair({"a", "z"}, counts) ==
        {{"a", :wrong_position}, %{"a" => 0, "i" => 1, "p" => 1, "z" => 2}}
    end

    test "when letter isn't in answer" do
      counts = Guess.letter_counts("pizza")
      assert Guess.process_letter_pair({"q", "z"}, counts) ==
        {{"q", :wrong_letter}, %{"a" => 1, "i" => 1, "p" => 1, "z" => 2}}
    end
  end

  describe "compare_letters/2" do
    test "compare apple and paper" do
      assert Guess.compare_letters("apple", "paper") ==
        [
          {"a", :wrong_position},
          {"p", :wrong_position},
          {"p", :correct},
          {"l", :wrong_letter},
          {"e", :wrong_position}
        ]
    end

    test "compare apple and tuple" do
      assert Guess.compare_letters("apple", "tuple") ==
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
      assert Guess.guess_word("apple", "apple") ==
        {:ok, :correct,
          %Guess{
            guess: "apple",
            results: [
              {"a", :correct},
              {"p", :correct},
              {"p", :correct},
              {"l", :correct},
              {"e", :correct}
            ]
          }}
    end

    test "guess apple for paper" do
      assert Guess.guess_word("apple", "paper") ==
        {:ok, :incorrect,
          %Guess{
            guess: "apple",
            results: [
              {"a", :wrong_position},
              {"p", :wrong_position},
              {"p", :correct},
              {"l", :wrong_letter},
              {"e", :wrong_position}
            ]
          }}
    end

    test "mismatched word length" do
      assert Guess.guess_word("audacious", "pizza") ==
        {:error, :invalid_length}
    end

    test "invalid inputs" do
      assert Guess.guess_word(100, "pizza") ==
        {:error, :invalid_arguments}
    end
  end
end
