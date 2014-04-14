Title: Creating Video with R: Bouncing Balls
Date: 2014-04-14 00:15:04
Category: R
Tags: R, video
Slug: video-in-R
Author: Jay Jacobs (@jayjacobs)

Well over a year ago, I stumbled across ["Mapping Bike Accidents in R"](http://bayesianbiologist.com/2012/09/14/mapping-bike-accidents-in-r/) and was immediately taken in by the possibilities of creating videos from data.  Since then I've done several videos, mostly just for fun.  We also touched on the topic rather briefly in our book, and I presented these bouncing balls at a local R user group a few meetings back.  I thought it would be good for me to put this post together to share how I create videos with R.

The basic premise for create data-driven videos is exactly the same as the stop motion "claymation" technique.  But rather than use clay and modify it slightly, we will use data to create the individual frames.  In order to do this, you will need R and then some video software to combine the exported images into a video.  I personally use [avconv](http://libav.org/avconv.html) to create the videos, but just search for "stop motion" software and you should come up with something (even iMovie on the mac can create stop motion videos).

Let's start with a little geekiness though and some equations: <br>
x=v<sub>0</sub>t cos(&Theta;) and y=v<sub>0</sub>t sin(&Theta;) - &#189;gt<super>2</super><br>
Recognize those?  Don't worry, they are not necessary to create a video using R, but they fun to play with because they are the formulas for calculating projectile motion.  And see the "t" in there?  That represents time meaning that's what we will focus on for each frame we create.  The rest of the formula is v<sub>0</sub> is the initial velocity of the projectile,  &Theta; is the angle at which it was launched and "g" is the constant for gravity (though we can make gravity whatever we want for this simulation).

Let's start with a simple bouncing ball.  We want to first create a data frame that will track the balls position as it bounces:

```r
  df <- data.frame(v0=100, # initial velocity
                   theta=1.4,  # angle in radians
                   gravity = 5,  # this is just picked for the scale
                   adj=0, # used in the bouncing effect
                   decay= 0.8,  # the "bounciness" of the ball
                   color="steelblue",  # color of the ball
                   cex=2,  # size of the ball
                   t=0,  # time position of this ball
                   xpos=0,  # current x position, will be overwritten
                   ypos=0)  # current y position, will be overwritten
```


Now we want to create a function that will plot the value in that data frame.  We could just loop around this, but having it as a function will allow us to expand on this and reuse the code more easily.


```r
# create a function, accepting in a data frame and counter
snapshot <- function(df, ct, outdir = "bouncing") {
    tval <- 0.3
    # open PNG device
    png(filename = sprintf("%s/bounce%04d.png", outdir, ct), width = 960, height = 540)
    # remove any margin
    par(mar = c(0, 0, 0, 0))
    # create blank canvas
    plot(c(0, 0), type = "n", col = "white", xlim = c(-1, 960), ylim = c(-5, 
        540), yaxt = "n", ann = FALSE, xaxt = "n", bty = "n")
    # add baseline calculate new position using projectile formula
    df$ypos <- df$v0 * df$t * sin(df$theta) - (df$gravity * (df$t^2))
    df$xpos <- df$v0 * df$t * cos(df$theta) + df$adj
    # draw the point(s)
    points(df$xpos, df$ypos, type = "p", cex = df$cex, pch = 16, col = df$color)
    # check for anything bouncing
    for (x in seq(nrow(df))) {
        if (df$ypos[x] < 0) {
            # reset the bounce
            df$adj[x] <- df$xpos[x]
            df$v0[x] <- df$v0[x] * df$decay[x]
            df$t[x] <- -tval
        }
    }
    # if stuck, settle it.
    df$v0 <- ifelse(df$v0 < 0.01, 0, df$v0)
    df$t <- df$t + tval
    dev.off()
    df
}
```


This function will take in a data frame (we will define this next), and updates the "time" then recalculate where the ball should be and creates a simple plot and saves it off.  Let's create 280 frames (PNG files) of a single ball bouncing.


```r
for (i in seq(280)) {
    df <- snapshot(df, i, outdir = "oneball")
    # could put some status messages in here, this may take some time.
}
system("avconv -f image2 -y -i oneball/bounce%04d.png  -r 25 -b 50000000 -s 1920x1080 -an oneball.mp4")
```


That last statement may fail on your system if you don't have "avconv" installed.  Feel free to comment that out and seek out a tool to convert a directory of files into a stop-motion video.  But here is the output from this simple test:

<iframe width="560" height="315" src="//www.youtube.com/embed/Sw6KPW_CjdI" frameborder="0" allowfullscreen></iframe>

But remember that we made the plotting function rather generic so it can take in more than one ball?  What would happen if we created a data frame of a whole lot of balls and ran it through, maybe even adding in one ball at a time to get a "spray" of balls going?  What if we also made them random velocities, angles, color, sizes and bounciness?


```r
num <- 1500
set.seed(1492)  # to be repeatable
df <- data.frame(v0 = rnorm(num, 95, 15), theta = rnorm(num, 1.25, 0.16), gravity = 5.2, 
    adj = 0, decay = rnorm(num, 0.8, 0.05), color = sample(colours(), num, replace = T), 
    cex = rnorm(num, 2, 0.4), t = 0, xpos = 0, ypos = 0)
atime <- seq(2)
realdf <- df[atime, ]
df <- df[-atime, ]
for (i in seq(1100)) {
    realdf <- snapshot(realdf, i, outdir = "multiball")
    if (nrow(df)) {
        realdf <- rbind(realdf, df[atime, ])
        df <- df[-atime, ]
    }
    if (i%%20 == 0) {
        cat("executing on", i, "\n")
    }
}
# now convert these to a video as above
```


And there we have it: 1,500 bouncing balls being flung around in this video:

<iframe width="560" height="315" src="//www.youtube.com/embed/84_PWVMVJmU" frameborder="0" allowfullscreen></iframe>

Enjoy, and happy video making!

