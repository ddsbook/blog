Title: About DDS
Date: 2014-01-01 11:00:00
Category: News
Tags: book, blog
Slug: about-dds
Author: Bob Rudis (@hrbrmstr)

Data Driven <b>Security</b> is a collaboration between Jay Jacobs &amp; Bob Rudis. Through their book, blog posts and podcasts Bob &amp; Jay hope to help security domain practitioners embrace and engage all elements of security data science to help defend their organizations.

Whether you're just starting out or are a "data veteran", Data Driven <b>Security</b> has something for everyone.

**Data Driven Security : Behind the Scenes**

One of the design goals for the family of websites that make up the whole of Data Driven Security was avoiding non-client dynamic content as much as possible.

To that end, we settled on the static blogging platform [Pelican](http://getpelican.com) for all content production and [github](https://github.com/ddsbook/blog) for content management. Github enables deep collaboration and robust version control by default. Pelican supports [reStructuredText](http://docutils.sourceforge.net/rst.html) and [markdown](http://daringfireball.net/projects/markdown/) for posts, both of which allow for inclusion of plain 'ol HTML (which is necessary for many of our visualizations).

When it's time to push a new article or change to an existing article or page, all it takes is a sync to the public github repository which then generates a github [service hook](https://help.github.com/articles/post-receive-hooks) call that triggers a content sync and regeneration, and also triggers a production site backup. The use of github also makes it possible to include other contributors to the blog. If you've got a post you'd like to share on the DDS blog, follow [these steps](https://help.github.com/articles/fork-a-repo) to fork the `https://github.com/ddsbook/blog` repository, add your content and issue a [pull request](https://help.github.com/articles/using-pull-requests).

This setup provides most of the features of a WordPress-style blog without the ills that come with php or other dynamic frameworks.

The podcast site also uses Pelican with the base content being generated automagically from the feed XML file. This makes it possible to add non-episode content if the need arises and reduces the time it takes to maintain a podcast web site. If you're interested in taking a peek at that setup, give a tweet to [@hrbrmstr](http://twitter.com/hrbrmstr).