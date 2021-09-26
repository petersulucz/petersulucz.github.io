---
layout: post
title:  "Implementing The Kusto Query Language"
date:   2021-09-25 00:00:00 -0700
categories: hyperv
---

This is the first bit on a series of implementing a big data search engine. The first few will focus on getting the grammar right.
So heres the 'WHY'. Some of the most popular Big Data search systems out there use SQL as their Query Language. Think Presto or Spark. SQL is fantastic, but generally a very difficult language to use for non experts; espessially as the queries get complicated. In order to lower barriers to entry for [logship](http://logshit.com), we didn't think SQL was the way to go.

Kusto to the Rescue! In the example below, I have a table of the posts scrapped from the /r/news subreddit. 

{% highlight kusto %}
reddit_news
| take 100
{% endhighlight %}

Equivalent SQL

{% highlight sql %}
SELECT *
FROM reddit_news
LIMIT 100
{% endhighlight %}

Kusto is a completely sequential language. Every operation, seperated by the '|' is applied on top of the previous one. So looking at, and understanding a query is extremely simple.

{% highlight kust %}
reddit_politics
| project PreciseTimestamp, key, authorKey, ups, title, permalink, selftext
| where ups > 10000
| where title contains "biden"
| where title contains "arizona"
| take 100
{% endhighlight %}

Pretty simple right?
The equivalent SQL would look like this

{% highlight sql %}
SELECT *
FROM reddit_news
WHERE ups > 10000
  AND title contains 'biden'
  AND title contains 'arizona'
LIMIT 100
{% endhighlight %}

To this is the intro, stay tuned for how this actually gets implemented!

![Simple kusto query]({{ site.url }}/assets/_pics/logship_simple_kusto-filter-09-25.png "Simple kusto query")