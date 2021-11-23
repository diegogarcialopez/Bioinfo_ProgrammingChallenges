  require 'rest-client'
  require 'json'
  require './Networks.rb'                                                        
  
inputs = ARGV
$max_depth = inputs[2]                                                                        # Let the user set the number of recursivity steps.

$list_of_genes = []
creating_list = File.open(inputs[0], "r").each do |gene_id|                                   # Creating a global varible containing all the input genes.
    $list_of_genes << gene_id.strip.upcase
end

input = File.open(inputs[0], "r").each do |gene_id|                                           # Adding the input genes to @gene_id.
  genes = InteractionNetwork.new(:gene_ID => gene_id.strip.upcase)
  puts "Currently working in the input gene: #{gene_id}"
  genes.search_interactions(genes.gene_ID, 1)
end
input.close

output = File.open(inputs[1], mode: "w") # Writting the output file                           # Writing the header of the output file.
output << "Assignment 2\nNetworks of input genes that interact with other input genes:\n\n-----------------------------------------------------------------------------------\n"
output.close

add = File.open(inputs[1], "a")                                                               # Adding the networks to the output file.
i = 0
InteractionNetwork.return_class.each do |network|
  if network.list_interactors.empty?
    next
  else
    i = i + 1
    add.puts "\nNetwork #{i}\n\n"
    add.puts "\nNetwork ID:" + " #{network.gene_ID}\n\n"
    add.puts "Interactor genes:\n"
    network.list_interactors.each do |interacting_genes|
      add.puts "\t#{interacting_genes}"
    end
    if network.go_list.empty?
      add.puts "GO Biological Process of the network:\n\tNo GO ID (nor GO Term) associated with this network\n"
    else
      add.puts "GO Biological Process of the network:\n"
      network.go_list.each do |go|
        add.puts "\t#{go}\n"
        end
    end
    if network.kegg_list.empty?
      add.puts "KEGG Pathways of the network:\n\tNo Kegg ID (nor Kegg Pathways) associated with this network\n"
    else
      add.puts "KEGG Pathways of the network:\n"
      network.kegg_list.each do |kegg|
        add.puts "\t#{kegg}\n"
      end
    end
    add.puts "\n-----------------------------------------------------------------------------------"
  end
end
puts "The program finished successfully. The resulting networks are detailed in the file #{inputs[1]}"
add.close