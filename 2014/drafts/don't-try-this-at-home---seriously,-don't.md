Title: Truthier Bars in Excel
Date: 2015-05-14 21:45:16
Category: blog
Status: draft
Tags: blog, excel, datavis
Slug: truthier-bars-in-excel
Author: Bob Rudis (@hrbrmstr)

I saw some chatter about a post on [spam and new gTLDs](https://securelist.com/analysis/quarterly-spam-reports/69932/spam-and-phishing-in-the-first-quarter-of-2015/) on Kasperky's SecureList and initally got excited that there might be actual data to look at since our work-team started looking at this very topic last year but got distracted by the 2015 DBIR work (we're hoping to pick up on it again as things settle down a bit). Needless to say that my elation waned quickly, but the purpose of this post is not to comment on the overall report. After scrolling through the content, I felt compelled to point out something our readers should _never_ _ever_ do. That would be this:

<img src="https://kasperskycontenthub.com/securelist/files/2015/05/Spam-report_Q1-2015_16.jpg" style="max-width:100%"/>

I have no issue with the use of European decimals (which are commas). I **do** have an issue with the y-axis not starting at 0% as it makes it look like there is a vast difference between the values. I'm not casting (much) blame at Kaspersky since **this is what Excel will do by default**. Yes, Excel helps you mislead with data by default (I validated this with the most recent beta of the new Excel for Mac). Since Excel was no doubt the culprit, I used Excel to fix the problem and create a more authentic chart:

<img src="http://dds.ec/blog/images/2015/05/betterbars.png" style="max-width:100%"/>

I also got rid of some chart junk (one could go even more minimal, too).

The visual differences are not nearly as stark as the original chart would indicate and both the variance (`0.001`) and standard deviation (`0.038`) are _really_ small, meaning there's also not much difference _statistically_.

You can grab the [Excel workbook](http://dds.ec/blog/extra/2015-05-bars.xlsx) and have a look at the data and result. Note that I had to add the y-axis, change the range, then delete the y-axis to correct the default (and bad) Excel defaults. Alas, there is no nice script to post since you have to do all the time-consuming mouse-clicks, deletes and box-value-fills on your own to reproduce from scratch.

Remember that your eyes and your mind are smarter than your tools. Don't rely on them to tell the story for you. Don't assume they are smarter than you. Ensure they're helping _you_ tell the messages that you'v found in the data and are also helping you do so truthfully and as clearly as possible.

