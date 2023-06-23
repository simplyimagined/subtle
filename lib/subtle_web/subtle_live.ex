defmodule SubtleWeb.SubtleLive do
  use SubtleWeb, :live_view
  use Phoenix.Component
  alias Subtle.{Puzzle, Guess}

  def mount(_params, session, socket) do
    puzzle = Puzzle.new("paper")
    {:ok, puzzle} = Puzzle.make_guess(puzzle, "apple")
    {:ok, puzzle} = Puzzle.make_guess(puzzle, "poppy")
    {:ok, assign(socket,
                  session_id: session["live_socket_id"],
                  puzzle: puzzle,
                  message: "Make a guess:" )}
  end

  def render(assigns) do
    ~H"""
    <h2 class="text-lg text-zinc-200">
      <%= @message %>
    </h2>
    <%= render_guesses(assigns) %>
    <p class="text-zinc-200"> <%= Puzzle.summary @puzzle %> </p>
    """
  end

  attr :puzzle, :map, required: true
  def render_guesses(assigns) do
    IO.inspect(Puzzle.normalized_guesses(assigns.puzzle))
    ~H"""
    <div class="flex">
      <div class="grid grid-flow-row auto-rows-max gap-y-4">
        <%= for guess <- Puzzle.normalized_guesses(@puzzle) do %>
          <%= render_guess guess %>
        <% end %>
        <p> <%= Puzzle.guesses_remaining(@puzzle) %> guesses remaining </p>
      </div>
    </div>
    """
  end

  attr :results, :list, required: true

  def render_guess(assigns) do
    ~H"""
    <div class="grid grid-cols-5 gap-x-4">
      <%= for {letter, hint} = _result <- @results do %>
        <.letter_box letter={letter} hint={hint}/>
      <% end %>
    </div>
    """
  end


  attr :letter, :string, required: true
  attr :hint, :atom, default: :none

  def letter_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <p class={[
      "inline-flex justify-center items-baseline py-3 px-5",
      "text-3xl font-semibold text-zinc-200",
      if(@hint == :correct, do: "bg-green-600"),
      if(@hint == :wrong_letter, do: "bg-red-600"),
      if(@hint == :wrong_position, do: "bg-orange-500"),
      if(@hint == :none, do: "bg-sky-500"),
      "rounded-lg border-2 border-zinc-200"
      ]}
    >
      <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
    </p>
    """
end

def bozo_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <div class="group relative rounded-2xl px-6 py-4">
      <span class={[
          "absolute inset-0 rounded-2xl bg-zinc-50",
          "border-6 border-solid",
          if(@hint == :correct, do: "border-green-600"),
          if(@hint == :wrong_letter, do: "border-red-600"),
          if(@hint == :wrong_position, do: "border-orange-500"),
          if(@hint == :none, do: "border-sky-500")
        ]}
      >
      </span>
      <span class="relative flex items-center gap-4">
        <p class="text-3xl font-semibold text-zinc-850">
          <%= @letter %>
        </p>
      </span>
    </div>
    """
end

  def border_class(hint) do
    IO.inspect(hint)
    "<span class=\"" <>
    "absolute inset-0 rounded-2xl group-hover:bg-zinc-100 bg-zinc-50 " <>
    "border-6 " <>
    case hint do
      :correct -> "border-green-500"
      :wrong_position -> "border-orange-300"
      :wrong_letter -> "border-red-200"
      _ -> "border-sky-500"
    end
    <> "\"> </span>"
  end

end
