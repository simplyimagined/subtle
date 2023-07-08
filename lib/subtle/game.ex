defmodule Subtle.Game do

  alias Subtle.{Game, Puzzle, PuzzleDictionary}

  @verify_guesses true

  @enforce_keys [:puzzle]
  defstruct [
    verify_guesses: @verify_guesses,
    puzzle: %{},
    message: ""
  ]

  def new() do
    Game.new(PuzzleDictionary.random_word())
  end
  def new(answer) do
    %Game{
      verify_guesses: @verify_guesses,
      puzzle: Puzzle.new(answer),
      message: "Guess a word."
    }
  end

  def set_verify(game, verify) do
    Map.put(game, :verify_guesses, verify)
  end

  def message(game), do: game.message

  def state(game), do: game.puzzle.state
  def answer(game), do: game.puzzle.answer
  def guesses_remaining(game), do: Puzzle.guesses_remaining(game.puzzle)
  def has_guessed?(game), do: Puzzle.has_guessed?(game.puzzle)
  def summary(game), do: Puzzle.summary(game.puzzle)

  def guesses(game), do: Puzzle.normalized_guesses(game.puzzle)

  def verify_guess(game, guess) do
    case game.verify_guesses do
      true -> Puzzle.verify_guess(game.puzzle, guess)
      false -> {:ok, game.puzzle}
    end
  end

  def make_guess(game, guess) do
    guess = String.downcase(guess)

    with  {:ok, _puzzle} <- verify_guess(game, guess),
          {:ok, puzzle} <- Puzzle.make_guess(game.puzzle, guess)
    do
      {:ok, game
            |> Map.put(:puzzle, puzzle)
            |> Map.put(:message, puzzle.message)}
    else
      {:error, puzzle, _reason} ->
        {:error, game
                  |> Map.put(:puzzle, puzzle)
                  |> Map.put(:message, puzzle.message)}
    end
  end

  # This won't work correctly. Ideally, we want to show letters that are in
  # correct position, but we also need to show letter not in position.
  # We need to do that without giving hints away, unless they uncovered it.
  # Then we need to show used letters.
  #
  # Maybe for now all used letters get marked?
  # ie, :wrong_letter and :in_puzzle, let them figure it out
  def letters_used(game) do
    # 1) Go through all the letters already guessed
    # 2) Create a map with results for each letter guessed
    # [{"b", :correct}, {"c", :wrong_letter}, {"b", :wrong_position}] ->
    # %{"b" => [:correct, :wrong_position]}, "c" => [:wrong_letter]}
    game.puzzle.guesses
    |> Enum.reduce([], fn x, acc -> [x.results | acc] end)
    |> List.flatten()
    |> reduce_letters()
  end

  def reduce_letters(l) do
    # This is similar to frequencies() but accumulating results, not count
    Enum.reduce(l, %{}, fn {letter, result}, map ->
      case map do
        %{^letter => value} -> %{map | letter => [result | value]}
        %{} -> Map.put(map, letter, [result])
      end
    end)
  end

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
  def available_words(game) do
    with true <- has_guessed?(game) do
      PuzzleDictionary.dictionary
      |> Enum.filter(&String.match?(&1, build_regex(game)))
    else
      false -> []
    end
  end

  def available_words_as_string(game, max_words \\ 10) do
    # use inspect to print some words into a string
    available_words(game)
    |> inspect([limit: max_words, as_strings: true])
    |> String.replace("\"", "")
    |> String.slice(1..-2//1)
  end

  @doc """
  Returns a regex for the game that can be used to find
  compatible words
  """
  def build_regex(game, _level \\ :simple) do
    # We need to build up a sequence of 5 matches
    # 1) for each :correct slot we put that letter
    #   {"a", :correct} --> "[a]"
    # 2) for all other slots we need to put a list of wrong letters
    #    that can't be in the answer --> "[^atu]"

    # First we need to get a map describing the guesses so far
    guess_map = process_guesses(game)

    # Get the letters that can't be used
    bad_letters =
      guess_map.bad
      |> Enum.sort
      |> List.to_string

    # build the regex slot by slot
    Enum.to_list(1..game.puzzle.word_length)
    |> Enum.reduce("",
      fn i, acc ->
        case Map.get(guess_map.good, i) do
          nil -> acc <> "[^" <> bad_letters <> "]"
          letter -> acc <> "[" <> letter <> "]"
        end
      end)
    |> Regex.compile!
  end

  @doc """
  Get a map describing the guesses so far

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

  Here we have a list of letters not in the puzzle as well as which slots
  have the correct letters.
  """
  def process_guesses(game) do
    game.puzzle.guesses
    |> Enum.reduce(%{bad: [], good: %{}, not_here: %{}},
          fn guess, map -> process_and_merge_guess(guess, map) end)
#    |> IO.inspect(label: "process_guesses")
  end
  def process_and_merge_guess(guess, map) do
    guess_map = process_guess(guess)
    Map.merge(map, guess_map,
      fn k, v1, v2 ->
        case k do
          :bad -> List.flatten([v2 | v1]) |> Enum.uniq  # concat letters and remove duplicates
          :good -> Map.merge(v1, v2)    # merge the two "good letter" maps
          # TODO: not correct yet
          :not_here -> Map.merge(v1, v2)  # this will need more logic than this
        end
      end)
  end
  def process_guess(guess) do
    # example:
    # %{bad: ["m", "n"], good: %{1 => "a", 5 => "e"}, not_here => %{1 => ["x", "y"]}}
    guess.results
    |> Enum.with_index(1)   # start with offset 1
    |> Enum.reduce(%{bad: [], good: %{}, not_here: %{}}, &update_guess_map/2)
#          fn {{letter, result}, index}, map ->
#            case result do
#              :wrong_letter ->
#                Map.update!(map, :bad, fn l -> [letter | l] end)
#              :correct ->
#                Map.update!(map, :good, fn m -> Map.put(m, index, letter) end)
#              :wrong_position ->
#                Map.update!(map, :not_here, fn m ->
#                  Map.update(m, index, [letter], fn l -> [letter | l] end) end)
#            end
#          end)
  end

  defp update_guess_map({{letter, result}, index}, map) do
    case result do
      :wrong_letter ->
          Map.update!(map, :bad, fn l -> [letter | l] end)
      :correct ->
          Map.update!(map, :good, fn m -> Map.put(m, index, letter) end)
      :wrong_position ->
          Map.update!(map, :not_here, fn m ->
            Map.update(m, index, [letter], fn l -> [letter | l] end) end)
    end
  end

end
