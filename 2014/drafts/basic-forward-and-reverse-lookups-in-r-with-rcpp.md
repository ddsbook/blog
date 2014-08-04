Title: Basic Forward and Reverse Lookups In R (with Rcpp)
Date: 2014-08-03 23:30:00
Category: tools
Tags: r, rstats, rcpp, dns
Slug: basic-forward-and-reverse-lookups-in-r-with-rcpp
Author: Bob Rudis (@hrbrmstr)

Back in April, we [showed](http://datadrivensecurity.info/blog/posts/2014/Apr/making-better-dns-txt-record-lookups-with-rcpp/) you how to use a C resolver library to make many different kinds of DNS lookups. More oft than not, such complete functionality is not necessary, but R still only provides [nsl](http://stat.ethz.ch/R-manual/R-devel/library/utils/html/nsl.html) to get an IPv4 address of a given hostname, which is woefully inadequate. I needed to write an R implementation of the [Project Honeypot http:BL API](https://www.projecthoneypot.org/httpbl.php) (which we'll be sharing soon in an upcoming post) and didn't want (or need) the `ldns` library dependency. I will be relying on the [Boost](http://www.boost.org/) libraries [again](http://datadrivensecurity.info/blog/posts/2014/May/speeding-up-ipv4-address-conversion-in-r/) as we delve back into some Rcpp goodness to implement a simple `gethostbyname` and `gethostbyaddr` pair of functions.

You'll need `Boost` installed (the code uses the `asio` portion of the libary) as well as the `Rcpp` and `inline` packages. This post will cover building and using these two functions via `sourceCpp()`, but the upcoming post on the http:BL API will have them built into a full Rcpp package.

Here are the two functions (also available via [this gist](https://gist.github.com/hrbrmstr/8c10e5ae313581dea023)):

    :::c
    #include <Rcpp.h>
    #include <boost/asio.hpp>

    using namespace Rcpp;

    Function message("message"); // lets us use R's message() function

    //[[Rcpp::export]]
    std::vector< std::string > gethostbyname(std::string hostname) {
  
      // setup storage for our return value

      std::vector<std::string> addresses;

      boost::asio::io_service io_service;
  
      // we're dealing with network/connectivity 'stuff' + you never know
      // when DNS queries will fail, so we need to handle exceptional cases
  
      try {
    
        // setup the resolver query
    
        boost::asio::ip::tcp::resolver resolver(io_service);
        boost::asio::ip::tcp::resolver::query query(hostname, "");
   
        // prepare response iterator
  
        boost::asio::ip::tcp::resolver::iterator destination = resolver.resolve(query);
        boost::asio::ip::tcp::resolver::iterator end;
        boost::asio::ip::tcp::endpoint endpoint;
    
        // example of using a c-ish while loop to iterate through possible multiple resoponses
    
        while (destination != end) {
          endpoint = *destination++;
          addresses.push_back(endpoint.address().to_string());
      
        }
    
      } catch(boost::system::system_error& error) {
        message( "Hostname not found" );
      }

      return(addresses);

    }

    //[[Rcpp::export]]
    std::vector< std::string > gethostbyaddr(std::string ipv4) {
  
      // setup storage for our return value
  
      std::vector<std::string> hostnames;
  
      boost::asio::ip::tcp::endpoint endpoint;
      boost::asio::io_service io_service;
  
      // we're dealing with network/connectivity 'stuff' + you never know
      // when DNS queries will fail, so we need to handle exceptional cases
  
      try {
    
        // setup the resolver query (for PTR record)
    
        boost::asio::ip::address_v4 ip = boost::asio::ip::address_v4::from_string(ipv4);    
        endpoint.address(ip);
        boost::asio::ip::tcp::resolver resolver(io_service);    
    
        // prepare response iterator
    
        boost::asio::ip::tcp::resolver::iterator destination = resolver.resolve(endpoint);
        boost::asio::ip::tcp::resolver::iterator end;
    
        // example of using a for-loop to iterate through possible multiple resoponses
    
        for (int i=1; destination != end; destination++, i++) {
           hostnames.push_back(destination->host_name());
        }
    
      } catch(boost::system::system_error& error) {
        message( "Address not found" );
      }
  
      return(hostnames);
  
    }

We've covered some of the `Rcpp` basics in previous posts, but the:

    Function message("message");
 
declration is new and enables us to call the R `message()` function from within our Rcpp program just as if it were a normal C/C++ function. One can use that same functionality to call just about any R function from `Rcpp`. We're using it here to provide [suppressable] feedback to the programs that will be calling these functions, since one cannot neither guarantee network connectivity nor the efficacy of local DNS resolvers.

Another new feature being used is the ability to use standard C++ data structures (e.g. `std::string`, `std::vector`) and letting R/`Rcpp` take care of the conversions.

The basic flow for each function is the same:

- take&mdash;as input&mdash;character string (<i>take note that these functions are not [vectorized](http://datadrivensecurity.info/blog/posts/2014/May/vectorizing-ipv4-address-conversions-part-2/)</i>)
- initialize the Boost resolver functions
- make a query (host&#8594;ip/ip&#8594;host)
- build a vector of the results (handls multiple `A` &amp; `PTR` records)
- return the results

As in previous cases, to use these new `Rcpp` functions, all you have to do is ensure the file (I called it `resolver.cpp`) is in your working directory and then run:

    :::r
    library(Rcpp)
    library(inline)

    sourceCpp("resolver.cpp")

That will make the `gethostbyname` and `gethostbyaddr` functions available to R during the running session. Then, it's just a matter of using them:

    # forward
    gethostbyname("dds.ec")
    ## [1] "162.243.111.4"
 
    # reverse
    gethostbyaddr(gethostbyname("dds.ec"))
    ## [1] "162.243.111.4"

    # multiple return values
    gethostbyname("google.com")

    ##  [1] "2607:f8b0:4006:806::100e" "74.125.226.14"           
    ##  [3] "74.125.226.8"             "74.125.226.3"            
    ##  [5] "74.125.226.6"             "74.125.226.4"            
    ##  [7] "74.125.226.9"             "74.125.226.0"            
    ##  [9] "74.125.226.2"             "74.125.226.1"            
    ## [11] "74.125.226.5"             "74.125.226.7" 

There's no error checking for passed parameters and the responses for `gethostbyname` return both IPv4 & IPv6 `A` records, but handling both those conditions is relatively straightforward (and should be added for production code).

Stay tuned for the `Rcpp` package version and the use of the new functions with the `http:BL` API!