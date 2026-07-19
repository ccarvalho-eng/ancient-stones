defmodule AncientStones.Templates.Skyrim do
  @moduledoc """
  Skyrim-inspired starter geography for the Nordic world-building template.
  """

  def data do
    %{
      name: "Nirn",
      description:
        "The mortal world where myth, empire, wilderness, and old magic shape the lives of its peoples.",
      galaxy: "Mundus",
      galaxies: galaxies(),
      timelines: timelines(),
      civilizations: civilizations(),
      creature_types: creature_types(),
      creatures: creatures(),
      gods: gods(),
      guilds: guilds(),
      characters: characters(),
      occupations: occupations(),
      spells: spells(),
      items: items(),
      skill_trees: skill_trees(),
      skills: skills(),
      political_offices: political_offices(),
      races: races(),
      location_types: location_types(),
      continents: continents()
    }
  end

  defp galaxies do
    [
      %{
        name: "Mundus",
        description: "The mortal plane that contains Nirn in Elder Scrolls cosmology."
      }
    ]
  end

  defp civilizations do
    [
      civilization(
        "Atmorans",
        "Merethic Era",
        "Merethic Era",
        "past",
        "The northern human ancestors associated with migrations from Atmora into Skyrim."
      ),
      civilization(
        "Dwemer",
        "Merethic Era to First Era",
        "Merethic Era",
        "vanished",
        "An advanced elven civilization associated with underground cities, tonal craft, and animunculi."
      ),
      civilization(
        "Snow Elves",
        "Merethic Era",
        "Merethic Era",
        "fallen",
        "The ancient Falmer civilization of Skyrim before war, flight underground, and transformation."
      ),
      civilization(
        "Ancient Nords",
        "Merethic Era to First Era",
        "Merethic Era",
        "past",
        "Early Nordic civilization tied to barrows, dragon cults, kings, and old stone monuments."
      )
    ]
  end

  defp civilization(name, era, timeline_era, status, description) do
    %{
      name: name,
      era: era,
      timeline_era: timeline_era,
      status: status,
      description: description
    }
  end

  defp timelines do
    [
      %{
        name: "Tamrielic Timeline",
        description: "The major historical eras used to frame Tamrielic history.",
        eras: [
          era(1, "Dawn Era", nil, nil, nil, "Mythic time before stable mortal chronology."),
          era(
            2,
            "Merethic Era",
            "ME",
            -2500,
            0,
            "The early mythic age of elves and first recorded Nordic reckoning."
          ),
          era(3, "First Era", "1E", 1, 2920, "The first era of recorded Tamrielic history."),
          era(4, "Second Era", "2E", 1, 896, "The era between the Reman and Septim empires."),
          era(
            5,
            "Third Era",
            "3E",
            1,
            433,
            "The Septim Empire era ending with the Oblivion Crisis."
          ),
          era(6, "Fourth Era", "4E", 1, nil, "The current era for the events of Skyrim.")
        ]
      }
    ]
  end

  defp era(position, name, abbreviation, starts_at_year, ends_at_year, description) do
    %{
      position: position,
      name: name,
      abbreviation: abbreviation,
      starts_at_year: starts_at_year,
      ends_at_year: ends_at_year,
      description: description
    }
  end

  defp continents do
    [
      %{
        name: "Tamriel",
        description: "The central continent of Nirn, traditionally divided into nine provinces.",
        calendars: [tamrielic_calendar()],
        provinces: tamriel_provinces()
      },
      %{
        name: "Akavir",
        description:
          "An eastern continent associated with Tsaesci, Tang Mo, Kamal, Ka Po' Tun, dragons, and invasions of Tamriel.",
        provinces: []
      },
      %{
        name: "Atmora",
        description:
          "A northern frozen continent remembered as the ancestral homeland of the Atmorans and early Nords.",
        provinces: []
      },
      %{
        name: "Pyandonea",
        description:
          "An island-continent south-west of Tamriel, associated with the Maormer sea elves.",
        provinces: []
      },
      %{
        name: "Yokuda",
        description:
          "The western homeland of the Redguards before catastrophe drove survivors toward Hammerfell.",
        provinces: []
      },
      %{
        name: "Aldmeris",
        description:
          "A mythic or lost homeland associated with elven origins in Elder Scrolls tradition.",
        provinces: []
      },
      %{
        name: "Thras",
        description:
          "The Coral Kingdom associated with the Sload, described as a partially submerged landmass.",
        provinces: []
      }
    ]
  end

  defp tamriel_provinces do
    [
      %{
        name: "Black Marsh",
        description: "The marshy south-eastern province of Tamriel, home of the Argonians."
      },
      %{
        name: "Cyrodiil",
        description: "The central Imperial Province of Tamriel and seat of the Imperial City."
      },
      %{
        name: "Elsweyr",
        description:
          "The Khajiit homeland in southern Tamriel, divided into Anequina and Pelletine by the Fourth Era."
      },
      %{
        name: "Hammerfell",
        description: "The western province of Tamriel associated with the Redguards."
      },
      %{
        name: "High Rock",
        description: "The north-western province of Tamriel associated with Bretons and Orsinium."
      },
      %{
        name: "Morrowind",
        description: "The north-eastern province of Tamriel associated with the Dunmer."
      },
      %{
        name: "Skyrim",
        description:
          "A cold northern province of mountains, old kingdoms, clan politics, barrows, and hard-won roads.",
        terrain: :mountain,
        climate: :cold,
        holds: holds()
      },
      %{
        name: "Summerset Isles",
        description: "The island province south-west of Tamriel associated with the Altmer."
      },
      %{
        name: "Valenwood",
        description: "The forested south-western province of Tamriel associated with the Bosmer."
      }
    ]
  end

  defp tamrielic_calendar do
    %{
      name: "Tamrielic Calendar",
      description: "The common Tamrielic calendar with twelve named months and a seven-day week.",
      days_per_week: 7,
      era: "Fourth Era",
      months: [
        month(1, "Morning Star", 31),
        month(2, "Sun's Dawn", 28),
        month(3, "First Seed", 31),
        month(4, "Rain's Hand", 30),
        month(5, "Second Seed", 31),
        month(6, "Mid Year", 30),
        month(7, "Sun's Height", 31),
        month(8, "Last Seed", 31),
        month(9, "Hearthfire", 30),
        month(10, "Frostfall", 31),
        month(11, "Sun's Dusk", 30),
        month(12, "Evening Star", 31)
      ]
    }
  end

  defp month(position, name, days) do
    %{position: position, name: name, days: days}
  end

  defp creature_types do
    [
      %{name: "Animal", description: "Natural wildlife found across wilderness and roads."},
      %{name: "Beast", description: "Dangerous non-civilized creatures and monsters."},
      %{name: "Construct", description: "Animated or built guardians and machines."},
      %{name: "Daedra", description: "Creatures associated with Oblivion and Daedric powers."},
      %{name: "Dragon", description: "Ancient dovah tied to the Voice, sky, and old prophecy."},
      %{name: "Undead", description: "Restless dead, spirits, draugr, vampires, and revenants."}
    ]
  end

  defp creatures do
    [
      creature("Dragon", "Dragon", "mountains and dragon lairs", "hostile", "severe"),
      creature("Draugr", "Undead", "Nordic ruins and barrows", "hostile", "high"),
      creature("Dwarven Spider", "Construct", "Dwemer ruins", "hostile", "medium"),
      creature("Frostbite Spider", "Beast", "caves, forests, and ruins", "hostile", "medium"),
      creature("Frost Troll", "Beast", "snowfields, passes, and high roads", "hostile", "high"),
      creature("Ice Wolf", "Animal", "cold forests and tundra", "hostile", "low"),
      creature("Sabre Cat", "Animal", "plains, forests, and mountain edges", "hostile", "medium"),
      creature("Skeever", "Animal", "caves, sewers, ruins, and roadsides", "hostile", "low"),
      creature("Spriggan", "Beast", "groves and old wild places", "hostile", "medium"),
      creature("Vampire", "Undead", "crypts, lairs, and hidden courts", "hostile", "high")
    ]
  end

  defp creature(name, type, habitat, temperament, danger_level) do
    %{
      name: name,
      type: type,
      habitat: habitat,
      temperament: temperament,
      danger_level: danger_level,
      description: "#{name} is commonly associated with #{habitat}."
    }
  end

  defp gods do
    [
      god("Akatosh", "Divines", "time, endurance, dragon kingship"),
      god("Arkay", "Divines", "birth, death, burial rites"),
      god("Dibella", "Divines / Nordic Pantheon", "beauty, art, love"),
      god("Julianos", "Divines", "wisdom, logic, learning"),
      god("Kynareth", "Divines", "air, wind, sky, nature"),
      god("Mara", "Divines / Nordic Pantheon", "love, compassion, marriage"),
      god("Stendarr", "Divines", "mercy, justice, protection"),
      god("Talos", "Divines", "hero-god of mankind and imperial apotheosis"),
      god("Zenithar", "Divines", "work, trade, commerce"),
      god("Alduin", "Nordic Pantheon", "the world-eating dragon and next cycle"),
      god("Herma-Mora", "Nordic Pantheon", "fate, knowledge, testing"),
      god("Jhunal", "Nordic Pantheon", "runes, wisdom, hermetic orders"),
      god("Kyne", "Nordic Pantheon", "storm, sky, mother of Nords"),
      god("Mauloch", "Nordic Pantheon", "the ostracized and testing"),
      god("Orkey", "Nordic Pantheon", "mortality and testing"),
      god("Shor", "Nordic Pantheon", "the dead god and Sovngarde"),
      god("Stuhn", "Nordic Pantheon", "ransom and shield-thanes"),
      god("Tsun", "Nordic Pantheon", "trials against adversity"),
      god("Ysmir", "Nordic Pantheon", "the dragon of the north"),
      god("Azura", "Daedric Princes", "dusk, dawn, prophecy"),
      god("Boethiah", "Daedric Princes", "plots, betrayal, overthrow"),
      god("Clavicus Vile", "Daedric Princes", "bargains, wishes, pacts"),
      god("Hermaeus Mora", "Daedric Princes", "forbidden knowledge and memory"),
      god("Hircine", "Daedric Princes", "the hunt and lycanthropy"),
      god("Jyggalag", "Daedric Princes", "order"),
      god("Malacath", "Daedric Princes", "outcasts, curses, sworn oaths"),
      god("Mehrunes Dagon", "Daedric Princes", "destruction, revolution, ambition"),
      god("Mephala", "Daedric Princes", "secrets, murder, lies"),
      god("Meridia", "Daedric Princes", "life energy and hatred of undead"),
      god("Molag Bal", "Daedric Princes", "domination and enslavement"),
      god("Namira", "Daedric Princes", "revulsion, decay, ancient darkness"),
      god("Nocturnal", "Daedric Princes", "night, shadows, thieves"),
      god("Peryite", "Daedric Princes", "pestilence and natural order"),
      god("Sanguine", "Daedric Princes", "revelry, indulgence, debauchery"),
      god("Sheogorath", "Daedric Princes", "madness"),
      god("Vaermina", "Daedric Princes", "dreams and nightmares"),
      god("Sithis", "Other", "the void and the Dark Brotherhood's dread father")
    ]
  end

  defp god(name, pantheon, domain) do
    %{
      name: name,
      pantheon: pantheon,
      domain: domain,
      description: "#{name} is associated with #{domain}."
    }
  end

  defp skill_trees do
    Enum.map(skills(), fn skill ->
      %{
        name: skill.name,
        category: skill.category,
        description: "#{skill.name} perk tree in the #{skill.category} constellation.",
        perks: skill_tree_perks(skill.name)
      }
    end)
  end

  defp skill_tree_perks(skill_name) do
    skill_name
    |> perks_for_skill()
    |> Enum.with_index(1)
    |> Enum.map(fn {{name, required_level, ranks, description}, position} ->
      %{
        name: name,
        required_level: required_level,
        ranks: ranks,
        position: position,
        description: description
      }
    end)
  end

  defp perks_for_skill("Archery") do
    [
      {"Overdraw", 0, 5, "Bows do more damage at ranks 1-5."},
      {"Eagle Eye", 30, 1, "Zoom in while aiming a bow."},
      {"Critical Shot", 30, 3, "Adds a chance of critical damage with bows."},
      {"Steady Hand", 40, 2, "Zooming with a bow slows time."},
      {"Power Shot", 50, 1, "Arrows stagger most targets."},
      {"Hunter's Discipline", 50, 1, "Recover twice as many arrows from dead bodies."},
      {"Ranger", 60, 1, "Move faster with a drawn bow."},
      {"Quick Shot", 70, 1, "Draw bows faster."},
      {"Bullseye", 100, 1, "Arrows can paralyze targets."}
    ]
  end

  defp perks_for_skill("Block") do
    [
      {"Shield Wall", 0, 5, "Blocking is more effective at ranks 1-5."},
      {"Deflect Arrows", 30, 1, "Arrows that hit a raised shield do no damage."},
      {"Quick Reflexes", 30, 1, "Time slows while blocking during enemy power attacks."},
      {"Power Bash", 30, 1, "Perform a power bash."},
      {"Elemental Protection", 50, 1,
       "Blocking with a shield reduces fire, frost, and shock damage."},
      {"Deadly Bash", 50, 1, "Bashing does more damage."},
      {"Block Runner", 70, 1, "Move faster while blocking with a shield."},
      {"Disarming Bash", 70, 1, "Power bashing can disarm opponents."},
      {"Shield Charge", 100, 1, "Sprinting with a raised shield knocks down most targets."}
    ]
  end

  defp perks_for_skill("Heavy Armor") do
    [
      {"Juggernaut", 0, 5, "Heavy armor rating improves at ranks 1-5."},
      {"Fists of Steel", 30, 1, "Unarmed attacks with heavy gauntlets do extra damage."},
      {"Well Fitted", 30, 1, "Wear all heavy armor for an armor bonus."},
      {"Cushioned", 50, 1, "Take half damage from falling while wearing heavy armor."},
      {"Tower of Strength", 50, 1, "Stagger less while wearing only heavy armor."},
      {"Conditioning", 70, 1, "Heavy armor weighs nothing and does not slow movement."},
      {"Matching Set", 70, 1, "Wear a matched heavy armor set for an armor bonus."},
      {"Reflect Blows", 100, 1, "Heavy armor can reflect melee damage back to enemies."}
    ]
  end

  defp perks_for_skill("One-handed") do
    [
      {"Armsman", 0, 5, "One-handed weapons do more damage at ranks 1-5."},
      {"Fighting Stance", 20, 1, "One-handed power attacks cost less stamina."},
      {"Hack and Slash", 30, 3, "War axes cause bleeding damage."},
      {"Bone Breaker", 30, 3, "Maces ignore a portion of armor."},
      {"Bladesman", 30, 3, "Swords gain a chance of critical damage."},
      {"Dual Flurry", 30, 2, "Dual-wielding attacks are faster."},
      {"Savage Strike", 50, 1, "Standing power attacks do bonus damage and can decapitate."},
      {"Critical Charge", 50, 1, "Sprinting power attacks do double critical damage."},
      {"Dual Savagery", 70, 1, "Dual-wielding power attacks do bonus damage."},
      {"Paralyzing Strike", 100, 1, "Backward power attacks can paralyze targets."}
    ]
  end

  defp perks_for_skill("Smithing") do
    [
      {"Steel Smithing", 0, 1, "Create and improve steel armor and weapons."},
      {"Elven Smithing", 30, 1, "Create and improve elven armor and weapons."},
      {"Dwarven Smithing", 30, 1, "Create and improve dwarven armor and weapons."},
      {"Advanced Armors", 50, 1, "Create and improve scaled and plate armor."},
      {"Orcish Smithing", 50, 1, "Create and improve orcish armor and weapons."},
      {"Arcane Blacksmith", 60, 1, "Improve magical weapons and armor."},
      {"Glass Smithing", 70, 1, "Create and improve glass armor and weapons."},
      {"Ebony Smithing", 80, 1, "Create and improve ebony armor and weapons."},
      {"Daedric Smithing", 90, 1, "Create and improve Daedric armor and weapons."},
      {"Dragon Armor", 100, 1, "Create and improve dragon armor."}
    ]
  end

  defp perks_for_skill("Two-handed") do
    [
      {"Barbarian", 0, 5, "Two-handed weapons do more damage at ranks 1-5."},
      {"Champion's Stance", 20, 1, "Two-handed power attacks cost less stamina."},
      {"Limbsplitter", 30, 3, "Battle axes cause bleeding damage."},
      {"Deep Wounds", 30, 3, "Greatswords gain a chance of critical damage."},
      {"Skullcrusher", 30, 3, "Warhammers ignore a portion of armor."},
      {"Devastating Blow", 50, 1, "Standing power attacks do bonus damage and can decapitate."},
      {"Great Critical Charge", 50, 1, "Sprinting power attacks do double critical damage."},
      {"Sweep", 70, 1, "Sideways power attacks hit all targets in front of you."},
      {"Warmaster", 100, 1, "Backward power attacks can paralyze targets."}
    ]
  end

  defp perks_for_skill("Alteration") do
    [
      {"Novice Alteration", 0, 1, "Cast novice Alteration spells for half magicka."},
      {"Alteration Dual Casting", 20, 1, "Dual casting overcharges Alteration spells."},
      {"Apprentice Alteration", 25, 1, "Cast apprentice Alteration spells for half magicka."},
      {"Mage Armor", 30, 3, "Protection spells are stronger when not wearing armor."},
      {"Magic Resistance", 30, 3, "Blocks a portion of spell effects."},
      {"Adept Alteration", 50, 1, "Cast adept Alteration spells for half magicka."},
      {"Stability", 70, 1, "Alteration spells last longer."},
      {"Expert Alteration", 75, 1, "Cast expert Alteration spells for half magicka."},
      {"Atronach", 100, 1, "Absorb part of incoming spell magicka."},
      {"Master Alteration", 100, 1, "Cast master Alteration spells for half magicka."}
    ]
  end

  defp perks_for_skill("Conjuration") do
    [
      {"Novice Conjuration", 0, 1, "Cast novice Conjuration spells for half magicka."},
      {"Conjuration Dual Casting", 20, 1, "Dual casting overcharges Conjuration spells."},
      {"Mystic Binding", 20, 1, "Bound weapons do more damage."},
      {"Apprentice Conjuration", 25, 1, "Cast apprentice Conjuration spells for half magicka."},
      {"Summoner", 30, 2, "Raise undead or summon atronachs farther away."},
      {"Soul Stealer", 30, 1, "Bound weapons cast Soul Trap on targets."},
      {"Necromancy", 40, 1, "Reanimated undead last longer."},
      {"Atromancy", 40, 1, "Atronach summons last longer."},
      {"Oblivion Binding", 50, 1,
       "Bound weapons banish summoned creatures and turn raised undead."},
      {"Adept Conjuration", 50, 1, "Cast adept Conjuration spells for half magicka."},
      {"Dark Souls", 70, 1, "Reanimated undead have more health."},
      {"Expert Conjuration", 75, 1, "Cast expert Conjuration spells for half magicka."},
      {"Elemental Potency", 80, 1, "Summoned atronachs are more powerful."},
      {"Twin Souls", 100, 1, "Maintain two atronachs or reanimated undead at once."},
      {"Master Conjuration", 100, 1, "Cast master Conjuration spells for half magicka."}
    ]
  end

  defp perks_for_skill("Destruction") do
    [
      {"Novice Destruction", 0, 1, "Cast novice Destruction spells for half magicka."},
      {"Destruction Dual Casting", 20, 1, "Dual casting overcharges Destruction spells."},
      {"Apprentice Destruction", 25, 1, "Cast apprentice Destruction spells for half magicka."},
      {"Augmented Flames", 30, 2, "Fire spells do more damage."},
      {"Augmented Frost", 30, 2, "Frost spells do more damage."},
      {"Augmented Shock", 30, 2, "Shock spells do more damage."},
      {"Impact", 40, 1, "Dual-cast Destruction spells stagger targets."},
      {"Rune Master", 40, 1, "Place runes farther away."},
      {"Adept Destruction", 50, 1, "Cast adept Destruction spells for half magicka."},
      {"Intense Flames", 50, 1, "Fire damage can make low-health targets flee."},
      {"Deep Freeze", 60, 1, "Frost damage can paralyze low-health targets."},
      {"Disintegrate", 70, 1, "Shock damage can disintegrate low-health targets."},
      {"Expert Destruction", 75, 1, "Cast expert Destruction spells for half magicka."},
      {"Master Destruction", 100, 1, "Cast master Destruction spells for half magicka."}
    ]
  end

  defp perks_for_skill("Enchanting") do
    [
      {"Enchanter", 0, 5, "New enchantments are stronger at ranks 1-5."},
      {"Soul Squeezer", 20, 1, "Soul gems provide extra magicka for recharging."},
      {"Fire Enchanter", 30, 1, "Fire enchantments are stronger."},
      {"Soul Siphon", 40, 1, "Death blows to creatures trap a portion of their soul."},
      {"Frost Enchanter", 40, 1, "Frost enchantments are stronger."},
      {"Insightful Enchanter", 50, 1, "Skill enchantments on armor are stronger."},
      {"Storm Enchanter", 50, 1, "Shock enchantments are stronger."},
      {"Corpus Enchanter", 70, 1, "Health, magicka, and stamina enchantments are stronger."},
      {"Extra Effect", 100, 1, "Apply two enchantments to one item."}
    ]
  end

  defp perks_for_skill("Illusion") do
    [
      {"Novice Illusion", 0, 1, "Cast novice Illusion spells for half magicka."},
      {"Illusion Dual Casting", 20, 1, "Dual casting overcharges Illusion spells."},
      {"Animage", 20, 1, "Illusion spells work on higher-level animals."},
      {"Apprentice Illusion", 25, 1, "Cast apprentice Illusion spells for half magicka."},
      {"Hypnotic Gaze", 30, 1, "Calm spells work on higher-level targets."},
      {"Kindred Mage", 40, 1, "Illusion spells work on higher-level people."},
      {"Adept Illusion", 50, 1, "Cast adept Illusion spells for half magicka."},
      {"Aspect of Terror", 50, 1, "Fear spells work on higher-level targets."},
      {"Quiet Casting", 50, 1, "All spells from every school are silent to others."},
      {"Rage", 70, 1, "Frenzy spells work on higher-level targets."},
      {"Expert Illusion", 75, 1, "Cast expert Illusion spells for half magicka."},
      {"Master of the Mind", 90, 1, "Illusion spells work on undead, Daedra, and automatons."},
      {"Master Illusion", 100, 1, "Cast master Illusion spells for half magicka."}
    ]
  end

  defp perks_for_skill("Restoration") do
    [
      {"Novice Restoration", 0, 1, "Cast novice Restoration spells for half magicka."},
      {"Restoration Dual Casting", 20, 1, "Dual casting overcharges Restoration spells."},
      {"Regeneration", 20, 1, "Healing spells cure more."},
      {"Apprentice Restoration", 25, 1, "Cast apprentice Restoration spells for half magicka."},
      {"Recovery", 30, 2, "Magicka regenerates faster."},
      {"Respite", 40, 1, "Healing spells also restore stamina."},
      {"Adept Restoration", 50, 1, "Cast adept Restoration spells for half magicka."},
      {"Ward Absorb", 60, 1, "Wards that are hit by spells recharge magicka."},
      {"Necromage", 70, 1, "Spells are more effective against undead."},
      {"Expert Restoration", 75, 1, "Cast expert Restoration spells for half magicka."},
      {"Avoid Death", 90, 1, "Automatically heal once per day when health is low."},
      {"Master Restoration", 100, 1, "Cast master Restoration spells for half magicka."}
    ]
  end

  defp perks_for_skill("Alchemy") do
    [
      {"Alchemist", 0, 5, "Created potions and poisons are stronger at ranks 1-5."},
      {"Physician", 20, 1, "Health, magicka, and stamina potions are stronger."},
      {"Poisoner", 30, 1, "Created poisons are stronger."},
      {"Benefactor", 30, 1, "Created potions with beneficial effects are stronger."},
      {"Experimenter", 50, 3, "Eating ingredients reveals more effects."},
      {"Concentrated Poison", 60, 1, "Poisons applied to weapons last for more hits."},
      {"Green Thumb", 70, 1, "Harvest two ingredients from plants."},
      {"Snakeblood", 80, 1, "Gain resistance to poisons."},
      {"Purity", 100, 1,
       "Remove negative effects from potions and positive effects from poisons."}
    ]
  end

  defp perks_for_skill("Light Armor") do
    [
      {"Agile Defender", 0, 5, "Light armor rating improves at ranks 1-5."},
      {"Custom Fit", 30, 1, "Wear all light armor for an armor bonus."},
      {"Unhindered", 50, 1, "Light armor weighs nothing and does not slow movement."},
      {"Wind Walker", 60, 1, "Stamina regenerates faster while wearing all light armor."},
      {"Matching Set", 70, 1, "Wear a matched light armor set for an armor bonus."},
      {"Deft Movement", 100, 1, "Gain a chance to avoid all damage from a melee attack."}
    ]
  end

  defp perks_for_skill("Lockpicking") do
    [
      {"Novice Locks", 0, 1, "Novice locks are easier to pick."},
      {"Apprentice Locks", 25, 1, "Apprentice locks are easier to pick."},
      {"Quick Hands", 40, 1, "Pick locks without being noticed."},
      {"Wax Key", 50, 1, "Automatically make a copy of a picked lock's key if it has one."},
      {"Adept Locks", 50, 1, "Adept locks are easier to pick."},
      {"Golden Touch", 60, 1, "Find more gold in chests."},
      {"Treasure Hunter", 70, 1, "Find special treasure more often."},
      {"Expert Locks", 75, 1, "Expert locks are easier to pick."},
      {"Locksmith", 80, 1, "Pick starts close to the opening position."},
      {"Unbreakable", 100, 1, "Lockpicks never break."},
      {"Master Locks", 100, 1, "Master locks are easier to pick."}
    ]
  end

  defp perks_for_skill("Pickpocket") do
    [
      {"Light Fingers", 0, 5, "Pickpocketing bonuses improve at ranks 1-5."},
      {"Night Thief", 30, 1, "Pickpocket sleeping people more easily."},
      {"Poisoned", 40, 1, "Place poison in a target's pockets."},
      {"Cutpurse", 40, 1, "Pickpocket gold more easily."},
      {"Extra Pockets", 50, 1, "Increase carrying capacity."},
      {"Keymaster", 60, 1, "Pickpocket keys almost always succeeds."},
      {"Misdirection", 70, 1, "Pickpocket equipped weapons."},
      {"Perfect Touch", 100, 1, "Pickpocket equipped items."}
    ]
  end

  defp perks_for_skill("Sneak") do
    [
      {"Stealth", 0, 5, "Sneaking is harder to detect at ranks 1-5."},
      {"Muffled Movement", 30, 1, "Armor noise is reduced."},
      {"Backstab", 30, 1, "Sneak attacks with one-handed weapons do more damage."},
      {"Light Foot", 40, 1, "Pressure plates no longer trigger."},
      {"Deadly Aim", 40, 1, "Sneak attacks with bows do more damage."},
      {"Silent Roll", 50, 1, "Sprinting while sneaking performs a silent roll."},
      {"Assassin's Blade", 50, 1, "Sneak attacks with daggers do much more damage."},
      {"Silence", 70, 1, "Walking and running do not affect detection."},
      {"Shadow Warrior", 100, 1, "Crouching can briefly stop combat and make enemies search."}
    ]
  end

  defp perks_for_skill("Speech") do
    [
      {"Haggling", 0, 5, "Buying and selling prices improve at ranks 1-5."},
      {"Allure", 30, 1, "Better prices with the opposite sex."},
      {"Bribery", 30, 1, "Bribe guards to ignore crimes."},
      {"Merchant", 50, 1, "Sell any type of item to any merchant."},
      {"Persuasion", 50, 1, "Persuasion attempts are easier."},
      {"Investor", 70, 1, "Invest in shopkeepers to increase available gold."},
      {"Intimidation", 70, 1, "Intimidation attempts are easier."},
      {"Fence", 90, 1, "Trade stolen goods with invested merchants."},
      {"Master Trader", 100, 1, "Every merchant gains more gold for bartering."}
    ]
  end

  defp perks_for_skill(_skill_name) do
    []
  end

  defp skills do
    [
      skill("Archery", "Combat"),
      skill("Block", "Combat"),
      skill("Heavy Armor", "Combat"),
      skill("One-handed", "Combat"),
      skill("Smithing", "Combat"),
      skill("Two-handed", "Combat"),
      skill("Alteration", "Magic"),
      skill("Conjuration", "Magic"),
      skill("Destruction", "Magic"),
      skill("Enchanting", "Magic"),
      skill("Illusion", "Magic"),
      skill("Restoration", "Magic"),
      skill("Alchemy", "Stealth"),
      skill("Light Armor", "Stealth"),
      skill("Lockpicking", "Stealth"),
      skill("Pickpocket", "Stealth"),
      skill("Sneak", "Stealth"),
      skill("Speech", "Stealth")
    ]
  end

  defp skill(name, category) do
    %{
      name: name,
      category: category,
      skill_tree: name,
      description: "#{name} is one of Skyrim's #{category} skills.",
      levels: skyrim_skill_levels()
    }
  end

  defp skyrim_skill_levels do
    [
      skill_level("Novice", 1, 15, "Starting skill band for untrained use."),
      skill_level("Apprentice", 2, 25, "Early trained skill band."),
      skill_level("Adept", 3, 50, "Mid-tier skill band used by adept training."),
      skill_level("Expert", 4, 75, "Advanced skill band used by expert training."),
      skill_level("Master", 5, 100, "Maximum skill band for mastery.")
    ]
  end

  defp skill_level(name, rank, minimum_value, description) do
    %{
      name: name,
      rank: rank,
      minimum_value: minimum_value,
      description: description
    }
  end

  defp spells do
    [
      spell("Candlelight", "Alteration", "Novice", 21, "Creates a hovering light."),
      spell("Oakflesh", "Alteration", "Novice", 103, "Improves the caster's armor rating."),
      spell("Magelight", "Alteration", "Apprentice", 84, "Creates a ball of light."),
      spell("Stoneflesh", "Alteration", "Apprentice", 194, "Improves the caster's armor rating."),
      spell("Ash Shell", "Alteration", "Adept", 251, "Immobilizes a target in hardened ash."),
      spell("Detect Life", "Alteration", "Adept", 100, "Reveals nearby living creatures."),
      spell("Ironflesh", "Alteration", "Adept", 266, "Improves the caster's armor rating."),
      spell("Telekinesis", "Alteration", "Adept", 170, "Manipulates objects at a distance."),
      spell("Transmute", "Alteration", "Adept", 100, "Transmutes unrefined ore."),
      spell("Waterbreathing", "Alteration", "Adept", 222, "Allows the caster to breathe water."),
      spell("Ash Rune", "Alteration", "Expert", 418, "Places an ash trap on a surface."),
      spell("Detect Dead", "Alteration", "Expert", 148, "Reveals nearby dead."),
      spell("Ebonyflesh", "Alteration", "Expert", 341, "Improves the caster's armor rating."),
      spell("Paralyze", "Alteration", "Expert", 450, "Paralyzes targets that fail to resist."),
      spell("Dragonhide", "Alteration", "Master", 837, "Reduces incoming physical damage."),
      spell("Mass Paralysis", "Alteration", "Master", 937, "Paralyzes nearby targets."),
      spell("Equilibrium", "Alteration", "N/A", nil, "Converts health into magicka."),
      spell("Bound Dagger", "Conjuration", "Novice", 53, "Creates a bound dagger."),
      spell("Bound Sword", "Conjuration", "Novice", 93, "Creates a bound sword."),
      spell("Conjure Familiar", "Conjuration", "Novice", 107, "Summons a familiar."),
      spell("Raise Zombie", "Conjuration", "Novice", 103, "Reanimates a weak dead body."),
      spell("Bound Battleaxe", "Conjuration", "Apprentice", 169, "Creates a bound battleaxe."),
      spell("Conjure Boneman", "Conjuration", "Apprentice", 129, "Summons a Soul Cairn boneman."),
      spell(
        "Conjure Flame Atronach",
        "Conjuration",
        "Apprentice",
        150,
        "Summons a flame atronach."
      ),
      spell("Conjure Mistman", "Conjuration", "Apprentice", 193, "Summons a Soul Cairn mistman."),
      spell("Reanimate Corpse", "Conjuration", "Apprentice", 144, "Reanimates a dead body."),
      spell("Soul Trap", "Conjuration", "Apprentice", 107, "Traps a target's soul on death."),
      spell("Banish Daedra", "Conjuration", "Adept", 196, "Banishes weaker summoned daedra."),
      spell("Bound Bow", "Conjuration", "Adept", 206, "Creates a bound bow."),
      spell("Conjure Frost Atronach", "Conjuration", "Adept", 215, "Summons a frost atronach."),
      spell("Conjure Wrathman", "Conjuration", "Adept", 301, "Summons a Soul Cairn wrathman."),
      spell(
        "Command Daedra",
        "Conjuration",
        "Expert",
        242,
        "Controls a summoned or raised creature."
      ),
      spell("Conjure Dremora Lord", "Conjuration", "Expert", 358, "Summons a dremora lord."),
      spell("Conjure Storm Atronach", "Conjuration", "Expert", 322, "Summons a storm atronach."),
      spell("Dread Zombie", "Conjuration", "Expert", 302, "Reanimates a powerful dead body."),
      spell("Expel Daedra", "Conjuration", "Expert", 620, "Banishes stronger summoned daedra."),
      spell("Ash Guardian", "Conjuration", "Expert", 355, "Summons an ash guardian."),
      spell("Ash Spawn", "Conjuration", "Expert", 358, "Summons an ash spawn."),
      spell("Conjure Arvak", "Conjuration", "Apprentice", 136, "Summons Arvak."),
      spell("Dead Thrall", "Conjuration", "Master", 1000, "Permanently reanimates a dead body."),
      spell(
        "Flame Thrall",
        "Conjuration",
        "Master",
        956,
        "Permanently summons a flame atronach."
      ),
      spell(
        "Frost Thrall",
        "Conjuration",
        "Master",
        1100,
        "Permanently summons a frost atronach."
      ),
      spell(
        "Storm Thrall",
        "Conjuration",
        "Master",
        1200,
        "Permanently summons a storm atronach."
      ),
      spell("Flames", "Destruction", "Novice", 14, "Deals fire damage over time."),
      spell("Frostbite", "Destruction", "Novice", 16, "Deals frost damage over time."),
      spell("Sparks", "Destruction", "Novice", 19, "Deals shock damage over time."),
      spell("Firebolt", "Destruction", "Apprentice", 41, "Launches a bolt of fire."),
      spell("Ice Spike", "Destruction", "Apprentice", 48, "Launches a spike of ice."),
      spell("Lightning Bolt", "Destruction", "Apprentice", 51, "Launches a bolt of lightning."),
      spell("Fire Rune", "Destruction", "Apprentice", 234, "Places a fire rune trap."),
      spell("Frost Rune", "Destruction", "Apprentice", 293, "Places a frost rune trap."),
      spell("Lightning Rune", "Destruction", "Apprentice", 323, "Places a lightning rune trap."),
      spell("Fireball", "Destruction", "Adept", 133, "Launches an exploding fire projectile."),
      spell("Flame Cloak", "Destruction", "Adept", 289, "Surrounds the caster with fire."),
      spell("Ice Storm", "Destruction", "Adept", 144, "Launches a freezing storm."),
      spell("Frost Cloak", "Destruction", "Adept", 316, "Surrounds the caster with frost."),
      spell("Chain Lightning", "Destruction", "Adept", 156, "Launches lightning that can arc."),
      spell(
        "Lightning Cloak",
        "Destruction",
        "Adept",
        370,
        "Surrounds the caster with lightning."
      ),
      spell("Icy Spear", "Destruction", "Expert", 320, "Launches a powerful ice spear."),
      spell("Incinerate", "Destruction", "Expert", 298, "Launches a powerful fire blast."),
      spell("Thunderbolt", "Destruction", "Expert", 343, "Launches a powerful lightning bolt."),
      spell("Wall of Flames", "Destruction", "Expert", 118, "Creates a wall of fire."),
      spell("Wall of Frost", "Destruction", "Expert", 137, "Creates a wall of frost."),
      spell("Wall of Storms", "Destruction", "Expert", 145, "Creates a wall of lightning."),
      spell(
        "Whirlwind Cloak",
        "Destruction",
        "Adept",
        338,
        "Creates a cloak of wind around the caster."
      ),
      spell(
        "Blizzard",
        "Destruction",
        "Master",
        656,
        "Creates a freezing storm around the caster."
      ),
      spell("Fire Storm", "Destruction", "Master", 846, "Creates a massive fire explosion."),
      spell("Lightning Storm", "Destruction", "Master", 138, "Channels continuous lightning."),
      spell(
        "Clairvoyance",
        "Illusion",
        "Novice",
        25,
        "Shows a path toward the current objective."
      ),
      spell("Courage", "Illusion", "Novice", 39, "Improves an ally's courage."),
      spell("Fury", "Illusion", "Novice", 67, "Causes targets to attack nearby actors."),
      spell("Calm", "Illusion", "Apprentice", 146, "Pacifies lower-level targets."),
      spell("Fear", "Illusion", "Apprentice", 153, "Makes lower-level targets flee."),
      spell("Muffle", "Illusion", "Apprentice", 144, "Muffles the caster's movement."),
      spell("Frenzy", "Illusion", "Adept", 209, "Causes targets to attack nearby actors."),
      spell("Rally", "Illusion", "Adept", 113, "Improves allies in an area."),
      spell("Invisibility", "Illusion", "Expert", 334, "Makes the caster invisible."),
      spell("Pacify", "Illusion", "Expert", 290, "Pacifies targets in an area."),
      spell("Rout", "Illusion", "Expert", 316, "Makes targets flee."),
      spell("Call to Arms", "Illusion", "Master", 655, "Improves allies in a wide area."),
      spell("Harmony", "Illusion", "Master", 1052, "Pacifies targets in a wide area."),
      spell("Hysteria", "Illusion", "Master", 866, "Makes targets flee in a wide area."),
      spell("Mayhem", "Illusion", "Master", 990, "Causes targets to attack nearby actors."),
      spell("Healing", "Restoration", "Novice", 12, "Restores the caster's health."),
      spell("Lesser Ward", "Restoration", "Novice", 34, "Raises a lesser magic ward."),
      spell("Sun Fire", "Restoration", "Novice", 24, "Deals sun damage to undead."),
      spell("Fast Healing", "Restoration", "Apprentice", 73, "Restores health immediately."),
      spell(
        "Healing Hands",
        "Restoration",
        "Apprentice",
        25,
        "Restores another target's health."
      ),
      spell("Necromantic Healing", "Restoration", "Apprentice", 27, "Restores undead health."),
      spell("Steadfast Ward", "Restoration", "Apprentice", 58, "Raises a stronger magic ward."),
      spell("Turn Lesser Undead", "Restoration", "Apprentice", 84, "Turns weaker undead."),
      spell("Close Wounds", "Restoration", "Adept", 126, "Restores more health immediately."),
      spell("Greater Ward", "Restoration", "Adept", 86, "Raises a greater magic ward."),
      spell("Heal Other", "Restoration", "Adept", 80, "Restores another target's health."),
      spell("Heal Undead", "Restoration", "Adept", 115, "Restores undead health."),
      spell("Repel Lesser Undead", "Restoration", "Adept", 115, "Repels weaker undead nearby."),
      spell("Turn Undead", "Restoration", "Adept", 168, "Turns undead."),
      spell(
        "Vampire's Bane",
        "Restoration",
        "Adept",
        106,
        "Deals sun damage to undead in an area."
      ),
      spell(
        "Circle of Protection",
        "Restoration",
        "Expert",
        171,
        "Creates a circle that repels undead."
      ),
      spell("Grand Healing", "Restoration", "Expert", 254, "Restores health to nearby targets."),
      spell("Poison Rune", "Restoration", "Expert", 146, "Places a poison rune trap."),
      spell("Repel Undead", "Restoration", "Expert", 353, "Repels undead nearby."),
      spell("Stendarr's Aura", "Restoration", "Expert", 248, "Damages nearby undead over time."),
      spell("Turn Greater Undead", "Restoration", "Expert", 267, "Turns stronger undead."),
      spell("Bane of the Undead", "Restoration", "Master", 988, "Burns and turns undead."),
      spell(
        "Guardian Circle",
        "Restoration",
        "Master",
        716,
        "Creates a healing circle that repels undead."
      )
    ]
  end

  defp spell(name, school, level, magicka_cost, description) do
    %{
      name: name,
      school: school,
      level: level,
      magicka_cost: magicka_cost,
      source: "Skyrim",
      description: description
    }
  end

  defp items do
    weapons() ++ apparel() ++ food()
  end

  defp weapons do
    weapon_set("Iron", "Skyrim", [
      weapon("Iron Dagger", "dagger", "one-handed", 4, 2, 10),
      weapon("Iron Sword", "sword", "one-handed", 7, 9, 25),
      weapon("Iron War Axe", "war axe", "one-handed", 8, 11, 30),
      weapon("Iron Mace", "mace", "one-handed", 9, 13, 35),
      weapon("Iron Greatsword", "greatsword", "two-handed", 15, 16, 50),
      weapon("Iron Battleaxe", "battleaxe", "two-handed", 16, 20, 55),
      weapon("Iron Warhammer", "warhammer", "two-handed", 18, 24, 60),
      weapon("Iron Arrow", "arrow", "ammunition", 8, 0, 1)
    ]) ++
      weapon_set("Steel", "Skyrim", [
        weapon("Steel Dagger", "dagger", "one-handed", 5, "2.5", 18),
        weapon("Steel Sword", "sword", "one-handed", 8, 10, 45),
        weapon("Steel War Axe", "war axe", "one-handed", 9, 12, 55),
        weapon("Steel Mace", "mace", "one-handed", 10, 14, 65),
        weapon("Steel Greatsword", "greatsword", "two-handed", 17, 17, 90),
        weapon("Steel Battleaxe", "battleaxe", "two-handed", 18, 21, 100),
        weapon("Steel Warhammer", "warhammer", "two-handed", 20, 25, 110),
        weapon("Steel Arrow", "arrow", "ammunition", 10, 0, 2)
      ]) ++
      weapon_set("Orcish", "Skyrim", [
        weapon("Orcish Dagger", "dagger", "one-handed", 6, 3, 30),
        weapon("Orcish Sword", "sword", "one-handed", 9, 11, 75),
        weapon("Orcish War Axe", "war axe", "one-handed", 10, 13, 90),
        weapon("Orcish Mace", "mace", "one-handed", 11, 15, 105),
        weapon("Orcish Greatsword", "greatsword", "two-handed", 18, 18, 75),
        weapon("Orcish Battleaxe", "battleaxe", "two-handed", 19, 25, 165),
        weapon("Orcish Warhammer", "warhammer", "two-handed", 21, 26, 180),
        weapon("Orcish Bow", "bow", "two-handed", 10, 9, 150),
        weapon("Orcish Arrow", "arrow", "ammunition", 12, 0, 3)
      ]) ++
      weapon_set("Dwarven", "Skyrim", [
        weapon("Dwarven Dagger", "dagger", "one-handed", 7, "3.5", 55),
        weapon("Dwarven Sword", "sword", "one-handed", 10, 12, 135),
        weapon("Dwarven War Axe", "war axe", "one-handed", 11, 14, 165),
        weapon("Dwarven Mace", "mace", "one-handed", 12, 16, 190),
        weapon("Dwarven Greatsword", "greatsword", "two-handed", 19, 19, 270),
        weapon("Dwarven Battleaxe", "battleaxe", "two-handed", 20, 23, 300),
        weapon("Dwarven Warhammer", "warhammer", "two-handed", 22, 27, 325),
        weapon("Dwarven Bow", "bow", "two-handed", 12, 10, 270),
        weapon("Dwarven Arrow", "arrow", "ammunition", 14, 0, 4)
      ]) ++
      weapon_set("Elven", "Skyrim", [
        weapon("Elven Dagger", "dagger", "one-handed", 8, 4, 95),
        weapon("Elven Sword", "sword", "one-handed", 11, 13, 235),
        weapon("Elven War Axe", "war axe", "one-handed", 12, 15, 280),
        weapon("Elven Mace", "mace", "one-handed", 13, 17, 330),
        weapon("Elven Greatsword", "greatsword", "two-handed", 20, 20, 470),
        weapon("Elven Battleaxe", "battleaxe", "two-handed", 21, 24, 520),
        weapon("Elven Warhammer", "warhammer", "two-handed", 23, 28, 565),
        weapon("Elven Bow", "bow", "two-handed", 13, 12, 470),
        weapon("Elven Arrow", "arrow", "ammunition", 16, 0, 2)
      ]) ++
      weapon_set("Glass", "Skyrim", [
        weapon("Glass Dagger", "dagger", "one-handed", 9, "4.5", 165),
        weapon("Glass Sword", "sword", "one-handed", 12, 14, 410),
        weapon("Glass War Axe", "war axe", "one-handed", 13, 16, 490),
        weapon("Glass Mace", "mace", "one-handed", 14, 18, 575),
        weapon("Glass Greatsword", "greatsword", "two-handed", 21, 22, 820),
        weapon("Glass Battleaxe", "battleaxe", "two-handed", 22, 25, 900),
        weapon("Glass Warhammer", "warhammer", "two-handed", 24, 29, 985),
        weapon("Glass Bow", "bow", "two-handed", 15, 14, 820),
        weapon("Glass Arrow", "arrow", "ammunition", 18, 0, 6)
      ]) ++
      weapon_set("Ebony", "Skyrim", [
        weapon("Ebony Dagger", "dagger", "one-handed", 10, 5, 290),
        weapon("Ebony Sword", "sword", "one-handed", 13, 15, 720),
        weapon("Ebony War Axe", "war axe", "one-handed", 15, 17, 865),
        weapon("Ebony Mace", "mace", "one-handed", 16, 19, 1000),
        weapon("Ebony Greatsword", "greatsword", "two-handed", 22, 22, 1440),
        weapon("Ebony Battleaxe", "battleaxe", "two-handed", 23, 26, 1585),
        weapon("Ebony Warhammer", "warhammer", "two-handed", 25, 30, 1725),
        weapon("Ebony Bow", "bow", "two-handed", 17, 16, 1440),
        weapon("Ebony Arrow", "arrow", "ammunition", 20, 0, 7)
      ]) ++
      weapon_set("Daedric", "Skyrim", [
        weapon("Daedric Dagger", "dagger", "one-handed", 11, 6, 500),
        weapon("Daedric Sword", "sword", "one-handed", 14, 16, 1250),
        weapon("Daedric War Axe", "war axe", "one-handed", 15, 18, 1500),
        weapon("Daedric Mace", "mace", "one-handed", 16, 20, 1750),
        weapon("Daedric Greatsword", "greatsword", "two-handed", 24, 23, 2500),
        weapon("Daedric Battleaxe", "battleaxe", "two-handed", 25, 27, 2750),
        weapon("Daedric Warhammer", "warhammer", "two-handed", 27, 31, 4000),
        weapon("Daedric Bow", "bow", "two-handed", 19, 18, 2500),
        weapon("Daedric Arrow", "arrow", "ammunition", 24, 0, 8)
      ]) ++
      weapon_set("Dragonbone", "Dawnguard", [
        weapon("Dragonbone Dagger", "dagger", "one-handed", 12, "6.5", 600),
        weapon("Dragonbone Sword", "sword", "one-handed", 15, 19, 1500),
        weapon("Dragonbone War Axe", "war axe", "one-handed", 16, 21, 1700),
        weapon("Dragonbone Mace", "mace", "one-handed", 17, 22, 2000),
        weapon("Dragonbone Greatsword", "greatsword", "two-handed", 25, 27, 2725),
        weapon("Dragonbone Battleaxe", "battleaxe", "two-handed", 26, 30, 3000),
        weapon("Dragonbone Warhammer", "warhammer", "two-handed", 28, 33, 4275),
        weapon("Dragonbone Bow", "bow", "two-handed", 20, 20, 2725),
        weapon("Dragonbone Arrow", "arrow", "ammunition", 25, 0, 9)
      ])
  end

  defp apparel do
    apparel_set("Iron", "heavy armor", [
      apparel_item("Iron Armor", "cuirass", 30, 125),
      apparel_item("Iron Boots", "boots", 6, 25),
      apparel_item("Iron Gauntlets", "gauntlets", 5, 25),
      apparel_item("Iron Helmet", "helmet", 5, 60),
      apparel_item("Banded Iron Shield", "shield", 12, 100)
    ]) ++
      apparel_set("Steel", "heavy armor", [
        apparel_item("Steel Armor", "cuirass", 35, 275),
        apparel_item("Steel Boots", "boots", 8, 55),
        apparel_item("Steel Cuffed Boots", "boots", 8, 55),
        apparel_item("Steel Imperial Gauntlets", "gauntlets", 4, 55),
        apparel_item("Steel Helmet", "helmet", 5, 125),
        apparel_item("Steel Shield", "shield", 12, 150)
      ]) ++
      apparel_set("Elven", "light armor", [
        apparel_item("Elven Armor", "cuirass", 4, 225),
        apparel_item("Elven Boots", "boots", 1, 45),
        apparel_item("Elven Gauntlets", "gauntlets", 1, 45),
        apparel_item("Elven Helmet", "helmet", 1, 110),
        apparel_item("Elven Shield", "shield", 4, 115)
      ]) ++
      apparel_set("Glass", "light armor", [
        apparel_item("Glass Armor", "cuirass", 7, 900),
        apparel_item("Glass Boots", "boots", 2, 190),
        apparel_item("Glass Gauntlets", "gauntlets", 2, 190),
        apparel_item("Glass Helmet", "helmet", 2, 450),
        apparel_item("Glass Shield", "shield", 6, 450)
      ]) ++
      apparel_set("Ebony", "heavy armor", [
        apparel_item("Ebony Armor", "cuirass", 38, 1500),
        apparel_item("Ebony Boots", "boots", 7, 275),
        apparel_item("Ebony Gauntlets", "gauntlets", 7, 275),
        apparel_item("Ebony Helmet", "helmet", 10, 750),
        apparel_item("Ebony Shield", "shield", 14, 750)
      ]) ++
      apparel_set("Daedric", "heavy armor", [
        apparel_item("Daedric Armor", "cuirass", 50, 3200),
        apparel_item("Daedric Boots", "boots", 10, 625),
        apparel_item("Daedric Gauntlets", "gauntlets", 6, 625),
        apparel_item("Daedric Helmet", "helmet", 15, 1600),
        apparel_item("Daedric Shield", "shield", 15, 1600)
      ]) ++
      [
        apparel_item("Amulet of Talos", "amulet", 1, 25)
        |> Map.merge(%{
          category: "apparel",
          material: "Nordic",
          source: "Skyrim",
          description: "A divine amulet associated with Talos."
        }),
        apparel_item("Gold Ring", "ring", "0.25", 75)
        |> Map.merge(%{
          category: "apparel",
          material: "Gold",
          source: "Skyrim",
          description: "A gold ring worn as jewelry."
        }),
        apparel_item("College Robes", "robes", 1, 5)
        |> Map.merge(%{
          category: "apparel",
          material: "Cloth",
          source: "Skyrim",
          description: "Robes associated with students and mages of the College of Winterhold."
        }),
        apparel_item("Fine Clothes", "clothes", 1, 40)
        |> Map.merge(%{
          category: "apparel",
          material: "Cloth",
          source: "Skyrim",
          description: "Fine clothing worn by wealthy citizens and nobles."
        })
      ]
  end

  defp weapon(name, kind, hands, damage, weight, value) do
    %{
      name: name,
      kind: kind,
      hands: hands,
      damage: damage,
      weight: weight,
      value: value
    }
  end

  defp weapon_set(material, source, weapons) do
    Enum.map(weapons, fn weapon ->
      Map.merge(weapon, %{
        category: "weapon",
        material: material,
        source: source,
        description: "#{weapon.name} is a #{material} #{weapon.kind}."
      })
    end)
  end

  defp apparel_item(name, kind, weight, value) do
    %{
      name: name,
      kind: kind,
      hands: "worn",
      weight: weight,
      value: value
    }
  end

  defp apparel_set(material, kind, apparel_items) do
    Enum.map(apparel_items, fn item ->
      Map.merge(item, %{
        category: "apparel",
        material: material,
        source: "Skyrim",
        description: "#{item.name} is #{kind} made in the #{material} style."
      })
    end)
  end

  defp food do
    [
      food_item("Apple", "produce", "0.1", 3, "A common apple eaten as food."),
      food_item("Bread", "baked good", "0.2", 2, "A loaf of bread found across Skyrim."),
      food_item("Cabbage", "produce", "0.25", 2, "A cabbage used as basic food."),
      food_item("Carrot", "produce", "0.1", 1, "A carrot eaten raw or cooked into stews."),
      food_item("Cheese Wheel", "dairy", 2, 13, "A full wheel of cheese."),
      food_item("Eidar Cheese Wedge", "dairy", "0.25", 5, "A wedge of Eidar cheese."),
      food_item("Goat Cheese Wheel", "dairy", 2, 20, "A full wheel of goat cheese."),
      food_item("Grilled Leeks", "cooked meal", "0.1", 2, "Leeks prepared over heat."),
      food_item("Horker Loaf", "cooked meal", 1, 2, "A loaf made from horker meat."),
      food_item("Horse Haunch", "meat", 2, 4, "A large cut of horse meat."),
      food_item("Leg of Goat Roast", "meat", 1, 4, "A roasted leg of goat."),
      food_item("Mammoth Snout", "meat", 3, 6, "A mammoth snout used as food."),
      food_item("Potato", "produce", "0.1", 1, "A staple potato."),
      food_item("Salmon Steak", "fish", "0.1", 4, "A cooked cut of salmon."),
      food_item("Tomato", "produce", "0.1", 4, "A tomato used in food and cooking."),
      food_item("Vegetable Soup", "soup", "0.5", 5, "A cooked soup made from vegetables."),
      food_item("Venison Chop", "meat", 2, 5, "A cooked cut of venison."),
      food_item("Sweet Roll", "baked good", "0.1", 2, "A sweet baked roll.")
    ]
  end

  defp food_item(name, kind, weight, value, description) do
    %{
      name: name,
      category: "food",
      kind: kind,
      weight: weight,
      value: value,
      source: "Skyrim",
      description: description
    }
  end

  defp occupations do
    [
      occupation(
        "Archivist",
        "lore",
        "Keeper of records, old histories, and dangerous knowledge."
      ),
      occupation(
        "Assassin",
        "underworld",
        "Contract killer operating through secrecy and ritual."
      ),
      occupation("Bard", "civic", "Performer, storyteller, singer, or court entertainer."),
      occupation("Blade", "military", "Dragon hunter or agent tied to the old Blades order."),
      occupation(
        "Commander",
        "military",
        "Military leader responsible for strategy and command."
      ),
      occupation(
        "Companion",
        "martial",
        "Warrior attached to a martial fellowship or honor order."
      ),
      occupation("Court Wizard", "court", "Arcane advisor serving a ruler's court."),
      occupation("Dragon", "legendary", "Ancient dragon with power, language, and territory."),
      occupation("Greybeard", "religious", "Monk devoted to the Voice and mountain discipline."),
      occupation("High King", "royal", "Provincial monarch or equivalent sovereign."),
      occupation("Housecarl", "court", "Sworn household guard and personal retainer."),
      occupation("Innkeeper", "trade", "Keeper of an inn, tavern, or public house."),
      occupation(
        "Jarl",
        "nobility",
        "Hold ruler responsible for law, court, taxes, and defense."
      ),
      occupation("Mage", "arcane", "Practitioner of formal or practical magic."),
      occupation("Merchant", "trade", "Trader, shopkeeper, factor, or market operator."),
      occupation("Noble", "nobility", "Influential landholder or aristocrat."),
      occupation("Smith", "trade", "Blacksmith, armorer, or metalworker."),
      occupation(
        "Steward",
        "court",
        "Administrative official managing a ruler's court and business."
      ),
      occupation("Thief", "underworld", "Burglary, smuggling, debt work, or criminal influence."),
      occupation("Vampire", "supernatural", "Undead bloodline member or vampire court actor."),
      occupation("Vampire Hunter", "military", "Hunter trained to fight vampires and undead.")
    ]
  end

  defp occupation(name, category, description) do
    %{name: name, category: category, description: description}
  end

  defp guilds do
    [
      %{
        name: "Bards College",
        description:
          "A Solitude college preserving song, performance, history, and noble patronage.",
        headquarters: "Solitude",
        alignment: "college"
      },
      %{
        name: "Blades",
        description:
          "An old dragon-hunting order once tied to imperial service and hidden fortresses.",
        leader: "Delphine",
        headquarters: "Sky Haven Temple",
        alignment: "order"
      },
      %{
        name: "College of Winterhold",
        description:
          "A northern academy for mages studying old ruins, spellcraft, and dangerous relics.",
        leader: "Savos Aren",
        headquarters: "College of Winterhold",
        alignment: "college"
      },
      %{
        name: "Companions",
        description:
          "A Whiterun warrior fellowship rooted in honor, contracts, and the legacy of Ysgramor.",
        leader: "Kodlak Whitemane",
        headquarters: "Jorrvaskr",
        alignment: "warrior fellowship"
      },
      %{
        name: "Dark Brotherhood",
        description:
          "A secretive assassin order bound by ritual, contracts, and whispered murder.",
        leader: "Astrid",
        patron: "Sithis",
        headquarters: "Dark Brotherhood Sanctuary",
        alignment: "assassin order"
      },
      %{
        name: "Dawnguard",
        description:
          "A fortress-based order dedicated to hunting vampires and guarding the living.",
        leader: "Isran",
        headquarters: "Fort Dawnguard",
        alignment: "vampire hunters"
      },
      %{
        name: "Greybeards",
        description:
          "Monks of High Hrothgar devoted to the Voice, restraint, and mountain isolation.",
        leader: "Arngeir",
        headquarters: "High Hrothgar",
        alignment: "monastic order"
      },
      %{
        name: "Imperial Legion",
        description:
          "The imperial army enforcing imperial law, order, and military command in Skyrim.",
        leader: "General Tullius",
        headquarters: "Castle Dour",
        alignment: "imperial military"
      },
      %{
        name: "Stormcloaks",
        description:
          "A rebellion of Nordic loyalists fighting for Skyrim's independence and old customs.",
        leader: "Ulfric Stormcloak",
        patron: "Talos",
        headquarters: "Palace of the Kings",
        alignment: "rebellion"
      },
      %{
        name: "Thieves Guild",
        description:
          "A Riften criminal guild built around burglary, influence, debts, and underworld favors.",
        leader: "Mercer Frey",
        patron: "Nocturnal",
        headquarters: "The Ragged Flagon",
        alignment: "criminal guild"
      },
      %{
        name: "Volkihar Clan",
        description: "A powerful vampire court ruling from a northern island castle.",
        leader: "Harkon",
        patron: "Molag Bal",
        headquarters: "Castle Volkihar",
        alignment: "vampire clan"
      }
    ]
  end

  defp characters do
    [
      character(
        "Ulfric Stormcloak",
        "Jarl of Windhelm",
        "Jarl",
        "Nord",
        "Stormcloaks",
        "Windhelm",
        "Stormcloak",
        inventory: [
          inventory_item("Weapons", "Steel Sword", true, "Jarl's sidearm."),
          inventory_item("Apparel", "Steel Armor", true, "War leader armor."),
          inventory_item("Apparel", "Amulet of Talos", true, "Religious symbol.")
        ]
      ),
      character(
        "General Tullius",
        "Military Governor",
        "Commander",
        "Imperial",
        "Imperial Legion",
        "Solitude",
        "Imperial",
        inventory: [
          inventory_item("Weapons", "Steel Sword", true, "Imperial command sidearm."),
          inventory_item("Apparel", "Steel Armor", true, "Military armor.")
        ]
      ),
      character(
        "Elisif the Fair",
        "Jarl of Solitude",
        "Jarl",
        "Nord",
        nil,
        "Solitude",
        "Imperial"
      ),
      character(
        "Balgruuf the Greater",
        "Jarl of Whiterun",
        "Jarl",
        "Nord",
        nil,
        "Whiterun",
        "Neutral",
        inventory: [
          inventory_item("Weapons", "Steel Sword", true, "Hold ruler sidearm."),
          inventory_item("Apparel", "Fine Clothes", true, "Court clothing.")
        ]
      ),
      character("Laila Law-Giver", "Jarl of Riften", "Jarl", "Nord", nil, "Riften", "Stormcloak"),
      character("Igmund", "Jarl of Markarth", "Jarl", "Nord", nil, "Markarth", "Imperial"),
      character("Korir", "Jarl of Winterhold", "Jarl", "Nord", nil, "Winterhold", "Stormcloak"),
      character(
        "Skald the Elder",
        "Jarl of Dawnstar",
        "Jarl",
        "Nord",
        nil,
        "Dawnstar",
        "Stormcloak"
      ),
      character(
        "Idgrod Ravencrone",
        "Jarl of Morthal",
        "Jarl",
        "Nord",
        nil,
        "Morthal",
        "Imperial"
      ),
      character("Siddgeir", "Jarl of Falkreath", "Jarl", "Nord", nil, "Falkreath", "Imperial"),
      character(
        "Delphine",
        nil,
        "Blade",
        "Breton",
        "Blades",
        "Riverwood",
        nil,
        inventory: [
          inventory_item("Weapons", "Steel Sword", true, "Blade weapon."),
          inventory_item("Weapons", "Steel Dagger", false, "Backup weapon.")
        ]
      ),
      character("Esbern", nil, "Archivist", "Nord", "Blades", "Sky Haven Temple", nil),
      character("Arngeir", nil, "Greybeard", "Nord", "Greybeards", "High Hrothgar", nil),
      character("Paarthurnax", nil, "Dragon", nil, nil, "The Throat of the World", nil),
      character("Kodlak Whitemane", "Harbinger", "Companion", "Nord", "Companions", nil, nil),
      character(
        "Savos Aren",
        "Arch-Mage",
        "Mage",
        "Dunmer",
        "College of Winterhold",
        "College of Winterhold",
        nil,
        inventory: [
          inventory_item("Apparel", "College Robes", true, "College robes."),
          inventory_item("Food", "Bread", false, "Travel ration.")
        ]
      ),
      character(
        "Astrid",
        nil,
        "Assassin",
        "Nord",
        "Dark Brotherhood",
        "Dark Brotherhood Sanctuary",
        nil
      ),
      character("Mercer Frey", "Guildmaster", "Thief", "Breton", "Thieves Guild", nil, nil),
      character("Brynjolf", nil, "Thief", "Nord", "Thieves Guild", "Riften", nil),
      character("Isran", nil, "Vampire Hunter", "Redguard", "Dawnguard", nil, nil),
      character(
        "Serana",
        nil,
        "Vampire",
        "Nord",
        "Volkihar Clan",
        nil,
        nil,
        inventory: [
          inventory_item("Weapons", "Elven Dagger", true, "Personal dagger."),
          inventory_item("Apparel", "Fine Clothes", true, "Noble clothing.")
        ]
      ),
      character(
        "Harkon",
        "Lord",
        "Vampire Lord",
        "Nord",
        "Volkihar Clan",
        "Castle Volkihar",
        nil
      ),
      character("Maven Black-Briar", nil, "Noble", "Nord", nil, "Riften", nil),
      character("Torygg", "High King", "High King", "Nord", nil, "Solitude", "Imperial",
        status: "dead"
      ),
      character("Jorleif", nil, "Steward", "Nord", nil, "Windhelm", "Stormcloak"),
      character("Wuunferth the Unliving", nil, "Court Wizard", "Nord", nil, "Windhelm", nil),
      character("Nenya", nil, "Steward", "Altmer", nil, "Falkreath", "Imperial"),
      character("Helvard", nil, "Housecarl", "Nord", nil, "Falkreath", "Imperial"),
      character("Falk Firebeard", nil, "Steward", "Nord", nil, "Solitude", "Imperial"),
      character("Sybille Stentor", nil, "Court Wizard", "Breton", nil, "Solitude", nil),
      character("Bolgeir Bearclaw", nil, "Housecarl", "Nord", nil, "Solitude", "Imperial"),
      character("Aslfur", nil, "Steward", "Nord", nil, "Morthal", "Imperial"),
      character("Gorm", nil, "Housecarl", "Nord", nil, "Morthal", "Imperial"),
      character("Bulrek", nil, "Steward", "Nord", nil, "Dawnstar", "Stormcloak"),
      character("Madena", nil, "Court Wizard", "Breton", nil, "Dawnstar", nil),
      character("Jod", nil, "Housecarl", "Nord", nil, "Dawnstar", "Stormcloak"),
      character("Raerek", nil, "Steward", "Nord", nil, "Markarth", "Imperial"),
      character("Calcelmo", nil, "Court Wizard", "Altmer", nil, "Markarth", nil),
      character("Faleen", nil, "Housecarl", "Redguard", nil, "Markarth", "Imperial"),
      character("Anuriel", nil, "Steward", "Bosmer", nil, "Riften", "Stormcloak"),
      character("Wylandriah", nil, "Court Wizard", "Bosmer", nil, "Riften", nil),
      character("Proventus Avenicci", nil, "Steward", "Imperial", nil, "Whiterun", "Neutral"),
      character("Farengar Secret-Fire", nil, "Court Wizard", "Nord", nil, "Whiterun", nil),
      character("Irileth", nil, "Housecarl", "Dunmer", nil, "Whiterun", "Neutral"),
      character("Malur Seloth", nil, "Steward", "Dunmer", nil, "Winterhold", "Stormcloak"),
      character("Thaena", nil, "Housecarl", "Nord", nil, "Winterhold", "Stormcloak")
    ]
  end

  defp political_offices do
    [
      province_office(
        "Skyrim",
        "High King",
        "Torygg",
        "Imperial",
        "The late High King of Skyrim."
      ),
      province_office(
        "Skyrim",
        "Imperial General",
        "General Tullius",
        "Imperial",
        "Imperial Legion command in Skyrim."
      ),
      province_office(
        "Skyrim",
        "Stormcloak General",
        "Ulfric Stormcloak",
        "Stormcloak",
        "Stormcloak rebellion command in Skyrim."
      ),
      hold_office("Eastmarch", "Jarl", "Ulfric Stormcloak", "Stormcloak"),
      hold_office("Eastmarch", "Steward", "Jorleif", "Stormcloak"),
      hold_office("Eastmarch", "Court Wizard", "Wuunferth the Unliving", nil),
      hold_office("Falkreath", "Jarl", "Siddgeir", "Imperial"),
      hold_office("Falkreath", "Steward", "Nenya", "Imperial"),
      hold_office("Falkreath", "Housecarl", "Helvard", "Imperial"),
      hold_office("Haafingar", "Jarl", "Elisif the Fair", "Imperial"),
      hold_office("Haafingar", "Steward", "Falk Firebeard", "Imperial"),
      hold_office("Haafingar", "Court Wizard", "Sybille Stentor", nil),
      hold_office("Haafingar", "Housecarl", "Bolgeir Bearclaw", "Imperial"),
      hold_office("Hjaalmarch", "Jarl", "Idgrod Ravencrone", "Imperial"),
      hold_office("Hjaalmarch", "Steward", "Aslfur", "Imperial"),
      hold_office("Hjaalmarch", "Housecarl", "Gorm", "Imperial"),
      hold_office("The Pale", "Jarl", "Skald the Elder", "Stormcloak"),
      hold_office("The Pale", "Steward", "Bulrek", "Stormcloak"),
      hold_office("The Pale", "Court Wizard", "Madena", nil),
      hold_office("The Pale", "Housecarl", "Jod", "Stormcloak"),
      hold_office("The Reach", "Jarl", "Igmund", "Imperial"),
      hold_office("The Reach", "Steward", "Raerek", "Imperial"),
      hold_office("The Reach", "Court Wizard", "Calcelmo", nil),
      hold_office("The Reach", "Housecarl", "Faleen", "Imperial"),
      hold_office("The Rift", "Jarl", "Laila Law-Giver", "Stormcloak"),
      hold_office("The Rift", "Steward", "Anuriel", "Stormcloak"),
      hold_office("The Rift", "Court Wizard", "Wylandriah", nil),
      hold_office("Whiterun", "Jarl", "Balgruuf the Greater", "Neutral"),
      hold_office("Whiterun", "Steward", "Proventus Avenicci", "Neutral"),
      hold_office("Whiterun", "Court Wizard", "Farengar Secret-Fire", nil),
      hold_office("Whiterun", "Housecarl", "Irileth", "Neutral"),
      hold_office("Winterhold", "Jarl", "Korir", "Stormcloak"),
      hold_office("Winterhold", "Steward", "Malur Seloth", "Stormcloak"),
      hold_office("Winterhold", "Housecarl", "Thaena", "Stormcloak")
    ]
  end

  defp province_office(province, office, character, politics, description) do
    %{
      scope: "province",
      province: province,
      office: office,
      character: character,
      politics: politics,
      description: description
    }
  end

  defp hold_office(hold, office, character, politics) do
    %{
      scope: "hold",
      hold: hold,
      office: office,
      character: character,
      politics: politics,
      description: "#{office} of #{hold}."
    }
  end

  defp character(name, title, role, race, guild, home_location, politics, opts \\ []) do
    inventory = Keyword.get(opts, :inventory, [])

    %{
      name: name,
      title: title,
      role: role,
      politics: politics,
      race: race,
      guild: guild,
      home_location: home_location,
      occupations: occupations_for_role(role),
      primary_occupation: primary_occupation_for_role(role),
      status: Keyword.get(opts, :status, "alive"),
      inventory_categories: inventory_categories_for(inventory),
      inventory_items: inventory_items_for(inventory),
      description: character_description(name, role)
    }
  end

  defp inventory_item(category, item, equipped, notes) do
    %{
      category: category,
      item: item,
      quantity: 1,
      equipped: equipped,
      notes: notes
    }
  end

  defp inventory_categories_for(inventory) do
    inventory
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.with_index(1)
    |> Enum.map(fn {category, position} ->
      %{
        name: category,
        position: position,
        description: "#{category} carried by this character."
      }
    end)
  end

  defp inventory_items_for(inventory) do
    Enum.map(inventory, fn item ->
      Map.put_new(item, :quantity, 1)
    end)
  end

  defp occupations_for_role(nil) do
    []
  end

  defp occupations_for_role(role) do
    role
    |> primary_occupation_for_role()
    |> List.wrap()
  end

  defp primary_occupation_for_role(nil) do
    nil
  end

  defp primary_occupation_for_role("Vampire Lord") do
    "Vampire"
  end

  defp primary_occupation_for_role(role) do
    role
  end

  defp character_description(name, nil) do
    "#{name} is a notable figure in Skyrim."
  end

  defp character_description(name, role) do
    "#{name} is a notable #{String.downcase(role)} in Skyrim."
  end

  defp races do
    [
      %{
        name: "Altmer",
        description: "High elves known for old bloodlines, formal learning, and powerful magic.",
        traits: [
          power("Highborn", "Regenerate magicka rapidly for a short time."),
          perk("Fortify Magicka", "Begin with a larger reserve of magicka.")
        ]
      },
      %{
        name: "Argonian",
        description: "Scaled folk from southern marshlands, shaped by waterways and survival.",
        traits: [
          power("Histskin", "Regenerate health rapidly for a short time."),
          perk("Resist Disease", "Resist disease more effectively than most peoples."),
          perk("Waterbreathing", "Breathe underwater.")
        ]
      },
      %{
        name: "Bosmer",
        description: "Wood elves tied to forest life, hunting traditions, and nimble movement.",
        traits: [
          power("Command Animal", "Turn a nearby animal into a temporary ally."),
          perk(
            "Resist Disease and Poison",
            "Resist disease and poison through hardy forest blood."
          )
        ]
      },
      %{
        name: "Breton",
        description:
          "A people of mixed ancestry with courtly customs and strong magical aptitude.",
        traits: [
          power("Dragonskin", "Absorb hostile magic for a short time."),
          perk("Magic Resistance", "Resist incoming magical effects.")
        ]
      },
      %{
        name: "Dunmer",
        description:
          "Dark elves marked by ashland heritage, ancestor customs, and hard politics.",
        traits: [
          power("Ancestor's Wrath", "Surround yourself with fire that harms nearby enemies."),
          perk("Resist Fire", "Resist fire through ashland ancestry.")
        ]
      },
      %{
        name: "Imperial",
        description: "Cosmopolitan citizens of empire, trade, law, soldiery, and administration.",
        traits: [
          power("Voice of the Emperor", "Calm nearby people for a short time."),
          perk("Imperial Luck", "Find more coin than most adventurers.")
        ]
      },
      %{
        name: "Khajiit",
        description:
          "Feline wanderers, caravaneers, traders, and scouts from warm southern lands.",
        traits: [
          power("Night Eye", "See clearly in darkness for a short time."),
          perk("Claws", "Fight effectively with natural claws when unarmed.")
        ]
      },
      %{
        name: "Nord",
        description: "Northern humans shaped by cold holds, old songs, clan honor, and warcraft.",
        traits: [
          power("Battle Cry", "Force nearby enemies to flee for a short time."),
          perk("Resist Frost", "Resist frost through northern hardiness.")
        ]
      },
      %{
        name: "Orc",
        description:
          "Stronghold people known for smithing, endurance, direct speech, and martial craft.",
        traits: [
          power("Berserker Rage", "Deal more damage and take less damage for a short time.")
        ]
      },
      %{
        name: "Redguard",
        description:
          "Desert-born warriors and sailors with deep sword traditions and independence.",
        traits: [
          power("Adrenaline Rush", "Regenerate stamina rapidly for a short time."),
          perk("Resist Poison", "Resist poison through desert-born endurance.")
        ]
      }
    ]
  end

  defp power(name, description) do
    %{category: "power", name: name, description: description}
  end

  defp perk(name, description) do
    %{category: "perk", name: name, description: description}
  end

  defp location_types do
    [
      %{
        name: "Camp",
        description: "Temporary or fortified outdoor shelters.",
        children: [
          %{name: "Imperial Camp", description: "Military camps held by imperial forces."},
          %{name: "Stormcloak Camp", description: "Military camps held by rebel forces."},
          %{name: "Giant Camp", description: "Open camps dominated by giants and mammoths."}
        ]
      },
      %{name: "Castle", description: "Fortified noble or military seats."},
      %{name: "Cave", description: "Natural underground places and lairs."},
      %{name: "Cemetery", description: "Burial grounds and graveyards."},
      %{name: "City", description: "Major walled or politically central settlements."},
      %{name: "Clearing", description: "Open wilderness clearings."},
      %{name: "Dock", description: "Waterfront landings and working docks."},
      %{name: "Farm", description: "Rural farms and steadings."},
      %{name: "Fort", description: "Military forts, keeps, and redoubts."},
      %{name: "Grove", description: "Distinct wooded sacred or natural places."},
      %{name: "Guild Hall", description: "Headquarters for guilds, orders, and companies."},
      %{
        name: "House",
        description: "Private homes and residences.",
        children: [
          %{name: "House (Ownable)", description: "Residences that can belong to a protagonist."}
        ]
      },
      %{name: "Inn", description: "Taverns, inns, and public houses."},
      %{name: "Jail", description: "Prisons and holding cells."},
      %{name: "Landmark", description: "Named visible places used for orientation."},
      %{name: "Library", description: "Libraries, archives, and collections of learning."},
      %{name: "Lighthouse", description: "Coastal towers and beacons."},
      %{name: "Mine", description: "Ore mines and excavation sites."},
      %{
        name: "Mound",
        description: "Burial mounds and raised ancient sites.",
        children: [
          %{name: "Dragon Mound", description: "Ancient burial mounds tied to dragons."}
        ]
      },
      %{name: "Orc Stronghold", description: "Fortified strongholds held by orc clans."},
      %{name: "Pass", description: "Mountain passes and major crossings."},
      %{name: "Point of Interest", description: "Notable sites that do not fit another type."},
      %{
        name: "Ruin",
        description: "Ancient, collapsed, or abandoned structures.",
        children: [
          %{name: "Dwemer Ruin", description: "Deep stone ruins of a vanished civilization."},
          %{name: "Nordic Ruin", description: "Old northern barrows, halls, and tombs."}
        ]
      },
      %{name: "Settlement", description: "Small inhabited communities."},
      %{name: "Shack", description: "Small isolated huts and cabins."},
      %{name: "Shipwreck", description: "Wrecked ships and stranded vessels."},
      %{
        name: "Shrine",
        description: "Sacred places and devotional sites.",
        children: [
          %{name: "Daedric Shrine", description: "Shrines dedicated to dark or alien powers."}
        ]
      },
      %{name: "Stable", description: "Horse stables and road services."},
      %{name: "Standing Stone", description: "Ancient stones with ritual or magical importance."},
      %{name: "Temple", description: "Formal religious halls and temples."},
      %{name: "Town", description: "Established towns smaller than major cities."},
      %{
        name: "Tower",
        description: "Watchtowers and isolated vertical fortifications.",
        children: [
          %{name: "Imperial Tower", description: "Watchtowers built or held by imperial forces."},
          %{name: "Nordic Tower", description: "Old northern towers and overlooks."}
        ]
      },
      %{
        name: "Mill",
        description: "Working mills and production sites.",
        children: [
          %{name: "Wheat Mill", description: "Mills for grain and flour."},
          %{name: "Wood Mill", description: "Sawmills and lumber operations."}
        ]
      },
      %{name: "Word Wall", description: "Ancient walls carved with words of power."},
      %{
        name: "Lair",
        description: "Dangerous dens and monster lairs.",
        children: [
          %{name: "Dragon Lair", description: "High places and nests claimed by dragons."}
        ]
      }
    ]
  end

  defp holds do
    [
      hold(
        "Eastmarch",
        "Windhelm",
        "Volcanic eastern lands marked by hot springs, old Nordic power, and hard stone roads.",
        :volcanic,
        :volcanic,
        [
          location("Kynesgrove", "Settlement", "A mining village south of Windhelm."),
          location(
            "Darkwater Crossing",
            "Settlement",
            "A mining settlement near the hot springs."
          ),
          location("Mixwater Mill", "Wood Mill", "A lumber mill on the White River."),
          location("Fort Amol", "Fort", "A fort on the road through southern Eastmarch."),
          location("Morvunskar", "Fort", "A ruined fort in the eastern volcanic plain."),
          location("Cronvangr Cave", "Cave", "A cave in the hot springs region."),
          location("Eldergleam Sanctuary", "Grove", "A sacred grove around the Eldergleam tree."),
          location("Steamcrag Camp", "Giant Camp", "A giant camp in the sulphur pools."),
          location("Gallows Rock", "Fort", "A fortified ruin used by hostile forces."),
          location("Bonestrewn Crest", "Dragon Lair", "A dragon lair in the volcanic flats.")
        ]
      ),
      hold(
        "Falkreath",
        "Falkreath",
        "Forested southern lands of hunting roads, graveyards, border passes, and old watchtowers.",
        :forest,
        :temperate,
        [
          location("Helgen", "Town", "A fortified town near the southern border."),
          location("Half-Moon Mill", "Wood Mill", "A sawmill on Lake Ilinalta."),
          location("Pinewatch", "House", "A remote house with hidden trouble beneath it."),
          location(
            "Dark Brotherhood Sanctuary",
            "Landmark",
            "A hidden sanctuary near Falkreath."
          ),
          location("Knifepoint Ridge", "Camp", "A bandit camp and mine in the mountains."),
          location("Glenmoril Coven", "Cave", "A cave associated with a coven of witches."),
          location("Ilinalta's Deep", "Ruin", "A flooded ruin on Lake Ilinalta."),
          location("Roadside Ruins", "Ruin", "Ruins beside the road through the forest."),
          location("Angi's Camp", "Camp", "An isolated mountain camp."),
          location("Falkreath Watchtower", "Tower", "A watchtower overlooking the hold.")
        ]
      ),
      hold(
        "Haafingar",
        "Solitude",
        "A coastal domain of imperial influence, sea trade, steep cliffs, and fortified roads.",
        :coast,
        :coastal,
        [
          location("Dragon Bridge", "Town", "A town beside the great stone bridge."),
          location("Thalmor Embassy", "Fort", "A fortified embassy in the mountains."),
          location("Katla's Farm", "Farm", "A farm outside Solitude."),
          location("Solitude Lighthouse", "Lighthouse", "A lighthouse on the northern coast."),
          location("Wolfskull Cave", "Cave", "A cave beneath ancient ruins."),
          location("Broken Oar Grotto", "Cave", "A coastal cave used by pirates."),
          location("Northwatch Keep", "Fort", "A remote coastal fortress."),
          location("Steepfall Burrow", "Cave", "An icy cave near the sea cliffs."),
          location("Shrine to Meridia", "Daedric Shrine", "A shrine to Meridia above Kilkreath."),
          location("Kilkreath Ruins", "Ruin", "Ancient ruins beneath Meridia's shrine.")
        ]
      ),
      hold(
        "Hjaalmarch",
        "Morthal",
        "Marshland country of fog, fishing villages, old burial grounds, and uneasy waterways.",
        :marsh,
        :wet,
        [
          location("Stonehills", "Settlement", "A small mining settlement in the marshlands."),
          location("Ustengrav", "Nordic Ruin", "An ancient Nordic tomb in the marsh."),
          location("Labyrinthian", "Nordic Ruin", "A vast ancient ruin in the mountains."),
          location("Movarth's Lair", "Cave", "A cave used as a vampire lair."),
          location("Folgunthur", "Nordic Ruin", "A Nordic ruin near the Karth delta."),
          location("Fort Snowhawk", "Fort", "A fort near Morthal."),
          location("Rannveig's Fast", "Nordic Ruin", "A Nordic ruin south of the marsh."),
          location("Cold Rock Pass", "Pass", "A mountain pass into the central hold."),
          location("Crabber's Shanty", "Shack", "A small shack by the marsh water."),
          location("Morthal Cemetery", "Cemetery", "The burial ground of Morthal.")
        ]
      ),
      hold(
        "The Pale",
        "Dawnstar",
        "Northern snowfields, mines, shipwreck coasts, and isolated roads.",
        :snowfield,
        :arctic,
        [
          location("Nightcaller Temple", "Temple", "A temple overlooking Dawnstar."),
          location(
            "Frostflow Lighthouse",
            "Lighthouse",
            "An isolated lighthouse on the northern coast."
          ),
          location("Fort Dunstad", "Fort", "A fort in the snowy interior."),
          location("High Gate Ruins", "Nordic Ruin", "Ancient ruins near the northern coast."),
          location("Iron-Breaker Mine", "Mine", "An iron mine in Dawnstar."),
          location("Quicksilver Mine", "Mine", "A quicksilver mine in Dawnstar."),
          location("Dawnstar Sanctuary", "Landmark", "A hidden sanctuary north of Dawnstar."),
          location("Red Road Pass", "Giant Camp", "A giant camp near the northern road."),
          location("The Tower Stone", "Standing Stone", "A standing stone near the coast."),
          location(
            "Wreck of the Brinehammer",
            "Shipwreck",
            "A wrecked ship off the northern coast."
          )
        ]
      ),
      hold(
        "The Reach",
        "Markarth",
        "Rugged western cliffs, silver mines, river canyons, and contested highlands.",
        :highlands,
        :cold,
        [
          location("Karthwasten", "Settlement", "A mining settlement in the Reach."),
          location("Old Hroldan Inn", "Inn", "An old inn with deep Reach history."),
          location("Kolskeggr Mine", "Mine", "A gold mine east of Markarth."),
          location("Left Hand Mine", "Mine", "A mine outside Markarth."),
          location("Hag Rock Redoubt", "Fort", "A redoubt in the western cliffs."),
          location("Druadach Redoubt", "Camp", "A camp hidden in the Reach."),
          location("Blind Cliff Cave", "Cave", "A cave and tower complex in the hills."),
          location("Sky Haven Temple", "Temple", "An ancient temple in the Karth valley."),
          location("Reachwater Rock", "Cave", "A cave tied to old Nordic legend."),
          location("Deepwood Redoubt", "Fort", "A fortified redoubt in the far Reach.")
        ]
      ),
      hold(
        "The Rift",
        "Riften",
        "Southeastern autumn forests, lake trade, farms, and shadowed crossings.",
        :forest,
        :temperate,
        [
          location("Ivarstead", "Town", "A village at the foot of the mountain road."),
          location("Shor's Stone", "Settlement", "A mining settlement north of Riften."),
          location("Heartwood Mill", "Wood Mill", "A sawmill on Lake Honrich."),
          location("Sarethi Farm", "Farm", "A farm in the Rift countryside."),
          location("Goldenglow Estate", "Farm", "An island estate on Lake Honrich."),
          location("Fort Greenwall", "Fort", "A fort north of Riften."),
          location("Faldar's Tooth", "Fort", "A ruined fort near the lake."),
          location("Broken Helm Hollow", "Cave", "A cave in the southeastern hills."),
          location("Forelhost", "Nordic Ruin", "A Nordic ruin in the mountains."),
          location("Autumnwatch Tower", "Dragon Lair", "A dragon lair above the Rift.")
        ]
      ),
      hold(
        "Whiterun",
        "Whiterun",
        "Central open tundra, farms, trade roads, and watchful barrows.",
        :plains,
        :temperate,
        [
          location("Riverwood", "Town", "A mill town on the White River."),
          location("Rorikstead", "Town", "A farming village in western Whiterun."),
          location("Fort Greymoor", "Fort", "A fort west of Whiterun."),
          location("Bleak Falls Barrow", "Nordic Ruin", "A Nordic barrow above Riverwood."),
          location("Dustman's Cairn", "Nordic Ruin", "A tomb in the central tundra."),
          location("Valtheim Towers", "Tower", "Twin towers on the road east of Whiterun."),
          location("Halted Stream Camp", "Camp", "A bandit camp north of Whiterun."),
          location("Silent Moons Camp", "Camp", "A camp near the Lunar Forge."),
          location("Honningbrew Meadery", "Farm", "A meadery outside Whiterun."),
          location("Pelagia Farm", "Farm", "A farm just beyond Whiterun's walls."),
          location("High Hrothgar", "Temple", "The monastery of the Greybeards."),
          location("The Throat of the World", "Landmark", "The highest mountain in Skyrim.")
        ]
      ),
      hold(
        "Winterhold",
        "Winterhold",
        "Ruined northern ice, storms, old learning, and a coastline shaped by disaster.",
        :snowfield,
        :arctic,
        [
          location(
            "College of Winterhold",
            "Guild Hall",
            "A college of magic overlooking the sea."
          ),
          location("Saarthal", "Nordic Ruin", "An ancient Nordic excavation site."),
          location("Yngol Barrow", "Nordic Ruin", "A coastal Nordic barrow."),
          location("Snow Veil Sanctum", "Nordic Ruin", "A Nordic ruin in the snowy hills."),
          location("Hob's Fall Cave", "Cave", "An icy cave on the northern coast."),
          location("Driftshade Refuge", "Fort", "A fortified refuge in the snow."),
          location("Sightless Pit", "Cave", "A deep pit leading into old ruins."),
          location("Shrine of Azura", "Daedric Shrine", "A great shrine overlooking Winterhold."),
          location("Alftand", "Dwemer Ruin", "A Dwemer ruin beneath the ice."),
          location("Wreck of the Winter War", "Shipwreck", "A shipwreck on the frozen coast.")
        ]
      )
    ]
  end

  defp hold(name, capital, description, terrain, climate, locations) do
    %{
      name: name,
      description: description,
      terrain: terrain,
      climate: climate,
      capital: capital,
      commerce_entries: commerce_entries_for_hold(name),
      locations: [location(capital, "City", "The capital settlement of #{name}.") | locations]
    }
  end

  defp commerce_entries_for_hold("Eastmarch") do
    [
      commerce(
        "Windhelm market dues",
        "income",
        "market",
        950,
        "monthly",
        "Trade inside Windhelm."
      ),
      commerce(
        "Mine and mill tariffs",
        "income",
        "industry",
        700,
        "monthly",
        "Mining settlements and timber along the White River."
      ),
      commerce(
        "Garrison wages",
        "expense",
        "military",
        850,
        "monthly",
        "Hold guards and Stormcloak patrols."
      ),
      commerce(
        "Road maintenance",
        "expense",
        "infrastructure",
        280,
        "monthly",
        "Stone roads through volcanic terrain."
      )
    ]
  end

  defp commerce_entries_for_hold("Falkreath") do
    [
      commerce(
        "Timber levies",
        "income",
        "industry",
        620,
        "monthly",
        "Mills and forest holdings."
      ),
      commerce(
        "Hunting permits",
        "income",
        "trade",
        260,
        "monthly",
        "Hunters and trappers working the pine forests."
      ),
      commerce(
        "Cemetery upkeep",
        "expense",
        "civic",
        180,
        "monthly",
        "Burial grounds and shrine care."
      ),
      commerce(
        "Border patrols",
        "expense",
        "military",
        520,
        "monthly",
        "Road watches near Helgen and mountain passes."
      )
    ]
  end

  defp commerce_entries_for_hold("Haafingar") do
    [
      commerce(
        "Solitude port customs",
        "income",
        "trade",
        1_600,
        "monthly",
        "Harbor duties and coastal trade."
      ),
      commerce(
        "Imperial contracts",
        "income",
        "military",
        1_100,
        "monthly",
        "Legion provisioning and court contracts."
      ),
      commerce(
        "Lighthouse and dock upkeep",
        "expense",
        "infrastructure",
        420,
        "monthly",
        "Coastal navigation and port maintenance."
      ),
      commerce(
        "Court administration",
        "expense",
        "civic",
        700,
        "monthly",
        "Blue Palace offices and court staff."
      )
    ]
  end

  defp commerce_entries_for_hold("Hjaalmarch") do
    [
      commerce(
        "Marsh fishing tithes",
        "income",
        "food",
        340,
        "monthly",
        "Fishing, crabbing, and marsh harvests."
      ),
      commerce(
        "Stonehills mine tax",
        "income",
        "industry",
        420,
        "monthly",
        "Mining revenue from the marsh settlement."
      ),
      commerce(
        "Causeway upkeep",
        "expense",
        "infrastructure",
        310,
        "monthly",
        "Roadwork through wet ground and fog."
      ),
      commerce(
        "Guard watches",
        "expense",
        "military",
        360,
        "monthly",
        "Patrols around Morthal and the marsh."
      )
    ]
  end

  defp commerce_entries_for_hold("The Pale") do
    [
      commerce(
        "Dawnstar mine revenue",
        "income",
        "industry",
        820,
        "monthly",
        "Iron and quicksilver mining in Dawnstar."
      ),
      commerce(
        "Northern harbor dues",
        "income",
        "trade",
        500,
        "monthly",
        "Cold-water trade and fishing boats."
      ),
      commerce(
        "Shipwreck salvage claims",
        "income",
        "salvage",
        180,
        "monthly",
        "Registered salvage from the northern coast."
      ),
      commerce(
        "Snow road patrols",
        "expense",
        "military",
        560,
        "monthly",
        "Guard patrols across exposed northern roads."
      )
    ]
  end

  defp commerce_entries_for_hold("The Reach") do
    [
      commerce(
        "Silver-Blood mine tax",
        "income",
        "industry",
        1_450,
        "monthly",
        "Silver and gold mining around Markarth."
      ),
      commerce(
        "Karth caravan tolls",
        "income",
        "trade",
        520,
        "monthly",
        "Trade moving through western passes."
      ),
      commerce(
        "Forsworn suppression",
        "expense",
        "military",
        920,
        "monthly",
        "Redoubt patrols and guard deployments."
      ),
      commerce(
        "Stonework upkeep",
        "expense",
        "infrastructure",
        360,
        "monthly",
        "Dwemer stone roads, gates, and city structures."
      )
    ]
  end

  defp commerce_entries_for_hold("The Rift") do
    [
      commerce(
        "Riften market taxes",
        "income",
        "market",
        980,
        "monthly",
        "Market stalls, docks, and lake trade."
      ),
      commerce(
        "Farm and mead levies",
        "income",
        "food",
        720,
        "monthly",
        "Farms, estates, and mead production around Lake Honrich."
      ),
      commerce(
        "Guard stipends",
        "expense",
        "military",
        620,
        "monthly",
        "Riften guards and road patrols."
      ),
      commerce(
        "Canal and dock maintenance",
        "expense",
        "infrastructure",
        260,
        "monthly",
        "Waterfront upkeep inside Riften."
      )
    ]
  end

  defp commerce_entries_for_hold("Whiterun") do
    [
      commerce(
        "Plains farm tithe",
        "income",
        "food",
        900,
        "monthly",
        "Grain, livestock, and farm trade across the tundra."
      ),
      commerce(
        "Central road tolls",
        "income",
        "trade",
        760,
        "monthly",
        "Caravans crossing Skyrim's central roads."
      ),
      commerce(
        "Meadery excise",
        "income",
        "market",
        360,
        "monthly",
        "Duties from mead and tavern supply."
      ),
      commerce(
        "Watchtower garrisons",
        "expense",
        "military",
        680,
        "monthly",
        "Western Watchtower, road guards, and hold patrols."
      )
    ]
  end

  defp commerce_entries_for_hold("Winterhold") do
    [
      commerce(
        "College service trade",
        "income",
        "education",
        520,
        "monthly",
        "Supplies, lodging, and services around the College."
      ),
      commerce(
        "Coastal salvage",
        "income",
        "salvage",
        240,
        "monthly",
        "Recovered goods from wrecks and storm-torn shores."
      ),
      commerce(
        "Storm damage repair",
        "expense",
        "infrastructure",
        460,
        "monthly",
        "Repairs from ice, wind, and coastal collapse."
      ),
      commerce(
        "Sparse guard budget",
        "expense",
        "military",
        300,
        "monthly",
        "Small patrol and town guard costs."
      )
    ]
  end

  defp commerce_entries_for_hold(_hold) do
    []
  end

  defp commerce(name, kind, category, amount, frequency, description) do
    %{
      name: name,
      kind: kind,
      category: category,
      amount: amount,
      currency: "Septims",
      frequency: frequency,
      description: description
    }
  end

  defp location(name, type, description) do
    %{
      name: name,
      type: type,
      description: description
    }
  end
end
