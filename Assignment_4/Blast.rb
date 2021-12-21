require 'bio'

def make_db(file, type)                                                                   # Function to create databases
  db_name = file.split('.')[0].to_s                                                       # Assigning the name to the database as the file name without its extension
  if type == Bio::Sequence::NA                                                            # Determining the database type. The database is either a nucleic or protein database
    db_type = 'nucl'
    system("makeblastdb -in '#{file}' -dbtype #{db_type} -out ./Databases/#{db_name}")
  elsif type == Bio::Sequence::AA
    db_type = 'prot'
    system("makeblastdb -in '#{file}' -dbtype #{db_type} -out ./Databases/#{db_name}")
  else
    abort "Incorrect sequence type"
  end
  return db_type                                                                          # Returning the database type
end

def write_output_file(gene1, gene2, tblastn_evalue, tblastn_coverage, blastx_evalue, blastx_coverage)              # Writing the output file 'Blast_results.txt'
  tbn_coverage = tblastn_coverage.to_f*100
  bx_coverage = blastx_coverage.to_f*100
  add = File.open('Blast_results.txt', mode: 'a')
  add.puts "#{gene1} and #{gene2}. The e-values and coverages for the Blasts are the following:"
  add.puts "\ttblastn: E-value = #{tblastn_evalue}; Coverage = #{tbn_coverage}"
  add.puts "\tblastx: E-value = #{blastx_evalue}; Coverage = #{bx_coverage}"
  add.close    
end

def blast(query_id, query_sequence, blast1, blast2, sequences)                                                                       # Function to make the blasts
  puts "Searching for #{query_id} hits in Aabidopsis thaliana"
  search_results = blast1.query(query_sequence)                                                                                      # Blasting the sequence with the first blast method
  if not search_results.hits.empty?                                                                                                  # Checking if there are hits
    best_hit = search_results.hits[0]
    hit_id = best_hit.definition.match(/(\w+\.\w+)|/).to_s                                                                           # Getting the best hit id
    hit_coverage = (best_hit.query_end.to_f - best_hit.query_start.to_f)/best_hit.query_len.to_f                                     # Calculating the query coverage
    if best_hit.evalue <= 10**-6 and hit_coverage >= 0.5                                                                             # Filtering for coverage and e-value
      puts "Searching for reciprocal hits for #{hit_id} in Schizosaccharomyces pombe"
      reciprocal_search = blast2.query(sequences[hit_id])                                                                            # Making the reciprocal blast with the second blast method
      if not reciprocal_search.hits.empty?                                                                                           # Checking if there are hits
        reciprocal_hit = reciprocal_search.hits[0]
        reciprocal_hit_id = reciprocal_hit.definition.match(/(\w+\.\w+)|/).to_s                                                      # Getting the best hit id
        reciprocal_hit_coverage = (reciprocal_hit.query_end.to_f - reciprocal_hit.query_start.to_f)/(reciprocal_hit.query_len.to_f)  # Calculating the query coverage
        if reciprocal_hit.evalue <= 10**-6 and reciprocal_hit_coverage >= 0.5                                                        # Filtering for coverage and e-value
          if query_id == reciprocal_hit_id                                                                                           # Checking that the first query id is the same as the obtained in the reciprocal blast
            puts "It is a recirpocal match!"
            write_output_file(query_id, hit_id, best_hit.evalue, hit_coverage, reciprocal_hit.evalue, reciprocal_hit_coverage)       # Writing the output file
          end
        end
      end
    end
  end
end

def blast_type(file_1, type_1, file_2, type_2)                          # Function to determine the blast type
  db1_name = file_1.split('.')[0].to_s
  db2_name = file_2.split('.')[0].to_s
  if type_1 == 'nucl' and type_2 == 'nucl'                              # Checkin the type of databases, and perform the appropiate blasts
    search1 = Bio::Blast.local('blastn', "./Databases/#{db1_name}")     
    search2 = Bio::Blast.local('blastn', "./Databases/#{db2_name}")
  elsif type_1 == 'nucl' and type_2 == 'prot'
    search1 = Bio::Blast.local('tblastn', "./Databases/#{db1_name}")
    search2 = Bio::Blast.local('blastx', "./Databases/#{db2_name}")
  elsif type_1 == 'prot' and type_2 == 'nucl'
    search1 = Bio::Blast.local('blastx', "./Databases/#{db1_name}")
    search2 = Bio::Blast.local('tblastn', "./Databases/#{db2_name}")
  elsif type_1 == 'prot' and type_2 == 'prot'
    search1 = Bio::Blast.local('blastp', "./Databases/#{db1_name}")
    search2 = Bio::Blast.local('blastp', "./Databases/#{db2_name}")
  end
  return [search1, search2]                                            # Returning the proper blast and reciprocal blast according to the databases types
end

def search_orthologues(file1, file2)                             # Function to search for the orthologues
  sequence1 = Bio::FastaFormat.open(file1)                         
  sequence2 = Bio::FastaFormat.open(file2)
  type1 = sequence1.next_entry.to_biosequence.guess              # Obtaining the sequence type of the file
  type2 = sequence2.next_entry.to_biosequence.guess              # Obtaining the sequence type of the file
  sequence1_hash = Hash.new                                      # Creating a hash of the first file, with the ids linked to their sequences
  sequence1.each do |sequence|
    sequence1_hash[sequence.entry_id.to_s] = sequence.seq.to_s
  end
  system("mkdir Databases")                                      # Creating the folder for the databases
  file1_type = make_db(file1, type1)                             # Creating the database for the first file and obtaining the database type
  file2_type = make_db(file2, type2)                             # Creating the database for the second file and obtaining the database type
  searches = blast_type(file1, file1_type, file2, file2_type)    # Obtaining the blast types
  search1 = searches[0]
  search2 = searches[1]
  sequence2.each do |fasta_seq|                                  # Obtaining each sequence from the second file
    id = fasta_seq.entry_id.to_s
    sequence = fasta_seq.seq.to_s
    blast(id, sequence, search1, search2, sequence1_hash)        # Performing the blast for each sequence in the second file
  end
  puts "The results of the Blast are in the file called 'Blast_results.txt'"
end