#!/usr/bin/env nextflow

// this is a work in process

params.in = null
params.help = false

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
        #!/usr/bin/env python3

        from collections import Counter
        from pathlib import Path
        from operator import itemgetter

        # open and read the normalized word file
        word_path = Path("$word_file")
        with word_path.open() as word_file:
            words = word_file.read().splitlines()

        # do the counting, and sort the results
        counts = Counter(words)
        sorted_words = [
        f"{count} {word}\\n"
        for count, word
        in sorted(counts.items(), key=itemgetter(1))
        ]

        # write the sorted word lines
        out_path = Path("out.counted.txt")
        with out_path.open("w") as out_file:
            out_file.writelines(sorted_words)
        """
}


process take_most_common_word{
    input: 
        path word_file

    output: 
        stdout 

    script:
        """
        #!/usr/bin/env -S Rscript

        word_counts <- readLines("$word_file")
        last_line <- tail(word_counts, n=1)
        most_common <- strsplit(trimws(last_line), " ")[[1]][1]
        # writeTable("out.counted.txt", most_common, sep=" ")
        # writeLines(most_common, "out.counted.txt")

        print(most_common)
        """
}

workflow {
  if (params.help) {
    usage()
    exit 0
  }
  
  if (params.in == null) {
    println("Missing parameter --in!")
    usage()
    exit 1
  }
  
    ch_input = channel.fromPath(params.in)

    normalize_words(ch_input)
        | count_words
        | take_most_common_word
}


