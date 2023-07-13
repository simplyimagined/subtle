defmodule SubtleWeb.SubtleComponents do
  use Phoenix.Component
  use Phoenix.HTML

  alias Phoenix.LiveView.JS

  alias SubtleWeb.CoreComponents
  import SubtleWeb.Gettext
  alias Subtle.Game

  attr :game, :map, required: true

  def guesses(assigns) do
    ~H"""
    <div class="guesses">
      <%= for result <- Game.live_guess_results(@game) do %>
        <.guess_row guess={result} />
      <% end %>
      <p class="text-zinc-200 ml-3"> <%= Game.guesses_remaining(@game) %> guesses remaining </p>
    </div>
    """
  end

  attr :guess, :list, required: true

  def guess_row(assigns) do
    ~H"""
    <div class="guessrow">
      <%= for %{letter: letter, hint: hint} <- @guess do %>
        <.guess_box letter={letter} hint={hint} />
      <% end %>
    </div>
    """
  end

  attr :letter, :string, required: true
  attr :hint, :atom, values: [:correct, :wrong_letter, :wrong_position, :none], default: :none

  def guess_box(assigns) do
    IO.inspect(assigns, label: "guess_box")
    ~H"""
    <div class="guessbox">
      <p class={box_class(@hint)}><%= @letter %></p>
    </div>
    """
  end

  defp box_class(hint_type) do
    case hint_type do
      :correct -> "correct"
      :wrong_letter -> "wrong_l"
      :wrong_position -> "wrong_p"
      :used -> "used"
      :unused -> "unused"
      :none -> "none"
    end
  end

  def letters_used(assigns) do
    ~H"""
    <div class="keys_used">
      <.key_row keys={~w[q w e r t y u i o p]} letters={@letters} />
      <.key_row keys={~w[a s d f g h j k l]} letters={@letters} />
      <div class="bottom_row">
        <CoreComponents.button class="whitespace-nowrap">
          Guess
        </CoreComponents.button>
        <.key_row keys={~w[z x c v b n m]} letters={@letters} />
        <CoreComponents.button>
          <CoreComponents.icon name="hero-backspace" />
        </CoreComponents.button>
      </div>
    </div>
    """
  end

  attr :keys, :list, required: true
  attr :letters, :list, required: true

  def key_row(assigns) do
    ~H"""
    <div class="keysrow">
      <%= for key <- @keys do %>
        <.key_box letter={key} hint={hint_for_key(@letters, key)} />
      <% end %>
    </div>
    """
  end

  defp hint_for_key(letters, key) do
    hints = Map.get(letters, key, [:unused])
    cond do
      :wrong_position in hints -> :used  # :wrong_position
      :correct in hints -> :used  # :correct
      :wrong_letter in hints -> :wrong_letter
      true -> :unused
    end
  end

  attr :letter, :string, required: true
  attr :hint, :atom, values: [:used, :unused, :none], default: :none

  def key_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <div class="keybox" phx-click="letterpress" phx-value-key={@letter}>
      <p class={box_class(@hint)}>
        <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
      </p>
    </div>
    """
  end

  attr :letters, :map, required: true   # map of letters and their hint type

  def legend(assigns) do
    ~H"""
    <div class="legend">
      <h1>Legend:</h1>
      <div class="legend_groups">
        <div class="legend_group">
          <h2>Guesses</h2>
          <.legend_key letter="!" hint={:correct} description="Correct letter" />
          <.legend_key letter="?" hint={:wrong_position} description="Good letter, wrong location" />
          <.legend_key letter="x" hint={:wrong_letter} description="Letter not in answer" />
        </div>
        <div class="legend_group">
          <h2>Letters used</h2>
          <.legend_key letter="x" hint={:used} description="Somewhere in puzzle" />
          <.legend_key letter="x" hint={:wrong_letter} description="Letter not in answer" />
          <.legend_key letter="x" hint={:unused} description="Not guessed yet" />
        </div>
      </div>
    </div>
    """
  end

  def legend_key(assigns) do
    ~H"""
    <div class="legend_key">
      <.legend_box letter={@letter} hint={@hint}/>
      <p class="desc"> <%= @description %> </p>
    </div>
    """
  end

  attr :letter, :string, required: true
  attr :hint, :atom, values: [:correct, :wrong_letter, :wrong_position, :used, :unused, :none], default: :none

  def legend_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <div class="keybox">
      <p class={box_class(@hint)}>
        <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
      </p>
    </div>
    """
  end

#  attr :keys, :list, required: true
#  attr :letters, :map, required: true
#  attr :leading, :integer, default: 0
#
#  def letter_row(assigns) do
#    ~H"""
#    <div class={[
#      "grid grid-flow-col",
#       "ml-" <> to_string(@leading),
#       "justify-start gap-x-1 md:gap-x-2"
#    ]}>
#      <%= for key <- @keys do %>
#        <.letter_box kind={:key} letter={key} hint={hint_for_key(@letters, key)} />
#      <% end %>
#    </div>
#    """
#    <div class={"grid grid-flow-col justify-start gap-x-2 ms-" <> to_string(@leading)}>
#  end


  attr :modal_id, :string, required: true
  attr :icon, :string, required: true

  def hero_modal_button(assigns) do
    ~H"""
      <button phx-click={CoreComponents.show_modal(@modal_id)}>
        <CoreComponents.icon name={@icon} class="icon" />
      </button>
    """
  end


  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def subtle_modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && CoreComponents.show_modal(@id)}
      phx-remove={CoreComponents.hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-zinc-400/50 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-slate-700 p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-60 hover:opacity-90"
                  aria-label={gettext("close")}
                >
                  <CoreComponents.icon name="hero-x-mark-solid" class="h-5 w-5 bg-zinc-200" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

end
