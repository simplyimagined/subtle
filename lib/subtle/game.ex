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

end
