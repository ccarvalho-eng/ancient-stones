defmodule AncientStones.Worlds.World do
  use Ecto.Schema
  import Ecto.Changeset

  alias AncientStones.Maps.MapDocument
  alias AncientStones.Worlds.Assembly
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.CharacterRole
  alias AncientStones.Worlds.Civilization
  alias AncientStones.Worlds.CommercialVenture
  alias AncientStones.Worlds.Continent
  alias AncientStones.Worlds.Creature
  alias AncientStones.Worlds.CreatureType
  alias AncientStones.Worlds.Document
  alias AncientStones.Galaxies.Galaxy
  alias AncientStones.Worlds.God
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.Household
  alias AncientStones.Worlds.Item
  alias AncientStones.Worlds.Effect
  alias AncientStones.Worlds.LocationType
  alias AncientStones.Worlds.Moon
  alias AncientStones.Worlds.Occupation
  alias AncientStones.Worlds.PoliticalOffice
  alias AncientStones.Worlds.Race
  alias AncientStones.Worlds.LoreConnection
  alias AncientStones.Worlds.CharacterRelationship
  alias AncientStones.Worlds.Skill
  alias AncientStones.Worlds.SkillTree
  alias AncientStones.Worlds.Spell
  alias AncientStones.Worlds.Timeline
  alias AncientStones.Worlds.TaxPolicy
  alias AncientStones.Worlds.WaterBody

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "worlds" do
    field :name, :string
    field :description, :string
    field :primary_star_name, :string
    field :orbital_period_days, :integer
    field :axial_tilt_degrees, :decimal
    field :day_length_hours, :decimal
    field :mean_radius_km, :integer
    field :mass_earths, :decimal
    field :surface_gravity_m_s2, :decimal
    field :orbital_distance_au, :decimal
    field :orbital_eccentricity, :decimal
    field :atmospheric_pressure_atm, :decimal
    field :bond_albedo, :decimal
    field :ocean_fraction, :decimal
    field :star_mass_solar, :decimal
    field :star_luminosity_solar, :decimal
    field :star_temperature_k, :integer
    field :map_projection, :string

    belongs_to(:galaxy, Galaxy)

    has_many(:characters, Character)
    has_many(:assemblies, Assembly)
    has_many(:character_roles, CharacterRole)
    has_many(:civilizations, Civilization)
    has_many(:commercial_ventures, CommercialVenture)
    has_many(:continents, Continent)
    has_many(:creature_types, CreatureType)
    has_many(:creatures, Creature)
    has_many(:documents, Document)
    has_many(:gods, God)
    has_many(:guilds, Guild)
    has_many(:households, Household)

    has_many(:hold_economic_profiles,
      through: [:continents, :provinces, :holds, :economic_profile]
    )

    has_many(:commodity_balances,
      through: [:continents, :provinces, :holds, :commodity_balances]
    )

    has_many(:tax_policies, TaxPolicy)
    has_many(:tax_assessments, through: [:tax_policies, :tax_assessments])
    has_many(:water_bodies, WaterBody)
    has_many(:character_relationships, CharacterRelationship)
    has_many(:items, Item)
    has_many(:effects, Effect)
    has_many(:location_types, LocationType)
    has_many(:moons, Moon, on_replace: :delete)
    has_many(:occupations, Occupation)
    has_many(:political_offices, PoliticalOffice)
    has_many(:races, Race)
    has_many(:lore_connections, LoreConnection)
    has_many(:skills, Skill)
    has_many(:skill_trees, SkillTree)
    has_many(:spells, Spell)
    has_many(:timelines, Timeline)
    has_many(:timeline_events, through: [:timelines, :events])
    has_many(:map_documents, MapDocument)

    timestamps(type: :utc_datetime)
  end

  def changeset(world, attrs) do
    world
    |> cast(attrs, [
      :name,
      :description,
      :primary_star_name,
      :orbital_period_days,
      :axial_tilt_degrees,
      :day_length_hours,
      :mean_radius_km,
      :mass_earths,
      :surface_gravity_m_s2,
      :orbital_distance_au,
      :orbital_eccentricity,
      :atmospheric_pressure_atm,
      :bond_albedo,
      :ocean_fraction,
      :star_mass_solar,
      :star_luminosity_solar,
      :star_temperature_k,
      :map_projection
    ])
    |> validate_required([:name])
    |> validate_number(:orbital_period_days, greater_than: 0)
    |> validate_number(:axial_tilt_degrees,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 90
    )
    |> validate_number(:day_length_hours, greater_than: 0)
    |> validate_number(:mean_radius_km, greater_than: 0)
    |> validate_number(:mass_earths,
      greater_than_or_equal_to: Decimal.new("0.00001"),
      less_than: Decimal.new("100000")
    )
    |> validate_number(:surface_gravity_m_s2, greater_than: 0)
    |> validate_number(:orbital_distance_au, greater_than: 0)
    |> validate_number(:orbital_eccentricity, greater_than_or_equal_to: 0, less_than: 1)
    |> validate_number(:atmospheric_pressure_atm, greater_than: 0)
    |> validate_number(:bond_albedo, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:ocean_fraction, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:star_mass_solar, greater_than: 0)
    |> validate_number(:star_luminosity_solar, greater_than: 0)
    |> validate_number(:star_temperature_k, greater_than: 0)
    |> check_constraint(:day_length_hours, name: :worlds_day_length_hours_positive)
    |> check_constraint(:mean_radius_km, name: :worlds_mean_radius_km_positive)
    |> check_constraint(:mass_earths, name: :worlds_physical_values_positive)
    |> check_constraint(:orbital_eccentricity, name: :worlds_orbital_eccentricity_range)
    |> check_constraint(:bond_albedo, name: :worlds_physical_fractions_range)
    |> foreign_key_constraint(:galaxy_id)
  end

  def creation_changeset(world, attrs) do
    moons_changeset(world, attrs)
  end

  def update_with_moons_changeset(world, attrs) do
    moons_changeset(world, attrs)
  end

  defp moons_changeset(world, attrs) do
    changeset = changeset(world, attrs)
    planet_radius = get_field(changeset, :mean_radius_km)

    changeset
    |> validate_moon_ids(world, attrs)
    |> cast_assoc(:moons,
      with: fn moon, moon_attrs ->
        moon
        |> Moon.nested_changeset(moon_attrs)
        |> validate_moon_clearance(planet_radius)
      end,
      sort_param: :moons_sort,
      drop_param: :moons_drop
    )
  end

  defp validate_moon_ids(changeset, world, attrs) do
    known_ids = MapSet.new(Enum.map(loaded_moons(world.moons), & &1.id))

    unknown_id? =
      attrs
      |> moon_attrs()
      |> Enum.any?(fn moon_attrs ->
        case moon_attr_value(moon_attrs, :id) do
          id when id in [nil, ""] -> false
          id -> not MapSet.member?(known_ids, id)
        end
      end)

    if unknown_id? do
      add_error(changeset, :moons, "contains a moon that does not belong to this world")
    else
      changeset
    end
  end

  defp loaded_moons(%Ecto.Association.NotLoaded{}) do
    []
  end

  defp loaded_moons(moons) when is_list(moons) do
    moons
  end

  defp moon_attrs(attrs) do
    case moon_attr_value(attrs, :moons) do
      moons when is_map(moons) -> Map.values(moons)
      moons when is_list(moons) -> moons
      _other -> []
    end
  end

  defp moon_attr_value(attrs, key) when is_map(attrs) do
    Map.get(attrs, key) || Map.get(attrs, Atom.to_string(key))
  end

  defp validate_moon_clearance(moon_changeset, planet_radius)
       when is_integer(planet_radius) and planet_radius > 0 do
    semi_major_axis = get_field(moon_changeset, :semi_major_axis_km)
    moon_radius = get_field(moon_changeset, :mean_radius_km) || 0
    eccentricity = get_field(moon_changeset, :orbital_eccentricity) || Decimal.new(0)

    with axis when is_integer(axis) and axis > 0 <- semi_major_axis,
         radius when is_integer(radius) and radius >= 0 <- moon_radius do
      periapsis = axis * (1.0 - Decimal.to_float(eccentricity))

      if periapsis > planet_radius + radius do
        moon_changeset
      else
        add_error(
          moon_changeset,
          :semi_major_axis_km,
          "must keep the moon above the planet at periapsis"
        )
      end
    else
      _other -> moon_changeset
    end
  end

  defp validate_moon_clearance(moon_changeset, _planet_radius) do
    moon_changeset
  end
end
