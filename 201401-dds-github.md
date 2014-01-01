Title: The Logs From Writing a Book
Date: 2014-01-01 08:23:00
Category: dataviz
Status: draft
Tags: book, blog
Summary: We have wrapped up the book and we are launching this website, blog and podcast to continue the discussion. 
But before we look forward, we thought it would be a good idea to look back at what we put into writing the book.
Since we used github to manage our material, we have all the data github stores about our commits and the first 
thing we want to look at is the days and times of our checkins.  Take a look...
Slug: 201401-dds-github
Author: Bob Rudis (@hrbrmstr) and Jay Jacobs (@jayjacobs)

<link rel="stylesheet" type="text/css" href="/blog/extra/201401-dds-github1.css">
<link rel="stylesheet" type="text/css" href="/blog/extra/201401-dds-github2.css">

We have wrapped up the book and we are launching this website, blog and podcast to continue the discussion. 
But before we look forward, we thought it would be a good idea to look back at what we put into writing the book.
Since we used github to manage our material, we have all the data github stores about our commits and the first 
thing we want to look at is the days and times of our checkins.  Take a look...

<div id="chart"></div>

Sadly, both of us were remiss in the verbosity of our commit comments, so any type of textual analysis or visualization 
on those would be woefully disappointing. However we thought it would be interesting to also show folks git file commit changes 
per chapter by day across the lifespan of the book's creation. 

Hover over the legend labels to isolate each chapter in the scatterplot and get a summary of commit
activity. 

<center>
<div style="width:630px;padding:0;margin:0">
	<div style="margin:auto; height:20px; font-weight:400; padding-bottom:10px; font-family:'Lato','Helvetica-Neue','Helvetica','Arial','sans-serif'" id="info"></div>
	<div style="width:630px;padding:0;margin:0" id="commits" class="commits"></div>
		<ul id="ch">
		</ul>
		<div style="clear:both"></div>
</div>
</center>	

<script type="text/javascript" src="/blog/extra/201401-dds-github1.js"></script>
<script type="text/javascript" src="/blog/extra/201401-dds-github2.js"></script>


