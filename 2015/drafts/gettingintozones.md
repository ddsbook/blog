Title: Getting into the zone(s) with R + jsonlite
Date: 2015-10-07
Tags: blog, r, rstats
Category: blog, r, rstats
Author: Bob Rudis (@hrbrmstr)
Slug: getting-into-the-zone-s-with-r-jsonlite
Status: draft

We have some *strange* data in cybersecurity. One of the (IMO) stranger data files is a Domain Name System (DNS) [zone file](https://en.wikipedia.org/wiki/Zone_file). This file contains mappings between domain names and IP addresses (and other things) represented by "resource records".

Here's an example for the dummy/example domain `example.com`:

    $ORIGIN example.com.     ; designates the start of this zone file in the namespace
    $TTL 1h                  ; default expiration time of all resource records without their own TTL value
    example.com.  IN  SOA   ns.example.com. username.example.com. ( 2007120710 1d 2h 4w 1h )
    example.com.  IN  NS    ns                    ; ns.example.com is a nameserver for example.com
    example.com.  IN  NS    ns.somewhere.example. ; ns.somewhere.example is a backup nameserver for example.com
    example.com.  IN  MX    10 mail.example.com.  ; mail.example.com is the mailserver for example.com
    @             IN  MX    20 mail2.example.com. ; equivalent to above line, "@" represents zone origin
    @             IN  MX    50 mail3              ; equivalent to above line, but using a relative host name
    example.com.  IN  A     192.0.2.1             ; IPv4 address for example.com
                  IN  AAAA  2001:db8:10::1        ; IPv6 address for example.com
    ns            IN  A     192.0.2.2             ; IPv4 address for ns.example.com
                  IN  AAAA  2001:db8:10::2        ; IPv6 address for ns.example.com
    www           IN  CNAME example.com.          ; www.example.com is an alias for example.com
    wwwtest       IN  CNAME www                   ; wwwtest.example.com is another alias for www.example.com
    mail          IN  A     192.0.2.3             ; IPv4 address for mail.example.com
    mail2         IN  A     192.0.2.4             ; IPv4 address for mail2.example.com
    mail3         IN  A     192.0.2.5             ; IPv4 address for mail3.example.com

(that came from the Wikipedia link above).

DNS is a hierarchical, distributed service and companies reel in the Benjamins by parsing these files from the [top level domains](https://en.wikipedia.org/wiki/Top-level_domain) (TLDs) and providing data in a more structured format. Some also capture passive DNS data (i.e. data obtained from the queries to--usually--large-scale DNS server deployments) and integrate it into the massive data set.

The TLD zones are really what make the internet "go". They provide pointers to everyting below them so the entire system knows where to route requests. Monitoring these TLD zone files for changes can reveal many things both operationally benign and malicious. Thankfully, you can get access to some of the (now *hundreds* of) TLD zones by filling out a form over [at ICANN](https://czds.icann.org/). You won't get approval for all of the TLD zone files and you'll need to go to other sites to try to get the big guns like `.com`, `.net` & `.org`.

Once you have a zone file you need to be able to do something with it. R did not have a zone file parser, but [now it does](https://github.com/hrbrmstr/zoneparser) thanks to the [V8 package](https://cran.rstudio.com/web/packages/V8/index.html) and a modified version of the Node.js [dns-zonefile module](https://github.com/elgs/dns-zonefile).

### Why V8?

I had a dual purpose for this post. One was to introduce the `zoneparser` package, but the other was to show how you can add missing functionality to R with V8. Shimming JavaScript (or even Java or other languages for that matter) won't necessarily get you the bare-metal performance of implementing something in R or Rcpp, but it *will* get you functional *quickly* and you can focus on Getting Things Done now and performance later. This recently happened with the package [`humanparser`](https://github.com/hrbrmstr/humanparser) that I wrote to answer a question on Stack Overflow. It's based on a Node.js module of the same name and is written using V8. Oliver Keyes spun that into the Rcpp-backed [`humaniformat`](https://github.com/hrbrmstr/humaniformat) package (and added some functionality) that is *much* faster.

For these TLD zone files, I only need to process them once a day and there aren't thousands or tens of thousands of them. Rather than code up a parser in R or munge some existing C/C++ domain parser code into an R package, All I had to do was this:

``` r
#' Parse a Domain Name System (DNS) zone file
#'
#' @param path path to DNS zone file to parse
#' @return \code{list} with DNS zone parsed
#' @export
#' @examples
#' parse_zone(system.file("zones/20151001-wtf-zone-data.txt", package="zoneparser"))
parse_zone <- function(path) {
  ct$call("zonefile.parse", paste(readLines(path), collapse="\n"))
}

.onAttach <- function(libname, pkgname) {

  ct <<- V8::new_context()
  ct$source(system.file("js/zoneparser.js", package="zoneparser"))

}
```

Those are the only two function in the package. The `.onAttach` sets up a V8 JavaScript context for `parse_zone` to use and loads the slightly modified `zoneparser.js` `[browserified](https://cran.rstudio.org/web/packages/V8/vignettes/npm.html) JavaScript file which makes the function`zonefile.parse()\` available to the context.

The `parse_zone` function takes in a file path to a zone file and returns a parsed structure. And, it's as easy to use as:

``` r
library(zoneparser)

example <- parse_zone("example-tld.txt")

# see all the resource records types that were parsed
(names(example))
```

    ## [1] "$origin" "$ttl"    "soa"     "ns"      "mx"      "a"       "aaaa"   
    ## [8] "cname"

``` r
# look at the mail exchangers
(example$mx)
```

    ##           name preference               host
    ## 1 example.com.         10  mail.example.com.
    ## 2            @         20 mail2.example.com.
    ## 3            @         50              mail3

Those can be easily exported into a database or structured plain text files for further data science-y processing.

### Fin

As of this post, there are ~198,000 Node.js modules out there and tons of browser-oriented JavaScript libraries. Many of these can be easily made to work in V8 (some cannot due to lack of functionality in the V8 engine).

If you have a "plumbing" task missing from R that needs implementing, try the V8/JavaScript route first since it took me less than 10 minutes to code up that package (I tweaked documentation, etc afterwards, though). You don't want to be three days into an Rcpp implementation when you "could have just used V8"!

<center>
<iframe width="560" height="315" src="https://www.youtube.com/embed/PUPdW3ba6F4" frameborder="0" allowfullscreen>
</iframe>
</center>

