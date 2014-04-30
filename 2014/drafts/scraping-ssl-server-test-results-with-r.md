Title: Scraping SSL Labs Server Test Results With R
Date: 2014-04-29 21:30:00
Category: munging
Tags: data munging, xml, R, rstats, scraping
Slug: scraping-ssl-server-test-results-with-r
Author: Bob Rudis (@hrbrmstr)

>**NOTE**: Qualys allows automated access to their SSL Server Test site in their [T&C's](https://www.ssllabs.com/about/terms.html), and the R fucntion/script provided here does its best to adhere to their guidelines. However, if you launch multiple scripts at one time and catch their attention you will, no doubt, be banned.

This post will show you how to do some basic web page data scraping with R. To make it more palatable to those in the security domain, we'll be scraping the results from Qualys' SSL Labs [SSL Test](https://www.ssllabs.com/ssltest/) site by building an R function that will:

- fetch the contents of a URL with `RCurl`
- process the HTML page tags with R's `XML` library
- identify the key elements from the page that need to be scraped
- organize the results into a usable R data structure

You can skip ahead to the code at the end (or in [this gist](https://gist.github.com/hrbrmstr/11387877)) or read on for some expository that isn't in the code's comments.

### Setting up the script and processing flow

We'll need some assistance from three R packages to perform the scraping, processing and transformation tasks:

    :::rsplus
    library(RCurl) # scraping
    library(XML)   # XML (HTML) processing
    library(plyr)  # data transformation

If you poke at the SSL Test site with a few different URLs, you'll see there are three primary inputs to the `GET` request we'll need to issue:

- `d` (the domain)
- `s` (the IP address to test)
- `ignoreMismatch` (which we'll leave as '`on`')

You'll also see that there's often a delay between issuing a request and getting the results, so we'll need to build in a `GET`+check-loop (like the javascript on the page does automagically). Finally, when the results are eventually displayed they are (at least for this example) usually either `"Overall Rating"` or `"Assessment"` and, we'll use that status result in our tests for what to return.

We'll account for the domain and IP address in the function parameters along with the amount of time we should pause between `GET`+check attempts. It's also a good idea to provide a way to pass in any extra `curl` options (e.g. in the event folks are behind a proxy server and need to input that to make the requests work). We'll define the function with some default parameters:

    get_rating <- function(site="rud.is", ip="", pause=5, curl.opts=list()) {
    }

This definition says that if we just call `get_rating()`, it will 

- default to using `"rud.is"` as the domain (you can pick what you want in your implementation)
- not supply an IP address (which the script will then have to lookup with `nsl`)
- will pause 5s between `GET`+check attempts
- pass no extra `curl` options

### Getting into the details

For the IP address logic, we'll have to test if we passed in an an address string and perform a lookup if not:

    # try to resolve IP if not specified; if no IP can be found, return
    # a "NA" data frame
    
      if (ip == "") {
        tmp <- nsl(site)
        if (is.null(tmp)) {
          return(data.frame(site=site, ip=NA, Certificate=NA, 
                            Protocol.Support=NA, Key.Exchange=NA, 
                            Cipher.Strength=NA)) }
        ip <- tmp
      }

(don't worry about the `return(...)` part yet, we'll get there in a bit).

Once we have an IP address, we'll need to make the call to the `ssllabs.com` test site and perform the check loop:

    # get the contents of the URL (will be the raw HTML text)
    # build the URL with sprintf
    
    rating.dat <- getURL(sprintf("https://www.ssllabs.com/ssltest/analyze.html?d=%s&s=%s&ignoreMismatch=on", site, ip), .opts=curl.opts)
    
    # while we don't find some indication of a completed request, 
    # pause and try again
     
    while(!grepl("(Overall Rating|Assessment failed)", rating.dat)) {    
    
      Sys.sleep(pause)
    
      rating.dat <- getURL(sprintf("https://www.ssllabs.com/ssltest/analyze.html?d=%s&s=%s&ignoreMismatch=on", site, ip), .opts=curl.opts)
    
    }

We can then start making some decisions based on the results:

    # if the assessment failed, return a data frame of NA's
    
    if (grepl("Assessment failed", rating.dat)) {
      return(data.frame(site=site, ip=NA, Certificate=NA, 
                        Protocol.Support=NA, Key.Exchange=NA, 
                        Cipher.Strength=NA))
    }
    
    # otherwise, parse the resultant HTML
    
    x <- htmlTreeParse(rating.dat, useInternalNodes = TRUE)    

Unfortunately, the results are not "consistent". While there are plenty of uniquely identifiable `<div>`s, there are enough differences between runs that we have to be a bit generic in our selection of data elements to extract. I'll leave the `view-source:` of a result as an exercise to the reader. For this example, we'll focus on extracting:

- the overall rating (A-F)
- the "Certificate" score
- the "Protocol Support" score
- the "Key Exchange" score
- the "Cipher Strength" score

There are *plenty* of additional fields to extract, but you should be able to extrapolate and grab what you want to from the rest of the example.

### Extracting the results

We'll need to delve into [XPath](http://www.w3schools.com/xpath/xpath_syntax.asp) to extract the `<div>` values. We'll use the `xpathSApply` function to perform this task. Since there sometimes is a `<span>` tag within the `<div>` for the rating and since the rating has a class tag to help identify which color it should be, we use a `starts-with` selection parameter to just get anything beginning with `rating_`. If it returns an R `list` structure, we know we have the one with a `<span>` element, so we re-issue the call with that extra XPath component.

    rating <- xpathSApply(x,"//div[starts-with(@class,'rating_')]/text()", xmlValue)
    if (class(rating) == "list") {
      rating <- xpathSApply(x,"//div[starts-with(@class,'rating_')]/span/text()", xmlValue)
    }

For the four attributes (and values) we'll be extracting, we can use the `getNodeSet`  call which will give us all of them into a structure we can process with `xpathSApply`

    labs <- getNodeSet(x,"//div[@class='chartBody']/div[@class='chartRow']/div[@class='chartLabel']")
    vals <- getNodeSet(x,"//div[@class='chartBody']/div[@class='chartRow']/div[starts-with(@class,'chartValue')]")
    
    # convert them to vectors
    
    labs <- xpathSApply(labs[[1]], "//div[@class='chartLabel']/text()", xmlValue)
    vals <- xpathSApply(vals[[1]], "//div[starts-with(@class,'chartValue')]/text()", xmlValue)

At this point, `labs` will be a vector of label names and `vals` will be the corresponding values. We'll put them, the original domain and the IP address into a data frame:

    # rbind will turn the vector into row elements, with each
    # value being in a column
    
    rating.result <- data.frame(site=site, ip=ip, 
                                rating=rating, rbind(vals), 
                                row.names=NULL)
                                
    # we use the labs vector as the column names (in the right spot)      
    colnames(rating.result) <- c("site", "ip", "rating", 
                                  gsub(" ", "\\.", labs))

and return the result:
  
    return(rating.result)

### Finishing up

If we run the whole function on one domain we'll get a one-row data frame back as a result. If we use `ldply` from the `plyr` package to run the `get_rating` function repeatedly on a vector of domains, it will combine them all into one whole data frame. For example:

    sites <- c("rud.is", "stackoverflow.com", "er-ant.com")
    ratings <- ldply(sites, get_rating)
    ratings
    ##                site              ip rating Certificate Protocol.Support Key.Exchange Cipher.Strength
    ## 1            rud.is  184.106.97.102      B         100               70           80              90
    ## 2 stackoverflow.com 198.252.206.140      A         100               90           80              90
    ## 3        er-ant.com            <NA>   <NA>        <NA>             <NA>         <NA>            <NA>

There are many tweaks you can make to this function to extract more data and perform additional processing. If you make some of your own changes, you're encouraged to add to the gist (link above & below) and/or drop a note in the comments.

Hopefully you've seen how well-suited R is for this type of operation and have been encouraged to use it in your next attempt at some site/data scraping.

<div style="font-size:12px">
<script src="https://gist.github.com/hrbrmstr/11387877.js"></script>
</diV>