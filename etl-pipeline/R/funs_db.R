#' Populate testing database with election data
#'
#' Creates a DuckDB database file and populates it with contestants, results,
#' and metadata tables.
#'
#' @param contestants tibble, candidate information data
#' @param results tibble, election results data
#'
#' @return character, path to the created database file ("testing_db.duckdb")
#'
#' @details
#' Creates three tables in the database:
#' - `contestant`: candidate information
#' - `results`: vote totals by contestant and district
#' - `meta`: timestamp of last database update
#' 
populate_testing_db <- function(contestants, results) {
  suppressPackageStartupMessages(library(dbplyr))
  suppressPackageStartupMessages(library(duckdb))
  suppressPackageStartupMessages(library(connections))

  db_file <- "testing_db.duckdb"

  con <- connection_open(duckdb::duckdb(), db_file)

  copy_to(
    con, 
    contestants, 
    name = "contestant", 
    overwrite = TRUE, temporary = FALSE
  )

  copy_to(
    con, 
    results, 
    name = "results", 
    overwrite = TRUE, temporary = FALSE
  )

  copy_to(
    con,
    tibble(last_updated = format(lubridate::now(), "%Y-%m-%d %H:%M:%S")),
    name = "meta",
    overwrite = TRUE, temporary = FALSE
  )

  connections::connection_close(con)

  return(db_file)
}


#' Connect to database
#'
#' Establishes database connection based on environment. Uses production
#' MySQL in production environment, DuckDB file for testing.
#'
#' @return database connection object, or NULL if production mode is enabled
#'   but connection details are commented out
#'
#' @details
#' Checks `PRODUCTION` environment variable:
#' - If "true": attempts MySQL connection (currently returns NULL as code is commented)
#' - Otherwise: connects to local DuckDB testing database
#' 
#' Production connection would use keyring for credential management.
#' 
db_connect <- function() {
  if (Sys.getenv("PRODUCTION") == "true") {
    # con <- DBI::dbConnect(
    #   odbc::odbc(), 
    #   Driver = "MySQL ODBC 9.0 Unicode Driver", 
    #   Server = "server details go here", 
    #   UID = keyring::key_get("db_username"), 
    #   PWD = keyring::key_get("db_password"), 
    #   Port = 3306
    # )
    NULL
  } else {
    db_file <- "testing_db.duckdb"

    con <- connections::connection_open(duckdb::duckdb(), db_file)
  }

  return(con)
}


#' Check database last update timestamp
#'
#' Retrieves the timestamp of the last database update from the meta table.
#'
#' @return character, timestamp string from the database meta table
#' 
check_db_update <- function() {
  suppressPackageStartupMessages(library(dbplyr))

  con <- db_connect()

  last_update <- tbl(con, I("meta")) |>
    collect() |>
    pull(last_updated)

  connections::connection_close(con)

  return(last_update)
}


#' Retrieve election data from database
#'
#' Fetches and joins contestant and results data from the database.
#'
#' @return tibble, joined contestant and results data with district_id from
#'   the results table (contestant table district_id is dropped to avoid conflicts)
#'
get_from_db <- function(...) {
  suppressPackageStartupMessages(library(dbplyr))

  con <- db_connect()

  # Get contestant-level results
  contestant_tbl <- tbl(con, I("contestant")) |>
    collect()

  # Get results
  results_tbl <- tbl(con, I("results")) |>
    collect()

  contestant_results <- contestant_tbl |>
    select(-district_id) |> 
    right_join(results_tbl, by = join_by(race_id, contestant_id))

  connections::connection_close(con)

  return(contestant_results)
}
