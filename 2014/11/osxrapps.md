Title: Turn R (Shiny) Scripts Into Double-clickable OS X Applictions With One Line of Code
Date: 2014-11-30 22:00:00
Category: blog
Tags: blog, r, rstats, os x, yosemite
Slug: os-x-yosemite-r-apps
Author: Bob Rudis (@hrbrmstr)

I was playing with some [non-security-oriented R+Shiny code](http://rud.is/b/2014/11/26/visualizing-historical-most-likely-first-snowfall-dates-for-u-s-regions/) the other day, and thought that Shiny apps would be even more useful if they were double-clickable applications that you could "just run"&mdash;provided R was installed on the target system&mdash;vs have to cut/paste code into R. Now, I know it's not hard to enter:

    :::r
    shiny::runGist('95ec24c1b0cb433a76a5', launch.browser=TRUE)
    
at an R console, but I'll wager many developers have users that would still appreciate a double-clickable icon. Since I'm running OS X Yosemite on some of my development machines, I thought this would be a good reason to try out Apple's new Javascript for Applications (JXA) since I am _loath_ to work in regular AppleScript.

If you fire up Apple's Script Editor, you can choose which language your script is in from the popup on the script window:

<center><img src="http://dds.ec/blog/images/2014/11/scripteditor.png"/></center>

With JXA, all you need is one line of code to run a Shiny gist in R:

    Application("R").cmd("shiny::runGist('95ec24c1b0cb433a76a5', launch.browser=TRUE)")
    
If you like/prefer "pure" AppleScript or are on an older version of OS X you still only need four lines of code:

    tell application "R"
      activate
    	cmd "shiny::runGist('95ec24c1b0cb433a76a5', launch.browser=TRUE)"
    end tell

Save the script as an application and your users will be greeted with your Shiny app in their default browser. 

### Caveat Scripter

When an application is created this way, it quits immediately after launching `R.app` and then the `R.app` window is left open (showing all the R console output from the script). I personally think this is A Very Good Thing, but some folks may not, so you can miniaturize it upon startup via:

    R = Application("R")
    R.windows[0].miniaturized = true
    R.cmd("shiny::runGist('95ec24c1b0cb433a76a5', launch.browser=TRUE)")

or

    tell application "R"
      activate
    	set miniaturized of window 1 to true
    	cmd "shiny::runGist('95ec24c1b0cb433a76a5', launch.browser=TRUE)"
    end tell

Users will still need to quit out of R, but you could also add a Shiny `actionButton` to your app that does a `quit(save="no", runLast=FALSE)` on submit (example code [in this gist](https://gist.github.com/hrbrmstr/95ec24c1b0cb433a76a5)) to make it feel like a "real" application.

This all assumes & relies on the fact that the `shiny` package is already installed on your systems. To ensure any application-dependent packages are installed without forcing the users to manually install them, you can use something like this:

    :::r
    pkg <- c("shiny", "zipcode", "pbapply", "data.table", "dplyr", 
             "ggplot2", "grid", "gridExtra", "stringi", "magrittr")
    new.pkg <- pkg[!(pkg %in% installed.packages())]
    if (length(new.pkg)) {
      install.packages(new.pkg)
    }

at the top of `server.R` to ensure they are available to your application (note that said hack assumes a CRAN mirror is set).

Finally, for maximum compatibility, you'll need to use the pure AppleScript version instead of the JXA version unless all your users are on Yosemite or higher.

### Example Shiny Snowfall App

If you're on OS X and have R and the `shiny` package installed, you can try out the sample "Shiny Snowfall"" app by downloading and unzipping this file (you may need to right/option-click->Save As):

<center><a href="http://dds.ec/blog/extra/Shiny Snowfall.zip"><img style="padding-bottom:12px" src="http://dds.ec/blog/images/2014/11/snowicon.png" alt="Shiny Snowfall.zip"/></a></center>

and then running the "Shiny Snowfall" app. (NOTE: You need to have your Security & Privacy settings set to _"Allow apps downloaded from 'Mac App Store and identified developers"_ to run the application or option/right-click "open" on the app icon")

The icon used is from <a href="http://twitter.com/adamwhitcroft">Adam Whitcroft's (@adamwhitcroft)</a> [Climacons](http://adamwhitcroft.com/climacons/) collection.



