defmodule AncientStones.Maps.ReferenceImageTest do
  use ExUnit.Case, async: true

  alias AncientStones.Maps.ReferenceImage

  @png Base.decode64!(
         "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
       )

  test "stores verified images under a generated public path" do
    source = temporary_file("reference.png", @png)

    assert {:ok, url} = ReferenceImage.store(source)
    assert url =~ ~r{\A/uploads/map-references/[0-9a-f-]+\.png\z}

    stored = Application.app_dir(:ancient_stones, "priv/static#{url}")
    assert File.read!(stored) == @png

    on_exit(fn -> File.rm(stored) end)
  end

  test "rejects files whose contents are not a supported image" do
    source = temporary_file("reference.png", "not an image")

    assert {:error, :invalid_image} = ReferenceImage.store(source)
  end

  defp temporary_file(name, contents) do
    path = Path.join(System.tmp_dir!(), "#{Ecto.UUID.generate()}-#{name}")
    File.write!(path, contents)
    on_exit(fn -> File.rm(path) end)
    path
  end
end
