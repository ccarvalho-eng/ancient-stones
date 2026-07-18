defmodule AncientStone.Repo do
  use Ecto.Repo,
    otp_app: :ancient_stone,
    adapter: Ecto.Adapters.Postgres
end
