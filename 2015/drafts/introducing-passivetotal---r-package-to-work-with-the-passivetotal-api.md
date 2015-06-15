Title: Introducing passivetotal - R Package To Work With the PassiveTotal API
Date: 2015-06-14 20:44:19
Category: blog
Status: draft
Tags: blog, r, rstats
Slug: introducing-passivetotal
Author: Bob Rudis (@hrbrmstr)

As a precursor to releasing Episode 18 of [DDSec Podcast](http://podcast.datadrivensecurity.info), we're releasing a _really_ basic [R package](https://github.com/hrbrmstr/passivetotal) to interface with the [PassiveTotal](https://www.passivetotal.org/) [API](https://www.passivetotal.org/api/docs). We asked Brandon Dixon to be on the podcast to talk about his [new visualization](http://blog.passivetotal.org/rethinking-passive-dns-results/) for users of PassiveTotal, which is a "threat research platform created for analysts, by analysts.". PT has deep and wide knowledge about domains and IP addresses which can be accessed via their portal or their API. They [provide](https://github.com/passivetotal/passivetotal_tools) API tools for various languages and we'll be working with them to get this new R package into their repository as soon as it's a bit more feature rich.

Since it's not on [CRAN](http://cran.r-project.org), you have to use `devtools` to install it:

    :::r
    devtools::install_github("hrbrmstr/passivetotal")

After that you just call the various API functions and get back an R list object from the returned JSON:

    :::r
    library(passivetotal)
    
    get_metadata("www.passivetotal.com")
    
    ## $ever_compromised
    ## [1] FALSE
    ## 
    ## $tags
    ## list()
    ## 
    ## $dynamic
    ## [1] FALSE
    ## 
    ## $value
    ## [1] "www.passivetotal.com"
    ## 
    ## $subdomains
    ## list()
    ## 
    ## $query_value
    ## [1] "www.passivetotal.com"
    ## 
    ## $tld
    ## [1] ".com"
    ## 
    ## $primaryDomain
    ## [1] "passivetotal.com"
    ## 
    ## $type
    ## [1] "domain"

You'll need to put your PassiveTotal API key in an `PASSIVETOTAL_API_KEY` environment variable, which is best done by editing your `.Renvion` file.

While you can get started playing with the PT API right away via this package we intend to add signifcant functionality to it. R list objects are all well-and-good, but I envision returning `igraph` objects that can be combined, maniupulated and visualized (both with static charts and `htmlwidgets`) with a few, simple function calls, which could make this a pretty powerful tool to use with the data the PT folks provide.

Suggestions, errors, etc shld all go [on github](https://github.com/hrbrmstr/passivetotal/issues).