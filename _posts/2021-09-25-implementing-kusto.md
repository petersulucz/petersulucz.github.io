---
layout: post
title:  "Implementing The Kusto Query Language"
date:   2021-09-25 00:00:00 -0700
categories: hyperv
---

This is the first bit on a series of implementing a big data search engine, and the beginning of a series on implementing the backend services of [logship](https://logshit.com). The goal is to implement a search / analytics system that anybody could walk off the street and use. The first few posts will start with getting the query language right, since that'll be the entry point to most users. For comparison some of the most popular Big Data search systems out there use SQL as their query language. Think Presto or Spark. SQL is fantastic, but generally a very difficult language to use for non experts; espessially as the queries get complicated.

In order to lower barriers to entry for [logship](https://logshit.com), I didn't think SQL was the way to go. While it is one of the most popular languages in the world, the syntax makes it clunky for data analytics. (Another interesting side note, when SQL is the entry point, users seem to treat the query engine as if they are actually querying a SQL database, a distinction I'd like to avoid.)

Kusto to the Rescue! In the example below, I have a table of the posts scrapped from the /r/politics subreddit. Following are a few examples of why Kusto was the choice made.

{% highlight kusto %}
reddit_politics
| take 100
{% endhighlight %}

Equivalent SQL

{% highlight sql %}
SELECT *
FROM reddit_politics
LIMIT 100
{% endhighlight %}

Kusto is a completely sequential language. Every operation is applied on top of the previous one (flowing downwards in the query). So looking at, and understanding a query is extremely simple.

{% highlight kust %}
reddit_politics
| where ups > 10000
| where title contains "biden"
| where title contains "arizona"
| take 100
{% endhighlight %}

Pretty simple right? reddit_politics -> posts with more than 10000 up votes -> take pots where the title contains the word 'biden' -> further filter down to posts where the title contains the word 'arizona' -> limit to 100 results.
The equivalent SQL would look like this:

{% highlight sql %}
SELECT *
FROM reddit_politics
WHERE ups > 10000
  AND title contains 'biden'
  AND title contains 'arizona'
LIMIT 100
{% endhighlight %}

So this is the intro, stay tuned for more!

![Simple kusto query]({{ site.url }}/assets/images/logship_simple_kusto-filter-09-25.png "Simple kusto query")

Also investing on running the entire query stack out of a command line, for testability and quick offline analysis. Sporting all the same features, optimizations, and performances.

![Simple kusto CLI]({{ site.url }}/assets/images/logship_kusto_cli_reddit_politics_09_26_2021.png "Simple kusto CLI")
