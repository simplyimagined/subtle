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

  def message(game), do: game.message

  def state(game), do: game.puzzle.state
  def answer(game), do: game.puzzle.answer
  def guesses_remaining(game), do: Puzzle.guesses_remaining(game.puzzle)
  def summary(game), do: Puzzle.summary(game.puzzle)

  def guesses(game), do: Puzzle.normalized_guesses(game.puzzle)

  def make_guess(game, guess) do
    guess = String.downcase(guess)

    with  {:ok, _puzzle} <- Puzzle.verify_guess(game.puzzle, guess),
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

end
