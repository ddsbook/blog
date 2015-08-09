Title: New R Package - domaintools (access the DomainTools.com WHOIS API)
Date: 2015-08-09 15:11
Slug: new-r-package-domaintools
Tags: blog, r, rstats
Category: blog
Author: Bob Rudis (@hrbrmstr)

We just did a [github release](https://github.com/hrbrmstr/domaintools) for an R package that provides an interface to the [DomainTools API](http://www.domaintools.com/resources/api-documentation/). It provides access to the core API functions that aren't restricted (i.e. the ones we have access to):

-   `domaintools_api_key`: Get or set `DOMAINTOOLS_API_KEY` value
-   `domaintools_username`: Get or set `DOMAINTOOLS_API_USERNAME` value
-   `domain_profile`: Domain Profile
-   `hosting_history`: Hosting History
-   `parsed_whois`: Parsed Whois
-   `reverse_ip`: Reverse IP
-   `reverse_ns`: Reverse Nameserver
-   `shared_ips`: Shared IPs
-   `whois`: Whois Lookup
-   `whois_history`: Whois History

Each function has a full description and sample call, so feel free to kick the typres and provide feedback on github.

If you have access to the API elements we do not, please either contribute a PR or help us out with some testing.

This is one more package on our path towards a complete set of "cybersecurity" R packages to help information security folk get their (hopefully) data-driven jobs done in R. I believe @[quominus](twitter.com/quominus) _may_ be working on a macro "whois" pacakge to unify access to all the various WHOIS services, too.
