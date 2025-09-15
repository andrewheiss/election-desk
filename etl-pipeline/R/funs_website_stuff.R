
#' Create interactive election results map
#'
#' Generates a Leaflet map displaying election results by district with 
#' interactive tooltips and legend.
#'
#' @param results tibble, election results data containing vote totals by
#'   contestant and district
#' @param map_to_use sf object, spatial data for districts with district_id column
#' @param party_colors tibble, mapping of contestant_party to color values
#'
#' @return leaflet map object with colored districts based on winning candidate,
#'   interactive popups showing detailed results, and legend of candidates
#'   ordered by total votes
#'
make_map <- function(results, map_to_use, party_colors) {
  library(sf)
  library(leaflet)
  library(leaflet.extras)
  library(kableExtra)

  options(dplyr.summarise.inform = FALSE)

  # Add colors
  district_results <- results |>
    left_join(party_colors, by = join_by(contestant_party))

  # Find overall candidate totals to get the legend in the right order
  contestant_totals <- district_results |>
    group_by(contestant_name, color) |>
    summarize(total = sum(total_votes)) |>
    ungroup() |>
    arrange(desc(total))

  # Find the winner in each district
  district_winners <- district_results |>
    group_by(district_id) |>
    slice_max(total_votes, n = 1) |>
    ungroup() |>
    select(district_id, winning_party = contestant_party, winning_color = color)

  build_tooltip <- function(df) {
    df_cleaned <- df |>
      arrange(desc(total_votes)) |>
      mutate(
        prop = total_votes / sum(total_votes),
        prop_nice = scales::label_percent()(prop),
        count_nice = scales::label_comma()(total_votes),
        contestant_nice = glue::glue("{contestant_name} ({contestant_party})"),
        color_box = glue::glue(
          "<span style='display: inline-block; width: 30px; height: 30px; background: {color};'></span>"
        )
      )

    df_cleaned |>
      select(color_box, contestant_nice, count_nice, prop_nice) |>
      kbl(
        col.names = c("", "", "", ""),
        format = "html",
        caption = unique(df_cleaned$district_nice),
        escape = FALSE
      ) |>
      kable_styling() |>
      column_spec(1:4, extra_css = "vertical-align:middle; font-size: 1.2em;") |> 
      as.character()
  }

  district_tooltip <- district_results |>
    mutate(district_nice = glue::glue("District {district_id}")) |>
    group_by(district_id) |>
    nest() |>
    mutate(tooltip = map_chr(data, \(x) build_tooltip(x)))

  map_with_results <- map_to_use |>
    left_join(district_winners, by = "district_id") |>
    left_join(district_tooltip, by = "district_id")

  leaflet(map_with_results) |>
    addPolygons(
      data = filter(map_with_results, !is.na(winning_color)),
      fillColor = ~winning_color,
      weight = 2,
      color = "white",
      fillOpacity = 0.8,
      label = ~ lapply(tooltip, htmltools::HTML),
      highlightOptions = highlightOptions(weight = 6, bringToFront = TRUE)
    ) |>
    addPolygons(
      data = filter(map_with_results, is.na(winning_color)),
      fillColor = "#B8B7B8",
      weight = 2,
      color = "white",
      fillOpacity = 1,
      highlightOptions = NULL,
      label = NULL,
    ) |>
    addLegend(
      position = "topright",
      colors = contestant_totals$color,
      labels = contestant_totals$contestant_name,
      title = "Leading Candidate",
      opacity = 1
    ) |>
    htmlwidgets::onRender("
      function(el, x) {
        el.style.backgroundColor = '#f2f2f2';
      }
    ")
}


#' Create formatted race results table
#'
#' Generates an interactive reactable displaying candidate vote totals and
#' percentages with data bars and custom styling.
#'
#' @param df tibble, election results data for a specific race
#' @param party_colors tibble, mapping of contestant_party to color values
#'
#' @return list containing:
#'   - `tbl_out`: reactable object with formatted results table
#'   - `race_title`: character, formatted race title for display
#' 
make_race_table <- function(df, party_colors) {
  library(reactable)
  library(reactablefmtr)

  options(dplyr.summarise.inform = FALSE)

  # Add colors
  district_results <- df |>
    left_join(party_colors, by = join_by(contestant_party))

  race_title <- district_results |>
    mutate(nice_race_title = case_when(
      race_type == "Presidential" ~ "Presidential",
      stringr::str_starts(race_type, "Congressional") ~ glue::glue("{race_type} US Representative"),
      .default = glue::glue("District {district_id} {race_type}")
    )) |> 
    slice(1) |>
    pull(nice_race_title)

  contestant_totals <- district_results |>
    mutate(contestant_nice = glue::glue("{contestant_name} ({contestant_party})")) |> 
    group_by(contestant_nice, color) |>
    summarize(total = sum(total_votes)) |>
    ungroup() |>
    mutate(percent = total / sum(total)) |> 
    arrange(desc(total))

  tbl_out <- contestant_totals %>%  # Needs to be %>% for the .
    reactable(
      pagination = F,
      style = list(
        fontFamily = "Lato"
      ),
      columns = list(
        color = colDef(
          show = F
        ),
        contestant_nice = colDef(
          name = "Candidate",
          style = cell_style(
            data = .,
            font_size = "0.9em")
        ),
        total = colDef(
          name = "Votes",
          format = colFormat(separators = T),
          style = cell_style(
            data = .,
            font_size = "0.9em")
        ),
        percent = colDef(
          name = "",
          style = cell_style(
            data = .,
            font_size = "0.9em"),
          cell = data_bars(
            data = .,
            text_position = "above",
            fill_color_ref = "color",
            round_edges = T,
            max_value = .51,
            number_fmt = scales::label_percent(accuracy = 0.1)
          )
        )
      )
    )

  return(lst(tbl_out, race_title))
}
