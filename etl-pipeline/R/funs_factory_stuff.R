suppressPackageStartupMessages(library(dplyr))

# All possible races
all_races <- readr::read_csv(
  "lookup_tables/district_race_lookup.csv",
  show_col_types = FALSE
)

# Backend tibbles for static branching
# Congressional races, with targets-friendly name prefixes (congress_10, etc.)
all_races_congressional <- all_races |> 
  distinct(race_id) |> 
  filter(race_id %in% 10:11) |> 
  mutate(target_name = glue::glue("congress_{race_id}"))

# District races, with targets-friendly name prefixes (district_race_23, etc.)
all_races_districts <- all_races |> 
  filter(race_id >= 20) |> 
  mutate(target_name = glue::glue("district_race_{race_id}"))

# Congressional race targets (results, maps, and tables)
congressional_things <- list(
  tar_map(
    values = all_races_congressional,
    names = target_name,
    descriptions = NULL,

    tar_target(
      results,
      parse_congressional(db_results, race_id)
    ),
    tar_target(
      map,
      make_map(results, maps_districts, party_colors)
    ),
    tar_target(
      table,
      make_race_table(results, party_colors)
    )
  )
)

# District race targets (results, maps, and tables)
district_things <- list(
  tar_map(
    values = all_races_districts,
    names = target_name,
    descriptions = NULL,

    tar_target(
      results,
      parse_district(db_results, race_id)
    ),
    tar_target(
      map,
      make_map(results, maps_districts, party_colors)
    ),
    tar_target(
      table,
      make_race_table(results, party_colors)
    )
  )
)
