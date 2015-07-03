<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output
    method="xml"
    encoding="utf-8"
    indent="yes"
    cdata-section-elements="script style" />

<xsl:template match="/">

<tool id="gatk" name="GATK" version="@VERSION@.d2">
    <description>tool collection Version @VERSION@</description>

    <macros>
        <import>gatk_macros.xml</import>
        <xsl:for-each select="analyses/analysis">
        <import><xsl:value-of select="macro_file" /></import>
        </xsl:for-each>
    </macros>

    <command>
<xsl:text disable-output-escaping="yes">&lt;![CDATA[
        ############################
        ## create links to input files with correct extensions
        ############################
        ln -s -f ${cond_reference.input_bam} input.bam &amp;&amp;
        ln -s -f ${cond_reference.input_bam.metadata.bam_index} input.bam.bai &amp;&amp;

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

        --input_file            input.bam
        --reference_sequence    ${cond_reference.ref_file.fields.path}
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

        <conditional name="cond_reference">
            <param name="cond_reference_selector" type="select" label="Choose the source for the reference list">
                <option value="cached">Locally cached</option>
                <!--option value="history">History</option-->
            </param>
            <when value="cached">
                <param name="input_bam" type="data" format="bam" label="Input file containing sequence data (BAM)" help="-I, &#8209;&#8209;input_file">
                    <validator type="unspecified_build" />
                    <validator type="dataset_metadata_in_data_table" table_name="picard_indexes" metadata_name="dbkey" metadata_column="dbkey" message="Sequences are not currently available for the specified build." /> 
                </param>
                <param name="ref_file" type="select" label="Using reference genome" help="-R,&#8209;&#8209;reference_sequence &amp;lt;reference_sequence&amp;gt;" >
                    <options from_data_table="picard_indexes">
                        <filter type="data_meta" key="dbkey" ref="input_bam" column="dbkey"/>
                    </options>
                    <validator type="no_options" message="A built-in reference genome is not available for the build associated with the selected input file"/>
                </param>
            </when>
            <!--when value="history">
                <param name="input_bam" type="data" format="bam" label="BAM file" help="-I,&#8209;&#8209;input_file &amp;lt;input_file&amp;gt;" />
                <param name="ref_file" type="data" format="fasta" label="Using reference file" help="-R,&#8209;&#8209;reference_sequence &amp;lt;reference_sequence&amp;gt;">
                <options>
                    <filter type="data_meta" key="dbkey" ref="input_bam" />
                </options>
                </param>
            </when-->
        </conditional>

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
                <param name="BQSR" type="data" format="table" label="Input covariates table file for on-the-fly base quality score recalibration" help="-BQSR,&#8209;&#8209;BQSR &amp;lt;BQSR&amp;gt; intended primarily for use with BaseRecalibrator and PrintReads" />
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
                <expand macro="{name}Parameters" />
            </when>
            </xsl:for-each>
        </conditional>
    </inputs>

    <outputs>
        <xsl:for-each select="analyses/analysis">
        <expand macro="{name}Output">
            <filter>analysis_type['analysis_type_selector'] == '<xsl:value-of select="name" />'</filter>
        </expand>
        </xsl:for-each>
        <data format="txt" name="output_log" label="${{tool.name}} - ${{analysis_type.analysis_type_selector}} on ${{on_string}} (log)" />
    </outputs>
</tool>

</xsl:template>
</xsl:stylesheet>


