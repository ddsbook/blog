Title: Firewall-busting ASN-lookups - Part 1
Date: 2014-04-23 22:11:26
Category: tools
Status: draft
Tags: asn, ip, r, rstats
Slug: firewall-busting-asn-lookups
Author: Bob Rudis (@hrbrmstr)

>This is a short post on one way to bust through your corproate firewall when trying to use the [Team CYMRU ASN lookup facility](http://www.team-cymru.org/Services/ip-to-asn.html#dns) that we presented in [our book](http://bit.ly/ddsec). Part 2 will show how to create a [vectorized](http://stackoverflow.com/a/11965712/1457051) version of this code.

Most corporate networks aren't going to allow `port 43` (`WHOIS`) access directly, which will make the bulk lookup routines that we presented in *Data-Driven Security* (the book) fail miserably. The Team CMRYU "API" also works via `DNS`, and I suspect that gets out in far more places than `WHOIS` does (just ask any C&C malware author).

The following is a small function that performs an IP&#8594;ASN mapping if given a character IP address (see the book for how to use the integer format in R):

    :::rsplus
    #' Return ASN info in list format from a given IP address
    #'
    #' @param string input character vector for IP address (defaults to Team CYMRU example address)
    #' @return list with "ip", "asn", "cidr", "cn", "registry"
    ip2asn <- function(ip="216.90.108.31") {
    
      # reverse the octets
      ip <- paste(rev(unlist(strsplit(ip, "\\."))), sep="", collapse=".")
    
      # create the 'dig' command string
      dig <- sprintf("dig +short %s.origin.asn.cymru.com TXT", ip)
    
      # call 'dig'
      out <- system(dig, intern=TRUE)
    
      # unwrap the results (ignoring date in this example)
      out <- unlist(strsplit(gsub("\"", "", out), "\ *\\|\ *"))
    
      # return as a list  
      return(list(ip=ip, asn=out[1], cidr=out[2], cn=out[3], registry=out[4]))
    
    }
    
    $ip
    [1] "31.108.90.216"
    
    $asn
    [1] "23028"
    
    $cidr
    [1] "216.90.108.0/24"
    
    $cn
    [1] "US"
    
    $registry
    [1] "arin"

>Remember: you can use `?STRING` at the `R` console to lookup any routine that you might not be familiar with.

This function relies on the [dig](http://www.madboa.com/geek/dig/) command. Readers who are running Windows might need to [install](http://www.madboa.com/geek/dig/) `dig` before using this function.

Stay tuned for Part 2!