<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:f="http://saxonica.com/ns/functions"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:idx="http://saxonica.com/ns/weblog-index"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="f h idx map xs"
                default-mode="html"
                version="3.0">

<xsl:param name="dtformat"
           select="'[MNn] [D01], [Y0001] at [h02]:[m02][P]'"/>

<xsl:variable name="srcdir" select="resolve-uri('../src/', static-base-uri())"/>
<xsl:variable name="builddir" select="resolve-uri('../build/', static-base-uri())"/>
<xsl:variable name="navigation" select="doc($builddir || '/navigation.xml')/idx:index"/>

<!-- ============================================================ -->

<xsl:template name="blog-nav">
  <xsl:param name="feed" as="xs:string?" select="()"/>

  <aside class="nav">
    <div class="navlinks">
      <xsl:if test="$feed">
        <div class="feed">
          <a href="{$feed}">Atom feed</a>
        </div>
      </xsl:if>
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
      <div class='blogroll'>
        <a href="/mike/">Saxon diaries</a><br/>
        <a href="/oneil/">O’Neil Delpratt’s Blog</a><br/>
        <a href="/norm/">Saxon Chronicles</a><br/>
        <a href="/">Combined archives</a>
      </div>
    </div>
  </aside>
</xsl:template>

<xsl:template name="banner">
  <xsl:param name="author" as="xs:string" required="yes"/>

  <div class="banner">
    <xsl:choose>
      <xsl:when test="$author = 'Michael Kay'">
        <h1><a href="/mike/">Saxon diaries</a></h1>
        <div class="tagline">Michael Kay’s blog</div>
      </xsl:when>
      <xsl:when test="$author = 'O’Neil Delpratt'">
        <h1><a href="/oneil/">O'Neil Delpratt's Blog</a></h1>
        <div class="tagline">Saxon, XSLT, XQuery and XML related</div>
      </xsl:when>
      <xsl:when test="$author = 'Norm Tovey-Walsh'">
        <h1><a href="/norm/">Saxon Chronicles</a></h1>
        <div class="tagline">( in a Norman style )</div>
      </xsl:when>
      <xsl:otherwise>
        <!-- nop -->
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

<!-- ============================================================ -->

<xsl:function name="f:author-token" as="xs:string">
  <xsl:param name="author" as="xs:string"/>
  <xsl:sequence select="$author
                        => lower-case()
                        => normalize-space()
                        => replace('[^-\p{L} ]', '')
                        => translate(' ', '-')"/>
</xsl:function>

<xsl:function name="f:post-author" as="xs:string?">
  <xsl:param name="context" as="node()"/>
  <xsl:sequence select="$context/root()/h:html/h:head
                        /h:meta[@name='author']/@content/string()"/>
</xsl:function>

<xsl:function name="f:post-title" as="node()*">
  <xsl:param name="post" as="node()"/>
  <xsl:variable name="title" select="($post/root()/h:html/h:head/h:title)[1]"/>
  <xsl:variable name="h1" select="($post/root()/h:html/h:body/h:h1)[1]"/>

  <xsl:choose>
    <xsl:when test="$h1">
      <xsl:sequence select="$h1/node()"/>
    </xsl:when>
    <xsl:when test="$title">
      <xsl:sequence select="$title/node()"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="'No title?'"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="f:post-date" as="xs:dateTime">
  <xsl:param name="post" as="node()"/>
  <xsl:variable name="date" select="($post/root()/h:html/h:head
                                    /h:meta[@name='pubdate']/@content/string())[1]"/>

  <xsl:choose>
    <xsl:when test="empty($date) or not($date castable as xs:dateTime)">
      <xsl:sequence select="current-dateTime()"/> <!-- ??? -->
    </xsl:when>
    <xsl:otherwise>
      <xsl:sequence select="xs:dateTime($date)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:function>

<xsl:function name="f:previous-post" as="element(h:html)?" cache="yes">
  <xsl:param name="post" as="element(h:html)"/>
  <xsl:variable name="href" select="substring-after(base-uri($post), $srcdir)"/>
  <xsl:variable name="post" select="key('posts', $href, $navigation)"/>
  <xsl:if test="$post/idx:prev">
    <xsl:sequence select="doc($srcdir || $post/idx:prev/@href)/h:html"/>
  </xsl:if>
</xsl:function>

<xsl:function name="f:next-post" as="element(h:html)?" cache="yes">
  <xsl:param name="post" as="element(h:html)"/>
  <xsl:variable name="href" select="substring-after(base-uri($post), $srcdir)"/>
  <xsl:variable name="post" select="key('posts', $href, $navigation)"/>
  <xsl:if test="$post/idx:next">
    <xsl:sequence select="doc($srcdir || $post/idx:next/@href)/h:html"/>
  </xsl:if>
</xsl:function>

<xsl:function name="f:date-index" as="xs:string">
  <xsl:param name="date" as="xs:dateTime"/>
  <xsl:param name="token" as="xs:string"/>
  <xsl:variable name="fragid"
                select="format-dateTime($date, 'D[Y0001]-[M01]')"/>
  <xsl:sequence select="'/authors.html#' || $token || '-' || $fragid"/>
</xsl:function>

</xsl:stylesheet>
