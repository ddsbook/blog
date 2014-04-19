Title: CRLs, Heartbleed, the Sad State of SSL & a DDS Reader Challenge!
Date: 2014-04-19 15:28:34
Category: challenge
Status: draft
Tags: python, ssl, heartbleed, analysis
Slug: crls-heartbleed-and-the-sad-state-of-ssl
Author: Bob Rudis (@hrbrmstr) & Jay Jacobs (@jayjacobs)

The fine folks over as [SANS ISC](http://isc.sans.org/) tweeted this out last week:

<blockquote class="twitter-tweet" lang="en"><p>The GlobalSign CRL just &quot;exploded&quot; with &gt; 54k revocations today. removed it from our graph for now. <a href="http://t.co/JZdDu7ulK7">http://t.co/JZdDu7ulK7</a></p>&mdash; SANS ISC (@sans_isc) <a href="https://twitter.com/sans_isc/statuses/456575373015138306">April 16, 2014</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

That piqued the curiosity of both of us, especially `@hrbrmstr` after him seeing `@lseltzer`'s [ZDNet article](http://www.zdnet.com/internet-slowed-by-heartbleed-identity-crisis-7000028506/) and ThreatPost's  [summary](http://threatpost.com/certificate-revocation-slow-for-heartbleed-servers/105489) of the situation reported by Netcraft [[1](http://news.netcraft.com/archives/2014/04/11/heartbleed-certificate-revocation-tsunami-yet-to-arrive.html)] [[2](http://news.netcraft.com/archives/2014/04/15/revoke-the-time-is-nigh.html)].

Now, Netcraft monitors more CRL lists than the ISC does but their revocations-per-hour chart shows a similar pattern:

<center><img style="max-width:100%" src="http://news.netcraft.com/wp-content/uploads/2014/04/heatbleed-revocations.png"/></center>

The second Netcraft article does enough of a good job stating most of the problems related to transport security & integrity that we won't go into the issues here. It's a bit sad, though that:

- Safari & Firefox do "best effort" OSCP by default
- Google has it's own way of dealing with browser-based certificate checks
- The use of CRLs by issuers is inconsistent at best
- OCSP stapling (which deals with some of the privacy concerns of OSCP) is not ubiquitous
- [Soft-fail](http://security.stackexchange.com/questions/55457/how-to-configure-browser-to-detect-revoked-certificates) is still 'a thing'
- The `reason` field for each revocation is rarely filled out, making the whole thing (in `@hrbrmstr`'s opinion) less than useful

If you want to play along at home with Netcraft & SANS ISC, you *could* go the route of hand-grabbing each of the 79 certificates on the SANS list, running:

    openssl crl -in <filename> -inform DER -text

by hand and processing the output, but it might be a bit better to use our [CSV version](https://gist.github.com/hrbrmstr/b466f9348b6369990c05) [GH] and write a script to grab the files (which is simple enough to not put here).

Rather than rely on the `openssl` command-line, you can use the `PyOpenSSL` library to process the files, which will make it easier to grab the reason for revocation:

    import OpenSSL
    import sys
    
    # pass in the PEM CRL file
    CRLFile = sys.argv[1]
    
    # read it in
    with open(CRLFile, 'r') as crlfile:
        CRL = "".join(crlfile.readlines())
    
    # create the CRL object
    parsedCRL = OpenSSL.crypto.load_crl(OpenSSL.crypto.FILETYPE_PEM, CRL)
    
    # get all the 'revoked' entried
    revoked = parsedCRL.get_revoked()
    
    # print out each entry
    for entry in revoked:
        print f, entry.get_rev_date(), entry.get_reason()

You'll need to do a translation step first from DER to PEM:

    openssl crl -inform DER -outform PEM \
       -in revoked.crl -out revoked.pem

and, will probably want to validate the format ahead of time since some files are actually PEM files to begin with.

###The Challenge!

We've teased out some graphs on Twitter the other day and *could* have just posted end-to-end code here. Rather than do that, we're issuing a DDS reader challenge! Winning is simple! Just provide a **complete solution** to the following requirements and you'll be entered to win a **signed copy of our book**. All you have to do to enter is send an e-mail to `contest at datadrivensecurity dot info` with a link to a [GitHub Gist](https://gist.github.com/) (any language/platform within reason), an iPython Notebook (via the [iPython Notebook Viewer](http://nbviewer.ipython.org/)) or [RPubs](https://rpubs.com/) that does the following:

- has a script/program that uses the CSV provided (or a better one you can find or create that has even more issuers) that downloads the CRLs and generates a data file or database records that have (at a minmum) `timestamp`, `issuer` & `reason` fields (you can include more if you want)
- has one or more additional scripts/programs that performs analyses and generates charts with explanations that tells the story of what CRL revocations looked like before **and** after the Heartbleed "crisis". At a minimum, you **must** show by-day, by-hour, by-issuer and by-reason views
- extra consideration will be given to submissions that are repeatable (i.e. not one-off scripts)

Once we receive the e-mail, you'll get a confirmation response (ping us on Twitter if you don't get a response as it's a GoDaddy forwarder).

Make sure you don't blather out the URL you provide to us before the contest! We'll publish **all** working entries in the post that announces the winner. If you already have a copy of our book or [acquire a copy](http://bit.ly/ddsec) to help with the contest, we'll work out another book-prize (preferably from Wiley Press :-) with you.

This contest will run until **Sunday, April 26, 2014 23:59PDT** and the winner will be announced by Wednesday of that week.

Questions & clarifications can be asked of either Bob or Jay on Twitter. 


