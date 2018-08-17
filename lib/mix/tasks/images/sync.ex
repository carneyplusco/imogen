defmodule Mix.Tasks.Images.Sync do
  use Mix.Task

  def run([destination, bucket, profile, _dryrun]) do
    IO.puts "Syncing with S3... (dry run)"
    sync(destination, bucket, profile, true)
  end

  def run([destination, bucket, profile]) do
    IO.puts "Syncing with S3..."
    sync(destination, bucket, profile, false)
  end

  defp sync(destination, bucket, profile, dryrun) do
    opts = [
      "s3",
      "sync",
      destination,
      "s3://#{bucket}",
      "--exclude=\"*[1234567890]x[1234567890]*\"",
      "--exclude=\"*DS_Store\"",
      "--exclude=\"*thumb.jpg\"",
      "--delete",
      "--acl=public-read",
      "--profile",
      profile
    ]
    sync = case dryrun do
      true -> opts ++ ["--dryrun"]
      _ -> opts
    end
    System.cmd("aws", sync, into: IO.stream(:stdio, :line))
  end
end
