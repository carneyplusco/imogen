defmodule Event do
  defstruct name: ""
end

defmodule Xml.Parser do
  import SweetXml

  def start do
    Path.wildcard("./files/*.xml") |> Enum.each(&parse_file/1)
  end

  def parse_file(file) do
    # File.stream!(file, [], 1048576)
    # |> xpath(~x"tuple"l)
    # |> Flow.from_enumerable(stages: 100)
    # |> Flow.map(fn(tuple) -> %Event{name: atom_title(tuple)} end)
    # |> Enum.to_list()

    File.read!(file)
    |> xpath(~x"tuple"l)
    # |> Stream.map(fn(tuple) -> %Event{name: atom_title(tuple)} end)
    # |> Enum.to_list()
    |> length
    |> IO.puts
  end

  def atom_title(el) do
    el |> xpath(~x"./atom[@name=\"EveEventTitle\"]/text()"s)
  end
end
