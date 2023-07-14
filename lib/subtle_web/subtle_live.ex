defmodule SubtleWeb.SubtleLive do
  use SubtleWeb, :live_view
  use Phoenix.Component
  import SubtleWeb.SubtleComponents
  alias Subtle.Game
  alias SubtleWeb.SubtleComponents

  def mount(_params, session, socket) do
    {:ok, assign(socket,
                  page_title: "Subtle",
                  session_id: session["live_socket_id"],
                  game: Game.new(),
                  message: "Subtle",
                  guess: "",
                  settings: to_form(%{"verify" => true})
                )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket,
                      message: socket.assigns.game.message)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="app_header">
      <div class="flex justify-start gap-x-2">
        <.hero_modal_button modal_id="legend-modal" icon="hero-question-mark-circle" />
        <.hero_modal_button modal_id="help-modal" icon="hero-book-open" />
      </div>
      <h1>Subtle</h1>
      <div class="flex justify-end gap-x-2">
        <.hero_modal_button modal_id="quit-modal" icon="hero-face-frown" />
        <.hero_modal_button modal_id="settings-modal" icon="hero-cog-6-tooth" />
      </div>
    </div>

    <.subtle_modal id="legend-modal">
      <%= SubtleComponents.legend(assigns) %>
    </.subtle_modal>
    <.subtle_modal id="help-modal">
      <div class="possible_words">
        <h1>Possible words:</h1>
        <p><%= Game.available_answers(@game, 20) %></p>
      </div>
    </.subtle_modal>
    <.subtle_modal id="quit-modal">
      <form class="give_up" phx-submit="give_up">
        <h1>Game over, man!</h1>
        <p>I tried really, really hard but this isn't working out for me. I'd like to quit the gym.</p>
        <.button phx-click={hide_modal("quit-modal")}>
          I give up
          <.icon name="hero-face-frown-mini" class="ml-1 w-6 h-6" />
        </.button>
      </form>
    </.subtle_modal>
    <.modal id="settings-modal">
      <.form for={@settings} phx-submit="settings">
        <.input type="checkbox" id="settings-verify"
            field={@settings[:verify]}
            label="Require guess to be in the dictionary"
            checked={@game.verify_guesses} />
        <p>&nbsp;</p>
        <.button phx-click={hide_modal("settings-modal")}>
          Save
        </.button>
      </.form>
    </.modal>


    <div class="grid grid-flow-row gap-y-4">

      <div class="gamebox" phx-window-keyup="letterpress">
        <div class="message">
          <p><%= @message %></p>
        </div>
        <div class="actions">
          <button class={if Game.is_playing?(@game), do: "hidden"}
            phx-click="new_game">
            New Game
            <.icon name="hero-arrow-right-circle-mini" class="ml-1 w-6 h-6" />
          </button>
        </div>
        <SubtleComponents.guesses game={@game} guess={@guess} />
        <SubtleComponents.letters_used letters={Game.letters_used(@game)} />
      </div>

    </div>
    """
  end

  attr :message, :string, default: ""
  attr :guess, :string, default: ""
  attr :verify, :boolean, default: true
  attr :errors, :list, default: []

  def guess_form(assigns) do
    ~H"""
    <form id="guess_form" phx-submit="guess">
      <div class="p-4 space-y-4">
        <label class="block text-xl font-medium text-zinc-200">
          <%= @message %>
        </label>
        <div class="flex items-center justify-between space-x-4">
        <.input type="text" id="guess" name="guess"
          autofocus autocomplete="off"
          value={Phoenix.HTML.Form.normalize_value("text", @guess)}
          class= "font-bold text-xl text-zinc-800"
        />
          <.button class="whitespace-nowrap">
            Guess
            <.icon name="hero-question-mark-circle-mini" class="ml-1 w-6 h-6" />
          </.button>
        </div>
      </div>
    </form>
    """
  end

  attr :message, :string, required: true
  attr :answer, :string, required: true
# The word was \u201C" <> String.upcase(@answer) <> "\u201D."
  def game_over(assigns) do
    ~H"""
    <div class="flex items-center space-x-10">
      <p class="text-2xl text-zinc-200">
        <%= @message %>
      </p>
      <.button phx-click="new_game">New Game</.button>
    </div>
    """
  end

#  attr :message, :string, required: true
#  attr :answer, :string, default: nil
#  attr :post, :string, default: nil
#
#  def pretty_message(assigns) do
#    ~H"""
#      <%= @message %>
#      <%= if @answer do %>
#        <span class="font-medium"><%= @answer %></span>
#      <% end %>
#      <%= if @post do %>
#        <%= @post %>
#      <% end %>
#    """
#  end
#  defp pretty_args(msg) do
#    with [message, answer, post] <- String.split(msg, "\"") do
#      %{message: message, emphasize: answer, post: post}
#    else
#      _ -> %{message: msg}
#    end
#  end
#    with 3 <- Enum.count(l) do
#      Enum.at(l, 0) <> "<span class=\"font-bold\">" <> "\u201C" <>
#        Enum.at(l, 1) <> "\u201D" <> "</span>" <> Enum.at(l, 2)
#    else
#      _ -> msg
#    end


  def handle_event("guess", _params, socket) do
    guess =
      socket.assigns.guess
      |> String.trim
      |> String.downcase

    with {:ok, game} <- Game.make_guess(socket.assigns.game, guess) do
      {:noreply,
        assign(socket,
          guess: "",
          message: game.message,
          game: game)}
    else
      # opportunity to set some error assigns
      {:error, game} ->
        {:noreply,
          assign(socket,
            guess: "",
            message: game.message,
            game: game)}
    end
  end

  def handle_event("letterpress", %{"key" => "Enter"} = params, socket) do
    handle_event("guess", params, socket)
  end

  def handle_event("backspace", _params, socket) do
    {:noreply, assign(socket,
      guess: String.slice(socket.assigns.guess, 0..-2)
    )}
  end

  def handle_event("letterpress", %{"key" => "Backspace"} = _params, socket) do
    {:noreply, assign(socket,
      guess: String.slice(socket.assigns.guess, 0..-2)
    )}
  end

  def handle_event("letterpress", %{"key" => letter} = _params, socket) do
    guess =
      Map.get(socket.assigns, :guess, "") <> letter
      |> String.slice(0..4)
    {:noreply, assign(socket, guess: guess)}
  end

  def handle_event("settings", %{"verify" => verify} = _params, socket) do
    game = Game.set_verify(socket.assigns.game, to_boolean(verify))
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("new_game", _params, socket) do
    game = Game.new()
    {:noreply,
      assign(socket,
        guess: "",
        message: game.message,
        game: game)}
  end

  def handle_event("give_up", _params, socket) do
    game = Game.game_over_man(socket.assigns.game)
    {:noreply,
      assign(socket,
        guess: "",
        message: game.message,
        game: game)}
  end

  # I'm not sure why these aren't in the Kernel, or if I'm missing something
  defp to_boolean("true"), do: true
  defp to_boolean(_), do: false

end
