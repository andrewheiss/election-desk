library(targets)

# View the graph for the pipeline (don't uncomment this though)
# tar_glimpse(label = "description")

# -----------------
# ETL pipeline ----
# -----------------
# get_results <- \() { NULL }
# clean_process_data <- \(results) { NULL }
# build_maps <- \(clean_results) { NULL }
# build_tables <- \(clean_results) { NULL }
# save_remotely <- \(maps, tables) { NULL }
#
# list(
#   tar_target(results, get_results(), description = "Data from database"),
#   tar_target(clean_data, clean_process_data(results), description = "Processed data"),
#   tar_target(maps, build_maps(clean_data), description = "Prebuilt maps"),
#   tar_target(tables, build_tables(clean_data), description = "Prebuilt tables"),
#   tar_target(saved_data, save_remotely(maps, tables), description = "All saved data")
# )

# ---------------------
# Website pipeline ----
# ---------------------
get_prebuilt_data <- \() { NULL }
build_site <- \(data) { NULL }
deploy_site <- \(site) { NULL }

list(
  tar_target(saved_data, get_prebuilt_data(), description = "Prebuilt data"),
  tar_target(site, build_site(saved_data), description = "Build Quarto site"),
  tar_target(deploy, deploy_site(site), description = "Deploy to Netlify")
)
