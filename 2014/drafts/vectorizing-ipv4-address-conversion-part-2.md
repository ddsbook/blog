Title: Vectorizing IPv4 Address Conversions - Part 2
Date: 2014-05-16 20:18:58
Category: tools
Status: draft
Tags: rstats, r, rcpp
Slug: vectorizing-ipv4-address-conversions-part-2
Author: Bob Rudis (@hrbrmstr)

The [previous
post](http://datadrivensecurity.info/blog/posts/2014/May/vectorizing-ipv4-address-conversions-part-1/)
looked at using the `Vectorize()` function to, well, *vectorize*, our
[Rcpp IPv4
functions](http://datadrivensecurity.info/blog/posts/2014/May/speeding-up-ipv4-address-conversion-in-r/).
While this is a completely acceptable practice, we can perform the
vectorization 100% in `Rcpp`/C++. We've included both the original
`Rcpp` IPv4 functions and the new `Rcpp`-vectorized functions together
to show the minimal differences between them:

    #include <Rcpp.h> 
    #include <boost/asio/ip/address_v4.hpp>
    
    using namespace Rcpp; 
    using namespace boost::asio::ip;
    
    // Rcpp/C++ vectorized routines
    
    // [[Rcpp::export]]
    NumericVector rcpp_rinet_pton (CharacterVector ip) { 
    
      int ipCt = ip.size(); // how many elements in vector
    
      NumericVector ipInt(ipCt); // allocate new numeric vector
    
      // CONVERT ALL THE THINGS!
      for (int i=0; i<ipCt; i++) {
        ipInt[i] = address_v4::from_string(ip[i]).to_ulong();
      }
    
      return(ipInt);
    }
    
    // [[Rcpp::export]]
    CharacterVector rcpp_rinet_ntop (NumericVector ip) {
      
      int ipCt = ip.size();
    
      CharacterVector ipStr(ipCt); // allocate new character vector
      // CONVERT ALL THE THINGS!
      for (int i=0; i<ipCt; i++) {
        ipStr[i] = address_v4(ip[i]).to_string();
      }
      
      return(ipStr);
      
    }
    
    // orignial single-element vector routines we'll vectorize with Vectorize()
    
    // [[Rcpp::export]]
    unsigned long rinet_pton (CharacterVector ip) { 
      return(boost::asio::ip::address_v4::from_string(ip[0]).to_ulong());
    }
    
    // [[Rcpp::export]]
    CharacterVector rinet_ntop (unsigned long addr) {
      return(boost::asio::ip::address_v4(addr).to_string());
    }

We've merely wrapped a `for` loop around the original code and built the
result vectors in `Rcpp`, relying on the object-oriented nature of C++
for proper value conversion+assignment. The pure-R+`Vectorize()`'d code
(from the examples in the [book](http://dds.ec/amzn)) is below, since
we're going to pit all three in a head-to-head performance competition.

    # Vectorize() the single-element vector routines
    v_rinet_pton <- Vectorize(rinet_pton, USE.NAMES=FALSE)
    v_rinet_ntop <- Vectorize(rinet_ntop, USE.NAMES=FALSE)
    
    # pure R version with Vectorize()
    ip2long <- Vectorize(function(ip) {
      ips <- unlist(strsplit(ip, '.', fixed=TRUE))
      octet <- function(x,y) bitOr(bitShiftL(x, 8), y)
      Reduce(octet, as.integer(ips))
    }, USE.NAMES=FALSE)
    
    long2ip <- Vectorize(function(longip) {
      octet <- function(nbits) bitAnd(bitShiftR(longip, nbits), 0xFF)
      paste(Map(octet, c(24,16,8,0)), sep="", collapse=".")
    }, USE.NAMES=FALSE)

Now, we'll read in a file of ~8,000 IPv4 addresses, make them into
integers and then use the `microbenchmark` package to profile the
to/from conversion of all three versions of the routines.

    # read in ~8K IP address strings & make ints for our benchmark
    ips <- read.table("data/ips.dat", header=FALSE, stringsAsFactors=FALSE)
    ints <- rcpp_rinet_pton(ips$V1)
    
    # run a benchmark 100 times per routine, giving plenty of "ramp up" time
    mb <- microbenchmark(rcpp_ints <- rcpp_rinet_pton(ips$V1), 
                         rcpp_chars <- rcpp_rinet_ntop(ints),
                         v_ints <- v_rinet_pton(ips$V1),
                         v_chars <- v_rinet_ntop(ints), 
                         r_ints <- ip2long(ips$V1),
                         r_chars <- long2ip(ints),
                         control=list(warmup=20),
                         times=100, unit="s")

Then, we'll take a look at the results (all times are in seconds):

<center><style>td { font-family:monospace; font-size:0.8em; padding:5px} table { margin-bottom:12px;}</style>
<TABLE border=1>
<TR> <TH> 
Version
</TH> <TH> 
min
</TH> <TH> 
lq
</TH> <TH> 
median
</TH> <TH> 
uq
</TH> <TH> 
max
</TH>  </TR>
  <TR> <TD> 
Rcpp-toInt
</TD> <TD align="right"> 
0.0007216090
</TD> <TD align="right"> 
0.0007610835
</TD> <TD align="right"> 
0.0007967235
</TD> <TD align="right"> 
0.0008572075
</TD> <TD align="right"> 
0.0026142800
</TD> </TR>
  <TR> <TD> 
Rcpp-toChar
</TD> <TD align="right"> 
0.0037574850
</TD> <TD align="right"> 
0.0038886490
</TD> <TD align="right"> 
0.0039565840
</TD> <TD align="right"> 
0.0040140285
</TD> <TD align="right"> 
0.0046188840
</TD> </TR>
  <TR> <TD> 
Rcpp+V()-toInt
</TD> <TD align="right"> 
0.0217142230
</TD> <TD align="right"> 
0.0266931380
</TD> <TD align="right"> 
0.0290988580
</TD> <TD align="right"> 
0.0316722610
</TD> <TD align="right"> 
0.0775550730
</TD> </TR>
  <TR> <TD> 
Rcpp+V()-toChar
</TD> <TD align="right"> 
0.0253528670
</TD> <TD align="right"> 
0.0290143845
</TD> <TD align="right"> 
0.0322646160
</TD> <TD align="right"> 
0.0346684450
</TD> <TD align="right"> 
0.0814177860
</TD> </TR>
  <TR> <TD> 
Pure R-toInt
</TD> <TD align="right"> 
0.1480684080
</TD> <TD align="right"> 
0.1588533500
</TD> <TD align="right"> 
0.1654142360
</TD> <TD align="right"> 
0.1701886530
</TD> <TD align="right"> 
0.1992565150
</TD> </TR>
  <TR> <TD> 
Pure R-toChar
</TD> <TD align="right"> 
0.2726176440
</TD> <TD align="right"> 
0.2863672665
</TD> <TD align="right"> 
0.2917557870
</TD> <TD align="right"> 
0.2960467515
</TD> <TD align="right"> 
0.3371749450
</TD> </TR>
   </TABLE>
</center>

If we just look at the median values, we can see that the conversion
*to* integer takes:

<center>
<TABLE border=1>
<TR> <TH> 
Version
</TH> <TH> 
median
</TH>  </TR>
  <TR> <TD> 
Rcpp-toInt
</TD> <TD align="right"> 
0.0007967235
</TD> </TR>
  <TR> <TD> 
Rcpp+V()-toInt
</TD> <TD align="right"> 
0.0290988580
</TD> </TR>
  <TR> <TD> 
Pure R-toInt
</TD> <TD align="right"> 
0.1654142360
</TD> </TR>
   </TABLE>
</center>

and, the conversion *to* character takes:

<center>
<TABLE border=1>
<TR> <TH> 
Version
</TH> <TH> 
median
</TH>  </TR>
  <TR> <TD> 
Rcpp-toChar
</TD> <TD align="right"> 
0.0039565840
</TD> </TR>
  <TR> <TD> 
Rcpp+V()-toChar
</TD> <TD align="right"> 
0.0322646160
</TD> </TR>
  <TR> <TD> 
Pure R-toChar
</TD> <TD align="right"> 
0.2917557870
</TD> </TR>
   </TABLE>
</center>

But, a visualization is (often) worth a dozen tables, so we'll take the
test results and make a violin plot (which is just a more granular
boxplot). Note that the plot is on a **log scale**, so the differences
between each set of comparisons are actually much larger than your eye
will initially comprehend (hence the inclusion of the above tables).

<a class="mag" href="/blog/images/2014/05/violin.png"><img src="/blog/images/2014/05/violin.png" title="microbenchmark violin plot" alt="microbenchmark violin plot" style="max-width:100%; display: block; margin: auto;" /></a>

It's often difficult for us to grok fractional seconds, so let's do some
basic math to see how long each method would take to process **1
billion** IP addresses. We'll use the median values from above and
compare the results in a simple bar chart:

<a class="mag" href="/blog/images/2014/05/billion.png"><img src="/blog/images/2014/05/billion.png" title="billion" alt="billion" style="width: 75%; display: block; margin: auto;" />

The fully vectorized `Rcpp` version are the clear "winner" and will let
us scale our IPv4 address conversions to millions, billions or trillions
of operations without having to rely on other scripting languages. We
can use this base as foundation for a complete IP address `S4` class
that we'll cover in future posts.

You can find the `Rmd` source that helped generate this post over [at github](https://gist.github.com/hrbrmstr/ae97ee7d27435d04fc4c).
