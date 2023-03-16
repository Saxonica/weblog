# How to publish to the weblog

(This page is only really relevant for Saxonica employees with a weblog on
https://blog.saxonica.com/)

The weblog is published automatically by a GitHub workflow. All you
have to do is commit a new HTML weblog post and it’ll be published for
you.

## Where to put your posts

To publish a new post, create the post under your username in the `src/` directory.
The file should be named `src/{username}/{year}/{month}/{day}-{shortname}`.
For example, Norm created a post about Maven on 29 October, 2020. That file is
in `src/norm/2020/10/29-maven`.

If you don’t have a username, there’s a little bit of first-time setup
that needs to be done. Ask Norm.

## How to format your posts

There are only a few, simple requirements for a posting.

1. It must be well-formed (X)HTML.
2. It must have a “meta” tag identifying the author.
3. It must have a “meta” tag identifying the pubdate.

Everything else is up to you.

Here’s a simple template:

```
<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>{YOUR TITLE}<title>
  <meta name="author" content="{YOUR NAME}" />
  <meta name="pubdate" content="{PUBLICATION DATE AS AN xs:dateTime}" />
</head>
<body>
<h1>{YOUR TITLE}</h1>

anything you want goes here

</body>
</html>
```

The build script will reject your post if it doesn’t satisfy the
location and publication metadata requirements.

It will also reject your post if it appears to contain broken links to
other resources in the weblog.

## Testing your posting

Open a shell window and navigate to the directory where you checked out the weblog.

Run `./gradlew`

The first time you do this, and the first time you do it after adding
a new post, it has to format all of the posts. Subsequent runs are
faster. (Whenever a new post is added, the whole collection is
reformatted so that the inter-post navigation can be recomputed; we
could do better, but it hasn’t seemed necessary yet.)

## Preview your posting

Previewing the pages only really works if you have a web server. This
simplifies things for the stylesheets by making absolute URIs do the
right thing. It complicates things for you because it means you can’t
just open up the files in your browser.

Run `./gradlew server`

That will fire up a simple Python web server. Point your browser at
http://localhost:9000/blog and you should be able to navigate around
the site.

## Publishing your post

Add it to the git repo and push the change. That will fire off the
job that will publish your posting.

You can check progress on the [actions tab](https://github.com/Saxonica/weblog/actions).
