defmodule Subtle.Puzzle do
  @moduledoc """
  Documentation for `Puzzle`.
  Functions for guesses and letter comparisons.
  """

  @doc """
  get_random_puzzle_word

  ## Examples

      iex> Puzzle.get_random_puzzle_word()
      "paper"

  """
  def get_random_puzzle_word() do
    puzzle_words()
    |> Enum.random()
  end

  # Ideally we would cache this, but for now it's simple and blazing fast
  def puzzle_words() do
    :code.priv_dir(:subtle)
    |> Path.join("/puzzle_files/puzzle_words.txt")
    |> File.read!()
    |> String.split("\n")
  end

  def guess_word(guess, answer)
  when is_binary(guess) and is_binary(answer) and guess == answer
  do
    {:ok, :correct}
  end
  def guess_word(guess, answer) when is_binary(guess) and is_binary(answer)
  do
    answer_len = String.length(answer)
    case String.length(guess) do
      ^answer_len -> {:ok, compare_letters(guess, answer)}
      _           -> {:error, :invalid_length}
    end
  end
  def guess_word(_guess, _answer) do
    {:error, :invalid_arguments}
  end

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
    #   {"l", :wrong_letter}, {"e", :wrong_position}]
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

  def process_letter_pair({_a, _b} = pair, counts) do
    case compare_letter_pair(pair) do
      {a, :correct} ->
        {{a, :correct}, reduce_letter_count(counts, a)}
      {a, :miss} ->
        cond do
          is_number(counts[a]) and counts[a] > 0 ->
            {{a, :wrong_position}, reduce_letter_count(counts, a)}
          true ->
            {{a, :wrong_letter}, counts}
        end
    end
  end

  def compare_letter_pair({a, b}) when a == b, do: {a, :correct}
  def compare_letter_pair({a, _b}), do: {a, :miss}
#  def compare_letter_pair({a, b}) do
#    cond do
#      a == b  -> {a, :correct}
#      true    -> {a, :miss}
#    end
#  end

  def letter_counts(word) do
    word
    |> String.graphemes()
    |> Enum.reduce(%{}, fn char, acc ->
          Map.put(acc, char, (acc[char] || 0) + 1)
        end)
  end

  def reduce_letter_count(letter_counts, reduced_letter) do
    letter_counts
    |> Enum.reduce(%{}, fn {letter, count} , acc  ->
      Map.put(acc, letter, adjust_count(letter, reduced_letter, count)) end)
  end

  defp adjust_count(a, b, count) when a == b and count > 0, do: count - 1
  defp adjust_count(_a, _b, count), do: count

#  defp adjust_count(a, b, count) do
#    cond do
#      a == b  -> count - 1
#      true    -> count
#    end
#  end

end
