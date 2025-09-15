library(targets)
library(tarchetypes)

# Set target options
tar_option_set(
  # Packages that all target functions have access to
  packages = c("dplyr", "readr", "tidyr"),
  # Store finished targets with qs instead of rds
  format = "qs"
)

etl_file_target <- function(target_name) {
  file.path("../etl-pipeline/_targets", "objects", target_name)
}

# Source all the R scripts in the R/ folder
tar_source()

# Actual pipeline
list(
  tar_target(output_functions, lst(
    build_race_output, #build_close_race_output
  )),

  tar_target(
    file_last_updated,
    etl_file_target("last_updated"),
    format = "file"
  ),
  tar_target(last_updated, qs2::qs_read(file_last_updated)),

  ## Presidential stuff ----
  tar_target(
    file_presidential_table,
    etl_file_target("presidential_table"),
    format = "file"
  ),
  tar_target(
    file_presidential_map,
    etl_file_target("presidential_map"),
    format = "file"
  ),
  tar_target(presidential_table, qs2::qs_read(file_presidential_table)),
  tar_target(presidential_map, fix_map_deps(qs2::qs_read(file_presidential_map))),

  ## Congressional stuff ----
  tar_target(
    file_congressional_tables,
    etl_file_target("congressional_tables"),
    format = "file"
  ),
  tar_target(
    file_congressional_maps,
    etl_file_target("congressional_maps"),
    format = "file"
  ),
  tar_target(congressional_tables, qs2::qs_read(file_congressional_tables)),
  tar_target(congressional_maps, lapply(qs2::qs_read(file_congressional_maps), fix_map_deps)),

  ## Legislative stuff ----
  tar_target(
    file_district_tables,
    etl_file_target("district_tables"),
    format = "file"
  ),
  tar_target(
    file_district_maps,
    etl_file_target("district_maps"),
    format = "file"
  ),
  tar_target(district_tables, qs2::qs_read(file_district_tables)),
  tar_target(district_maps, lapply(qs2::qs_read(file_district_maps), fix_map_deps)),

  ## Website building and deploying ----
  tar_quarto(website, quiet = FALSE),

  tar_target(deploy_script, {
    # Select the deploy script based on the OS
    ifelse(
      Sys.info()["sysname"] == "Windows", 
      "deploy.bat", 
      "deploy.sh"
    )
  }, format = "file"),
  tar_target(deploy_site, {
    # Make the Quarto website a dependency
    website

    # Build OS-specific terminal command
    cmd <- ifelse(
      Sys.info()["sysname"] == "Windows", 
      deploy_script, 
      paste0("./", deploy_script)
    )

    # Run the command
    processx::run(cmd)
  })
)
