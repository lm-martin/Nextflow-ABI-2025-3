process count_words{
    input:
        path word_file
    script:
        """
        cat /Users/leonardo_martin/Nextflow/data/ipsum.txt \\
            | tr -s ' ' '\n' \\
            | tr -d '[:punct:]' \\
            | tr '[:upper:]' '[:lower:]' \\
            | sort \\
            | uniq -c \\
            | sort -n \\
            | tail -1 \\
            | tr -s ' ' \\
            | cut -d ' ' -f 3 \\
        > out.txt
        """
}

workflow {
    ch_input = channel.fromPath("/Users/leonardo_martin/Nextflow/data/ipsum.txt")
    count_words(ch_input)
}


