Title: Making Better DNS TXT Record Lookups With Rcpp
Date: 2014-04-25 12:00:00
Category: R
Status: draft
Tags: rstats, R, Rcpp
Slug: making-better-dns-txt-record-lookups-with-rcpp
Author: Bob Rudis (@hrbrmstr)

*Technically* this is Part 2 of [Firewall-busting ASN-lookups](http://datadrivensecurity.info/blog/posts/2014/Apr/firewall-busting-asn-lookups/). However, I said (in Part 1) that Part 2 would be about making a vectorized version and this is absolutely not about that. Rather than fib, I merely misdirect. Moving on&hellip;

As you can see in Part 1, we have to resort to a `system()` call to do the `TXT` record lookup with `dig`. Frankly, I really dislike that. It's somewhat sloppy, wasteful of resources and we can do better. *Much* better (initially, just a *little* better, tho). R, like most modern interpreted languages, has a C interface. Hadley Wickham goes into far more detail in his epic online (and I'm assuming soon-to-be print) book [Advanced R Programming](http://adv-r.had.co.nz/C-interface.html) than I will be doing in this post and Jonathan Callahan also has some [great in-depth material](http://mazamascience.com/WorkingWithData/?p=1099) you should review. You might want to take a peed at some of [Dirk Eddelbuettel](http://dirk.eddelbuettel.com/code/rcpp.html)'s work, too. This post will (*should?*) get you jumpstarted with the basics of integrating C &amp; R and will dovetail nicely with Part 2 of the proper series, since we'll not only be creating a vectorized version of the `ip2asn()` function but will also be putting it into a proper R package.

### Peeking Under The Covers

Even if you've only dabbled with R, you've already used traditional C-backed functions, and if you've done more extensive computing with R&mdash;say, worked with the `RMySQL` package to connect to a database&mdash;then you've absolutely used the more "modern"/prevalent `Rcpp`-backed functions. For example, the `mysqlCloseConnection` looks like this:

    mysqlCloseConnection
    function (con, ...) 
    {
        if (!isIdCurrent(con)) 
            return(TRUE)
        rs <- dbListResults(con)
        if (length(rs) > 0) {
            if (dbHasCompleted(rs[[1]])) 
                dbClearResult(rs[[1]])
            else stop("connection has pending rows (close open results set first)")
        }
        conId <- as(con, "integer")
        .Call("RS_MySQL_closeConnection", conId, PACKAGE = .MySQLPkgName)
    }
    <environment: namespace:RMySQL>

>PROTIP: you can see the source code for **any** R function by just typing the function name sans-parentheses & parameters at the R console prompt

Towards the bottom of the above code listing, you'll see the `.Call("RS_MySQL_closeConnection"...)` line which is reaching out to the underlying C/C++ code (in `RS-MySQL.c`) that makes up the libary. Here's the definition for that function:

    /* open a connection with the same parameters used for in conHandle */
    Con_Handle *
    RS_MySQL_cloneConnection(Con_Handle *conHandle)
    {
        S_EVALUATOR

        return RS_MySQL_createConnection(
    			RS_DBI_asMgrHandle(MGR_ID(conHandle)),
    			RS_MySQL_cloneConParams(RS_DBI_getConnection(conHandle)->conParams));
    }

Now, we're not working with MySQL in this post, but that's a fairly familiar tool and provides the framework for us to discuss how we'll be using C/C++,  `Rcpp` & `.Call()` to make DNS calls from R in a much more efficient manner.

### Picking A DNS Library

For folks familiar with DNS, you may be thinking that we're going to build an interface to the trusted old standard `BIND` `libresolv` library. While that was an option, we're going to skip with tradition and use the [ldns](http://www.nlnetlabs.nl/projects/ldns/) library from [NLNet Labs](https://twitter.com/NLnetLabs), makers of the `#spiffy` [Unbound](https://twitter.com/NLnetLabs) validating recursive caching resolver (which uses `ldns`).  Their `ldns` implementation has a simple but also robust API which supports IPv4, IPv6, TSIG & DNSEC plus is wicked fast, small and can make *synchronous* calls (which makes it easier to do a basic port). If you're running Mac OS X, you'll need to either use [Homebrew](http://brew.sh/) or [MacPorts](http://www.macports.org/) or compile the library from source. I prefer Homebrew, and used:

    brew install ldns

For Linux users, you'll need both the `ldns` library and the `bsd` library (the latter primarily for `strlcopy`). I gravitate towards Ubuntu for Linux and used the following there:

    sudo apt-get install libldns-dev libbsd-dev

>You'll note the lack of a **Windows** section. Consider this an open offer to anyone on Windows to augment our blog with a Windows version. The [Rtools](http://cran.r-project.org/bin/windows/Rtools/) package can help you get started. Hit us up for details on how to join in the fun!

We are making the broad assumption that you have the necessary development environment setup on either Linux or Mac OS X. It's unlikely you'd be this far along in the post if not :-)

### Starting Small

Rather than build an entire R interace to the whole `ldns` library, we're going to focus this post on:

- Getting a small `Rcpp` example built
- Interfacing with `ldns` to retreive a `TXT` record
- Building an `ip2asn()` R function that uses this new capability

>NOTE: all of the code for this post is in [this gist](https://gist.github.com/hrbrmstr/11286662). You can download them all in one fell 
swoop with:  
>  
>`git clone https://gist.github.com/hrbrmstr/11286662`,  
>  
>and we'll have a proper repository for the full package impementation in later posts.

We'll begin with having you install the `Rcpp` package. Fire up an R console (or use the RStudio R console pane) and do:

    > install.packages("Rcpp")

Next, create a directory (perhaps `ip2asn` for this limited example) and put the following code block into the file `txt.cpp` (or just use the one you cloned above):

    // these three includes do a great deal of heavy lifting
    // by making the necessary structures, functions and macros
    // available to us for the rest of the code

    #include <Rcpp.h>
    #include <Rinternals.h>
    #include <Rdefines.h>

    #ifdef __linux__
    #include <bsd/string.h>
    #endif

    // REF: http://www.nlnetlabs.nl/projects/ldns/ for API info
    #include <ldns/ldns.h>

    // need this for 'wrap()' which *greatly* simplifies dealing
    // with return values
    using namespace Rcpp; 

    // the sole function that does all the work. it accepts an
    // R character vector as input (even though we're only expecting
    // one string to lookuo) and returns a character vector (one row
    // of the DNS TXT records)
    RcppExport SEXP txt(SEXP ipPointer) {
  
      ldns_resolver *res = NULL;
      ldns_rdf *domain = NULL;
      ldns_pkt *p = NULL;
      ldns_rr_list *txt = NULL;
      ldns_status s;
      ldns_rr *answer;
  
      // SEXP passes in an R vector, we need this as a C++ StringVector
      Rcpp::StringVector ip(ipPointer);
  
      // we only passed in one IP address
      domain = ldns_dname_new_frm_str(ip[0]);
      if (!domain) { return(R_NilValue) ; }
  
      s = ldns_resolver_new_frm_file(&res, NULL);
      if (s != LDNS_STATUS_OK) { return(R_NilValue) ; }
  
      p = ldns_resolver_query(res, domain, LDNS_RR_TYPE_TXT, LDNS_RR_CLASS_IN, LDNS_RD);

      ldns_rdf_deep_free(domain); // no longer needed
  
      if (!p) { return(R_NilValue) ; }
                               
      // get the TXT record(s)
      txt = ldns_pkt_rr_list_by_type(p, LDNS_RR_TYPE_TXT, LDNS_SECTION_ANSWER); 
      if (!txt) {
        ldns_pkt_free(p);
        ldns_rr_list_deep_free(txt);
        return(R_NilValue) ;
      }

      // get the TXT record (could be more than one, but not for our IP->ASN)
      answer = ldns_rr_list_rr(txt, 0);
  
      // get the TXT record (could be more than one, but not for our IP->ASN)
      ldns_rdf *rd = ldns_rr_pop_rdf(answer) ;  
  
      // get the character version via safe copy
      char *answer_str = ldns_rdf2str(rd) ;

      // Max TXT record length is 255 chars, but for this example
      // the Team CYMRU ASN resolver TXT records should never exceed
      // 80 characters (from bulk analysis of large sets of IPs)
  
      char ret[80] ;
      strlcpy(ret, answer_str, sizeof(ret)) ;

      Rcpp::StringVector result(1);
      result[0] = ret ;

      // clean up memory
      free(answer_str);    
      ldns_rr_list_deep_free(txt);  
      ldns_pkt_free(p);
      ldns_resolver_deep_free(res);

      // return the TXT answer string which is ridiculously
      // simple even for wonkier structures thanks to `wrap()`
      return(wrap(result));
    
    }

The code is commented pretty well and I won't be covering all of the nuances of the individual `ldns` calls. Please note that the function has **minimal error checking** since it is serving first and foremost as a compact example. The full package version will have all i's dotted and t's crossed and I'll make it a point to show the differences between a "toy" example and production-worthy code when we post the package follow-up.

The code flow pattern will be the same for most of these API library mappings:

- define data types that need to be passed in and returned
- convert them to structures C/C++ can handle
- perform your calculations/operations on that converted data
- clean up after yourself
- return a value R can handle

To compile that code into an object we can use in R, you need to do the following:

    export PKG_LIBS=`Rscript --vanilla -e 'Rcpp:::LdFlags()'`
    export PKG_CPPFLAGS=`Rscript --vanilla -e 'Rcpp:::CxxFlags()'`
    R CMD SHLIB -lldns txt.cpp

The `export` lines setup environment variables that help R/`Rcpp` know where to look for libraries and define the proper compiler flags for your environment. The last line does the hard work of building the proper compilation and linking directives/commands. All three of them belong in a proper `Makefile` (or your build system of choice). Again, we're taking a few shortcuts to make the overall concept a bit more digestible. Complexity coming soon!

If the build was successful, you'll have `txt.o` and `txt.so` files in your directory. Now, on to the good bits!

### Interfacing With R

Having a compiled object is all well and good, but we need to be able to access the `txt()` function from R. It turns out that this part is pretty straightforward. Put the following into a file (perhaps `ip2asn.R`) or use the gist version:

    # yes, this (dyn.load) is all it takes to expose the function we 
    # just created to R. and, yes, it's a bit more complicated than
    # that, but for now bask in the glow of simplicity
    
    dyn.load("txt.so")
    
    # this function should look more than vaguely familiar
    # http://dds.ec/blog/posts/2014/Apr/firewall-busting-asn-lookups/
    
    ip2asn <- function(ip="216.90.108.31") {
    
      orig <- ip
    
      ip <- paste(paste(rev(unlist(strsplit(ip, "\\."))), sep="", collapse="."), 
                  ".origin.asn.cymru.com", sep="", collapse="")
    
      # in essence, we replaced the `system("dig ...")` call with this
      
      result <- .Call("txt", ip)
    
      out <- unlist(strsplit(gsub("\"", "", result), "\ *\\|\ *"))
    
      return(list(ip=orig, asn=out[1], cidr=out[2], cn=out[3], registry=out[4]))
    
    }

To use this new function, make sure your R session is in the working directory of the library (via `setwd()`) and do:

    source("ip2asn.R")
    ip2asn()
    ## $ip
    ## [1] "216.90.108.31"
    ##
    ## $asn
    ## [1] "23028"
    ##
    ## $cidr
    ## [1] "216.90.108.0/24"
    ##
    ## $cn
    ## [1] "US"
    ##
    $registry
    ## [1] "arin"

That uses the function default IP address, but you can use any IP (and, it still only works with a single IP address). Kittens and polar bears will suffer greatly if you pass in anything but a single, 100% valid IP address (see, error checking saves wildlife and pets), but it gets the job done without a `system()` call and sets us up nicely for adding more capability.

### Wrapping Up

We gave you a whirlwind tour of interfacing with R and we'll be re-visitng this topic in later posts. If any parts were a bit confusing or your setup has some errors, drop a note in the comments here or over at the [gist](https://gist.github.com/hrbrmstr/11286662) and we'll do our best to help you out.