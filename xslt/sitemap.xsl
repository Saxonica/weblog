<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs"
                version="3.0">

<xsl:output method="xml" encoding="utf-8" indent="yes"/>

<xsl:template name="xsl:initial-template">
  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <xsl:for-each select="tokenize(unparsed-text('../build/git-data.txt'), '\n')">
      <xsl:variable name="data" select="tokenize(.)"/>
      <xsl:if test="$data[1]">
        <url xsl:expand-text="yes">
          <loc>https://blog.saxonica.com/{substring-after($data[3], 'src/')}</loc>
          <lastmod>{$data[1]}</lastmod>
        </url>
      </xsl:if>
    </xsl:for-each>
  </urlset>
</xsl:template>

<xsl:template match="element()">
  <xsl:copy>
    <xsl:apply-templates select="@*,node()"/>
  </xsl:copy>
</xsl:template>

<xsl:template match="attribute()|text()|comment()|processing-instruction()">
  <xsl:copy/>
</xsl:template>

</xsl:stylesheet>
