defmodule SubtleWeb.SubtleComponents do
  use Phoenix.Component
  use Phoenix.HTML

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
end
