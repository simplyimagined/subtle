defmodule Subtle.Game do
  use GenServer

  alias Subtle.Game
  alias Subtle.Puzzle

  # Client

  def start_link(default) do
    GenServer.start_link(Game, default)
  end

  def make_guess(game, guess) do
    GenServer.call(game, {:make_guess, guess})
  end

  def get_puzzle(game) do
    GenServer.call(game, :get_puzzle)
  end

  def reset_puzzle(game, answer \\ "") do
    GenServer.call(game, {:reset_puzzle, answer})
  end

  # Server (callbacks)

  @impl true
  def init(_default) do
    {:ok, Puzzle.new()}
  end

  @impl true
  def handle_call({:reset_puzzle, answer}, _from, _state) do
    puzzle = Puzzle.new(answer)
    {:noreply, puzzle, puzzle}
  end

  def handle_call({:make_guess, guess}, _from, puzzle) do
    IO.inspect(guess)
    case Puzzle.make_guess(puzzle, guess) do
      {:ok, modified_puzzle} ->
        {:noreply, {:ok, modified_puzzle}, modified_puzzle}
      {:error, puzzle, reason} ->
        {:noreply, {:error, puzzle, reason}, puzzle}
    end
  end

  def handle_call(:get_puzzle, _from, puzzle) do
    {:reply, puzzle, puzzle}
  end
end
