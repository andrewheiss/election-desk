#' Create fictional district map data
#'
#' Generates a simple sf object with four fictional electoral districts
#' using hardcoded coordinate matrices.
#'
#' @return sf object with columns:
#'   - `district_id`: integer, district identifier (1-4)
#'   - `geometry`: sf geometry column, polygon geometries for each district
#' 
make_district_maps <- function() {
  suppressPackageStartupMessages(library(sf))

  # Invent a fake map
  districts_sf <- tibble(
    district_id = 1:4,
    coords = list(
      matrix(
        c(0, 0, 1.1, 0.1, 0.9, 1.1, -0.1, 0.9, 0, 0),
        ncol = 2,
        byrow = TRUE
      ),
      matrix(
        c(1.1, 0.1, 2, 0, 2.1, 0.9, 0.9, 1.1, 1.1, 0.1),
        ncol = 2,
        byrow = TRUE
      ),
      matrix(
        c(-0.1, 0.9, 0.9, 1.1, 1, 2, 0, 2, -0.1, 0.9),
        ncol = 2,
        byrow = TRUE
      ),
      matrix(
        c(0.9, 1.1, 2.1, 0.9, 2, 2, 1, 2, 0.9, 1.1),
        ncol = 2,
        byrow = TRUE
      )
    )
  ) |>
    mutate(
      geometry = map(coords, \(coord_matrix) st_polygon(list(coord_matrix)))
    ) |>
    select(district_id, geometry) |>
    st_sf()

  return(districts_sf)
}
