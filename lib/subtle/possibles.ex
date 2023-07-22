defmodule Subtle.Possibles do

  alias Subtle.{Game, PuzzleDictionary}

  @doc """
  Returns a list of words that might be the answer for the game

  ## Examples
    Game.new("paper")
    Game.make_guess("stare")
    Game.make_guess("panic")
    Game.process_guesses
    ["paddy", "paler", "papal", "paper", "parer", "parka", "parry", "payee",
    "payer"]
  """
  def possible_words(game) do
    with true <- Game.has_guessed?(game) do
      PuzzleDictionary.dictionary
      |> Enum.filter(&String.match?(&1, guess_regex(game)))
    else
      false -> []
    end
  end

  @doc """
  Returns a regex for the game that can be used to find
  compatible words
  """
  def guess_regex(game, _level \\ :simple) do
    # We need to build up a sequence of 5 matches
    # 1) for each :correct slot we put that letter
    #   {"a", :correct} --> "[a]"
    # 2) for all other slots we need to put a list of wrong letters
    #    that can't be in the answer --> "[^atu]"

    # First we need to get a map describing the guesses so far
    guess_map = process_guesses(game)

    # build the regex slot by slot
    Enum.to_list(1..game.puzzle.word_length)
    |> Enum.reduce("",
      fn i, acc ->
        case Map.get(guess_map.good, i) do
          nil -> acc <> "[^" <> unavailable_letters(guess_map, i) <> "]"
          letter -> acc <> "[" <> letter <> "]"
        end
      end)
    |> Regex.compile!
  end

  @doc """
  Returns a sorted list of unavailable letters by merging
  :bad with :not_here for the desired index.
  """
  def unavailable_letters(guess_map, i) do
    guess_map.bad
    |> Enum.concat(Map.get(guess_map.not_here, i, []))
    |> Enum.uniq
    |> Enum.sort
    |> List.to_string
  end

  @doc """
  Get a map describing the guesses so far.

  We're transforming the Puzzle results into a map containing a list of
  all the wrong letters, the locations of the correct letters, and where
  good letters can't be.

  ## Examples
    Game.new("paper")
    Game.make_guess("stare")
    Game.make_guess("panic")
    Game.process_guesses
    %{
      bad: ["c", "i", "n", "t", "s"],
      good: %{1 => "p", 2 => "a"},
      not_here: %{3 => ["a"], 4 => ["r"], 5 => ["e"]}
    }

  """
  def process_guesses(game) do
    game.puzzle.guesses
    |> Enum.reduce(%{bad: [], good: %{}, not_here: %{}},
        fn guess, map ->
          Map.merge(map, process_guess(guess), &merge_guess/3)
        end)
  end

  defp merge_guess(:bad, v1, v2) do
    # concat letters and remove duplicates
    List.flatten([v2 | v1]) |> Enum.uniq |> Enum.sort
  end
  defp merge_guess(:good, v1, v2) do
    Map.merge(v1, v2)    # merge the two "good letter" maps
  end
  defp merge_guess(:not_here, v1, v2) do
    # merge the previous list of letters with this new list
    Map.merge(v1, v2,
      fn _key, val1, val2 ->
        val1 |> Enum.concat(val2) |> Enum.uniq |> Enum.sort
      end)
  end

  @doc """
  Transform a single guess into a map containing wrong letters, the
  locations of the correct letters, and where good letters can't be.
  """
  def process_guess(guess) do
    # example output:
    # %{bad: ["m", "n"], good: %{1 => "a", 5 => "e"}, not_here => %{1 => ["x", "y"]}}
    guess.results
    |> Enum.with_index(1)   # start with offset 1
    |> Enum.reduce(%{bad: [], good: %{}, not_here: %{}}, &update_guess_map/2)
  end

  defp update_guess_map({{letter, :wrong_letter}, _index}, map) do
    Map.update!(map, :bad, fn l -> [letter | l] end)
  end
  defp update_guess_map({{letter, :correct}, index}, map) do
    Map.update!(map, :good, fn m -> Map.put(m, index, letter) end)
  end
  defp update_guess_map({{letter, :wrong_position}, index}, map) do
    # this is a map: key is index, value is a list
    Map.update!(map, :not_here,
        fn m -> Map.update(m, index, [letter], fn l -> [letter | l] end)
      end)
  end

end
