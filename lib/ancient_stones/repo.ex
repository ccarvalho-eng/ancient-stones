defmodule AncientStones.Repo do
  use Ecto.Repo,
    otp_app: :ancient_stones,
    adapter: Ecto.Adapters.Postgres
end
