Title: AlienVault Longitudinal Study Part 2
Date: 2014-02-22 17:00
Tags: datavis, dataviz, AlienVault, data analysis. data management
Category: Analysis
Author: Steve Patton (@spttnnh)
Status: draft
Slug: alienvault-longitudinal-study-part-2

In [Part 1](alienvault-longitudinal-study-part-1) we looked at acquiring raw
data, and wrangling it into a time series dataset. Now we will examine
[AlienVault](http://www.alienvault.com/) types in the reputation database.
Listing 3-22 of [Data-Driven Security](http://amzn.to/ddsec) shows R code that
groups type categories into a larger group of "multiples" when there is a
semicolon in the type. This is a useful simplification when taking a first
look at a complex dataset. In this post, we will look deeper at types, and
the combinations in the dataset. While we will get to pictures later in the
post, it is important to "know your data" prior to cranking up your favorite
'viz' engine.

Our dataset has 80 unique different types:

    MariaDB [avrep]> SELECT DISTINCT type FROM avip;
    +-----------------------------------------------+
    | type                                          |
    +-----------------------------------------------+
    | Malware IP                                    |
    | Scanning Host                                 |
     
    ... 
     
    | Malware Domain;C&C;Malware IP;Spamming        |
    | Malware Domain;Scanning Host;Malicious Host   |
    +-----------------------------------------------+
    80 rows in set (2.80 sec)

However, only 8 of them are "single type", which represent the base types:

    MariaDB [avrep]> SELECT DISTINCT type FROM avip WHERE type NOT LIKE '%;%';
    +----------------------+
    | type                 |
    +----------------------+
    | Malware IP           |
    | Scanning Host        |
    | Malicious Host       |
    | Malware Domain       |
    | Spamming             |
    | C&C                  |
    | APT                  |
    | Malware distribution |
    +----------------------+
    8 rows in set (0.52 sec)

This means that 90% of the distinct type values are compound or "multiple" values.
We probably need to look more deeply at these so we will not miss insights in the
type values. While compound values represent the vast majority of distinct values,
we need to know more about the profile of types across our dataset.

It is important to note that our table 'avip' contains each unique description of
each IP address encountered during our longitudinal study. Some addresses do repeat,
but as we pointed out in Part 1, the vast majority of descriptions are stable. Thus,
we will use records in the avip table as a proxy for addresses, though there are a
few addresses that repeat.  How many entries does the avip table have?

    MariaDB [avrep]> SELECT COUNT(*) FROM avip;
    +----------+
    | COUNT(*) |
    +----------+
    |   918524 |
    +----------+
    1 row in set (0.39 sec)


How many addresses have compound types?

    MariaDB [avrep]> SELECT COUNT(type) FROM avip WHERE type LIKE '%;%';
    +-------------+
    | COUNT(type) |
    +-------------+
    |        5781 |
    +-------------+
    1 row in set (0.28 sec)
 
This represents about six tenths of one percent (0.6%) of addresses, underscoring why it
was reasonable to lump them together in preliminary analysis in the book. But before we
dismiss compound types, let us ensure that we have not overlooked other aspects of their
contribution to the dataset.

How do the reliability and risk ratings of compound types compare to the others?

    MariaDB [avrep]> SELECT AVG(risk), AVG(rel) FROM avtrack, avip WHERE avtrack.iind=avip.iind AND type LIKE '%;%';
    +-----------+----------+
    | AVG(risk) | AVG(rel) |
    +-----------+----------+
    |    2.4526 |   4.3978 |
    +-----------+----------+
    1 row in set (26.84 sec)
    
    MariaDB [avrep]> SELECT AVG(risk), AVG(rel) FROM avtrack, avip WHERE avtrack.iind=avip.iind AND type NOT LIKE '%;%';
    +-----------+----------+
    | AVG(risk) | AVG(rel) |
    +-----------+----------+
    |    2.0663 |   2.3505 |
    +-----------+----------+
    1 row in set (32.55 sec)

That is quite interesting! Addresses with a compound type, while they represent a small
fraction of addresses in the AlienVault Reputation Database, average a risk rating more
than *18% higher* than addresses with a simple type. Not only that, but they average a
reliability rating *87% higher* than addresses with a simple type. This actually makes sense, since addresses demonstrating multiple types of malicious behavior are both a higher risk and higher reliability with regard to that risk.

What about compound types in relation to our time series? We have determined that
addresses with a compound type are a small fraction of all tracked addresses, but do
they occur more frequently in our daily tracking?

    MariaDB [avrep]> SELECT COUNT(type) FROM avtrack, avip WHERE avtrack.iind=avip.iind AND type LIKE '%;%';
    +-------------+
    | COUNT(type) |
    +-------------+
    |      178961 |
    +-------------+
    1 row in set (26.39 sec)
    
    MariaDB [avrep]> SELECT COUNT(type) FROM avtrack, avip WHERE avtrack.iind=avip.iind;
    +-------------+
    | COUNT(type) |
    +-------------+
    |    20343620 |
    +-------------+
    1 row in set (25.56 sec)

Compound types are still a small fraction of the daily tracking, however,
they are a greater proportion of the daily records (0.9%) than they are
of the addresses tracked (0.6%).

We know that characterizing compound types or the "multiple" types as a group is
reasonable, since all together the compound times are a fraction of a percent
of addresses tracked, and daily risk and reliability ratings in our dataset.
Our analysis will be simplified by tracking 9 categories (8 simple types, and the multiples).
Had we done a graph of all types, our output would have been confused by 
almost ten times more data points, 90% of which add up to less than one
percent of our data.

Continuing our exploration of the types, we now
build a small table that will help us look at type by day:

    DROP TABLE IF EXISTS daytype;
    CREATE TABLE daytype (
        d     DATE,
        type  VARCHAR(30),
        count INT
    );
    
    INSERT INTO daytype
    SELECT d, type, COUNT(type) AS count
      FROM avip, avtrack
     WHERE avip.iind=avtrack.iind AND
           type NOT LIKE '%;%'
     GROUP BY d, type;
    
    INSERT INTO daytype
    SELECT d, "Multiple", COUNT(type) AS count
      FROM avip, avtrack
     WHERE avip.iind=avtrack.iind AND
           type LIKE '%;%'
     GROUP BY d;

We can easily see now a breakdown of type for one day:

    MariaDB [avrep]> SELECT * FROM daytype WHERE d='2013-10-01' ORDER BY count DESC;
    +------------+----------------------+--------+
    | d          | type                 | count  |
    +------------+----------------------+--------+
    | 2013-10-01 | Scanning Host        | 201635 |
    | 2013-10-01 | Malware Domain       |   7221 |
    | 2013-10-01 | Malware IP           |   3353 |
    | 2013-10-01 | Malicious Host       |   3131 |
    | 2013-10-01 | Spamming             |   1709 |
    | 2013-10-01 | Multiple             |   1347 |
    | 2013-10-01 | C&C                  |    811 |
    | 2013-10-01 | APT                  |      5 |
    | 2013-10-01 | Malware distribution |      2 |
    +------------+----------------------+--------+
    9 rows in set (0.00 sec)

This shows us how scanning hosts dwarf everything else in the feed. To help see this
more clearly, we will look at the whole time series and view the types by percentage:

    MariaDB [avrep]> SET @total = (SELECT COUNT(*) from avtrack);
    Query OK, 0 rows affected (18.45 sec)
    
    MariaDB [avrep]> SELECT @total;
    +----------+
    | @total   |
    +----------+
    | 20343621 |
    +----------+
    1 row in set (0.00 sec)
    
    MariaDB [avrep]> SELECT type, SUM(count), SUM(count)/@total FROM daytype GROUP BY type ORDER BY SUM(count)/@total DESC;
    +----------------------+------------+-------------------+
    | type                 | SUM(count) | SUM(count)/@total |
    +----------------------+------------+-------------------+
    | Scanning Host        |   18389369 |            0.9039 |
    | Malware Domain       |     594145 |            0.0292 |
    | Malicious Host       |     456027 |            0.0224 |
    | Spamming             |     377958 |            0.0186 |
    | Malware IP           |     270912 |            0.0133 |
    | Multiple             |     178961 |            0.0088 |
    | C&C                  |      75569 |            0.0037 |
    | Malware distribution |        254 |            0.0000 |
    | APT                  |        425 |            0.0000 |
    +----------------------+------------+-------------------+
    9 rows in set (0.00 sec)

Scanning hosts are more than 90% of the addresses. The next type is malware domain
at less than 3%.
We now have a difficult decision to make. If we graph all the categories, basically
everything will be drowned in a sea of scanning hosts. If, however, we ignore the top
category, we should be careful to inform readers what we've done in the interest
of full disclosure and better understanding.

First, we will remove some mystery by showing R code for the two graphs included at
the bottom of [Part 1](alienvault-longitudinal-study-part-1). We won't
repeat the inclusion of the graphics here.

    library(RMySQL)
    library(reshape2)
    library(ggplot2)
    library(scales)
    
    avdb = dbConnect(MySQL(), user='a', password='b', dbname='avrep')
    
    rs <- dbSendQuery(avdb, statement = 
                        "SELECT * FROM avrep_c_rollup;")
    c_rollup <- fetch(rs, n = -1)   # extract all rows
    c_rollup$d = as.Date(c_rollup$d, "%Y-%m-%d")
    
    ggplot(c_rollup[c_rollup$cc=="US",], aes(x=d, y=recs))+geom_point()+theme_bw()+
      xlab("Day")+ylab("IP Addresses")+ggtitle("US Addresses 10/13 - 12/13")
    
    ggplot(c_rollup[c_rollup$cc=="RU",], aes(x=d, y=recs))+geom_point()+theme_bw()+
      xlab("Day")+ylab("IP Addresses")+ggtitle("Russian Addresses 10/13 - 12/13")

Now we load the daytype table into an R data frame to enable visualization of the
type categories we have been exploring.

    rs <- dbSendQuery(avdb, statement = 
                        "SELECT * FROM daytype;")
    daytype <- fetch(rs, n = -1)   # extract all rows
    daytype$d = as.Date(daytype$d, "%Y-%m-%d")
    
    ggplot(daytype, aes(x=d, y=count))+geom_point()+theme_bw()+
      xlab("Day")+ylab("IP Addresses")+ggtitle("Addresses by Type 10/13 - 12/13")
    
This simple plot shows the problem of the overwhelming number of scanning hosts.

<center><img src="type_addr.svg" width="630" style="max-width:100%"/></center>

If we alter the graph by omitting scanned hosts, with this R code:

    ggplot(daytype[daytype$type!="Scanning Host",], aes(x=d, y=count))+geom_point()+theme_bw()+
      xlab("Day")+ylab("IP Addresses")+ggtitle("Addresses by Type (x Scan Hosts) 10/13 - 12/13")

this is what we get:

<center><img src="noscan_addr.svg" width="630" style="max-width:100%"/></center>

You can see more detail since we've dropped the scanning hosts, but a 
simple point plot won't show us the relationships we want to view. Even if we enhance
this plot with a different color for each type, it is still difficult to see the
different types clearly:

    ggplot(daytype[daytype$type!="Scanning Host",], aes(x=d, y=count, color=type))+geom_point()+theme_bw()+
      xlab("Day")+ylab("IP Addresses")+ggtitle("Addresses by Type (x Scan Hosts) 10/13 - 12/13")

this is what we get:

<center><img src="noscan_addr_color.svg" width="630" style="max-width:100%"/></center>

To really separate all the types
we'll need a facet grid blot. We will remove the x scale breaks, since in the
small facet grid format the dates become unreadable.

Here is a facet_grid plot of all threat types:

    ggplot(daytype, aes(d, count)) + geom_point() + theme_bw() +
        scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ type)

<center><img src="alltype.svg" width="630" style="max-width:100%"/></center>

This is a different view of the overwhelming number of scanning hosts. Now if we
repeat the plot but omit scanning hosts, here is the revised facet_grid:

    ggplot(daytype[daytype$type!="Scanning Host",], aes(d, count)) + geom_point() + theme_bw() +
      scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ type)

<center><img src="type.svg" width="630" style="max-width:100%"/></center>

The revised plot lets us see the variability of the numerically smaller types.
Now we more fully understand types over our sample period. In our next installment
we will look more deeply at countries in the Alien Vault feed during our sample
period.
