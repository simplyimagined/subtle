defmodule Subtle.Guess do
  @moduledoc """
  Functions for guesses and letter comparisons.
  """

  alias __MODULE__

  @enforce_keys [:guess]
  defstruct [:guess, :results]

  def new(guess, results) do
    %Guess{guess: guess, results: results}
  end

#I have no idea how to typedef what I want, so dynamic it is!
 # @letter_position [:correct, :wrong_position, :wrong_letter, :none]

#  @type guess_result_tuple :: {
#    letter: String.t,
#    result: atom()
#  }

  @doc """
  Function that takes a guess and compares it to the answer.

  ### Examples
      Guess apple for paper

      iex> Guess.guess_word("apple", "paper")
      {:ok, :incorrect,
        %Guess{
          guess: "apple"
          results: [
            {"a", :wrong_position}, {"p", :wrong_position},
            {"p", :correct}, {"l", :wrong_letter},
            {"e", :wrong_position}
          ]
        }}

      Guess paper for paper

      iex> Guess.guess_word("paper", "paper")
      {:ok, correct,
        %Guess{
          guess: "paper"
          results: [
            {"p", :correct}, {"a", :correct}, {"p", :correct},
            {"e", :correct}, {"r", :correct}
          ]
        }}
  """
  def guess_word(guess, answer)
  when is_binary(guess) and is_binary(answer) and guess == answer
  do
    {:ok, :correct, new(answer, compare_letters(answer))}
  end
  def guess_word(guess, answer) when is_binary(guess) and is_binary(answer)
  do
    answer_len = String.length(answer)
    case String.length(guess) do
      ^answer_len -> {:ok, :incorrect, new(guess, compare_letters(guess, answer))}
      _           -> {:error, :invalid_length}
    end
  end
  def guess_word(_guess, _answer) do
    {:error, :invalid_arguments}
  end

  @doc """
  compare_letters/2

  ## Examples
      # guess apple for paper
      iex> Guess.compare_letters("apple", "paper")
      [ {"a", :wrong_position}, {"p", :wrong_position},
        {"p", :correct}, {"l", :wrong_letter},
        {"e", :wrong_position} ]
  """
  @spec compare_letters(String.t, String.t) :: list
  def compare_letters(guess, answer) do
    # guess = "apple", answer = "paper"
    # make into grapheme lists:
    # ["a", "p", "p", "l", "e"], ["p", "a", "p", "e", "r"]
    # zip these together:
    # -> [{"a", "p"}, {"p", "a"}, {"p", "p"}, {"l", "e"}, {"e", "r"}]
    # map_reduce:
    # {"a", "p"}, %{"a" => 1, "e" => 1, "p" => 2, "r" => 1} -> {"a", :wrong_position}
    # {"p", "a"}, %{"a" => 0, "e" => 1, "p" => 2, "r" => 1} -> {"p", :wrong_position}
    # {"p", "p"}, %{"a" => 0, "e" => 1, "p" => 1, "r" => 1} -> {"p", :correct}
    # {"l", "e"}, %{"a" => 0, "e" => 1, "p" => 0, "r" => 1} -> {"p", :wrong_letter}
    # {"e", "r"}, %{"a" => 0, "e" => 1, "p" => 0, "r" => 1} -> {"p", :wrong_position}
    #
    # answers =
    #   [{"a", :wrong_position}, {"p", :wrong_position}, {"p", :correct},
    #     {"l", :wrong_letter}, {"e", :wrong_position}]
    #
    answer_letters = String.graphemes(answer)
    guess_letters = String.graphemes(guess)

    {answers, _counts} =
      Enum.zip(guess_letters, answer_letters)
      |> Enum.map_reduce(letter_counts(answer),
          fn pair, counts -> process_letter_pair(pair, counts) end)

    # return only the answers, not the counts
    answers
  end
  def compare_letters(answer), do: compare_letters(answer, answer)

  @doc """
  process_letter_pair/2

  ## Examples
      # guess apple for paper, first char
      iex> Guess.process_letter_pair("a", "p", letter_counts(paper))
      {"a", :wrong_position}
      # guess apple for paper, third char
      iex> Guess.process_letter_pair("p", "p", letter_counts(paper))
      {"p", :correct}

  """
  def process_letter_pair({_a, _b} = pair, counts) do
    case compare_letter_pair(pair) do
      # they match, return success
      {a, :correct} ->
        {{a, :correct}, reduce_letter_count(counts, a)}
      # they don't match, but the letter may be in the puzzle elsewhere
      {a, :miss} ->
        cond do
          # check if the letter is in the puzzle elsewhere
          is_number(counts[a]) and counts[a] > 0 ->
            {{a, :wrong_position}, reduce_letter_count(counts, a)}
          true ->
            {{a, :wrong_letter}, counts}
        end
    end
  end

  defp compare_letter_pair({a, b}) when a == b, do: {a, :correct}
  defp compare_letter_pair({a, _b}), do: {a, :miss}

   @doc """
  letter_counts/1

  ## Examples

      iex> Guess.letter_counts("apple")
      %{"a" => 1, "e" => 1, "l" => 1, "p" => 2}

  """
  def letter_counts(word) do
    word
    |> String.graphemes()
    |> Enum.reduce(%{}, fn char, acc ->
          Map.put(acc, char, (acc[char] || 0) + 1)
        end)
  end

   @doc """
  reduce_letter_count/2

  ## Examples

      iex> apple_counts = letter_counts("apple")
      %{"a" => 1, "e" => 1, "l" => 1, "p" => 2}
      iex> Guess.reduce_letter_count(apple_counts, "e")
      %{"a" => 1, "e" => 0, "l" => 1, "p" => 2}

  """
  def reduce_letter_count(letter_counts, reduced_letter) do
    letter_counts
    |> Enum.reduce(%{}, fn {letter, count} , acc  ->
      Map.put(acc, letter, adjust_count(letter, reduced_letter, count)) end)
  end

  defp adjust_count(a, b, count) when a == b and count > 0, do: count - 1
  defp adjust_count(_a, _b, count), do: count
end
