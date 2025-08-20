<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:f="http://saxonica.com/ns/functions"
                xmlns:idx="http://saxonica.com/ns/weblog-index"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns="http://www.w3.org/2005/Atom"
                exclude-result-prefixes="f h idx xs"
                version="3.0">

<xsl:import href="format.xsl"/>

<xsl:output method="xml" encoding="utf-8" indent="no"/>

<xsl:param name="author-id" as="xs:string?"/>

<xsl:template match="/">
  <xsl:processing-instruction name="xml-stylesheet"> href="/xslt/atom.xsl" type="text/xsl"</xsl:processing-instruction>
  <feed xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:dcterms="http://purl.org/dc/terms/"
        xml:lang="EN-us">
    <xsl:apply-templates/>
  </feed>
</xsl:template>

<xsl:template match="idx:index[$author-id='norm-tovey-walsh']">
  <title>Saxon Chronicles</title>
  <subtitle>(in a Norman style)</subtitle>
  <link href="https://blog.saxonica.com/norm/" rel="alternate" type="text/html"/>
  <link href="https://blog.saxonica.com/atom/norm.xml" rel="self"/>
  <id>https://blog.saxonica.com/norm/atom.xml</id>
  <updated>
    <xsl:sequence select="adjust-dateTime-to-timezone(
                            current-dateTime(),
                            xs:dayTimeDuration('PT0H'))"/>
  </updated>
  <author>
    <name>Norm Tovey-Walsh</name>
  </author>
  <xsl:apply-templates select="f:select-posts(.)"/>
</xsl:template>

<xsl:template match="idx:index[$author-id='michael-kay']">
  <title>Saxon diaries</title>
  <subtitle>Michael Kay’s blog</subtitle>
  <link href="https://blog.saxonica.com/mike/" rel="alternate" type="text/html"/>
  <link href="https://blog.saxonica.com/atom/mike.xml" rel="self"/>
  <id>https://blog.saxonica.com/mike/atom.xml</id>
  <updated>
    <xsl:sequence select="adjust-dateTime-to-timezone(
                            current-dateTime(),
                            xs:dayTimeDuration('PT0H'))"/>
  </updated>
  <author>
    <name>Michael Kay</name>
  </author>
  <xsl:apply-templates select="f:select-posts(.)"/>
</xsl:template>

<xsl:template match="idx:index[$author-id='oneil-delpratt']">
  <title>O’Neil Delpratt’s Blog</title>
  <subtitle>Saxon, XSLT, XQuery and XML related</subtitle>
  <link href="https://blog.saxonica.com/oneil/" rel="alternate" type="text/html"/>
  <link href="https://blog.saxonica.com/atom/oneil.xml" rel="self"/>
  <id>https://blog.saxonica.com/oneil/atom.xml</id>
  <updated>
    <xsl:sequence select="adjust-dateTime-to-timezone(
                            current-dateTime(),
                            xs:dayTimeDuration('PT0H'))"/>
  </updated>
  <author>
    <name>O’Neil Delpratt</name>
  </author>
  <xsl:apply-templates select="f:select-posts(.)"/>
</xsl:template>

<xsl:template match="idx:index">
  <title>Saxonica Weblogs</title>
  <link href="https://blog.saxonica.com/" rel="alternate" type="text/html"/>
  <link href="https://blog.saxonica.com/atom.xml" rel="self"/>
  <id>https://blog.saxonica.com/atom.xml</id>
  <updated>
    <xsl:sequence select="adjust-dateTime-to-timezone(
                            current-dateTime(),
                            xs:dayTimeDuration('PT0H'))"/>
  </updated>
  <xsl:apply-templates select="f:select-posts(.)"/>
</xsl:template>

<xsl:template match="idx:index[$author-id='announcements']">
  <title>Saxonica announcements</title>
  <link href="https://blog.saxonica.com/announcements/" rel="alternate" type="text/html"/>
  <link href="https://blog.saxonica.com/announcements/atom.xml" rel="self"/>
  <id>https://blog.saxonica.com/announcements/atom.xml</id>
  <updated>
    <xsl:sequence select="adjust-dateTime-to-timezone(
                            current-dateTime(),
                            xs:dayTimeDuration('PT0H'))"/>
  </updated>
  <xsl:apply-templates select="f:select-posts(.)"/>
</xsl:template>

<xsl:template match="idx:post">
  <entry xsl:expand-text="yes">
    <xsl:apply-templates select="idx:title"/>
    <link href="https://blog.saxonica.com/{@href}"
          rel="alternate" type="text/html"/>
    <id>https://blog.saxonica.com/{@href}</id>
    <published>
      <xsl:sequence select="adjust-dateTime-to-timezone(
                              xs:dateTime(idx:pubdate),
                              xs:dayTimeDuration('PT0H'))"/>
    </published>
    <content type="xhtml">
      <xsl:attribute name="xml:base"
                     select="'https://blog.saxonica.com/' ||@href"/>
      <div xmlns="http://www.w3.org/1999/xhtml">
        <xsl:apply-templates 
            select="doc(resolve-uri('../src/' || @href))/*:html/*:body/node()"
            mode="copyhtml"/>
      </div>
    </content>
  </entry>
</xsl:template>

<xsl:template match="idx:title">
  <title>
    <xsl:apply-templates/>
  </title>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

<!-- ============================================================ -->

<xsl:template match="h:h1" mode="copyhtml">
  <!-- If the first h1 is exactly the same as the title, suppress it. -->
  <xsl:if test="preceding::h:h1
                or normalize-space(.) != normalize-space(/h:html/h:head/h:title[1])">
    <xsl:next-match/>
  </xsl:if>
</xsl:template>

<xsl:template match="element()" mode="copyhtml">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()" mode="copyhtml"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()"
              mode="copyhtml">
  <xsl:copy/>
</xsl:template>

<!-- ============================================================ -->

<xsl:function name="f:select-posts">
  <xsl:param name="index" as="element(idx:index)"/>

  <xsl:variable name="posts" as="element()+">
    <xsl:choose>
      <xsl:when test="$author-id = 'announcements'">
        <xsl:sequence select="$index/idx:post[starts-with(@href, 'announcements/')]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="if (exists($author-id))
                              then $index/idx:post[idx:author[@id=$author-id]]
                              else $index/idx:post"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:sequence select="$posts[position() le 30]"/>
</xsl:function>


</xsl:stylesheet>
