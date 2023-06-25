defmodule Subtle.PuzzleDictionaryTest do
  use ExUnit.Case, async: true

  alias Subtle.PuzzleDictionary

  setup do
    case Process.alive?(Subtle.PuzzleDictionary) do
      true ->
        dict_pid = Process.whereis(Subtle.PuzzleDictionary)
        %{puzzle_dict_pid: dict_pid}
      false ->
        {:ok, dict_pid} = PuzzleDictionary.start_link([])
        %{puzzle_dict_pid: dict_pid}
    end
  end

  describe "Test the PuzzleDictionary" do
    test "make sure we have a dict" do
      assert Enum.count(PuzzleDictionary.dictionary()) > 0
    end
  end
end
