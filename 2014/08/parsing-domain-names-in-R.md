Title: Parsing Domain Names in R with tldextract
Date: 2014-08-04 22:30:00
Category: tools
Tags: r, rstats, dns
Slug: parsing-domain-names-in-R
Author: Jay Jacobs(@jayjacobs)

The R Language is really good at data and statistical analysis, but when
it comes to working with information security data it has a few holes
that need plugging up. Bob has been doing a couple of posts using Rcpp
to do things like [Basic DNS
Lookups](http://datadrivensecurity.info/blog/posts/2014/Aug/basic-forward-and-reverse-lookups-in-r-with-rcpp/),
[TXT
lookups](http://datadrivensecurity.info/blog/posts/2014/Apr/making-better-dns-txt-record-lookups-with-rcpp/),
and [IPv4
Conversions](http://datadrivensecurity.info/blog/posts/2014/May/speeding-up-ipv4-address-conversion-in-r/).
I wanted to add to some of that work with a quick package for parsing
domain names.

While _\*.com_, _\*.net_ and _\*.org_ top-level domains are easy
to parse, the rest of the world gets messy rather quick. Just taking the
entry after the last dot creates problems for top-level domains like
anything in _\*.com.uk_. Or to make things even more complicated, the
name of "*us-west-1.compute.amazonaws.com*" is considered (for name
parsing) to be a top-level domain and the domain name we'd want to
process is the name that would appear before the *us-west-1* in that
name.

### Introducing TLD Extract (the R version)

It's always easier to imitate rather than reinvent, so I took some time
to read through the
[tldextract](https://github.com/john-kurkowski/tldextract) Python
package, and used that to test my code was executing properly during
development so I used the same name for the R pacakge. The data for the
package is drawn from the same source as the python package, [the Public
Suffix List](https://www.publicsuffix.org/) from the Mozilla Foundation.
For convenience, I include a cached version of the data so it can run
offline.

### Installation

To install this package, use the devtools package:

    devtools::install_github("jayjacobs/tldextract")

### Usage

Using the package is fairly straight forward, it will return a data frame with the 
original name and seperate columns for each parsed component.

    library(tldextract)

    # use the cached lookup data, simple call
    tldextract("www.google.com")

    ##             host subdomain domain tld
    ## 1 www.google.com       www google com

    # it can take multiple domains at the same time
    tldextract(c("www.google.com", "www.google.com.ar", "googlemaps.ca", "tbn0.google.cn"))

    ##                host subdomain     domain    tld
    ## 1    www.google.com       www     google    com
    ## 2 www.google.com.ar       www     google com.ar
    ## 3     googlemaps.ca      <NA> googlemaps     ca
    ## 4    tbn0.google.cn      tbn0     google     cn

The specification for the top-level domains is cached in the package and
is viewable.

    # view and update the TLD domains list in the tldnames data
    data(tldnames)
    head(tldnames)

    ## [1] "ac"     "com.ac" "edu.ac" "gov.ac" "net.ac" "mil.ac"

If the cached version is out of data and the package isn't updated, the
data can be manually loaded, and then passed into the function.

    # get most recent TLD listings
    tld <- getTLD() # optionally pass in a different URL than the default
    manyhosts <- c("pages.parts.marionautomotive.com", "www.embroiderypassion.com", 
                   "fsbusiness.co.uk", "www.vmm.adv.br", "ttfc.cn", "carole.co.il",
                   "visiontravail.qc.ca", "mail.space-hoppers.co.uk", "chilton.k12.pa.us")
    tldextract(manyhosts, tldnames=tld)

    ##                               host   subdomain            domain       tld
    ## 1 pages.parts.marionautomotive.com pages.parts  marionautomotive       com
    ## 2        www.embroiderypassion.com         www embroiderypassion       com
    ## 3                 fsbusiness.co.uk        <NA>        fsbusiness     co.uk
    ## 4                   www.vmm.adv.br         www               vmm    adv.br
    ## 5                          ttfc.cn        <NA>              ttfc        cn
    ## 6                     carole.co.il        <NA>            carole     co.il
    ## 7              visiontravail.qc.ca        <NA>     visiontravail     qc.ca
    ## 8         mail.space-hoppers.co.uk        mail     space-hoppers     co.uk
    ## 9                chilton.k12.pa.us        <NA>           chilton k12.pa.us

And there we have it!

One last thing, this is the first package I created with unit tests.
This package is really simple and adding in unit tests seamed like a
no-brainer. After reading through Hadley Wickham's [Advanced
R](http://adv-r.had.co.nz/Philosophy.html) online book and exploring how
other packages implement the
[testthat](https://github.com/hadley/testthat) package, I implemented a
few simple tests. If you are creating (or about to create) R packages,
look at this package for the incredibly simple unit tests included with
it!
