Title: Controlling RStudio Python Child Processes
Date: 2014-06-23 14:00:00
Category: blog
Tags: r, rstats, python, rstudio
Slug: controlling-rstudio-python-child-processes
Author: Bob Rudis (@hrbrmstr)

I've been using RStudio's new ability to [run Python scripts](http://www.rstudio.com/products/rstudio/download/preview-release-notes/) since I often need to analyze/process data in R but then run web services with said data in Python (usually via [Flask](http://flask.pocoo.org/)). I'd rather live with the foibles of the RStudio editor than use a separate one and run code on the command line.

>Everyting below is for OS X, but I suspect holds true for Linux and can be adapted pretty readily for Windows via PowerShell

###Running the "Right" Python

The first "gotcha" was running the version of Python I wanted to. By default, it will use the system Python and I rarely use that since I'd rather have [Homebrew](http://brew.sh/) manage my config. My Homebrew Python binary is in `/usr/local/bin` and all that needs to be done in R to make it look there for the `system()` call it uses to run Python scripts is to add:

    Sys.setenv(PATH = paste("/usr/local/bin", Sys.getenv("PATH"), sep=":"))

to your `.Rprofile`. There are other ways to do this, but I prefer this method. Feel free to share yours in the comments.

###Killing Python

Running a long Python job from RStudio, or running something like a Flask app from within RStudio means a having blocked `rsession` until the child process exits. That's fine if the process *is* going to exit, but tasks like a Flask app will just keep running and the RStudio "stop" icon won't just kill the child process it will try to terminate the entire R session (`#notcool`). You can kill off the Python process by adding the following `bash` function to your shell startup script:

    rpspy() { pgrep rsession | while read ppid ; do pgrep -lP $ppid ; done }

run it:

    rpspy
    24451 Python

then do a normal `kill 24451` to stop the job. I was going to combine the search & destroy operations it into one function, but sometimes I just want to have the `PID` at hand vs kill it (and there's no need for two shell functions when it's so little typing to kill the program). You can add such a feature as a function option if you desire.

While you *could* just do a `pkill python`, I have other jobs running that I don't want killed, so the `rpspy` function will find the Python binary with a parent process of RStudio's `rsession` and just kill it.

The prospect of having RStudio as a completely unified data science developent environemnt is pretty exciting and I'm looking for further tool integration and features from the RStudio team.