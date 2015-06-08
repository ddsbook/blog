Title: Running other languages in R Markdown (Rmd) files
Date: 2015-06-08 09:20:15
Category: blog
Status: draft
Tags: blog, r, rstats
Slug: running-other-languages-in-r-markdown-files
Author: Bob Rudis (@hrbrmstr)

After seeing [IPython Markdown Opportunities in IPython Notebooks and Rstudio](http://blog.ouseful.info/2015/06/06/ipython-markdown-opportunities/) in the feeds today I wondered how easy/hard it would be to write a handler for something like [go](https://golang.org/) code. After taking a look at [Yihui Xie](https://twitter.com/xieyihui)'s knitr [source](https://github.com/yihui/knitr/blob/master/R/engine.R) it seemed like it would be fairly easy to mimic a combination of `Rcpp` and "shell" block handling to process standalone Go code blocks.

I call these "standalone" blocks since they don't preserve anthing between the code chunks, so you're really just embedding a language script for reproducible processing. My naive Go implementation also doesn't handle any visualizations that code would generate nor does it format the Go code nicely (that's definitely on the `TODO` list, though). However, it does show how to make a minimal working chunk language processor and provides basic functionality for Go scripts.

Here's the start of a self-contained Rmd file for supporting Go language blocks:

    ---
    output: html_document
    ---
    ```{r setup, echo=FALSE}
    
    library(knitr)
    
    eng_go <- function(options) {
      
      # create a temporary file
    
      f <- basename(tempfile("go", '.', paste('.', "go", sep = '')))
      on.exit(unlink(f)) # cleanup temp file on function exit
      writeLines(options$code, f)
    
      out <- ''
      
      # if eval != FALSE compile/run the code, preserving output
    
      if (options$eval) {
        out <- system(sprintf('go run %s', paste(f, options$engine.opts)), intern=TRUE)
      }
      
      # spit back stuff to the user
      
      engine_output(options, options$code, out)
    }
    
    knitr::knit_engines$set(go=eng_go)
    
    ```

It's pretty self-explanatory, but the steps in the `eng_go` function are:

- create a temporary file for the `go` source code
- ensure that temp file is deleted on function exit
- if told to eval, then run the `go` file with any options/arguments and preserve the output
- pass the code & output back to knitr

And, then all we have to do is register the engine with the last line.

Now, we can take the [Go language 'slices' example](https://gobyexample.com/slices) code and put it in a chunk below that:

    ```{r go-ex, engine='go', eval=TRUE, echo=FALSE}
    package main

    import "fmt"

    func main() {

        // Unlike arrays, slices are typed only by the
        // elements they contain (not the number of elements).
        // To create an empty slice with non-zero length, use
        // the builtin `make`. Here we make a slice of
        // `string`s of length `3` (initially zero-valued).
        s := make([]string, 3)
        fmt.Println("emp:", s)

        // We can set and get just like with arrays.
        s[0] = "a"
        s[1] = "b"
        s[2] = "c"
        fmt.Println("set:", s)
        fmt.Println("get:", s[2])

        // `len` returns the length of the slice as expected.
        fmt.Println("len:", len(s))

        // In addition to these basic operations, slices
        // support several more that make them richer than
        // arrays. One is the builtin `append`, which
        // returns a slice containing one or more new values.
        // Note that we need to accept a return value from
        // append as we may get a new slice value.
        s = append(s, "d")
        s = append(s, "e", "f")
        fmt.Println("apd:", s)

        // Slices can also be copied. Here we create an
        // empty slice `c` of the same length as `s` and copy
        // into `c` from `s`.
        c := make([]string, len(s))
        copy(c, s)
        fmt.Println("cpy:", c)

        // Slices support a "slice" operator with the syntax
        // `slice[low:high]`. For example, this gets a slice
        // of the elements `s[2]`, `s[3]`, and `s[4]`.
        l := s[2:5]
        fmt.Println("sl1:", l)

        // This slices up to (but excluding) `s[5]`.
        l = s[:5]
        fmt.Println("sl2:", l)

        // And this slices up from (and including) `s[2]`.
        l = s[2:]
        fmt.Println("sl3:", l)

        // We can declare and initialize a variable for slice
        // in a single line as well.
        t := []string{"g", "h", "i"}
        fmt.Println("dcl:", t)

        // Slices can be composed into multi-dimensional data
        // structures. The length of the inner slices can
        // vary, unlike with multi-dimensional arrays.
        twoD := make([][]int, 3)
        for i := 0; i < 3; i++ {
            innerLen := i + 1
            twoD[i] = make([]int, innerLen)
            for j := 0; j < innerLen; j++ {
                twoD[i][j] = i + j
            }
        }
        fmt.Println("2d: ", twoD)
    }
    ```

And, check the output after knitting:

    ## emp: [  ]
    ## set: [a b c]
    ## get: c
    ## len: 3
    ## apd: [a b c d e f]
    ## cpy: [a b c d e f]
    ## sl1: [c d e]
    ## sl2: [a b c d e]
    ## sl3: [c d e f]
    ## dcl: [g h i]
    ## 2d:  [[0] [1 2] [2 3 4]]

If you remove the `echo=FALSE` you'll get the Go code in a block before the output.

You can make this a package for handling Go code and then just issue a `library` call to it in the "setup" chunk. To ensure the language handler registration happens, just add `knitr::knit_engines$set(go=eng_go)` to the package's `.onLoad` function.

You can find the complete R Markdown file [on github](https://gist.github.com/hrbrmstr/9accf90e63d852337cb7).

Lots more can (and will) be done to extend this example. If you've already made a more robust Go handler, please drop a note in the comments with a link!
