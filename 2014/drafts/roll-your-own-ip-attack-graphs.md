Title: Roll Your Own IP Attack Graphs with IPew
Date: 2014-10-29 10:05:50
Category: blog
Status: draft
Tags: datavis, d3, security
Slug: roll-your-own-ip-attack-graphs
Author: Bob Rudis (@hrbrmstr)

<img src="https://raw.githubusercontent.com/hrbrmstr/pewpew/master/pewpew.png" style="max-width:100%"/> 

Are you:

- A security vendor feeling inadequate because you don't have your own "live attack graph"?
- A SOC manager who needs to distract/impress visitors and/or executives with an "ooh, shiny!" display?
- A researcher who wants to draw attention to your project but just don't have the time to dedicate to inane animated visualizations? 

If so, then [IPew](http://ocularwarfare.com/ipew) is for you!

### What is IPew?

IPew is an open source "live attack map" simulation built with D3 ([Datamaps](http://datamaps.github.io/)) that puts global cyberwar just a `git clone` away for anyone wanting to display these good-for-only-eye-candy maps on your site.

### What makes IPew Different from The Others?

- **SOUND EFFECTS**!! Why settle for the silent treatment when you can have your choice of sound effects ranging from Star Wars blasters (the default) to [Galaga guns](http://ocularwarfare.com/ipew?galaga=1) and more (Wargames, Babylon 5, ST:TNG, a disturbing human "pew" and even the choice to cycle through all of them)!

- **PROPER PROJECTIONS**!! Does Greenland make the other maps look big? We thought so, too. IPew uses the [Winkel-Tripel](http://xkcd.com/977/) projection which we feel provides the proper balance of geometries, positions & size, which will set _your_ map apart from all the other cartographic posers.
  
- **FULLY (mostly) RESPONSIVE**! From iPhones to 60" displays, IPew accomodates all screen sizes. Setup multiple ones in your SOC for *maximum impressiveness*.

- **SELF-EFFACEMENT**!! While we use actual, generated probabilities for the source country attack frequencies we took some liberties with the attack types. Plus, we let you *go crazy* with configurations by including options to:

  * [Randomize](http://ocularwarfare.com/ipew?random_mode=1) source/destination pairs
  * Let the internet have a really [bad day](http://ocularwarfare.com/ipew?bad_day=1&nofx=1)
  * Point the finger at [everyone's favorite whipping country](http://ocularwarfare.com/ipew?china_mode=1&wargames=1)
  * Custmize the display with your [org name](http://ocularwarfare.com/ipew?china_mode=1&allfx=1&org_name=Mandiant) (that one's my favorite config)

Full configuration options are over at [github](https://github.com/hrbrmstr/pewpew) and feel free to clone, modify and use this to your heart's content. It's been released under a CC BY-SA license, so be sure to share your creation with the world!.

Brought to you by [hrbrmstr](http://twitter.com/hrbrmstr) & [alexcpsec](http://twitter.com/alexcpsec).