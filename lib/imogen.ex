defmodule Imogen do
  # import ExProf.Macro
  import Mogrify
  @moduledoc """
  Documentation for Imogen.
  """

  def download_from_json(file, destination \\ "") do
    {ssh_status, conn} = open_connection()
    download_with_connection(ssh_status, conn, file, destination)
  end

  defp download_with_connection(:error, _conn, _file, _destination), do: IO.puts("error connecting via SSH")
  defp download_with_connection(:ok, conn, file, destination) do
    {decode_status, result} = file |> File.read! |> Jason.decode
    case decode_status do
      :ok ->
        [key | _blank] = Map.keys(result)
        truncate_folders(result[key], "#{destination}/#{key}")
        fetch_files(conn, result[key], "#{destination}/#{key}")
        process_images("#{destination}/#{key}")
      _ -> IO.inspect(result)
    end

    close_connection(conn)
  end

  defp open_connection do
    Application.ensure_all_started(:sshkit)
    config = Application.get_all_env(:imogen)
    SSHKit.SSH.connect(config[:emu_host], user: config[:emu_username], password: config[:emu_password], timeout: 5000)
  end

  defp close_connection(conn) do
    SSHKit.SSH.close(conn)
  end

  defp fetch_files(conn, obj_list, destination) do
    obj_list
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.reject(fn(obj) -> is_nil(obj["images"]) end)
    |> Flow.flat_map(fn(obj) -> obj["images"] end)
    |> Flow.partition()
    |> Flow.filter(fn(obj) -> obj["permitted"] end)
    |> Flow.map(fn(obj) -> obj["irn"] end)
    |> Flow.partition()
    |> Flow.map(&compute_path/1)
    |> Flow.map(fn(path) -> download_files(conn, path, destination) end)
    |> Enum.to_list
  end

  defp compute_path(id) do
    id
    |> Integer.to_string
    |> String.pad_leading(4, "0")
    |> String.split_at(-3)
    |> Tuple.to_list
  end

  defp download_files(conn, path, destination) do
    emu_path = "../emu/cma/multimedia/#{Enum.join(path, "/")}"
    backup_path = "#{destination}/#{Enum.join(path,"")}"
    if !File.exists?(backup_path) do
      File.mkdir_p!(backup_path)
      SSHKit.SCP.download(conn, "#{emu_path}/*", backup_path, recursive: true)
    end
  end

  def clean(file, directory) do
    {decode_status, result} = file |> File.read! |> Jason.decode

    case decode_status do
      :ok ->
        truncate_folders(result["thing"], directory)
      _ -> IO.inspect(result)
    end 
  end

  defp truncate_folders(obj_list, directory) do
    allowed_folders = obj_list
    |> Enum.reject(fn(obj) -> is_nil(obj["images"]) end)
    |> Enum.flat_map(fn(obj) -> obj["images"] end)
    |> Enum.filter(fn(obj) -> obj["permitted"] end)
    |> Enum.map(fn(obj) -> obj["irn"] end)
    |> Enum.map(&Integer.to_string/1)

    dirs = File.ls!(directory)
    dirs -- allowed_folders
    |> Enum.map(fn(dir) -> "#{directory}/#{dir}" end)
    |> Enum.each(fn(dir) ->
      IO.puts "Removing: #{dir}"
      File.rm_rf!(dir)
    end)
  end

  def process_images(img_dir) do
    File.ls!(img_dir)
    |> Enum.reject(fn(dir) -> dir =~ ~r/\./ end)
    |> Flow.from_enumerable(max_demand: 2, stages: 16)
    |> Flow.each(fn(dir) -> resize_images("#{img_dir}/#{dir}", File.ls!("#{img_dir}/#{dir}")) end)
    |> Enum.to_list
  end

  defp resize_images(dir, []), do: IO.puts "No images in #{dir}"
  defp resize_images(dir, imgs) do
    if !File.exists?("#{dir}/sizes") do
      IO.puts "Creating: #{dir}"
      imgs
      |> Enum.filter(fn(img) -> img =~ ~r/\.jpg$/i end) # jpgs only
      |> Enum.reject(fn(img) -> img =~ ~r/\dx\d/i end) # no previously resized images
      |> Enum.reject(fn(img) -> img =~ ~r/thumb/i end) # no thumbnails
      |> Enum.map(fn(img) ->
        sizes = [210, 420, 840, 1680]
        Enum.each(sizes, fn(size) ->
          File.mkdir("#{dir}/sizes")
          open("#{dir}/#{img}") |> resize_to_limit("#{size}x#{size}") |> save(path: "#{dir}/sizes/#{Path.basename(img, ".jpg")}-#{size}.jpg")
        end)
      end)
    end
  end
end
