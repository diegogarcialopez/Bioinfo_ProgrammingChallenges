require './Blast.rb'

inputs = ARGV

ath_dna = inputs[0]
sce_prot = inputs[1]

system("rm -r Databases")                                       # Removing previoulsly created Databases

output = File.open('Blast_results.txt', mode: 'w')              # Writing the header of the results file
output << "Assignment 4\n\nGenes that could be orthologues:\n"
output.close

search_orthologues(ath_dna, sce_prot)                           # Searching for orthologues