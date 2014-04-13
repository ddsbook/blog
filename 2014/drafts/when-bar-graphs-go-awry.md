Title: When Bar Graphs Go Awry
Date: 2014-04-08 22:34:29
Category: blog
Status: draft
Tags: blog
Slug: when-bar-graphs-go-awry
Author: Bob Rudis (@hrbrmstr)

The US Government Accountability Office (GAO) released a report on April 2, 2014 titled "[Federal Agencies Need to Enhance Responses to Data Breaches](http://www.gao.gov/products/GAO-14-487T)". One of the extremely positive effects of [Section 508](http://www.ada.gov/508/index.html) is that agencies must produce these type of reports in an accessible format (usually plain text) and I almost always start with those documents since it's nigh impossible to come across a useless pie chart in those.

But, when I saw this data for the first figure:

    Figure: Information Security Incidents Involving PII, Fiscal Years 2009–2013: 
        
    Fiscal year: 2009; 
    Number of reported incidents: 10,481. 
    
    Fiscal year: 2010; 
    Number of reported incidents: 13,028. 
    
    Fiscal year: 2011; 
    Number of reported incidents: 15,584. 
    
    Fiscal year: 2012; 
    Number of reported incidents: 22,156. 
    
    Fiscal year: 2013; 
    Number of reported incidents: 26,566. 

I thought *"oh, they led with a bar chart&hellip;the doc must be halfway decent"*. So, I grabbed the PDF and flipped to Figure 1:

<center>![fig1](/blog/images/2014/04/fig1.jpg)</center>

Well, I don't know how it's possbible, but the Feds managed to mess up a simple bar chart. The title says *"in thousands"* but the y-axis tick labels are just 2-digits, yet the labels on the bars are in the thousands:

<center>![fig1a](/blog/images/2014/04/fig1a.jpg)</center>

The document has a few more like it (and, of course it has a pie chart).

ZDNet posted [an article](http://www.zdnet.com/government-breaches-at-all-time-high-press-blunder-under-reports-by-millions-7000028113/) where the mis-interpretation of the charts caused them to chide other news reports only to have them retract said chides (take a look at the overstrikes in their post). One of the examples they focused on was the total incident count:

    Figure 1: Information Security Incidents Reported to US-CERT by All 
    Federal Agencies, Fiscal Years 2009-2013: 
    
    Fiscal year: 2009; 
    Number of reported incidents: 29,999. 
    
    Fiscal year: 2010; 
    Number of reported incidents: 41,776. 
    
    Fiscal year: 2011; 
    Number of reported incidents: 42,854. 
    
    Fiscal year: 2012; 
    Number of reported incidents: 48,562. 
    
    Fiscal year: 2013; 
    Number of reported incidents: 61,214. 

The bar chart is equally as awry as the example above, so I won't repeat it. Instead, let's see how we can make some better visualizations from it and show how to do more detailed customizations with `ggplot` along the way.

First, we'll make a proper version of the bar chart:

<center>![fig1-ggplot](/blog/images/2014/04/fig1-ggplot.svg)</center>

