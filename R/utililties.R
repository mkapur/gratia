## smooth_terms should be removed
`smooth_terms` <- function(obj, ...) {
    UseMethod("smooth_terms")
}

`smooth_terms.gam` <- function(object, ...) {
    lapply(object[["smooth"]], `[[`, "term")
}

`smooth_terms.gamm` <- function(object, ...) {
    smooth_terms(object[["gam"]], ...)
}

`smooth_terms.mgcv.smooth` <- function(object, ...) {
    object[["term"]]
}

`smooth_terms.fs.interaction` <- function(object, ...) {
    object[["term"]]
}

##' Dimension of a smooth
##'
##' Extracts the dimension of an estimated smooth.
##'
##' This is a generic function with methods for objects of class
##'   `"gam"`, `"gamm"`, and `"mgcv.smooth"`.
##
##' @param object an R object. See Details for list of supported objects.
##'
##' @return A numeric vector of dimensions for each smooth.
##'
##' @author Gavin L. Simpson
##'
##' @rdname smooth_dim
##' @export
`smooth_dim` <- function(object) {
    UseMethod("smooth_dim")
}

##' @rdname smooth_dim
##' @export
`smooth_dim.gam` <- function(object) {
    vapply(object[["smooth"]], FUN = `[[`, FUN.VALUE = integer(1), "dim")
}

##' @rdname smooth_dim
##' @export
`smooth_dim.gamm` <- function(object) {
    smooth_dim(object[["gam"]])
}

##' @rdname smooth_dim
##' @export
`smooth_dim.mgcv.smooth` <- function(object) {
    object[["dim"]]
}

`select_terms` <- function(object, terms) {
    TERMS <- unlist(smooth_terms(object))
    terms <- if (missing(terms)) {
                 TERMS
             } else {
                 want <- terms %in% TERMS
                 if (any(!want)) {
                     msg <- paste("Terms:",
                                  paste(terms[!want], collapse = ", "),
                                  "not found in `object`")
                     message(msg)
                 }
                 terms[want]
             }
    terms
}

`select_smooth` <- function(object, smooth) {
    SMOOTHS <- smooths(object)
    if (missing(smooth)) {
        stop("'smooth' must be supplied; eg. `smooth = 's(x2)'`")
    }
    if (length(smooth) > 1L) {
        message(paste("Multiple smooths supplied. Using only first:", smooth[1]))
        smooth <- smooth[1]
    }
    want <- grep(smooth, SMOOTHS, fixed = TRUE)
    SMOOTHS[want]
}

##' Names of smooths in a GAM
##'
##' @param object a fitted GAM or related model. Typically the result of a call
##'   to [mgcv::gam()], [mgcv::bam()], or [mgcv::gamm()].
##'
##' @export
`smooths` <- function(object) {
    vapply(object[["smooth"]], FUN  = `[[`, FUN.VALUE = character(1), "label")
}

`smooth_variable` <- function(smooth) {
    check_is_mgcv_smooth(smooth)
    smooth[["term"]]
}

`smooth_factor_variable` <- function(smooth) {
    check_is_mgcv_smooth(smooth)
    smooth[["fterm"]]
}

`smooth_label` <- function(smooth) {
    check_is_mgcv_smooth(smooth)
    smooth[["label"]]
}

##' @title Check if objects are smooths or are a particular type of smooth
##'
##' @param smooth an R object, typically a list
##'
##' @export
##' @rdname is_mgcv_smooth
`is_mgcv_smooth` <- function(smooth) {
    inherits(smooth, "mgcv.smooth")
}

##' @export
##' @rdname is_mgcv_smooth
`is_mrf_smooth` <- function(smooth) {
  inherits(smooth, what= "mrf.smooth")
}

`check_is_mgcv_smooth` <- function(smooth) {
    out <- is_mgcv_smooth(smooth)
    if (identical(out, FALSE)) {
        stop("Object passed to 'smooth' is not a 'mgcv.smooth'.")
    }
    invisible(out)
}

`is.gamm` <- function(object) {
    inherits(object, "gamm")
}

`is.gam` <- function(object) {
    inherits(object, "gam")
}

##' @title Extract an mgcv smooth by name
##'
##' @param object a fitted GAM model object.
##' @param term character; the name of a smooth term to extract
##'
##' @return A single smooth object, or a list of smooths if several match the
##'   named term.
##'
##' @export
`get_smooth` <- function(object, term) {
    if (is.gamm(object)) {
        object <- object[["gam"]]
    }
    smooth <- object[["smooth"]][which_smooth(object, term)]
    if (identical(length(smooth), 1L)) {
        smooth <- smooth[[1L]]
    }
    smooth
}

##' @title Extract an mgcv smooth given its position in the model object
##'
##' @param object a fitted GAM model object.
##' @param id numeric; the position of the smooth in the model object.
##'
##' @export
`get_smooths_by_id` <- function(object, id) {
    if (is.gamm(object)) {
        object <- object[["gam"]]
    }
    object[["smooth"]][id]
}

##' @title Extract an factor-by smooth by name
##'
##' @param object a fitted GAM model object.
##' @param term character; the name of a smooth term to extract.
##' @param level character; which level of the factor to exrtact the smooth for..
##'
##' @return A single smooth object, or a list of smooths if several match the
##'   named term.
##'
##' @export
`get_by_smooth` <- function(object, term, level) {
    if (is.gamm(object)) {
        object <- object[["gam"]]
    }

    ## which smooth match the term?
    take <- which_smooth(object, term)
    S <- object[["smooth"]][take]

    ## if there are multiple, then suggests a factor by smooth
    is_by <- vapply(S, is_factor_by_smooth, logical(1L))

    ## if any are factor by variable smooths, get the levels
    if (any(is_by)) {
        if (missing(level)) {
            stop("No value provided for argument 'level':\n  Getting a factor by-variable smooth requires a 'level' be supplied.")
        }
        level <- as.character(level)    # explicit coerce to character for later comparison
        levs <- vapply(S, `[[`, character(1L), "by.level")
        take <- match(level, levs)
        if (is.na(take)) {
            msg <- paste0("Invalid 'level' for smooth '", term, "'. Possible levels are:\n")
            msg <- paste(msg, paste(strwrap(paste0(shQuote(levs), collapse = ", "),
                                            prefix = " ", initial = ""),
                                    collapse = "\n"))
            stop(msg)
        }

        S <- S[[take]]
    } else {
        stop("The requested smooth '", term, "' is not a by smooth.")
    }

    ## return a single smooth object
    S
}

##' @title Identify a smooth term by it's label
##'
##' @param object a fitted GAM.
##' @param terms character; one or more (partial) term labels with which to identify
##'   required smooths.
##' @param ... arguments passed to other methods.
##'
##' @export
`which_smooths` <- function(object, ...) {
    UseMethod("which_smooths")
}

##' @export
##' @rdname which_smooths
`which_smooths.default` <- function(object, ...) {
    stop("Don't know how to identify smooths for <", class(object)[[1L]], ">",
         call. = FALSE)           # don't show the call, simpler error
}

##' @export
##' @rdname which_smooths
`which_smooths.gam` <- function(object, terms, ...) {
    ids <- unique(unlist(lapply(terms, function(x, object) { which_smooth(object, x) },
                                object = object)))
    if (identical(length(ids), 0L)) {
        stop("None of the terms matched a smooth.")
    }

    ids
}

##' @export
##' @rdname which_smooths
`which_smooths.bam` <- function(object, terms, ...) {
    ids <- unique(unlist(lapply(terms, function(x, object) { which_smooth(object, x) },
                                object = object)))
    if (identical(length(ids), 0L)) {
        stop("None of the terms matched a smooth.")
    }

    ids
}

##' @export
##' @rdname which_smooths
`which_smooths.gamm` <- function(object, terms, ...) {
    ids <- unique(unlist(lapply(terms, function(x, object) { which_smooth(object, x) },
                                object = object[["gam"]])))
    if (identical(length(ids), 0L)) {
        stop("None of the terms matched a smooth.")
    }

    ids
}

`which_smooth` <- function(object, term) {
    if (is.gamm(object)) {
        object <- object[["gam"]]
    }
    smooths <- smooths(object)
    grep(term, smooths, fixed = TRUE)
}

##' How many smooths in a fitted model
##'
##' @inheritParams smooths
##'
##' @export
`n_smooths` <- function(object) {
    UseMethod("n_smooths")
}

##' @export
##' @rdname n_smooths
`n_smooths.default` <- function(object) {
    if (!is.null(object[["smooth"]])) {
        return(length(object[["smooth"]]))
    }

    stop("Don't know how to identify smooths for <", class(object)[[1L]], ">",
         call. = FALSE)           # don't show the call, simpler error
}

##' @export
##' @rdname n_smooths
`n_smooths.gam` <- function(object) {
    length(object[["smooth"]])
}

##' @export
##' @rdname n_smooths
`n_smooths.gamm` <- function(object) {
    length(object[["gam"]][["smooth"]])
}

##' @export
##' @rdname n_smooths
`n_smooths.bam` <- function(object) {
    length(object[["smooth"]])
}

`get_vcov` <- function(object, unconditional = FALSE, frequentist = FALSE,
                       term = NULL, by_level = NULL) {
    V <- if (frequentist) {
        object$Ve
    } else if (unconditional) {
        if (is.null(object$Vc)) {
            warning("Covariance corrected for smoothness uncertainty not available.\nUsing uncorrected covariance.")
            object$Vp     # Bayesian vcov of parameters
        } else {
            object$Vc     # Corrected Bayesian vcov of parameters
        }
    } else {
        object$Vp         # Bayesian vcov of parameters
    }

    ## extract selected term if requested
    if (!is.null(term)) {
        ## to keep this simple, only evaluate a single term
        if (length(term) > 1L) {
            message("Supplied more than 1 'term'; using only the first")
            term <- term[1L]
        }
        term <- select_smooth(object, term)
        smooth <- get_smooth(object, term)
        start <- smooth$first.para
        end <- smooth$last.para
        para.seq <- start:end
        V <- V[para.seq, para.seq, drop = FALSE]
    }
    V
}

`has_s` <- function(terms) {
    grepl("^s\\(.+\\)$", terms)
}

`add_s` <- function(terms) {
    take <- ! has_s(terms)
    terms[take] <- paste("s(", terms[take], ")", sep = "")
    terms
}

`is_re_smooth` <- function(smooth) {
    check_is_mgcv_smooth(smooth)
    inherits(smooth, "random.effect")
}

`is_fs_smooth` <- function(smooth) {
    check_is_mgcv_smooth(smooth)
    inherits(smooth, "fs.interaction")
}

##' Fix the names of a data frame containing an offset variable.
##'
##' Identifies which variable, if any, is the model offset, and fixed the name
##'   such that `offset(foo(var))` is converted to `var`, and possibly sets the
##'   values of that variable to `offset_val`.
##
##' @param model a fitted GAM.
##'
##' @param newdata data frame; new values at which to predict at.
##'
##' @param offset_val numeric, optional; if provided, then the offset variable
##'   in `newdata` is set to this constant value before returning `newdata`
##'
##' @return The original `newdata` is returned with fixed names and possibly
##'   modified offset variable.
##'
##' @author Gavin L. Simpson
##'
##' @export
##'
##' @examples
##' library("mgcv")
##' \dontshow{set.seed(2)}
##' df <- gamSim(1, n = 400, dist = "normal")
##' m <- gam(y ~ s(x0) + s(x1) + offset(x2), data = df, method = "REML")
##' names(model.frame(m))
##' names(fix_offset(m, model.frame(m), offset_val = 1L))
`fix_offset` <- function(model, newdata, offset_val = NULL) {
    m.terms <- names(newdata)
    p.terms <- attr(terms(model[["pred.formula"]]), "term.labels")

    ## remove repsonse from m.terms if it is in there
    tt <- terms(model)
    resp <- names(attr(tt, "dataClasses"))[attr(tt, "response")]
    Y <- m.terms == resp
    if (any(Y)) {
        m.terms <- m.terms[!Y]
    }

    ## is there an offset?
    off <- is_offset(m.terms)
    if (any(off)) {
        ## which cleaned terms not in model terms
        ind <- m.terms %in% p.terms
        ## for the cleaned terms not in model terms, match with the offset
        off_var <- grep(p.terms[!ind], m.terms[off])
        if (any(off_var)) {
            names(newdata)[which(names(newdata) %in% m.terms)][off] <- p.terms[!ind][off_var]
        }

        ## change offset?
        if (!is.null(offset_val)) {
            newdata[, p.terms[!ind][off_var]] <- offset_val
        }
    }

    newdata                        # return
}

##' Is a model term an offset?
##'
##' Given a character vector of model terms, checks to see which, if any, is the model offset.
##'
##' @param terms character vector of model terms.
##'
##' @return A logical vector of the same length as `terms`.
##'
##' @author Gavin L. Simpson
##'
##' @export
##'
##' @examples
##' library("mgcv")
##' df <- gamSim(1, n = 400, dist = "normal")
##' m <- gam(y ~ s(x0) + s(x1) + offset(x0), data = df, method = "REML")
##' nm <- names(model.frame(m))
##' nm
##' is_offset(nm)
`is_offset` <- function(terms) {
    grepl("offset\\(", terms)
}

##' Names of any parametrix terms in a GAM
##'
##' @param model a fitted model.
##' @param ... arguments passed to other methods.
##'
##' @export
`parametric_terms` <- function(model, ...) {
    UseMethod("parametric_terms")
}

##' @export
##' @rdname parametric_terms
`parametric_terms.default` <- function(model, ...) {
    stop("Don't know how to identify parametric terms from <",
         class(model)[[1L]], ">", call. = FALSE)
}

##' @export
##' @rdname parametric_terms
`parametric_terms.gam` <- function(model, ...) {
    tt <- model$pterms        # get parametric terms
    labs <- if (is.list(tt)) {
        unique(unlist(lapply(tt, function(x) labels(delete.response(x)))))
    } else {
        tt <- delete.response(tt) # remove response so easier to work with
        labels(tt)                # names of all parametric terms
    }
    labs
}

## Internal functions
`by_smooth_failure` <- function(object) {
    msg <- paste("Hmm, something went wrong identifying the requested smooth. Found:\n",
                 paste(vapply(object, FUN = smooth_label,
                              FUN.VALUE = character(1L)),
                       collapse = ', '),
                 "\nNot all of these are 'by' variable smooths. Contact Maintainer.")
    msg
}

##' @title Repeat the first level of a factor n times
##'
##' @description Function to repeat the first level of a factor n times and
##'   return this vector as a factor with the original levels intact
##'
##' @param f a factor
##' @param n numeric; the number of times to repeat the first level of `f`
##'
##' @return A factor of length `n` with the levels of `f`, but whose elements
##'   are all the first level of `f`.
`rep_first_factor_value` <- function(f, n) {
    stopifnot(is.factor(f))
    levs <- levels(f)
    factor(rep(levs[1L], length.out = n), levels = levs)
}

##' @title Create a sequence of evenly-spaced values
##'
##' @description Creates a sequence of `n` evenly-spaced values over the range
##'   `min(x)` -- `max(x)`.
##'
##' @param x numeric; vector over which evenly-spaced values are returned
##' @param n numeric; the number of evenly-spaced values to return
##'
##' @return A numeric vector of length `n`.
##'
##' @export
##'
##' @examples
##' \dontshow{set.seed(1)}
##' x <- rnorm(10)
##' n <- 10L
##' seq_min_max(x, n = n)
`seq_min_max` <- function(x, n) {
    seq(from = min(x, na.rm = TRUE), to = max(x, na.rm = TRUE),
        length.out = n)
}

##' Vectorized version of `data.class`
##'
##' @param df a data frame or tibble.
##'
##' @return A named character vector of data classes.
##'
##' @seealso The underlying functionality is provided by [data.class()].
##'
##' @export
`data_class` <- function(df) {
    vapply(df, data.class, character(1L))
}

##' Names of any factor variables in model data
##'
##' @param df a data frame or tibble
`factor_var_names` <- function(df) {
    ind <- is_factor_var(df)
    result <- if (any(ind)) {
        names(df)[ind]
    } else {
        NULL
    }
    result
}

##' Are variables in a data frame factors?
##'
##' @param df a data frame or tibble
`is_factor_var` <- function(df) {
    result <- vapply(df, is.factor, logical(1L))
    result
}

##' Shift numeric values in a data frame by an amount `eps`
##'
##' @param df a data frame or tibble.
##' @param h numeric; the amount to shift values in `df` by.
##' @param i logical; a vector indexing columns of `df` that should not be
##'   included in the shift.
##' @param FUN function; a function to applut the shift. Typically `+` or `-`.
`shift_values` <- function(df, h, i, FUN = '+') {
    FUN <- match.fun(FUN)
    result <- df
    if (any(i)) {
        result[, !i] <- FUN(result[, !i], h)
    } else {
        result <- FUN(result, h)
    }
    result
}

##' @importFrom stats qnorm
`coverage_normal` <- function(level) {
    if (level <= 0 || level >= 1 ) {
         stop("Invalid 'level': must be 0 < level < 1", call. = FALSE)
     }
     qnorm((1 - level) / 2, lower.tail = FALSE)
}

##' @importFrom stats qt
`coverage_t` <- function(level, df) {
    if (level <= 0 || level >= 1 ) {
         stop("Invalid 'level': must be 0 < level < 1", call. = FALSE)
     }
     qt((1 - level) / 2, df = df, lower.tail = FALSE)
}

##' @importFrom mgcv fix.family.rd
`get_family_rd` <- function(object) {
    if (inherits(object, "glm")) {
        fam <- family(object)           # extract family
    } else {
        fam <- object[["family"]]
    }
    ## mgcv stores data simulation funs in `rd`
    fam <- fix.family.rd(fam)
    if (is.null(fam[["rd"]])) {
        stop("Don't yet know how to simulate from family <",
             fam[["family"]], ">", call. = FALSE)
    }
    fam[["rd"]]
}
