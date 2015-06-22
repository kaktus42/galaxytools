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
        <import>realigner_target_creator.xml</import>
        <import>indel_realigner.xml</import>
    </macros>

    <command><![CDATA[
        ############################
        ## create links to input files with correct extensions
        ############################
        ln -s -f ${reference.input_bam} input.bam &&
        ln -s -f ${reference.input_bam.metadata.bam_index} input.bam.bai &&

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
        --reference_sequence    ${reference.ref_file.fields.path}
        --log_to_file           ${output_log}

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
        2>&1 | awk '\$1 != "INFO" && \$1 != "WARN"' >&2
]]>
    </command>

    <inputs>

        <conditional name="reference">
            <param name="reference_source_selector" type="select" label="Choose the source for the reference list">
                <option value="cached">Locally cached</option>
                <option value="history">History</option>
            </param>
            <when value="cached">
                <param name="input_bam" type="data" format="bam" label="Input file containing sequence data (BAM)" help="-I, --input_file">
                    <validator type="unspecified_build" />
                    <validator type="dataset_metadata_in_data_table" table_name="picard_indexes" metadata_name="dbkey" metadata_column="dbkey" message="Sequences are not currently available for the specified build." /> 
                </param>
                <param name="ref_file" type="select" label="Using reference genome" help="-R,--reference_sequence &amp;lt;reference_sequence&amp;gt;" >
                    <options from_data_table="picard_indexes">
                        <filter type="data_meta" key="dbkey" ref="input_bam" column="dbkey"/>
                    </options>
                    <validator type="no_options" message="A built-in reference genome is not available for the build associated with the selected input file"/>
                </param>
            </when>
            <when value="history">
                <param name="input_bam" type="data" format="bam" label="BAM file" help="-I,--input_file &amp;lt;input_file&amp;gt;" />
                <param name="ref_file" type="data" format="fasta" label="Using reference file" help="-R,--reference_sequence &amp;lt;reference_sequence&amp;gt;">
                <options>
                    <filter type="data_meta" key="dbkey" ref="input_bam" />
                </options>
                </param>
            </when>
        </conditional>

        <conditional name="analysis_type">
            <param name="analysis_type_selector" type="select" label="Analysis Type">
                <xsl:for-each select="analysis/name">
                <option value="{.}"><xsl:value-of select="." /></option>
                </xsl:for-each>
            </param>
            <xsl:for-each select="analysis/name">
            <when value="{.}">
                <expand macro="{.}Parameters" />
            </when>
            </xsl:for-each>
        </conditional>
    </inputs>

    <outputs>
        <xsl:for-each select="analysis/name">
        <expand macro="{.}Output">
            <filter>analysis_type['analysis_type_selector'] == '<xsl:value-of select="." />'</filter>
        </expand>
        </xsl:for-each>
        <data format="txt" name="output_log" label="${{tool.name}} - ${{analysis_type.analysis_type_selector}} on ${{on_string}} (log)" />
    </outputs>
</tool>

</xsl:template>
</xsl:stylesheet>


