require './Sequences.rb'

inputs = ARGV
no_file = inputs[1]
gff_1 = inputs[2]
gff_2 = inputs[3]

output1 = File.open(no_file, mode: "w")                                                      
output1 << "Assignment 3\n\nGenes that do not contain the CTTCTT repeat in their exons:\n"
output1.close

output2 = File.open(gff_1, mode: "w")
output2 << "##gff-version 3\n"
output2.close

output3 = File.open(gff_2, mode: "w")
output3 << "##gff-version 3\n"
output3.close

input = File.open(inputs[0], "r").each do |gene_id|
  gene = gene_id.strip.upcase
  puts "Currently working in the input gene: #{gene_id}"
  search_exons(gene, no_file, gff_1, gff_2)
end
input.close







