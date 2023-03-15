<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:f="http://saxonica.com/ns/functions"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:idx="http://saxonica.com/ns/weblog-index"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="f h idx xs"
                version="3.0">

<xsl:import href="format.xsl"/>

<xsl:output method="html" html-version="5" encoding="utf-8" indent="no"/>

<xsl:global-context-item as="document-node(element(idx:index))"/>

<xsl:template match="idx:index">
  <xsl:variable name="index" select="."/>
  <xsl:variable name="directories"
                select="distinct-values(idx:post/@href ! f:directory(.))"/>

  <xsl:for-each select="$directories">
    <xsl:variable name="dir" select="."/>
    <xsl:variable name="path"
                  select="resolve-uri('../build/docs/' || $dir, static-base-uri())"/>
    <xsl:variable name="posts"
                  select="$index/idx:post[starts-with(@href, $dir)]"/>

    <xsl:choose>
      <xsl:when test="count($posts) eq 1">
        <xsl:result-document href="{$path}/index.html" indent="yes">
          <html>
            <head>
              <meta http-equiv="Refresh" content="0; url=/{$posts/@href/string()}"/>
              <title>Redirect</title>
            </head>
            <body>
              <a href="/{$posts/@href/string()}">Redirect</a>.
            </body>
          </html>
        </xsl:result-document>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="parts" select="tokenize($dir, '/')"/>
        <xsl:variable name="year" select="$parts[2]"/>
        <xsl:variable name="month" select="$parts[3]"/>
        <xsl:variable name="datestr"
                      select="if (exists($month))
                              then
                                let $date := xs:date($year || '-' || $month || '-01')
                                return format-date($date, '[MNn], [Y0001]')
                              else
                                $year"/>

        <xsl:variable name="posts"
                      select="$posts/@href ! doc($srcdir || .)/h:html"/>
        <xsl:variable name="author" select="f:post-author($posts[1])"/>

        <xsl:result-document href="{$path}/index.html" indent="yes">
          <html>
            <head>
              <meta name="viewport"
                    content="width=device-width, initial-scale=1.0" />
              <title><xsl:sequence select="$datestr"/> Archive</title>
              <link rel="stylesheet" href="/css/blog.css" type="text/css"/>
              <xsl:if test="$author">
                <link rel="stylesheet" type="text/css"
                      href="/css/{f:author-token($author)}.css"/>
              </xsl:if>
              <link href="/{$parts[1]}/atom.xml"
                    type="application/atom+xml" rel="alternate" title="Atom feed" />
            </head>
            <body class="{f:author-token($author)}">
              <header>
                <xsl:call-template name="banner">
                  <xsl:with-param name="author" select="$author"/>
                </xsl:call-template>
                <h2><xsl:sequence select="$datestr"/> Archive</h2>
                <xsl:call-template name="blog-nav">
                  <xsl:with-param name="feed"
                                  select="'/' || $parts[1] || '/atom.xml'"/>
                </xsl:call-template>
                <div class="byline">
                  <span class="by">By </span>
                  <span class="name">
                    <a href="/authors.html#{f:author-token($author)}">
                      <xsl:sequence select="$author"/>
                    </a>
                  </span>
                </div>
              </header>
              <main>
                <div class="post-index">
                  <xsl:call-template name="posts-by-years">
                    <xsl:with-param name="posts" select="$posts"/>
                  </xsl:call-template>
                </div>
              </main>
            </body>
          </html>
        </xsl:result-document>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>

  <xsl:variable name="posts"
                select="$index/idx:post/@href
                        ! resolve-uri('../src/' || ., static-base-uri())
                        ! doc(.)/h:html"/>
  <xsl:variable name="date" select="current-dateTime()"/>

  <xsl:result-document href="{resolve-uri('../build/docs/archive.html', static-base-uri())}"
                       indent="yes">
    <html>
      <head>
        <meta http-equiv="Refresh" content="0; url=/"/>
        <title>Redirect</title>
      </head>
      <body>
        <a href="/">Redirect</a>.
      </body>
    </html>
  </xsl:result-document>

  <xsl:result-document href="{resolve-uri('../build/docs/index.html', static-base-uri())}"
                       indent="yes">
    <html>
      <head>
        <title>def.saxonica.com blog archives</title>
        <link rel="stylesheet" href="/css/blog.css" type="text/css"/>
        <meta name="viewport"
              content="width=device-width, initial-scale=1.0" />
      </head>
      <body>
        <header>
          <h1>Saxonica weblog archives</h1>
          <xsl:call-template name="blog-nav"/>
          <div class="byline">
            <xsl:if test="exists($date)">
              <span class="date" time="{$date}">
                <xsl:sequence select="format-dateTime($date, $dtformat)"/>
              </span>
            </xsl:if>
          </div>
        </header>
        <main>
          <xsl:call-template name="post-index">
            <xsl:with-param name="posts" select="$posts"/>
            <xsl:with-param name="show-author" select="true()"/>
          </xsl:call-template>
        </main>
      </body>
    </html>
  </xsl:result-document>

  <xsl:result-document href="{resolve-uri('../build/docs/authors.html', static-base-uri())}"
                       indent="yes">
    <html>
      <head>
        <title>Author index</title>
        <link rel="stylesheet" href="/css/blog.css" type="text/css"/>
        <meta name="viewport"
              content="width=device-width, initial-scale=1.0" />
      </head>
      <body>
        <header>
          <h1>Author index</h1>
          <xsl:call-template name="blog-nav"/>
          <div class="byline">
            <xsl:if test="exists($date)">
              <span class="date" time="{$date}">
                <xsl:sequence select="format-dateTime($date, $dtformat)"/>
              </span>
            </xsl:if>
          </div>
        </header>
        <main>
          <xsl:variable name="akeys"
                        select="distinct-values(idx:post/@href
                                                ! substring-before(., '/'))"/>

          <p>
            <xsl:text>Authors: </xsl:text>
            <xsl:for-each select="$akeys">
              <xsl:sort select="count(f:posts-by-akey($index/idx:post, .))"
                        order="descending"/>
              <xsl:variable name="akey" select="."/>
              <xsl:if test="position() gt 1">, </xsl:if>

              <xsl:variable name="post"
                            select="($index/idx:post[starts-with(@href, $akey)]
                                     ! @href)[1]
                                    ! doc($srcdir || .)/h:html"/>

              <a href="#{f:author-token(f:post-author($post))}">
                <xsl:sequence select="f:post-author($post)"/>
              </a>
            </xsl:for-each>
          </p>

          <xsl:for-each select="$akeys">
            <xsl:sort select="count(f:posts-by-akey($index/idx:post, .))"
                      order="descending"/>
            <xsl:variable name="akey" select="."/>

            <xsl:variable name="posts"
                          select="$index/idx:post[starts-with(@href, $akey)]
                                  ! @href
                                  ! doc($srcdir || .)/h:html"/>

            <div class="author">
              <h2 id="{f:author-token(f:post-author($posts[1]))}">
                <xsl:sequence select="f:post-author($posts[1])"/>
              </h2>
              <xsl:call-template name="post-index">
                <xsl:with-param name="posts" select="$posts"/>
                <xsl:with-param name="show-author" select="true()"/>
                <xsl:with-param name="idx-prefix"
                                select="f:author-token(f:post-author($posts[1])) || '-'"/>
              </xsl:call-template>
            </div>
          </xsl:for-each>
        </main>
      </body>
    </html>
  </xsl:result-document>
</xsl:template>

<xsl:template name="posts-by-years">
  <xsl:param name="posts" as="element(h:html)+"/>

  <xsl:variable name="years"
                select="distinct-values($posts ! f:post-date(.) ! year-from-dateTime(.))"/>

  <xsl:choose>
    <xsl:when test="count($years) gt 1">
      <ul class="years">
        <xsl:for-each select="$years">
          <xsl:sort order="descending"/>

          <xsl:variable name="year" select="."/>
          <xsl:variable name="date"
                        select="format-number($year, '0001') || '-01-01'"/>
          <xsl:variable name="date" select="xs:date($date)"/>
          <li>
            <a href="{$year}/">
              <xsl:sequence select="format-date($date, '[Y0001]')"/>
            </a>

            <xsl:call-template name="posts-by-months">
              <xsl:with-param name="posts"
                              select="$posts[f:post-date(.) ! year-from-dateTime(.) = $year]"/>
            </xsl:call-template>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="posts-by-months">
        <xsl:with-param name="posts" select="$posts"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="posts-by-months">
  <xsl:param name="posts" as="element(h:html)+"/>

  <xsl:variable name="year" select="f:post-date($posts[1]) ! year-from-dateTime(.)"/>
  <xsl:variable name="months"
                select="distinct-values($posts ! f:post-date(.) ! month-from-dateTime(.))"/>

  <xsl:choose>
    <xsl:when test="count($months) gt 1">
      <ul class="months">
        <xsl:for-each select="$months">
          <xsl:sort order="descending"/>

          <xsl:variable name="month" select="."/>
          <xsl:variable name="date"
                        select="$year || '-' || format-number($month, '01') || '-01'"/>
          <xsl:variable name="date" select="xs:date($date)"/>
          <li>
            <a href="{$year}/{format-number($month, '01')}/">
              <xsl:sequence select="format-date($date, '[MNn], [Y0001]')"/>
            </a>

            <xsl:call-template name="posts-by-month">
              <xsl:with-param name="posts"
                              select="$posts[f:post-date(.) ! month-from-dateTime(.) = $month]"/>
            </xsl:call-template>
          </li>
        </xsl:for-each>
      </ul>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="posts-by-month">
        <xsl:with-param name="posts" select="$posts"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="posts-by-month">
  <xsl:param name="posts" as="element(h:html)+"/>

  <ul>
    <xsl:for-each select="$posts">
      <li>
        <span class="title">
          <a href="/{substring-after(base-uri(.), $srcdir)}">
            <xsl:sequence select="f:post-title(.)"/>
          </a>
        </span>
        <span class="date">
          <xsl:text>, </xsl:text>
          <xsl:sequence select="format-dateTime(f:post-date(.),
                                $dtformat)"/>
        </span>
      </li>
    </xsl:for-each>
  </ul>
</xsl:template>

<xsl:template name="post-index">
  <xsl:param name="posts" as="element(h:html)+"/>
  <xsl:param name="show-author" as="xs:boolean" select="false()"/>
  <xsl:param name="idx-prefix" as="xs:string?" select="()"/>

  <div class="post-index">
    <ul class="years">
      <xsl:for-each
          select="distinct-values($posts ! f:post-date(.) ! year-from-dateTime(.))">
        <xsl:sort select="." order="descending"/>

        <xsl:variable name="year" select="."/>
        <xsl:variable name="posts"
                      select="$posts[f:post-date(.) ! year-from-dateTime(.) = $year]"/>

        <li id="{$idx-prefix}D{.}">
          <xsl:sequence select="$year"/>

          <xsl:for-each
              select="distinct-values($posts
                                      ! f:post-date(.)
                                      ! month-from-dateTime(.))">
            <xsl:sort select="." order="descending"/>

            <xsl:variable name="month" select="."/>
            <xsl:variable name="posts"
                          select="$posts[f:post-date(.)
                                         ! month-from-dateTime(.) = $month]"/>
            <xsl:variable name="date"
                          select="$year || '-' || format-number($month, '01')
                                  || '-01'"/>
            <xsl:variable name="date" select="xs:date($date)"/>

            <ul class="month" id="{$idx-prefix}D{$year}-{format-number($month, '01')}">
              <li>
                <xsl:sequence select="format-date($date, '[MNn]')"/>
                <ul>
                  <xsl:for-each select="$posts">
                    <xsl:sort select="f:post-date(.)" order="descending"/>
                    <xsl:variable name="post" select="."/>
                    <li>
                      <span class="title">
                        <a href="/{substring-after(base-uri(.), $srcdir)}">
                          <xsl:sequence select="f:post-title($post)"/>
                        </a>
                      </span>
                      <xsl:if test="$show-author">
                        <span class="author">
                          <xsl:text>, </xsl:text>
                          <xsl:sequence select="f:post-author($post)"/>
                        </span>
                      </xsl:if>
                      <span class="date">
                        <xsl:text>, </xsl:text>
                        <xsl:sequence select="format-dateTime(f:post-date($post),
                                                              $dtformat)"/>
                      </span>
                    </li>
                  </xsl:for-each>
                </ul>
              </li>
            </ul>
          </xsl:for-each>
        </li>
      </xsl:for-each>
    </ul>
  </div>
</xsl:template>

<!-- ============================================================ -->

<xsl:function name="f:directory" as="xs:string+">
  <xsl:param name="filename" as="xs:string"/>
  <xsl:variable name="parts" select="tokenize($filename, '/')"/>

  <xsl:if test="count($parts) ne 4">
    <xsl:sequence select="error((), 'Unexpected post URI: ' || $filename)"/>
  </xsl:if>

  <xsl:sequence
      select="($parts[1],
               $parts[1] || '/' || $parts[2],
               $parts[1] || '/' || $parts[2] || '/' || $parts[3])"/>
</xsl:function>

<xsl:function name="f:posts-by-akey" as="element(idx:post)*">
  <xsl:param name="posts" as="element(idx:post)*"/>
  <xsl:param name="akey" as="xs:string"/>
  <xsl:sequence select="$posts[starts-with(@href, $akey)]"/>
</xsl:function>

</xsl:stylesheet>

