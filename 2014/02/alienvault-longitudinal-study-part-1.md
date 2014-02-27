Title: AlienVault Longitudinal Study Part 1
Date: 2014-02-17 16:40
Tags: datavis, dataviz, AlienVault, data analysis, data management
Category: Analysis
Author: Steve Patton (@spttnnh)
Slug: alienvault-longitudinal-study-part-1

Chapter 3 of [Data-Driven Security](http://amzn.to/ddsec) explores one download of the [AlienVault](http://www.alienvault.com/) reputation database. As you can see from the book, the reputation database has many interesting aspects to explore, including country profiles, risk versus reliability, and a variety of threat types. Of course, one download represents a simple snapshot in time. Yet we know threats are continually changing, moving, intensifying and waning. How could we expand our analysis to look at the reputation database over time?

In this series of occasional posts, we will take a time series of the database, and essentially conduct a brief [longitudinal study](http://en.wikipedia.org/wiki/Longitudinal_study) of the reputation database and its changes. One of the first challenges is how to get a picture of change over time, and to manage the resulting dataset. For our purposes, a cron job captured the reputation database hourly for three months (October through December 2013). The resulting files are the primary dataset for our study. It can be overwhelming to manage this number of elements:

 * 250,000 records
 * 8 fields
 * 24 times daily
 * 92 days

produces a truckload of elements: **4.4 billion**, to be somewhat precise.

While all this data needs to be processed for our analysis, there are certain simplifications that can reduce the amount of data needed to draw meaningful conclusions. For example, out of approximately 885,000 unique IP addresses found over the study period, less than 4% of the addresses had any change to their description. Additionally, less than one tenth of one percent of records had a change to the reliability or risk rating of an address. We can use this relative stability of records to responsibly prune the number of records we track. The raw number of records is roughly 250,000 times 24 hours times 92 days, or 552 million rows. But by choosing our smallest unit of analysis to be a day, we can smooth out any gaps in our hourly collection, and reduce our record count to about 20 million.

For all the wonderful features of open source R, there are some tasks it is not well suited for. When dealing with millions of records, a relational database is an ideal tool for managing and aggregating records. Here is a brief overview of the foundational scripts used to make the primary dataset for our study. The bash script running hourly in cron is below:

    YMDHM=`date +%Y%m%d%H%M`
    cd /data/avrep
    # move previous version file
    mv reputation.rev reputation.prev
    # get current version file
    wget http://reputation.alienvault.com/reputation.rev
    UPDATE=`diff reputation.prev reputation.rev | wc -l`
    # if version files do not match, download reputation file
    if [ $UPDATE -gt 0 ]; then
        echo get
        wget -O avrep${YMDHM}.data http://reputation.alienvault.com/reputation.data
        bzip2 avrep${YMDHM}.data
    fi

Here is the table definition script for MariaDB:

    DROP TABLE IF EXISTS avip;
    CREATE TABLE avip (
        iind    INT UNSIGNED NOT NULL AUTO_INCREMENT,
        ip      INT UNSIGNED NOT NULL,
        type    VARCHAR(50),
        cc      VARCHAR(2),
        city    VARCHAR(30),
        latlon  VARCHAR(30),
        PRIMARY KEY (iind),
        UNIQUE INDEX avip_ind (ip, type, cc, city, latlon)
    );
    
    DROP TABLE IF EXISTS avtrack;
    CREATE TABLE avtrack (
        d       DATE NOT NULL,
        iind    INT UNSIGNED NOT NULL,
        risk    TINYINT UNSIGNED,
        rel     TINYINT UNSIGNED,
        minrisk TINYINT UNSIGNED,
        minrel  TINYINT UNSIGNED,
        maxrisk TINYINT UNSIGNED,
        maxrel  TINYINT UNSIGNED,
        PRIMARY KEY (d, iind)
    );

Here is the bash script for loading the files into a database:

    ls avrep*.data.bz2 > avrep.lst
    while read line
    do
        bzcat $line > avrep_tmp.data
        DATESTR=`echo ${line} | cut -c11-18`
        sed -e "s/<DAY>/${DATESTR}/g" avtrack.mysql.template > avtrack.mysql
        mysql avrep -u aaa --password=bbb < avtrack.mysql
    done < avrep.lst

Here is the processing script called for each AlienVault download:

    DROP TABLE IF EXISTS avrep;
    CREATE TABLE avrep (
        ip      VARCHAR(20),
        risk    TINYINT UNSIGNED,
        rel     TINYINT UNSIGNED,
        type    VARCHAR(50),
        cc      VARCHAR(2),
        city    VARCHAR(30),
        latlon  VARCHAR(30),
        x       VARCHAR(10)
    );
    
    LOAD DATA LOCAL INFILE '/data/avrep_tmp.data' INTO TABLE avrep
         FIELDS TERMINATED BY '#';
    SHOW WARNINGS;
    
    INSERT IGNORE INTO avip
    SELECT NULL, INET_ATON(ip), type, cc, city, latlon
      FROM avrep;
    
    SET @day = '<DAY>';
    
    INSERT INTO avtrack
    SELECT @day AS d,
           (SELECT iind FROM avip WHERE INET_ATON(avrep.ip)=avip.ip AND 
                                        avrep.type=avip.type AND avrep.cc=avip.cc AND
                                        avrep.city=avip.city AND avrep.latlon=avip.latlon),
           risk, rel, risk, rel, risk, rel
      FROM avrep
    ON DUPLICATE KEY UPDATE
        avtrack.risk=avrep.risk, avtrack.rel=avrep.rel,
        avtrack.minrisk=IF(avrep.risk<avtrack.minrisk, avrep.risk, avtrack.minrisk),
        avtrack.minrel=IF(avrep.rel<avtrack.minrel, avrep.rel, avtrack.minrel),
        avtrack.maxrisk=IF(avrep.risk>avtrack.maxrisk, avrep.risk, avtrack.maxrisk),
        avtrack.maxrel=IF(avrep.rel>avtrack.maxrel, avrep.rel, avtrack.maxrel);

With these scripts, we can collect AlienVault downloads and load them into two tables, avip and avtrack. In our next installment, we'll start looking at the data we have aggregated. With a dataset covering a time period, in contrast to a single fixed-time sample, we can look at changes over time.

<center><img src="/blog/images/2014/02/USaddr.svg" width="630" style="max-width:100%"/></center>
<center><img src="/blog/images/2014/02/RUaddr.svg" width="630" style="max-width:100%"/></center>
