Title: Shell Script to Build 'Shiny Apps' from Github Gists
Date: 2014-12-02 16:18:20
Category: blog
Tags: blog, R, rstats
Slug: shell-script-to-build-'shiny-apps'-from-github-gists
Author: Bob Rudis (@hrbrmstr)

Since the [previous post](http://datadrivensecurity.info/blog/posts/2014/Nov/os-x-yosemite-r-apps/) was fairly popular, I went ahead and built a small [shell script](https://gist.github.com/hrbrmstr/90d7f303fccca46ef846) (also below) to ease the process of building the OS X Shiny-gist application.

After copying the script to a place you can run it from in your `PATH` and executing a "`chmod a+x shinyapp.sh`" (or whatever you named it), all you have to do is enter the GitHub Gist ID and the desired app name. In the case of my example "snowfall" app, one could do something like:

    $ shinyapp 95ec24c1b0cb433a76a5 "Shiny Snowfall"

which would then build the `Shiny Snowfall.app` executable.

You can find the GitHub Gist ID as the last part of the gist URL. For example, the "Shiny Snowfall" app is at URL `https://gist.github.com/hrbrmstr/95ec24c1b0cb433a76a5`, so the gist ID I'd use would be "`95ec24c1b0cb433a76a5`".

The script also takes in two optional parameters. The first (`-i`) lets you specify an [icns file](http://en.wikipedia.org/wiki/Apple_Icon_Image_format) which will be used in place of the generic AppleScript icon image. Apple provides a free utility in their [Graphics Tools for Xcode](https://developer.apple.com/downloads/index.action) bundle which makes creating icons as simple as drag and drop. 

The second (`-d`) lets you specify your Apple Mac OS Developer ID (if you have one) that you want to use to sign the app. Signing the app makes it more easily runnable by users provided they have their security restrictions setup properly You can find out more about code-signing [on Apple's site](https://developer.apple.com/library/mac/documentation/Security/Conceptual/CodeSigningGuide/Introduction/Introduction.html).

To re-create the example "Shiny Snowfall" app just do:

    $ shinyapp -i snowcloud.icns \
               -d 'Bob Rudis (CBY22P58G8)' \
               95ec24c1b0cb433a76a5 'Shiny Snowfall'

Hopefully this makes the process a bit easier for folks who want to deliver Shiny apps this way on Mac OS. A future post will show how to make a Mac OS X Shiny app from a local `ui.R`, `server.R` and any associated support/data files. Since the file is a gist, please submit all issues, enhancements and bugs as comments to this post.

### shinyapp.sh Source Code:
<script src="https://gist.github.com/hrbrmstr/90d7f303fccca46ef846.js"></script>