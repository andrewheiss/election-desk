# Only use this stuff if you're using AWS as the intermediate storage location

# This is how you can access S3-based targets from other pipelines
#
# In the ETL pipeline:
#
#   tar_target(pres_map, whatever(), repository = "aws")
#
# In the website pipeline:
#
#   tar_change(
#     pres_map,
#     get_s3_qs("pres_map"),
#     change = get_s3_etag("pres_map")
#   )
#
# (via https://github.com/ropensci/targets/discussions/872)

# Configure AWS as a target resource
#
# tar_option_set(
#   resources = tar_resources(
#     aws = tar_resources_aws(
#       bucket = Sys.getenv("S3_BUCKET"),
#       prefix = Sys.getenv("S3_PREFIX")
#     )
#   )
# )

get_s3_etag <- function(object, bucket = Sys.getenv("S3_BUCKET")) {
  client <- paws::s3()

  object <- client$get_object(
      Bucket = bucket,
      Key = paste0(Sys.getenv("S3_PREFIX"), "/objects/", object)
    )

  return(object$ETag)
}

get_s3_qs <- function(object, bucket = Sys.getenv("S3_BUCKET")) {
  client <- paws::s3()

  object <- client$get_object(
    Bucket = bucket,
    Key = paste0(Sys.getenv("S3_PREFIX"), "/objects/", object)
  )

  # {qs} has a neat qdeserialize() function for working with binary streams like
  # this. If this was using rds instead, we'd need to save the object as a
  # temporary file and read it in with readRDS(), or use rawConnection() to
  # treat it like a file
  return(qs::qdeserialize(object$Body))
}
