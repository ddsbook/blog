Title: Update to resolv (0.1.2) + valgrind and R + Parallel DNS Requests with Revolution R's 'foreach' and `doParallel`
Date: 2014-08-15 10:15:30
Category: tools
Tags: r, rstats, valgrind, rcpp, dns
Slug: update-to-resolve-valgrind-and-r
Author: Bob Rudis (@hrbrmstr)

Thanks to a blog comment by [@arj](http://twitter.com/arj), I finally ran at least one of the new `Rcpp`-based through [`valgrind`](http://valgrind.org/) ([`resolv`](https://github.com/hrbrmstr/resolv)) and, sure enough there were a few memory leaks which are now fixed. However, I first ran `valgind` with a simple test `R` script that just did `library(stats)` to get a baseline (and dust off some very rusty `valgrind` memories). After running that through:

    R --vanilla -d "valgrind --tool=memcheck --track-origins=yes" --vanilla < valgrindtest.R

these are the results from an Ubuntu system:

    ==24555==
    ==24555== HEAP SUMMARY:
    ==24555==     in use at exit: 17,713,425 bytes in 7,077 blocks
    ==24555==   total heap usage: 21,258 allocs, 14,181 frees, 30,580,692 bytes allocated
    ==24555==
    ==24555== LEAK SUMMARY:
    ==24555==    definitely lost: 80 bytes in 2 blocks
    ==24555==    indirectly lost: 240 bytes in 20 blocks
    ==24555==      possibly lost: 0 bytes in 0 blocks
    ==24555==    still reachable: 17,713,105 bytes in 7,055 blocks
    ==24555==         suppressed: 0 bytes in 0 blocks
    ==24555== Rerun with --leak-check=full to see details of leaked memory
    ==24555==
    ==24555== For counts of detected and suppressed errors, rerun with: -v
    ==24555== ERROR SUMMARY: 18 errors from 18 contexts (suppressed: 0 from 0)

and, this is from OS X:

    ==77581==
    ==77581== HEAP SUMMARY:
    ==77581==     in use at exit: 30,077,961 bytes in 14,565 blocks
    ==77581==   total heap usage: 32,198 allocs, 17,633 frees, 49,527,117 bytes allocated
    ==77581==
    ==77581== LEAK SUMMARY:
    ==77581==    definitely lost: 18 bytes in 1 blocks
    ==77581==    indirectly lost: 0 bytes in 0 blocks
    ==77581==      possibly lost: 3,704 bytes in 77 blocks
    ==77581==    still reachable: 28,814,406 bytes in 13,624 blocks
    ==77581==         suppressed: 1,259,833 bytes in 863 blocks
    ==77581== Rerun with --leak-check=full to see details of leaked memory
    ==77581==
    ==77581== For counts of detected and suppressed errors, rerun with: -v
    ==77581== ERROR SUMMARY: 1718 errors from 213 contexts (suppressed: 906524 from 939)

(both for R 3.1.1)

I know R is a complex piece of software with many hands and some excellent (perhaps, draconian :-) review processes, so the leaks actually surprised me. I'm not conerned about the heap cleanup (the kernel will deal with that and it helps apps shut down faster)&mdash;and, these are tiny leaks and will not really be an issue&mdash;but if I hadn't baselined this first, I would have suspected there were more errors in `resolv` than actually existed.

I didn't dig into why these memory leaks are in R, but that's definitely on the `TODO` list.

### Speeding Up Resolution

There is no effort made by the `resolv` package functions to parallelize DNS requests since (for now) I just needed the base functionality. If you do want to speedup lookups when you're doing a boatload of them, you can use the super-straightforward [`foreach`](http://cran.r-project.org/web/packages/foreach/index.html) and [`doParallel`](http://cran.r-project.org/web/packages/doParallel/index.html) packages from the `#spiffy` [Revolution R](http://www.revolutionanalytics.com/) folks:

    :::r
    library(foreach)
    library(doParallel)
    library(data.table)
    library(resolv)
    
    alexa <- fread("data/top-1m.csv") # http://s3.amazonaws.com/alexa-static/top-1m.csv.zip
    
    n <- 10000 # top 'n' to resolve
    
    registerDoParallel(cores=6) # set to what you've got
    output <- foreach(i=1:n, .packages=c("Rcpp", "resolv")) %dopar% resolv_a(alexa[i,]$V2)
    names(output) <- alexa[1:n,]$V2})

You can also get much fancier parallel functionality with their packages (check them out!).

I'll post some benchmarks in a future post since I want to run `valgrind` on `iptools` and get any memory bugs squashed there next, but you could see 3-6x speedup (or significantly more) using this process. Setting up an aggressive local caching DNS server will also help speed up repeat queries (but increases chances of missing "fresh" data).

