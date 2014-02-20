Title: Monitoring Credential Dumps Plus Using Twitter As a Data Source
Date: 2014-02-20 09:14:06
Category: analysis
Status: draft
Tags: data analysis, twitter, data visualization, datavis, passwords
Slug: monitoring-credential-dumps-plus-using-twitter-as-a-data-source
Author: Bob Rudis (@hrbrmstr)

The topic of "dump monitoring"&mdash;i.e. looking for lists of stolen/hacked credentials or notices of targted hacking&mdash;came up on the [securitymetrics.org](http://securitymetrics.org) mailing list recently and that seemed like a good opportunity for a quick post on how to use Twitter as a data source and how to do some "meta-monitoring" of the dump monitors. 

You can manually watch feeds like [LeakedIn](https://twitter.com/leakedin) and [Dump Monitor](https://twitter.com/dumpmon) (both of which monitor multiple dump sites) to look for details on dumps from sites or organizations you care about, but since `@dumpmon` actually provides summary information in most of the tweets, it could be useful just to look at the volume of dumps over time. One of the easiest ways to do this is via the ["t" utility](https://github.com/sferik/t) developed by Erik Michaels-Ober. `t` is a Ruby script that provides a powerful command-line interface to Twitter. To use it, you'll need to setup an application slot at the [Twitter dev portal](http://dev.twitter.com/apps/new) and setup your credentials via

    :::bash
    $ t authorize

all of which is documented pretty well at the github repo.

>Twitter and other languages all have libraries that interface directly with Twitter, but I find it's 
>both easier to extract data with `t` and using said extract makes the core  data analysis and/or 
>visualization code much cleaner as a result.

Once you're setup, you can actually use `t` to read, post and search twitter just as you would with any GUI Twitter client. For example, youc can see the lastet posts by the `@dumpmon` bot via:

    :::bash
    $ t timeline dumpmon
    @dumpmon
    http://t.co/zO5QtCH6tf Emails: 24 Keywords: 0.0 #infoleak

    @dumpmon
    http://t.co/It3HoylEWS Emails: 24 Keywords: 0.0 #infoleak

    @dumpmon
    http://t.co/LhT6lJ9odd Emails: 24 Keywords: -0.14 #infoleak

    @dumpmon
    http://t.co/rh526IokhC Emails: 82 Keywords: 0.33 #infoleak
    ...

However, you can also take the output of most of the commands to `t` and save it as a CSV file (plus most of the commands let you specify the number of records to return). In the case of `@dumpmon`, we can retrieve the last 3,000 tweets and save them off as a CSV file via:

    :::bash
    $ t timeline dumpmon -n 3000 -c > dumpmon.csv
    $ head -5 dumpmon.csv
    ID,Posted at,Screen name,Text
    436435189909041152,2014-02-20 09:40:32 +0000,dumpmon,http://t.co/zO5QtCH6tf Emails: 24 Keywords: 0.0 #infoleak
    436434530992275456,2014-02-20 09:37:55 +0000,dumpmon,http://t.co/It3HoylEWS Emails: 24 Keywords: 0.0 #infoleak
    436428752688381953,2014-02-20 09:14:57 +0000,dumpmon,http://t.co/LhT6lJ9odd Emails: 24 Keywords: -0.14 #infoleak
    436422318290501632,2014-02-20 08:49:23 +0000,dumpmon,http://t.co/rh526IokhC Emails: 82 Keywords: 0.33 #infoleak

Since the bot produces well-formatted records, we can use that fact to extract:

- the number of dumps per day
- the total numbers of e-mails dumped
- the total numbers hashes (passwords) dumped

The `@dumpmon` bot provides some additional data, but for the purposes of this post, we'll focus on those three values with the intent of producing the following chart:

<center><a href="http://datadrivensecurity.info/dashboard/img/dumpmon.svg" target=_blank><img src="/dashboard/img/dumpmon.svg" max-width="100%"/></a></center>

The liberally annotated R code is below. We're doing a daily `@dumpmon` [extract](http://datadrivensecurity.info/data/dumpmon.csv) [CSV] that you can use on your own if you don't want to muck with `t` and Ruby and we'll also be generating the [above chart](http://datadrivensecurity.info/dashboard/img/dumpmon.svg) daily as well (which will be on a forthcoming Data Driven Security Daily Dashboard page). Note that we aren't taking into account the "goodness" value that `@dumpmon` calculates and also note that some of the dumps `@dumpmon` finds aren't actual dumps (they just have data that looks dump-ish and fits certain broad keyword parameters). If you want more refined, accurate statistcs and dump results, you can clone the `@dumpmon` [github repo](https://github.com/jordan-wright/dumpmon) and refine the code or curate the data results on your own (and you won't need to mine Twitter for the stats!).

    :::r
    library(stringr)
    library(plyr)
    library(reshape2)
    library(ggplot2)

    # read in last 3K tweets
    dumpmon <- read.csv("dumpmon.csv", stringsAsFactors=FALSE)

    # only leave yyyy-mm-dd so we can aggregate by day
    dumpmon$Posted.at <- gsub(" .*$", "", dumpmon$Posted.at)

    # extract data from tweet using str_extract() to find the patterns we want
    # and then gsub() to just give us the values
    dumpmon$emails <- as.numeric(gsub("Emails: ", "", 
                                       str_extract(dumpmon$Text, "Emails: [0-9]+")))
    dumpmon$keywords <- as.numeric(gsub("Keywords: ", "", 
                                        str_extract(dumpmon$Text, "Keywords: [0-9\\.]+")))
    dumpmon$hashes <- as.numeric(gsub("Hashes: ", "", 
                                      str_extract(dumpmon$Text, "Hashes: [0-9]+")))
    
    # the previous extracts will produce NAs where there were no values,
    # so we need to turn those  NAs to 0 for our calculations
    dumpmon[is.na(dumpmon)] <- 0

    # aggregate records & leaks via the plyr count() function
    emails.agg <- count(dumpmon, c("Posted.at"), "emails")
    hashes.agg <- count(dumpmon, c("Posted.at"), "hashes")

    # where the previous aggregations countd a particular value
    # this one just counts total tweets per day
    dump.count <- count(dumpmon, c("Posted.at"))

    # first convert the date string to an actual Date object
    emails.agg$Posted.at <- as.Date(emails.agg$Posted.at)
    hashes.agg$Posted.at <- as.Date(hashes.agg$Posted.at)
    dump.count$Posted.at <- as.Date(dump.count$Posted.at)

    # create a new data frame that is just a sequence of all the 
    # days so we can fill in missing time series dates (if any)
    # for that we'll need the min & max date from the tweet extract
    min.date <- min(emails.agg$Posted.at, hashes.agg$Posted.at, dump.count$Posted.at)
    max.date <- max(emails.agg$Posted.at, hashes.agg$Posted.at, dump.count$Posted.at)
    all.days <- data.frame(Posted.at=seq(min.date, max.date, "days"))

    # now do the time series fill for each of the previous aggregations
    emails.agg <- merge(emails.agg, all.days, all=TRUE)
    colnames(emails.agg) <- c("Date", "Emails")

    hashes.agg <- merge(hashes.agg, all.days, all=TRUE)
    colnames(hashes.agg) <- c("Date", "Hashes")

    dump.count <- merge(dump.count, all.days, all=TRUE)
    colnames(dump.count) <- c("Date", "DumpCount")

    # and turn NAs to 0 (again)
    emails.agg[is.na(emails.agg)] <- 0
    hashes.agg[is.na(hashes.agg)] <- 0
    dump.count[is.na(dump.count)] <- 0

    # compute time series diff()'s (give us a feel for change between days
    emails.diff <- emails.agg
    emails.diff$Emails <- c(0, diff(emails.diff$Emails))
    colnames(emails.diff) <- c("Date", "EmailsDiff")

    hashes.diff <- hashes.agg
    hashes.diff$Hashes <- c(0, diff(hashes.diff$Hashes))
    colnames(hashes.diff) <- c("Date", "HashesDiff")

    dump.count.diff <- dump.count
    dump.count.diff$DumpCount <- c(0, diff(dump.count.diff$DumpCount))
    colnames(dump.count.diff) <- c("Date", "DumpCountDiff")

    # now buld new data frame for 'melting'
    # we're doing scaling of the diff() deltas to see how 
    # "out of norm" they are. We could just plot the raw values
    # but this scaling might let us see if a particular day was
    # out of the ordinary and worth poking at more
    dumps <- data.frame(Date=emails.agg$Date,
                        Emails=emails.agg$Emails,
                        EmailsDiff=scale(emails.diff$EmailsDiff),
                        Hashes=hashes.agg$Hashes,
                        HashesDiff=scale(hashes.diff$HashesDiff),
                        DumpCount=dump.count$DumpCount,
                        DumpCountDiff=scale(dump.count.diff$DumpCountDiff))

    # 'melting' is just turning the data from wide to long
    # since we want to use the individual columns as facets for our plot
    dumps.melted <- melt(dumps, id.vars=c("Date"))

    # setup a substitution list for prettier facet labels
    facet_names <- list(
      'Emails'="Emails Daily Raw Count",
      'EmailsDiff'="Emails Daily Change (Diff+Scaled)",
      'Hashes'="Hashes Daily Raw Count",
      'HashesDiff'="Hashes Daily Change (Diff+Scaled)",
      'DumpCount'="# Dumps/Day Raw Count",
      'DumpCountDiff'="# Dumps/Day Change (Diff+Scaled)"
    )

    # this will do the actual substitution. it's a good pattern to follow
    # since facet_grid() actually as a 'labeller' parameter.
    facet_labeller <- function(value) {
      return(as.character(facet_names[value]))
    }

    # but, facet_wrap() (which we're using) does not have a 'labeller'
    # parameter, so we just munge the data directly
    dumps.melted$variable <- facet_labeller(dumps.melted$variable)

    # and then produce the final plot. Note that we are using
    # free scales, so each chart stand on it's own value-wise, but we 
    # group the diff/scaled ones together via the ncol=2 parameter
    gg <- ggplot(dumps.melted, aes(x=Date))
    gg <- gg + geom_line(aes(y=value, color=variable), alpha=0.65)
    gg <- gg + geom_point(aes(y=value, color=variable), size=2, alpha=0.5)
    gg <- gg + facet_wrap(~variable, scales="free_y", ncol=2)
    gg <- gg + labs(x="", y="", title=sprintf("@dumpmon Statistics as of %s",format(Sys.time(), "%Y-%m-%d")))
    gg <- gg + scale_color_manual(values=c("#0074d9", "#0074d9", "#2ecc40", "#2ecc40", "#FF851B", "#FF851B"))
    gg <- gg + theme_bw()
    gg <- gg + theme(legend.position="none")
    gg <- gg + theme(plot.title=element_text(face="bold", size=13))
    gg <- gg + theme(strip.background=element_blank())
    gg <- gg + theme(strip.text=element_text(face="bold", size=11))

    # save it out for posterity
    ggsave(filename="dumpmon.svg", plot=gg, width=9, height=7)

