Title: The New and Improved R Shodan Package
Date: 2015-08-07 10:15
Slug: the-new-and-improved-r-shodan-package
Tags: blog
status: draft
Category: blog
Author: Bob Rudis (@hrbrmstr)

For those not involved with all things "cyber", let me start with a description of what [Shodan](http://shodan.io/) is (though visiting the site is probably the best introduction to what secrets it holds).

Shodan is&mdash;at it's core&mdash;a search engine. Unlike Google, Shodan indexes what I'll call "cyber" metadata and content about everything accessible via a public IP address. This means things like

- routers, switches and cable/DSL/FiOS modems (which are the underpinnings of our innternet access)
- internet web, ftp, mail, etc servers
- public (protected or otherwise) CCTV & home surveillance & web camears
- desktops, printers and other things that may end up in public IP space
- gas station pumps and industrial control systems
- VoIP phones & more

Shodan contacts the IP addresses associated with all the devices, sees what [ports](https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers) and [protocols](https://en.wikipedia.org/wiki/Internet_Protocol) might be in use and then tries to retrieve content from those ports and protocols (which could be anything from webcam snapshots to web server HTML to actual header responses from internet servers to banners from routers and switches). It indexes all that metadata and content and makes it available in a search engine and API for securiy researchers (I was _so_ tempted to put that word in quotes).

To give you an idea what it can do, take a look at [this query for webcams](https://www.shodan.io/search?query=Server%3A+SQ-WEBCAM) and/or read this [full explanation of what you can do with that data](http://null-byte.wonderhowto.com/how-to/hack-like-pro-find-vulnerable-webcams-across-globe-using-shodan-0154830/).

While you can have fun with Shodan, it does have real value to security folk and R needed a real API interface to it (I did a half-hearted one a couiple years ago). Hence the rebirth of the [shodan package](https://github.com/hrbrmstr/shodan).

The package is brand-new, but it has basic, full coverage of the [Shodan API](https://developer.shodan.io/api) _except_ for the streaming functions. But, a line of code is worth a thousand blatherings, so let's find all the IIS servers in Maine.

    :::r
    library(shodan)
    maine_iis <- shodan_search("iis state:me")

    # get the total number of IIS servers in Maine that Shodan found
    print(maine_iis$total) 
    ## [1] 2948

    # what else does it know about these servers?
    print(colnames(maine_iis$matches))

    ##  [1] "product"   "hostnames" "version"   "title"     "ip"        "org"      
    ##  [7] "isp"       "cpe"       "data"      "asn"       "port"      "transport"
    ## [13] "timestamp" "domains"   "ip_str"    "os"        "_shodan"   "location" 
    ## [19] "ssl"       "link"  

Now, the `data.frame` in `maine_iis$matches` is somewhat ugly for the moment. Some columns have lists and data frames since the Shodan REST API returns (like many APIs do) nested JSON. I'm actually looking for collaboration on what would be the most useful format for the returned data structures so hit me up if you have ideas that would benefit your use of it.

I'll violate my own rule about mapping IP addresses just to show you Shodan also does geolocation for you (and, hey, y'all seem to like maps). We'll make it a _bit_ more useful and add some metadata about what it found to the location popups:

    :::r
    library(leaflet)
    library(htmltools)
    library(htmlwidgets)

    for_map <- cbind.data.frame(loc, 
                            ip=maine_iis$matches$ip,
                            isp=maine_iis$matches$isp,
                            title=maine_iis$matches$title,
                            org=maine_iis$matches$org,
                            data=maine_iis$matches$data,
                            stringsAsFactors=FALSE)

    leaflet(for_map, width="600", height="600") %>% 
      addTiles() %>% 
      setView(-69.233328, 45.250556, 7) %>% 
      addCircles(data=for_map, lng=~longitude , lat=~latitude, 
                 popup=~sprintf("<b>%s</b><br/>%s, Maine</b><br/>ISP: %s<br/><hr noshade size='1'/><pre>%s\n\n%s", 
                                htmlEscape(org), htmlEscape(city), htmlEscape(isp), 
                                htmlEscape(title), htmlEscape(data))) 


<center>
<b>IIS Servers in MAine</b>
<iframe style="max-width=100%" 
        src="/widgets/2015-08-08-shodan-01.html" 
        sandbox="allow-same-origin 
        allow-scripts" width="600" 
        height="600" 
        scrolling="no" 
        seamless="seamless" 
        frameBorder="0"></iframe>
</center>
