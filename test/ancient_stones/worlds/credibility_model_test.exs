defmodule AncientStones.Worlds.CredibilityModelTest do
  use ExUnit.Case, async: true

  alias AncientStones.Worlds.Calendar
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.PoliticalOffice

  test "calendar records a structured intercalation rule" do
    changeset =
      Calendar.changeset(%Calendar{continent_id: Ecto.UUID.generate()}, %{
        name: "Tyrven Reckoning",
        intercalation_interval_years: 7,
        intercalary_days: 7,
        intercalation_rule: "Seven feast days follow Deepwinter every seventh year."
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :intercalation_interval_years) == 7
    assert Ecto.Changeset.get_field(changeset, :intercalary_days) == 7
  end

  test "calendar requires both parts of an intercalation cycle" do
    changeset =
      Calendar.changeset(%Calendar{continent_id: Ecto.UUID.generate()}, %{
        name: "Broken Reckoning",
        intercalation_interval_years: 7
      })

    refute changeset.valid?

    assert "is required when an intercalation interval is set" in errors_on(changeset).intercalary_days
  end

  test "calendar does not accept intercalary days without an interval" do
    changeset =
      Calendar.changeset(%Calendar{continent_id: Ecto.UUID.generate()}, %{
        name: "Broken Reckoning",
        intercalary_days: 7
      })

    refute changeset.valid?

    assert "is required when intercalary days are set" in errors_on(changeset).intercalation_interval_years
  end

  test "household records residents and dependents without fabricating named characters" do
    changeset =
      Household.changeset(%Household{world_id: Ecto.UUID.generate()}, %{
        name: "Arne's household",
        resident_count: 9,
        dependent_count: 4,
        servant_count: 2
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :resident_count) == 9
  end

  test "household composition cannot exceed its residents" do
    changeset =
      Household.changeset(%Household{world_id: Ecto.UUID.generate()}, %{
        name: "Impossible household",
        resident_count: 3,
        dependent_count: 2,
        servant_count: 2
      })

    refute changeset.valid?

    assert "dependents and servants cannot exceed residents" in errors_on(changeset).resident_count
  end

  test "household composition requires a resident count" do
    changeset =
      Household.changeset(%Household{world_id: Ecto.UUID.generate()}, %{
        name: "Incomplete household",
        dependent_count: 2
      })

    refute changeset.valid?

    assert "is required when composition counts are set" in errors_on(changeset).resident_count
  end

  test "political office records selection, succession, and tenure" do
    changeset =
      PoliticalOffice.changeset(%PoliticalOffice{world_id: Ecto.UUID.generate()}, %{
        office: "Lawspeaker",
        scope: "continent",
        selection_method: "Chosen by the Great Thing",
        succession_rule: "A new choice is made at the first spring assembly after a vacancy.",
        term_started_year: 418,
        term_length_years: 3
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :term_length_years) == 3
  end

  test "creature records its ecological and economic place" do
    changeset =
      Creature.changeset(%Creature{world_id: Ecto.UUID.generate()}, %{
        name: "Northland sheep",
        population_status: "domestic",
        diet: "grass, sedges, hay, and leaf fodder",
        ecological_role: "grazing livestock",
        economic_uses: "wool, milk, meat, horn, and manure",
        seasonal_pattern: "upland grazing in summer and sheltered feeding in winter"
      })

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :population_status) == :domestic
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        options
        |> Keyword.get(String.to_existing_atom(key), key)
        |> to_string()
      end)
    end)
  end
end
