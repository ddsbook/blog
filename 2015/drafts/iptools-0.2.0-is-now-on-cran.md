Title: iptools 0.2.0 is now on CRAN
Date: 2015-07-01 20:10:16
Category: blog
Tags: blog, r, rstats, ip
Slug: iptools-0.2.0-is-now-on-cran
Author: Bob Rudis (@hrbrmstr)

We are happy to announce that the `iptools` package is now [on CRAN](http://cran.r-project.org/web/packages/iptools/index.html). Formerly only available [on GitHub](https://github.com/hrbrmstr/iptools), `iptools` now compiles under Debian/Ubuntu, Fedora/CentOS/RedHat and Mac OS X (we're still working on that _other_ operating system). 

[Oliver](https://twitter.com/quominus) (the package co-author and on-CRAN instigator) wrote some [excellent](https://github.com/hrbrmstr/iptools/blob/master/vignettes/introduction_to_iptools.Rmd) [vignettes](https://github.com/hrbrmstr/iptools/blob/master/vignettes/iptools_datasets.Rmd) that cover the functionality of the package in-depth, but here's a short-list of what you can find/expect in `iptools`:

- _wicked-fast_ IP conversions (`148` _milliseconds_ for converting 1,000,000 addresses to integers and `700` milliseconds the other way 'round)
- IP classification with `ip_classify` which can distinguish IPv4, IPv6 and non-IP address inputs
- hostname resolution (both ways) with `hostname_to_ip` and `ip_to_hostname`

plus, ways to handle CIDR blocks and generate random (but valid) IPv4 addresses.

We've also included some core [IANA](http://www.iana.org/) datasets and provided routines to refresh them.

`iptools` pairs nicely with [urltools](http://cran.r-project.org/web/packages/urltools/index.html), [webtools](https://github.com/Ironholds/webtools) and [rgeolocate](https://github.com/Ironholds/rgeolocate), enabling many avenues of feature generation (for machine learning) and data analysis for cybersecurity and web analytics.

If you manage to get it working well on Windows, drop us a note in the comments (you'll get a free copy of [Data-Driven Security](http://dds.ec/amzn)) and if you've use `iptools` in any cool projects hit us up here or on Twitter so we can get you on [the podcast](http://podcast.datadrivensecurity.info).