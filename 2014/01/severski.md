Title: Playing with betaPERT
Date: 2014-01-17 22:30:00
Category: R
Tags: simluation
Slug: severski
Author: Jay Jacobs (@jayjacobs)

<style>
.deirfig:hover {
	opacity:0.7;
}
</style>

A few years ago I worked on an excel plugin (to support risk analysis) called [OpenPERT](https://code.google.com/p/openpert/) with Chris Hayes.  The entire point of this plugin was to brig the betaPERT distribution into excel because there is no native support for it.  OpenPERT accomplishes this quite nicely with a single excel call that looks like this:
```
# excel command (min, most likely, max, confidence)
=OpenPERT(1, 5, 20, 4)
```
So if you think some event could cause at a minimum $100 damage or on a bad day a maximum of $10,000 and the most likely loss would be around $2,000, you could model this distribution with:
```
=OpenPERT(100, 2000, 10000, 4)
```
where the confidence represents how "confident" we are in the most likely value being correct (we'll talk more about this below).   The return from this one cell call in excel is a randomly chosen value from the distribution.  But the real power comes from doing a Monte Carlo simulation and generating a lot of values from the distribution and looking at the results.  OpenPERT supports this and allows someone with moderate excel skills to play around with the resulting values.

To be honest, I haven't worked with OpenPERT in over a year, I've moved away from using Excel as a daily tool and been focusing much more on R and python.  So when David Severski asked a question on the [SIRA mailing list](https://www.societyinforisk.org/) today about doing a betaPERT distribution in R, I felt I had to respond.  Rather than keep yapping away, let's look at code:


```r
# use just the mc2d package Tools for Two-Dimensional Monte-Carlo
# Simulations
library(mc2d)
```


This loads up the mc2d package and gives us access to the *pert functions, where * is d, p, q and r and corresponds to the convention within R for distribution functions (do a help(rpert) for the docs).  Let's create a distribution with 10,000 samples and create basic histogram.


```r
# make this repeatable
set.seed(1492)
# do 10,000 estimations with (50,100,500)
est <- rpert(1000, min = 50, mode = 100, max = 500, shape = 4)
summary(est)
```

```
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
##    50.4   103.0   154.0   163.0   210.0   437.0
```


You can see what the output is and you can repeat this if you set the same seed.  But the range of values is between 50 and 437 (doesn't quite reach 500), and the mode isn't easy to pick out from these numbers (it's a continuous distribution).  Let's see what it looks like in a histogram with ggplot.


```r
library(ggplot2)
gg <- ggplot(data.frame(est), aes(x = est))
gg <- gg + geom_histogram(color = "black", fill = "steelblue", binwidth = 15)
gg <- gg + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/severski/hist.svg" target="_blank"><img src="/blog/images/2014/01/severski/hist.svg" style="max-width:100%" class="deirfig"/></a>



Now I've been really digging density plots lately to show distributions.  They smooth things out and make it pretty, so let's create a histogram again (and set the "y" value to a magical "..density..") and overlay a density plot so we can get a feel for what the curve looks like.


```r
gg <- ggplot(data.frame(est), aes(x = est))
gg <- gg + geom_histogram(aes(y = ..density..), color = "black", fill = "white", 
    binwidth = 15)
gg <- gg + geom_density(fill = "steelblue", alpha = 1/3)
gg <- gg + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/severski/density-hist.svg" target="_blank"><img src="/blog/images/2014/01/severski/density-hist.svg" style="max-width:100%" class="deirfig"/></a>


Now the most likely value we set is clear to be around a hundred.

### Confidence value
Now there's that fourth value in the betaPERT call that is used in what's called a "modified PERT" distribution and was developed by David Vose.  It sets the kurtosis (also called the "peakedness" or as we called it the "confidence") of the distribution, as the number gets higher, the distribution will cluster a lot more around the most likely value, with lower values the peak mellows out a bit.  The original betaPERT function was designed with a kurtosis of 4, so some like to think of that as the beginning reference and modify the kurtosis.  Let's see what different values do to the curve, with the rpert function, we pass this in as the shape parameter.


```r
set.seed(1492)
# run 10,000 samples for a confidence of 1, 4, 16 and 64
df <- rbind(data.frame(x = rpert(10000, 0, 200, 500, shape = 1), k = "1"), data.frame(x = rpert(10000, 
    0, 200, 500, shape = 4), k = "4"), data.frame(x = rpert(10000, 0, 200, 500, 
    shape = 16), k = "16"), data.frame(x = rpert(10000, 0, 200, 500, shape = 64), 
    k = "64"))
# now overlay some density plots, set the fill the for the text of 'k'
gg <- ggplot(df, aes(x = x, fill = k))
gg <- gg + geom_density(alpha = 1/4) + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/severski/confidence.svg" target="_blank"><img src="/blog/images/2014/01/severski/confidence.svg" style="max-width:100%" class="deirfig"/></a>


Now we get a visual here of what the values in that confidence mean.  All the code is on the page, so fire up R and try out some different values in the "k" values above and see how they work out!

### One last "fun" thing: ALE
One of the examples I used to give with OpenPERT was to do the classic Annualized Loss Expectancy (ALE) example but with Monte Carlo simulations.  For the uninitiated, ALE attempts to estimate annual loss by multiplying the Annual Rate of Occurrence (ARO) by the Single Loss Expectancy (SLE).  Basically, estimate how many times a bad thing will occur (on average) and how much it will cost each time (on average) and then multiply those.  One of the issues with this is that any given year won't be like any other year and any two events may have different loss with each, so multplying averages like this makes for some odd results... Enter the BetaPERT distribution.

Let's say an event of a lost laptop occurs at a minimum 10 times in a year, at a maximum we may lose up to 60, but most likely around 2 a month, so 24 in a year. This will be the "aro" variable.

For each event, we'd have to replace the laptop and occasionally we have some lost productivity and sometime lost data we have to deal with, so let's say $800 to $10,000, with the most likely around $1,000, but we know there is more variety here, so let's make the confidence a "2" on this.  This will be the "sle" variable.

*Note: I have no idea how many laptops are lost nor how much replacement and recovery costs are, I'm just tossing out some numbers for discussions here.*



```r
set.seed(1492)
# how many simulations?
n <- 10000
# annual rate of occurance
aro <- rpert(n, 10, 24, 60, shape = 4)
# single loss expectency
sle <- rpert(n, 800, 1000, 10000, shape = 2)
```


Now what's great about R is we can simply multiple the two vectors (as variables) together and it does the right thing.
  

```r
# annualized loss = aro * sle
ale <- aro * sle

# That's it!  now let's plot it.  need 'scales' to show commas on x-axis
library(scales)
gg <- ggplot(data.frame(ale), aes(x = ale))
gg <- gg + geom_histogram(aes(y = ..density..), color = "black", fill = "white", 
    binwidth = 10000)
gg <- gg + geom_density(fill = "steelblue", alpha = 1/3)
gg <- gg + scale_x_continuous(labels = comma)
gg <- gg + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/severski/ale.svg" target="_blank"><img src="/blog/images/2014/01/severski/ale.svg" style="max-width:100%" class="deirfig"/></a>


So it looks like most likely lost laptops (assuming we could back up those estimations), would most likely be around $50,000 per year, with years going above that.  The summary command could be useful too.

```r
summary(ale)
```

```
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
##    9780   43200   71700   88400  118000  435000
```


So half of the years the organzation could expect to lose more than $70,000 ($71,700, but round off).  On average 1 out of 4 years they'd lose more than $120,000 (again, just ball-park rounding here).  On the plus side, 1 out of 4 years will be less than $45,000 in losses too.  This type of approach is much better than what most security people are taught:  

> 24 lost laptops x
> $1,000 per laptop
> == $24,000 in losses expected.

Which completely misses the effect of long tails usually seen in incidents like these.  It's those long tails that will cause the "on average" estimates to be misleading.

Now go forth and betaPERT away!
