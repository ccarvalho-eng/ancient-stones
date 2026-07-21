defmodule AncientStones.Repo.Migrations.AddGenderToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :gender, :string
    end

    create constraint(:characters, :characters_gender_valid,
             check: "gender in ('female', 'male')"
           )
  end
end
