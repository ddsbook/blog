Title: New and Updated R Packages for Security Data Science
Date: 2014-08-12 16:30:26
Category: tools
Tags: r, rstats, analysis
Slug: new-and-updated-r-packages-for-security-data-science
Author: Bob Rudis (@hrbrmstr)

We've got some new and updated R packages that are (hopefully) helpful to security folks who are endeavouring to use R in their quest to find and prevent malicious activity. All packages now incorporate a `testthat` workflow and are fully `roxygen`-ized and present some best practices in R package development (a post on that very topic is pending).

We'll start with the old and work our way to the new&hellip;

### Changes to the `resolv` package

I've updated [resolv](https://github.com/hrbrmstr/resolv) for the newest `Rcpp` and for a better build on linux and OS X systems (still no Windows compatibiity). The package also includes vectorized versions of the core `resolv_` functions. Here's an example:

    :::r
    library(resolv)
    library(data.table)
    library(plyr)
    
    # Read in the Alexa top 1 million list
    alexa <- fread("data/top-1m.csv") # http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
    str(alexa)
    
    ## Classes ‘data.table’ and 'data.frame':  1000000 obs. of  2 variables:
    ##  $ V1: int  1 2 3 4 5 6 7 8 9 10 ...
    ##  $ V2: chr  "google.com" "facebook.com" "youtube.com" "yahoo.com" ...
    ##  - attr(*, ".internal.selfref")=<externalptr> 
     
    # How many of the Alexa top *1,000* have spf records?
    alexa.txt <- TXT(alexa[1:1000]$V2) # this takes a few seconds as it's not performed in parallel
    
    # iterate over the results, testing for presence spf records in each 
    table(sapply(alexa.txt, function(x) { grepl("spf", unlist(x[1]));  }))
    
    ## FALSE  TRUE 
    ##   487   513 
  
Doing all 1M would take a short while, but it'd be an interesting experiment to run (then, analyze the records to see which services these sites trust with their mail sending).

### Updates to the  `netintel` package

The `netintel` package is back from the dead! (thanks to a helpful push by [David Severski](http://twitter.com/dseverski)).

All core functions have been re-written and the package now uses `httr` and `data.table` in some places for better realiability and speed. Functions that take AS numbers as parameters automagically strip or add the `AS` prefix as needed. To remind or introduce you to some of the workings:

    :::r
    # continuing from the previous code
    
    library(netintel)
    
    # get the IP addresses of the top 10 alexa domains
    alexa.a <- A(alexa[1:10]$V2)
    
    # retrieve the AS information
    origin <- BulkOrigin(as.character(unlist(alexa.a)))
    
    ##       AS              IP       BGP.Prefix CC Registry  Allocated                                                              AS.Name
    ## 1  15169   74.125.22.100   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 2  15169   74.125.22.101   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 3  15169   74.125.22.102   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 4  15169   74.125.22.113   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 5  15169   74.125.22.138   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 6  15169   74.125.22.139   74.125.22.0/24 US     arin 2007-03-13                                              GOOGLE - Google Inc.,US
    ## 7  32934  173.252.110.27  173.252.96.0/19 US     arin 2011-02-28                                         FACEBOOK - Facebook, Inc.,US
    ## 8  15169   64.233.171.91  64.233.171.0/24 US     arin 2003-08-18                                              GOOGLE - Google Inc.,US
    ## 9  15169   64.233.171.93  64.233.171.0/24 US     arin 2003-08-18                                              GOOGLE - Google Inc.,US
    ## 10 15169  64.233.171.136  64.233.171.0/24 US     arin 2003-08-18                                              GOOGLE - Google Inc.,US
    ## 11 15169  64.233.171.190  64.233.171.0/24 US     arin 2003-08-18                                              GOOGLE - Google Inc.,US
    ## 12 36646  98.138.253.109    98.138.0.0/16 US     arin 2007-12-07                                                 YAHOO-NE1 - Yahoo,US
    ## 13 26101   98.139.183.24  98.139.128.0/17 US     arin 2007-12-07                                                  YAHOO-3 - Yahoo!,US
    ## 14 36647   206.190.36.45  206.190.32.0/20 US     arin                                                            YAHOO-GQ1 - Yahoo,US
    ## 15  4808 123.125.114.144  123.125.64.0/18 CN    apnic 2007-01-29 CHINA169-BJ CNCGROUP IP network China169 Beijing Province Network,CN
    ## 16 23724  220.181.111.85  220.181.96.0/19 CN    apnic 2002-10-30      CHINANET-IDC-BJ-AP IDC, China Telecommunications Corporation,CN
    ## 17 23724  220.181.111.86  220.181.96.0/19 CN    apnic 2002-10-30      CHINANET-IDC-BJ-AP IDC, China Telecommunications Corporation,CN
    ## 18 14907  208.80.154.224  208.80.152.0/22 US     arin 2007-07-23                             WIKIMEDIA - Wikimedia Foundation Inc.,US
    ## 19 13414    199.16.156.6  199.16.156.0/22 US     arin 2010-07-09                                    TWITTER-NETWORK - Twitter Inc.,US
    ## 20 13414   199.16.156.70  199.16.156.0/22 US     arin 2010-07-09                                    TWITTER-NETWORK - Twitter Inc.,US
    ## 21 13414  199.16.156.102  199.16.156.0/22 US     arin 2010-07-09                                    TWITTER-NETWORK - Twitter Inc.,US
    ## 22 13414  199.16.156.198  199.16.156.0/22 US     arin 2010-07-09                                    TWITTER-NETWORK - Twitter Inc.,US
    ## 23  4837  125.39.240.113    125.36.0.0/14 CN    apnic 2005-12-30                      CHINA169-BACKBONE CNCGROUP China169 Backbone,CN
    ## 24 17623  163.177.65.160  163.177.65.0/24 CN    apnic 2011-03-30                          CNCGROUP-SZ China Unicom Shenzen network,CN
    ## 25 16509   72.21.194.212   72.21.192.0/19 US     arin 2004-12-30                                      AMAZON-02 - Amazon.com, Inc.,US
    ## 26 16509   72.21.215.232   72.21.192.0/19 US     arin 2004-12-30                                      AMAZON-02 - Amazon.com, Inc.,US
    ## 27 16509   176.32.98.166   176.32.96.0/21 IE  ripencc 2011-05-23                                      AMAZON-02 - Amazon.com, Inc.,US
    ## 28 16509  205.251.242.54 205.251.240.0/22 US     arin 2010-08-27                                      AMAZON-02 - Amazon.com, Inc.,US
    ## 29 37963   42.120.194.11    42.120.0.0/16 CN    apnic 2011-02-21     CNNIC-ALIBABA-CN-NET-AP Hangzhou Alibaba Advertising Co.,Ltd.,CN

You could then look up each peer and see how "connected" the top 10 are.

### Introducing `iptools`

The `iptools` package  is a set of tools for a working with IPv4 addresses. The aim is to provide functionality not presently available with any existing R package and to do so with as much speed as possible. To that end, many of the operations are written in `Rcpp` and require installation of the `Boost` libraries. A current, lofty goal is to mimic most of the functionality of the Python `iptools` module and make IP addresses first class R objects.

While `resolv` provides many helpful DNS functions, it is dependent upon the `ldns` library, which may not ever work well under Windows+Rcpp. The `iptools` package provides minimally featured functions for IPv4 `PTR`/`A` record lookups in an effort to (hopefully) make it usable under Windows.

The package also uses the v1 [GeoLite](http://dev.maxmind.com/geoip/legacy/geolite/) MaxMind library to perform basic geolocation of a given IPv4 address. You must manually install both the maxmind library (`brew install geoip` on OS X, `sudo apt-get install libgeoip-dev` on Ubuntu) and the `GeoLiteCity.dat` <http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz> & `GeoLiteASNum.dat` <http://geolite.maxmind.com/download/geoip/database/GeoLiteASNum.dat.gz> files for the geolocation/ASN functions to work. If there's interest in porting to the newer library/GeoLite2 format, I'll consider updating the package.

The following functions are implemented:

*Revolver-ish*

-   `gethostbyaddr` - Returns all `PTR` records associated with an IPv4 address
-   `gethostsbyaddr` - Vectorized version of `gethostbyaddr`
-   `gethostbyname` - Returns all `A` records associated with a hostname
-   `gethostsbyname` - Vectorized version of `gethostbyname`

*IP int/string conversion*

-   `ip2long` - Character (dotted-decimal) IPv4 Address Conversion to long integer
-   `long2ip` - Intger IPv4 Address Conversion to Character

*Validation*

-   `validateIP` - Validate IPv4 addresses in dotted-decimal notation
-   `validateCIDR` - Validate IPv4 CIDRs in dotted-decimal slash notation

*Geo/ASN Lookup*

-   `geoip` - Perform (local) maxmind geolocation on IPv4 addresses (see `?geoip` for details)
-   `asnip` - Perform (local) maxmind AS \# & org lookup on IPv4 addresses (see `?asnip` for details)

*Testing*

-   `randomIPs` - generate a vector of valid, random IPv4 addresses (very helpful for testing)

The following data sets are included:

-   `ianaports` - IANA Service Name and Transport Protocol Port Number Registry
-   `ianaipv4spar` - IANA IPv4 Special-Purpose Address Registry
-   `ianaipv4assignments` - IANA IPv4 Address Space Registry
-   `ianarootzonetlds` - IANA Root Zone Database
-   `ianaprotocolnumbers` - IANA Protocol Numbers

#### `iptools` Installation

    :::r
    devtools::install_git("https://gitlab.dds.ec/bob.rudis/iptools.git")

> NOTE: Under Ubuntu (it probably applies to other variants), this only works with the current version (1.55) of the boost library, which I installed via the [launchpad boost-latest](https://launchpad.net/~boost-latest/+archive/ubuntu/ppa/+packages) package:

    sudo add-apt-repository ppa:boost-latest/ppa
    # sudo apt-get install python-software-properties if "add-apt-repository" is not found
    sudo apt-get update
    sudo apt-get install boost1.55 # might need to use 1.54 on some systems

> `homebrew` (OS X) users can do: `brew install boost` and it should `#justwork`.

The first person(s) to get this working under Windows/mingw + boost/Rcpp gets a free copy of [our book](http://dds.ec/amzn)

We'll give you an opportunity to play with `iptools` before covering some examples.

You are also encouraged to drop a note in the comments here or on github with any issues, suggestions or contributions. We've not quite worked out how we'll be handling public gitlab issues/comments yet, but it's on the `TODO` list.
