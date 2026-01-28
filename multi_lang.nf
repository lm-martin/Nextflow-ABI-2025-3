#!/usr/bin/env nextflow

// this is a work in process

params.in = null
params.help = true

def usage() {
    log.info"""
    SYNOPSIS

        nextflow run <options> [file] [this script name]

        nextflow run [this script name] --help

        if you execute this script locally: 
        nextflow run --in PATH/to/your/data multi_lang.nf

        if executed from within GitHub:
        nextflow run lm-martin/Nextflow-ABI-2025-3/multi_lang.nf --in PATH/to/your/data

        DESCRIPTION

        This is a word counting script. It takes a path to a txt file or 
        a glob pattern as input, count the words in the specified file or
        files and returns the most common word in each file as output.

        The workflow is organized in three processes, each of them written in 
        a different language, Bash, python and R respectively.

        OPTIONS

        --in a file path or a glob pattern, e.g., "data/<filename>" or "data/*.txt"

        --help print this info

    """
}

process normalize_words{
    input:
        path word_file
    
    output: 
        path "out.normalized.txt"

    script:
        """
        cat $word_file \\
            | tr -s ' ' '\n' \\
            | tr -d '[:punct:]' \\
            | tr '[:upper:]' '[:lower:]' \\
        > out.normalized.txt
        """
}

process count_words{
    input: 
        path word_file

    output: 
        path "out.counted.txt"

    script:
        """
        cat "$word_file" \\
            | sort \\
            | uniq -c \\
            | sort -n \\
        > out.counted.txt
        """    
}

process take_most_common_word{
    input: 
        path word_file

    output: 
        path "out.most.common.word.txt"

    script:
        """
        cat "$word_file" \\
            | tail -1 \\
            | tr -s ' ' \\
            | cut -d ' ' -f 3 \\
        > out.most.common.word.txt
        """
}

workflow {
  if (params.help) {
    usage()
    exit 0
  }
  
    ch_input = channel.fromPath(params.in)

    normalize_words(ch_input)
        | count_words
        | take_most_common_word
}


