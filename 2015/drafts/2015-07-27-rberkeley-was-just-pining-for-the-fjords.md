Title: RBerkeley Was Just Pining For The Fjords
Date: 2015-07-27 11:13
Slug: rberkeley-was-just-pining-for-the-fjords
Tags: blog, r, rstats
Category: blog, r, rstats
Author: Bob Rudis (@hrbrmstr)

If you made it to Chapter 8 of [Data-Driven Security](http://dds.ec/amzn) after ~October 2014 and tried to run the BerkeleyDB R example, you were greeted with:

    :::text
    Warning in install.packages :
      package ‘RBerkely’ is not available (for R version [YOUR_R_VERSION])

That's due to the fact that it was removed from CRAN at the end of September, 2014 because the package author & maintainer did not respond to requests from the CRAN team to update the package to conform to new requirements (specifically the way package vignettes are handled).

Sharon Machlis (@sharon000 on Twitter) let me know about this recently. Since then I've had a few more pings about it (thank you all for reading the book! :-). So, I [resurrected the package](https://github.com/hrbrmstr/RBerkeley). It's not on CRAN yet, but I did submit an update to it, so we'll see how that goes.

I did a bit more than move the vignette. It has a proper `autoconf` setup now and I fixed some of the warnings it was throwing on compilation. I also tweaked the configuration so it should work without whining on `libdb` 4+. 

I highly doubt there were many other packages or projects relying on this package, but it seemed only fair to try to keep it alive while the book is still going strong (either that or I would have had to write a new example for that chapter, which _may_ have been easier now that I've mucked with the package innards).

Post all issues/etc on github as usual - https://github.com/hrbrmstr/RBerkeley

<iframe width="640" height="390" src="https://www.youtube.com/embed/npjOSLCR2hE" frameborder="0" allowfullscreen></iframe>
