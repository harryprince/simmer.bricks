#' Delayed Release of a Resource
#'
#' This brick encapsulates a delayed release: the arrival releases the resource
#' and continues its way immediately, but the resource is busy for an additional
#' period of time.
#'
#' @inheritParams simmer::release
#' @inheritParams simmer::timeout
#' @inheritParams simmer::get_capacity
#'
#' @return Returns the following chain of activities: \code{\link[simmer]{clone}}
#' > \code{\link[simmer:clone]{synchronize}} (see examples below).
#' @export
#'
#' @examples
#' env <- simmer() %>%
#'   add_resource("res1") %>%
#'   add_resource("res2", preemptive=TRUE)
#'
#' ## These are equivalent if the resource is non-preemptive:
#' trajectory() %>%
#'   delayed_release(env, "res1", 5, 1)
#'
#' trajectory() %>%
#'   clone(
#'     2,
#'     trajectory() %>%
#'       set_capacity("res1", function()
#'         get_capacity(env, "res1") - 1) %>%
#'       release("res1", 1),
#'     trajectory() %>%
#'       timeout(5) %>%
#'       set_capacity("res1", function()
#'         get_capacity(env, "res1") + 1)
#'   ) %>%
#'   synchronize(wait=FALSE)
#'
#' ## These are equivalent if the resource is preemptive:
#' trajectory() %>%
#'   delayed_release(env, "res2", 5, 1)
#'
#' trajectory() %>%
#'   clone(
#'     2,
#'     trajectory() %>%
#'       release("res2", 1),
#'     trajectory() %>%
#'       set_prioritization(function()
#'         get_prioritization(env) + c(rep(.Machine$integer.max, 2), 0)) %>%
#'       seize("res2", 1) %>%
#'       timeout(5) %>%
#'       release("res2", 1)
#'   ) %>%
#'   synchronize(wait=FALSE)
#'
delayed_release <- function(.trj, .env, resource, task, amount=1) {
  . <- NULL
  .trj %>% {
    if (!is_preemptive(.env, resource))
      clone(
        ., 2,
        trajectory() %>%
          set_capacity(resource, function()
            get_capacity(.env, resource) - amount) %>%
          release(resource, amount),
        trajectory() %>%
          timeout(task) %>%
          set_capacity(resource, function()
            get_capacity(.env, resource) + amount)
      )
    else
      clone(
        ., 2,
        trajectory() %>%
          release(resource, amount),
        trajectory() %>%
          set_prioritization(function()
            get_prioritization(.env) + c(rep(.Machine$integer.max, 2), 0)) %>%
          seize(resource, amount) %>%
          timeout(task) %>%
          release(resource, amount)
      )
  } %>% synchronize(wait=FALSE)
}