Title: Rcpp & DNS - From Small Example To A Full "resolv" Package  
Date: 2014-04-27 12:22:55  
Category: tools  
Status: draft  
Tags: asn, ip, r, rstats  
Slug: rcpp-dns-from-small-example-to-package  
Author: Bob Rudis (@hrbrmstr)  

In [Making Better DNS TXT Record Lookups With Rcpp](http://datadrivensecurity.info/blog/posts/2014/Apr/making-better-dns-txt-record-lookups-with-rcpp/), we setup a small example of how to get started with `Rcpp` by creating a wrapper around the [ldns]() library to perform DNS TXT record lookups. We're going to extend that example (as promised) by making a `resolv` package for R that will fill a gap (there is no DNS package for R) and hopefully serve as a catalyst for others to build upon. There is a rich legacy (in infosec) of these type of library wrappers/interfaces in Python, Ruby, Perl and other languages. Hopefully through these posts you'll be encouraged to contribute ports of your favorite libraries to the R community.

### Getting Organized

The `txt()` function we created in the previous post works, but it's difficult to use and manage in production. You've got to keep libraries and R source files manually organized and accessible in the right fashion or your code won't work. And, foremost, it was one small, hastily crafted function. We promised *much* better and we aim to deliver. The first thing we need to do is create an R [package](http://www.statmethods.net/interface/packages.html). These are similar to Python pacakges, or Perl modules in that they group functions and data together and can be installed easily. You can make them by hand, but [RStudio](http://www.rstudio.com/) makes the whole act of creating a package – even an `Rcpp`-based package - really simple. Just go to `File->New Project->New Directory->R Package` and, in this case, choose "Package w/Rcpp". Give it a name and a location and definitely go the "git repository" route since it will make it easier to manage code changes/rollbacks and also help you get it up on Github, which is a good first step for publishing your work to the broader community.

<center><img src="http://datadrivensecurity.info/blog/images/2014/04/rstudio.png" alt="rstudio"/></center>




    