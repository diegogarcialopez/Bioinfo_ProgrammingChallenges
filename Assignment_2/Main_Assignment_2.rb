  require 'rest-client'
  require 'json'


class InteractionNetwork # Defining the class that content the networks for all of the genes in the input file
  
  attr_accessor :gene_ID  
  attr_accessor :interactions
  attr_accessor :go_ID
  attr_accessor :kegg_pathways
  
  
  def initialize (params = {})
    
    @gene_ID = params.fetch(:gene_ID, "000000000")
    @interactions = params.fetch(:interactions, Array.new)
    @go_bio = params.fetch(:go_bio, Array.new)
    @kegg_pathways = params.fetch(:kegg_pathways, Array.new)
    
    $AGI = @gene_ID # Making the gene_ID a global variable
  end
  
    def InteractionNetwork.fetch(url, headers = {accept: "*/*"}, user = "", pass="") # Function to get a response for a web page
  
    response = RestClient::Request.execute({
      method: :get,
      url: url.to_s,
      user: user,
      password: pass,
      headers: headers})

  return response
  
  rescue RestClient::ExceptionWithResponse => e
    $stderr.puts e.inspect
    response = false
    return response  
  rescue RestClient::Exception => e
    $stderr.puts e.inspect
    response = false
    return response  
  rescue Exception => e
    $stderr.puts e.inspect
    response = false
    return response  
    
end 
  
  def InteractionNetwork.find_go(gene1) # Function to find the "GO: Biological Process" of the genes
    res = InteractionNetwork.fetch("http://togows.org/entry/ebi-uniprot/#{gene1}/dr.json"); # Link to search for interctions indicated in "http://togows.dbcls.jp/"
    if res
      data = JSON.parse(res.body)
      if data[0] and data[0]["GO"] # Avoiding errors due to non-existent web page or GO terms for the gene
        final_go = []
      data[0]["GO"].each do |go|
        if go[1].match(/P:/) # Matching the "P", term for the Biological Process
          final_go << [go[0]+ go[1]]
          return final_go
        end
      end
    end
    else
      puts "togows.org failed - see STDERR for details..."
    end
  end
  
  def InteractionNetwork.find_kegg(gene2) # Function to find the "KEEG Pathways" of the genes
    ros = InteractionNetwork.fetch("http://togows.org/entry/kegg-genes/ath:#{gene2}/pathways.json"); # Link to search for interctions indicated in "http://togows.dbcls.jp/"
    if ros
      data = JSON.parse(ros.body)
      if data[0] # Avoiding errors due to non-existent web page
        final_kegg = []
      data[0].each do |kegg|
        final_kegg << [kegg[0]+":"+kegg[1]]
        return final_kegg 
      end
    end
    else
      puts "togows.org failed - see STDERR for details..."
    end
  end
  
  def search_interactions(some_gene, depth) # Function to search for the interactions of a given gene
    if depth <= 2 # Setting the depth of the recursivity to 2. That means that the program will only search the interactions for the given gene and its interactors
      depth = depth + 1
      link = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/#{some_gene}"); # Link to search for interctions indicated in "http://bar.utoronto.ca/affydb/BAR_instructions.html#AIV"
      if link 
        body = link.to_s.split("\n")
        body.each do |interaction|
          line = interaction.split("\t")
          agi1 = line[2].split(":")[1].upcase
          agi2 = line[3].split(":")[1].upcase
          tax1 = line[9].split(":")[1]
          tax2 = line[10].split(":")[1]
          score = line[14].split(":")[1]
          if tax1.to_i != 3702 or tax2.to_i !=3702 # Filtering by species (Arabidopsis thaliana).
            next
          elsif score.to_f < 0.45 # Filtering by an intermediate score (DOI: 10.1093/database/bau131)
            next
          elsif some_gene.to_s == agi1.to_s and some_gene.to_s == agi2.to_s # Discarding interactions beteen the same gene         
            next
          elsif not (agi1.match(/AT\dG\d\d\d\d\d/)) or not (agi2.match(/AT\dG\d\d\d\d\d/)) # Discarding genes that does not match the structure of and AGI code
            next
          else
            case # Checking the position of the query gene in the "interaction vector"
            when agi1.to_s == some_gene.to_s 
              ggi = [some_gene, agi2]
              ggi_inverse = [agi2, some_gene]
              if not (@interactions.include?(ggi)) and not (@interactions.include?(ggi_inverse)) and agi2 != @gene_ID # Discarding interaction that are already in the array
                @interactions << ggi # Adding interactions
                @go_bio << InteractionNetwork.find_go(agi2) # Adding GO Terms
                @kegg_pathways << InteractionNetwork.find_kegg(agi2) # Adding KEEG Pathways
                ListNetworks.is_in_the_list(agi2) # Searching if there is an interaction with another list gene to add it to ListNetworks.
                search_interactions(agi2, depth) # Applying recursivity to search for interactions of the genes linked to the input genes
              end
            else
              ggi = [some_gene, agi1]
              ggi_inverse = [agi1, some_gene]
              if not (@interactions.include?(ggi)) and not (@interactions.include?(ggi_inverse)) and agi1 != @gene_ID # Discarding interaction that are already in the array
                @interactions << ggi # Adding interactions
                @go_bio << InteractionNetwork.find_go(agi1) # Adding GO Terms
                @kegg_pathways << InteractionNetwork.find_kegg(agi1) # Adding KEEG Pathways
                ListNetworks.is_in_the_list(agi1) # Searching if there is an interaction with another list gene to add it to ListNetworks.
                search_interactions(agi1, depth) # Applying recursivity to search for interactions of the genes linked to the input genes
              end
            end
          end
        end
      else
        puts "bar.utoronto.ca call failed - see STDERR for details..."
    end
  end
end
end




  class ListNetworks
  
  @@all_interactions = Array.new
  attr_accessor :network_ID
  attr_accessor :interactors
  attr_accessor :network_go
  attr_accessor :network_kegg
  
  def initialize (params = {})
    @network_ID = params.fetch(:network_ID, "000000000")
    @interactors = params.fetch(:interactors, Array.new)
    @network_go = params.fetch(:network_go, Array.new)
    @network_kegg = params.fetch(:network_kegg, Array.new)
       
    @@all_interactions << self # Variable containing all the objects of this class
    
  end
  
  def ListNetworks.is_in_the_list(gene_to_check) # Function to create networks for genes of the input list that interact between them
if $list_of_genes.include?("#{gene_to_check}") 
      if @network_ID == nil
        ListNetworks.new(:network_ID => $AGI)
        @interactors |= [gene_to_check]
        @network_go |= [InteractionNetwork.find_go(gene_to_check)]
        @network_kegg |= [InteractionNetwork.find_kegg(gene_to_check)]
      elsif @network_ID.include?($AGI) and (not @interactors.include?(gene_to_check))
        @interactors << [gene_to_check]
        @network_go << [InteractionNetwork.find_go(gene_to_check)]
        @network_kegg << [InteractionNetwork.find_kegg(gene_to_check)]
      else
        ListNetworks.new(:network_ID => $AGI)
        @interactors << [gene_to_check]
        @network_go << [InteractionNetwork.find_go(gene_to_check)]
        @network_kegg << [InteractionNetwork.find_kegg(gene_to_check)]
      end
    end
  end
end
  
  
  
  
  
  
input_file = ARGV
$list_of_genes = []
input = File.open(input_file[0], "r").each do |gene_id| # Selecting the input genes that are in the input file
  $list_of_genes << gene_id.strip.upcase
  genes = InteractionNetwork.new(:gene_ID => gene_id.strip.upcase)
  genes.search_interactions(genes.gene_ID,1)
end
input.close

output = File.open(input_file[1], mode: "w") # Writting the output file
output << "Assignment 2\nLists of input genes networks that interact with other input genes:\n"
output.close
add = File.open(input_file[1], "a")
ListNetworks.class_variable_get(:@@all_interactions).each do |network| # I tried to output the results by several ways but none of them was correct. I tried this one, that makes sense in my head however, it does not work
  add.puts "\n"+network.to_s
end
add.close

# I could not finish this Assignment because I got stuck in different points and I finally run out of time
# This program can perform a network for the list given in the input file, however I could not find a way to output the results of the interacting genes of the list given
# Although I think that those networks are correctly arranged in the class ListNetworks