defmodule Subtle.PuzzleDictionary do
  use Agent

  @wordle_words "/puzzle_files/wordle_words.txt"
  @large5_words "/puzzle_files/large5_words.txt"
  @small5_words "/puzzle_files/small5_words.txt"

  # Fire up the Agent and store the dictionary map in it
  @doc false
  def start_link(_opts) do
    Agent.start_link(
      fn -> dictionary_map_from_disk() end,
      name: __MODULE__)
  end

  @doc"""
  Pull the dictionary from our Agent's state
  Valid keys include [:wordle, :large5, :small5]
  """
  def dictionary(dict \\ :wordle) do
    Agent.get(__MODULE__, fn dict_map -> dict_map end)
    |> Map.get(dict)
  end

  @doc"""
  Verifies that a word is in the dictionary.

  ### Examples

      iex> PuzzleDictionary.verify_word("apple")
      # true
      iex> PuzzleDictionary.verify_word("foobar")
      # false

  """
  def verify_word(guess, dict \\ :large5) do
    dictionary(dict)
    |> Enum.member?(guess)
  end

  @doc """
  Get a random word from our dictionary.

  ### Examples

      iex> PuzzleDictionary.random_word()
      # "paper"

  """
  def random_word(dict \\ :wordle) do
    dictionary(dict)
    |> Enum.random()
  end

  # Load both wordle and large5 dictionaries from the files
  @doc false
  def dictionary_map_from_disk do
    %{
      :wordle => dict_words_from_file(@wordle_words),
      :large5 => dict_words_from_file(@large5_words),
      :small5 => dict_words_from_file(@small5_words)
     }
  end

  # Load a list of words from the file
  @doc false
  def dict_words_from_file(filename) do
    :code.priv_dir(:subtle)
    |> Path.join(filename)
    |> File.read!()
    |> String.split("\n")
    |> Enum.map(fn w -> String.downcase(w) end)
  end

end
