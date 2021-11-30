require 'json'
require 'rest-client'
require 'bio'
  
  def fetch(url, headers = {accept: "*/*"}, user = "", pass="")     # Function to get a response for a web page.
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
  
  def write_no_cttctt(gene_without_cttctt, file)               # Function to write the first output file.
    add = File.open(file, "a")
    add.puts "#{gene_without_cttctt}"
    add.close
  end
  
  def write_gff1(array_of_exons, file)                                                                                                                               # Function to write the second output file.
    add = File.open(file, "a")
    array_of_exons.each do |feature|
      start = feature.position.to_s.split('..')[0]
      finish = feature.position.to_s.split('..')[1]
      qualifier_values = []
      feature.qualifiers.each do |qualifier|
      qualifier_values << qualifier.value                                                                                                                            # Adding the qualifiers values to a vector.
     end
      add.puts "#{qualifier_values[0]}\tBioRuby\tnucleotide_motif\t#{start}\t#{finish}\t.\t#{qualifier_values[2]}\t.\tID=#{qualifier_values[3]};Note=cttctt"         # Writing the file in the gff3 format.
    end      
    add.close
  end
  
  def write_gff2(array_of_exons, file)                 # Function to write the third output file.
    add = File.open(file, "a")
    array_of_exons.each do |feature|
      qualifier_values = []
      feature.qualifiers.each do |qualifier|
      qualifier_values << qualifier.value
    end
    start = qualifier_values[1].to_s.split('..')[0]
    finish = qualifier_values[1].to_s.split('..')[1]
    add.puts "chr#{qualifier_values[0][2]}\tBioRuby\tnucleotide_motif\t#{start}\t#{finish}\t.\t#{qualifier_values[2]}\t.\tID=#{qualifier_values[3]};Note=cttctt"
    end
    add.close
  end
  
  def search_exons(some_gene, file1, file2, file3)                                                                            # Function to search the cttctt repetition in the input gene exons.
    response = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{some_gene}")          # Link to www.ebi.ac.uk to get the exon sequence.
    if response
      record = response.body
      gene_start = record.match(/chromosome:\S+/).to_s.split(':')[3]                                                          # Getting the start of the gene in chromosomic coordinates.
      sequence = Bio::EMBL.new(record).to_biosequence                                                                         # Getting the gene sequence, and adding it as a new record.
      cttctt_exons = 0                                                                                                        # Setting the number of gene exons with the cttctt repetition to 0.
      sequence.features.each do |feature|
        if feature.feature == "exon"                                                                                          
          exon_region = feature.position.match(/\d+\.\.\d+/).to_s                                                             # Getting the position of the exon.
          exon = Bio::Feature.new('exon',exon_region)                                                                         # Creating the exon feature for the gene.
          exon.append(Bio::Feature::Qualifier.new('gene', some_gene))                                                         # Creating the gene qualifier for the exon feature.
          feature.qualifiers.each do |qualifier|
            exon_ID = qualifier.value.match(/(exon_id=((.*?)exon\d))/)[2].to_s                                                # Getting the exon ID.
            agi = exon_ID.split('.')[0]
            if agi.to_s == some_gene                                                                                          # Discarding exons of other genes.     
              exon.append(Bio::Feature::Qualifier.new('number', exon_ID))                                                     # Creating the exon ID qualifier for the exon feature..
              if not feature.position.match(/complement/)                                                                     # Checking on which strand is the gene. If it is in the positive one then...
                exon.append(Bio::Feature::Qualifier.new('strand', '+'))                                                       # Setting the strand qualifier of the exon feature to '+'.
                exon_region_limit1 = exon_region.split('..')[0]
                exon_region_limit2 = exon_region.split('..')[1]
                exon_sequence = sequence.subseq(exon_region_limit1.to_i, exon_region_limit2.to_i)                             # Getting the exon sequence.
                exon.append(Bio::Feature::Qualifier.new('sequence', exon_sequence))                                           # Adding the exon sequence as a qualifier of the exon feature.
                exon.qualifiers.each do |x|
                  if x.qualifier == "sequence" and not x.value.gsub(/(?=(cttctt))/).map{Regexp.last_match.begin(0)}.empty?    # Checking if there is a match for the cttctt repetition in the exon sequence.
                    match_positions = x.value.gsub(/(?=(cttctt))/).map{Regexp.last_match.begin(0)}                            # Note that this Regexp even checks for overlapping sequences. In the sequence cttcttctt there would be 2 matches.
                    match_begin = match_positions.map(&:succ)                                                                 # Adding +1 to the position given by the previous command, that starts counting in 0, instead of 1.
                    i = 0
                    all_match = Array.new                                                                                     # Creating an array to store the match feature and its qualifiers.
                    while i < match_begin.length
                      pos1 = match_begin[i].to_i + exon_region_limit1.to_i - 1                                                # Setting the start position of the match in genomic coordinates.
                      pos2 = match_begin[i].to_i + 5 + exon_region_limit1.to_i - 1                                            # Setting the end position of the match in genomic coordinates. Adding +5 because it is the match length.
                      chr1 = gene_start.to_i + pos1 - 1                                                                        
                      chr2 = gene_start.to_i + pos2 - 1                                                                       
                      match = Bio::Feature.new('match', pos1..pos2)                                                           # Setting the match feature and its start and end positions.
                      match.append(Bio::Feature::Qualifier.new('sequid', some_gene))                                          # Setting the sequid as the gene identifier.
                      match.append(Bio::Feature::Qualifier.new('chromosome_position', chr1..chr2))                            # Setting the start and end positions of the match in chromosomic coordinates.
                      match.append(Bio::Feature::Qualifier.new('strand', '+'))                                                # Setting the strand qualifier of the macth feature to '+'.
                      match.append(Bio::Feature::Qualifier.new('attribute2', exon_ID))                                        # Setting the exon ID as a match attribute.
                      all_match << match
                      i = i +1
                      cttctt_exons += 1                                                                                       # Adding +1 to the number of gene exons that contain the cttctt repeat.
                    end
                  write_gff1(all_match, file2)                                                                                # Writing the second output file.
                  write_gff2(all_match, file3)                                                                                # Writing the third output file.
                  end
                end
              else                                                                                                            # If the gene is in the negative strand then...
                exon.append(Bio::Feature::Qualifier.new('strand', '-'))                                                       # Setting the strand qualifier of the exon feature to '+'.
                exon_region_limit1 = exon_region.split('..')[0]
                exon_region_limit2 = exon_region.split('..')[1]
                exon_lenght = exon_region_limit2.to_i - exon_region_limit1.to_i
                exon_sequence = sequence.subseq(exon_region_limit1.to_i, exon_region_limit2.to_i).complement                  # Obtaining the complement sequence of the exon.
                exon.append(Bio::Feature::Qualifier.new('sequence', exon_sequence))
                exon.qualifiers.each do |x|
                  if x.qualifier == "sequence" and not x.value.gsub(/(?=(cttctt))/).map{Regexp.last_match.begin(0)}.empty?
                    match_positions = x.value.gsub(/(?=(cttctt))/).map{Regexp.last_match.begin(0)}
                    match_begin = match_positions.map(&:succ)
                    i = 0
                    all_match = Array.new
                    while i < match_begin.length
                      pos1 = exon_region_limit1.to_i + exon_lenght - (match_begin[i].to_i + 5) + 1                            # Setting the positions of the match in the - strand respect to the + one. This is due to the complementary conversion of the sequence done in previous steps.    
                      pos2 = exon_region_limit1.to_i + exon_lenght - match_begin[i].to_i + 1
                      chr1 = gene_start.to_i + pos1 - 1
                      chr2 = gene_start.to_i + pos2 - 1
                      match = Bio::Feature.new('match', pos1..pos2)
                      match.append(Bio::Feature::Qualifier.new('sequid', some_gene))
                      match.append(Bio::Feature::Qualifier.new('chromosome_position', chr1..chr2))
                      match.append(Bio::Feature::Qualifier.new('strand', '-'))                                                # Setting the strand qualifier of the macth feature to '+'.
                      match.append(Bio::Feature::Qualifier.new('attribute2', exon_ID))
                      all_match << match
                      i = i +1
                      cttctt_exons += 1
                    end
                  write_gff1(all_match, file2)
                  write_gff2(all_match, file3)
                  end
                end
              end
            else
              next
            end
          end
        end
      end
      if cttctt_exons == 0
       write_no_cttctt(some_gene, file1)                                                                                     # Adding the gene identifier to the file of genes without cttctt in their exons, if none of the gene exons have this motif.
      end
    end
  end