# Some {leaflet}-related extensions hardcode the absolute path to dependencies
# in the leaflet object, which locks leaflet objects to specific versions of R
# and specific platforms (e.g. if the map is made on R 4.4 on macOS, it won't
# work on R 4.3 on Windows)
#
# This follows a suggestion at https://github.com/rstudio/leaflet/issues/467 and
# rewrites the path to the dependency for the ones with weird hardcoded paths
fix_map_deps <- function(x) {
  if (is.null(x)) {
    return(x)
  }

  # Find which dependency has is named "leaflet-providers" and change the hardcoded path
  i_providers <- which(sapply(x$dependencies, \(y) y$name == "leaflet-providers"))
  if (length(i_providers) > 0) {
    x$dependencies[[i_providers]]$src$file <- normalizePath(paste0(.libPaths()[1], "/leaflet.providers"))
  }

  # Find which dependency has is named "lfx-fullscreen" and change the hardcoded path
  i_lfx <- which(sapply(x$dependencies, \(y) y$name == "lfx-fullscreen"))
  if (length(i_lfx) > 0) {
    x$dependencies[[i_lfx]]$src$file <- normalizePath(paste0(.libPaths()[1], "/leaflet.extras/htmlwidgets/build/lfx-fullscreen"))
  }

  return(x)
}
