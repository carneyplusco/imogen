defmodule Imogen do
  # import ExProf.Macro
  import Mogrify
  @moduledoc """
  Documentation for Imogen.
  """

  # NimbleCSV.define(MyParser, separator: ",", escape: "\"")

  # def parse_csv do
  #   Progress.start_link([:download_image, :resize_image])

  #   "./backup/files_output.csv"
  #   |> File.stream!
  #   |> MyParser.parse_stream
  #   |> Flow.from_enumerable(max_demand: 1, stages: 32)
  #   |> Flow.map(fn [_,_,_,_,_,_,_,_,_,_,_,_,url,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_,_] -> url end)
  #   |> Flow.partition()
  #   |> Flow.map(&download_image/1)
  #   |> Flow.map(&resize_image/1)
  #   |> Enum.to_list()
  # end

  # def download_image(img) do
  #   uri = URI.parse(img)
  #   filename = Path.basename(uri.path)
  #   %HTTPoison.Response{body: body} = HTTPoison.get!(img)
  #   File.write!("./images/art/#{filename}", body)
  #   # Progress.incr(:download_image)
  #   filename
  # end

  def process_images(img_dir) do
    File.ls!(img_dir)
    |> Enum.reject(fn(dir) -> dir =~ ~r/\./ end)
    |> Enum.take(5)
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.each(fn(dir) -> resize_images("#{img_dir}/#{dir}", File.ls!("#{img_dir}/#{dir}")) end)
    |> Enum.to_list
  end  

  def resize_images(dir, imgs) do
    img = imgs
    |> Enum.filter(fn(img) -> img =~ ~r/\.jpg/ end)
    |> Enum.sort(fn(a, b) -> File.stat!("#{dir}/#{a}").size >= File.stat!("#{dir}/#{b}").size end)
    |> List.first

    sizes = [210, 420, 840, 1680]
    Enum.each(sizes, fn(size) ->
      File.mkdir("#{dir}/sizes")
      open("#{dir}/#{img}") |> resize_to_limit("#{size}x#{size}") |> save(path: "#{dir}/sizes/#{Path.basename(img, ".jpg")}-#{size}.jpg")
    end)
    # Progress.incr(:resize_image)
  end

  def fetch_files(conn, obj_list) do
    obj_list
    |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Flow.reject(fn(obj) -> is_nil(obj["images"]) end)
    |> Flow.flat_map(fn(obj) -> obj["images"] end)
    |> Flow.partition()
    |> Flow.reject(fn(obj) -> obj["permitted"] end)
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
        # add_image_refs(result["thing"])
      _ -> IO.inspect(result)
    end

    SSHKit.SSH.close(conn)
  end

  def add_image_refs(obj_list, img_dir) do
    imgs = File.ls!(img_dir)
    |> Enum.reject(fn(dir) -> dir =~ ~r/\./ end)
    |> Enum.reduce(%{}, fn(dir, acc) -> Map.put(acc, dir, File.ls!("#{img_dir}/#{dir}")) end)

    obj_list
    # |> Flow.from_enumerable(max_demand: 1, stages: 32)
    |> Enum.reject(fn(obj) -> is_nil(obj["images"]) end)
    # |> Flow.partition()
    |> Enum.reduce([], fn(obj, acc) ->
      new_images = Enum.reduce(obj["images"], [], fn(img, acc) -> 
        irn = Integer.to_string(img["irn"])
        image_with_files = Map.put(img, "files", imgs[irn])
        acc ++ [image_with_files]
      end)

      new_obj = Map.put(obj, "images", new_images)
      acc ++ [new_obj]
    end)
    # |> Enum.to_list
  end

  # def augment_json(file) do
  #   {decode_status, result} = file |> File.read! |> Jason.decode

  #   case decode_status do
  #     :ok ->
  #       add_image_refs(result["thing"])
  #     _ -> IO.inspect(result)
  #   end
  # end
end
