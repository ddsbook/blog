Title: Introducing the cymruservices R Package
Date: 2015-07-22 17:19
Slug: introducing-the-cymruservices-r-package
Tags: blog, r, rstats, graph, bots
Category: blog
Author: Bob Rudis (@hrbrmstr)

The R world has come a long way since Jay & I wrote [Data-Driven Security](http://dds.ec/amzn). We had to make a conscious decision to stick with R 2.14.0 (R is at version 3.2.1 now) and packages such as knitr and dplyr either didn't exist or were in their infancy.

In Chapter 4, we showed some very basic exploratory data analysis and visualization. One of those examples showed how to do a basic network visualization of the ZeuS botnet nodes, clustered by country of origin.

We turned some of the functions that collected metadata on the ZeuS IP addresses into a new R package - [cymruservices](https://github.com/hrbrmstr/cymruservices) which will be on CRAN soon. If you're new to installing from github, you'll need to install and load the `devtools` package then do a `devtools::install_github("hrbrmstr/cymruservices")` to work with that package until it gets on CRAN. (UPDATE: It's [on CRAN](http://cran.r-project.org/web/packages/cymruservices/index.html).)

We'll re-create the first network visualization from listing 4-12 (page 94) using this package and also modify the code to use `dplyr` functions and visualize the graph with `networkD3`, a super-spiffy `htmlwidget` package. You'll be able to pan & zoom the visualization and hopefully get some inspiration to "Try This At Home".

We've placed the ZeuS botnet data used in the book on our website to make it easier to replicate the example. The code is (unsurprisingly) similar to the listing in the book:

    :::r
    library(igraph)
    library(dplyr)
    library(cymruservices)
    library(networkD3)

    # reading the IP list in a slightly different way
    ips <- grep("^#|^$", readLines("http://dds.ec/data/zeus-book.csv"), 
                value=TRUE, invert=TRUE)

    # get metadata
    origin <- bulk_origin(ips)

    # build graph
    g <- graph.empty()
    g <- g + vertices(ips, group=1)
    g <- g + vertices(origin$cc, group=2)

    # there are other ways to build this edgelist, but I'm keeping with 
    # the example in the book for consistency

    ip_cc_edges <- lapply(ips, function(x) {
      i_cc <- filter(origin, ip==x) %>% .$cc
      lapply(i_cc, function(y) {
        c(x, y)
      })
    })

    g <- g + edges(unlist(ip_cc_edges))

    # simplify graph
    g <- simplify(g, edge.attr.comb=list(weight="sum"))
    g <- delete.vertices(g, which(degree(g) < 1))

    # get ready to make javascript vis
    gd <- get.data.frame(g, what = "edges")

    simpleNetwork(gd, linkDistance=20, charge=-100,
                  nodeColour="#377eb8", textColour="black",
                  fontSize=7, fontFamily="sans-serif",
                  height=600, width=600, zoom=TRUE)

If you have the book, take a look at some of the subtle changes and also see how easy it is to make existing, static R visualizations dynamic.

<center><iframe height=600 width=600 style="width:600;height=600" seamless src="http://dds.ec/frames/201507cymru.html"/></center>

There are a few more interesting functions in that package that will get you tons of useful metadata for your security data science projects. The package should be helpful when creating features for classification or just building relationships between objects that you may never know have exists. Plus, you now have a new visualization toy to play with!
