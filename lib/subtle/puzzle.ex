defmodule Subtle.Puzzle do

  def get_random_puzzle_word() do
    puzzle_words()
    |> Enum.random()
#
#    words = fetch_words()
#    count = Enum.count(words)
#    Enum.random(words)
  end

  def puzzle_words() do
    :code.priv_dir(:subtle)
    |> Path.join("/puzzle_files/puzzle_words.txt")
    |> File.read!()
    |> String.split("\n")
  end

  def fetch_words() do
#    words_path = Path.join(:code.priv_dir(:subtle), "puzzle_files/puzzle_words.txt")
    words_path = Application.app_dir(:my_app, "/priv/puzzle_files/puzzle_words.txt")
#    words_path = "priv/puzzle_words/puzzle_words.txt"
#    IO.inspect(words_path)
    blob = File.read!(words_path)
    String.split(blob, "\n")
  end

end
