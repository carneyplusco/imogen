defmodule Mix.Tasks.Images.Sync do
  use Mix.Task

  def run([destination, bucket, _dryrun]) do
    IO.puts "Syncing with S3... (dry run)"
    sync(destination, bucket, true)
  end

  def run([destination, bucket]) do
    IO.puts "Syncing with S3..."
    sync(destination, bucket, false)
  end

  defp sync(destination, bucket, dryrun) do
    opts = ["s3", "sync", destination, "s3://#{bucket}", "--exclude=\"*\"", "--include=\"*.jpg\"", "--delete", "--acl=public-read"]
    sync = case dryrun do
      true -> opts ++ ["--dryrun"]
      _ -> opts
    end
    System.cmd("aws", sync, into: IO.stream(:stdio, :line))
  end
end
