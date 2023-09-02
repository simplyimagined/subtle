defmodule Subtle.Possibles do

  alias Subtle.{Game, PuzzleDictionary}

  @doc """
  Returns a list of words that might be the answer for the game.

  ## Examples
    Game.new("paper")
    Game.make_guess("stare")
    Game.make_guess("panic")
    Game.process_guesses()
    ["paddy", "paler", "papal", "paper", "parer", "parka", "parry", "payee",
    "payer"]
  """
  @spec possible_words(Game, :simple | :intermediate) :: list
  def possible_words(game, guidance \\ :simple) do
    with true <- Game.has_guessed?(game) do
      PuzzleDictionary.dictionary
      |> Enum.filter(&String.match?(&1, guess_regex(game, guidance)))
    else
      false -> []
    end
  end

  @doc """
  Returns a regex for the game that can be used to find compatible words.

  The guidance level of :simple or :intermediate will determine how much
  help is given.
  """
  @spec guess_regex(Game, :simple | :intermediate) :: Regex.t()
  def guess_regex(game, guidance \\ :simple) do
    # We need to build up a sequence of 5 matches
    # 1) for each :correct slot we put that letter
    #   {"a", :correct} --> "[a]"
    # 2) for all other slots we need to put a list of wrong letters
    #    that can't be in the answer --> "[^atu]"

    # First we need to get a map describing the guesses so far
    guess_map = process_guesses(game)

    contains = contains_letters_pattern(guess_map, guidance)
    filter = correct_and_exclusions_pattern(guess_map, game.puzzle.word_length)

    pattern = Enum.join([contains, filter])

    Regex.compile!(pattern)
  end

  @doc """
  Returns a string for the regex for each index in the answer.

  Will be either [^xyz] to exclude these letters or [a] to require an 'a'.
  """
  def correct_and_exclusions_pattern(guess_map, length) do
    # Build the pattern slot by slot.
    # Slot will be "none of these letter here" or "this letter here".
    Enum.to_list(1..length)
    |> Enum.reduce("",
      fn i, acc ->
        case Map.get(guess_map.good, i) do
          nil     -> acc <> "[^" <> unavailable_letters(guess_map, i) <> "]"
          letter  -> acc <> "[" <> letter <> "]"
        end
      end)
  end

  @doc """
  Return a string for the added to the regex to search for words
  containing required letters.

  For :intermediate filtering:
    The :not_here list contains letters that must be in the answer,
    but not at this location. We turn this into a list of required letters
    and have the regex require them.

  For :simple filtering we return an empty string.
  """
  def contains_letters_pattern(guess_map, :intermediate) do
    # Get every letter in :not_here at least once, then flatten()
    # and uniq() to remove duplicates.
    Map.get(guess_map, :not_here, %{})
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reduce("", fn letter, acc -> acc <> "(?=.*#{letter})" end)
  end

  def contains_letters_pattern(_guess_map, :simple) do
    # Empty pattern because we only want :simple search.
    ""
  end

  @doc """
  Returns a sorted list of unavailable letters by merging
  :bad with :not_here for the desired index.
  """
  def unavailable_letters(guess_map, i) do
    guess_map.bad
    |> Enum.concat(Map.get(guess_map.not_here, i, []))
    |> Enum.uniq()
    |> Enum.sort()
    |> List.to_string()
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
    guess_map =
      Enum.reduce(
        game.puzzle.guesses,
        %{bad: [], good: %{}, not_here: %{}},
        fn guess, map ->
          Map.merge(map, process_guess(guess), &merge_guess/3)
        end)
    # Remove every letter in :not_here map from :bad list.
    remove_not_here_from_bad(guess_map)
  end

  defp remove_not_here_from_bad(guess_map) do
    # Remove every letter in :not_here map from :bad list.
    #
    # A guess "again" for answer "omega" has "a" in :bad list and
    # also :not_here list. We need to fix the :bad list so :not_here
    # letters aren't excluded from every slot.
    not_heres =
      guess_map.not_here
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()

    filtered_bad = Enum.reject(guess_map.bad, & &1 in not_heres)

    %{guess_map | bad: filtered_bad}
  end

  defp merge_guess(:bad, v1, v2) do
    # concat letters and remove duplicates
    List.flatten([v2 | v1]) |> Enum.uniq |> Enum.sort
  end

  defp merge_guess(:good, v1, v2) do
    # Merge the two "good letter" maps.
    Map.merge(v1, v2)
  end

  defp merge_guess(:not_here, v1, v2) do
    # Merge the previous list of letters with this new list.
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

  # Wrong letters go in the :bad letter list.
  defp update_guess_map({{letter, :wrong_letter}, _index}, map) do
    Map.update!(map, :bad, fn l -> [letter | l] end)
  end

  # Correct letters go in the :good map for this index.
  defp update_guess_map({{letter, :correct}, index}, map) do
    Map.update!(map, :good, fn m -> Map.put(m, index, letter) end)
  end

  # Good letters in the wrong position are marked :not_here for this index.
  defp update_guess_map({{letter, :wrong_position}, index}, map) do
    # this is a map: key is index, value is a list
    Map.update!(map, :not_here,
        fn m -> Map.update(m, index, [letter], fn l -> [letter | l] end)
      end)
  end

end
