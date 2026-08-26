# Ancient Stones

[![CI](https://github.com/ccarvalho-eng/ancient-stones/actions/workflows/ci.yml/badge.svg)](https://github.com/ccarvalho-eng/ancient-stones/actions/workflows/ci.yml)
[![Security](https://github.com/ccarvalho-eng/ancient-stones/actions/workflows/security.yml/badge.svg)](https://github.com/ccarvalho-eng/ancient-stones/actions/workflows/security.yml)
[![Elixir 1.19.5](https://img.shields.io/badge/Elixir-1.19.5-4B275F?logo=elixir)](https://elixir-lang.org/)
[![Phoenix 1.8](https://img.shields.io/badge/Phoenix-1.8-FD4F00?logo=phoenixframework)](https://www.phoenixframework.org/)
[![License: Apache-2.0](https://img.shields.io/badge/License-Apache--2.0-blue.svg)](LICENSE)

Ancient Stones is a Phoenix LiveView workspace for designing fictional worlds, RPG settings, campaign references, and story bibles. It keeps geography, societies, characters, history, economies, and maps in one structured model so a setting can grow without becoming a collection of disconnected notes.

The application is setting-agnostic. Its optional Skyrim-inspired template is a reference dataset that demonstrates the model; it does not constrain the kinds of worlds Ancient Stones can represent.

## What it can model

- Galaxies, worlds, moons, continents, provinces, holds, locations, and connected bodies of water.
- Terrain, climate, geology, watersheds, coordinates, capitals, settlement functions, and political jurisdictions.
- Civilizations, races, households, characters, occupations, relationships, guilds, gods, and political offices.
- Trade routes and legs, commodities, currencies, ventures, taxation, exemptions, revenue shares, and regional economic profiles.
- Calendars, months, eras, events, documents, lore connections, skills, perks, spells, creatures, and historical items.
- World guides exported as PDF or EPUB.

## Atlas editor

Each world can contain multiple maps, including nested regional maps. The browser editor supports:

- Freehand ink, erasing, editable landmass polygons, terrain textures, labels, and reusable map symbols.
- Zoom, pinch gestures, panning, snapping, grids, center guides, focus mode, layering, locking, and duplication.
- Searchable medieval and fantasy symbols sourced from [Game-icons.net](https://game-icons.net/).
- Local reference-image uploads for tracing; reference images are excluded from exported maps.
- PostgreSQL persistence for map documents and indexed map objects.
- PNG export for finished maps.

## Project status

Ancient Stones is active early-stage software. Its core world-building, map-authoring, template, and export workflows are functional, but the data model and user interface are still evolving.

The application does not currently provide authentication or production-grade upload storage. Reference images use local application storage, which is appropriate for development but should be replaced with durable object storage before a distributed deployment.

See [docs/skyrim_template.md](docs/skyrim_template.md) for the reference template's coverage and known limitations.

## Technology

- Elixir 1.19 and Erlang/OTP 28
- Phoenix 1.8 and Phoenix LiveView 1.2
- Ecto and PostgreSQL
- Tailwind CSS 4 and Fabric.js
- ExUnit, LiveViewTest, Credo, Dialyzer, Doctor, Sobelow, and MixAudit

The repository pins its development toolchain in [.tool-versions](.tool-versions).

## Requirements

The supported project constraint is Elixir 1.17 or later. For a reproducible development environment, use the pinned versions:

- Erlang/OTP 28.4.1
- Elixir 1.19.5 with OTP 28
- Node.js 24.15.0
- PostgreSQL 17

The development database defaults to `localhost`, database `ancient_stones_dev`, and the `postgres` user with password `postgres`. Adjust [config/dev.exs](config/dev.exs) when your local database differs.

## Getting started

Install dependencies, create and migrate the database, load development seeds, and build the assets:

```sh
mix setup
```

Start the development server:

```sh
mix phx.server
```

Open [http://localhost:4000](http://localhost:4000).

## Main routes

| Route | Purpose |
| --- | --- |
| `/` or `/worlds` | Browse and edit galaxies and worlds |
| `/worlds/new` | Create a blank or template-based world |
| `/worlds/:id` | View a world summary |
| `/worlds/:id/dashboard` | Manage a world's structured lore and maps |
| `/maps` | Browse and filter the global map library |
| `/worlds/:id/export.pdf` | Export a print-ready world guide |
| `/worlds/:id/export.epub` | Export a reflowable e-reader edition |

## Architecture

Ancient Stones follows Phoenix context boundaries:

- `AncientStones.Galaxies` owns galaxy persistence and associations.
- `AncientStones.Worlds` owns world geography, society, history, economy, and related schemas.
- `AncientStones.Maps` owns map documents, indexed map items, and reference images.
- `AncientStones.Templates` creates optional reference datasets through the same domain APIs used by the application.
- `AncientStones.WorldExports` turns a loaded world guide into PDF and EPUB editions.
- `AncientStonesWeb` contains LiveViews, components, controllers, and the interactive map client.

PostgreSQL is the source of truth for structured records and map state. LiveView owns server-rendered forms and navigation, while the Fabric.js hook manages direct canvas interaction and synchronizes map changes through LiveView events.

## Development

Run the full local gate before submitting changes:

```sh
mix precommit
```

Useful commands:

```sh
mix test                 # Run the Elixir test suite
mix test --cover         # Run tests with built-in Elixir coverage
mix quality              # Run compile, architecture, style, docs, security, and type checks
mix format               # Format Elixir and HEEx files
mix assets.build         # Compile CSS and JavaScript assets
mix ecto.reset           # Recreate, migrate, and seed the development database
mix docs                 # Generate local API documentation
```

JavaScript regression tests use Node's built-in test runner:

```sh
node --test assets/js/game_icon_library.test.mjs assets/js/map_geometry.test.mjs
```

CI runs compilation with warnings as errors, formatting, compile-connected cycle detection, lockfile consistency, built-in coverage, JavaScript tests, asset compilation, Credo, documentation coverage, Sobelow, dependency auditing, Dialyzer, filesystem vulnerability scanning, and secret scanning.

## Repository layout

| Path | Contents |
| --- | --- |
| `lib/ancient_stones` | Domain contexts, schemas, templates, exports, and persistence logic |
| `lib/ancient_stones_web/live` | LiveView pages, components, forms, and dashboard workflows |
| `assets/js/hooks` | Interactive map editor and browser integrations |
| `assets/css` | Tailwind entry point and application styling |
| `priv/repo/migrations` | PostgreSQL schema history |
| `priv/repo/seeds.exs` | Development seed data |
| `docs` | Reference-template and project documentation |
| `test` | Context, LiveView, export, template, and JavaScript regression coverage |

## Attribution

The Skyrim-inspired template demonstrates the framework with a recognizable world structure. It is not intended to be a complete canonical database.

Ancient Stones is not affiliated with Bethesda, ZeniMax, or The Elder Scrolls. Skyrim and The Elder Scrolls names belong to their respective owners.

Map symbols are sourced from [Game-icons.net](https://game-icons.net/) and retain their respective creator credits and licenses.

## License

Ancient Stones is available under the [Apache License 2.0](LICENSE).
