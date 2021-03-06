% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diagnose.R
\name{appraise}
\alias{appraise}
\title{Model diagnostic plots}
\usage{
appraise(model, method = c("direct", "simulate", "normal"),
  n_uniform = 10, type = c("deviance", "pearson", "response"),
  n_bins = c("sturges", "scott", "fd"), ncol = 2, ...)
}
\arguments{
\item{model}{a fitted model. Currently only class \code{"gam"}.}

\item{method}{character; method used to generate theoretical quantiles.}

\item{n_uniform}{numeric; number of times to randomize uniform quantiles
in the direct computation method (\code{method = "direct"}).}

\item{type}{character; type of residuals to use. Only \code{"deviance"},
\code{"response"}, and \code{"pearson"} residuals are allowed.}

\item{n_bins}{character or numeric; either the number of bins or a string
indicating how to calculate the number of bins.}

\item{ncol}{numeric; number of columns to draw plots in. See
\code{\link[cowplot:plot_grid]{cowplot::plot_grid()}}.}

\item{...}{arguments passed to \code{\link[cowplot:plot_grid]{cowplot::plot_grid()}}, except for \code{align}
and \code{axis}, which are set internally.}
}
\description{
Model diagnostic plots
}
\examples{
library(mgcv)
\dontshow{set.seed(2)}
## simulate some data...
dat <- gamSim(1, n = 400, dist = "normal", scale = 2)
mod <- gam(y ~ s(x0) + s(x1) + s(x2) + s(x3), data = dat)
## run some basic model checks, including checking
## smoothing basis dimensions...
appraise(mod)
}
\seealso{
The plots are produced by functions \code{\link[gratia:qq_plot]{gratia::qq_plot()}},
\code{\link[gratia:residuals_linpred_plot]{gratia::residuals_linpred_plot()}}, \code{\link[gratia:residuals_hist_plot]{gratia::residuals_hist_plot()}},
and \code{\link[gratia:observed_fitted_plot]{gratia::observed_fitted_plot()}}.
}
