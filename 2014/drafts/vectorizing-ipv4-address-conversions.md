Title: Vectorizing IPv4 Address Conversions - Part 1
Date: 2014-05-16 07:26:53
Category: tools
Status: draft
Tags: rstats, r, rcpp
Slug: vectorizing-ipv4-address-conversions-part-1
Author: Bob Rudis (@hrbrmstr)

Our [previous post](http://datadrivensecurity.info/blog/posts/2014/May/speeding-up-ipv4-address-conversion-in-r/) showed how to speed up the conversion of IPv4 addresses to/from integer format by taking advantage of a simple `Rcpp` wrapper to "bootsted" native functions. However, to convert more than one IP address, you need to stick those functions into one of the R `*apply` functions, which does the job, but is not an optimal solution. Ideally, it would be advantageous to be able to pass in a vector (with more than one element) of character IP addresses or a vector of integer format IP addresses and know that the function will work.

In this post we'll introduce a shortcut method of vectorization with the `Vectorize()` function. Then, in the second and final part of the series, we'll look at implementing the necessary code at the `Rcpp` layer to perform the vectorization at the C++-level and show some benchmarks for each method.

### The Vectorize() Shortcut

At the end of our previous exercise, we had two functions: `rinet_pton()` & `rinet_ntop()`. Each took a single argument (the former a single element character vector and the latter a single element numeric vector) and returned a single element vector as a result. Let's vectorize each one using the `Vectorize()` function:

    :::r
    # the following code assumes you've already done the "sourceCpp" in the prev article
    
    ip_to_long <- Vectorize(rinet_pton)
    long_to_ip <- Vectorize(rinet_ntop)

Yes, that's all it takes. Now we can pass in a vector of one or more elements and each function will return a vector of the same size as a result. The proof is in the output, so let's give them a go, first with the original single-element vector use case:

    :::r
    # try a single IP address first
      
    ip_to_long("10.0.0.0")
    ##  10.0.0.0 
    ## 167772160
    
    long_to_ip(167772160)
    ## [1] "10.0.0.0"

So far, so good *except* that the default behavior (in `Vectorize()`) of producing a named vector when a character vector is passed in is probably not what we really want, so we'll tweak the call to `Vectorize()` for each function:

    :::r
    ip_to_long <- Vectorize(rinet_pton, USE.NAMES=FALSE)
    long_to_ip <- Vectorize(rinet_ntop, USE.NAMES=FALSE)
    
    ip_to_long("10.0.0.0")
    ## [1] 167772160
    
    long_to_ip(167772160)    
    ## [1] "10.0.0.0"
    

Now, let's test it with more than one element:

    :::r
    srcIp <- c("146.178.58.99", "174.5.172.152", "146.178.58.99", "213.186.42.8", 
              "146.178.58.99", "170.138.152.142", "170.138.152.142", "174.5.172.152", 
              "146.178.58.99", "213.186.42.8")
    
    srcInt <- c(2461153891, 2919607448, 2461153891, 3585747464, 2461153891, 
                2861209742, 2861209742, 2919607448, 2461153891, 3585747464)
    
    ip_to_long(srcIp)
    ##  [1] 2461153891 2919607448 2461153891 3585747464 2461153891 2861209742
    ##  [7] 2861209742 2919607448 2461153891 3585747464
    
    long_to_ip(srcInt)
    ##  [1] "146.178.58.99"   "174.5.172.152"   "146.178.58.99"  
    ##  [4] "213.186.42.8"    "146.178.58.99"   "170.138.152.142"
    ##  [7] "170.138.152.142" "174.5.172.152"   "146.178.58.99"  
    ## [10] "213.186.42.8"

Everything works as expected and we can now use those conversion routines without resorting to `*apply` calls.

>***Exercise For the reader!***
>
>To see what `Vectorize()` does under the covers, just enter `ip_to_long` or `long_to_ip`
>at an R console prompt **without** the parenthesis. This will show the source of the functions
>that `Vectorize()` built. Try to build your own vectorized versions by trimming down
>what's in the generated source code.

We'll see how to perform the same vectorization task at the `Rcpp` level in the next post and put each version in a head-to-head benchmark test. **NOTE**: Using `Rcpp` with R markdown takes some extra steps, and I've [posted a gist](https://gist.github.com/hrbrmstr/f2a97ed43750d5dd3461) that shows some of the options you need to set to ensure the `Rcpp` code compiles and links properly and also the wicked-cool way you can embed `Rcpp` code right in markdown documents.