defmodule Imogen do
  # import ExProf.Macro
  import Mogrify
  @moduledoc """
  Documentation for Imogen.
  """

  NimbleCSV.define(MyParser, separator: ",", escape: "\"")

  def parse_csv do
    Progress.start_link([:download_image, :resize_image])

    "./backup/files_output.csv"
    |> File.stream!
    |> MyParser.parse_stream
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.map(fn [_,_,_,_,_,_,_,_,_,_,_,_,url,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_] -> url end)
    |> Flow.partition()
    |> Flow.map(&download_image/1)
    |> Flow.map(&resize_image/1)
    |> Enum.to_list()
  end

  def download_image(img) do
    uri = URI.parse(img)
    filename = Path.basename(uri.path)
    %HTTPoison.Response{body: body} = HTTPoison.get!(img)
    File.write!("./images/art/#{filename}", body)
    Progress.incr(:download_image)
    filename
  end

  def resize_image(img) do
    mog = open("./images/art/#{img}") |> resize("100x100") |> save(path: "./images/resized/#{img}")
    Progress.incr(:resize_image)
    mog
  end

  def fetch_files(conn, obj_list) do
    obj_list
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.reject(fn(obj) -> is_nil(obj["images"]) end)
    |> Flow.flat_map(fn(obj) -> obj["images"] end)
    |> Flow.partition()
    |> Flow.reject(fn(obj) -> obj["permitted"] != "Yes" end)
    |> Flow.map(fn(obj) -> obj["irn"] end)
    |> Flow.partition()
    |> Flow.map(&compute_path/1)
    |> Flow.map(fn(path) -> download_files(conn, path) end)
    |> Enum.to_list
  end

  def compute_path(id) do
    id
    |> Integer.to_string
    |> String.pad_leading(4, "0")
    |> String.split_at(-3)
    |> Tuple.to_list
  end

  def download_files(conn, path) do
    emu_path = "../emu/cma/multimedia/#{Enum.join(path, "/")}"
    backup_path = "/Volumes/Files/collections/images/#{Enum.join(path,"")}"
    if !File.exists?(backup_path) do
      File.mkdir_p!(backup_path)
      SSHKit.SCP.download(conn, "#{emu_path}/*", backup_path, recursive: true)
    end
  end

  def download_from_json(file) do
    config = Application.get_all_env(:imogen)
    {_ssh_status, conn} = SSHKit.SSH.connect(config[:emu_host], user: config[:emu_username], password: config[:emu_password])

    {decode_status, result} = file |> File.read! |> Jason.decode

    case decode_status do
      :ok ->
        fetch_files(conn, result["thing"])
      _ -> IO.inspect(result)
    end

    SSHKit.SSH.close(conn)
  end

  def add_image_refs(obj_list) do
    obj_list
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.reject(fn(obj) -> is_nil(obj["images"]) end)
    # |> Flow.each(fn(obj) -> )
    |> Flow.reduce(fn -> [] end, fn(obj, list) ->
      backup_path = "/Volumes/Files/collections/images/#{Enum.join(path,"")}"
      # File.ls
    end)
  end

  def augment_json(file) do
    {decode_status, result} = file |> File.read! |> Jason.decode

    case decode_status do
      :ok ->
        add_image_refs(result["thing"])
      _ -> IO.inspect(result)
    end
  end
end
