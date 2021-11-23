## Program description and usage
This program searches the interactions for some given genes and their interactors, but only from Arabidopsis thaliana.
Afterwards, it builds the interaction networks for each input gene with all its direct interactors, and also with the genes that directly interact with these interactors (there is only one step of recursivity).
Moreover, the networks are accompanied by the GO ID, GO Term, KEGG ID and KEGG Pathways of the interacting members. However, these networks are not outputted.
Nevertheless, the main purpose of the program is to output the networks of the input genes that interact with other input genes. The program will output the results in the "Output file" indicated.
Finally, the usage of this programs is:
ruby Main.rb "Input gene list file" "Output file"
Example:
ruby Main.rb ArabidopsisSubNetwork_GeneList.txt Output.txt


