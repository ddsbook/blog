Title: statebins - U.S. State Cartogram Heatmaps in R
Date: 2014-08-27 00:01:49
Category: packages
Tags: cartography, maps, mapping, heatmap, cartogram
Slug: statebins-mapping-the-us-without-maps
Author: Bob Rudis (@hrbrmstr)

I became enamored (OK, obsessed) with a recent visualization by the [WaPo team](http://bit.ly/statebins) which @[ryanpitts](https://twitter.com/ryanpitts/) tweeted and dubbed *statebins*:

<blockquote class="twitter-tweet" lang="en"><p>Statebins! RT <a href="https://twitter.com/kevinschaul">@kevinschaul</a>: States with the most jobs lost or threatened because of trade. <a href="http://t.co/r1pJhudpz3">http://t.co/r1pJhudpz3</a> <a href="http://t.co/eMozAgyEAb">pic.twitter.com/eMozAgyEAb</a></p>&mdash; Ryan Pitts (@ryanpitts) <a href="https://twitter.com/ryanpitts/statuses/503613265839017984">August 24, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

In a very real sense they are heatmap-like [cartograms](http://en.m.wikipedia.org/wiki/Cartogram) (read more about cartograms in Monmonier's & de Blij's [How to Lie With Maps](http://www.amazon.com/gp/product/0226534219/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=0226534219&linkCode=as2&tag=rudisdotnet-20&linkId=54N7RQDVFEBV6CSZ)). These *statebins* are more *heat* than *map* and convey quantitative and rough geographic information quickly without forcing someone to admit they couldn't place AR, TN & KY properly if you offered them $5.00USD. Plus, they aren't "boring" old bar charts for those folks who need something different and they take up less space than most traditional choropleths.

As @[alexcpsec](http://twitter.com/alexcpsec) said in his talk at security summer camp:

<blockquote class="twitter-tweet" lang="en"><p>&quot;PLEASE STOP USING GLOBAL MAPS for visualizing IP-based threat data.&quot; - <a href="https://twitter.com/alexcpsec">@alexcpsec</a> <a href="https://twitter.com/hashtag/defcon?src=hash">#defcon</a></p>&mdash; Wendy Nather (@451wendy) <a href="https://twitter.com/451wendy/statuses/497808992039870466">August 8, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

Despite some posts here and even a few mentions in [our book](http://dds.ec/amzn), geographic maps have little value in information security. Bots are attracted to population centers as there are more people with computers (and, hence, more computers) in those places; IP geolocation data is still far from precise (as our "[Potwin Effect](http://books.google.com/books?id=7DqwAgAAQBAJ&pg=PA113&lpg=PA113&dq=potwin+effect&source=bl&ots=CyYrKxlkCa&sig=Kk6bd9Mz2uJdNOVp2wj3Bn4AgSI&hl=en&sa=X&ei=mTj9U8WhBIvnoASOrYKwBQ&ved=0CCIQ6AEwAA#v=onepage&q=potwin%20effect&f=false)" has shown multiple times); and, the current state of attacker origin attribution involves far more shamanism than statistics.

Yet, there can be some infosec use cases for looking at data through the lens of a map, especially since *"Even before you understand them, your brain is drawn to maps."*. To that end, while you could examine the WaPo javascript to create your own statebin visualizations, I put together a small [statebins package](http://github.com/hrbrmstr/statebins/) that lets you create these cartogram heatmaps in R with little-to-no effort. 

Let's look at one potential example: data breaches; specifically, which states have breach notification laws. Now, I can simply tell you that Alabama, New Mexio and South Dakota have no breach notification laws, but this:

<img src="http://datadrivensecurity.info/blog/images/2014/08/state-breach-laws.png" style="max-width:100%; width:630px"/>

took just 4 lines of code to produce:

    :::r
    library(statebins)
    dat <- data.frame(state=state.abb, value=0, stringsAsFactors=FALSE)
    dat[dat$state %in% c("AL", "NM", "SD"),]$value <- 1
    statebins(dat, breaks=2, labels=c("Yes", "No"), brewer_pal="PuOr",
              text_color="black", font_size=3,
              legend_title="State has breach law", legend_position="bottom")


and makes those three states look more like the slackers they are than the sentence above conveyed.

We can move to a less kitschy use case and chart out # of breaches-per-state from the venerable [VCDB](http://github.com/vz-risk/VCDB):

<img src="http://datadrivensecurity.info/blog/images/2014/08/breaches-per-state.png" style="max-width:100%; width:630px"/>

    :::r
    library(data.table)
    library(verisr)
    library(dplyr)
    library(statebins)

    vcdb <- json2veris("VCDB/data/json/")
    
    # toss in some spiffy dplyr action for good measure
    # and to show statebins functions work with dplyr idioms
    
    tbl_dt(vcdb) %>% 
      filter(victim.state %in% state.abb) %>% 
      group_by(victim.state) %>% 
      summarize(count=n()) %>%
      select(state=victim.state, value=count) %>%
      statebins_continuous(legend_position="bottom", legend_title="Breaches per state", 
                           brewer_pal="RdPu", text_color="black", font_size=3)

The VCDB is extensive, but not exhaustive ([signup to help improve the corpus](http://vcdb.org/volunteer.html)!) and U.S. organizations and state attorneys general are better than it would seem about keeping breaches quiet. It's clear there are more public breach reports coming out of California than other states, but *why* is a highly nuanced question, so be careful when making any geographic inferences from it or any public breach database.

There are far more uses for statebins *outside* of information security, and it only takes a few lines of code to give it a whirl, so take it for a spin the next time you have some state-related data to convey. You can submit any issuses, feature- or pull requests to the [github repo](https://github.com/hrbrmstr/statebins) as I'll be making occassional updates to the package (which may make it to CRAN this time, too).


