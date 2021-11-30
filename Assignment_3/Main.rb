require './Sequences.rb'

inputs = ARGV
no_file = inputs[1]                                  # File with the genes that do not contain cttctt in their exons.
gff_1 = inputs[2]                                    # Gff3 file with genomic positions.
gff_2 = inputs[3]                                    # Gff3 file with chromosomic positions.

output1 = File.open(no_file, mode: "w")                                                         # Writing the header of the first output file.
output1 << "Assignment 3\n\nGenes that do not contain the CTTCTT repeat in their exons:\n"
output1.close

output2 = File.open(gff_1, mode: "w")               # Writing the header of the second output file.
output2 << "##gff-version 3\n"
output2.close

output3 = File.open(gff_2, mode: "w")               # Writing the header of the third output file.
output3 << "##gff-version 3\n"
output3.close

input = File.open(inputs[0], "r").each do |gene_id|                 # Getting the gene identifiers.
  gene = gene_id.strip.upcase
  puts "Currently working in the input gene: #{gene_id}"
  search_exons(gene, no_file, gff_1, gff_2)                         # Searching for the cttctt repetition in the gene exons.
end
input.close







