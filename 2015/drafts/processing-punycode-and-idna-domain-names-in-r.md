Title: Processing Punycode and IDNA Domain Names in R
Date: 2015-06-03 20:42:02
Category: blog
Status: draft
Tags: blog
Slug: processing-punycode-and-idna-domain-names-in-r
Author: Bob Rudis (@hrbrmstr)

When fighting the good cyber-fight, one often has to process domain names. Our good friend @alexcpsec was in need of [Punycode](https://www.ietf.org/rfc/rfc3492.txt)/[IDNA](https://www.ietf.org/rfc/rfc3490.txt) processing in R which begat the newly-minted [punycode R package](https://github.com/hrbrmstr/punycode). Much of the following has been culled from open documentation, so if you are already "in the know" about Punycode & IDNA, skip to the R code bits.

#### What is 'Punycode'?

Punycode is a simple and efficient transfer encoding syntax designed for use
with Internationalized Domain Names in Applications. It uniquely and
reversibly transforms a Unicode string into an ASCII string. ASCII
characters in the Unicode string are represented literally, and non-ASCII
characters are represented by ASCII characters that are allowed in host
name labels (letters, digits, and hyphens).

#### What is 'IDNA'?

Until now, there has been no standard method for domain names to use
characters outside the ASCII repertoire. The IDNA document defines
internationalized domain names (IDNs) and a mechanism called IDNA for
handling them in a standard fashion. IDNs use characters drawn from a
large repertoire (Unicode), but IDNA allows the non-ASCII characters to be
represented using only the ASCII characters already allowed in so-called
host names today. This backward-compatible representation is required in
existing protocols like DNS, so that IDNs can be introduced with no changes
to the existing infrastructure. IDNA is only meant for processing domain
names, not free text.

#### Why domain validation?

Organizations that manage some Top Level Domains (TLDs) have published
tables with characters they accept within the domain. The reason may be to
reduce complexity that come from using the full Unicode range, and to
protect themselves from future (backwards incompatible) changes in the
IDN or Unicode specifications. Libidn (and, hence, this package) implements
an infrastructure for defining and checking strings against such tables.

### Working with punycode

All three functions in the package are vectorized at the C-level. 

For encoding and decoding operations, you pass in vectors of domain names and the functions return
encoded or decoded character vectors. If there are any issues during the conversion
of a particular domain name, the function will substitute \code{"Invalid"} for the
domain name. 

For the TLD validation function, any character set or conversion issue will cause \code{FALSE} to 
be returned. Otherwise the function will return \code{TRUE}.

#### Usage

    :::r
    devtools::install_github("hrbrmstr/punycode")
    library(punycode)

    ascii_doms <- c("xn------qpeiobbci9acacaca2c8a6ie7b9agmy.net",
    "xn----0mcgcx6kho30j.com",
    "xn----9hciecaaawbbp1b1cd.net",
    "xn----9sbmbaig5bd2adgo.com",
    "xn----ctbeewwhe7i.com",
    "xn----ieuycya4cyb1b7jwa4fc8h4718bnq8c.com",
    "xn----ny6a58fr8c8rtpsucir8k1bo62a.net",
    "xn----peurf0asz4dzaln0qm161er8pd.biz",
    "xn----twfb7ei8dwjzbf9dg.com",
    "xn----ymcabp2br3mk93k.com")

    intnl_doms <- c("ثبت-دومین.com",
    "טיול-לפיליפינים.net",
    "бизнес-тренер.com",
    "новый-год.com",
    "東京ライブ-バルーンスタンド.com",
    "看護師高収入-求人.net",
    "ユベラ-贅沢ポリフェノール.biz",
    "เด็ก-ภูเก็ต.com",
    "ایران-هاست.com")


    for_valid <- c("gr€€n.no", "זגורי-אימפריה-לצפייה-ישירה.net", "ثبت-دومین.com",
    "טיול-לפיליפינים.net", "xn------qpeiobbci9acacaca2c8a6ie7b9agmy.net", "xn----0mcgcx6kho30j.com",
    "xn----9hciecaaawbbp1b1cd.net", "rudis.net")

    # encoding

    puny_encode(ascii_doms)

    ##  [1] "זגורי-אימפריה-לצפייה-ישירה.net"  "ثبت-دومین.com"                   "טיול-לפיליפינים.net"            
    ##  [4] "бизнес-тренер.com"               "новый-год.com"                   "東京ライブ-バルーンスタンド.com"
    ##  [7] "看護師高収入-求人.net"           "ユベラ-贅沢ポリフェノール.biz"   "เด็ก-ภูเก็ต.com"                      
    ## [10] "ایران-هاست.com"

    # decoding

    puny_decode(intnl_doms)

    ## [1] "xn----0mcgcx6kho30j.com"                   "xn----9hciecaaawbbp1b1cd.net"             
    ## [3] "xn----9sbmbaig5bd2adgo.com"                "xn----ctbeewwhe7i.com"                    
    ## [5] "xn----ieuycya4cyb1b7jwa4fc8h4718bnq8c.com" "xn----ny6a58fr8c8rtpsucir8k1bo62a.net"    
    ## [7] "xn----peurf0asz4dzaln0qm161er8pd.biz"      "xn----twfb7ei8dwjzbf9dg.com"              
    ## [9] "xn----ymcabp2br3mk93k.com"

    # validation

    puny_tld_check(for_valid)

    ## [1] FALSE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE  TRUE

#### Fin

If you find any errors or need more functionality, post an issue on github and/or drop a note in the comments.
