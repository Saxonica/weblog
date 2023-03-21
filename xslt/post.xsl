<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:f="http://saxonica.com/ns/functions"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:idx="http://saxonica.com/ns/weblog-index"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="f h idx map xs"
                version="3.0">

<xsl:import href="format.xsl"/>

<xsl:output method="html" html-version="5" encoding="utf-8" indent="no"/>

<xsl:global-context-item as="document-node(element(h:html))"/>

<xsl:key name="posts" match="idx:post" use="@href"/>

<xsl:variable name="post" select="/h:html"/>

<xsl:template match="h:html">
  <xsl:if test="count(h:head) ne 1
                or count(h:body) ne 1
                or exists(* except (h:head|h:body))">
    <xsl:sequence select="error((), 'Post is not reasonable XHTML: ' || base-uri(.))"/>
  </xsl:if>

  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="h:head">
  <!-- There is exactly one author -->
  <xsl:if test="count(h:meta[@name='author']/@content) eq 0">
    <xsl:sequence select="error((), 'Post has no author: ' || base-uri(.))"/>
  </xsl:if>

  <xsl:if test="count(h:meta[@name='author']) gt 1">
    <xsl:sequence select="error((), 'Post has multiple authors: ' || base-uri(.))"/>
  </xsl:if>

  <!-- There is exactly one pubdate -->
  <xsl:if test="count(h:meta[@name='pubdate']/@content) eq 0">
    <xsl:sequence select="error((), 'Post has no pubdate: ' || base-uri(.))"/>
  </xsl:if>

  <xsl:if test="count(h:meta[@name='pubdate']) gt 1">
    <xsl:sequence select="error((), 'Post has multiple pubdates: ' || base-uri(.))"/>
  </xsl:if>

  <!-- The pubdate is a dateTime -->
  <xsl:if test="not(h:meta[@name='pubdate']/@content castable as xs:dateTime)">
    <xsl:sequence select="error((), 'Post has invalid pubdate: ' || base-uri(.)
                          || ': ' || string(h:meta[@name='pubdate']/@content))"/>
  </xsl:if>


  <!-- The pubdate year and month are consistent with the uri -->
  <xsl:variable name="pubdate" select="xs:dateTime(h:meta[@name='pubdate']/@content)"/>
  <xsl:variable name="pubdate-ym" select="format-dateTime($pubdate, '[Y0001]/[M01]')"/>

  <xsl:variable name="uri-year"
                select="base-uri(.) => substring-after('/src/') => substring-after('/')"/>
  <xsl:variable name="uri-month"
                select="$uri-year => substring-after('/') => substring-before('/')"/>
  <xsl:variable name="uri-year"
                select="$uri-year => substring-before('/')"/>
  <xsl:variable name="uri-ym" select="$uri-year || '/' || $uri-month"/>
  <xsl:if test="$uri-ym ne $pubdate-ym">
    <xsl:sequence select="error((), 'Post has unreasonable pubdate: ' || base-uri(.)
                          || ': ' || string(h:meta[@name='pubdate']/@content))"/>
  </xsl:if>

  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
    <link rel="stylesheet" type="text/css" href="/css/blog.css"/>

    <xsl:variable name="author" select="h:meta[@name='author']/@content/string()"/>
    <xsl:variable name="token" select="$author ! f:author-token(.)"/>

    <xsl:choose>
      <xsl:when test="contains(base-uri(.), '/announcements/')">
        <link rel="stylesheet" type="text/css"
              href="/css/announcements.css"/>
        <meta content="Saxonica announcements" property="og:site_name" />
        <meta content="https://blog.saxonica.com/img/sitecard.png" property="og:image" />
        <meta content="The latest news from Saxonica." property="og:description" />
        <meta content="https://blog.saxonica.com/announcements/" property="og:url" />
      </xsl:when>
      <xsl:when test="$token = 'michael-kay'">
        <link rel="stylesheet" type="text/css"
              href="/css/{$token}.css"/>
        <meta content="Saxon diaries" property="og:site_name" />
        <meta content="https://blog.saxonica.com/img/sitecard.png" property="og:image" />
        <meta content="Michael Kay's blog." property="og:description" />
        <meta content="https://blog.saxonica.com/mike/" property="og:url" />
      </xsl:when>
      <xsl:when test="$token = 'oneil-delpratt'">
        <link rel="stylesheet" type="text/css"
              href="/css/{$token}.css"/>
        <meta content="O'Neil Delpratt's Blog" property="og:site_name" />
        <meta content="https://blog.saxonica.com/img/sitecard.png" property="og:image" />
        <meta content="Saxon, XSLT, XQuery, and XML related." property="og:description" />
        <meta content="https://blog.saxonica.com/oneil" property="og:url" />
      </xsl:when>
      <xsl:when test="$token = 'norm-tovey-walsh'">
        <link rel="stylesheet" type="text/css"
              href="/css/{$token}.css"/>
        <meta content="Saxon Chronicles (in a Norman style)" property="og:site_name" />
        <meta content="https://blog.saxonica.com/img/sccard.png" property="og:image" />
        <meta content="Norm Tovey-Walsh's Saxonica weblog." property="og:description" />
        <meta content="https://blog.saxonica.com/norm" property="og:url" />
      </xsl:when>
      <xsl:otherwise>
        <!-- nop -->
      </xsl:otherwise>
    </xsl:choose>

    <meta content="600" property="og:image:width" />
    <meta content="315" property="og:image:height" />
    <meta content="{string(h:title)}" property="og:title" />
    <meta content="en_GB" property="og:locale" />
    <meta content="website" property="og:type" />

    <xsl:if test="not(h:title) and ../h:body/h:h1">
      <title><xsl:value-of select="(../h:body/h:h1)[1]"/></title>
    </xsl:if>

    <xsl:if test="not(h:meta[@name='viewport'])">
      <meta name="viewport"
            content="width=device-width, initial-scale=1.0" />
    </xsl:if>

  </xsl:copy>
</xsl:template>

<xsl:template match="h:body">
  <xsl:copy>
    <xsl:apply-templates select="@*"/>
    <xsl:attribute name="class"
                   select="string-join((@class, f:author-token(f:post-author(.))), ' ')"/>
    <xsl:call-template name="blog-header"/>
    <main>
      <xsl:apply-templates select="node()"/>
    </main>
    <xsl:call-template name="blog-footer"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="h:h1"/>

<xsl:template name="blog-header">
  <xsl:variable name="title">
    <xsl:sequence select="f:post-title(.)"/>
  </xsl:variable>

  <xsl:variable name="author">
    <xsl:sequence select="f:post-author(.)"/>
  </xsl:variable>

  <xsl:variable
      name="date"
      as="xs:string?"
      select="ancestor::h:html/h:head/h:meta[@name='pubdate']/@content/string()"/>

  <xsl:variable name="date" as="xs:dateTime?"
                select="if ($date) then xs:dateTime($date) else ()"/>

  <xsl:variable name="blogid"
                select="substring-after(base-uri(.), 'weblog/src/')
                        =&gt; substring-before('/')"/>

  <header>
    <xsl:call-template name="banner">
      <xsl:with-param name="blogid" select="$blogid"/>
      <xsl:with-param name="author" select="$author"/>
    </xsl:call-template>
    <h2>
      <xsl:apply-templates select="$title"/>
    </h2>
    <xsl:call-template name="blog-nav"/>
    <div class="byline">
      <span class="by">By </span>
      <span class="name">
        <a href="/authors.html#{f:author-token(f:post-author(.))}">
          <xsl:sequence select="f:post-author(.)"/>
        </a>
      </span>
      <xsl:if test="exists($date)">
        <span class="on"> on </span>
        <a href="{f:date-index($date, f:author-token(f:post-author(.)))}">
          <span class="date" time="{$date}">
            <xsl:sequence select="format-dateTime($date, $dtformat)"/>
          </span>
        </a>
      </xsl:if>
    </div>
  </header>
</xsl:template>

<xsl:template name="blog-footer">
  <xsl:variable name="prev" select="f:previous-post($post)"/>
  <xsl:variable name="next" select="f:next-post($post)"/>

  <xsl:variable name="prevuri"
                select="substring-after(base-uri($prev), $srcdir)"/>
  <xsl:variable name="nexturi"
                select="substring-after(base-uri($next), $srcdir)"/>

  <footer>
    <xsl:if test="exists($prev)">
      <div class="prev-uri">
        <a href="/{$prevuri}">
          <xsl:sequence select="f:post-title($prev)"/>
        </a>
      </div>
    </xsl:if>
    <xsl:if test="exists($next)">
      <div class="next-uri">
        <a href="/{$nexturi}">
          <xsl:sequence select="f:post-title($next)"/>
        </a>
      </div>
    </xsl:if>
  </footer>
</xsl:template>

<xsl:template name="blog-nav">
  <aside class="nav">
    <div class="navlinks">
      <div id='search'>
        <form action="https://www.google.com/search" target="_parent">
          <span>Search: </span>
          <input size="20" name="as_q" />
          <input type="hidden" name="hl" value="en" />
          <input type="hidden" name="ie" value="UTF-8" />
          <input type="hidden" name="btnG" value="Google+Search" />
          <input type="hidden" name="as_qdr" value="all" />
          <input type="hidden" name="as_occt" value="any" />
          <input type="hidden" name="as_dt" value="i" />
          <input type="hidden" name="as_sitesearch" value="blog.saxonica.com" />
        </form>
      </div>
      <div id='blogroll'>
        <a href="/">Home (combined archives)</a><br/>
        <a href="/announcements/">Announcements</a><br/>
        <a href="/mike/">Saxon diaries</a><br/>
        <a href="/oneil/">O’Neil Delpratt’s Blog</a><br/>
        <a href="/norm/">Saxon Chronicles</a>
      </div>
    </div>
  </aside>
</xsl:template>

<!-- Discard comments -->
<xsl:template match="h:div[@class='commentsHead']
                     |h:div[@id='comments_block_id']"/>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

<!-- ============================================================ -->

</xsl:stylesheet>
