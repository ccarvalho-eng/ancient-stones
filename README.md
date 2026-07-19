# Ancient Stones

Ancient Stones is a Phoenix and LiveView world-building dashboard for creating RPG settings, campaign references, and fiction worlds.

The current app focuses on a Skyrim-inspired framework: worlds, galaxies, continents, provinces, holds, locations, races, guilds, gods, civilizations, characters, politics, calendars, timelines, creatures, skills, spells, items, inventories, and local commerce. You can start from a Nordic fantasy template or create a blank world and define your own structure.

Ancient Stones is a project, not a packaged library.

## What It Does

- Create worlds from a blank canvas or the Skyrim-inspired template.
- Organize geography from galaxy and world down to continent, province, hold, and location.
- Browse and edit world-building records from a compact dashboard.
- Track races, guilds, gods, civilizations, calendars, timelines, characters, politics, creatures, skills, spells, items, and character inventories.
- Model regional details such as terrain, climate, capitals, political offices, local commerce, and location types.
- Use a starter data set inspired by Skyrim as a reference structure for RPGs, games, or book settings.

## Status

This is early project work. The data model is already broad enough to explore an RPG-maker style workflow, but it is not complete game tooling yet. The strongest areas today are geography, template creation, character relationships, skill/perk references, item catalogs, and the builder dashboard.

See [docs/skyrim_template.md](docs/skyrim_template.md) for the current template coverage and known gaps.

## Requirements

- Elixir 1.17 or later
- Erlang/OTP compatible with the Elixir version above
- PostgreSQL

## Setup

Install dependencies, create the database, run migrations, and build assets:

```sh
mix setup
```

Start the Phoenix server:

```sh
mix phx.server
```

Open:

```text
http://localhost:4000
```

## Development

Run the project checks:

```sh
mix precommit
```

Useful commands:

```sh
mix test
mix format
mix ecto.reset
```

## Main Routes

- `/` and `/worlds`: world and galaxy workspace
- `/worlds/new`: world creation flow
- `/worlds/:id/dashboard`: builder dashboard for a world
- `/worlds/:id`: world summary page

## Template Notes

The Skyrim-inspired template is included as a starter data set for testing and design exploration. It is meant to demonstrate the framework and provide recognizable structure, not to be a complete canonical database.

Ancient Stones is not affiliated with Bethesda, ZeniMax, or The Elder Scrolls. Skyrim and The Elder Scrolls names belong to their respective owners.

## Project Direction

The long-term goal is a focused world-building workspace that can help people design their own RPG setting, prepare a game database, or organize lore for fiction writing. The current shape leans into Nordic fantasy because that gives the framework concrete constraints: capitals, jarls, housecarls, guilds, gods, ruins, dangerous regions, local markets, skills, weapons, spells, and other familiar RPG concepts.
