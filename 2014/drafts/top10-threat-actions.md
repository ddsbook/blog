Title: Top 10 Threat Actions by Industry
Date: 2014-01-09 20:11:14
Category: dataviz
Tags: d3, vcdb
Status: draft
Summary: I work a lot with breach data and one of the things that is slowly emerging from the data is that there is no single approach that would work for every organization.  In order to begin to peel away at this problem (and to work on my D3 skills), I am tapping into the VCDB data set.  For those not familiar with [VCDB](http://veriscommunity.net/doku.php?id=public) (VERIS Community Database) it is a project started at Verizon early in 2013 (and part of my rather fun day job).  VCDB scours headlines for information about security incidents and records them in the [VERIS](http://veriscommunity.net) format.  &hellip;
Slug: top10-threat-actions
Author: Jay Jacobs (@jayjacobs)

I work a lot with breach data and one of the things that is slowly emerging from the data is that there is no single approach that would work for every organization.  In order to begin to peel away at this problem (and to work on my D3 skills), I am tapping into the VCDB data set.  For those not familiar with VCDB ([VERIS Community Database](http://veriscommunity.net/doku.php?id=public), it is a project started at Verizon early in 2013 (and part of my rather fun day job).  VCDB scours headlines for information about security incidents and records them in the [VERIS](http://veriscommunity.net) format.  

<link rel="stylesheet" type="text/css" href="/blog/extra/201401-vcdb-actions.css">

I have a feeling I’ll be doing quite a bit of things with this data because 1) I like how VERIS was set up, and 2) all of the VCDB data is [freely available]( https://github.com/vz-risk/VCDB) for download!  That means anything I do here, you could grab the data in either a JSON format (my favorite) or a CSV format (for those whose hammer is “excel”) and follow along or even try your own stuff with the code.

There are two data points within incidents I want to pull out to question this “one size fits all” approach: the industry of the victim and the threat actions of the attacker.  VERIS uses the North American Industry Classification System (NAICS) for industries, and defines over 100 varieties of threat actions across 7 categories. What I’d like to do is compare the top 10 threat actions in the top 10 industries.  If one security-size fits all, then we would see just some minor random variation) across industries. 

### The Viz
<i>Select an industry on the right and mouse-over the bar for details of the actions.  The digit in the industry is the NAICS code (e.g. [Public (92)]( http://www.census.gov/cgi-bin/sssd/naics/naicsrch?code=92&search=2012%20NAICS%20Search) is Public Administration). </i>

<div id="chart"></div>

What do you see here?  
Theft and privilege abuse are common and public disclosures are light on details, so “unknown” hacking actions are a prominent theme.  The one take away is that we've got quite a bit of variation across industries.  Now, it might be hard to attribute a whole lot of meaning to this type of visualization, but it sure is interesting to click around there for a bit, isn’t it?

### How this was made
This was created with D3, and the data was extracted from VCDB with an R script I posted to a [gist]( https://gist.github.com/jayjacobs/8346745).

<script type="text/javascript" src="/blog/extra/201401-vcdb-actions.js"></script>
