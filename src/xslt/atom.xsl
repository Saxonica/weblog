<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xs"
                version="1.0">

<xsl:output method="html" encoding="utf-8" indent="no"/>

<xsl:template match="atom:feed">
  <html>
    <head>
      <title><xsl:value-of select="atom:title"/></title>
      <link rel="stylesheet" href="/css/atom.css"/>
    </head>
    <body>
      <h1><xsl:value-of select="atom:title"/></h1>
      <xsl:apply-templates select="atom:subtitle"/>
      <xsl:apply-templates select="atom:link[@type='text/html' and @rel='alternate']"/>
      <xsl:apply-templates select="atom:updated"/>
      <xsl:apply-templates select="atom:entry"/>
    </body>
  </html>
</xsl:template>

<xsl:template match="atom:subtitle">
  <h2 class="subtitle">
    <xsl:apply-templates/>
  </h2>
</xsl:template>

<xsl:template match="atom:link">
  <p>
    <a href="{@href}">
      <xsl:value-of select="@href"/>
    </a>
  </p>
</xsl:template>

<xsl:template match="atom:updated">
  <p>
    <xsl:value-of select="substring(., 1, 10)"/>
  </p>
</xsl:template>

<xsl:template match="atom:entry">
  <div class="entry">
    <details>
      <summary>
        <a href="{atom:link/@href}">
          <xsl:value-of select="atom:title"/>
        </a>
        <xsl:text>, </xsl:text>
        <xsl:value-of select="substring(atom:published, 1, 10)"/>
      </summary>
      <div class="body">
        <xsl:apply-templates select="atom:content[@type='xhtml']/node()" mode="html"/>
      </div>
    </details>
  </div>
</xsl:template>

<xsl:template match="*" mode="html">
  <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1999/xhtml">
    <xsl:apply-templates mode="html"/>
  </xsl:element>
</xsl:template>

</xsl:stylesheet>

<!--
   <entry>
      <title>Ordered Maps and JNodes</title>
      <link href="https://blog.saxonica.com/mike/2025/08/implementing-jnodes.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/mike/2025/08/implementing-jnodes.html</id>
      <published>2025-08-19T09:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/mike/2025/08/implementing-jnodes.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Ordered Maps and JNodes</h1>
            <p>Since I last wrote about <a href="https://blog.saxonica.com/mike/2024/12/ordered-maps.html">ordered maps</a>,
        the XPath 4.0 specifications have now introduced the idea of JNodes, which adds a new set of 
        requirements to the specification.</p>
            <p>I wrote about JNodes in <a href="https://www.balisage.net/Proceedings/vol30/html/Kay01/BalisageVol30-Kay01.html">my paper at Balisage 2025</a>, 
        and I won't repeat the introduction here. Suffice it to say that a JNode can wrap a specific entry in an XDM
        map, and it allows you (among other things) to:</p>
            <ol>
               <li>Establish which of two entries in the same map comes first in document order (or equivalently,
            in map order);</li>
               <li>Get the preceding or following siblings of a map entry (the entries that precede it or follow it 
                in map order).</li>
            </ol>
            <p>The prototype implementation of JNodes that I demonstrated at Balisage included support for these
        operations, but the implementation would be hopelessly inefficient in production. The current implementation
        of ordered maps on the Saxon 13 development branch uses the <code>LinkedHashMap</code> implementation
            from the VAVR library, and this doesn't have anything that would support either of these operations.</p>
            <p>I'm therefore proposing to use a home-grown map implementation as described below.</p>
            <p>First note that <code>map:put</code> and <code>map:remove</code> operations are rare, and it's OK
        to have a map implementation that allows the map to be constructed by a mutable builder class in one phase of operation,
        and thereafter to be read-only. If a <code>map:put</code> or <code>map:remove</code> operation is attempted,
        we can rebuild the map using a different (immutable | persistent | functional) data structure. 
        So let's first consider a structure that 
        doesn't support <code>map:put</code> and <code>map:remove</code> operations directly. I'm calling this
        a <code>FixedMap</code>.</p>
            <p>A <code>FixedMap</code> is underpinned by three Java structures:</p>
            <ul>
               <li>
                  <code>keys</code>: An array of keys: type <code>AtomicValue[]</code>.</li>
               <li>
                  <code>values</code>: An array of values: type <code>GroundedValue[]</code>.</li>
               <li>
                  <code>index</code>: A map from atomic match keys to integers: type <code>Map&lt;AtomicMatchKey, Integer&gt;&gt;</code>.
            Note that this map doesn't need to be ordered. The class <code>AtomicMatchKey</code> is a surrogate
            for an XDM atomic value whose Java <code>equals()</code> method respects the XDM equality
            semantics: for example, if the key is an <code>xs:string</code> then the <code>AtomicMatchKey</code>
            is an instance of Saxon's <code>UnicodeString</code> class.</li>
            </ul>
            <p>The basic operations on XDM maps are simply and efficiently implemented as follows:</p>
            <ul>
               <li>Get the value corresponding to a given key: set <code>i = index.get(key)</code>;
                return if <code>i == null</code> then <code>null</code> else <code>values[i]</code>.</li>
               <li>Get all keys in map order: iterate over <code>keys</code>.</li>
               <li>Get all values in map order: iterate over <code>values</code>.</li>
            </ul>
            <p>The new operations required to support JNode navigation can also be efficiently implemented:</p>
            <ul>
               <li>Determine which of two entries with keys <code>X</code> and <code>Y</code> is first in document
                order: compare <code>index.get(X)</code> with <code>index.get(Y)</code> (an integer comparison).</li>
               <li>Get preceding or following siblings of an entry with key <code>X</code>: find <code>index.get(X)</code>
            and then iterate forwards or backwards in the <code>keys</code> and <code>values</code> arrays
            from this integer offset.</li>
            </ul>
            <p>All very straightforward. Now, what about <code>map:put</code> and <code>map:remove</code>?</p>
            <p>When one of these operations occurs, I propose to copy the <code>FixedMap</code> to an
        <code>ExtensibleMap</code>. This will have a very similar structure to the <code>FixedMap</code>, except
        that:</p>
            <ul>
               <li>The arrays of keys and values are replaced by immutable lists of keys and values. 
            I propose to implement these immutable lists using the existing Saxon class <code>ZenoChain</code>.
            This is described in a <a href="https://blog.saxonica.com/mike/2021/03/zeno_chains.html">previous blog</a>.    
            This uses the same logic as the <code>ZenoString</code> which I introduced in 
            <a href="https://www.balisage.net/Proceedings/vol26/html/Kay01/BalisageVol26-Kay01.html">a 2021 Balisage paper.</a>
            It provides efficient support for getting an entry at a particular integer offset, and for appending
            individual entries at the end of the list: therefore for <code>map:get</code> and <code>map:put</code>.</li>
               <li>The map from <code>AtomicMatchKey</code> to <code>Integer</code> is replaced by an immutable map.
            There are plenty of implementations available (we could revert to the Michael Froh implementation
            used in earlier Saxon releases), because there is no need for this structure to support ordering.</li>
            </ul>
            <p>The design relies on the fact that adding or removing entries to the map does not change the integer
        offset of existing entries. That's fine for <code>map:put</code>, which always puts new entries at the end
        (in terms of map ordering). To support <code>map:remove</code>, I propose to keep a separate list holding
        the integer offsets of map entries that have been removed; a traversal of the map keys or arrays needs
        to check this list and skip an entry if it is present. When the number of removed entries exceeds some
        threshold (a rare event) we can rebuild the map from scratch.</p>
            <p>The new design looks as if all the main operations perform in constant or logarithmic time, with traversal
        of the map in linear time; and it seems to be reasonably economical in terms of memory usage.</p>
            <p>The design allows the use of an optimization whereby the index (from atomic match keys to integer offsets)
        is built lazily, the first time <code>map:get</code> is called. This is useful when processing JSON, because
        it's likely that many maps constructed during JSON parsing will either be copied unchanged to the
        transformation output, or will never be referenced at all, so the work needed to construct an index can be
        saved (it's still necessary to check for duplicate keys, but this can be done cheaply with a simple Bloom
        filter).</p>
            <p>We currently have an optimized implementation of maps for cases where all the keys are known in advance
        to be instances of <code>xs:string</code>. This can potentially save a bit of space because in place
            of the <code>StringValue</code> representing each string-valued key, we can simply store the underlying
            <code>UnicodeString</code>. This saves holding the wrapper object and the type annotation, which can
            be significant in the case of very large maps.</p>
            <p>One of the benefits of this design is that it reduces our dependencies on third-party code, which in
        turn simplifies porting Saxon across different platforms, and transpiling to C# for the .NET platform.
        In the current Saxon 13 code base, we're not only dependent on the VAVR library, but we're actually
        dependent on a fork of that library that uses a different implentation of linked hash maps, to avoid
        a <a href="https://github.com/vavr-io/vavr/issues/2727">performance bug</a>.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>SaxonC Python 12.8 for Python 3.14</title>
      <link href="https://blog.saxonica.com/announcements/2025/08/saxon-12.8-for-python-3.14.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/08/saxon-12.8-for-python-3.14.html</id>
      <published>2025-08-14T11:15:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/08/saxon-12.8-for-python-3.14.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>With the recent release of Python 3.14.0rc1, the ABI for Python 3.14 is
final, and any SaxonC Python wheels we build against it will also work with
the final 3.14 release. The TL;DR is that we’ve done that, and you can
<code>pip install saxonche</code> (or <code>saxoncee</code> /
<code>saxoncpe</code>) with the 3.14.0rc1 release right now.</p>
            <p>The Python 3.13 release was trickier for us to deal with than it should have
been – our build processes required a lot more manual intervention for different
Python versions than we liked, and we had to wait for a new Saxon release to get
wheels built for Python 3.13, which was frustrating.</p>
            <p>We’ve been working on improving our build processes and making  it easier to
build Python wheels across all the platforms and Python versions we support. Easy
enough, in fact, that we were able to test Python 3.14 support back at the beta
stage, and were ready to build SaxonC Python 12.8 against 3.14 as soon as the RC
dropped and the ABI was stable.</p>
            <p>These new wheels were built from the same commit as the all the other SaxonC
Python 12.8 wheels for Python 3.9-3.13. We’d love for you to install 12.8 for 3.14
and kick the tires: since Python 3.14 is still RC and not at the final release stage,
there may be some problems we haven't come across. If you run into any problems,
please report them on the
<a href="https://saxonica.plan.io/projects/saxon-c/issues">SaxonC issue tracker</a>.
</p>
            <p>There are wheels for the same platforms as always – macOS x86_64 and arm64,
Linux x86_64 and aarch64, and Windows x86_64. For macOS x86_64, Python 3.14 now
requires macOS 11 or later. As a result, Python 3.14 wheels of SaxonC Python 12.8
require macOS 11 or later on x86_64 too.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Saxon 11.7 and 12.8</title>
      <link href="https://blog.saxonica.com/announcements/2025/07/saxon-11.7-and-12.8.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/07/saxon-11.7-and-12.8.html</id>
      <published>2025-07-03T17:40:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/07/saxon-11.7-and-12.8.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>The accompanying release announcements for
<a href="saxon-11.7.html">Saxon 11.7</a> and
<a href="saxon-12.8.html">Saxon 12.8</a> describe those
releases in detail. This post summarizes why we decided that we
needed to release them both this week.</p>
            <p>Some applications are known to use Saxon to run untrusted, user-submitted
stylesheets or queries. Running untrusted code always entails some risk. Saxon
provides two
<a href="https://www.saxonica.com/documentation12/index.html#!configuration/config-features">features</a>
designed to help mitigate this risk: <code>ALLOWED_PROTOCOLS</code> and

<code>ALLOW_EXTERNAL_FUNCTIONS</code>. Setting <code>ALLOWED_PROTOCOLS</code>
can limit what resources a stylesheet or query can access; it can for example,
forbid access to file: URIs. The <code>ALLOW_EXTERNAL_FUNCTIONS</code> feature
can disable access to reflexive Java extension functions, some system
properties, and some other extension functions. (The remit of the
<code>ALLOW_EXTERNAL_FUNCTIONS</code> feature is a little wider than you might
expect.)</p>
            <p>Unfortunately, we discovered a function in Saxon 11 and 12 that was not
adequately controlled by these features. In principle, a stylesheet or query
running in Saxon-PE or Saxon-EE could access the local filesystem even if the
<code>ALLOWED_PROTOCOLS</code> feature was set to forbid such access. The risk
is small: it only applies to untrusted code running in Saxon-PE or Saxon-EE (it
does not apply to Saxon-HE) on a system where reading from the local filesystem
would be deemed a risk. (We would encourage anyone running untrusted code to use
a sandboxed environment where there is no data on the filesystem that needs to
be protected from read access.)</p>
            <p>Although we judge the risk to be small, At Saxonica, we take security
seriously and we are publishing maintenance releases of Saxon 11 and Saxon 12 to
close this gap. We urge anyone running untrusted stylesheets or queries under
Saxon-PE or Saxon-EE to move to version 11.7 or 12.8 immediately.</p>
            <p>This bug is present in the Java, C#, C, C++, Python and PHP products. It is
not present in Saxon 10 (including the Saxon.NET 10) or in earlier releases. It
is not present in SaxonJS.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing Saxon 12.8!</title>
      <link href="https://blog.saxonica.com/announcements/2025/07/saxon-12.8.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/07/saxon-12.8.html</id>
      <published>2025-07-03T17:35:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/07/saxon-12.8.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing Saxon 12.8!</h1>
            <p>The Saxon 12.8 maintenance release has been published.
This is a
maintenance release for Java, C#, C/C++, PHP, and Python that
<a href="saxon-11.7-and-12.8.html">fixes a security gap</a> and a few
other issues that have been addressed since 12.7 was released.</p>
            <p>Saxon 12.8 was released on 3 July 2025. This release has been uploaded to the
usual locations on the Saxonica website, GitHub, and Maven, PyPi, and NuGet.
SaxonCS 12.8 is built with .NET 8.</p>
            <p>For a list of the issues resolved in this release, please visit the issue trackers
for
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=103&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonJ and SaxonCS</a> or
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=104&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonC</a>
on the Saxon support site.
</p>
            <p>Download products:</p>
            <ul>
               <li>Binaries for PE and EE are available from our
<a href="http://www.saxonica.com/download/download_page.xml">download pages</a>.
</li>
               <li>SaxonJ-HE is available on the
<a href="https://central.sonatype.com/artifact/net.sf.saxon/Saxon-HE/12.8">Maven Central
repository</a>.
</li>
               <li>SaxonJ-HE, PE, and EE can also be found on our
<a href="https://dev.saxonica.com/maven/">experimental Maven repository</a>.
</li>
               <li>Python wheels for SaxonC (HE, PE, and EE) are available from
<a href="https://pypi.org/user/saxonica/">PyPI</a>.
</li>
               <li>SaxonCS is available on
<a href="https://www.nuget.org/packages/SaxonCS">NuGet</a>
               </li>
               <li>Saxon-HE is available from our open source
<a href="https://github.com/Saxonica/Saxon-HE/">GitHub repository</a>.
The GitHub repository also provides source code for those who need it.
</li>
            </ul>
            <p>For more details, please consult
<a href="https://www.saxonica.com/documentation12">the documentation</a>.
</p>
            <h2>Issues resolved</h2>
            <p>In addition to the security issue, only a few other issues have been fixed;
our focus was on getting the security release out promptly.</p>
            <h3>Issues in SaxonJ</h3>
            <p>Only one additional issue was fixed in SaxonJ:</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6804">6804</a>
    String index out-of-bounds in <code>parse-xml()</code>
               </li>
            </ul>
            <h3>Issues in SaxonC</h3>
            <p>A few small issues were fixed in SaxonC:</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6835">6835</a>
    SaxonC PHP @@VERSION@@</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6830">6830</a>
    SaxonC HE 12.7.0 - PHP - XdmNode-&gt;getColumnNumber() returns the line number</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6823">6823</a>
    DocumentBuilder memory not deleted</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6803">6803</a>
    Please provide parseJsonFromString example</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6802">6802</a>
    Remove XdmAtomicValue::getStringValue</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6801">6801</a>
    PRIMITIVE_TYPE defined, but not used?</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6800">6800</a>
    Implement operator== for XdmItem or make it private</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6785">6785</a>
    Instructions in Python README for running pytest are missing the use of a pytest.ini</li>
            </ul>
            <p>If you encounter any issues with Saxon 12.8, please
<a href="https://saxonica.plan.io/projects/saxon/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing Saxon 11.7!</title>
      <link href="https://blog.saxonica.com/announcements/2025/07/saxon-11.7.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/07/saxon-11.7.html</id>
      <published>2025-07-03T17:30:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/07/saxon-11.7.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing Saxon 11.7!</h1>
            <p>The Saxon 11.7 maintenance release has been published.
This is a
maintenance release for Java, C#, C/C++, PHP, and Python that
<a href="saxon-11.7-and-12.8.html">fixes a security gap</a> and a number of
other issues that have been addressed since 11.6 was released.</p>
            <p>Saxon 11.7 was released on 3 July 2025. This release has been
uploaded to the usual locations on the Saxonica website, GitHub,
Maven, and NuGet. SaxonCS 11.7 is built with .NET 8.</p>
            <p>For a list of the issues resolved in this release, please visit the
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=102&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">issue tracker</a>
on the Saxon support site.
</p>
            <p>Download products:</p>
            <ul>
               <li>Binaries for PE and EE are available from our
<a href="http://www.saxonica.com/download/download_page.xml">download pages</a>.
</li>
               <li>SaxonJ-HE is available on the
<a href="https://central.sonatype.com/artifact/net.sf.saxon/Saxon-HE/11.7">Maven Central
repository</a>.
</li>
               <li>SaxonJ-HE, PE, and EE can also be found on our
<a href="https://dev.saxonica.com/maven/">experimental Maven repository</a>.
</li>
               <li>SaxonCS is available on
<a href="https://www.nuget.org/packages/SaxonCS">NuGet</a>
               </li>
               <li>Saxon-HE is no longer distributed on SourceForge. It is now available from
our open source
<a href="https://github.com/Saxonica/Saxon-HE/">GitHub repository</a>.
The GitHub repository also provides source code for those who need it.
</li>
            </ul>
            <p>For more details, please consult
<a href="https://www.saxonica.com/documentation11">the documentation</a>.
</p>
            <p>If you encounter any issues with Saxon 11.7, please
<a href="https://saxonica.plan.io/projects/saxon/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing SaxonJS-HE 3.0.0-beta2!</title>
      <link href="https://blog.saxonica.com/announcements/2025/06/saxonjs-3.0.0-beta2.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/06/saxonjs-3.0.0-beta2.html</id>
      <published>2025-06-02T13:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/06/saxonjs-3.0.0-beta2.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing SaxonJS-HE 3.0.0-beta2!</h1>
            <p>SaxonJS 3.0 is a major update to the SaxonJS product. In June 2025, we are
publishing a second preview release, version 3.0.0-beta2. This is a preview
release of the SaxonJS 3.0 HE (Home Edition) product. An EE (Enterprise Edition)
product is in the works.
</p>
            <div>
               <h2>New features in the beta2 release</h2>
               <p>This release includes a few bug fixes from the first beta.
</p>
               <ul>
                  <li>
                     <a href="https://saxonica.plan.io/issues/5923">5923</a>
   Provide a way to control event listener parameters</li>
                  <li>
                     <a href="https://saxonica.plan.io/issues/6599">6599</a>
   Sequence interacts badly with try/catch</li>
                  <li>
                     <a href="https://saxonica.plan.io/issues/6697">6697</a>
   Checksum checking in SaxonJS 3</li>
                  <li>
                     <a href="https://saxonica.plan.io/issues/6742">6742</a>
   Untethered promises with SaxonJS 3.0.0-beta1</li>
               </ul>
               <p>Of these, the most consequential is probably 6697. In the course of fixing a
bug related to SEF files produced for SaxonJS 2, we introduced a bug where
SaxonJ 12.6 couldn’t produce SEF files for SaxonJS 3.0 beta1! That’s been fixed.
You can now produce SEF files for SaxonJS 3.0 beta2 with Saxon 12.6 or later.
(Unfortunately, you can’t produce SEF files for SaxonJS 3.0 beta2 with SaxonJ
12.5 or earlier!)
</p>
               <div>
                  <h2>Getting started</h2>
               </div>
               <p>You can try out SaxonJS-HE 3.0 today, the packages have been uploaded to
<a href="https://www.npmjs.com/">npmjs.com</a>: 
<a href="https://www.npmjs.com/package/saxonjs-he">saxonjs-he</a>
and 
<a href="https://www.npmjs.com/package/xslt3-he">xslt3-he</a>. You can also
download them <a href="https://downloads.saxonica.com/SaxonJS/3/index.html">our website</a>.</p>
               <p>Our <a href="https://www.saxonica.com/saxonjs/documentation3/index.html">documentation
pages</a> have been updated.</p>
               <p>Please report any issues that you encounter on <a href="https://saxonica.plan.io/projects/saxon-js/issues">our issue tracker</a>.
</p>
            </div>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing Saxon 12.7!</title>
      <link href="https://blog.saxonica.com/announcements/2025/05/saxon-12.7.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/05/saxon-12.7.html</id>
      <published>2025-05-16T10:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/05/saxon-12.7.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing Saxon 12.7!</h1>
            <p>The Saxon 12.7 maintenance release has been published. This is a maintenance
release for Java, C#, C/C++, PHP, and Python that addresses a few significant
shortcomings in the Saxon 12.6 release.
</p>
            <p>Saxon 12.7 was released on 16 May 2025. This release has been uploaded to the
usual locations on the Saxonica website, GitHub, and Maven, PyPi, and NuGet.
SaxonCS 12.7 is built with .NET 8.</p>
            <p>For a list of the issues resolved in this release, please visit the issue trackers
for
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=101&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonJ and SaxonCS</a> or
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=100&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonC</a>
on the Saxon support site.
</p>
            <p>Download products:</p>
            <ul>
               <li>Binaries for PE and EE are available from our
<a href="http://www.saxonica.com/download/download_page.xml">download pages</a>.
</li>
               <li>SaxonJ-HE is available on the
<a href="https://central.sonatype.com/artifact/net.sf.saxon/Saxon-HE/12.7">Maven Central
repository</a>.
</li>
               <li>SaxonJ-HE, PE, and EE can also be found on our
<a href="https://dev.saxonica.com/maven/">experimental Maven repository</a>.
</li>
               <li>Python wheels for SaxonC (HE, PE, and EE) are available from
<a href="https://pypi.org/user/saxonica/">PyPI</a>.
</li>
               <li>SaxonCS is available on
<a href="https://www.nuget.org/packages/SaxonCS">NuGet</a>
               </li>
               <li>Saxon-HE is available from our open source
<a href="https://github.com/Saxonica/Saxon-HE/">GitHub repository</a>.
The GitHub repository also provides source code for those who need it.
</li>
            </ul>
            <p>For more details, please consult
<a href="https://www.saxonica.com/documentation12">the documentation</a>.
</p>
            <h2>Issues resolved</h2>
            <p>The substantial changes in this release are:</p>
            <ol>
               <li>We’ve returned to supporting JDK 8 in 12.7. The decision to move to JDK 11
in 12.6 was intentional, but perhaps too eager. Fair warning: it is very
unlikely that Saxon 13 will be released with support for JDK 8.</li>
               <li>We worked around a bug that caused the SaxonC products to fail under X86 emulation
on Windows/ARM. (The bug is that Windows emulation doesn’t support some modern
instructions that GraalVM was generating. We worked around it by turning down some
GraalVM optimizations in that environment.)</li>
            </ol>
            <h3>Issues in SaxonJ and SaxonCS</h3>
            <p>These are just the release highlights, for a full list, see
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=101&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6547">6547</a>
    Resolved some schema loading performance regressions</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6771">6771</a>
    Restored JDK 8 compatibility to the class files</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6776">6776</a>
    Resolved a null pointer exception</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6778">6778</a>
    Fixed the class name in the javax.xml.validation.SchemaFactory service</li>
            </ul>
            <h3>Issues in SaxonC</h3>
            <p>In addition to the X86 emulation problem, we resolved a few more issues in SaxonC.
For a full list, see
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=%3D&amp;v%5Bstatus_id%5D%5B%5D=3&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=100&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6443">6443</a>
    Fixed a bug in Python PySaxonProcessor.make_atomic_value</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6522">6522</a>
    The documentation for Saxon\SchemaValidator is incorrect</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6525">6525</a>
    Fixed XdmNode::getChildren()</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6526">6526</a>
    Fixed xdmNode-&gt;axisNodes(3) on PHP</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6536">6536</a>
    Fixed segmentation fault with Python SaxonCHE 12.5</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6780">6780</a>
    Accepted suggestion to set sxn_environ values to NULL after allocation</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6781">6781</a>
    Fixed crash on Windows 11 under x86 emulation on ARM</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6787">6787</a>
    The setCatalogFiles method was missing from the C API</li>
            </ul>
            <p>If you encounter any issues with Saxon 12.7, please
<a href="https://saxonica.plan.io/projects/saxon/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing Saxon 12.6!</title>
      <link href="https://blog.saxonica.com/announcements/2025/05/saxon-12.6.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2025/05/saxon-12.6.html</id>
      <published>2025-05-02T15:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2025/05/saxon-12.6.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing Saxon 12.6!</h1>
            <p>The Saxon 12.6 maintenance release has been published. This is a maintenance
release for Java, C#, C/C++, PHP, and Python that addresses well over 100 issues
and feature requests reported since the Saxon 12.5 release.
</p>
            <p>Saxon 12.6 was released on 2 May 2025. This release has been uploaded to the
usual locations on the Saxonica website, GitHub, and Maven, PyPi, and NuGet.
SaxonCS 12.6 is built with .NET 8.</p>
            <p>For a list of the issues resolved in this release, please visit the issue trackers
for
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=98&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonJ and SaxonCS</a> or
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=99&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonC</a>
on the Saxon support site.
</p>
            <p>Download products:</p>
            <ul>
               <li>Binaries for PE and EE are available from our
<a href="http://www.saxonica.com/download/download_page.xml">download pages</a>.
</li>
               <li>SaxonJ-HE is available on the
<a href="https://central.sonatype.com/artifact/net.sf.saxon/Saxon-HE/12.6">Maven Central
repository</a>.
</li>
               <li>SaxonJ-HE, PE, and EE can also be found on our
<a href="https://dev.saxonica.com/maven/">experimental Maven repository</a>.
</li>
               <li>Python wheels for SaxonC (HE, PE, and EE) are available from
<a href="https://pypi.org/user/saxonica/">PyPI</a>.
</li>
               <li>SaxonCS is available on
<a href="https://www.nuget.org/packages/SaxonCS">NuGet</a>
               </li>
               <li>Saxon-HE is available from our open source
<a href="https://github.com/Saxonica/Saxon-HE/">GitHub repository</a>.
The GitHub repository also provides source code for those who need it.
</li>
            </ul>
            <p>For more details, please consult
<a href="https://www.saxonica.com/documentation12">the documentation</a>.
</p>
            <h2>Partial list of issues resolved</h2>
            <p>This section is a subset of the complete list of resolved issues.
It’s curated to bring attention to the bugs that seem most likely to
impact customers. 
</p>
            <h3>Issues in SaxonJ and SaxonCS</h3>
            <p>In addition to the individual issues listed below, this release fixes
several issues related to streaming transformations and several issues
related to tracing.</p>
            <p>For a full list, see
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=98&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6748">6748</a>
    Updated xsl:array to track the evolving QT4CG specifications</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6746">6746</a>
    Resolved errors related to version ranges in xsl:use-package/@package-version</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6724">6724</a>
    Clarified limitations on importing schemas for reserved namespaces (such as fn:)</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6711">6711</a>
    Clarified how setting allowedProtocols to restrict parse-xml is handled</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6696">6696</a>
    Resolved a concurrency issue during lazy evaluation</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6688">6688</a>
    Fixed a bug where the coverage report from XSpec creates XML that is not well formed</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6682">6682</a>
    Resolved an issue in XSD uniqueness constraints vs. key constraints</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6679">6679</a>
    Fixed a bug where an incorrect variable was accessed when using xsl:iterate within xsl:accumulator</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6671">6671</a>
    Resolved an issue during schema load with multiple imports</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6652">6652</a>
    parse-xml no longer fails if the string it’s parsing begins with a BOM</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6621">6621</a>
    Clarified how reflexive extension functions and varargs work</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6597">6597</a>
    Fixed a bug where calling getBaseUri() in the Axiom tree model triggers infinite recursion</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6577">6577</a>
    Resolved an issue related to xsl:where-populated and namespace fixup</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6565">6565</a>
    Fixed a performance regression in DocumentFn with Java 12 or higher</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6544">6544</a>
    Fixed a bug where ID/IDREF attributes were not recognized when using the StAX parser</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6543">6543</a>
    Fixed a bug where whitespace text nodes were reported incorrectly when using a pull parser</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6537">6537</a>
    Fixed incorrect rounding of negative xs:double values</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6504">6504</a>
    Clarified how collection() and uri-collection() handle invalid URIs</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6502">6502</a>
    Fixed a bug where several invalid patterns were accepted</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6494">6494</a>
    Fixed a bug where whitespace text output disappeared when indenting</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6489">6489</a>
    Fixed Gizmo issue with prefix, precede, suffix, and follow commands</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6480">6480</a>
    Cardinality of sequences returned by extension functions are now validated</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6472">6472</a>
    Fixed a bug related to sort order in xsl:for-each-group in named templates</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6471">6471</a>
    Corrected the operator precedence of validate expressions</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6452">6452</a>
    Fixed round#2 and round-half-to-even#2 to give correct results on large negative integers</li>
            </ul>
            <h3>Issues in SaxonC</h3>
            <p>In the SaxonC 12.6 release, we have included a compiled C++ API library
(.dll, .so, .dylib as appropriate) along with accompanying CMake files to
simplify integration into C++ applications. This is provided in addition to the
core SaxonC library, which continues to be cross-compiled using GraalVM.</p>
            <p>To use SaxonC in a C++ project, users now only need the two compiled library
files and the header files—greatly reducing setup complexity. Integrating with a
project already using CMake is as simple as using FindPackage(SaxonCHE 12.6.0)
(Or SaxonCEE, or SaxonCPE, if using the EE or PE editions). A sample CMake
project is provided with the samples in the download ZIP.</p>
            <p>This change applies only to the C++ API. It does not affect the PHP or Python extensions:</p>
            <dl>
               <dt>PHP</dt>
               <dd>Installation instructions are included in the README file in the download
ZIP and also available in the online documentation.</dd>
               <dt>Python</dt>
               <dd>The extension is distributed as pre-built wheels via PyPI, making
installation straightforward using pip.</dd>
            </dl>
            <p>In addition to the individual issues listed below, this release fixes a
number of multithreading issues, encoding problems, and memory leaks. API
support has been added for getcwd, getProperty/getProperties, and
getJustInTimeCompilation on several objects. There have also been a number
of documentation improvements.</p>
            <p>For a full list, see
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=99&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6731">6731</a>
    Support adding properties to the Processor in the Saxon C API</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6695">6695</a>
    Fixed an issue related to creating maps of strings in Python</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6677">6677</a>
    Improve error messages associated with Xslt30Processor::compileFromString</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6676">6676</a>
    Support initial template invocation with a combination of tunnel and non-tunnel parameters</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6668">6668</a>
    Support setOutputFile() on SchemaValidator</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6657">6657</a>
    Fixed line and column numbers in PySaxonApiError message</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6656">6656</a>
    Fixed a bug where multiple calls to XdmNode.getParent() could leads to an exception</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6649">6649</a>
    Improved error message associated with an expired license</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6634">6634</a>
    Added support for getcwd and getProperties</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6628">6628</a>
    Fixed a bug where the copy constructor for Xdm objects failed</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6620">6620</a>
    Fixed a double-free bug in clearSettings</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6619">6619</a>
    Resolved missing calls to super constructors</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6618">6618</a>
    Fixed a bug where getDoubleValue crashed for text strings in XdmAtomicValue class</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6615">6615</a>
    Fixed a bug where isEmpty crashed for new empty XdmMap</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6614">6614</a>
    Fixed a bug where the XdmValue::XdmValue constructor crashed</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6606">6606</a>
    Fixed a bug related to cwd and static-base-uri() in XPath</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6605">6605</a>
    Fixed a bug in static-base-uri() when compiling a query from a string</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6575">6575</a>
    Resolved a bug where som exception messages were empty in the PHP API</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6573">6573</a>
    Added isMap, isArray and isFunction methods to the PHP API</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6562">6562</a>
    Fixed issues related to mapSize when casting XdmValue from parseJson to XdmMap</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6556">6556</a>
    Fixed a bug where the standardErrorOutputFile feature was ignored</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6539">6539</a>
    Support PyXdmMap and PyXdmArray on PySaxonProcessor.parse_json</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6475">6475</a>
    Fixed a bug where the PySchemaValidator did not handle an XdmNode input correctly</li>
            </ul>
            <p>If you encounter any issues with Saxon 12.6, please
<a href="https://saxonica.plan.io/projects/saxon/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>21st Anniversary Flash Sale!</title>
      <link href="https://blog.saxonica.com/norm/2025/02/06-flash.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/norm/2025/02/06-flash.html</id>
      <published>2025-02-06T14:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/norm/2025/02/06-flash.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>21<sup>st</sup> Anniversary Flash Sale!</h1>
            <img alt="Saxon at 21 Flash Sale banner"
                 class="sale"
                 src="/img/saxon21.jpg"/>
            <p>Saxonica was incorporated twenty-one years ago, in February 2004. To
celebrate, we’re having a flash sale. For one weekend only, a Saxon license
is just <span title="Base 2 is just like base 10… if you're missing 8 fingers">£101.01</span>!<sup>
                  <a class="tandclink" href="#tandc">*</a>
               </sup>
            </p>
            <p>A lot has changed since Michael Kay founded Saxonica. Our flagship Java
product has been joined by C, C++, C#, JavaScript, PHP, and Python products.
We’re now delivering applications and tools for three platforms across five
architectures. Our team has grown, and our business has evolved. But what hasn’t
changed is our dedication to being an industry-leading provider of XML
technologies.</p>
            <p>The sale runs Friday evening (7 February 2025) through Monday morning, UK
time. With a savings of almost 75% off our regular price, this is your perfect
opportunity to hop aboard and join us for the next 21 years!</p>
            <p id="tandc" class="fineprint">
               <sup>*</sup> Terms and conditions apply 😁:
limited to one single-user EE license purchased through our online shop.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Ordered Maps</title>
      <link href="https://blog.saxonica.com/mike/2024/12/ordered-maps.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/mike/2024/12/ordered-maps.html</id>
      <published>2024-12-29T09:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/mike/2024/12/ordered-maps.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>There's been a lot of discussion recently in the QT4 community group about introducing
        ordered maps: that is, maps in which there is a defined and predictable ordering of entries,
        typically "last-in, last-out" where the most recently added entry always appears at the end.
        The main motivation for this is that JSON is designed (like XML) to be human-readable, but
        JSON content in which the entries appear in random order is anything but: if a phone bill
        contains a name, address, account number, a summary of charges, and an itemized list of calls,
        then you don't want the phone number appearing in the middle, sandwiched between the
        list of calls and the list of charges. Currently when data is serialized as JSON, we provide
        an option to indent it for readability, but indentation isn't going to make the data readable if
        it's in random order.</p>
            <p>Retaining order is particularly useful for visual inspection of changes: if you write code that
        modifies one entry in a JSON document, you want to satisfy yourself that the transformation
        did exactly what you expected, and the best way to convince yourself is by placing the
        input and output side-by-side and comparing them visually.</p>
            <p>There seems to be consensus that support for ordered maps, at least in some circumstances,
        is desirable. There is debate about whether all maps should be ordered, and about whether
        ordering should be the default, and about whether ordering should be supported if a map
        is built incrementally using <code>map:put</code> operations. The answer to those questions
        depends at least in part on understanding how great the overhead is in retaining order
        in maps: if the overhead is negligible, then we might as well make all maps ordered.</p>
            <p>Normally I'm the first to argue that the language specification should not be driven
        by performance concerns: we should design a clean language and leave implementors to
        worry about how to implement it efficiently. But in this case, if we're making a change
        to the language semantics that affects users whether they want the feature or not, I think
        we need to understand clearly whether we are asking users to pay a performance price.</p>
            <p>Both JavaScript (from ES2015) and Python (from 3.7) have moved 
        in the direction of making all maps (objects/dictionaries) ordered, so we wouldn't 
        be on our own in doing this. However, JavaScript objects and Python dictionaries
        are mutable, whereas XDM maps are functionally persistent (adding an entry
        creates a new map, leaving the original unchanged), so the performance
        constraints are somewhat different.</p>
            <p>So let's look now at how Saxon implements maps.</p>
            <p>In SaxonJ 12.x there are two main implementations (ignoring special cases such as empty
        maps and singleton maps). The default implementation is in the class 
        <code>net.sf.saxon.ma.map.HashTrieMap</code>, and this is built using an open source
        implementation of immutable hash tries written by Michael Froh; it has been in the
        product since 9.6. In SaxonCS 12.x we replace this with the functionally equivalent Microsoft 
        class <code>System.Collections.Immutable.ImmutableDictionary</code>. Both these library
        implementations are unordered.</p>
            <p>There is a minor tweak that complicates the implementation. In an ideal world,
        we would create an underlying map of type <code>Map&lt;AtomicValue, GroundedValue&gt;</code>,
        where <code>AtomicValue</code> is the Saxon class used to hold all atomic values,
        and <code>GroundedValue</code> is the Saxon class used to hold all sequences other than
        those that are lazily-evaluated. However, <code>AtomicValue.equals()</code> does
        not implement the equality semantics defined by XDM for comparing map keys. This
        is because XPath has different rules for equality comparisons in different circumstances.
        The Microsoft <code>ImmutableDictionary</code> can take a custom <code>KeyComparer</code>
        parameter, which would solve this problem, but there is no equivalent in the Froh
        library that we use in SaxonJ. So instead we implement an underlying map of type
        <code>Map&lt;AtomicMatchKey, Tuple&lt;AtomicValue, GroundedValue&gt;&gt;</code>, where
        <code>AtomicMatchKey</code> is a value derived from the <code>AtomicValue</code>
        that has the correct equality semantics. We need to hold the <code>AtomicValue</code>
        because in general two atomic values can have the same <code>AtomicMatchKey</code>
        (for example this is the case when the keys are a mix of different numeric types):
        and the XPath functionality for maps requires the original key value (including
        its type annotation) to be retained.</p>
            <p>The second implementation of maps found in SaxonJ and SaxonCS is the class
        <code>net.sf.saxon.ma.map.DictionaryMap</code>. This is implemented over a standard
        mutable <code>java.util.HashMap&lt;String, GroundedValue&gt;&gt;</code> on Java, or
        <code>System.Collections.Generic.Dictionary&lt;string, GroundedValue&gt;</code>
        on .NET. It is suitable only where the keys are all instances of <code>xs:string</code>
        (which means we don't need to retain the type annotation), and where no in-situ
        modification takes place. As soon as an operation such as <code>map:put</code>
        or <code>map:remove</code> is applied to the map, we make a copy using the
        more general <code>HashTrieMap</code> implementation. But for many maps,
        especially those derived from JSON parsing, incremental modification is rare,
        and the lower-overhead <code>DictionaryMap</code> is perfectly satisfactory.</p>
            <p>In Saxon 13 (not yet released), a third map implementation has been introduced:
        the <code>ShapedMap</code>. This is described in the article 
        <a href="https://blog.saxonica.com/mike/2024/08/maps-and-records.html">Maps and Records</a>,
        and it is particularly useful in cases where many maps have exactly the same structure.
        This often happens when parsing CSV or JSON files. A <code>ShapedMap</code> is in two
        parts: a <code>Shape</code> object which holds a mapping from keys to integer slot numbers,
        and a simple array of slots holding the values of the fields. The <code>Shape</code>
        object can be shared between all map instances having a common structure. As with the
        <code>DictionaryMap</code>, if a <code>ShapedMap</code> is subjected to <code>map:put</code>
        or <code>map:remove</code> operations, it is immediately copied to a <code>HashTrieMap</code>.</p>
            <p>How are these map implementations affected by the requirement to maintain order
        of entries?</p>
            <p>For the <code>ShapedMap</code>, order is already maintained, so it isn't a problem.
        The only impact is that two maps can only share the same <code>Shape</code> object
        if their keys are in the same order. There isn't going to be any observable performance
        regression.</p>
            <p>For the <code>DictionaryMap</code>, on the Java platform we can replace the
        underlying <code>HashMap&lt;String, GroundedValue&gt;</code> by a 
        <code>LinkedHashMap&lt;String, GroundedValue&gt;</code>. That's easily done,
        because it supports the same interface. I don't yet know how much overhead
        it imposes (in space or time); that requires some measurements.</p>
            <p>On .NET, unfortunately, there is no equivalent to Java's <code>LinkedHashMap</code>.
        I have therefore implemented my own: this comprises a <code>Dictionary&lt;string, int&gt;</code>
        that maps string-valued keys to integer positions in the sequence, and two lists:
        a list of <code>AtomicValue</code> for the keys and a list of <code>GroundedValue</code>
        for the values.</p>
            <p>For the <code>HashTrieMap</code> on Java, my plan is to scrap the immutable map implemented
        by Michael Froh, and substitute it with the <code>io.vavr.collection.LinkedHashMap</code>
        from the VAVR library, which appears to have the required semantics. Again, there appears
        to be no direct equivalent on .NET, so a home grown solution is again called for. My
        current implementation uses the same apprach as for the <code>DictionaryMap</code>:
        an immutable unordered map from atomic keys to integers, supplemented by ordered 
        immutable lists of <code>AtomicValue</code> for the keys and <code>GroundedValue</code>
        for the values.</p>
            <p>Which brings us to the question, what are the overheads? Answering that question
        means making some assumptions about the workloads we want to measure. For example,
        how important are <code>map:put</code> and <code>map:remove</code> operations? 
        Anecdotal evidence suggests these are rather rare, and that most maps are read-only
        once built. But they might be important to some use cases.</p>
            <p>The other complication is that we might be able to mitigate the overheads of making
        maps ordered by introducing new optimisations. We've already introduced the 
        <code>ShapedMap</code> idea, where ordering hopefully imposes very little overhead.
        On .NET we could consider taking advantage of the ability to use a custom 
        <code>KeyComparer</code> to avoid the overhead of effectively storing the keys twice.</p>
            <p>We could also get smarter about choosing which implementation of maps to use under
        which circumstances. One change that I'm making is to introduce a <code>MapBuilder</code>
        class: during the initial construction of a map (for example during JSON parsing or
        during processing of <code>map:merge</code> or <code>map:build</code>, or during
        evaluation of a map constructor) we can add entries to a mutable builder object, and
        this then gives us the opportunity to choose the final map implementation when we
        know what all the keys and values are. For example, if all the keys have the same
        type annotation, then in principle we don't need to save the type annotations with
        every key value. We also know the size of the map at this stage.</p>
            <p>We can even go further and avoid indexing the map until the first lookup 
        (or <code>map:get</code>) operation. It might seem surprising, but there
        are many maps that are never used for lookup. For example, a JSON document
        might contain thousands of maps that are simply copied unchanged to the output,
        or that are discarded because they are irrelevant to the particular query.
        Perhaps the map builder should simply maintain a list of keys and values,
        and do nothing else until the first <code>map:get</code>? The only complication
        here is the need to detect duplicate keys, but that could be done cheaply
        using a Bloom filter.</p>
            <p>So we need to do some measurements. But there's a good chance that if
        it does turn out that ordered maps impose an overhead, we can find compensating
        optimisations that mean there's no regression on the bottom line.</p>
            <p>My first experiments looking at the cost of parsing and re-serializing
        JSON actually suggest that most of the cost is in the parsing and serializing,
        and that the choice of data structure for the XDM maps has very little impact 
        on the bottom line. But that's provisional and subject to confirmation.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing SaxonJS-HE 3.0.0-beta1!</title>
      <link href="https://blog.saxonica.com/announcements/2024/12/saxonjs-he-3.0.0-beta1.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2024/12/saxonjs-he-3.0.0-beta1.html</id>
      <published>2024-12-18T16:30:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2024/12/saxonjs-he-3.0.0-beta1.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing SaxonJS-HE 3.0.0-beta1!</h1>
            <p>SaxonJS 3.0 is a major update to the SaxonJS product. In December 2024, it is
being published as a preview release, version 3.0.0-beta1. This is a preview
release of the SaxonJS 3.0 HE (Home Edition) product. An EE (Enterprise Edition)
product is in the works.
</p>
            <div>
               <h2>New features in the beta1 release</h2>
               <p>This release includes a number of new features, with several more planned
before the final 3.0 release.
</p>
               <div>
                  <h3>Promises</h3>
                  <p>SaxonJS 3 introduces new mechanisms for enabling asynchronous processing
using promises. A new instruction <code>ixsl:promise</code> is introduced which
can be used as a replacement for the existing <code>ixsl:schedule-action</code>
instruction.
</p>
                  <ul>
                     <li>The new instruction can now call any asychronous function to fetch any kind of
resource. Adding new kinds of resource is just a question of implementing new
functions (which can be user-written functions as well as system-supplied
functions). So if you want to fetch data from a SQL database, for example, you
can easily write a function to do that.</li>
                     <li>The machinery for handling asynchronous requests is now closely aligned with
JavaScript promises, both in terms of the conceptual design, and the
implementation. This makes it much easier to understand for users familiar
with the JavaScript processing model.</li>
                     <li>The mechanism takes advantage of XDM higher-order functions. (Note, however,
that it still “bends” the pure declarative approach of XPath by introducing
mutability. A promise, for example, is a mutable object, so you need to
exercise care for example if you bind it to a variable.)</li>
                  </ul>
                  <p>Note that for Node.js, run time use of ixsl:promise is an EE feature. So XSLT
stylesheets using <code>ixsl:promise</code> can be compiled to SEF with the XX
compiler in SaxonJS without a JS-EE license, and then run in the browser; but to
run such a stylesheet on Node.js requires SaxonJS-EE and a valid JS-EE license.
</p>
               </div>
               <div>
                  <h3>JavaScript extension functions</h3>
                  <p>JavaScript developers have easy access to a huge variety of tools and
libraries distributed as JavaScript packages through <code>npm</code> and other
mechanisms. We want to make those libraries easily accessible for SaxonJS
developers too.
</p>
                  <p>In SaxonJS 3, you can define extension functions in JavaScript and call them
directly from XPath, both from <code>SaxonJS.XPath.evaluate</code> and from
within XSLT stylesheets running on SaxonJS in the browser or on Node.js.
</p>
                  <p>This opens up whole new horizons for SaxonJS developers.
</p>
               </div>
               <div>
                  <h3>Smaller changes and improvements</h3>
                  <p>While a lot of our focus has been on larger improvements, a few less dramatic
features are also debuting in beta1.
</p>
                  <ul>
                     <li>Support XPath expressions (other than “.”) after ? in <code>xsl:result-document</code>
                     </li>
                     <li>New methods on <code>xsl:result-document</code>: <code>ixsl:replace-element</code>, <code>ixsl:insert-before</code>, and
<code>ixsl:insert-after</code>
                     </li>
                     <li>Improved support for following HTTP redirects</li>
                     <li>Improved support for accessing JavaScript objects with <code>ixsl:set-property</code>, <code>ixsl:json-parse</code>,
<code>ixsl:new</code>, <code>ixsl:apply</code>, <code>ixsl:call</code>, <code>ixsl:eval</code>, and <code>ixsl:get</code>
                     </li>
                     <li>Support the <code>escape-solidus</code> option when generating JSON.</li>
                  </ul>
               </div>
            </div>
            <div>
               <h2>New features coming soon</h2>
               <p>Eager to publish a release, at this stage, we’ve opted only to publish the HE
version of SaxonJS 3.0 as beta1. More work is planned before the general
release, including SaxonJS 3.0 EE.
</p>
               <div>
                  <h3>SaxonJS-EE</h3>
                  <p>SaxonJS-HE will remain a free product, but in 2025 we will also be introducing a
licensed version of SaxonJS, SaxonJS-EE. The licensed version will provide additional
features on Node.js (such as built-in EXPath and Saxon extension functions).
</p>
                  <p>The promises API run time will be a licensed feature on Node.js.
</p>
               </div>
               <div>
                  <h3>Calling XSLT functions from JavaScript</h3>
                  <p>Many transformations, on XML and JSON, are easier to define in XSLT than in
JavaScript. XSLT has a rich vocabulary of instructions for describing, constructing,
and transforming data in a clear, descriptive, and functional way.
</p>
                  <p>We anticipate making those features more accessible to JavaScript developers by
allowing JavaScript to call functions defined in XSLT.
</p>
               </div>
               <div>
                  <h3>Adding a SaxonJS.compile API</h3>
                  <p>The ability to construct an XSLT stylesheet and then compile it directly for
use in the current transformation is a powerful feature. A new API for doing this,
<code>SaxonJS.compile</code>, will be added in the general release.
</p>
               </div>
               <div>
                  <h2>Getting started</h2>
               </div>
               <p>You can try out SaxonJS-HE 3.0 today, the packages have been uploaded to
<a href="https://www.npmjs.com/">npmjs.com</a>: 
<a href="https://www.npmjs.com/package/saxonjs-he">saxonjs-he</a>
and 
<a href="https://www.npmjs.com/package/xslt3-he">xslt3-he</a>. You can also
download them <a href="https://downloads.saxonica.com/SaxonJS/3/index.html">our website</a>.</p>
               <p>Our <a href="https://www.saxonica.com/saxonjs/documentation3/index.html">documentation
pages</a> have been updated and a repository of short examples has been
published: <a href="https://github.com/Saxonica/SaxonJS3-demo">SaxonJS3
demo</a>.</p>
               <p>We hope you’re as excited as we are and we look forward to your feedback. Please
report any issues that you encounter on
<a href="https://saxonica.plan.io/projects/saxon-js/issues">our issue tracker</a>.
</p>
            </div>
         </div>
      </content>
   </entry>
   <entry>
      <title>Oops, we did it again</title>
      <link href="https://blog.saxonica.com/norm/2024/10/17-oops.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/norm/2024/10/17-oops.html</id>
      <published>2024-10-17T15:01:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/norm/2024/10/17-oops.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>As some of you have noticed, the SaxonJS
“<a href="../../2023/10/06-no-longer-supported.html">no longer supported</a>” bug
returned a few days ago. I’d have sworn that I removed that warning when we shipped
SaxonJS 2.6. But I’d also have sworn we would get 3.0 out before now. Maybe I’m
not very good at swearing.</p>
            <p>That warning <em>has been</em> removed from
<a href="../../../announcements/2024/10/saxonjs-2.7.html">SaxonJS 2.7</a>, so
this issue won’t surface again next October.</p>
            <p>Apologies for not getting a maintenance release out sooner. We really should
have. Focus has been on SaxonJS 3.0, which is still coming along nicely, but
there were a number of bug fixes in SaxonJS 2.x that we could have shipped
months ago.</p>
            <p>My expectation is that we’ll ship some sort of beta test version of SaxonJS
3.0 “real soon now” and Saxon 12.6 to fix
<a href="https://saxonica.plan.io/issues/6487">the SEF bug</a> in 12.5 shortly
before or after that.
</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing SaxonJS 2.7!</title>
      <link href="https://blog.saxonica.com/announcements/2024/10/saxonjs-2.7.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2024/10/saxonjs-2.7.html</id>
      <published>2024-10-17T15:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2024/10/saxonjs-2.7.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing SaxonJS 2.7!</h1>
            <p>The SaxonJS 2.7 maintenance release has been published. This is a
maintenance release for NodeJS and the browser. It fixes a number of bugs.
(Including <a href="/norm/2023/10/06-no-longer-supported.html">that one</a>
about the spurious warning message. Again.)</p>
            <p>Highlights include:</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/4991">#4991</a>: Support JSON indentation in xml-to-json</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/5540">#5540</a>: Namespace context is reset before each XSLT transformation</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/5743">#5743</a>: Text nodes are no longer lost in xsl:catch instruction</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6234">#6234</a>: Corrected the behavior of a map called as a function</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6318">#6318</a>: Fixed an error in parsing regular expressions</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6352">#6352</a>: Resolved a performance issue introduced in SaxonJS 2.6</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6393">#6393</a>: Fixed a string/number comparison bug</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6418">#6418</a>: Improve behavior when attempting to use IXSL extensions on Node.js</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6516">#6516</a>: Fixed some XPath parsing errors related to uncommon expressions (like <code>/[x]</code>)</li>
            </ul>
            <p>For a complete list of the issues resolved in this release, please visit the
<a href="https://saxonica.plan.io/projects/saxon-js/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=status_id&amp;op%5Bstatus_id%5D=c&amp;f%5B%5D=cf_10&amp;op%5Bcf_10%5D=%3D&amp;v%5Bcf_10%5D%5B%5D=97&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">issue tracker</a>
on the Saxonica support site.</p>
            <p>SaxonJS 2.7 was released on 17 October 2024. This release has been
uploaded to the usual locations on the Saxonica website and the NPM
repository.
For more details, please consult
<a href="https://www.saxonica.com/saxon-js/documentation2/index.html">the documentation</a>.
</p>
            <div class="note">
               <p>Note: Saxon 12.5 won’t create SEF files that can be used with SaxonJS 2.x.
This is a <a href="https://saxonica.plan.io/issues/6487">known bug</a> that will
be fixed in Saxon 12.6. Saxon 12.4 and earlier versions will make SEF files that
SaxonJS 2.x can use.</p>
            </div>
            <p>If you encounter any issues with SaxonJS 2.7, please
<a href="https://saxonica.plan.io/projects/saxon-js/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Packaging SaxonJS for the browser</title>
      <link href="https://blog.saxonica.com/norm/2024/08/16-packaging.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/norm/2024/08/16-packaging.html</id>
      <published>2024-08-16T15:20:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/norm/2024/08/16-packaging.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>Over the years, there have been several requests to improve the way that
SaxonJS is packaged for the browser. In the run up towards SaxonJS 3.0 (real
soon now, I promise), I’ve spent a few hours trying to see if that’s possible.</p>
            <p>For SaxonJS on Node.js, things seem to be working the way users expect. You
can install SaxonJS, and <em>xslt3.js</em>, the command-line XSLT processor,
with <code>npm install</code>. Then you can use them as you would other Node.js
modules and applications.</p>
            <p>For the browser, things are a little less clear.</p>
            <p>I’ll start out by observing that SaxonJS is a large(ish) collection of mostly
plain JavaScript files. There are a mixture of techniques used, as you might
expect from a code base that stretches back seven or eight years (roughly ∞ in
JavaScript years). This code is compiled by the <a href="https://developers.google.com/closure/compiler">Closure Compiler</a> to
produce the release artifacts.</p>
            <div class="aside">
               <p>
                  <em>Aside:</em> Producing TypeScript instead of JavaScript is almost certainly
impractical. And
the answer to the question, “can you make it an ESM module?” appears to be “no”. But
maybe I’m wrong?</p>
            </div>
            <p>Almost anything is <em>possible</em> in software,
but there some things are probably <em>impractical</em> because of how SaxonJS
is built.
</p>
            <p>What I’ve come to realize after several hours is that I
don’t actually understand what problem I’m trying to solve. That usually makes
problems harder.</p>
            <p>For example, it would be easy to package the browser versions of the SaxonJS
libraries into the <code>saxon-js</code>
               <em>npm</em> package. That would allow
you to use <code>npm install</code> to install it. Once installed, you could
refer to it in HTML like this:</p>
            <pre>
               <code>&lt;script src="node_modules/saxon-js/SaxonJS3.rt.js"&gt;&lt;/script&gt;</code>
            </pre>
            <p>That’s a non-zero usability improvement over downloading the browser release
yourself and adding it to your project, but it’s an <em>awfully small</em>
improvement. So small, that I conjecture that the request to “put it in the npm
package” means more than that. But I don’t know what more.</p>
            <p>Another request that’s come up a couple of times is whether we should provide
a version that’s been packaged up with <em>webpack</em>. Well. Okay. I spent
a bit of time on that and eventually I managed to get</p>
            <pre>
               <code>npx webpack 
            </pre>
            <p>to take <code>src/SaxonJS3.js</code>, chew on it for a while, and produce
<code>dist/SaxonJS3.js</code>. That was a little, uh, underwhelming. I started
with a JavaScript library that I could load in the browser and ended with…a
different one, I guess?</p>
            <p>Then there are suggestions that instead of <em>webpack</em> I should be
trying <em>vite</em> or <em>bun</em> or something else and do I also need
<em>browserify</em>? I don’t know.
I’m about to give up, at least in the short term, but before I do, I thought
I’d see if anyone out there can tell me what I’m missing.</p>
            <p>If you would like to see SaxonJS for the browser packaged up in some
different way, can you tell me how? And why? A small test case would be ideal:
something that isn’t too complicated, that doesn’t work with SaxonJS as it’s
distributed today, that would work if we packaged it in some other way.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Maps and Records</title>
      <link href="https://blog.saxonica.com/mike/2024/08/maps-and-records.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/mike/2024/08/maps-and-records.html</id>
      <published>2024-08-10T09:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/mike/2024/08/maps-and-records.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <p>Maps have proved to be one of the most powerful new features in the 3.0/3.1 family of standards,
        and records, which extend the capability will probably prove one of the most powerful in 4.0. 
        Under the name <i>tuple types</i>, the feature has been available as a proprietary Saxon extension
        since Saxon 9.8, which came out on the same day as the XSLT 3.0 Recommendation in June 2017.
        The feature is now well established, but the details are still being refined.</p>
            <p>A record type is declared like this:</p>
            <pre>record(longitude as xs:double, latitude as xs:double)</pre>
            <p>A record type is simply a new way of constraining maps; the instances of the type
        are maps (in this case a map with two entries, one with key "longitude" and one with
        key "latitude"). You can use a record type to declare the types of variables and function
        arguments, but the actual value of the variable is a map, and all the standard map operations
        are available, such as the lookup operator: <code>$location?longitude</code>.</p>
            <p>We're working on an extension that allows named record types to be declared globally:</p>
            <pre>&lt;xsl:record name="my:location"&gt;
   &lt;xsl:field name="longitude" as="xs:double"/&gt;
   &lt;xsl:field name="latitude" as="xs:double"/&gt;
&lt;/xsl:record&gt;</pre>
            <p>which would also give you a constructor function: <code>my:location($long, $lat)</code>.</p>
            <p>The main thing I want to talk about in this article is how records can be efficiently
        implemented.</p>
            <p>Until recently, a record type simply constrained the contents of a map, and had no
        bearing on the way the map was implemented.</p>
            <p>Internally, Saxon represents maps using the interface <code>net.sf.saxon.ma.map.MapItem</code>
        (actually an abstract class), and there are several implementations of this interface:</p>
            <ul>
               <li>
                  <code>EmptyMap</code> for an empty map</li>
               <li>
                  <code>SingleEntryMap</code> for a map with one entry, such as the map created by <code>map:entry()</code>
               </li>
               <li>
                  <code>DictionaryMap</code> for a map whose keys are all strings, and that isn't likely to be modified
            (for example maps derived by parsing JSON, or maps written using literal constructors as option parameter values)</li>
               <li>
                  <code>HashTrieMap</code> as the general implementation that handles everything.</li>
            </ul>
            <p>For the next release, Saxon 13, we've written a new implementation called a
        <i>ShapedMap</i>. There are two parts to this: a <i>Shape</i> is a mapping from field names to
        integer slot numbers, and a <i>ShapedMap</i> is a reference to a <i>Shape</i>, plus an array of slots.
        So it's great where you have many maps with exactly the same structure, because you only hold the keys
        once.</p>
            <p>So far we're mainly using shaped maps where the structure of the map is defined by the language specification,
        for example for the key-value pairs returned by <code>map:pairs()</code>, for the results of functions such as
        <code>parse-csv()</code>, <code>random-number-generator()</code>, and <code>load-xquery-module()</code>,
        and for the labels attached to values by the new deep-lookup operator (plenty of scope there for future articles).
        I would love to use them also for the result of <code>parse-json()</code> if we can detect the common case
        of a JSON file containing thousands of maps (JSON objects) with exactly the same structure. And of course, once
        we have record constructor functions as described above, they are an obvious candidate for the result
        of such a function.</p>
            <p>Shaped maps immediately give a space saving because the keys and their hash index are shared between instances.
        The next challenge after that is to make lookup on shaped maps more efficient. Given a lookup expression
        such as <code>$location?longitude</code>, we <i>ought</i> to be able to extract the corresponding value directly
        from slot 0 of the <code>ShapedMap</code> object, without the overhead of doing a run-time hash lookup of the string
        <code>"longitude"</code> in the corresponding <code>Shape</code> in order to establish that this field is always
        in slot 0.</p>
            <p>The obvious, classic way of doing that is through static type inference: if we know the static type of the
        <code>$location</code> variable, then we can know at compile time what the mapping of field names to slots will be,
        and can generate an execution plan accordingly.</p>
            <p>But I'm becoming a bit disillusioned with relying on static type analysis. Users, in general, are lazy: they
        want good performance without doing extra work, like declaring the types of all their variables. That's particularly
        true when you start writing code that relies heavily on higher-order functions, which we want to encourage.
        So I'm looking increasingly at options that decide the execution plan at run-time, modifying it in the light
        of actual experience. Given an expression like <code>$location?longitude</code> that is executed repeatedly,
        the chances are that if <code>$location</code> is a shaped map with <code>longitude</code> in slot 0 on one occasion,
        then the same will be true next time you execute the same expression.</p>
            <p>We've quietly introduced this kind of approach in recent releases, and it's working well. For example, with
        lazy evaluation of variables and function results we now use a learning approach: we start with lazy evaluation,
        but if on the first 20 executions the value is immediately read to completion, we switch to eager evaluation.
        That's because lazy evaluation has a significant set-up overhead to retain the parts of the context on which the
        expression depends, and there is no benefit in doing this if the caller is going to immediately materialise
        the value anyway.</p>
            <p>The concrete design for shaped record access goes something like this. We augment the 
            <code>MapItem</code> interface with a method
        <code>map.lookup(key, plan)</code>. This method returns the requested value from the map, but also updates the
        value of <code>plan</code> with information that will be retained the next time the same expression is evaluated.
        If the map is a shaped map, the returned plan can include the <code>Shape</code> and the slot number; if an incoming
        request comes with a plan that identifies the same <code>Shape</code> (which it usually will), 
        then we can access the relevant slot number directly,
        ignoring the value of the key. That only works, of course, for a lookup expression where the key is a literal
        constant; but that's the normal case when working with records.</p>
            <p>If we can make this work (and it seems straightforward), then the same approach might have other applications.
        For example, can we make path expressions go faster if we optimize for the tree model in use? Or could we get rid
        of statically-allocated fingerprints (with the inconvenience they cause by not allowing documents and stylesheets
        to be shared across configurations), and instead have the expression discover the fingerprint and NamePool at 
        execution time?</p>
            <p>Saxon is now 25 years old. It seems there are still plenty of exciting ways to make it better.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing Saxon 12.5!</title>
      <link href="https://blog.saxonica.com/announcements/2024/07/saxon-12.5.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2024/07/saxon-12.5.html</id>
      <published>2024-07-02T11:30:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2024/07/saxon-12.5.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing Saxon 12.5!</h1>
            <p>The Saxon 12.5 maintenance release has been published. This is a
maintenance release for Java, C#, C/C++, PHP, and Python that fixes a
number of issues reported since previous Saxon 12.4 releases.
</p>
            <p>Saxon 12.5 was released on 1 July 2024.
This release has been
uploaded to the usual locations on the Saxonica website, GitHub, and
Maven, PyPi, and NuGet. SaxonCS 12.5 is built with .NET 6. This
release includes SaxonC and Python releases for the ARM 64
architecture as well as X86-64 architecture.</p>
            <p>For a list of the issues resolved in this release, please visit the issue trackers
for
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=96&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonJ and SaxonCS</a> or
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_3&amp;op%5Bcf_3%5D=%7E&amp;v%5Bcf_3%5D%5B%5D=12.5&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">SaxonC</a>
on the Saxon support site.
</p>
            <p>Download products:</p>
            <ul>
               <li>Binaries for PE and EE are available from our
<a href="http://www.saxonica.com/download/download_page.xml">download pages</a>.
</li>
               <li>SaxonJ-HE is available on the
<a href="https://central.sonatype.com/artifact/net.sf.saxon/Saxon-HE/12.5">Maven Central
repository</a>.
</li>
               <li>SaxonJ-HE, PE, and EE can also be found on our
<a href="https://dev.saxonica.com/maven/">experimental Maven repository</a>.
</li>
               <li>Python wheels for SaxonC (HE, PE, and EE) are available from
<a href="https://pypi.org/user/saxonica/">PyPI</a>.
</li>
               <li>SaxonCS is available on
<a href="https://www.nuget.org/packages/SaxonCS">NuGet</a>
               </li>
               <li>Saxon-HE is available from our open source
<a href="https://github.com/Saxonica/Saxon-HE/">GitHub repository</a>.
The GitHub repository also provides source code for those who need it.
</li>
            </ul>
            <p>For more details, please consult
<a href="https://www.saxonica.com/documentation12">the documentation</a>.
</p>
            <h2>Partial list of issues resolved</h2>
            <p>This section is a subset of the complete list of resolved issues.
It’s curated to bring attention to the bugs that seem most likely to
impact customers. 
</p>
            <h3>Issues in SaxonJ and SaxonCS</h3>
            <p>For a full list, see
<a href="https://saxonica.plan.io/projects/saxon/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_6&amp;op%5Bcf_6%5D=%3D&amp;v%5Bcf_6%5D%5B%5D=96&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6450">6450</a>
    CollectionFinder parsesd ALLOWED_PROTOCOLS incorrectly</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6449">6449</a>
    SaxonCS failure when using collection function to pull a collection catalog file over HTTP(S)</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6448">6448</a>
    Saxon-HE 12.4J has wrong column number in trace, unlike Saxon-EE</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6446">6446</a>
    Improved performance of XQuery group by some circumstances</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6435">6435</a>
    Resolve concurrency issue in the use of accumulators behind the scenes in xsl:for-each</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6428">6428</a>
    Output of xsl:on-non-empty changes when using TraceListener</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6426">6426</a>
    fn:matches surprisingly returns false for fn:matches("AB", "^(.*)+B")</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6420">6420</a>
    -Tout filename not used when set on command line</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6419">6419</a>
    Union of nodes in a Template Match produces wrong output in Trace</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6415">6415</a>
    Improved results for trace of an unreferenced XSLT variables</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6407">6407</a>
    Tree Model option -tree seems to be ignored for initial source documents</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6406">6406</a>
    A collection cannot contain the same document more than once</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6405">6405</a>
    Improve saxon:column-number() for text nodes not inside xsl:text</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6394">6394</a>
    Resolve "Duplicate definition of global variable" exception when using compileLibrary on modules which import a common module</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6386">6386</a>
    Resolve inadvertant backwards incompatibility in some uses of Configuration#setFeature</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6381">6381</a>
    set_unprefixed_element_matching_policy(1) doesn't seem to work</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6380">6380</a>
    Internal error when match pattern invoked by xsl:next-match refers to global variable</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6378">6378</a>
    Resolved problem with tracing a variable declared abstract</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6377">6377</a>
    Resolved exception that could be thrown by format-time in some circumstances</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6370">6370</a>
    XSD based validation finds a validation throws NullPointerException when trying to generate a validation report</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6365">6365</a>
    Fixed bug where Gizmo could fail if no license was provided</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6363">6363</a>
    Incorrect result comparing untypedAtomic value to NaN</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6348">6348</a>
    Fixed multi-threading bug related to xsl:result-document operating asynchronously </li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6340">6340</a>
    Fixed exception that sometimes arose when using saxon:capture="yes" in an accumlator rule</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6339">6339</a>
    Describe fix and workaround for ArrayIndexOutOfBoundsException in saxon:transform() </li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6313">6313</a>
    Static type error from fn:remove()</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6302">6302</a>
    Improved trace output when the transform function is used</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6286">6286</a>
    Resolved problem where $connection?close() could throw an error</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6279">6279</a>
    Incorrect optimization of generate-id() comparisons</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6256">6256</a>
    function-name returns an empty sequence for node-name#0, string#0 and more?</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6183">6183</a>
    Improved documentation for debugging errors when using "fallback=no" on UCA collation</li>
            </ul>
            <h3>Issues in SaxonC</h3>
            <p>Memory management in SaxonC, PHP, and Python has been greatly improved. This resolved
a number of issues (<a href="https://saxonica.plan.io/issues/6338">6338</a>,
<a href="https://saxonica.plan.io/issues/6349">6349</a>,
<a href="https://saxonica.plan.io/issues/6357">6357</a>,
<a href="https://saxonica.plan.io/issues/6396">6396</a>, and
<a href="https://saxonica.plan.io/issues/6397">6397</a>). In addition, the following
issues were resolved. (For a full list, see
<a href="https://saxonica.plan.io/projects/saxon-c/issues?utf8=%E2%9C%93&amp;set_filter=1&amp;sort=id%3Adesc&amp;f%5B%5D=cf_3&amp;op%5Bcf_3%5D=%7E&amp;v%5Bcf_3%5D%5B%5D=12.5&amp;f%5B%5D=&amp;c%5B%5D=tracker&amp;c%5B%5D=status&amp;c%5B%5D=priority&amp;c%5B%5D=subject&amp;c%5B%5D=assigned_to&amp;c%5B%5D=updated_on&amp;group_by=&amp;t%5B%5D=">the issue tracker</a>.)</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6439">6439</a>
    Fixed bug in Python extension that could cause an AttributeError on PyXdmFunctionItem</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6402">6402</a>
    Added <code>clearXslMessages</code> to clear accumulated xsl:message messages</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6401">6401</a>
    Resolved bug when setting a filename on an executable in Python</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6372">6372</a>
    Updated build to include all character sets (will enable Windows-1252 encoded XML files to be parsed on Linux)</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6360">6360</a>
    Fixed bug where setOutputFile did not work with transformToFile()</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6356">6356</a>
    Fixed argument count error in executable in PHP</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6351">6351</a>
    Added methods for getting the line and column number of a node</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6342">6342</a>
    Fixed bug where in compileFromAssociatedFile PHP might fail</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6341">6341</a>
    Support try/catch in PHP for underlying parse errors</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6336">6336</a>
    Fixed bug when passing array values as parameters in Python</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6327">6327</a>
    Fixed bug where an empty XdmValue in Python might throw a TypeError</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6297">6297</a>
    Fixed build issue on CentOS 7</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6276">6276</a>
    Fixed bug where proc.version did not include the patch version</li>
            </ul>
            <p>If you encounter any issues with Saxon 12.5, please
<a href="https://saxonica.plan.io/projects/saxon/issues">report them</a>
on our issue tracker.</p>
         </div>
      </content>
   </entry>
   <entry>
      <title>Announcing SaxonC 12.4.2!</title>
      <link href="https://blog.saxonica.com/announcements/2024/01/saxonc-12.4.2.html"
            rel="alternate"
            type="text/html"/>
      <id>https://blog.saxonica.com/announcements/2024/01/saxonc-12.4.2.html</id>
      <published>2024-01-26T10:00:00Z</published>
      <content type="xhtml"
               xml:base="https://blog.saxonica.com/announcements/2024/01/saxonc-12.4.2.html">
         <div xmlns="http://www.w3.org/1999/xhtml">
            <h1>Announcing SaxonC 12.4.2!</h1>
            <p>A SaxonC 12.4.2 maintenance release has been published. This
release fixes several issues:</p>
            <ul>
               <li>
                  <a href="https://saxonica.plan.io/issues/6197">6197</a> A segmentation fault in the PHP extension</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6273">6273</a> A change in the way whitespace is handled in filenames</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6274">6274</a> An problem with the “encoding” keyword in the python saxon processor</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6277">6277</a> A build configuration issue for the SaxonC HE Python processor</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6288">6288</a> A build issue for the SaxonC PHP extension</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6294">6294</a> A segmentation fault parsing JSON</li>
               <li>
                  <a href="https://saxonica.plan.io/issues/6301">6301</a> A compile error related to memory allocation with some C++ compilers</li>

-->
