defmodule Subtle.PuzzleDictionary do
  use Agent

  @dict_filename "/puzzle_files/puzzle_words.txt"

  # Fire up the Agent and store the dictionary in it
  @doc false
  def start_link(_opts) do
#    opts = Map.put_new(opts, :name, __MODULE__)
#    IO.inspect(opts)
    Agent.start_link(
      fn -> dict_words_from_file(@dict_filename) end,
      name: __MODULE__)
  end

  @doc"""
  Pull the dictionary from our Agent's state
  """
  def dictionary() do
    Agent.get(__MODULE__, fn dict -> dict end)
  end

  @doc"""
  Check that a word is in the dictionary

  ### Examples

      iex> PuzzleDictionary.verify_word("apple")
      # true
      iex> PuzzleDictionary.verify_word("foobar")
      # false

  """
  def verify_word(guess) do
    dictionary()
    |> Enum.member?(guess)
  end

  @doc """
  Get a random word from our dictionary.

  ### Examples

      iex> PuzzleDictionary.random_word()
      # "paper"

  """
  def random_word() do
    dictionary()
    |> Enum.random()
  end

  # Load a list of words from the file
  @doc false
  def dict_words_from_file(filename) do
    :code.priv_dir(:subtle)
    |> Path.join(filename)
    |> File.read!()
    |> String.split("\n")
  end

# keeping this stream example for another day
#
#  {:ok, list_of_results} =
#    Repo.transaction(
#      fn ->
#        an_ecto_query
#        |> Repo.stream(max_rows: 1000)
#        |> Stream.map(...)
#        |> Stream.filter(...)
#        |> Stream.flat_map(...)
#        # etc. processing steps for each record
#        |> Enum.to_list()
#      end,
#      timeout: :infinity
#    )
end
