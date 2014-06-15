Title: Another Marx Video: TCP/UDP Ports
Date: 2014-06-15 13:00:00
Category: R
Tags: R, Video, Marx
Slug: marx-ports
Author: Jay Jacobs (@jayjacobs)

Bob and I presented at Secure360 together back in May (the slides are [available on our site]( http://dds.ec/sec360/2014)).   But during that presentation we played the last Marx video I built in the post titled, “[Visualizing countries from the Marx data](http://datadrivensecurity.info/blog/posts/2014/Apr/marxvideo/)“.  The reaction we got was completely unexpected and many people commented on how much they enjoyed that video afterwards. Combine that with the fact that I already enjoy making R-based videos, and the conditions were favorable for a follow up video.

Last time I just captured the source country and destination host.  This time I wanted to capture the ports being scanned, but struggled to also include the host being scanned.  I ended up shifting the source countries into the center and sent UDP traffic to the left and TCP traffic to the right.  I also wanted to fit it a LOT of ports, so I had to reduce the font down to the point of being unreadable.  I compensated for that by having the font increase in size when the port received packets.   Take a look, but remember, this data is from nine separate hosts from the eight Amazon (AWS) data centers and this isn’t just one hosts worth of data.

<iframe width="560" height="315" src="//www.youtube.com/embed/GEjzCR1fN8Y" frameborder="0" allowfullscreen></iframe>

Couple of things to note:
*  I slowed down the time it takes a bubble to travel so the times don’t line up with the previous video.  In hindsight, I should have tried to keep these in sync. 
*  The massive port scan from Vietnam (starting at 1:12) is really interesting, and since one frame is 5 minutes, this is a really slow port scan.  Best guess is, they are scanning way more than just these 9 hosts.
*  The huge packet flood from Iran to Tokyo is also interesting in this one.  Looking at 4:27, we see a huge ball from Iran to UDP port 2193.  A liberal dose of searching turns up it is probably ”Dr.Web Enterprise Management”.  But who really know what’s going on.  Maybe just a configuration error. 

And finally the code to create this is in [this gist](https://gist.github.com/jayjacobs/b42ac3661d38f2b83350). 
