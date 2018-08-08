defmodule Mix.Tasks.Images.Update do
  use Mix.Task

  def run([json_file, destination]) do
    IO.puts "Processing images..."
    Imogen.download_from_json(json_file, destination)
  end
end
