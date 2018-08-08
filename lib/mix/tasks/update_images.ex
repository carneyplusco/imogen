defmodule Mix.Tasks.UpdateImages do
  use Mix.Task

  def run([json_file, destination]) do
    Imogen.download_from_json(json_file, destination)
  end
end
