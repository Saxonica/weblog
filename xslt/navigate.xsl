<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:f="http://saxonica.com/ns/functions"
                xmlns:idx="http://saxonica.com/ns/weblog-index"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                exclude-result-prefixes="f idx map xs"
                version="3.0">

<xsl:import href="format.xsl"/>

<xsl:output method="xml" encoding="utf-8" indent="yes"/>

<xsl:template name="xsl:initial-template">
  <xsl:variable name="posts" as="map(xs:anyURI, node())">
    <xsl:map>
      <xsl:for-each select="collection($srcdir || '?recurse=yes;select=*.html')">
        <xsl:variable name="path" select="substring-after(base-uri(.), '/src/')"/>
        <xsl:variable name="parts" select="tokenize($path, '/')"/>
        <xsl:choose>
          <xsl:when test="count($parts) = 4
                          and $parts[2] castable as xs:integer
                          and xs:integer($parts[2]) ge 2006
                          and $parts[3] castable as xs:integer
                          and xs:integer($parts[3]) ge 1
                          and xs:integer($parts[3]) le 12">
            <!-- This looks like a posting to me... -->
            <xsl:map-entry key="base-uri(.)" select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message select="'Not a posting: ' || $path"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:map>
  </xsl:variable>

  <xsl:variable name="index" as="element(idx:index)">
    <index xmlns="http://saxonica.com/ns/weblog-index">
      <xsl:for-each select="map:keys($posts)">
        <xsl:sort select="f:post-date($posts(.))" order="descending"/>
        <post href="{.}"/>
      </xsl:for-each>
    </index>
  </xsl:variable>

  <xsl:variable name="index" as="element(idx:index)">
    <index xmlns="http://saxonica.com/ns/weblog-index">
      <xsl:for-each select="$index/idx:post">
        <post href="{substring-after(@href, $srcdir)}">
          <author id="{f:author-token(f:post-author($posts(@href)))}">
            <xsl:sequence select="f:post-author($posts(@href))"/>
          </author>
          <title><xsl:sequence select="f:post-title($posts(@href))"/></title>
          <pubdate><xsl:sequence select="f:post-date($posts(@href))"/></pubdate>
        </post>
      </xsl:for-each>
    </index>
  </xsl:variable>

  <index xmlns="http://saxonica.com/ns/weblog-index">
    <xsl:for-each select="$index/idx:post">
      <xsl:variable name="aid" select="idx:author/@id/string()"/>
      <xsl:variable name="prev" select="following::idx:post[1]/@href/string()"/>
      <xsl:variable name="next" select="preceding::idx:post[1]/@href/string()"/>
      <xsl:variable name="prev-by-author"
                    select="(following::idx:post[idx:author/@id = $aid])[1]/@href/string()"/>
      <xsl:variable name="next-by-author"
                    select="(preceding::idx:post[idx:author/@id = $aid])[1]/@href/string()"/>
      <post href="{@href}">
        <xsl:copy-of select="*"/>
        <xsl:if test="$prev">
          <prev href="{$prev}"/>
        </xsl:if>
        <xsl:if test="$next">
          <next href="{$next}"/>
        </xsl:if>
        <xsl:if test="$prev-by-author">
          <prev-by-author href="{$prev-by-author}"/>
        </xsl:if>
        <xsl:if test="$next-by-author">
          <next-by-author href="{$next-by-author}"/>
        </xsl:if>
      </post>
    </xsl:for-each>
  </index>
</xsl:template>

</xsl:stylesheet>
