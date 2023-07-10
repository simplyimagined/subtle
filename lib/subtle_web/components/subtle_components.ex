defmodule SubtleWeb.SubtleComponents do
  use Phoenix.Component
  use Phoenix.HTML

  alias Phoenix.LiveView.JS
  alias SubtleWeb.CoreComponents
  import SubtleWeb.Gettext

  attr :letter, :string, required: true
  attr :hint, :atom, values: [:correct, :wrong_letter, :wrong_position, :used, :unused, :none], default: :none
  attr :kind, :atom, values: [:guess, :key], required: true

  def letter_box(assigns) do
  #  IO.inspect(assigns)
    ~H"""
    <div class={class_for_kind(@kind)}>
      <p class={class_for_hint(@hint)}>
        <%= String.replace_prefix(@letter, " ", "&nbsp;") |> raw() %>
      </p>
    </div>
    """
  end

  defp class_for_kind(box_type) do
    case box_type do
      :guess -> "guessbox"
      :key -> "keybox"
    end
  end

  defp class_for_hint(hint_type) do
    case hint_type do
      :correct -> "correct"
      :wrong_letter -> "wrong_letter"
      :wrong_position -> "wrong_position"
      :used -> "used"
      :unused -> "unused"
      :none -> "none"
    end
  end

  attr :letters, :map, required: true

  def show_letters_used(assigns) do
    ~H"""
    <div class="flex rounded-lg p-2 bg-slate-700/20 grid grid-flow-row auto-rows-min gap-y-2">
      <.letter_row keys={~w[q w e r t y u i o p]} letters={@letters} />
      <.letter_row keys={~w[a s d f g h j k l]} leading={2} letters={@letters} />
      <.letter_row keys={~w[z x c v b n m]} leading={4} letters={@letters} />
    </div>
    """
  end

  attr :keys, :list, required: true
  attr :letters, :map, required: true
  attr :leading, :integer, default: 0

  def letter_row(assigns) do
    ~H"""
    <div class="grid grid-flow-col justify-start gap-x-1 md:gap-x-2">
      <%= for key <- @keys do %>
        <.letter_box kind={:key} letter={key} hint={hint_for_key(@letters, key)} />
      <% end %>
    </div>
    """
#    <div class={"grid grid-flow-col justify-start gap-x-2 ms-" <> to_string(@leading)}>
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
