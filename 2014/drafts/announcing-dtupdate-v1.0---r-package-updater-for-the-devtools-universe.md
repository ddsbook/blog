Title: Announcing dtupdate v1.0 - R Package Reporter/Updater for the devtools Universe
Date: 2014-08-21 11:10:29
Category: tools
Tags: r, rstats, devtools, github
Slug: announcing-dtupdate-r-package-updater-for-the-devtools-universe
Author: Bob Rudis (@hrbrmstr)

The [dtupdate](https://github.com/hrbrmstr/dtupdate) package has functions that attempt to figure out which packages have non-CRAN versions (currently only looks for github ones) and then tries to figure out which ones have updates (i.e. the github version is \> local version). It provides an option (not recommended) to auto-update any packages with newer development versions. The reason auto updating is not recommended is due to there being potential incompatibilities between what's in the devtools universe and what you have installed. There *is* a reason for CRAN, so it's best to just use the functions that are and will be in this package to get a feel for how out of date you are, then go check the details of the new package versions before updating.

The `URL` and `BugReports` fields are, frankly, a mess. Many packages have multiple URLs in one or both of those fields and the non-github URLs are all over the place in terms of formatting. It will take some time, but I'm pretty confident I can get r-forge, bitbucket, gitorius and other external repos working. This was an easy first step.

TODO: A nice `knitr` HTML report is planned with clickable links and embedded `NEWS` and `DESCRIPTION` files for each package.

The following functions are implemented:

- `github_update` - find, report and optionally update packages installed from or available on github. This initial version just keys off of the `BugReports:` field, looking for a github-ish URL and then grabbing what info that it can to see if the repo is in package format and has a `DESCRIPTION` file it can key off of

### News

-   Version `1.0` released (nascent github pkg update capability)

### Installation

    :::r
    devtools::install_github("hrbrmstr/dtupdate")

### Usage

    :::r
    library(dtupdate)
    
    # get current verison
    packageVersion("dtupdate")
    
    ## [1] '1.0'
    
    # see what packages are available for an update
    github_update()
    
    ##      package.repo       owner installed.version current.version update.available
    ## 1      data.table  Rdatatable             1.9.3           1.9.3            FALSE
    ## 2        dtupdate    hrbrmstr               1.0             1.0            FALSE
    ## 3        forecast robjhyndman               5.4             5.6             TRUE
    ## 4          gmailr   jimhester             0.0.1           0.0.1            FALSE
    ## 5        jsonlite  jeroenooms             0.9.9          0.9.10             TRUE
    ## 6           knitr       yihui             1.6.6          1.6.14             TRUE
    ## 7  knitrBootstrap   jimhester             1.0.0           1.0.0            FALSE
    ## 8       lubridate      hadley             1.3.3           1.3.3            FALSE
    ## 9        markdown     rstudio               0.7           0.7.4             TRUE
    ## 10        memoise      hadley             0.2.1          0.2.99             TRUE
    ## 11       miniCRAN      andrie            0.0-20          0.0-20            FALSE
    ## 12        packrat     rstudio             0.4.0        0.4.0.12             TRUE
    ## 13           Rcpp    RcppCore            0.11.2        0.11.2.1             TRUE
    ## 14  RcppArmadillo    RcppCore         0.4.400.0       0.4.400.0            FALSE
    ## 15       reshape2      hadley               1.4        1.4.0.99             TRUE
    ## 16         resolv    hrbrmstr             0.2.2           0.2.2            FALSE
    ## 17           rzmq    armstrtw             0.7.0           0.7.0            FALSE
    ## 18         scales      hadley             0.2.4        0.2.4.99             TRUE
    ## 19          shiny     rstudio       0.10.0.9001     0.10.1.9004             TRUE
    ## 20       shinyAce trestletech             0.1.0           0.1.0            FALSE
    ## 21        slidify    ramnathv             0.4.5           0.4.5            FALSE
    ## 22         testit       yihui               0.3             0.3            FALSE
