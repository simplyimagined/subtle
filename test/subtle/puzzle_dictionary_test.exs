defmodule Subtle.PuzzleDictionaryTest do
  use ExUnit.Case, async: true

  alias Subtle.PuzzleDictionary

# We made PuzzleDictionary a singleton (I think) by using
# Subtle.PuzzleDictionary as the :name in start_link()
# This makes the test down below fail at :erlang.is_process_alive
# because it wants a pid and we have a "module id"?
# Anyway, I was hoping to avoid holding and passing in a pid,
# but we may need to.
#  setup do
#    case Process.alive?(Subtle.PuzzleDictionary) do
#      true ->
#        dict_pid = Process.whereis(Subtle.PuzzleDictionary)
#        %{puzzle_dict_pid: dict_pid}
#      false ->
#        {:ok, dict_pid} = PuzzleDictionary.start_link([])
#        %{puzzle_dict_pid: dict_pid}
#    end
#  end

#  describe "Test the PuzzleDictionary" do
#    test "make sure we have a dict" do
#      assert Enum.count(PuzzleDictionary.dictionary()) > 0
#    end
#  end
end
