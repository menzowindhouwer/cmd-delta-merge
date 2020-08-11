<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" exclude-result-prefixes="xs" version="2.0" xmlns:cmd="http://www.clarin.eu/cmd/">

    <xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"/>

    <xsl:param name="delta" select="()"/>

    <xsl:param name="profile" select="()"/>

    <xsl:variable name="cmd-version" select="'1.1'"/>
    <xsl:variable name="cmd-ns" select="'http://www.clarin.eu/cmd/'"/>

    <xsl:param name="cr-uri" select="'https://catalog.clarin.eu/ds/ComponentRegistry/rest/registry'"/>
    <xsl:variable name="cr-extension-xml" select="'/xml'"/>

    <!-- CR REST API -->
    <xsl:variable name="cr-profiles" select="concat($cr-uri, '/', $cmd-version, '/profiles')"/>

    <xsl:variable name="base">
        <xsl:choose>
            <xsl:when test="normalize-space(base-uri(/*)) != ''">
                <xsl:sequence select="normalize-space(base-uri(/*))"/>
            </xsl:when>
            <xsl:when test="normalize-space(/cmd:CMD/cmd:Header/cmd:MdSelfLink) != ''">
                <xsl:sequence select="normalize-space(/cmd:CMD/cmd:Header/cmd:MdSelfLink)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'NULL'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- try to determine the profile -->
    <xsl:variable name="cmd-profile">
        <xsl:variable name="header">
            <xsl:choose>
                <xsl:when test="matches(/cmd:CMD/cmd:Header/cmd:MdProfile, '.*(clarin.eu:cr1:p_[0-9]+).*')">
                    <xsl:sequence select="replace(/cmd:CMD/cmd:Header/cmd:MdProfile, '.*(clarin.eu:cr1:p_[0-9]+).*', '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="schema">
            <xsl:variable name="location">
                <xsl:choose>
                    <xsl:when test="normalize-space(/cmd:CMD/@xsi:noNamespaceSchemaLocation) != ''">
                        <xsl:message>WRN: <xsl:value-of select="$base"/>: CMDI 1.1 uses namespaces so @xsi:schemaLocation should be used instead of @xsi:schemaLocation!</xsl:message>
                        <xsl:sequence select="normalize-space(/cmd:CMD/@xsi:noNamespaceSchemaLocation)"/>
                    </xsl:when>
                    <xsl:when test="normalize-space(/cmd:CMD/@xsi:schemaLocation) != ''">
                        <xsl:variable name="pairs" select="tokenize(/cmd:CMD/@xsi:schemaLocation, '\s+')"/>
                        <xsl:choose>
                            <xsl:when test="count($pairs) = 1">
                                <!-- WRN: improper use of @xsi:schemaLocation! -->
                                <xsl:message>WRN: <xsl:value-of select="$base"/>: @xsi:schemaLocation with single value[<xsl:value-of select="$pairs[1]"/>], should consist of (namespace URI, XSD URI) pairs!</xsl:message>
                                <xsl:sequence select="$pairs[1]"/>
                            </xsl:when>
                            <xsl:when test="exists(index-of($pairs, 'http://www.clarin.eu/cmd/'))">
                                <xsl:variable name="pos" select="index-of($pairs, 'http://www.clarin.eu/cmd/') + 1"/>
                                <xsl:if test="$pos le count($pairs)">
                                    <xsl:sequence select="$pairs[$pos]"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>WRN: <xsl:value-of select="$base"/>: no XSD bound to the CMDI 1.1 namespace was found!</xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:if test="not(matches($location, 'http(s)?://catalog.clarin.eu/ds/ComponentRegistry/rest/'))">
                <xsl:message>WRN: <xsl:value-of select="$base"/>: non-ComponentRegistry XSD[<xsl:value-of select="$location"/>] will be replaced by a CMDI 1.2 ComponentRegistry XSD!</xsl:message>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="matches($location, '.*(clarin.eu:cr1:p_[0-9]+).*')">
                    <xsl:sequence select="replace($location, '.*(clarin.eu:cr1:p_[0-9]+).*', '$1')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:if test="count($header) gt 1">
            <xsl:message>WRN: <xsl:value-of select="$base"/>: found more then one profile ID (<xsl:value-of select="string-join($header, ',')"/>) in a cmd:MdProfile, will use the first one! </xsl:message>
        </xsl:if>
        <xsl:if test="count($schema) gt 1">
            <xsl:message>WRN: <xsl:value-of select="$base"/>: found more then one profile ID (<xsl:value-of select="string-join($schema, ',')"/>) in a xsi:schemaLocation, will use the first one! </xsl:message>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="normalize-space(($header)[1]) != '' and normalize-space(($schema)[1]) != ''">
                <xsl:if test="($header)[1] ne ($schema)[1]">
                    <xsl:message>WRN: <xsl:value-of select="$base"/>: the profile IDs found in cmd:MdProfile (<xsl:value-of select="($header)[1]"/>) and xsi:schemaLocation (<xsl:value-of select="($schema)[1]"/>), don't agree, will use the xsi:schemaLocation!</xsl:message>
                </xsl:if>
                <xsl:value-of select="normalize-space(($schema)[1])"/>
            </xsl:when>
            <xsl:when test="normalize-space(($header)[1]) != '' and normalize-space(($schema)[1]) = ''">
                <xsl:value-of select="normalize-space(($header)[1])"/>
            </xsl:when>
            <xsl:when test="normalize-space(($header)[1]) = '' and normalize-space(($schema)[1]) != ''">
                <xsl:value-of select="normalize-space(($schema)[1])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">ERR: <xsl:value-of select="$base"/>: the profile ID can't be determined!</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="cr-profile-xml" select="concat($cr-profiles, '/', $cmd-profile, $cr-extension-xml)"/>
    <xsl:variable name="prof" select="
            if (exists($profile)) then
                ($profile)
            else
                (doc($cr-profile-xml))"/>

    <!-- identity copy -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- handle delta -->

    <xsl:template name="upsert">
        <xsl:param name="node" select="current()"/>
        <xsl:param name="node-delta"/>
        <xsl:param name="node-prof"/>
        <xsl:message>?DBG:upsert:node[<xsl:value-of select="name($node)"/>]delta[<xsl:value-of select="name($node-delta[1])"/>][<xsl:value-of select="count($node-delta)"/>]prof[<xsl:value-of select="name($node-prof[1])"/>][<xsl:value-of select="count($node-prof)"/>]</xsl:message>
        <!-- attributes -->
        <!-- TODO -->
        <!-- value -->
        <xsl:if test="exists($node-prof/self::CMD_Element)">
            <xsl:choose>
                <xsl:when test="exists($node-delta)">
                    <xsl:comment>previous value[<xsl:value-of select="$node"/>]</xsl:comment>
                    <xsl:value-of select="$node-delta"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>generated empty value!</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- elements and components -->
        <xsl:for-each select="$node-prof/(CMD_Element | CMD_Component)">
            <xsl:variable name="c-name" select="@name"/>
            <xsl:variable name="c-prof" select="current()"/>
            <xsl:variable name="c-delta" select="$node-delta/node()[namespace-uri() = $cmd-ns][local-name() = $c-name]"/>
            <xsl:variable name="c-nodes" select="$node/node()[namespace-uri() = $cmd-ns][local-name() = $c-name]"/>
            <!-- follow the delta-->
            <xsl:choose>
                <xsl:when test="exists($c-delta)">
                    <xsl:choose>
                        <!-- follow existing nodes -->
                        <xsl:when test="exists($c-nodes)">
                            <xsl:apply-templates select="$c-nodes" mode="upsert">
                                <xsl:with-param name="node-delta" select="$c-delta"/>
                                <xsl:with-param name="node-prof" select="$c-prof"/>
                            </xsl:apply-templates>
                        </xsl:when>
                        <!-- create missing node(s) -->
                        <xsl:when test="empty($c-nodes)">
                            <xsl:comment>generate CMD XML</xsl:comment>
                            <xsl:call-template name="insert">
                                <xsl:with-param name="node-delta" select="$c-delta"/>
                            </xsl:call-template>
                            <xsl:comment>generatet CMD XML</xsl:comment>
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="$c-nodes"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="insert">
        <xsl:param name="node-prof" select="current()"/>
        <xsl:param name="node-delta" select="()"/>
        <xsl:for-each select="1 to max((1, count($node-delta), number(@CardinalityMin))) cast as xs:integer">
            <xsl:variable name="pos" select="position()"/>
            <xsl:element namespace="{$cmd-ns}" name="{$node-prof/@name}">
                <!-- attributes -->
                <!-- TODO -->
                <!-- value -->
                <xsl:if test="exists($node-prof/self::CMD_Element)">
                    <xsl:choose>
                        <xsl:when test="exists($node-delta[$pos])">
                            <xsl:value-of select="$node-delta[$pos]"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:comment>generated empty value!</xsl:comment>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                <!-- elements and components -->
                <xsl:for-each select="$node-prof/(CMD_Element | CMD_Component)">
                    <xsl:variable name="delta" select="$node-delta[$pos]/node()[namespace-uri() = $cmd-ns][local-name() = current()/@name]"/>
                    <xsl:choose>
                        <!-- follow the delta -->
                        <xsl:when test="exists($delta)">
                            <xsl:call-template name="insert">
                                <xsl:with-param name="node-delta" select="$delta"/>
                            </xsl:call-template>
                        </xsl:when>
                        <!-- create mandatory structure -->
                        <xsl:when test="number(@CardinalityMin) gt 0">
                            <xsl:call-template name="insert"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="node()" mode="upsert">
        <xsl:param name="node" select="current()"/>
        <xsl:param name="node-delta"/>
        <xsl:param name="node-prof"/>
        <xsl:copy>
            <xsl:call-template name="upsert">
                <xsl:with-param name="node" select="$node"/>
                <xsl:with-param name="node-delta" select="$node-delta"/>
                <xsl:with-param name="node-prof" select="$node-prof"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="cmd:Components">
        <xsl:message>?DBG:cmd:Components:profile[<xsl:value-of select="$cmd-profile"/>][<xsl:value-of select="$cr-profile-xml"/>][<xsl:value-of select="$prof/CMD_ComponentSpec/Header/Name"/>]</xsl:message>
        <xsl:variable name="node" select="current()"/>
        <xsl:copy>
            <xsl:call-template name="upsert">
                <xsl:with-param name="node" select="$node"/>
                <xsl:with-param name="node-delta" select="$delta//cmd:Components/upsert"/>
                <xsl:with-param name="node-prof" select="$prof/CMD_ComponentSpec"/>
            </xsl:call-template>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
