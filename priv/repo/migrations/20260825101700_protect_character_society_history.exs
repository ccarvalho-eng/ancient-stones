defmodule AncientStones.Repo.Migrations.ProtectCharacterSocietyHistory do
  use Ecto.Migration

  def change do
    alter table(:household_memberships) do
      modify :character_id,
             references(:characters, type: :binary_id, on_delete: :restrict),
             from: references(:characters, type: :binary_id, on_delete: :delete_all)
    end

    alter table(:character_relationships) do
      modify :character_a_id,
             references(:characters, type: :binary_id, on_delete: :restrict),
             from: references(:characters, type: :binary_id, on_delete: :delete_all)

      modify :character_b_id,
             references(:characters, type: :binary_id, on_delete: :restrict),
             from: references(:characters, type: :binary_id, on_delete: :delete_all)
    end
  end
end
