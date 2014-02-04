Title: ripal - Password Dump Analysis in R
Date: 2014-02-040 10:00:00
Category: analysis
Tags: R, passwords
Slug: ripal
Author: Bob Rudis (@hrbrmstr)

The [`pipal`](http://www.digininja.org/projects/pipal.php) utility is one of the standard, "go-to" tools when analyzing cracked password dumps. It's a command-line program written in Ruby and I thought it would be interesting to port the base functionality to R and then build upon that base over time (R has some really handy advanced textual analysis tools).

This first relase duplicates most of `pipal`'s functionality and will hopefully serve as an extended introduction to R for those just approaching the language. Our [book](http://amzn.to/ddsec) provides a solid, basic introduction to R, but this example incorporates more complex data structures and packages and some additional `*apply()` function machinations that we didn't really cover in detail in the text (due to lack of time/space).

We'll start by loading two packages for assistance. The `data.table` package gives us the wicked-fast `fread()` function and `stringr` makes working with strings a bit less messy. 

	:::r
	library(data.table)
	library(stringr)

First, we'll read in a sample file (the [infamous "phpbb" hack dump](http://sla.ckers.org/forum/read.php?3,26387)). The `fread()` function performs just like the built-in `read.delim()` function but operates much faster and produces a `data.table`, which is an optimized `data.frame`.

> **NOTE**: there are some multi-byte characters towards the end of the list so make sure to convert the file to UTF-8 before trying this at home:

	:::r
	passwords <- fread("phpbb.txt")
	setnames(passwords ,"V1", "orig") # decent label for the column
	tot <- nrow(passwords) # we compute many ratios with this

We can get the "top 10" passwords pretty easily in R using the `summary()` function on a `factor()` (a function that creates a special enumerated reference type of a set of input values) created from the original passwords, but the `phpbb` file was pre-`uniq`'d so it isn't very interesting in this case:


	:::r
	top.10 <- factor(passwords$orig)
	summary(top.10, maxsum=11)


	##      __rob_rao        _1phpbb       _7114461         _87698        _amber_ 
	##              1              1              1              1              1 
	##       _apr1l1a      _babytje_          _bean      _blubber_ _disablemenow_ 
	##              1              1              1              1              1 
	##        (Other) 
	##         184379

But, we want a *tad* nicer output, so we need to transform the data just a bit to build a `data.frame` and also include the percentages:

	:::r
	top.10 <- as.data.frame(head(sort(table(passwords$orig), decreasing=TRUE),10))
	top.10$Password <- rownames(top.10)
	rownames(top.10) <- NULL
	top.10 <- top.10[,c(2,1)]
	colnames(top.10) <- c("Password","Count")
	top.10$Percent <- sprintf("%3.2f%%", ((top.10$Count / tot) * 100))
	print(top.10, row.names=FALSE)

	##        Password Count Percent
	##       __rob_rao     1   0.00%
	##         _1phpbb     1   0.00%
	##        _7114461     1   0.00%
	##          _87698     1   0.00%
	##         _amber_     1   0.00%
	##        _apr1l1a     1   0.00%
	##       _babytje_     1   0.00%
	##           _bean     1   0.00%
	##       _blubber_     1   0.00%
	##  _disablemenow_     1   0.00%

Now, we check for commonality among "base" words, which (according to `pipal`) are *"words with any non-alpha character stripped from the start and end."* The `gsub()` function does most of the heavy lifting here, taking in a regex and removing it from the original strings. The `gsub()` function is *vectorized* so we can pass in the entire `data.table` column and it will perform the substitution on each element without a loop (the same is true for `tolower()`).

	:::r
	passwords$basewords <- gsub("^[^a-z]*", "", passwords$orig, ignore.case=TRUE)
	passwords$basewords <- gsub("[^a-z]*$", "", passwords$basewords, ignore.case=TRUE)
	passwords$basewords <- tolower(passwords$basewords)

We can then use the same `factor()`/`summary()` combination to get the statistics we're looking for, and filter the `data.frame` on only basewords that have more than three characters.

	:::r
	basewords <- factor(passwords[nchar(passwords$basewords)>3,]$basewords)
	summary(basewords, maxsum=11)

	##    phpbb password   dragon     pass     mike     blue     test   qwerty 
	##      332       89       76       70       69       67       66       59 
	##     alex    alpha  (Other) 
	##       58       53   149917

And, again we'll make a nice table:

	:::r
	basewords <- as.data.frame(head(sort(table(passwords[nchar(passwords$basewords)>3,]$basewords), decreasing=TRUE),10))
	basewords$Password <- rownames(basewords)
	rownames(basewords) <- NULL
	basewords <- basewords[,c(2,1)]
	colnames(basewords) <- c("Password","Count")
	basewords$Percent <- sprintf("%3.2f%%", ((basewords$Count / tot) * 100))
	print(basewords, row.names=FALSE)

    ##  Password Count Percent
    ##     phpbb   332   0.18%
    ##  password    89   0.05%
    ##    dragon    76   0.04%
    ##      pass    70   0.04%
    ##      mike    69   0.04%
    ##      blue    67   0.04%
    ##      test    66   0.04%
    ##    qwerty    59   0.03%
    ##      alex    58   0.03%
    ##     alpha    53   0.03%

To get a breakdown by overall password length, we run `nchar()` over the original password column and create a new column that just has the length of each passwors. Then, we build a contingency table from that new column and show it first by length then create an ordered factor so we can view it also by frequency.

	:::r
    passwords$len <- nchar(passwords$orig)
    # length ordered
	summary(factor(passwords$len))
	by.length <- as.data.frame(table(passwords$len))
	colnames(by.length) <- c("Password","Count")
	by.length$Percent <- sprintf("%3.2f%%", ((by.length$Count / tot) * 100))
	print(by.length, row.names=FALSE)
	# freq ordered
	length.tab <- table(passwords$len) # contingency table
	summary(factor(passwords$len, 
	               levels = names(length.tab[order(length.tab, decreasing = TRUE)])))
	by.freq <- as.data.frame(table(factor(passwords$len, 
	                        levels = names(length.tab[order(length.tab, decreasing = TRUE)]))))
	colnames(by.freq) <- c("Password","Count")
	by.freq$Percent <- sprintf("%3.2f%%", ((by.freq$Count / tot) * 100))
	print(by.freq, row.names=FALSE)

	##  Password Count Percent
	##         8 55338  30.01%
	##         6 42070  22.82%
	##         7 32731  17.75%
	##         9 19188  10.41%
	##        10 11896   6.45%
	##         5  8198   4.45%
	##        11  4933   2.68%
	##         4  4598   2.49%
	##        12  2505   1.36%
	##        13  1018   0.55%
	##         3   776   0.42%
	##        14   515   0.28%
	##        15   232   0.13%
	##         2   137   0.07%
	##        16   125   0.07%
	##        17    36   0.02%
	##         1    32   0.02%
	##        18    27   0.01%
	##        19     9   0.00%
	##        20     8   0.00%
	##        21     5   0.00%
	##        23     3   0.00%
	##        32     3   0.00%
	##        22     2   0.00%
	##        27     2   0.00%
	##        25     1   0.00%
	##        28     1   0.00%

	plot(length.tab, col="steelblue", main="Password Length Frequency", xlab="Password Length", ylab="Count")

<center><img src="/blog/images/2014/02/ripal01.svg" width="630" style="max-width:100%"/></center>

Next we break down the composition a bit more, seeing how many had 1-6 characters, 1-8, chars and >9 chars. This is a basic `data.frame` filtering function (and we end up just counting the resulting rows).

	:::r
	one.to.six <- nrow(passwords[passwords$len>=1 & passwords$len<=6,])
	one.to.eight <- nrow(passwords[passwords$len>=1 & passwords$len<=8,])
	nine.plus <- nrow(passwords[passwords$len>8,])

	print(sprintf("One to six characters = %d, (%3.3f%%)", one.to.six, 100*(one.to.six/tot)))
	print(sprintf("One to eight characters = %d, (%3.3f%%)", one.to.eight, 100*(one.to.eight/tot)))
	print(sprintf("More than eight characters = %d, (%3.3f%%)", nine.plus, 100*(nine.plus/tot)))

	One to six characters = 55811, (30.268%)
	One to eight characters = 143880, (78.031%)
	More than eight characters = 40509, (21.969%)

To examine other bits of alpha-numeric compositon, we use use `grepl()` which will return `TRUE` if a regex is found and rely on a sneaky bit of functionality by the `sum()` function where it will ignore `FALSE` values and sum up the `TRUE` ones in a vector (which is returned by `grepl()`).

	:::r
	only.lower.alpha <- sum(grepl("^[a-z]+$",passwords$orig))
	only.upper.alpha <- sum(grepl("^[A-Z]+$",passwords$orig))
	only.alpha <- only.lower.alpha + only.upper.alpha
	only.numeric <- sum(grepl("^[0-9]+$",passwords$orig))

	first.cap.last.sym <- sum(grepl("^[A-Z].*[[:punct:]]$",passwords$orig))
	first.cap.last.num <- sum(grepl("^[A-Z].*[0-9]$",passwords$orig))

	print(sprintf("Only lowercase alpha = %d, (%3.3f%%)", only.lower.alpha, 100*(only.lower.alpha/tot)))
	print(sprintf("Only uppercase alpha = %d, (%3.3f%%)", only.upper.alpha, 100*(only.upper.alpha/tot)))
	print(sprintf("Only alpha = %d, (%3.3f%%)", only.alpha, 100*(only.alpha/tot)))
	print(sprintf("Only numeric = %d, (%3.3f%%)", only.numeric, 100*(only.numeric/tot)))
	print(sprintf("First capital last symbol = %d, (%3.3f%%)", first.cap.last.sym, 100*(first.cap.last.sym/tot)))
	print(sprintf("First capital last number = %d, (%3.3f%%)", first.cap.last.num, 100*(first.cap.last.num/tot)))

	Only lowercase alpha = 76041, (41.239%)
	Only uppercase alpha = 1706, (0.925%)
	Only alpha = 77747, (42.165%)
	Only numeric = 20728, (11.241%)

	First capital last symbol = 225, (0.122%)
	First capital last number = 4749, (2.576%)

We move next to comparing against password lists. The `pipal` tool let you pipe in lists (which this will eventually let you do) but we can start with the "25 worst passwords on the internet". We'll use the same basic pattern for all of these list-based comparisons:

- Put the list of words into a vector
- Create a "list of lists"&mdash;basically a nested data structure&mdash;that holds the search term and the count of times it appeared in the password dump.
- Output the search term, count and percentage

We'll be using `sapply()` to execute a new function, `makeCounts()`, which will do the grepping and building of the nested data structure, then use another new function, `printCounts()`, which will generate a familiar table output.

	:::r
	makeCounts <- function(x) {
	  return(x=list("count"=sum(grepl(x, passwords$orig, ignore.case=TRUE))))  
	}

	printCounts <- function(ct) {
	  tmp <- data.frame(Term=names(ct), Count=as.numeric(unlist(ct)))
	  tmp$Percent <- sprintf("%3.2f%%", ((tmp$Count / tot) * 100))
	  print(tmp[order(-tmp$Count),], row.names=FALSE)
	}

	# setup the "worst passwords" vector
	worst.pass <- c("password", "123456", "12345678", "qwerty", "abc123", 
	                "monkey", "1234567", "letmein", "trustno1", "dragon", 
	                "baseball", "111111", "iloveyou", "master", "sunshine", 
	                "ashley", "bailey", "passw0rd", "shadow", "123123", 
	                "654321", "superman", "qazwsx", "michael", "football")

	worst.ct <- sapply(worst.pass, makeCounts, simplify=FALSE)
	printCounts(worst.ct)

	##      Term Count Percent
	##    master   229   0.12%
	##    123456   208   0.11%
	##    dragon   185   0.10%
	##  password   164   0.09%
	##    monkey   118   0.06%
	##    shadow   105   0.06%
	##    qwerty    95   0.05%
	##   1234567    72   0.04%
	##  12345678    47   0.03%
	##   letmein    44   0.02%
	##   michael    39   0.02%
	##    123123    27   0.01%
	##    abc123    26   0.01%
	##    654321    26   0.01%
	##  superman    18   0.01%
	##    qazwsx    17   0.01%
	##    111111    15   0.01%
	##    ashley    15   0.01%
	##    bailey    15   0.01%
	##  baseball    13   0.01%
	##  sunshine    13   0.01%
	##  football    12   0.01%
	##  iloveyou    11   0.01%
	##  passw0rd     9   0.00%
	##  trustno1     7   0.00%

Now, we'll do the same for weekdays (full & abbreviated), month names (full & abbreviated) and years (1975-2030). This will demonstrate some of R's built in arrays and sequence generation capabilities.

	:::r
	weekdays.full <- c("sunday", "monday", "tuesday", "wednesday",
	                   "thursday", "friday", "saturday")
	weekdays.abbrev <- c("sun", "mon", "tue", "wed", "thu", "fri", "sat")

	months.full <- tolower(month.name)
	months.abbrev <- tolower(month.abb)

	yrs <- as.character(1975:2030)

	printCounts(sapply(weekdays.full, makeCounts, simplify=FALSE))

    ##       Term Count Percent
    ##     monday    12   0.01%
    ##     friday    11   0.01%
    ##     sunday     5   0.00%
    ##   thursday     3   0.00%
    ##    tuesday     2   0.00%
    ##  wednesday     1   0.00%
    ##   saturday     1   0.00%

	printCounts(sapply(weekdays.abbrev, makeCounts, simplify=FALSE))

    ##  Term Count Percent
    ##   mon   954   0.52%
    ##   sun   299   0.16%
    ##   sat   187   0.10%
    ##   thu   184   0.10%
    ##   fri   169   0.09%
    ##   wed    69   0.04%
    ##   tue    16   0.01%

	printCounts(sapply(months.full, makeCounts, simplify=FALSE))

    ##       Term Count Percent
    ##        may   171   0.09%
    ##       june    56   0.03%
    ##      april    48   0.03%
    ##       july    27   0.01%
    ##      march    23   0.01%
    ##     august    22   0.01%
    ##    october    15   0.01%
    ##    january     8   0.00%
    ##   november     7   0.00%
    ##   december     6   0.00%
    ##   february     3   0.00%
    ##  september     3   0.00%

	printCounts(sapply(months.abbrev, makeCounts, simplify=FALSE))

    ##  Term Count Percent
    ##   mar  1406   0.76%
    ##   jan   341   0.18%
    ##   jun   190   0.10%
    ##   may   171   0.09%
    ##   nov   161   0.09%
    ##   jul   158   0.09%
    ##   dec   120   0.07%
    ##   sep   118   0.06%
    ##   apr   108   0.06%
    ##   aug    83   0.05%
    ##   oct    69   0.04%
    ##   feb    42   0.02%

	printCounts(sapply(yrs, makeCounts, simplify=FALSE))

    ##  Term Count Percent
    ##  2000   428   0.23%
    ##  2002   268   0.15%
    ##  2001   236   0.13%
    ##  2003   235   0.13%
    ##  2005   199   0.11%
    ##  1987   183   0.10%
    ##  2004   180   0.10%
    ##  1984   176   0.10%
    ##  1985   171   0.09%
    ##  1983   168   0.09%
    ##  1988   165   0.09%
    ##  1986   152   0.08%
    ##  2006   145   0.08%
    ##  1979   142   0.08%
    ##  1982   142   0.08%
    ##  1981   139   0.08%
    ##  1989   139   0.08%
    ##  1980   130   0.07%
    ##  1990   127   0.07%
    ##  1978   118   0.06%
    ##  1991   115   0.06%
    ##  1977    96   0.05%
    ##  2007    91   0.05%
    ##  1975    82   0.04%
    ##  1992    82   0.04%
    ##  1976    80   0.04%
    ##  1999    79   0.04%
    ##  2010    57   0.03%
    ##  1997    56   0.03%
    ##  1993    49   0.03%
    ##  1998    49   0.03%
    ##  2011    48   0.03%
    ##  2020    47   0.03%
    ##  2012    45   0.02%
    ##  1994    41   0.02%
    ##  2021    39   0.02%
    ##  1996    38   0.02%
    ##  2030    32   0.02%
    ##  2008    30   0.02%
    ##  2013    27   0.01%
    ##  2022    27   0.01%
    ##  2009    26   0.01%
    ##  2019    26   0.01%
    ##  1995    25   0.01%
    ##  2028    19   0.01%
    ##  2025    18   0.01%
    ##  2027    18   0.01%
    ##  2017    17   0.01%
    ##  2015    16   0.01%
    ##  2018    16   0.01%
    ##  2023    15   0.01%
    ##  2024    15   0.01%
    ##  2026    13   0.01%
    ##  2016    12   0.01%
    ##  2014     9   0.00%
    ##  2029     8   0.00%

As `pipal` points out, *"the common assumption is that when people are forced to use passwords with numbers, their general response is to add a single digit on the end. Looking at this next set of stats, in this list people actually prefered to add two digits onto the end. The assumption that the last digit will be "1" does however hold true."*

We'll rely on `grepl()` and standard regex for this part of the analysis:

	:::r
	singles.on.end <- sum(grepl("[^0-9]+([0-9]{1})$", passwords$orig))
	doubles.on.end <- sum(grepl("[^0-9]+([0-9]{2})$", passwords$orig))
	triples.on.end <- sum(grepl("[^0-9]+([0-9]{3})$", passwords$orig))

	print(sprintf("Single digit on the end = %d, (%3.3f%%)", singles.on.end, 100*(singles.on.end/tot)))
	print(sprintf("Two digits on the end = %d, (%3.3f%%)", doubles.on.end, 100*(doubles.on.end/tot)))
	print(sprintf("Three digits on the end = %d, (%3.3f%%)", doubles.on.end, 100*(doubles.on.end/tot)))

	Single digit on the end = 14447, (7.835%)
	Two digits on the end = 18113, (9.823%)
	Three digits on the end = 18113, (9.823%)

	passwords$last.num <- as.numeric(str_extract(passwords$orig, "[0-9]$"))
	last.num.factor <- factor(na.omit(passwords$last.num))
	plot(last.num.factor, col="steelblue", main="Count By Last digit")
	summary(last.num.factor)

<center><img src="/blog/images/2014/02/ripal02.svg" width="630" style="max-width:100%"/></center>

    ##     0     1     2     3     4     5     6     7     8     9 
    ##  7753 13572  8735  9313  6279  6409  5992  6472  5726  6728

	last.num <- as.data.frame(table(last.num.factor))
	colnames(last.num) <- c("Digit","Count")
	last.num$Percent <- sprintf("%3.2f%%", ((last.num$Count / tot) * 100))
	print(last.num, row.names=FALSE)

    ##  Digit Count Percent
    ##      0  7753   4.20%
    ##      1 13572   7.36%
    ##      2  8735   4.74%
    ##      3  9313   5.05%
    ##      4  6279   3.41%
    ##      5  6409   3.48%
    ##      6  5992   3.25%
    ##      7  6472   3.51%
    ##      8  5726   3.11%
    ##      9  6728   3.65%

We'll conclude with a final digit-based analysis, this time taking a look at commonality by last n (1-5) digits used. We'll leave the tabluar output as an exercise for the reader (rest assured, it'll be there in the final version).

	:::r
	passwords$last.2 <- str_extract(passwords$orig, "[0-9]{2}$")
	passwords$last.3 <- str_extract(passwords$orig, "[0-9]{3}$")
	passwords$last.4 <- str_extract(passwords$orig, "[0-9]{4}$")
	passwords$last.5 <- str_extract(passwords$orig, "[0-9]{5}$")

	print(tail(sort(table(na.omit(passwords$last.2))),10))

    ##   88   69   13   21   99   11   12   01   00   23 
    ## 1028 1052 1095 1150 1341 1620 1817 1992 2185 3027

	print(tail(sort(table(na.omit(passwords$last.3))),10))

    ##  111  002  101  321  666  001  007  234  000  123 
    ##  261  274  284  286  398  430  449  477  708 2164

    print(tail(sort(table(na.omit(passwords$last.4))),10))

    ## 1985 1988 1987 2004 2005 2001 2003 2002 2000 1234 
    ##  132  133  141  153  166  181  202  215  377  424

	print(tail(sort(table(na.omit(passwords$last.5))),10))

    ## 77777 23123 21985 11988 00000 21984 11111 54321 23456 12345 
    ##    13    14    15    16    18    21    23    25    68   110

You can follow the development of `ripal` over on [github](https://github.com/ddsbook/ripal) and stay tuned to the DDSec Blog as we incorporate some additional analytics and build a Shiny app around the tool. Use the comments to request features or enhancements and file issues over at github if things seem wonky.
