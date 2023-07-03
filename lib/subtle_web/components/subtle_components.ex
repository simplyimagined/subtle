defmodule SubtleWeb.SubtleComponents do
  use Phoenix.Component
  use Phoenix.HTML

  alias SubtleWeb.SubtleComponents
  alias Subtle.Game

  attr :letter, :string, required: true
  attr :hint, :atom, values: [:correct, :wrong_letter, :wrong_position, :unused, :none], default: :none
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
      :unused -> "unused"
      :none -> "none"
    end
  end

end
