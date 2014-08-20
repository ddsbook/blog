Title: Open iTerm (OS X) to a Directory from R
Date: 2014-08-20 15:35:40
Category: tools
Tags: r, rstats, iterm, osx
Slug: open-iterm-to-a-directory-from-r
Author: Bob Rudis (@hrbrmstr)

Sometimes you need to get to a command prompt from R, whether it's to wrangle `git` on the command line or do some package work. RStudio provides ways to do this from menus and hotkeys, but on OS X it sticks you in `Terminal.app`. I'm an [iTerm](http://iterm2.com/) user&mdash;and, I *really* prefer being in that app vs the one Apple ships&mdash;so, I wrote a tiny function that will drop you into either the current working directory or a path you specify.

    iterm <- function(directory=getwd()) {
  
      system(paste("osascript -e 'activate application \"iTerm\"' ",
                   " -e 'tell application \"System Events\" to keystroke \"t\" using command down' ",
                   sprintf(" -e 'tell application \"iTerm\" to tell session -1 of current terminal to write text \"cd %s\"'", directory)))
  
    }
    
It issues a three line AppleScript telling iTerm to

- activate (or launch)
- open a new tab
- `cd` to the desired location

Nothing earth shattering, but it saves a few mouse clicks and keystrokes and keeps me in the app I want to be in. It should be pretty straightforward to modify this for other operating systems.