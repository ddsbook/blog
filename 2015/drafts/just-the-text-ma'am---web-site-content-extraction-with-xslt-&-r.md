Title: "Just the text ma'am" - Web Site Content Extraction with XSLT & R
Date: 2015-07-09 16:30:42
Category: blog
Tags: blog, r, rstats, xml, xslt, webscraping
Slug: just-the-text-maam
Author: Bob Rudis (@hrbrmstr)

Sometimes you just need the salient text from a web site, often as a first step towards natural language processing (NLP) or classification. There are many ways to achieve this, but [XSLT](http://www.w3.org/TR/xslt) (eXtensible Stylesheet Language) was purpose-built for slicing, dicing and transforming XML (and, hence, HTML) so, it can make more sense and even be speedier use XSLT transformations than to a write a hefty bit of R (or other language) code. 

R has had XSLT processing capabilities in the past. [Sxslt](http://www.omegahat.org/Sxslt/) and [SXalan](http://www.omegahat.org/SXalan/) both provided extensive XSLT/XML processing capabilities, and [Carl Boettiger](http://www.carlboettiger.info/) (@[cboettig](http://twitter.com/cboettig)) has resurrected `Sxslt` [on github](https://github.com/cboettig/Sxslt). However, it has some legacy memory bugs (just like the `XML` package does and said bugs were there long before Carl did his reanimation) and is a bit more heavyweight than at least I needed.

Thus, [xslt](https://github.com/hrbrmstr/xslt) was born. It's based `libxml2` and `libxslt` so it plays nicely with `xml2` and partially wraps [xmlwrapp](http://vslavik.github.io/xmlwrapp/), which is, itself, a C++ wrapper for `libxml2` and `libxslt`.

The github page for the package has installation instructions (you'll need to be somewhat adventureous until the package matures a bit), but I wanted to demonstrate the utility before refining it.

### Using XSLT in Data Analyis Workflows

At [work](verizonenterprise.com/DBIR/2015/), we maintain an ever-increasing list of public breaches known as the Veris Community Database - [VCDB](https://github.com/vz-risk/vcdb). Each breach is a [github issue](https://github.com/vz-risk/vcdb/issues) and we store links to news stories (et al) that document or report the breach in each issue. Coding breaches is pretty labor-intensive work and we have not really received a ton of volunteers (the "C" in "VCDB" stands for "Community"), so we've been looking at ways to at least auto-classify the breaches and get some details from them programmatically. This means that getting just the salient text from these news stories/reports is critical.

With the `xslt` package, we can use [an XSLT tranformation](http://dds.ec/dl/justthetext.xslt) (that XSLT file is a bit big, mostly due to my XSLT being rusty) in an `rvest`/`xml2` pipeline to extract just the text.

Here's a sample of it in action with apologies for the somewhat large text chunks:

    :::R
    library(xslt)
    library(stringr)
    library(xml2)    # this requires a "devtools" install of "xml2" : devtools::install_github("hadley/xml2")
    library(rvest)   # this requires a "devtools" install of "rvest" : devtools::install_github("hadley/rvest")

    just_the_text_maam <- function(doc, sheet) {
      xslt_transform(doc, sheet, is_html = TRUE, fix_ns = TRUE) %>%
        html_text %>%
        str_replace_all("[\\r\\n]", "") %>%
        str_replace_all("[[:blank:]]+", " ") %>%
        str_trim
    }

    sheet <- read_xslt("http://dds.ec/dl/justthetext.xslt")
    
    just_the_text_maam("http://krebsonsecurity.com/2015/07/banks-card-breach-at-trump-hotel-properties/", sheet)

    ## [1] "01Jul 15 Banks: Card Breach at Trump Hotel Properties The Trump Hotel Collection, a string of luxury hotel properties tied to business magnate and , appears to be the latest victim of a credit card breach, according to data shared by several U.S.-based banks.Trump International Hotel and Tower in Chicago.Contacted regarding reports from sources at several banks who traced a pattern of fraudulent debit and credit card charges to accounts that had all been used at Trump hotels, the company declined multiple requests for comment.Update, 4:56 p.m. ET: The Trump Organization just acknowledged the issue with a brief statement from Eric Trump, executive vice president of development and acquisitions: “Like virtually every other company these days, we have been alerted to potential suspicious credit card activity and are in the midst of a thorough investigation to determine whether it involves any of our properties,” the statement reads. “We are committed to safeguarding all guests’ personal information and will continue to do so vigilantly.”Original story:But sources in the financial industry say they have little doubt that Trump properties in several U.S. locations — including Chicago, Honolulu, Las Vegas, Los Angeles, Miami, and New York — are dealing with a card breach that appears to extend back to at least February 2015.If confirmed, the incident would be the latest in a long string of credit card breaches involving hotel brands, restaurants and retail establishments. In March, upscale hotel chain Mandarin Oriental . The following month, hotel franchising firm White Lodging acknowledged that, , card processing systems at several of its locations were breached by hackers.It is likely that the huge number of card breaches at U.S.-based organizations over the past year represents a response by fraudsters to upcoming changes in the United States designed to make credit and debit cards more difficult and expensive to counterfeit. Non-chip cards store cardholder data on a magnetic stripe, which can be trivially copied and re-encoded onto virtually anything else with a magnetic stripe.Magnetic-stripe based cards are the primary target for hackers who have been breaking into retailers like and and installing malicious software on the cash registers: The data is quite valuable to crooks because it can be sold to thieves who encode the information onto new plastic and go shopping at big box stores for stuff they can easily resell for cash (think high-dollar gift cards and electronics).In October 2015, merchants that have not yet installed card readers which accept more secure chip-based cards will for the cost of fraud from counterfeit cards. While most experts believe it may be years after that deadline before most merchants have switched entirely to chip-based card readers (and many U.S. banks are only now thinking about issuing chip-based cards to customers) cyber thieves no doubt well understand they won’t have this enormously profitable cash cow around much longer, and they’re busy milking it for all it’s worth.For more on chip cards and why most U.S. banks are moving to chip-and-signature over the more widely used chip-and-PIN approach, check out . Tags: , , , , , , , , , , Leave a comment Read previous post:Cybercriminals have long relied on compromised Web sites to host malicious software for use in drive-by download attacks, but at..."
    
    just_the_text_maam("http://www.csoonline.com/article/2943968/data-breach/hacking-team-hacked-attackers-claim-400gb-in-dumped-data.html", sheet)

    ## [1] "Firm made famous for helping governments spy on their citizens left exposed CSO | Jul 5, 2015 6:53 PM PT On Sunday, while most of Twitter was watching the Women's World Cup – an amazing game from start to finish – one of the world's most notorious security firms was being hacked.Note: This story is the first of two on the Hacking Team incident. In addition, of visuals from the hack is also available.Specializing in surveillance technology, Hacking Team is now learning how it feels to have their internal matters exposed to the world, and privacy advocates are enjoying a bit of schadenfreude at their expense.Hacking Team is an Italian company that sells intrusion and surveillance tools to governments and law enforcement agencies.The lawful interception tools developed by this company have been linked to several cases of privacy invasion by researchers and the media.Reporters Without Borders has listed the company due largely to Hacking Teams' business practices and their primary surveillance tool Da Vinci.It isn't known who hacked Hacking Team; however, the attackers have published a Torrent file with 400GB of internal documents, source code, and email communications to the public at large.In addition, the attackers have taken to Twitter, defacing the Hacking Team account with a new logo, biography, and published messages with images of the compromised data.Salted Hash will continue to follow developments and update as needed.Update 1: Christopher Soghoian , Hacking Team's customers include South Korea, Kazakhstan, Saudi Arabia, Oman, Lebanon, and Mongolia. Yet, the company maintains that it does not do business with oppressive governments.Update 2: Researchers have started to post items from the released Torrent file. One such item is this invoice for 58,000 Euro to Egypt for Hacking Team's RCS Exploit Portal.Update 3: The video below is a commercial for Hacking Team's top tool Da Vinci.Update 4:An email from a person linked to several domains allegedly tied to the Meles Zenawi Foundation (MZF), Ethiopia's Prime Minister until his death in 2012, was published Sunday evening as part of the cache of files taken from Hacking Team.In the email, Biniam Tewolde offers his thanks to Hacking Team for their help in getting a high value target.Around the time the email was sent, which was eight months after the Prime Minister's death, Tewolde had registered eight different MZF related domains. Given the context of the email and the sudden appearance (and disappearance) of the domains, it's possible all of them were part of a Phishing campaign to access the target. Who the high value target is, remains unknown.An invoice leaked with the Hacking Team cache shows that Ethiopia paid $1,000,000 Birr (ETB) for Hacking Team's Remote Control System, professional services, and communications equipment.Update 5:Hacking Team currently has, based on internal documents leaked by the attackers on Sunday evening, customers in the following locations:Egypt, Ethiopia, Morocco, Nigeria, SudanChile, Colombia, Ecuador, Honduras, Mexico, Panama, United StatesAzerbaijan, Kazakhstan, Malaysia, Mongolia, Singapore, South Korea, ThailandUzbekistan, Vietnam, Australia, Cyprus, Czech Republic, Germany, HungaryItaly, Luxemburg, Poland, Russia, Spain, Switzerland, Bahrain, OmanSaudi Arabia, UAEThe list, and subsequent invoice for 480,000 Euro, disproves Hacking Team's claims that they have never done business with Sudan. , Sudanese security forces have repeatedly and violently suppressed protestors demonstrating against the government, with more than 170 killed in 2013.Update 6: Is Hacking Team awake yet?It's 0100 EST, so sometime soon, , someone in Italy is about to have very a bad day.Late Sunday evening, the Twitter account used by Hacking Team was defaced, and a link to a 400GB Torrent file was posted. The file contains a number of newsworthy items, particularly when it comes to the questionable business relationships between Hacking Team and nations that aren't known for their positive outlook on basic human rights.New developments in the Hacking Team incident include the release of a document outlining the maintenance agreement status of various customers. The document, shared with Salted Hash, lists Russia and Sudan as clients, but instead of an 'active' or 'expired' flag on their account, the two nations are listed as \"Not officially supported\"--The list of clients in the maintenance tracker is similar to the client list provided in the previous update. It's worth mentioning that the Department of Defense is listed as not active, while the Drug Enforcement Agency (DEA) has a renewal in progress. The document notes that the FBI had an active maintenance contract with Hacking Team until June 30, 2015.The 2010 contact between Hacking Team and the National Intelligence Centre (CNI) of Spain was released as part of the cache. According to records, they are listed as an active EU customer with a maintenance contract until 31 January 2016. At the time the contract was signed, the total financial consideration to Hacking Team is listed at 3.4 million Euros.Hacking Team's Christian Pozzi was personally exposed by the incident, as the security engineer's password store from Firefox was published as part of the massive data dump. The passwords in the file are of poor quality, using a mix of easily guessed patterns or passwords that are commonly known to security engineers and criminal hackers. The websites indexed include social media (Live, Facebook, LinkedIn), financial (banks, PayPal), and network related (routers with default credentials).However, Pozzi wasn't the only one to have passwords leaked. Clients have had their passwords exposed as well, as several documents related to contracts and configurations have been circulating online. Unfortunately, the passwords that are circulating are just as bad as the ones observed in the Firefox file.Here are some examples:HTPassw0rdPassw0rd!81Passw0rdPassw0rd!Pas$w0rdRite1.!!Update 7:Among the leaked documents shared by are client details, including a number of configuration and access documents. Based on the data, it appears that Hacking Team told clients in Egypt and Lebanon to use VPN services based in the United States and Germany.--"
    
    just_the_text_maam("http://datadrivensecurity.info/blog/posts/2015/Jul/hiring-data-scientist/", sheet)

    ## [1] "Five Critical Points To Consider When Hiring a Data Scientist By Jay Jacobs (@jayjacobs) Tue 07 July 2015 | tags: , -- () I was recently asked for advice on hiring someone for a data science role. I gave some quick answers but thought the topic deserved more thought because I’ve not only had the experience of hiring for data science but also interviewing (I have recently changed jobs - hello ). So without much of an intro, here are the top 5 pieces of advice I would give to any company trying to hire a data scientist. Put data where their mouth isThis is probably the single best piece of advice I can give and should help you understand more about a candidate then any set of questions. At first, I was surprised when a company gave me a large file to explore and report back on, but in hindsight it’s brilliant. It’s clever because (as I’ve learned), most applicants can talk the talk, but there is a lot of variation in the walks. If at all possible, you should use data from your environment, preferably a sample of data they’d be working on. Don’t expect them to build a complex model or anything, just ask them to come back with either a written report and/or verbal presentation on what the data is.You are looking for three very critical skills. First, you should expect them to identify one or more interesting questions about the data. A big skill of working with data is identifying good questions that can be answered by the data. The good and interesting parts are very critical because many questions are easy, but good questions that are interesting and that deserved to be answered is where skill comes in. Second, look for the train of thought and evidence of building on previous work. You are asking them to do exploratory data analysis, which is all about building up the analyst’s intuition about the data. Be sure you see signs of discovery and learning (about the data, not the analysis). Third, you are looking for their communication skills. Can they present on data-driven topics? Did they leverage visualizations to explain what they’ve learned? And that bridges into the next bit of advice…Don’t be afraid to look dumb.I’m sorry to say that I’ve seen a whole lot of bad research being accepted at face value because people were too afraid say something thinking they would look dumb. If something doesn’t make sense, or doesn’t quite smell right, speak up and ask for clarification on whatever doesn’t sit right. The worst you can do is to just assume they must be right since it seems like they know what they are talking about. I’m serious about this. I’ve seen entire rooms of people nodding their heads to someone saying the equivalent of 2 + 2 = 5. Speak up and ask for clarification. It’s okay if you don’t get something, this is why you want to hire a data scientist anyway. You won’t discover what’s really going on under the surface until you dig a little and unfortunately it can be tricky. What you want to know is that they can talk you like an equal and explain things to a satisfactory level. Remember if they can’t explain the simple things in an interview, how will they explain more complex topics on the job?Don’t try to stump candidatesThe flip side to asking for explanations is a bit of a personal pet peeve. Some interviewers like to pull together technical questions to see if the candidate knows their facts. But here’s a not-so-little secret, data scientists (like everyone else) do much better work with the internet than without. Don’t put them on the spot and ask them to verbally explain the intricacies of the such-n-such algorithm or to list all the assumptions in a specific modeling technique. If these types of questions are critical to the job do a written set of questions and let them use the tools they would use on the job. Sure, you’d like to ensure they know their stuff, but ask technical questions broadly and don’t expect a single specific answer, but just see if they can talk about what things they would need to look out for. Find out what they have done.Ask about projects they have done and I like to follow the . First have then describe a situation, problem or challenge, then have them talk about the tasks or what they needed to achieve in order to resolve the situation (build a classifier, perform regression, etc). Then find out exactly what they contributed and what their actions were. Be sure to hone in on their role, especially if the project is done in academia where teams of research are more common. Finally how did it turn out (the results)? How did they evaluate their work and did the results meet expectations? Having them talk through a project like that should help you get to know them a little more. Don’t hold out for a full-stack data scientistIdeally, a good “full stack” data scientist will have the following skills:Domain expertise - understanding of the industry is helpful at every stage of analyses.Good programming skills - perhaps look for public examples ()Statistics – because data uses it own langaugeMachine learning – because sometimes machines can be better, fast and smarter than you and IData management – the data has to live somewhereVisualizations – data science is pointless unless it can be communicated.But don’t hold out for the full stack of skills. Every candidate will be stronger in one or two of these than the rest, so identify what skills are critical to the role and what may not be as important. Than hire for those strengths. Hope those are helpful, if you have more, leave a comment with your ideas and tips! Please enable JavaScript to view the"

(those are links from three recent breaches posted to VCDB).

Those operations are also pretty fast:

    system.time(just_the_text_maam("http://krebsonsecurity.com/2015/07/banks-card-breach-at-trump-hotel-properties/", sheet))
    ##    user  system elapsed 
    ##   0.089   0.102   0.199

    system.time(just_the_text_maam("http://www.csoonline.com/article/2943968/data-breach/hacking-team-hacked-attackers-claim-400gb-in-dumped-data.html", sheet))
    ##    user  system elapsed 
    ##   0.127   0.179   0.311

    system.time(just_the_text_maam("http://datadrivensecurity.info/blog/posts/2015/Jul/hiring-data-scientist/", sheet))
    ##    user  system elapsed 
    ##   0.034   0.043   0.078

(more benchmarks that exclude the randomness of download speeds will be forthcoming).

Rather than focus on handling tags, attributes and doing some fancy footwork with regular expressions (like all the various [readability](https://github.com/masukomi/ar90-readability) ports do), you get to focus on the data analysis pipeline, with text that's pretty clean (you can see it misses some things) and also pretty much ready for LDA or other text analysis.

The `xmlwrapp` C++ library doesn't have much functionality beyond the transformation function, so there may not be much more added to this package. There is one extra option&mdash;to pass parameters to XSLT transformation scripts&mdash;that will be coded up in short order.

If you find a use for `xslt` (or a bug) drop us a note here or [on github](https://github.com/hrbrmstr/xslt).