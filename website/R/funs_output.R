build_race_output <- function(heading, tbl, mp, district = NA) {
  # Determine if there's a race name
  if (!is.na(district)) {
    race_title <- glue::glue("## {district}")
  } else {
    race_title <- ""
  }

  # Combine all the pieces
  output <- glue::glue('
  <<race_title>>

  ### <<heading>>

  ::: {.panel-tabset}

  #### {{< fa list-ul >}}

  ```{r}
  <<tbl>>
  ```

  #### {{< fa map-location-dot >}}

  ```{r}
  <<mp>>
  ```

  :::
  ', .open = "<<", .close = ">>")

  output
}
