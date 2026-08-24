defmodule AncientStones.Repo.Migrations.CreateGuildMemberships do
  use Ecto.Migration

  def change do
    create table(:guild_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :guild_id, references(:guilds, type: :binary_id, on_delete: :delete_all), null: false

      add :character_id, references(:characters, type: :binary_id, on_delete: :delete_all),
        null: false

      add :role, :string, null: false, default: "member"
      add :rank, :string
      add :status, :string, null: false, default: "active"
      add :is_primary, :boolean, null: false, default: false
      add :description, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:guild_memberships, [:guild_id, :character_id])
    create index(:guild_memberships, [:character_id])

    create unique_index(:guild_memberships, [:character_id],
             where: "is_primary",
             name: :guild_memberships_one_primary_per_character_index
           )

    create constraint(:guild_memberships, :guild_memberships_role_check,
             check:
               "role IN ('leader', 'officer', 'member', 'initiate', 'affiliate', 'informant')"
           )

    create constraint(:guild_memberships, :guild_memberships_status_check,
             check: "status IN ('active', 'inactive', 'former', 'expelled', 'missing', 'secret')"
           )

    create constraint(:guild_memberships, :guild_memberships_primary_active_check,
             check: "NOT is_primary OR status = 'active'"
           )
  end
end
