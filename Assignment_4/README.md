## Program description and usage
This program searches for the possible orthologues among the sequences given in two different files.

Afterwards, it outputs a file with the results of the blast, in which the possible orthologues are indicated. This file is named: 'Blast_results.txt'.

The usage of this programs would be like this:

ruby Main.rb "input_sequence_file_1" "input_sequence_file_2"

Example:

ruby Main.rb DNA_sequences.fa Protein_sequences.fa

With the example given, we found 1,750 posible orthologues between Arabidopsis thaliana and Schizosaccharomyces pombe