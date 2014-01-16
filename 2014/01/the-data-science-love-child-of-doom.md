Title: The Data Science Love Child of Doom
Date: 2014-01-16 14:00:00
Category: tools
Tags: python, R
Slug: the-data-science-love-child-of-doom
Author: Bob Rudis (@hrbrmstr)

Readers of the [data exploration in R post](http://datadrivensecurity.info/blog/drafts/data-exploration-in-r.html) will have noticed the use of Python for the extraction of TLD components of malware domain names. The excerpt in question is below:

	:::SLexer
	write.table(str_extract(mdl.df$domain, perl("^[a-zA-Z0-9\\-\\._]+")),
	            file="/tmp/indomains.txt",
	            quote=FALSE,
	            col.names=FALSE,
	            row.names=FALSE)
	# grab tlds.py from https://gist.github.com/hrbrmstr/8275775
	system("tlds.py", ignore.stdout=TRUE)
	mdl.df$domain <- factor(scan(file="/tmp/outdomains.txt", 
	                             what=character(), 
	                             quiet=TRUE))

There is no R equivalent of the `tldextract` [Python module](http://pydoc.net/Python/tldextract/0.1.1/tldextract.tldextract/) and often times there's no good reason to reinvent the wheel in another language, especially if it's going to be a procedure that is not executed frequently.

I used the `temp file write->script execute->temp file read` process in the main post since performance was not a concern and I knew it would work in almost any R setting. However, there is a much better way to marry R and Python in the R package [rPython](http://rpython.r-forge.r-project.org/).

To get `rPython` setup in R on Linux or Mac OS X, it's just a matter of doing a standard _source_ install of the R package:


	:::SLexer
	install.packages("rPython", type="source")

Most R modules work fine with a standard binary installation (i.e. leave off the `type="source"`), but you'll want `rPython` to establish bindings to *your* default Python environment (when I installed the binary version on OS X it defaulted to Python 2.6 when 2.7 was my default install and that caused some module import issues).

Those folks working on Windows systems will need to [check out the README](http://cran.r-project.org/bin/windows/contrib/r-release/ReadMe) for instructions for how to make the package work under Windows.

Here's what the revised code looks like using `rPython` instead of calling out to a schell script:

	:::SLexer
	library(rPython)
	
	python.exec("import tldextract")
	python.assign("hosts", mdl.df$domain)
	python.exec("tlds = ['.'.join(tldextract.extract(host.rstrip())[-2 : ]) for host in hosts]")
	tlds <- factor(python.get("tlds"))

Through `rPython` we are able to pass R variables to Python and read Python data structures back into R pretty seamlessly. Unlike many hybrid language biding approaches, `rPython` converts all data to JSON structures for the exchange between environments. While this approach does not provide direct variable memory access between environemnts, it does optimize compatibility.

As this relatively simplistic example shows, you can execute almost any bit of Python code and use nearly every Python module without having to resort to file-based data exchange methods.

Python has a similar [rpy2](http://rpy.sourceforge.net/rpy2.html) module for going in the reverse direction (i.e. calling R code from Python) and pandas has some [special helper functions](http://pandas.pydata.org/pandas-docs/dev/r_interface.html) for easy transport between pandas objects and R objects.

Data science isn't about sticking with one tool, it's about answering questions and solving problems. If you can save time by using a critical piece of functionality from another language in a hybrid solution like `rPython` or `rPy2` there is really no reason not to. There may be cases where performance or production stability concerns make it necessary to stay within one language and replicate functionality from another, but those instances will more likely be the exception vs the rule.

For those just beginning on the data science path, you can find out more about R packages and Python modules at [Quick-R](http://www.statmethods.net/interface/packages.html) and [python.org](http://docs.python.org/2/tutorial/modules.html) respectively.