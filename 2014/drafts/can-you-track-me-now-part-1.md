Title: Can You Track Me Now? (Visualizing Xfinity Wi-Fi Hotspot Coverage) [Part 1] 
Date: 2014-06-06 21:00:00
Category: blog
Status: draft
Tags: rstats, r, datavis, wifi, cartography, maps
Slug: can-you-track-me-now-part-1
Author: Bob Rudis (@hrbrmstr)

>This is the first of a two-part series. Part 1 sets up the story and goes into how to discover, digest & reformat the necessary data. Part 2 will show how to perform some basic visualizations and then how to build beautiful & informative density maps from the data and offer some suggestions as to how to prevent potential tracking.

Xfinity has a [Wi-Fi hotspot offering](http://wifi.comcast.com/) that they offer through a partnership with [BSG Wireless](http://bsgwireless.com/). Customers of Xfinity get access to the hotspots for "free" and you can pay for access to them if you aren't already a customer. I used the service a while back in near area where I live (which is just southwest of the middle of nowhere) when I needed internet access and 3G/4G connectivity was non-existent.

Since that time, I started noticing regular associations to Xfinity hotspots and also indicators saying it was available (i.e. when Wi-Fi was "off" on my phone but not *really* off). When driving, that caused some hiccups with streaming live audio since I wasn't in a particular roaming area long enough to associate and grab data, but was often in range *just* long enough to temporarily disrupt the stream.

On a recent family+school trip to D.C., I noticed nigh pervasive coverage of Xfinity Wi-Fi as we went around the sights (with varied levels of efficacy when connecting to them). That finally triggered a *"Hrm. Somewhere in their vast database, they know I was in Maine a little while ago and now am in D.C."*. There have been plenty of articles over the years on the privacy issues of hotspots, but this made me want to dig into just how pervasive the potential for tracking was on Xfinity Wi-Fi.

>**DISCLAIMER** I have no proof&mdash;nor am I suggesting&mdash;that Xfinity or BSG Wireless **is** actually maintaining records of associations or probes from mobile devices. However, the ToS & privacy pages on each of their sites did not leave me with any tpye of warm/fuzzy feeling that this data is not&mdash;in fact&mdash;being used for tracking purposes.

### Digging for data

Since the Xfinity Wi-Fi site suggests using their mobible app to find hotspots, I decided to grab it for both my iPhone & Galaxy S3 and see what type of data might be available. I first zoomed out to the seacoast region to get a feel for the Xfinity Wi-Fi coverage:

<center><a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-android.png"><img width=200 style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-android.png"/></a></center>

Yikes! If BSG (or any similar service) is, indeed, recording all associations & probes, it looks like there's almost nowhere to go in the seacoast area without being tracked.

Not wanting to use a tiny screen to continue my investigations, I decided to poke around the app a bit to see if there might be any way to get the locations of the hotspots to work with in R. Sure enough, there was:

<center>
  <a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-database-1.png"><img width=200 style="max-width:50%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-database-1.png"/></a>
  <a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-database-2.png"><img width=200 style="max-width:50%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-database-2.png"/></a>
</center>

I fired up [Burp Proxy](http://portswigger.net/burp/proxy.html), reconfigured my devices to use it and recorded session as I poked around the mobile app/tool. There were *"are you there?"* checks before almost every API call, but I was able to see calls to a "discovery" service as well as the URLs for the region datasets.

The following Burp Proxy intercept shows that the app requesting data from the "discovery" API and receiving a JSON response:

**REQUEST**

>(Host: http://datafeed.bsgwireless.com)

    :::http
    POST /ajax/finderDataService/discover.php HTTP/1.1
    Accept-Encoding: gzip,deflate
    Content-Length: 40
    Content-Type: application/x-www-form-urlencoded
    Host: datafeed.bsgwireless.com
    Connection: Keep-Alive

    api_key=API_KEY_STRING_FROM_BURP_INTERCEPT

**RESPONSE**

    :::http
    HTTP/1.1 200 OK
    Date: Sat, 31 May 2014 16:20:41 GMT
    Server: Apache/2.2.22 (Debian)
    X-Powered-By: PHP/5.4.4-14+deb7u9
    Set-Cookie: PHPSESSID=mci434v907571ihq7d16vtmce0; path=/
    Expires: Thu, 19 Nov 1981 08:52:00 GMT
    Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0
    Pragma: no-cache
    Vary: Accept-Encoding
    Content-Length: 1306
    Keep-Alive: timeout=5, max=100
    Connection: Keep-Alive
    Content-Type: text/html
            {"success":true,"results":{"baseURL":"http:\/\/comcast.datafeed.bsgwireless.com\/data\/comcast","fileList":[{"id":"45","name":"metadata.sqlite","title":"Metadata","description":null,"lastUpdated":"20140513","fileSize":"11264","txSize":"3210","isMeta":true},{"id":"51","name":"finder_comcast_matlantic.sqlite","title":"Mid-Atlantic","description":"DC, DE, MD, NJ, PA, VA, WV","lastUpdated":"20140513","fileSize":"9963520","txSize":"2839603","isMeta":false},{"id":"52","name":"finder_comcast_west.sqlite","title":"West","description":"AK, AZ, CA, CO, HI, ID, MT, NV, NM, ND, OR, SD, UT, WA, WY","lastUpdated":"20140513","fileSize":"5770240","txSize":"1644518","isMeta":false},{"id":"53","name":"finder_comcast_midwest.sqlite","title":"Midwest","description":"AR, IL, IN, IA, KS, KY, MI, MN, MO, NE, OH, OK, WI","lastUpdated":"20140513","fileSize":"3235840","txSize":"922214","isMeta":false},{"id":"54","name":"finder_comcast_nengland.sqlite","title":"Northeast","description":"CT, ME, MA, NH, NY, RI, VT","lastUpdated":"20140513","fileSize":"10811392","txSize":"3081246","isMeta":false},{"id":"55","name":"finder_comcast_south.sqlite","title":"South","description":"AL, FL, GA, LA, MS, NC, SC, TN, TX","lastUpdated":"20140513","fileSize":"5476352","txSize":"1560760","isMeta":false}],"generated":1401553245}}

We can use R to make the same request and also turn the JSON into R objects that we can work with via the `jsonlite` library:

    :::r
    library(RCurl)
    library(jsonlite)
    
    # post the same form/query via RCurl
    
    resp <- postForm("http://datafeed.bsgwireless.com/ajax/finderDataService/discover.php", 
                     api_key="API_KEY_STRING_FROM_BURP_INTERCEPT")
    
    # convert the JSON response to R objects
    
    resp <- fromJSON(as.character(resp))
    
    # take a peek at what we've got
    
    print(resp)
    ## $success
    ## [1] TRUE
    ## 
    ## $results
    ## $results$baseURL
    ## [1] "http://comcast.datafeed.bsgwireless.com/data/comcast"
    ## 
    ## $results$fileList
    ##   id                            name        title
    ## 1 45                 metadata.sqlite     Metadata
    ## 2 51 finder_comcast_matlantic.sqlite Mid-Atlantic
    ## 3 52      finder_comcast_west.sqlite         West
    ## 4 53   finder_comcast_midwest.sqlite      Midwest
    ## 5 54  finder_comcast_nengland.sqlite    Northeast
    ## 6 55     finder_comcast_south.sqlite        South
    ##                                                  description lastUpdated
    ## 1                                                       <NA>    20140513
    ## 2                                 DC, DE, MD, NJ, PA, VA, WV    20140513
    ## 3 AK, AZ, CA, CO, HI, ID, MT, NV, NM, ND, OR, SD, UT, WA, WY    20140513
    ## 4         AR, IL, IN, IA, KS, KY, MI, MN, MO, NE, OH, OK, WI    20140513
    ## 5                                 CT, ME, MA, NH, NY, RI, VT    20140513
    ## 6                         AL, FL, GA, LA, MS, NC, SC, TN, TX    20140513
    ##   fileSize  txSize isMeta
    ## 1    11264    3210   TRUE
    ## 2  9963520 2839603  FALSE
    ## 3  5770240 1644518  FALSE
    ## 4  3235840  922214  FALSE
    ## 5 10811392 3081246  FALSE
    ## 6  5476352 1560760  FALSE
    ## 
    ## $results$generated
    ## [1] 1401553861

We can see that each region (from the app screen capture) has an entry in the `resp$results$fileList` data frame that obviously corresponds to a SQLite database for that region. Furthermore, each one also shows when it was last updated (which you can then use to determine if you need to re-download it). There's also a `metadata.sqlite` file that might be interesting to poke around at as well.

The API also gives us the base URL which matches the request from the Burp Proxy session (when retrieving an individal dataset file). The following is the Burp Proxy request capture from the iOS app:

    :::http
    GET /data/comcast/finder_comcast_nengland.sqlite HTTP/1.1
    Host: comcast.datafeed.bsgwireless.com
    Pragma: no-cache
    Proxy-Connection: keep-alive
    Accept: */*
    User-Agent: XFINITY%20WiFi/232 CFNetwork/672.1.14 Darwin/14.0.0
    Accept-Language: en-us
    Accept-Encoding: gzip
    Connection: keep-alive

The Android version of the app sends somewhat different request headers, including an `Authorization` header that Base64 decodes to `csl:123456` (and isn't used by the API):

    :::http
    GET /data/comcast/finder_comcast_midwest.sqlite HTTP/1.1
    Accept-Encoding: gzip
    Host: comcast.datafeed.bsgwireless.com
    Connection: Keep-Alive
    User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)
    Authorization: Basic Y3NsOjEyMzQ1Ng==

Given that there are no special requirements for downloading the data files (even the `User-Agent` isn't standardized between operating system versions), we can use plain ol' `download.file` from the "built-in" `utils` package to handle retrieval:

    :::r
    # plyr isn't truly necessary, but I like the syntax standardization it provides
    
    library(plyr)
    
    l_ply(resp$results$fileList$name, function(x) {
      download.file(sprintf("http://comcast.datafeed.bsgwireless.com/data/comcast/%s", x),
                    sprintf("data/%s",x))
    })

>NOTE: As you can see in the example, I'm storing all the data files in a `data` subdirectory of the project I started for this exaple.

While the `metadata.sqlite` file *is* interesting, the data really isn't all that useful for this post since the Xfinity app doesn't use most of it (and is very US-centric). I suspect that data is far more interesting in the full BSG hotspot data set (which we aren't using here). Therefore, we'll just focus on taking a look at the hotspot data, specifically the `sites` table:

    :::sql
    CREATE TABLE "sites" (
      "siteUID"               integer PRIMARY KEY NOT NULL DEFAULT null, 
      "siteTypeUID"           integer NOT NULL DEFAULT null,
      "siteCategory"          integer DEFAULT null, 
      "siteName"              varchar NOT NULL DEFAULT null, 
      "address1"              varchar DEFAULT null, 
      "address2"              varchar DEFAULT null, 
      "town"                  varchar,
      "county"                varchar, 
      "postcode"              varchar, 
      "countryUID"            integer DEFAULT null, 
      "latitude"              double NOT NULL, 
      "longitude"             double NOT NULL, 
      "siteDescription"       text DEFAULT null, 
      "siteWebsite"           varchar DEFAULT null, 
      "sitePhone"             varchar DEFAULT null, 
      "operatorUID"           integer NOT NULL DEFAULT null, 
      "ssid"                  varchar(50), 
      "connectionTypeUID"     integer DEFAULT null, 
      "serviceProviderBrand"  varchar(50) DEFAULT null, 
      "additionalSearchTerms" varchar); 

>You can get an overview on how to use the SQLite command line tool in [the SQLite CLI documentation](http://www.sqlite.org/cli.html) if you're unfamiliar with SQL/SQLite.

The app most likely uses individual databases to save device space and bandwith, but it would be helpful if we had all the hotspot data in one data frame. We can do this pretty easily in R since we can work with SQLite databases via the `RSQLite` package and use `ldply` to combine results for us:

    :::r
    library(RSQLite)
    library(sqldf)
    
    # the 'grep' is here since we don't want to process the 'metadata' file
    
    xfin <- ldply(grep("metadata.sqlite", 
                       resp$results$fileList$name, 
                       invert=TRUE, value=TRUE), function(x) {
    
      db <- dbConnect(SQLite(), dbname=sprintf("data/%s", x))
    
      query <- "SELECT siteCategory, siteName, address1, town, county, postcode, latitude, longitude, siteWebsite, sitePhone FROM sites"
    
      results <- dbSendQuery(db, query)
      
      # this makes a data frame from the entirety of the results
    
      aps <- fetch(results, -1)
    
      # the operation can take a little while, so this just shows progress
      # and also whether we retrieved all the results from thery for each call
      # by using message() you can use suppressMessageS() to disable the
      # "debugging" messages
      
      message("Loading [", x, "]... ", ifelse(dbHasCompleted(results), "successful!", "unsuccessful :-("))
    
      dbClearResult(results)
    
      return(aps)
    
    })

>I had intended to use more than just `latitude` & `longitude` with this post, but ended up not using it. I left it in the query since a future post might use it and also as an example for those unfamiliar with using `SQLite`/`RSQLite`.

The function in the `ldply` combines each region's data frame into one. We can get a quick overview of what it looks like:

    :::r
    str(xfin) 
    ## 'data.frame':	261365 obs. of  10 variables:
    ##  $ siteCategory: int  2 2 2 2 2 2 2 2 3 2 ...
    ##  $ siteName    : chr  "CableWiFi" "CableWiFi" "CableWiFi" "CableWiFi" ...
    ##  $ address1    : chr  "7 ELM ST" "603 BROADWAY" "6501 HUDSON AVE" "1607 CORLIES AVE" ...
    ##  $ town        : chr  "Morristown" "Bayonne" "West New York" "Neptune" ...
    ##  $ county      : chr  "New Jersey" "New Jersey" "New Jersey" "New Jersey" ...
    ##  $ postcode    : chr  "07960" "07002" "07093" "07753" ...
    ##  $ latitude    : num  40.8 40.7 40.8 40.2 40.9 ...
    ##  $ longitude   : num  -74.5 -74.1 -74 -74 -74.6 ...
    ##  $ siteWebsite : chr  "" "" "" "" ...
    ##  $ sitePhone   : chr  "" "" "" "" ...

Now that we have the data into the proper format, we'll cover how to visualize it in the second and final part of the series.