Title: AlienVault Longitudinal Study Part 3
Date: 2014-04-02 10:00
Tags: datavis, dataviz, AlienVault, data analysis. data management
Category: Analysis
Author: Steve Patton (@spttnnh)
Slug: alienvault-longitudinal-study-part-3
Status: draft

In [Part 1](/blog/2014/02/alienvault-longitudinal-study-part-1) we looked at
acquiring raw data, and wrangling it into a time series dataset. In
[Part 2](/blog/2014/03/alienvault-longitudinal-study-part-2) we looked at
types of threats in the time series.  Now we will examine countries in the
[AlienVault](http://www.alienvault.com/) reputation database.

One of the skills a data scientist must develop is the curation of various
datasets that help enhance core datasets used for analysis. Such enhancement
is a key part of creating new knowledge from different sources. We will
practice this skill by incorporating some data from
[OpenGeoCode.org](http://http://opengeocode.org/download.php#cow) known as the
Countries of the World or COW dataset. The useful thing for us is that this
dataset uses the ISO 3166 two letter country codes, *just like the Alien Vault feed*,
such that we can easily link figures in the COW dataset to addresses in the
Alien Vault dataset. It is this common link that opens up untold amounts of
data to us that can now be linked to Alien Vault addresses.

Specifically, the COW dataset uses ISO 3166-1 alpha-2 compliant codes.
The Alien Vault reputation databases also uses ISO 3166-1 alpha-2 codes with a 
few internet specific ones added, such as "A1" for Anonymous Proxy. The COW dataset
also has other country designations, such as the alpha-3 (three letter) codes,
and even the official name in a variety of languages. The COW dataset is
somewhat unwieldy in this regard. It has numerous variants of country names.
While this isn't particularly useful to us right now, a good data scientist
will make note of this, and remember that the COW dataset is a useful tool
for joining different country related feeds from different sources using
different naming, because the COW dataset can link them all together by
a common country row in the set. It matters not whether the new feed being
analyzed uses "US" or "USA" or "United States of America", the COW dataset
will help link incoming data to the proper country. We could find some
awesome threat data on a French website, and the COW dataset would help us
associate that with Alien Vault addresses because it has the nations of
the world listed in French (as well as many other languages).

We will now select the fields from the COW dataset that are useful for our
exploration of the countries in the Alien Vault reputation database. Using
R:

    # Function trims leading/trailing spaces from strings
    trim <- function (x) gsub("^\\s+|\\s+$", "", x)

    # Load the COW dataset from a disk file
    thefile <- "/home/steve/Develop/avrep/cow.txt"
    cowtables <- read.csv(file=thefile, header=TRUE, sep=";", skip=28)
    cow <- cowtables[,c("ISO3166A2", "ISOen_name", "land", "population")]
    colnames(cow) <- c("code", "country", "land", "pop")
    # Trim country names because COW format separates columns with "; "
    cow$country <- sapply(cow$country, trim)

Now we have a tight dataset suitable for our analysis:

    > head(cow)
      code         country    land      pop
    1   AF     Afghanistan  652230 30419928
    2   AX   Aland Islands   13517    28007
    3   AL         Albania   27398  3002859
    4   DZ         Algeria 2381741 35406303
    5   AS  American Samoa     199    68061
    6   AD         Andorra     468    85082

We will now build a summary table in MariaDB similar to the one we did for types
in Part 2. The daycc table can be made as follows:

    DROP TABLE IF EXISTS daycc;
    CREATE TABLE daycc (
        d     DATE,
        cc    VARCHAR(2),
        count INT
    );
    
    INSERT INTO daycc
    SELECT d, cc, COUNT(cc) AS count
      FROM avip, avtrack
     WHERE avip.iind=avtrack.iind
     GROUP BY d, cc;

We can get a feel for the table as follows:

    MariaDB [avrep]> SELECT * FROM daycc LIMIT 10;
    +------------+------+-------+
    | d          | cc   | count |
    +------------+------+-------+
    | 2013-10-01 |      |  5906 |
    | 2013-10-01 | A1   |    11 |
    | 2013-10-01 | A2   |     3 |
    | 2013-10-01 | AE   |   543 |
    | 2013-10-01 | AG   |   256 |
    | 2013-10-01 | AL   |     1 |
    | 2013-10-01 | AM   |    14 |
    | 2013-10-01 | AN   |     3 |
    | 2013-10-01 | AO   |     3 |
    | 2013-10-01 | AR   |   663 |
    +------------+------+-------+
    10 rows in set (0.29 sec)

    MariaDB [avrep]> SELECT * FROM daycc WHERE cc='US';
    +------------+------+-------+
    | d          | cc   | count |
    +------------+------+-------+
    | 2013-10-01 | US   | 46181 |
    | 2013-10-02 | US   | 45903 |
    | 2013-10-03 | US   | 45960 |
    | 2013-10-04 | US   | 46343 |
    | 2013-10-05 | US   | 46482 |
    
    ...
    
    | 2013-12-30 | US   | 43763 |
    | 2013-12-31 | US   | 42472 |
    +------------+------+-------+
    92 rows in set (0.02 sec)

We are now ready to explore more thoroughly the profiles of
countries in the Alien Vault reputation database. We can look at the
top 10 countries represented in the database on the first day
of our sample, and the last. Notice they are similar but not
identical. This is one of the challenges with a time series. Which
are the top represented countries is a time-dependent question.

    MariaDB [avrep]> SELECT * FROM daycc WHERE d='2013-10-01' ORDER BY count DESC LIMIT 10;
    +------------+------+-------+
    | d          | cc   | count |
    +------------+------+-------+
    | 2013-10-01 | CN   | 58526 |
    | 2013-10-01 | US   | 46181 |
    | 2013-10-01 | TW   | 21665 |
    | 2013-10-01 | NL   |  9442 |
    | 2013-10-01 | DE   |  8491 |
    | 2013-10-01 | TR   |  6083 |
    | 2013-10-01 |      |  5906 |
    | 2013-10-01 | FR   |  5665 |
    | 2013-10-01 | RU   |  5101 |
    | 2013-10-01 | BR   |  4645 |
    +------------+------+-------+
    10 rows in set (0.01 sec)
    
    MariaDB [avrep]> SELECT * FROM daycc WHERE d='2013-12-31' ORDER BY count DESC LIMIT 10;
    +------------+------+-------+
    | d          | cc   | count |
    +------------+------+-------+
    | 2013-12-31 | CN   | 55246 |
    | 2013-12-31 | US   | 42472 |
    | 2013-12-31 |      | 10499 |
    | 2013-12-31 | NL   |  7572 |
    | 2013-12-31 | DE   |  7412 |
    | 2013-12-31 | RU   |  7087 |
    | 2013-12-31 | FR   |  5702 |
    | 2013-12-31 | KR   |  5334 |
    | 2013-12-31 | TR   |  5300 |
    | 2013-12-31 | TW   |  5064 |
    +------------+------+-------+
    10 rows in set (0.02 sec)

In Part 2 we discovered the need to filter and manipulate type information. In 
particular, we sometimes ignored scanning hosts because they were so numerous.
We also combined compound types (those with a ";" embedded in the type) into a
new type called "Multiples" so we could better see more detail and manage
types that were statistical outliers. Now we'll be faced with a similar
challenge in analyzing countries.

    MariaDB [avrep]> SELECT COUNT(cc) FROM daycc GROUP BY d;
    +-----------+
    | COUNT(cc) |
    +-----------+
    |       160 |
    |       159 |
    |       164 |
    
    ...
    
    |       163 |
    |       162 |
    |       163 |
    |       163 |
    +-----------+
    92 rows in set (0.03 sec)

We will likely find it overwhelming to look at 160 countries of data
in our visualizations. This is especially true with about half the
countries having 10 or less addresses.

    MariaDB [avrep]> SELECT COUNT(cc) FROM daycc WHERE count < 10 GROUP BY d;
    +-----------+
    | COUNT(cc) |
    +-----------+
    |        79 |
    |        75 |
    |        73 |
    
    ...
    
    |        72 |
    |        72 |
    |        73 |
    |        73 |
    +-----------+
    92 rows in set (0.01 sec)

We need to cut this down to size in a reasonable manner. What do
various countries represent as to the percentage of entries for
a representative day in our series? Let us use the first day as
a proxy for the rest. We know it will vary, but this is not likely
to be too far off from a typical day. To do this, we will assign
a variable to the total count for the day:

    MariaDB [avrep]> SET @DAYTOT=(SELECT SUM(count) from daycc where d='2013-10-01');
    Query OK, 0 rows affected (0.02 sec)
    
    MariaDB [avrep]> SELECT @DAYTOT;
    +---------+
    | @DAYTOT |
    +---------+
    |  219214 |
    +---------+
    1 row in set (0.00 sec)

Then we will determine the percentage by country:

    MariaDB [avrep]> SELECT cc, count, count/@DAYTOT AS pct FROM daycc WHERE d='2013-10-01' ORDER BY pct DESC;
    +------+-------+--------+
    | cc   | count | pct    |
    +------+-------+--------+
    | CN   | 58526 | 0.2670 |
    | US   | 46181 | 0.2107 |
    | TW   | 21665 | 0.0988 | <-- 57.65% (3 countries)
    | NL   |  9442 | 0.0431 |
    | DE   |  8491 | 0.0387 |
    | TR   |  6083 | 0.0277 |
    |      |  5906 | 0.0269 | <-- 71.29% (7 countries)
    | FR   |  5665 | 0.0258 |
    | RU   |  5101 | 0.0233 |
    | BR   |  4645 | 0.0212 |
    | GB   |  3932 | 0.0179 | <-- 80.11% (11 countries)
    | KR   |  3235 | 0.0148 |
    | RO   |  3233 | 0.0147 |
    | UA   |  2433 | 0.0111 |
    | IN   |  2314 | 0.0106 |
    | ES   |  2250 | 0.0103 |
    | IT   |  2047 | 0.0093 |
    | JP   |  1949 | 0.0089 |
    | VN   |  1734 | 0.0079 |
    | CA   |  1742 | 0.0079 |
    | CZ   |  1647 | 0.0075 | <-- 90.41% (21 countries)
    | PL   |  1531 | 0.0070 |
    | HK   |  1523 | 0.0069 |
    | TH   |  1277 | 0.0058 |
    | BG   |  1097 | 0.0050 | <-- 92.88% (25 countries)
    | IS   |  1031 | 0.0047 |
    
    ...
    
    | LA   |     3 | 0.0000 |
    | LB   |     4 | 0.0000 |
    | LC   |     2 | 0.0000 |
    | LK   |     3 | 0.0000 |
    | NI   |     3 | 0.0000 |
    +------+-------+--------+
    160 rows in set (0.01 sec)

This shows us that once we pass the top 25 countries or so, we are below one
half of one percent per country, and we have also covered almost 93% of the
addresses in the reputation database. With 25 data points, we can still have
a readable graph uncrowded by excessive data points.

NOTE: Any exclusion of data, such as this approach of ignoring approximately
135 of 160 countries, decidedly affects the resulting analysis. The data
scientist must be able to defend the reasons for exclusion, and have a
plausible explanation for why the selected data deserves the treatment
received. Further our selection of 25 countries based on the examination of
one day is another factor in the resulting analysis. In this case, we have
reason to believe that covering countries representing more than 90% of
the addresses, and down to individual countries representing well under
one percent of the addresses, is a reasonable approximation of the data set
and will permit better visualizations that readers can readily understand.

To manage this country selection, we'll create a table to hold our "key
countries" and speed their selection:

    CREATE TABLE cctab (
        cc  VARCHAR(2)
    );

Now we will insert the top 25 countries by address count as of 10/01/2013:
    
    MariaDB [avrep]> INSERT INTO cctab 
                     SELECT cc FROM daycc WHERE d='2013-10-01'
                         ORDER BY count/@DAYTOT DESC LIMIT 25;
    Query OK, 25 rows affected (0.02 sec)
    Records: 25  Duplicates: 0  Warnings: 0

And check our handiwork:
    
    MariaDB [avrep]> SELECT * FROM cctab;
    +------+
    | cc   |
    +------+
    | CN   |
    | US   |
    | TW   |
    | NL   |
    | DE   |
    | TR   |
    |      |
    | FR   |
    | RU   |
    | BR   |
    | GB   |
    | KR   |
    | RO   |
    | UA   |
    | IN   |
    | ES   |
    | IT   |
    | JP   |
    | VN   |
    | CA   |
    | CZ   |
    | PL   |
    | HK   |
    | TH   |
    | BG   |
    +------+
    25 rows in set (0.00 sec)

Now we will see how much of the original daycc table we have cut out:

    MariaDB [avrep]> SELECT COUNT(*) FROM daycc;
    +----------+
    | COUNT(*) |
    +----------+
    |    14904 |
    +----------+
    1 row in set (0.01 sec)
    
    MariaDB [avrep]> SELECT COUNT(*) FROM daycc WHERE cc IN (SELECT * FROM cctab);
    +----------+
    | COUNT(*) |
    +----------+
    |     2300 |
    +----------+
    1 row in set (0.05 sec)

That is about an 85% reduction.  Good work for a few lines of SQL! We are finally
ready to transition to R and begin visualizations of the country relationships in
the Alien Vault reputation database.

    library(RMySQL)
    
    avdb = dbConnect(MySQL(), user='x', password='y', dbname='avrep')
    
    rs <- dbSendQuery(avdb, statement = 
        "SELECT * FROM daycc WHERE cc IN (SELECT * FROM cctab);")
    daycc <- fetch(rs, n = -1)   # extract all rows
    daycc$d = as.Date(daycc$d, "%Y-%m-%d")

We now have a data frame in R called daycc with the top 25 countries (from the
first day of our series) and their counts for each day of our time series.

<center><img src="/blog/images/2014/03/cc.svg" width="630" style="max-width:100%"/></center>

We can see again that familiar problem of too much data in one graph. We will use the facet
technique to "spread out" the countries to see them better. Here is the R:

    ggplot(daycc, aes(d, count)) + geom_point() + theme_bw() +
      scale_x_date(breaks=NULL) + xlab("Day") + ylab("Count") + facet_grid(. ~ cc)

And what we see:

<center><img src="/blog/images/2014/03/allcc.svg" width="630" style="max-width:100%"/></center>

We can see clearly that China and the US dominate the address space. In previous
work with address types, you may recall we dealt with this by eliminating a
category (scanning hosts) to better view the others. Now we will try a different
approach, a logarithmic Y scale:

    ggplot(daycc, aes(d, count)) + geom_point() + theme_bw() +
      scale_y_log10() + scale_x_date(breaks=NULL) +
      xlab("Day") + ylab("Count") + facet_grid(. ~ cc)

And the graph:

<center><img src="/blog/images/2014/03/allcc2.svg" width="630" style="max-width:100%"/></center>

The logarithmic scale lets us keep the high address count countries while still
seeing the low address count countries with a reasonable amount of detail.

Now that we have seen an overview of the country counts, and have made
adjustments for better viewing, we will use the COW dataset to further
analyze country profiles in the Alien Vault reputation database. By enhancing
the daycc data frame with some of the COW data, we can ask more interesting
questions. Using R, we will add three columns to the daycc data frame: land
area, population, and population divided by land area (population density).
This will allow us to examine the countries to see if there is a correlation
against these three values. The R to enhance the data frame follows:

    # Merge the daycc and cow data frames
    daycow <- merge(daycc, cow, by.x = "cc", by.y = "code")
    # NOTE: 92 rows were dropped. These are the rows of the "blank" country.
    # This is acceptable, since no population or land area could be known
    # for the "blank" country.
    #
    # Add population density column
    daycow$popdens <- daycow$pop / daycow$land;

Now we can examine countries in the context of more country specific information.

    gplot(daycow, aes(d, count/pop)) + geom_point() + theme_bw() +
      scale_y_log10() + scale_x_date(breaks=NULL) +
      xlab("Day") + ylab("Count/Population") + facet_grid(. ~ cc)

This gives us the following facets:

<center><img src="/blog/images/2014/03/cowpop.svg" width="630" style="max-width:100%"/></center>

We can now see that the prevalence of Indian (IN) sites in the Alien Vault reputation
database is much lower than that of Taiwan (TW).

Now we will repeat using population density instead of population:

    ggplot(daycow, aes(d, count/popdens)) + geom_point() + theme_bw() +
      scale_y_log10() + scale_x_date(breaks=NULL) +
      xlab("Day") + ylab("Count/Pop Density") + facet_grid(. ~ cc)

And the facets:

<center><img src="/blog/images/2014/03/cowpopdens.svg" width="630" style="max-width:100%"/></center>

In our last installment, we looked at types. In this installment, we examined
countries. Next time, we'll look at countries and types in combination.
