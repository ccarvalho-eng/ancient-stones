defmodule AncientStones.Maps.ReferenceImage do
  @moduledoc """
  Validates and stores local reference images used while tracing a map.

  File content, rather than the supplied extension, determines whether an image
  is an accepted PNG, JPEG, or WebP file. Stored images receive generated names
  under the application's static upload directory.
  """

  @max_file_size 10_000_000
  @upload_path "uploads/map-references"

  @type store_error :: :too_large | :invalid_file | :invalid_image | File.posix()

  @doc """
  Copies a validated local image into static reference-image storage.

  Returns the public path for a stored image or an error when the source is too
  large, is not a regular file, has unsupported content, or cannot be copied.
  """
  @spec store(Path.t()) :: {:ok, String.t()} | {:error, store_error()}
  def store(path) when is_binary(path) do
    with {:ok, %{type: :regular, size: size}} when size <= @max_file_size <- File.stat(path),
         {:ok, extension} <- image_extension(path),
         :ok <- File.mkdir_p(upload_directory()),
         filename = "#{Ecto.UUID.generate()}.#{extension}",
         :ok <- File.cp(path, Path.join(upload_directory(), filename)) do
      {:ok, "/#{@upload_path}/#{filename}"}
    else
      {:ok, %{size: size}} when size > @max_file_size -> {:error, :too_large}
      {:ok, _stat} -> {:error, :invalid_file}
      {:error, reason} -> {:error, reason}
    end
  end

  defp upload_directory do
    Application.app_dir(:ancient_stones, "priv/static/#{@upload_path}")
  end

  defp image_extension(path) do
    with {:ok, file} <- File.open(path, [:read, :binary]),
         header <- IO.binread(file, 12),
         :ok <- File.close(file) do
      extension_from_header(header)
    end
  end

  defp extension_from_header(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>>) do
    {:ok, "png"}
  end

  defp extension_from_header(<<0xFF, 0xD8, 0xFF, _rest::binary>>) do
    {:ok, "jpg"}
  end

  defp extension_from_header(<<"RIFF", _size::binary-size(4), "WEBP", _rest::binary>>) do
    {:ok, "webp"}
  end

  defp extension_from_header(_header) do
    {:error, :invalid_image}
  end
end
