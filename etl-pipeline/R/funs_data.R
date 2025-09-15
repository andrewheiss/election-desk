#' Create party color mapping
#'
#' Returns a tibble mapping political party abbreviations to their associated
#' colors for maps and tables. The colors come from the Urban Institute's style
#' guide (https://urbaninstitute.github.io/graphics-styleguide/#color)
#'
#' @return A tibble with columns `contestant_party` (character) and `color`
#'   (character, hex codes). Contains mappings for Democratic (DEM), Republican
#'   (REP), and Libertarian (LIB) parties.
#'
#' @return A tibble with columns:
#'   - `contestant_party`: character, party affiliation (DEM, REP, LIB)
#'   - `color`: character, hex codes
#' 
make_colors <- function() {
  party_colors <- tribble(
    ~contestant_party, ~color,
    "DEM", "#1696d2",
    "REP", "#db2b27",
    "LIB", "#fdbf11"
  )
}


#' Generate simulated election contestants
#'
#' Creates a tibble of fictional candidates across different types of elections
#' including presidential, congressional, and state legislative races.
#'
#' @return A tibble with columns:
#'   - `district_id`: integer, district identifier (0 for statewide races)
#'   - `race_id`: integer, race identifier
#'   - `race_type`: character, description of the race type
#'   - `contestant_id`: integer, contestant identifier within each race
#'   - `contestant_name`: character, randomly generated candidate names
#'   - `contestant_party`: character, party affiliation (DEM, REP, LIB)
#'
#' @details
#' The function generates candidates for:
#'   - 1 presidential race (3 candidates)
#'   - 2 congressional district races (3 candidates each)
#'   - 12 state legislative races across 4 districts (3 candidates each)
#' 
generate_contestants <- function() {
  library(randomNames)

  set.seed(12345)

  presidential_candidates <- tibble(
    district_id = 0L,
    race_id = 1L,
    race_type = "Presidential",
    contestant_id = c(1L, 2L, 3L),
    contestant_name = randomNames(
      n = 3,
      name.order = "first.last",
      name.sep = " "
    ),
    contestant_party = c("DEM", "REP", "LIB")
  )

  congressional_candidates <- bind_rows(
    tibble(
      district_id = 0L,
      race_id = 10L,
      race_type = "Congressional District 1",
      contestant_id = c(1L, 2L, 3L),
      contestant_name = randomNames(
        n = 3,
        name.order = "first.last",
        name.sep = " "
      ),
      contestant_party = c("DEM", "REP", "LIB")
    ),
    tibble(
      district_id = 0L,
      race_id = 11L,
      race_type = "Congressional District 2",
      contestant_id = c(1L, 2L, 3L),
      contestant_name = randomNames(
        n = 3,
        name.order = "first.last",
        name.sep = " "
      ),
      contestant_party = c("DEM", "REP", "LIB")
    )
  )

  legislative_candidates <- bind_rows(
    tibble(
      district_id = 1L,
      race_id = 20L:22L,
      race_type = c("Senator", "Representative A", "Representative B")
    ),
    tibble(
      district_id = 2L,
      race_id = 23L:25L,
      race_type = c("Senator", "Representative A", "Representative B")
    ),
    tibble(
      district_id = 3L,
      race_id = 26L:28L,
      race_type = c("Senator", "Representative A", "Representative B")
    ),
    tibble(
      district_id = 4L,
      race_id = 29L:31L,
      race_type = c("Senator", "Representative A", "Representative B")
    )
  ) |>
    mutate(
      candidates = map(race_type, \(x) {
        tibble(
          contestant_id = c(1L, 2L, 3L),
          contestant_name = randomNames(
            n = 3,
            name.order = "first.last",
            name.sep = " "
          ),
          contestant_party = c("DEM", "REP", "LIB")
        )
      })
    ) |>
    unnest(candidates)

  contestants <- bind_rows(
    presidential_candidates,
    congressional_candidates,
    legislative_candidates
  )

  return(contestants)
}


#' Generate simulated election results
#'
#' Creates vote totals for contestants across all races and districts. 
#' Distributes presidential and congressional races across districts while
#' keeping district-specific races within their boundaries.
#'
#' @param contestants tibble, output from `generate_contestants()` containing
#'   candidate information
#'
#' @return A tibble with columns:
#'   - `race_id`: integer, race identifier
#'   - `district_id`: integer, district identifier
#'   - `contestant_id`: integer, contestant identifier
#'   - `total_votes`: integer, vote count for the contestant
#'
#' @details
#' Vote allocation follows realistic patterns:
#'   - Democratic and Republican candidates receive 40-49% each
#'   - Libertarian candidates receive the remainder (2-20%)
#'   - Turnout ranges from 30,000 to 60,000 voters per race/district
#' 
#' Presidential and congressional races appear in all districts, while
#' legislative races only appear in their assigned districts.
generate_results <- function(contestants) {
  pres_in_districts <- expand_grid(
    race_id = 1,
    district_id = 1:4
  ) |>
    mutate(
      candidates = map(race_id, \(x) {
        contestants |> filter(race_id == x) |> select(-race_id, -district_id)
      })
    ) |>
    unnest(candidates)

  congressional_in_districts <- tibble(
    race_id = c(10, 10, 11, 11),
    district_id = 1:4
  ) |>
    mutate(
      candidates = map(race_id, \(x) {
        contestants |> filter(race_id == x) |> select(-race_id, -district_id)
      })
    ) |>
    unnest(candidates)

  districts_only <- contestants |>
    filter(district_id != 0)

  contestants_long <- bind_rows(
    pres_in_districts,
    congressional_in_districts,
    districts_only
  )

  results <- contestants_long |>
    group_by(race_id, district_id) |>
    mutate(
      # Make this realistic-ish, with DEM and REP getting 40-50% of the vote...
      party_share = case_when(
        contestant_party == "DEM" ~ runif(1, 0.40, 0.49),
        contestant_party == "REP" ~ runif(1, 0.40, 0.49),
        contestant_party == "LIB" ~ NA_real_
      ),
      # ...and LIB getting the remainder
      party_share = if_else(
        contestant_party == "LIB",
        1 - sum(party_share, na.rm = TRUE),
        party_share
      ),
      # Make up turnout numbers
      race_turnout = sample(30000:60000, 1),
      # Finally create votes
      total_votes = as.integer(party_share * race_turnout)
    ) |>
    select(race_id, district_id, contestant_id, total_votes) |> 
    ungroup()

  return(results)
}


#' Update election results with random variation
#'
#' Randomly selects races and adds ±10% to their vote totals to simulate
#' updated results or counting errors.
#'
#' @param results tibble, election results data with vote totals
#' @param n_races_to_change integer, number of races to modify (default: 0)
#'
#' @return A tibble with the same structure as `results` but with modified
#'   vote totals for selected races:
#'   - `race_id`: integer, race identifier
#'   - `district_id`: integer, district identifier  
#'   - `contestant_id`: integer, contestant identifier
#'   - `total_votes`: integer, updated vote count for the contestant
#'
update_results <- function(results, n_races_to_change = 0) {
  # {targets} uses its own internal seed for things, and it gets used here so
  # that the same random changes happen every time. In this case, we don't care
  # about exact replicability—we want these little vote count changes to really
  # just be random noise all the time, so we unset the seed here so that R uses
  # its default time-based seed
  set.seed(NULL)

  races_to_change <- sample(unique(results$race_id), n_races_to_change)

  results_updated <- results |>
    mutate(
      total_votes = if_else(
        race_id %in% races_to_change,
        # Add ± 10% to the vote count
        total_votes + (total_votes * runif(n(), -0.1, 0.1)),
        total_votes
      ),
      total_votes = as.integer(total_votes)
    )

  return(results_updated)
}

#' Save district-race lookup table to CSV
#'
#' Extracts unique race and district combinations and saves them as a CSV file.
#' This is needed for static branching with {targets}
#'
#' @param df tibble, data containing race_id and district_id columns
#'
#' @return character, file path where the lookup table was saved
#' 
save_district_race_lookup <- function(df) {
  df |> 
    distinct(race_id, district_id) |> 
    write_csv("lookup_tables/district_race_lookup.csv")

  return("lookup_tables/district_race_lookup.csv")
}


#' Parse presidential race results
#'
#' Filters results to include only presidential race data.
#'
#' @param results tibble, election results data
#'
#' @return tibble, filtered results containing only presidential races
#' 
parse_presidential <- function(results) {
  # This is pretty simple here, but IRL could involve all sorts of other calculations
  results |> 
    filter(race_type == "Presidential")
}


#' Parse congressional race results
#'
#' Filters results to a specific congressional race.
#'
#' @param results tibble, election results data
#' @param x integer, race_id to filter for
#'
#' @return tibble, filtered results for the specified race
#' 
parse_congressional <- function(results, x) {
  results |> 
    filter(race_id == x)
}


#' Parse district race results
#'
#' Filters results to a specific district race.
#'
#' @param results tibble, election results data
#' @param x integer, race_id to filter for
#'
#' @return tibble, filtered results for the specified race
#' 
parse_district <- function(results, x) {
  results |> 
    filter(race_id == x)
}
