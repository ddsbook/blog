Title: Modern Honey Network Machinations with R, Python & JavaScript
Date: 2015-08-23 08:55
Slug: mhn-machinations-r-python-javascript
Tags: blog, r, rstats, python, javascript
status: draft
Category: blog
Author: Bob Rudis (@hrbrmstr)

This was (initially) going to be a blog post announcing the new [mhn R package](http://github.com/hrbrmstr/mhn) (more on what that is in a bit) but somewhere along the way we ended up taking a left turn at Albuquerque (as we often do here at ddsec hq) and had an adventure in a twisty maze of [Modern Honey Network](http://threatstream.github.io/mhn/) passages that we thought we'd relate to everyone.

### Episode 0 : The Quest!

We find our <strike>intrepid heroes</strike> data scientists finally getting around to playing with the Modern Honey Network (MHN) software that they promised [Jason Trost](https://twitter.com/jason_trost) they'd do _ages_ ago. MHN makes it easy to [freely] centrally setup, control, monitor and collect data from one or more [honeypots](https://en.wikipedia.org/wiki/Honeypot_(computing)). Once you have this data you can generate threat indicator feeds from it and also do analysis on it (which is what we're interested in eventually doing and what [ThreatStream](https://www.threatstream.com/) _does do_ with their global network of MHN contributors).

Jason has a [Vagrant](https://www.vagrantup.com/) [quickstart](https://github.com/threatstream/mhn/wiki/Getting-up-and-running-using-Vagrant) version of MHN which lets you kick the tyres locally, safely and securely before venturing out into the enterprise (or internet). You stand up the server (mostly Python-y things), then tell it what type of honeypot you want to deploy. You get a handy cut-and-paste-able string which you paste-and-execute on a system that will become an actual honeypot (which can be a "real" box, a VM or even a RaspberryPi!). When the honeypot is finished installing the necessary components it registers with your MHN server and you're ready to start catching cyber bad guys.

<center><img src="https://farm8.staticflickr.com/7035/6437570877_cf5b1a35de_o_d.jpg"/><br/>(cyber bad guy)</center>

### Episode 1 : Live! R! Package!

We decided to deploy a test MHN server and series of honeypots on [Digital Ocean](https://www.digitalocean.com/?refcode=4bb3577c3b73) since they work _OK_ on the smallest droplet size (not recommended for a production MHN setup).

While it's great to peruse the incoming attacks:

<center><a href="attacks.png"><img style="max-width:100%" src="http://dds.ec/blog/images/2015/08/attacks.png"/></a></center>

we wanted programmatic access to the data, so we took a look at all the [routes in their API](https://github.com/threatstream/mhn/blob/master/server/mhn/api/views.py) and threw together an [R package](https://github.com/hrbrmstr/mhn) to let us work with it.

    :::r
    library(mhn)
    
    attacks <- sessions(hours_ago=24)$data
    tail(attacks)
    
    ##                           _id destination_ip destination_port honeypot
    ## 3325 55d93cb8b5b9843e9bb34c75 111.222.33.111               22      p0f
    ## 3326 55d93cb8b5b9843e9bb34c74 111.222.33.111               22      p0f
    ## 3327 55d93d30b5b9843e9bb34c77 111.222.33.111               22      p0f
    ## 3328 55d93da9b5b9843e9bb34c79           <NA>             6379  dionaea
    ## 3329 55d93f1db5b9843e9bb34c7b           <NA>             9200  dionaea
    ## 3330 55d94062b5b9843e9bb34c7d           <NA>               23  dionaea
    ##                                identifier protocol       source_ip source_port
    ## 3325 bf7a3c5e-48e7-11e5-9fcf-040166a73101     pcap    45.114.11.23       58621
    ## 3326 bf7a3c5e-48e7-11e5-9fcf-040166a73101     pcap    45.114.11.23       58621
    ## 3327 bf7a3c5e-48e7-11e5-9fcf-040166a73101     pcap    93.174.95.81       44784
    ## 3328 83e2f4e0-4876-11e5-9fcf-040166a73101     pcap 184.105.139.108       43000
    ## 3329 83e2f4e0-4876-11e5-9fcf-040166a73101     pcap  222.186.34.160        6000
    ## 3330 83e2f4e0-4876-11e5-9fcf-040166a73101     pcap   113.89.184.24       44028
    ##                       timestamp
    ## 3325 2015-08-23T03:23:34.671000
    ## 3326 2015-08-23T03:23:34.681000
    ## 3327 2015-08-23T03:25:33.975000
    ## 3328 2015-08-23T03:27:36.810000
    ## 3329 2015-08-23T03:33:48.665000
    ## 3330 2015-08-23T03:39:13.899000

NOTE: that's not the real `destination_ip` so don't go poking since it's probably someone else's real system (if it's even up).

You can also get details about the attackers (this is just one example):

    :::r
    attacker_stats("45.114.11.23")$data
    
    ## $count
    ## [1] 1861
    ## 
    ## $first_seen
    ## [1] "2015-08-22T16:43:59.654000"
    ## 
    ## $honeypots
    ## [1] "p0f"
    ## 
    ## $last_seen
    ## [1] "2015-08-23T03:23:34.681000"
    ## 
    ## $num_sensors
    ## [1] 1
    ## 
    ## $ports
    ## [1] 22

The package makes it really easy (OK, we're probably a _bit_ biased) to grab giant chunks of time series and associated metadata for further analysis.

While cranking out the API package we noticed that there were no endpoints for the MHN HoneyMap. _Yes_, they do the "attacks on a map" thing but don't think too badly of them since most of you seem to want them.

<center><a href="map.png"><img style="max-width:100%" src="http://dds.ec/blog/images/2015/08/map.png"/></a></center>

After poking around the MHN source a bit more (and navigating the `view-source` of the map page) we discovered that they use a [Go-based websocket server](https://github.com/threatstream/mhn/blob/master/scripts/install_honeymap.sh) to push the honeypot hits out to the map. (You can probably see where this is going, but it takes that turn first).

### Episode 2 : Hacking the Anti-Hackers

The _other_ thing we noticed is that&mdash;unlike the MHN-server proper&mdash;the websocket component _does not require authentication_. Now, to be fair, it's also not really spitting out seekrit data, just (pretty useless) geocoded attack source/dest and type of honeypot involved.

Still, this got us wondering if we could find other MHN servers out there in the cold, dark internet. So, we fired up RStudio again and took a look using the [shodan package](http://github.com/hrbrmstr/shodan):

    :::r
    library(shodan)
    
    # the most obvious way to look for MHN servers is to 
    # scour port 3000 looking for content that is HTML
    # then look for "HoneyMap" in the <title>
    
    # See how many (if any) there are
    host_count('port:3000 title:HoneyMap')$total
    ## [1] 141
    
    # Grab the first 100
    hm_1 <- shodan_search('port:3000 title:HoneyMap')
    
    # Grab the last 41
    hm_2 <- shodan_search('port:3000 title:HoneyMap', page=2)
    
    head(hm_1)
    
    ##                                           hostnames    title
    ## 1                                                   HoneyMap
    ## 2                                  hb.c2hosting.com HoneyMap
    ## 3                                                   HoneyMap
    ## 4                                          fxxx.you HoneyMap
    ## 5            ip-192-169-234-171.ip.secureserver.net HoneyMap
    ## 6 ec2-54-148-80-241.us-west-2.compute.amazonaws.com HoneyMap
    ##                    timestamp                isp transport
    ## 1 2015-08-22T17:14:25.173291               <NA>       tcp
    ## 2 2015-08-22T17:00:12.872171 Hosting Consulting       tcp
    ## 3 2015-08-22T16:49:40.392523      Digital Ocean       tcp
    ## 4 2015-08-22T15:27:29.661104      KW Datacenter       tcp
    ## 5 2015-08-22T14:01:21.014893   GoDaddy.com, LLC       tcp
    ## 6 2015-08-22T12:01:52.207879             Amazon       tcp
    ##                                                                                                                                                                                                       data
    ## 1 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 2278\r\nContent-Type: text/html; charset=utf-8\r\nLast-Modified: Sun, 02 Nov 2014 21:16:17 GMT\r\nDate: Sat, 22 Aug 2015 17:14:22 GMT\r\n\r\n
    ## 2 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 2278\r\nContent-Type: text/html; charset=utf-8\r\nLast-Modified: Wed, 12 Nov 2014 18:52:21 GMT\r\nDate: Sat, 22 Aug 2015 17:01:25 GMT\r\n\r\n
    ## 3 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 2278\r\nContent-Type: text/html; charset=utf-8\r\nLast-Modified: Mon, 04 Aug 2014 18:07:00 GMT\r\nDate: Sat, 22 Aug 2015 16:49:38 GMT\r\n\r\n
    ## 4 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 2278\r\nContent-Type: text/html; charset=utf-8\r\nDate: Sat, 22 Aug 2015 15:22:23 GMT\r\nLast-Modified: Sun, 27 Jul 2014 01:04:41 GMT\r\n\r\n
    ## 5 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 2278\r\nContent-Type: text/html; charset=utf-8\r\nLast-Modified: Wed, 29 Oct 2014 17:12:22 GMT\r\nDate: Sat, 22 Aug 2015 14:01:20 GMT\r\n\r\n
    ## 6 HTTP/1.1 200 OK\r\nAccept-Ranges: bytes\r\nContent-Length: 1572\r\nContent-Type: text/html; charset=utf-8\r\nDate: Sat, 22 Aug 2015 12:06:15 GMT\r\nLast-Modified: Mon, 08 Dec 2014 21:25:26 GMT\r\n\r\n
    ##   port location.city location.region_code location.area_code location.longitude
    ## 1 3000          <NA>                 <NA>                 NA                 NA
    ## 2 3000   Miami Beach                   FL                305           -80.1300
    ## 3 3000 San Francisco                   CA                415          -122.3826
    ## 4 3000     Kitchener                   ON                 NA           -80.4800
    ## 5 3000    Scottsdale                   AZ                480          -111.8906
    ## 6 3000      Boardman                   OR                541          -119.5290
    ##   location.country_code3 location.latitude location.postal_code location.dma_code
    ## 1                   <NA>                NA                 <NA>                NA
    ## 2                    USA           25.7906                33109               528
    ## 3                    USA           37.7312                94124               807
    ## 4                    CAN           43.4236                  N2E                NA
    ## 5                    USA           33.6119                85260               753
    ## 6                    USA           45.7788                97818               810
    ##   location.country_code location.country_name                           ipv6
    ## 1                  <NA>                  <NA> 2600:3c02::f03c:91ff:fe73:4d8b
    ## 2                    US         United States                           <NA>
    ## 3                    US         United States                           <NA>
    ## 4                    CA                Canada                           <NA>
    ## 5                    US         United States                           <NA>
    ## 6                    US         United States                           <NA>
    ##            domains                org   os module                         ip_str
    ## 1                                <NA> <NA>   http 2600:3c02::f03c:91ff:fe73:4d8b
    ## 2    c2hosting.com Hosting Consulting <NA>   http                  199.88.60.245
    ## 3                       Digital Ocean <NA>   http                104.131.142.171
    ## 4         fxxx.you      KW Datacenter <NA>   http                  162.244.29.65
    ## 5 secureserver.net   GoDaddy.com, LLC <NA>   http                192.169.234.171
    ## 6    amazonaws.com             Amazon <NA>   http                  54.148.80.241
    ##           ip     asn link uptime
    ## 1         NA    <NA> <NA>     NA
    ## 2 3344448757 AS40539 <NA>     NA
    ## 3 1753452203    <NA> <NA>     NA
    ## 4 2733907265    <NA> <NA>     NA
    ## 5 3232361131 AS26496 <NA>     NA
    ## 6  915689713    <NA> <NA>     NA

Yikes! 141 servers just on the default port (3000) alone! While these systems may be shown as existing in Shodan, we really needed to confirm that they were, indeed, live MHN HoneyMap [websocket] servers. 

### Episode 3 : Picture [Im]Perfect
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
Rather than just test for existence of the websocket/data feed we decided to take a screen shot of every server, which is pretty easy to do with a crude-but-effective mashup of R and `phantomjs`. For this, we made a script which is just a call&mdash;for each of the websocket URLs&mdash;to the "built-in" phantomjs [rasterize.js script](https://gist.github.com/hrbrmstr/6b119648739cd275a69e#file-ourrasterize-js-L45) that we've slightly modified to wait 30 seconds from page open to snapshot creation. We did that in the hopes that we'd see live attacks in the captures.

    :::r
    cat(sprintf("phantomjs rasterize.js http://%s:%s %s.png 800px*600px\n",
                hm_1$matches$ip_str,
                hm_1$matches$port,
                hm_1$matches$ip_str), file="capture.sh")

That makes `capture.sh` look something like:

    :::bash
    phantomjs rasterize.js http://199.88.60.245:3000 199.88.60.245.png 800px*600px
    phantomjs rasterize.js http://104.131.142.171:3000 104.131.142.171.png 800px*600px
    phantomjs rasterize.js http://162.244.29.65:3000 162.244.29.65.png 800px*600px
    phantomjs rasterize.js http://192.169.234.171:3000 192.169.234.171.png 800px*600px
    phantomjs rasterize.js http://54.148.80.241:3000 54.148.80.241.png 800px*600px
    phantomjs rasterize.js http://95.97.211.86:3000 95.97.211.86.png 800px*600px

Yes, there _are_ far more elegant ways to do this, but the number of URLs was small and we had no time constraints. We could have used a
pure phantomjs solution (list of URLs in phantomjs JavaScript) or used
GNU parallel to speed up the image captures as well.

Sifting through ~140 images manually to see if any had "hits" would not have been _too_ bad, bit a glance at the directory listing showed that many had the exact same size, meaning those were probably showing a default/blank map. We `uniq`'d them by MD5 hash and made an image gallery of them:

<style>
.wmuGallery .wmuGalleryImage,.wmuSlider .wmuSliderWrapper article{position:relative;text-align:center}.wmuGallery .wmuGalleryImage img,.wmuSlider .wmuSliderWrapper article img{max-width:100%;width:auto;height:auto}.wmuGallery,.wmuSlider{margin-bottom:20px}.wmuSlider{position:relative;overflow:hidden}.wmuSlider .wmuSliderWrapper{display:none}.wmuGallery .wmuGalleryImage{margin-bottom:10px}.wmuSliderNext,.wmuSliderPrev{position:absolute;width:40px;height:80px;text-indent:-9999px;background:url(http://dds.ec/images/sprites.png) no-repeat;top:50%;margin-top:-40px;z-index:2}.wmuSliderPrev{background-position:100% 0;left:20px}.wmuSliderNext{right:20px}.wmuSliderPagination{z-index:2;position:absolute;left:20px;bottom:10px}.wmuSliderPagination li{float:left;margin:0 5px 0 0;list-style-type:none}.wmuSliderPagination a{display:block;text-indent:-9999px;width:10px;height:10px;background:url(http://dds.ec/images/sprites.png) 0 -80px no-repeat}.wmuSliderPagination a.wmuActive{background-position:-10px -80px}
</style>
<div style="width:630;height:600;"><div class="wmuSlider"><div class="wmuSliderWrapper">
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/146.83.210.9.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/187.174.195.77.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/12.45.132.78.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/54.148.80.241.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/188.122.73.245.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/202.12.103.108.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/45.55.195.250.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/174.140.165.250.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/54.183.152.115.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/81.167.148.253.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/128.199.121.95.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/192.169.69.20.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/192.169.69.25.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/192.167.251.4.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/192.210.204.20.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/46.101.24.221.png"/></article>
<article><img width="800" height="600" src="http://dds.ec/galleries/hp/46.101.19.232.png"/></article>
</div></div></div>
<script type="text/javascript" charset="utf8" src="http://dds.ec/js/modernizr.custom.min.js"></script>    
<script type="text/javascript" charset="utf8" src="http://dds.ec/js/vendor/jquery-1.10.2.min.js"></script>
<script type="text/javascript" charset="utf8" src="http://dds.ec/js/jquery.touchSwipe.min.js"></script>
<script type="text/javascript" charset="utf8" src="http://dds.ec/js/jquery.wmuGallery.min.js"></script>
<script type="text/javascript" charset="utf8" src="http://dds.ec/js/jquery.wmuSlider.min.js"></script>
<script>$('.wmuSlider').wmuSlider({animation: 'slide',animationDuration: 600,slideshow: true,slideshowSpeed: 7000,slideToStart: 0,navigationControl: true,paginationControl: false,previousText: 'Previous',nextText: 'Next',touch: Modernizr.touch,slide: 'article',items: 1});</script>

It was interesting to see Mexico CERT and OpenDNS in the mix.

Most of the 140 were active/live MHN HoneyMap sites. We can only imagine what a full Shodan search for HoneyMaps on other ports would come back with (mostly since we only have the basic API access and don't want to burn the credits).

### Episode 3 : With "Meh" Data Comes Great Irresponsibility

For those who may not have been with DDSec for it's entirety, you may not be aware that we have our _own_ [attack map](http://ocularwarfare.com/ipew/) ([github](https://github.com/hrbrmstr/pewpew)).

We thought it would be interesting to see if we could mashup MHN HoneyMap data with our creation. We first had to see what the websocket returned. Here's a bit of Python to do that (the R `websockets` package was abandoned by it's creator, but keep an eye out for another @hrbrmstr resurrection):

    :::python
    import websocket
    import thread
    import time

    def on_message(ws, message):
        print message

    def on_error(ws, error):
        print error

    def on_close(ws):
        print "### closed ###"


    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("ws://128.199.121.95:3000/data/websocket",
                                on_message = on_message,
                                on_error = on_error,
                                on_close = on_close)
    ws.run_forever()

That particular server is _very_ active, hence why we chose to use it.

The output should look something like:

    :::bash
    $ python ws.py
    --- request header ---
    GET /data/websocket HTTP/1.1
    Upgrade: websocket
    Connection: Upgrade
    Host: 128.199.121.95:3000
    Origin: http://128.199.121.95:3000
    Sec-WebSocket-Key: 07EFbUtTS4ubl2mmHS1ntQ==
    Sec-WebSocket-Version: 13


    -----------------------
    --- response header ---
    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: nvTKSyCh+k1Rl5HzxkVNAZjZZUA=
    -----------------------
    {"city":"Clarks Summit","city2":"San Francisco","countrycode":"US","countrycode2":"US","latitude":41.44860076904297,"latitude2":37.774898529052734,"longitude":-75.72799682617188,"longitude2":-122.41940307617188,"type":"p0f.events"}
    {"city":"Clarks Summit","city2":"San Francisco","countrycode":"US","countrycode2":"US","latitude":41.44860076904297,"latitude2":37.774898529052734,"longitude":-75.72799682617188,"longitude2":-122.41940307617188,"type":"p0f.events"}
    {"city":null,"city2":"Singapore","countrycode":"US","countrycode2":"SG","latitude":32.78310012817383,"latitude2":1.2930999994277954,"longitude":-96.80670166015625,"longitude2":103.85579681396484,"type":"p0f.events"}

Those are near-perfect JSON records for our map, so we figured out a way to tell iPew/PewPew (whatever folks are calling it these days) to take any accessible MHN HoneyMap as a live data source. For example, to plug this highly active HoneyMap into iPew all you need to do is [this](http://ocularwarfare.com/ipew/?mhnsource=http://128.199.121.95:3000/data/):

>`http://ocularwarfare.com/ipew/?mhnsource=http://128.199.121.95:3000/data/`

Once we make the websockets component of the iPew map a bit more resilient we'll post it to GitHub (you can just view the source to try it on your own now).

### Fin

As we stated up front, the main goal of this post is to introduce the [mhn package](http://github.com/hrbrmstr/mhn). But, our diversion has us curious. Are the open instances of HoneyMap deliberate or accidental? If any of them are "real" honeypot research or actual production environments, does such an open presence of the MHN controller reduce the utility of the honeypot nodes? Is Greenland paying ThreatStream to use that map projection instead of a better one?

If you use the new package, found this post helpful (or, at least, amusing) or know the answers to any of those questions, drop a note in the comments.
