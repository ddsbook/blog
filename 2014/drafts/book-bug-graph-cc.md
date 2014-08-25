Title: Book Bug - graph.cc
Date: 2014-08-25 07:55:32
Category: book
Status: draft
Tags: book, bug
Slug: book-bug-graph-cc
Author: Bob Rudis (@hrbrmstr)

Russ McRee (@[holisticinfosec](http://twitter.com/holisticinfosec)) was kind enough to tell us about a bug in the book's code if you decide to play with a more current version of AlienVault's `reputation.data` file with the bad IPs data file provided with the book. The `graph.cc` function makes an errant assumption about how many evil categories will be displayed in the bar charts. `#argh`

Line 612 in `ch04.R` (the code from the downloads on the book's web site) should be changed to:

    :::r
    col.df <- data.frame(Type=names(ftab), Color=myColors[1:length(names(ftab))])

if you're playing along at home and tinkering, as Russ was.

We (like almost everyone) dislike bugs, we truly appreciate and encourage bug reports (so keep'm coming *if* you find them).
