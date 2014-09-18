Title: Migrating Table-oriented Web Scraping Code to rvest w/XPath & CSS Selector Examples
Date: 2014-09-17 12:30:35
Category: tools
Tags: r, rstats, rvest
Slug: migrating-to-rvest
Author: Bob Rudis (@hrbrmstr)

I was offline much of the day Tuesday and completely missed Hadley Wickham's tweet about the new [rvest package](https://github.com/hadley/rvest):

<blockquote class="twitter-tweet" lang="en"><p>Are you an <a href="https://twitter.com/hashtag/rstats?src=hash">#rstats</a> user who misses python&#39;s beautiful soup? Please try out rvest (<a href="http://t.co/PeiIHr3jDW">http://t.co/PeiIHr3jDW</a>) and let me know what you think.</p>&mdash; Hadley Wickham (@hadleywickham) <a href="https://twitter.com/hadleywickham/status/510494494819500032">September 12, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

My intrepid colleague (@jayjacobs) informed me of this (and didn't gloat too much). I've got a "pirate day" post coming up this week that involves scraping content from the web and thought folks might benefit from another example that compares the "old way" and the "new way" (Hadley excels at making lots of "new ways" in R :-) I've left the output in with the code to show that you get the same results.

The following shows old/new methods for extracting a table from a web site, including how to use either XPath selectors or CSS selectors in `rvest` calls. To stave of some potential comments: due to the way this table is setup and the need to extract only certain components from the `td` blocks and elements from tags within the `td` blocks, a simple `readHTMLTable` would not suffice.

The old/new approaches are very similar, but I especially like the ability to chain output ala `magrittr`/`dplyr` and not having to mentally switch gears to XPath if I'm doing other work targeting the browser (i.e. prepping data for D3). 

The code (sans output) is in [this gist](https://gist.github.com/hrbrmstr/94c2cacec9b2fe36f435), and IMO the `rvest` package is going to make working with web site data _so_ much easier.

    library(XML)
    library(httr)
    library(rvest)
    library(magrittr)

    # setup connection & grab HTML the "old" way w/httr
    freak_get <- GET("http://torrentfreak.com/top-10-most-pirated-movies-of-the-week-130304/")
    freak_html <- htmlParse(content(freak_get, as="text"))

    # do the same the rvest way, using "html_session" since we may need connection info in some scripts
    freak <- html_session("http://torrentfreak.com/top-10-most-pirated-movies-of-the-week-130304/")

    # extracting the "old" way with xpathSApply
    xpathSApply(freak_html, "//*/td[3]", xmlValue)[1:10]
    
    ##  [1] "Silver Linings Playbook "           "The Hobbit: An Unexpected Journey " "Life of Pi (DVDscr/DVDrip)"        
    ##  [4] "Argo (DVDscr)"                      "Identity Thief "                    "Red Dawn "                         
    ##  [7] "Rise Of The Guardians (DVDscr)"     "Django Unchained (DVDscr)"          "Lincoln (DVDscr)"                  
    ## [10] "Zero Dark Thirty "
    
    xpathSApply(freak_html, "//*/td[1]", xmlValue)[2:11]
    
    ##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10"
    
    xpathSApply(freak_html, "//*/td[4]", xmlValue)
    
    ##  [1] "7.4 / trailer" "8.2 / trailer" "8.3 / trailer" "8.2 / trailer" "8.2 / trailer" "5.3 / trailer" "7.5 / trailer"
    ##  [8] "8.8 / trailer" "8.2 / trailer" "7.6 / trailer"
    
    xpathSApply(freak_html, "//*/td[4]/a[contains(@href,'imdb')]", xmlAttrs, "href")
    
    ##                                    href                                    href                                    href 
    ##  "http://www.imdb.com/title/tt1045658/"  "http://www.imdb.com/title/tt0903624/"  "http://www.imdb.com/title/tt0454876/" 
    ##                                    href                                    href                                    href 
    ##  "http://www.imdb.com/title/tt1024648/"  "http://www.imdb.com/title/tt2024432/"  "http://www.imdb.com/title/tt1234719/" 
    ##                                    href                                    href                                    href 
    ##  "http://www.imdb.com/title/tt1446192/"  "http://www.imdb.com/title/tt1853728/"  "http://www.imdb.com/title/tt0443272/" 
    ##                                    href 
    ## "http://www.imdb.com/title/tt1790885/?"
    
    # extracting with rvest + XPath
    freak %>% html_nodes(xpath="//*/td[3]") %>% html_text() %>% .[1:10]
    
    ##  [1] "Silver Linings Playbook "           "The Hobbit: An Unexpected Journey " "Life of Pi (DVDscr/DVDrip)"        
    ##  [4] "Argo (DVDscr)"                      "Identity Thief "                    "Red Dawn "                         
    ##  [7] "Rise Of The Guardians (DVDscr)"     "Django Unchained (DVDscr)"          "Lincoln (DVDscr)"                  
    ## [10] "Zero Dark Thirty "
    
    freak %>% html_nodes(xpath="//*/td[1]") %>% html_text() %>% .[2:11]
    
    ##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10"
    
    freak %>% html_nodes(xpath="//*/td[4]") %>% html_text() %>% .[1:10]
    
    ##  [1] "7.4 / trailer" "8.2 / trailer" "8.3 / trailer" "8.2 / trailer" "8.2 / trailer" "5.3 / trailer" "7.5 / trailer"
    ##  [8] "8.8 / trailer" "8.2 / trailer" "7.6 / trailer"
    
    freak %>% html_nodes(xpath="//*/td[4]/a[contains(@href,'imdb')]") %>% html_attr("href") %>% .[1:10]
    
    ##  [1] "http://www.imdb.com/title/tt1045658/"  "http://www.imdb.com/title/tt0903624/" 
    ##  [3] "http://www.imdb.com/title/tt0454876/"  "http://www.imdb.com/title/tt1024648/" 
    ##  [5] "http://www.imdb.com/title/tt2024432/"  "http://www.imdb.com/title/tt1234719/" 
    ##  [7] "http://www.imdb.com/title/tt1446192/"  "http://www.imdb.com/title/tt1853728/" 
    ##  [9] "http://www.imdb.com/title/tt0443272/"  "http://www.imdb.com/title/tt1790885/?"
    
    # extracting with rvest + CSS selectors
    freak %>% html_nodes("td:nth-child(3)") %>% html_text() %>% .[1:10]
    
    ##  [1] "Silver Linings Playbook "           "The Hobbit: An Unexpected Journey " "Life of Pi (DVDscr/DVDrip)"        
    ##  [4] "Argo (DVDscr)"                      "Identity Thief "                    "Red Dawn "                         
    ##  [7] "Rise Of The Guardians (DVDscr)"     "Django Unchained (DVDscr)"          "Lincoln (DVDscr)"                  
    ## [10] "Zero Dark Thirty "
    
    freak %>% html_nodes("td:nth-child(1)") %>% html_text() %>% .[2:11]
    
    ##  [1] "1"  "2"  "3"  "4"  "5"  "6"  "7"  "8"  "9"  "10"
    
    freak %>% html_nodes("td:nth-child(4)") %>% html_text() %>% .[1:10]
    
    ##  [1] "7.4 / trailer" "8.2 / trailer" "8.3 / trailer" "8.2 / trailer" "8.2 / trailer" "5.3 / trailer" "7.5 / trailer"
    ##  [8] "8.8 / trailer" "8.2 / trailer" "7.6 / trailer"
    
    freak %>% html_nodes("td:nth-child(4) a[href*='imdb']") %>% html_attr("href") %>% .[1:10]
    
    ##  [1] "http://www.imdb.com/title/tt1045658/"  "http://www.imdb.com/title/tt0903624/" 
    ##  [3] "http://www.imdb.com/title/tt0454876/"  "http://www.imdb.com/title/tt1024648/" 
    ##  [5] "http://www.imdb.com/title/tt2024432/"  "http://www.imdb.com/title/tt1234719/" 
    ##  [7] "http://www.imdb.com/title/tt1446192/"  "http://www.imdb.com/title/tt1853728/" 
    ##  [9] "http://www.imdb.com/title/tt0443272/"  "http://www.imdb.com/title/tt1790885/?"
    
    # building a data frame (which is kinda obvious, but hey)
    data.frame(movie=freak %>% html_nodes("td:nth-child(3)") %>% html_text() %>% .[1:10],
               rank=freak %>% html_nodes("td:nth-child(1)") %>% html_text() %>% .[2:11],
               rating=freak %>% html_nodes("td:nth-child(4)") %>% html_text() %>% .[1:10],
               imdb.url=freak %>% html_nodes("td:nth-child(4) a[href*='imdb']") %>% html_attr("href") %>% .[1:10],
               stringsAsFactors=FALSE)
               
    ##                                 movie rank        rating                              imdb.url
    ## 1            Silver Linings Playbook     1 7.4 / trailer  http://www.imdb.com/title/tt1045658/
    ## 2  The Hobbit: An Unexpected Journey     2 8.2 / trailer  http://www.imdb.com/title/tt0903624/
    ## 3          Life of Pi (DVDscr/DVDrip)    3 8.3 / trailer  http://www.imdb.com/title/tt0454876/
    ## 4                       Argo (DVDscr)    4 8.2 / trailer  http://www.imdb.com/title/tt1024648/
    ## 5                     Identity Thief     5 8.2 / trailer  http://www.imdb.com/title/tt2024432/
    ## 6                           Red Dawn     6 5.3 / trailer  http://www.imdb.com/title/tt1234719/
    ## 7      Rise Of The Guardians (DVDscr)    7 7.5 / trailer  http://www.imdb.com/title/tt1446192/
    ## 8           Django Unchained (DVDscr)    8 8.8 / trailer  http://www.imdb.com/title/tt1853728/
    ## 9                    Lincoln (DVDscr)    9 8.2 / trailer  http://www.imdb.com/title/tt0443272/
    ## 10                  Zero Dark Thirty    10 7.6 / trailer http://www.imdb.com/title/tt1790885/?