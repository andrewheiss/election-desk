library(targets)
library(tarchetypes)

# Set target options
tar_option_set(
  # Packages that all target functions have access to
  packages = c("dplyr", "readr", "tidyr", "purrr"),
  # Store finished targets with qs instead of rds
  format = "qs"
)

# Set this to either "aws" to upload specific targets to AWs, or to "local" to
# keep final files on the computer
remote_repo <- "local"
#
# If using AWS, uncomment this to configure the AWS data store
# tar_option_set(
#   resources = tar_resources(
#     aws = tar_resources_aws(
#       bucket = Sys.getenv("S3_BUCKET"),
#       prefix = Sys.getenv("S3_PREFIX"),
#       verbose = FALSE
#     )
#   )
# )

# Source all the R scripts in the R/ folder
tar_source()

# TODO: Add README
# TODO: Add cronjob timing explanation to README
# TODO: Add S3 scaffolding to website side
# TODO: Deploy to github pages

# Actual pipeline
list(
  # General setup ----
  tar_target(n_races_to_change, 3),
  tar_target(candidate_lookup, generate_contestants()),
  tar_target(results_raw, generate_results(candidate_lookup)),
  tar_target(district_race_lookup, save_district_race_lookup(results_raw), format = "file"),
  tar_force(
    results_updated,
    update_results(
      results_raw,
      n_races_to_change = n_races_to_change
    ),
    force = n_races_to_change > 0
  ),
  tar_target(party_colors, make_colors()),

  ## DB for testing ----
  tar_target(
    testing_db,
    populate_testing_db(candidate_lookup, results_updated)
  ),

  ## Map files ----
  tar_target(maps_districts, make_district_maps()),

  # Get data from database ----
  tar_change(
    db_results,
    get_from_db(testing_db),
    change = check_db_update()
  ),
  tar_change(
    last_updated,
    check_db_update(),
    change = check_db_update(),
    repository = remote_repo
  ),

  # Create maps and tables for each race ----
  ## Presidential race ----
  tar_target(results_presidential, parse_presidential(db_results)),
  tar_target(
    presidential_map,
    make_map(results_presidential, maps_districts, party_colors),
    repository = remote_repo
  ),
  tar_target(
    presidential_table,
    make_race_table(results_presidential, party_colors),
    repository = remote_repo
  ),

  ## Congressional races ----
  congressional_things,

  ## Legislative races ----
  district_things,

  # Stuff to store remotely to make accessible to the website pipeline ----
  # Combine all the district race maps and tables into single objects to
  # store remotely to limit the number of S3 API calls
  tar_combine(
    congressional_tables, 
    tar_select_targets(congressional_things, starts_with("table_")), 
    command = lst(!!!.x),
    repository = remote_repo
  ),

  tar_combine(
    congressional_maps, 
    tar_select_targets(congressional_things, starts_with("map_")), 
    command = lst(!!!.x),
    repository = remote_repo
  ),

  tar_combine(
    district_tables, 
    tar_select_targets(district_things, starts_with("table_")), 
    command = lst(!!!.x),
    repository = remote_repo
  ),

  tar_combine(
    district_maps, 
    tar_select_targets(district_things, starts_with("map_")), 
    command = lst(!!!.x),
    repository = remote_repo
  )
)
