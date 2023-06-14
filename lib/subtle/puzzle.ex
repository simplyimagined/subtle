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

end
