Title: Installing dplyr 0.3 on Mac OS X (Mavericks)
Date: 2014-09-25 18:10:36
Category: tools
Tags: r, rstats, dplyr
Slug: installing-dplyr-0.3-on-mac-os-x
Author: Bob Rudis (@hrbrmstr)

>**UPDATE** Per the author, a `devtools::install_github("hadley/devtools")` should take care of everything you need prior to installing the latest `dplyr` (though I did not have postgres libs installed and suspect that might still be needed).

The R [dplyr](http://github.com/hadley/dplyr) package just turned `0.3` and to get it working in my development environment (OS X Mavericks) I had to do the following:

- `brew install postgresql` _(you are using [homebrew](http://brew.sh/) on Macs, right?)_
- `install.packages("DBI", type="source")`
- `install.packages("RPostgreSQL", type="source")`
- `devtools::install_github("rstudio/rmarkdown")`
- `devtools::install_github("hadley/lazyeval")`
- `devtools::install_github("hadley/dplyr")`

Such is the way of things when living on the cutting edge of the Hadleyverse.

Why go through the trouble of using the newest version of `dplyr`? Take a look at some of the new capabilities available:
 
* `between()` vector function efficiently determines if numeric values fall
  in a range, and is translated to special form for SQL (#503).

* `count()` makes it even easier to do (weighted) counts (#358).

* `data_frame()` by @kevinushey is a nicer way of creating data frames.
  It never coerces column types (no more `stringsAsFactors = FALSE`!),
  never munges column names, and never adds row names. You can use previously 
  defined columns to compute new columns (#376).

* `distinct()` returns distinct (unique) rows of a tbl (#97). Supply
  additional variables to return the first row for each unique combination
  of variables.

* Set operations, `intersect()`, `union()` and `setdiff()` now have methods 
  for data frames, data tables and SQL database tables (#93). They pass their 
  arguments down to the base functions, which will ensure they raise errors if 
  you pass in two many arguments.

* Joins (e.g. `left_join()`, `inner_join()`, `semi_join()`, `anti_join()`)
  now allow you to join on different variables in `x` and `y` tables by
  supplying a named vector to `by`. For example, `by = c("a" = "b")` joins
  `x.a` to `y.b`.

* `n_groups()` function tells you how many groups in a tbl. It returns
  1 for ungrouped data. (#477)

* `transmute()` works like `mutate()` but drops all variables that you didn't
  explicitly refer to (#302).

* `rename()` makes it easy to rename variables - it works similarly to 
  `select()` but it preserves columns that you didn't otherwise touch.

* `slice()` allows you to selecting rows by position (#226). It includes
  positive integers, drops negative integers and you can use expression like
  `n()`.
  
Also, the `lazyeval` package looks pretty interesting.