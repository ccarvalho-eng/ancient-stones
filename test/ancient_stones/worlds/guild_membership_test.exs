defmodule AncientStones.Worlds.GuildMembershipTest do
  use AncientStones.DataCase, async: true

  alias AncientStones.Worlds
  alias AncientStones.Worlds.Character
  alias AncientStones.Worlds.Guild
  alias AncientStones.Worlds.GuildMembership
  alias AncientStones.Worlds.World

  test "creates one primary membership and synchronizes the legacy guild reference" do
    world = world_fixture("Aldrun")
    guild = guild_fixture(world, "Wardens of the Cairn")
    character = character_fixture(world, "Agnar Agnarsson")

    assert {:ok, membership} =
             Worlds.create_guild_membership(world, %{
               "guild_id" => guild.id,
               "character_id" => character.id,
               "role" => "leader",
               "status" => "active"
             })

    assert membership.is_primary
    assert membership.role == :leader
    assert Repo.reload!(character).guild_id == guild.id
    assert Repo.reload!(guild).leader == character.name
  end

  test "rejects duplicate and cross-world memberships" do
    world = world_fixture("Aldrun")
    other_world = world_fixture("Veyra")
    guild = guild_fixture(world, "Wardens")
    character = character_fixture(world, "Runa")
    outsider = character_fixture(other_world, "Mara")

    attrs = %{"guild_id" => guild.id, "character_id" => character.id}

    assert {:ok, _membership} = Worlds.create_guild_membership(world, attrs)
    assert {:error, duplicate_changeset} = Worlds.create_guild_membership(world, attrs)
    assert "has already been taken" in errors_on(duplicate_changeset).guild_id

    assert {:error, cross_world_changeset} =
             Worlds.create_guild_membership(world, %{
               "guild_id" => guild.id,
               "character_id" => outsider.id
             })

    assert errors_on(cross_world_changeset).character_id != []
  end

  test "moving and deleting the primary membership preserves one primary guild" do
    world = world_fixture("Aldrun")
    first_guild = guild_fixture(world, "Wardens")
    second_guild = guild_fixture(world, "Wayfarers")
    character = character_fixture(world, "Yrsa")

    assert {:ok, first_membership} =
             Worlds.create_guild_membership(world, %{
               "guild_id" => first_guild.id,
               "character_id" => character.id
             })

    assert {:ok, second_membership} =
             Worlds.create_guild_membership(world, %{
               "guild_id" => second_guild.id,
               "character_id" => character.id,
               "is_primary" => "true"
             })

    refute Repo.reload!(first_membership).is_primary
    assert Repo.reload!(second_membership).is_primary
    assert Repo.reload!(character).guild_id == second_guild.id

    assert {:ok, _deleted_membership} = Worlds.delete_guild_membership(second_membership)
    assert Repo.reload!(first_membership).is_primary
    assert Repo.reload!(character).guild_id == first_guild.id
  end

  test "primary membership must remain active" do
    changeset =
      GuildMembership.changeset(%GuildMembership{}, %{
        "role" => "member",
        "status" => "former",
        "is_primary" => true
      })

    assert "requires an active membership" in errors_on(changeset).is_primary
  end

  test "a first secret affiliation remains concealed from the primary guild reference" do
    world = world_fixture("Aldrun")
    guild = guild_fixture(world, "Veiled Oar")
    character = character_fixture(world, "Yrsa")

    assert {:ok, membership} =
             Worlds.create_guild_membership(world, %{
               "guild_id" => guild.id,
               "character_id" => character.id,
               "role" => "informant",
               "status" => "secret"
             })

    refute membership.is_primary
    assert membership.status == :secret
    assert Repo.reload!(character).guild_id == nil
  end

  test "the legacy character guild field maintains the normalized primary membership" do
    world = world_fixture("Aldrun")
    first_guild = guild_fixture(world, "Wardens")
    second_guild = guild_fixture(world, "Wayfarers")
    character = character_fixture(world, "Yrsa")

    assert {:ok, updated_character} =
             Worlds.update_character(character, %{"name" => character.name}, %{
               guild: first_guild
             })

    assert updated_character.guild_id == first_guild.id

    assert [%GuildMembership{guild_id: first_guild_id, is_primary: true}] =
             Repo.all(
               from membership in GuildMembership,
                 where: membership.character_id == ^character.id
             )

    assert first_guild_id == first_guild.id

    assert {:ok, updated_character} =
             Worlds.update_character(updated_character, %{"name" => character.name}, %{
               guild: second_guild
             })

    assert updated_character.guild_id == second_guild.id

    memberships =
      Repo.all(
        from membership in GuildMembership,
          where: membership.character_id == ^character.id,
          order_by: membership.guild_id
      )

    assert length(memberships) == 2
    assert Enum.count(memberships, & &1.is_primary) == 1
    assert Enum.find(memberships, & &1.is_primary).guild_id == second_guild.id
  end

  defp world_fixture(name) do
    %World{name: name}
    |> Repo.insert!()
  end

  defp guild_fixture(world, name) do
    %Guild{world_id: world.id, name: name}
    |> Repo.insert!()
  end

  defp character_fixture(world, name) do
    %Character{world_id: world.id, name: name}
    |> Repo.insert!()
  end
end
