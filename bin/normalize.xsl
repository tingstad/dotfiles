<?xml version="1.0" encoding="UTF-8"?>
<!-- Richard H. Tingstad's XML normalizer

Useful for diff-ing XML using well-formed normalization,
but may produce invalid XML e.g. if order of elements is significant.

- Sorts all elements by:
  - Namespace URI
  - Local name
  - Attributes, sorted by namespace URI and local name
- Strips all element namespace prefixes
  - Defines namespace on element if not defined by ancestor
- Keeps attribute namespace prefixes, but
  - defines prefix only once
- All namespace definitions precede other attributes
- Strips text/whitespace between elements (ignores xml:space="preserve")
- Elements are never self-closing
- Indents elements

-->
<stylesheet version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common">

    <output method="text" />

    <variable name="attrname"><!-- name for stringified attributes attribute -->
        <call-template name="find-unused-attr">
            <with-param name="candidate" select="'__attr'" />
        </call-template>
    </variable>

    <template match="/">
        <variable name="preprocessed">
            <apply-templates mode="preprocess" select="@*|node()" />
        </variable>
        <variable name="sorted">
            <apply-templates mode="sort" select="exsl:node-set($preprocessed)" />
        </variable>
        <apply-templates mode="print" select="exsl:node-set($sorted)" />
    </template>

    <template mode="print" match="/">
        <text disable-output-escaping="yes">&lt;?xml version="1.0" encoding="UTF-8"?&gt;&#10;</text>
        <apply-templates mode="print" select="*" />
        <text>&#10;</text>
    </template>

    <template mode="print" match="*">
        <if test="parent::*">
            <value-of disable-output-escaping="yes" select="'&#10;'" />
        </if>

        <variable name="indentation">
            <call-template name="indent">
                <with-param name="depth" select="count(ancestor::*)" />
            </call-template>
        </variable>

        <value-of disable-output-escaping="yes"
            select="concat($indentation, '&lt;', local-name())" />

        <if test="namespace-uri(..) != namespace-uri()">
            <value-of disable-output-escaping="yes"
                select="concat(' xmlns=&quot;', namespace-uri(), '&quot;')" />
        </if>

        <for-each select="@*[namespace-uri()]">
            <variable name="prefix" select="substring-before(name(), ':')" />
            <variable name="ns" select="namespace-uri()" />
            <variable name="i" select="position()" />
            <if test="not(../@*[namespace-uri()][position() &lt; $i and namespace-uri() = $ns and substring-before(name(), ':') = $prefix])">
                <value-of disable-output-escaping="yes"
                    select="concat(' xmlns:', $prefix, '=&quot;', $ns, '&quot;')" />
            </if>
        </for-each>

        <for-each select="@*">
            <if test="name() != $attrname">
                <value-of disable-output-escaping="yes"
                    select="concat(' ', name(), '=&quot;')" />
                <call-template name="xml-escape">
                    <with-param name="str" select="." />
                </call-template>
                <text>&quot;</text>
            </if>
        </for-each>

        <value-of disable-output-escaping="yes"
            select="concat('&gt;', '')" />

        <for-each select="*">
            <apply-templates mode="print" select="." />
        </for-each>

        <if test="not(*) and text()">
            <!-- must escape when output method="text" -->
            <call-template name="xml-escape">
                <with-param name="str" select="text()" />
            </call-template>
        </if>

        <if test="*">
            <value-of disable-output-escaping="yes"
                select="concat('&#10;', $indentation)" />
        </if>

        <value-of disable-output-escaping="yes"
            select="concat('&lt;/', local-name(), '&gt;')" />
    </template>

    <template mode="preprocess" match="*">
        <element name="{local-name()}" namespace="{namespace-uri()}">
            <attribute name="{$attrname}">
                <call-template name="attr-str" />
            </attribute>

            <apply-templates select="@*|text()" />

            <for-each select="*">
                <apply-templates mode="preprocess" select="." />
            </for-each>
        </element>
    </template>

    <template mode="sort" match="*">
        <element name="{local-name()}" namespace="{namespace-uri()}">

            <for-each select="@*">
                <sort select="concat('{', namespace-uri(), '}', local-name())" />
                <copy />
            </for-each>

            <for-each select="*">
                <sort select="concat('{', namespace-uri(), '}', local-name())" />
                <sort select="@*[name() = $attrname]" /><!-- from preprocess -->
                <apply-templates mode="sort" select="." />
            </for-each>

            <apply-templates select="text()" />
        </element>
    </template>

    <template match="@*|text()|comment()|processing-instruction()">
        <copy />
    </template>

    <!-- stringifies attributes of current element, for example:
        <e s:v="" s:name="bar" n="1" xmlns:s="ns:do">
    ==> "{}n=1|{ns:do}name=bar|{ns:do}v=" -->
    <template name="attr-str">
        <for-each select="@*">
            <sort select="namespace-uri()" />
            <sort select="local-name()" />
            <value-of select="concat('{', namespace-uri(), '}', local-name(), '=', .)" />
            <if test="position() != last()">|</if>
        </for-each>
    </template>

    <!-- prepend _ until attr candidate name does not exist in document  -->
    <template name="find-unused-attr">
        <param name="candidate" />
        <choose>
            <when test="//@*[name() = $candidate]">
                <call-template name="find-unused-attr">
                    <with-param name="candidate"
                        select="concat('_', $candidate)" />
                </call-template>
            </when>
            <otherwise>
                <value-of select="$candidate" />
            </otherwise>
        </choose>
    </template>

    <template name="indent">
        <param name="depth" />
        <if test="$depth &gt; 0">
            <text>    </text> <!-- 4 spaces -->
            <call-template name="indent">
                <with-param name="depth" select="$depth - 1" />
            </call-template>
        </if>
    </template>

    <template name="xml-escape">
        <param name="str" />

        <variable name="s1"> <!-- & → &amp; -->
            <call-template name="xml-escape-symbol">
                <with-param name="chr" select="'&amp;'" />
                <with-param name="str" select="$str" />
                <with-param name="rep" select="'amp;'" />
            </call-template>
        </variable>
        <variable name="s2"> <!-- < → &lt; -->
            <call-template name="xml-escape-symbol">
                <with-param name="chr" select="'&lt;'" />
                <with-param name="str" select="$s1" />
                <with-param name="rep" select="'lt;'" />
            </call-template>
        </variable>
        <variable name="s3"> <!-- > → &gt; -->
            <call-template name="xml-escape-symbol">
                <with-param name="chr" select="'&gt;'" />
                <with-param name="str" select="$s2" />
                <with-param name="rep" select="'gt;'" />
            </call-template>
        </variable>
        <variable name="s4"> <!-- " → &quot; -->
            <call-template name="xml-escape-symbol">
                <with-param name="chr" select="'&quot;'" />
                <with-param name="str" select="$s3" />
                <with-param name="rep" select="'quot;'" />
            </call-template>
        </variable>
        <variable name="s5"> <!-- ' → &apos; -->
            <call-template name="xml-escape-symbol">
                <with-param name="chr" select="&quot;&apos;&quot;" />
                <with-param name="str" select="$s4" />
                <with-param name="rep" select="'apos;'" />
            </call-template>
        </variable>
        <value-of select="$s5" />
    </template>

    <template name="xml-escape-symbol">
        <param name="chr" />
        <param name="str" />
        <param name="rep" />
        <param name="acc" select="''" />
        <choose>
            <when test="contains($str, $chr)">
                <call-template name="xml-escape-symbol">
                    <with-param name="chr" select="$chr" />
                    <with-param name="str" select="substring-after($str, $chr)" />
                    <with-param name="rep" select="$rep" />
                    <with-param name="acc" select="concat($acc, substring-before($str, $chr), '&amp;', $rep)" />
                </call-template>
            </when>
            <otherwise>
                <value-of select="concat($acc, $str)" />
            </otherwise>
        </choose>
    </template>

</stylesheet>

