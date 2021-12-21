## Program description and usage
This program searches for the possible orthologues among the sequences given in two different files.

Afterwards, it outputs a file with the results of the blast, in which the possible orthologues are indicated. This file is named: 'Blast_results.txt'.

The usage of this programs would be like this:

ruby Main.rb "input_sequence_file_1" "input_sequence_file_2"

Example:

ruby Main.rb DNA_sequences.fa Protein_sequences.fa

**With the example given, we found 1,750 possible orthologues between Arabidopsis thaliana and Schizosaccharomyces pombe.**

Bibliography:

Moreno-Hagelsieb, G., & Latimer, K. (2008). Choosing BLAST options for better detection of orthologs as reciprocal best hits. Bioinformatics, 24(3), 319-324.

Ward, N., & Moreno-Hagelsieb, G. (2014). Quickly finding orthologs as reciprocal best hits with BLAT, LAST, and UBLAST: how much do we miss?. PloS one, 9(7), e101850.

In the above scientific articles, it is recommended to select an e-value <= 10e-6 and a coverage >= 50% when looking for orthologues.

**To finally determine if the outputted genes are orthologues or not, we would have to check their function (e.g., their GO Ontologies), and confirm that they are the same or very similar.
Moreover, we would also have to perform a phylogenetic study to determine whether the homology between genes is a the result of a speciation event and both genes are orthologues
or by a duplication event and the genes are paralogs.**