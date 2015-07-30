<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
    method="xml"
    encoding="utf-8"
    indent="yes"
    cdata-section-elements="script style" />

<xsl:template match="/">

<tool id="gatk" name="GATK" version="@VERSION@.d7">
    <description>tool collection Version @VERSION@</description>

    <macros>
        <import>gatk_macros.xml</import>
        <xsl:for-each select="analyses/analysis">
        <import><xsl:value-of select="macro_file" /></import>
        </xsl:for-each>
    </macros>

    <expand macro="requirements" />

    <stdio>
        <regex match="^INFO" level="log" />
        <regex match="^WARN" level="warning" />
        <regex match="Using .* implementation of PairHMM" level="warning" />
        <regex match="There is insufficient memory for the Java Runtime Environment to continue" level="fatal" />
        <regex match="^##### ERROR" level="fatal" />
        <exit_code range="1:" level="fatal"/>
    </stdio>

    <command>
<xsl:text disable-output-escaping="yes">&lt;![CDATA[
        ############################
        ## import analysis specific preprocessings by using cheetahs internal searchList
        ## if not defined, ignore
        ############################
        #if $analysis_type.analysis_type_selector + "Preprocessing" in vars()['SL'][2]
            #set $analysisPreprocessing = vars()['SL'][2][$analysis_type.analysis_type_selector + "Preprocessing"]
            #include source=$analysisPreprocessing
        #end if
        
        ############################
        ## GATK tool unspecific options
        ############################
        @GATK_EXEC@
        
        --analysis_type ${analysis_type.analysis_type_selector}
        --reference_sequence    ${ref_file.fields.path}

        --log_to_file           ${output_log}

        #if $cond_intervals.cond_intervals_enabled
            #for $interval in $cond_intervals.intervals:
                --intervals ${interval.L}
            #end for
        #end if

        #if $cond_BQSR.cond_BQSR_enabled
          --BQSR $cond_BQSR.BQSR
        #end if

        ############################
        ## import analysis specific options by using cheetahs internal searchList
        ## if not defined throw raw python error until better idea
        ############################
        #if $analysis_type.analysis_type_selector + "Options" in vars()['SL'][2]
            #set $analysisOptions = vars()['SL'][2][$analysis_type.analysis_type_selector + "Options"]
            #include source=$analysisOptions
        #else
            #set $analysisOptions = vars()['SL'][2][$analysis_type.analysis_type_selector + "Options"]
        #end if
        
        ############################
        ## only put ERROR or FATAL log messages into stderr
        ## but keep full log for printing into log file
        ############################
        2>&amp;1 | awk '\$1 != "INFO" &amp;&amp; \$1 != "WARN"' >&amp;2
]]&gt;</xsl:text>
    </command>

    <inputs>

        <param name="ref_file" type="select" label="Using reference genome" help="-R,&#8209;&#8209;reference_sequence &amp;lt;reference_sequence&amp;gt;" >
            <options from_data_table="picard_indexes">
                <!--filter type="data_meta" key="dbkey" ref="@TAG@_input" column="dbkey" /-->
            </options>
            <validator type="no_options" message="A built-in reference genome is not available for the build associated with the selected input file"/>
        </param>

        <conditional name="cond_intervals">
            <param name="cond_intervals_enabled" type="boolean" label="Select interval subset to operate on?" />
            <when value="true">
                <repeat name="intervals" title="genomic interval over which to operate" help="-L,&#8209;&#8209;intervals &amp;lt;intervals&amp;gt;">
                    <param name="L" type="text" value="" />
                </repeat>
            </when>
            <when value="false" />
        </conditional>

        <conditional name="cond_BQSR">
            <param name="cond_BQSR_enabled" type="boolean" label="Select covariates for on-the-fly recalibration?" />
            <when value="true">
                <param name="BQSR" type="data" format="tabular" label="Input covariates table file for on-the-fly base quality score recalibration" help="-BQSR,&#8209;&#8209;BQSR &amp;lt;BQSR&amp;gt; intended primarily for use with BaseRecalibrator and PrintReads" />
            </when>
            <when value="false" />
        </conditional>

        <conditional name="analysis_type">
            <param name="analysis_type_selector" type="select" label="Analysis Type">
                <xsl:for-each select="analyses/analysis">
                <option value="{name}"><xsl:value-of select="name" /></option>
                </xsl:for-each>
            </param>
            <xsl:for-each select="analyses/analysis">
            <when value="{name}">
                <!--xsl:choose>
                    <xsl:when test="input_type = 'bam'">
                        <expand macro="macro_bam_input" tag="{tag}" />
                    </xsl:when>
                    <xsl:when test="input_type = 'gvcf'">
                        <expand macro="macro_gvcf_input" tag="{tag}" />
                    </xsl:when>
                </xsl:choose-->
                <expand macro="{name}Parameters" tag="{tag}" />
            </when>
            </xsl:for-each>
        </conditional>
    </inputs>

    <outputs>
        <xsl:for-each select="analyses/analysis">
        <expand macro="{name}Output" tag="{tag}">
            <filter>analysis_type['analysis_type_selector'] == '<xsl:value-of select="name" />'</filter>
        </expand>
        </xsl:for-each>
        <data format="txt" name="output_log" label="${{tool.name}} - ${{analysis_type.analysis_type_selector}} on ${{on_string}} (log)" />
    </outputs>

    <expand macro="macro_tests" />

    <citations>
        <citation type="doi">10.1101/gr.107524.110</citation>
        <citation type="doi">10.1038/ng.806</citation>
        <citation type="doi">10.1002/0471250953.bi1110s43</citation>
    </citations>
</tool>

</xsl:template>
</xsl:stylesheet>


