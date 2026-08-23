# Ancient Stones

Ancient Stones is a Phoenix LiveView workspace for building RPG settings, campaign references, and fictional worlds. It combines structured lore management with an interactive map editor, so geography, characters, politics, calendars, and locations can evolve together instead of living in disconnected notes.

The application is designed as a generic world-building system. A Skyrim-inspired template is included as an optional example dataset, not as a limitation on the settings Ancient Stones can model.

## Highlights

### World-building dashboard

- Create blank worlds or start from a populated reference template.
- Organize galaxies, worlds, continents, provinces, holds, and locations.
- Edit records directly from a consistent select-and-form dashboard workflow.
- Define custom weekday and calendar structures.
- Track civilizations, races, characters, roles, guilds, gods, political offices, and relationships.
- Catalog creatures, skills, perks, spells, items, inventories, documents, timelines, and regional commerce.
- Record coordinates, capitals, terrain, climate, visibility, and other location details.

### Atlas map editor

- Create and manage multiple maps for each world, including outer and nested maps.
- Draw freehand ink, erase strokes, and construct editable landmass polygons.
- Paint reusable terrain textures for forests, mountains, grasslands, marshes, deserts, roads, and water.
- Place searchable medieval and fantasy symbols powered by [Game-icons.net](https://game-icons.net/).
- Add, drag, duplicate, layer, lock, and precisely position symbols and text labels.
- Use zoom, pinch gestures, pan mode, grid preferences, snapping, center guides, and focus mode.
- Upload a reference image as a non-exported tracing layer.
- Persist canvas documents and indexed map objects in PostgreSQL.
- Export finished maps as PNG files.

## Project Status

Ancient Stones is active early-stage software rather than a packaged library or production service. Its primary world-building and map-authoring workflows are functional, but the data model, editor tools, storage strategy, and deployment story are still evolving.

Reference images currently use local application storage. That is suitable for development, but a production deployment should move uploads to durable object storage.

See [docs/skyrim_template.md](docs/skyrim_template.md) for the reference template's coverage and known gaps.

## Technology

- Elixir and Phoenix 1.8
- Phoenix LiveView 1.2
- Ecto and PostgreSQL
- Tailwind CSS 4
- Fabric.js canvas rendering
- ExUnit and LiveViewTest

## Requirements

- Elixir 1.17 or later
- A compatible Erlang/OTP release
- PostgreSQL

The development database defaults to a local PostgreSQL instance using the `postgres` user and password. Adjust `config/dev.exs` if your environment differs.

## Getting Started

Install dependencies, create and migrate the database, load seeds, and build assets:

```sh
mix setup
```

Start the development server:

```sh
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000).

## Main Routes

| Route | Purpose |
| --- | --- |
| `/` or `/worlds` | Browse and edit galaxies and worlds |
| `/worlds/new` | Create a blank or template-based world |
| `/worlds/:id` | View a world summary |
| `/worlds/:id/dashboard` | Manage a world's lore and maps |
| `/maps` | Browse and filter the global map library |

## Development

Run the complete project checks before submitting changes:

```sh
mix precommit
```

Common commands:

```sh
mix test          # Run the test suite
mix format        # Format Elixir and HEEx files
mix assets.build  # Compile CSS and JavaScript assets
mix ecto.reset    # Recreate, migrate, and seed the database
```

## Project Structure

| Path | Contents |
| --- | --- |
| `lib/ancient_stones` | Domain contexts, schemas, and persistence logic |
| `lib/ancient_stones_web/live` | LiveView pages and dashboard workflows |
| `assets/js/hooks` | Interactive map editor and browser integrations |
| `assets/css` | Tailwind entry point and application styling |
| `priv/repo/migrations` | PostgreSQL schema history |
| `priv/repo/seeds.exs` | Development seed data |
| `test` | Context, LiveView, and JavaScript regression coverage |

## Template and Asset Attribution

The Skyrim-inspired template demonstrates the framework with a recognizable world structure. It is not intended to be a complete canonical database.

Ancient Stones is not affiliated with Bethesda, ZeniMax, or The Elder Scrolls. Skyrim and The Elder Scrolls names belong to their respective owners.

Map symbols are sourced from [Game-icons.net](https://game-icons.net/) and retain their respective creator credits and licenses.

## Direction

The long-term goal is a focused, extensible workspace for designing original RPG worlds, preparing campaign material, organizing fiction lore, and producing maps whose objects remain connected to the underlying world model.
