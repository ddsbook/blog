Title: Speeding Up IPv4 Address Conversion in R
Date: 2014-05-14 20:00:00
Tags: rstats, r, rcpp
Slug: speeding-up-ipv4-address-conversion-in-r
Author: Bob Rudis (@hrbrmstr)

In [our book](http://dds.ec/amzn) we provide examples of how to convert IPv4 addresses to integer format (and back). We held ourselves to using only basic R functionality since the book had to be at an introductory level. On a fairly modern box, the `ip2long` function  takes (roughly) `0.1s` to convert 4,000 IPv4 address to integers (I just happened to have a file with 4K of IPv4 addresses lying around). For raw R code, that's not too shabby, but we can incorporate some of the `Rcpp` techinques we showed in previous posts to crank that time down *significantly*. Don't worry, this post will be much shorter than the previous one since we're not building a whole package, just showing you a quick way to smooth out bottlenecks by (briefly) dropping into C++ and taking advantage of the [Boost](http://www.boost.org/) libraries.

For those unfamiliar with C++, Boost is a collection of robust and rigorously developed/peer-reviewed C++ libraries that are very compatible with `Rcpp`. We're going to use the <code>[ip::address_v4](http://www.boost.org/doc/libs/1_55_0/doc/html/boost_asio/reference/ip__address_v4.html)</code> class to replace the functionality of two of the book's IPv4 conversion functions (`ip2long` and `long2ip`). Put the following code into a file called `iputils.cpp`

    :::cpp
    #include <Rcpp.h> 
    #include <boost/asio/ip/address_v4.hpp>
    
    using namespace Rcpp; 
    
    # we're modeling these sample routine names off of 
    # the C inet_ntop and inet_pton functions
    
    #' Convert IP in dotted (char) notation to integer
    // [[Rcpp::export]]
    unsigned long rinet_pton (CharacterVector ip) { 
      return(boost::asio::ip::address_v4::from_string(ip[0]).to_ulong());
    }
    
    #' Convert an IP in integer foramt to dotted (char) notation
    // [[Rcpp::export]]
    CharacterVector rinet_ntop (unsigned long addr) {
      return(boost::asio::ip::address_v4(addr).to_string());
    }

Now, either in another R file or in the R console, do the following:

    :::r
    # these make the Rcpp magic happen
    library(Rcpp)
    library(inline)
    
    # this compiles our code and makes the
    # two functions available to our session
    sourceCpp("iputils.cpp")
    
    # test convert an IPv4 string to integer
    rinet_pton("10.0.0.0")
    [1] 167772160
    
    # test conversion back
    rinet_ntop(167772160)
    [1] "10.0.0.0"

The `iputils.cpp` file will need to be in the working directory for that bit of code to work (which is why packages are usually a better route). The call to `sourceCpp` does most of the heavy lifting for us (with some help from the `[[Rcpp::export]]` hint in the code which tells `sourceCpp` to do quite a bit of work for you under the covers). The `sourceCpp` function takes care of ensuring that proper memory allocation & garbage collection protection is performed and also handles all return value wrapping (conversion). As you can see in the code snippet, the Boost `asio` library provides two methods that make it super-easy to use native versions of the IP address conversion functions and also highlights the object compatibilty between `Rcpp` and C++.

Performing the same 4,000 IPv4 conversion exercise now takes **`0.01s`** (remember, the pure R version took **`0.1s`**). For a few thousand IP addresses, the difference is negligible, but if you're working with millions or billions of IP addresses, this speedup can help dramatically and keep your processing in R vs potentially splitting up you workflow between R and, say, Python.

>**Exercise for the reader!**
>
>Try modifying the functions to handle both IPv4 *and* IPv6 addresses.
>You can start by writing two similar functions just to get your feet
>wet and then work on the logic necessary to combine the four into two.
>If you do the exercise, drop us a note here, on Twitter or over at
>github and we'll feature you in an upcoming post **and** podcast!

If the world of `Rcpp` seems intriguing, you'd do well to pick up a copy of Dirk Eddelbuttel's [Seamless R & C++ Integration with Rcpp](http://www.amazon.com/gp/product/1461468671/ref=as_li_tl?ie=UTF8&camp=1789&creative=390957&creativeASIN=1461468671&linkCode=as2&tag=rudisdotnet-20&linkId=LDK4U6A5C5G5A3FE). He goes into great detail with tons of examples that should make it much easier take advantage of the functionality that `Rcpp` provides.