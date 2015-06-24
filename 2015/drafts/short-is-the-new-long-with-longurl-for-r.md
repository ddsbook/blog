Title: Short is the new Long with longurl for R (plus working with weblogs & URLs in R)
Date: 2015-06-23 23:00:48
Category: blog
Tags: blog, r, rstats, ropensec
Slug: short-is-the-new-long-with-longurl-for-r
Author: Bob Rudis (@hrbrmstr)

Necessity is the mother of invention and I had the opportunity today to take an R package from development to CRAN in less than the span of 24 hours.

Despite being on vacation, I answered an R question on StackOverflow pertaining to the use of `decode_short_url` from the `twitteR` package. That function has no option for validity checking (i.e. whether the resultant URL was expanded and exists). It's also not vectorized. The `twitteR::decode_short_url` function uses the [LongURL service](http://longurl.org), which has a dirt simple API to both get a list of all long URL domains it knows about and expand a shortened URL (if it can). I wrapped this API into a [small R package](https://github.com/hrbrmstr/longurl) right after I answered the SO question and proceded to add the finishing touches to be able to, then, submit it to CRAN. Attempt #1 failed, but I amended the `DESCRIPTION` file after very helpful suggestion from the volunteer CRAN maintainers and it's now [on CRAN](http://cran.r-project.org/web/packages/longurl/index.html). That makes CRAN in Par 2!

As Jay pointed out to me later in the day, the attention to detail by the CRAN Guardians is one of the things that helps maintain super-high quality in the R community and truly sets us apart from those "other" data science languages (I _might_ have taken _some_ liberties with Jay's original quote to me).

###Why do we need longurl?

I'll point readers to a [paper](http://www.syssec-project.eu/m/page-media/3/maggi-longshore-www13.pdf)&mdash;*Two Years of Short URLs Internet Measurement: Security Threats and Countermeasures* [PDF]&mdash;by Maggi, Frossi, Zanero, Stringhini, Stone-Gross, Kruegel & Vigna where the authors look at the potential (and actual) evil behind short URLs. Many things can hide there, from malware to phishing sites and knowing both the short and full URL can help defenders stop attacks before they are fully successful.

###How to use longurl

I took a sampling of `bit.ly` and `t.co` referer domains from some `datadrivensecurity.info` weblogs (you can grab that [here](https://gist.github.com/hrbrmstr/186aec0f0db62347ea32)) to show how to use this and other packages to parse weblogs, expand URLs and extract various bits of info from them, soley with R. I'll be using packages from myself, [Oliver Keyes](https://twitter.com/quominus), [Jay Jacobs](https://twitter.com/jayjacobs) & [Hadley Wickham](https://twitter.com/hadleywickham/) to accomplish this task.

All of the packages can be `install.packages` from CRAN, except for `webtools`. For that, you can just `install.github("ironholds/webtools")`.

Let's get package loading out of the way:

    :::r
    library(webtools)
    library(dplyr)
    library(stringr)
    library(longurl)
    library(urltools)

Oliver made it super-easy to read in web logs. I use the "combined" common log format (CLF) on the blog's web server, which can be parsed in one line of R:

    :::r
    log <- read_combined("web.log", has_header=FALSE)
    
    glimpse(log)
    
    ## Observations: 484
    ## Variables:
    ## $ ip_address        (chr) "198.11.246.195", "75.68.128.29", "36.80.104...
    ## $ remote_user_ident (chr) NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, ...
    ## $ local_user_ident  (chr) NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, ...
    ## $ timestamp         (time) 2015-06-14 02:07:49, 2015-06-13 01:35:00, 2...
    ## $ request           (chr) "GET /blog/posts/2014/Dec/ponemon/ HTTP/1.1"...
    ## $ status_code       (int) 200, 200, 200, 200, 301, 200, 200, 301, 200,...
    ## $ bytes_sent        (int) 10036, 6404, 22120, 6283, 185, 6132, 23667, ...
    ## $ referer           (chr) "http://t.co/G4XiI9USB3", "http://t.co/j9Rmm...
    ## $ user_agent        (chr) "Mozilla/5.0 (Windows NT 6.3; WOW64) AppleWe...

To get some short URLs to expand we only need focus the `referer` for this example, so let's:

- remove all the query strings (this is just an example, after all)
- only work on the unique ones
- expand them

Here's the code:

    :::r
    log %>%
      mutate(referer=str_replace(referer, "\\?.*$", "")) %>%
      distinct(referer) %>%
      .$referer %>%
      expand_urls(check=FALSE, warn=FALSE) -> referers
      
    glimpse(referers)
    
    ## Observations: 61
    ## Variables:
    ## $ orig_url     (chr) "http://t.co/G4XiI9USB3", "http://t.co/j9RmmOY9Kr", "http:...
    ## $ expanded_url (chr) "http://datadrivensecurity.info/blog/posts/2014/Dec/ponemo...

Now that we have a nice set of expanded URLs, we can parse them into their components: 

    :::r
    parsed_refs <- url_parse(referers$expanded_url)

We went from 484 potential URLs to shorten to 61 (after de-duping).

**Please** be kind to the LongURL service and also note that parsing huge lists of URLs can take a while, especially if you turn on validity checking. You'll at least get a free progress bar when using an interactive session (unless you disable it).

    :::r
    glimpse(parsed_refs)
    
    ## Observations: 61
    ## Variables:
    ## $ scheme    (chr) "http", "http", "http", "http", "http", "http", "http", "http...
    ## $ domain    (chr) "datadrivensecurity.info", "datadrivensecurity.info", "datadr...
    ## $ port      (chr) "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "...
    ## $ path      (chr) "blog/posts/2014/dec/ponemon/", "blog/", "podcast/data-driven...
    ## $ parameter (chr) "", "", "", "ie=utf8&qid=1374598875&sr=8-1&keywords=best+secu...
    ## $ fragment  (chr) "", "", "", "", "", "", "gsc.tab=0&gsc.q=hosting", "", "", ""...

With parsed URLs in hand we can can proceed with any other bits of analysis, such as seeing the top domains (which is, unsurprisingly, this very blog):

    :::r
    sort(table(parsed_refs$domain))
    
    ##             de.buyvip.com iosappstar.blogspot.co.at        serv.adwingate.com 
    ##                         1                         1                         1 
    ##        sony.attributed.to           sports.bwin.com            www.amazon.com 
    ##                         1                         1                         1 
    ##           www.godaddy.com            www.google.com                    dds.ec 
    ##                         1                         1                         2 
    ##            www.netnews.at   datadrivensecurity.info 
    ##                         2                        49 

###Fin

This was (obviously) a trivial example to get you started on using some of these truly helpful packages when doing URL/domain analysis in R. These URL/domain components can further be used to develop features for machine learning pipelines, metrics/reports or even forensic investigations. If you have other helpful R packages for the cybersecurity domain or use `longurl` or any of the other packages in an interesting way, drop a note in the comments.
