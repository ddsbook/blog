Title: AlienVault Longitudinal Study Part 4
Date: 2014-06-08 18:00
Tags: datavis, dataviz, AlienVault, data analysis. data management, R
Category: Analysis
Author: Steve Patton (@spttnnh)
Slug: alienvault-longitudinal-study-part-4
status: draft

In [Part 1](/blog/2014/02/alienvault-longitudinal-study-part-1) we looked at
acquiring raw data, and wrangling it into a time series dataset. In
[Part 2](/blog/2014/03/alienvault-longitudinal-study-part-2) we looked at
types of threats in the time series. In [Part 3](/blog/2014/04/alienvault-longitudinal-study-part-3)
we looked at countries. Now we will examine countries and types in
combination in the [AlienVault](http://www.alienvault.com/) reputation database.

Just as we shaped our dataset for better understanding in previous posts, we will
use the top 25 countries in the cctab table, and ignore address types with a compound
description, i.e. with a semicolon in the type field. Here is the SQL to make our
core dataset for this post:

    -- Create table with countries and type summaries
    DROP TABLE IF EXISTS avcctyp;
    CREATE TABLE avcctyp (
        d         DATE,
        cc        CHAR(2),
        type      CHAR(50),
        avgrisk   DECIMAL(4,2),
        avgrel    DECIMAL(4,2),
        minrisk   INTEGER UNSIGNED,
        minrel    INTEGER UNSIGNED,
        maxrisk   INTEGER UNSIGNED,
        maxrel    INTEGER UNSIGNED,
        count     INTEGER UNSIGNED
    );
   
    -- Insert countries, types, and average, min, max scores 
    INSERT INTO avcctyp
    SELECT d, cc, type,
           AVG(risk) AS avgrisk, AVG(rel) AS avgrel,
           MIN(risk) AS minrisk, MIN(rel) AS minrel,
           MAX(risk) AS maxrisk, MAX(rel) AS maxrel,
           COUNT(*) AS count
      FROM avtrack, avip
     WHERE avtrack.iind=avip.iind
    GROUP BY d, cc, type;
   
    -- Delete compound types (with semicolon) and non-top-25 countries 
    DELETE FROM avcctyp WHERE type LIKE '%;%';
    DELETE FROM avcctyp WHERE cc NOT IN (SELECT * FROM cctab);

Let us now load a data frame in R with the country and type data:

    library(RMySQL)
    
    avdb = dbConnect(MySQL(), user='xxxxxx', password='zzzzzzzz', dbname='avrep')
    rs <- dbSendQuery(avdb, statement = "SELECT * FROM avcctyp;")
    avcctyp <- fetch(rs, n = -1)   # extract all rows
    avcctyp$d = as.Date(avcctyp$d, "%Y-%m-%d")

We now have a data frame in R called avcctyp with the top 25 countries (from the
first day of our series) and their types, averages and counts for each day of our time series.

Looking at one country, and one day, this SQL gives us a feel for what we can explore:

    MariaDB [avrep]> SELECT * FROM avcctyp WHERE d='2013-10-01' AND cc='US';
    +------------+------+----------------------+---------+--------+---------+--------+---------+--------+-------+
    | d          | cc   | type                 | avgrisk | avgrel | minrisk | minrel | maxrisk | maxrel | count |
    +------------+------+----------------------+---------+--------+---------+--------+---------+--------+-------+
    | 2013-10-01 | US   | APT                  |    4.00 |   2.00 |       4 |      2 |       4 |      2 |     1 |
    | 2013-10-01 | US   | C&C                  |    5.83 |   4.47 |       2 |      4 |      10 |      6 |   239 |
    | 2013-10-01 | US   | Malicious Host       |    3.99 |   3.01 |       1 |      1 |       9 |      6 |   616 |
    | 2013-10-01 | US   | Malware distribution |    4.00 |   3.00 |       4 |      3 |       4 |      3 |     1 |
    | 2013-10-01 | US   | Malware Domain       |    5.81 |   2.05 |       1 |      1 |      10 |      4 |  2061 |
    | 2013-10-01 | US   | Malware IP           |    5.11 |   3.02 |       1 |      1 |      10 |      5 |  1483 |
    | 2013-10-01 | US   | Scanning Host        |    2.07 |   2.00 |       1 |      1 |       6 |      4 | 40228 |
    | 2013-10-01 | US   | Spamming             |    6.11 |   2.39 |       1 |      2 |      10 |      5 |  1161 |
    +------------+------+----------------------+---------+--------+---------+--------+---------+--------+-------+
    8 rows in set (0.02 sec)

Here are scanning hosts by country:

    ggplot(avcctyp[avcctyp$type=="Scanning Host",], aes(d, count)) + geom_point() + theme_bw() +
      scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ cc)

And what we see:

<center><img src="/blog/images/2014/06/scancc.svg" width="630" style="max-width:100%"/></center>

Here are malware domains by country:

    ggplot(avcctyp[avcctyp$type=="Malware Domain",], aes(d, count)) + geom_point() + theme_bw() +
      scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ cc)

And what we see:

<center><img src="/blog/images/2014/06/maldcc.svg" width="630" style="max-width:100%"/></center>

You can see that each type of address could be investigated this way to determine country based
patterns in the various address types. We can also see the various types for a particular country:

    ggplot(avcctyp[avcctyp$cc=="US",], aes(d, count)) + geom_point() + theme_bw() +
      scale_y_log10() + scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ type)

And what we see:

<center><img src="/blog/images/2014/06/cctypes.svg" width="630" style="max-width:100%"/></center>

This graphic shows us the various types of addresses as facets for United States entries.

There are many other relationships that could be explored in the Alien Vault threat feed. For
example, our dataframe has average, minimum and maximum risk and reliability ratings. Countries
and types could be more fully explored based on ratings,
but these will have to be left as exercises for the reader. This four part series gave
you a sense of how to start with a raw data feed and analyze it from a variety of
perspectives. We hope you'll try the code we've published here, and take it farther with
your own exploration. 
