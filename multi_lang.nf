// this is a work in process

params.in = null

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
    ch_input = channel.fromPath(params.in)

    normalize_words(ch_input)
        | count_words
        | take_most_common_word
}


