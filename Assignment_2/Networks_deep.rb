class InteractionNetwork                # Defining the class that content the networks for all of the genes in the input file  
  
  @@class_objects = Array.new           # Array containing every object of the class
  attr_accessor :gene_ID                # Core gene of the network
  attr_accessor :interactions           # All the genes that interact with the core gene after two steps of searching interactors
  attr_accessor :list_interactors       # List genes that interact with the core gene
  attr_accessor :go_p                   # GO Biological Process of all the interactors
  attr_accessor :go_list                # GO Biological Process of the interactors from the list
  attr_accessor :kegg_pathways          # KEGG ID and pathways of all the interactors
  attr_accessor :kegg_list              # KEGG ID and pathways of the interactors from the list
  
  def initialize (params = {})
    
    @gene_ID = params.fetch(:gene_ID, "000000000")
    @interactions = params.fetch(:interactions, Array.new)
    @list_interactors = params.fetch(:list_interactors, [])
    @go_p = params.fetch(:go_p, [])
    @go_list = params.fetch(:go_list, [])
    @kegg_pathways = params.fetch(:kegg_pathways, [])
    @kegg_list = params.fetch(:kegg_list, [])
    
    @@class_objects << self    
  end
  
  def self.fetch(url, headers = {accept: "*/*"}, user = "", pass="")   # Function to get a response for a web page
    
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
  
    def self.return_class        # Function to return every object of the class
      return @@class_objects
    end

  def find_go(gene1, to_list)                                                               # Function to find the "GO: Biological Process" of the genes
    res = InteractionNetwork.fetch("http://togows.org/entry/ebi-uniprot/#{gene1}/dr.json"); # Link to search for interctions indicated in "http://togows.dbcls.jp/"
    if res
      data = JSON.parse(res.body)
      if data[0] and data[0]["GO"]                                                          # Avoiding errors due to non-existent web page or GO terms for the gene
      data[0]["GO"].each do |go|
        if go[1].match(/P:/)                                                                # Matching the "P", term for the Biological Process
          go_term = go[0] + " " + go[1]
          if not (@go_p.include?(go_term))                                                  # Do not add redundant GOs
            @go_p << go_term
          end
          case
            when to_list == 2                                                               # If the interactor is in the list add also the GO ID and Term to @go_list
              if not (@go_p.include?(go_term))
                @go_p << go_term
              end
              if not (@go_list.include?(go_term))
                @go_list << go_term
              end
          end
        else
          next
        end
      end
    end
    else
      puts "togows.org failed - see STDERR for details..."                                  # Puts error if the web do not work
    end
  end
  
  def find_kegg(gene2, to_list)                                                                      # Function to find the "KEEG Pathways" of the genes
    ros = InteractionNetwork.fetch("http://togows.org/entry/kegg-genes/ath:#{gene2}/pathways.json"); # Link to search for interctions indicated in "http://togows.dbcls.jp/"
    if ros
      data = JSON.parse(ros.body)
      if data[0]                                                                                     # Avoiding errors due to non-existent web page
        data[0].each do |kegg|
          kegg_term = kegg[0]+":"+kegg[1]
          if not (@kegg_pathways.include?(kegg_term))                                                # Do not add redundant KEEGs
            @kegg_pathways <<  kegg_term
          end
          case
            when to_list == 2                                                                        # If the interactor is in the list add also the KEGGs to @kegg_list
              if not (@kegg_pathways.include?(kegg_term))
                @kegg_pathways <<  kegg_term
              end
              if not (@kegg_list.include?(kegg_term))
                @kegg_list << kegg_term
              end
          end
        end
      end
    else
      puts "togows.org failed - see STDERR for details..."                                           # Puts error if the web do not work
    end
  end
  
  def list_interactions(gene_to_check)                                                           # Function to check if an interactor is in the input list of genes
    if $list_of_genes.include?(gene_to_check) and not @list_interactors.include?(gene_to_check)  # If the interactor is in the list, add the GOs and KEEGs to @go_list and @kegg_list
      @list_interactors << gene_to_check
      find_go(gene_to_check, 2)
      find_kegg(gene_to_check, 2)
      return "is in the list"                                                                    # Checking is the interactor gene was or not in the input list
    end
  end
  
  def search_interactions(some_gene, depth)                                                                                  # Function to search for the interactions of a given gene
    if depth <= $max_depth                                                                                                   # Setting the depth of the recursivity to 2.
      depth = depth + 1
      link = InteractionNetwork.fetch("http://bar.utoronto.ca:9090/psicquic/webservices/current/search/query/#{some_gene}"); # Link to search for interctions indicated in "http://bar.utoronto.ca"
      if link 
        body = link.to_s.split("\n")
        body.each do |interaction|
          line = interaction.split("\t")
          agi1 = line[2].split(":")[1].upcase
          agi2 = line[3].split(":")[1].upcase
          tax1 = line[9].split(":")[1]
          tax2 = line[10].split(":")[1]
          score = line[14].split(":")[1]
          if tax1.to_i != 3702 or tax2.to_i !=3702                                                                           # Filtering by species (Arabidopsis thaliana).
            next
          elsif score.to_f < 0.45                                                                                            # Filtering by an intermediate score (DOI: 10.1093/database/bau131)
            next
          elsif some_gene.to_s == agi1.to_s and some_gene.to_s == agi2.to_s                                                  # Discarding interactions between the same gene         
            next
          elsif not (agi1.match(/AT\dG\d\d\d\d\d/)) or not (agi2.match(/AT\dG\d\d\d\d\d/))                                   # Discarding genes that does not match the structure of and AGI code
            next
          else
            case                                                                                                             # Checking the position of the query gene in the "interaction vector"
            when agi1.to_s == some_gene.to_s 
              ggi = [some_gene, agi2]
              ggi_inverse = [agi2, some_gene]
              if not (@interactions.include?(ggi)) and not (@interactions.include?(ggi_inverse)) and agi2 != @gene_ID        # Discarding redundant interactions
                @interactions << ggi 
                list_interactions(agi2)                                                                                      # Searching if the interactor is in the input list.
                if list_interactions(agi2) != "is in the list"                                                               # If the interactor is in the list the GOs and KEGGs are already searched
                  find_go(agi2, 1)                                                                                           # Search the GOs
                  find_kegg(agi2, 1)                                                                                         # Search the KEGGs
                end
                search_interactions(agi2, depth)                                                                             # Applying recursivity to search for interactions of the genes that interact with the input genes
              end
            else                                                                                                             # Doing the same process for cases in which the interactor vector comes in the inverted order
              ggi = [some_gene, agi1]
              ggi_inverse = [agi1, some_gene]
              if not (@interactions.include?(ggi)) and not (@interactions.include?(ggi_inverse)) and agi1 != @gene_ID 
                @interactions << ggi 
                list_interactions(agi1) 
                if list_interactions(agi1) != "is in the list"
                  find_go(agi2, 1) 
                  find_kegg(agi2, 1) 
                end
                search_interactions(agi1, depth) 
              end
            end
          end
        end
      else
        puts "bar.utoronto.ca call failed - see STDERR for details..."                                                       # Puts error if the web do not work
      end
    end
  end
end 