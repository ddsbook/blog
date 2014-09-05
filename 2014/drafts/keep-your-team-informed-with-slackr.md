Title: Keep your team informed with "slackr"
Date: 2014-09-05 07:07:52
Category: blog
Status: draft
Tags: blog
Slug: keep-your-team-informed-with-slackr
Author: Bob Rudis (@hrbrmstr)

[Karl Broman](http://twitter.com/kwbroman) did a spiffy job [summarizing a good number of the options](http://kbroman.wordpress.com/2014/09/03/notifications-from-r/) availble to R folk if they want to get notifications from R. You can also generate [OS X notifications](http://rud.is/b/2013/09/12/send-mac-os-notifications-from-r/) as well. If you're using [Slack](https://slack.com/r/02j411cy-02jchz0q) for team coordination and communications, you've got a new option - [slackr](http://github.com/hrbrmstr/slackr) that also enables you go a bit deeper than just notifications, letting you push R output to the service for sharing results or observations.

### What is Slack?

Slack (@[SlackHQ](http://titter.com/SlackHQ)) is a cloud-hosted, team messaging platform that lets you setup public & privte internal channels for various types of communications, incuding markdown, text, pictures, video, links and more. They also offer connectivity with many outside services (e.g. github, twitter, etc.). The service is super-simple to setup, and there are desktop and mobile applications for most platforms (as well as the web interface). It has the utility of e-mail, twitter and skype (and more) combined, and their [API](http://api.slack.com/) makes it possible to create your own integrations.

While their full API affords more flexibility, they have simple "webhook"-type integrations that are more lightweight and make quick work out connecting to Slack. The `slackr` package takes advantage of the webook API to connect R with the service. To use it, you'll first need to [signup for the service](https://slack.com/r/02j411cy-02jchz0q) and get your teammates to join and then setup the webhook integration.

### Why `slackr`?

If you've ever used a plaintext messaging tool (e.g. Skype) to try to share R code snippets or output, you know the drill: select what was sent to you; copy, then paste into a text editor so it's actually readable. The `slackr` package eliminates those steps by letting you execute one function - `slackr()` - and send any R output/expression to any Slack team channel or team member. Here's an example, using the code from the `lm` `stats` package function example code (hit up `?lm` in R to see that directly):

    :::r
    # setup the slackr API. this example assumes a .slackr config file in ~/
    slackrSetup() 
    
    # run the lm() example
    ctl <- c(4.17,5.58,5.18,6.11,4.50,4.61,5.17,4.53,5.33,5.14)
    trt <- c(4.81,4.17,4.41,3.59,5.87,3.83,6.03,4.89,4.32,4.69)
    group <- gl(2, 10, 20, labels = c("Ctl","Trt"))
    weight <- c(ctl, trt)
    lm.D9 <- lm(weight ~ group)
    lm.D90 <- lm(weight ~ group - 1) # omitting intercept
    
    # share the results with Jay
    slackr(anova(lm.D9), summary(lm.D90), channel="@jayjacobs")

Here's what will be seen in the slack channel:

![img](http://datadrivensecurity.info/blog/images/2014/09/slack01.png)

The `slackr()` function can also be setup to do trivial notifications (and the various Slack apps and integrations can notify you anywhere in an out of slack, if that's your cup of tea):

    :::r
    performSomeLongClassifictationTask()
    
    # notify me directly
    slackr("Classification complete", channel="@hrbrmstr")
    
    # or notify the default channel
    slackr("Classification complete")

![img](http://datadrivensecurity.info/blog/images/2014/09/slack02.png)

With `slackrSetup()`, you can choose the default channel and username, as well as select the icon being used (overriding the default one during the initial webhook setup). The config file (mentioned earlier) is pretty straightforward:

    token: YOUR_SLACK_API_TOKEN
    channel: #general
    username: slackr
    icon_emoji:
    incoming_webhook_url: https://YOURTEAM.slack.com/services/hooks/incoming-webhook?

and definitely beats passing all those in as parameters (and, doesn't have to live in `~/.slackr` if you want to use an alternate location or have multiple profiles for multiple teams).

The webhook API is text/rich-text-only, but the full API lets you send anything. For that, full OAuth setup is required, and since it's super-simple to just drag graphics from an RStudio window to Slack the extra functionality hasn't made it to the `slackr` project `TODO` list _yet_, but I can defintely see a `ggslack()` or even a `dev.slack()` graphics device (ala `png()`) function or two making their way to the package in the not-too-distant future.

### How to get `slackr`

The `slackr` package is [up on github](http://github.com/hrbrmstr/slackr) and _may_ make it to CRAN next week. Over the coming weeks we'll probably add the ability to consume output _from_ slack channels and definitely welcome any issues, comments or feature requests.

