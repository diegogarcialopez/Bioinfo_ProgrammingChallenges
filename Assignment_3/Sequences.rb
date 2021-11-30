require 'json'
require 'rest-client'
require 'bio'
  
  def fetch(url, headers = {accept: "*/*"}, user = "", pass="")
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
  
  def write_no_cttctt(gene_without_cttctt, file)
    add = File.open(file, "a")
    add.puts "#{gene_without_cttctt}"
    add.close
  end
  
  def write_gff1(array_of_exons, file)
    add = File.open(file, "a")
    array_of_exons.each do |feature|
      start = feature.position.to_s.split('..')[0]
      finish = feature.position.to_s.split('..')[1]
      qualifier_values = []
      feature.qualifiers.each do |qualifier|
      qualifier_values << qualifier.value
      end
      add.puts "#{qualifier_values[0]}\tBioRuby\tnucleotide_motif\t#{start}\t#{finish}\t.\t#{qualifier_values[2]}\t.\trepetitive_motif=CTTCTT;ID=#{qualifier_values[3]}"
    end      
    add.close
  end
  
  def write_gff2(array_of_exons, file)
    add = File.open(file, "a")
    array_of_exons.each do |feature|
      qualifier_values = []
      feature.qualifiers.each do |qualifier|
      qualifier_values << qualifier.value
    end
    start = qualifier_values[1].to_s.split('..')[0]
    finish = qualifier_values[1].to_s.split('..')[1]
    add.puts "chr#{qualifier_values[0][2]}\tBioRuby\tnucleotide_motif\t#{start}\t#{finish}\t.\t#{qualifier_values[2]}\t.\trepetitive_motif=CTTCTT;ID=#{qualifier_values[3]}"
    end
    add.close
  end
  
  def search_exons(some_gene, file1, file2, file3)
    response = fetch("http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ensemblgenomesgene&format=embl&id=#{some_gene}")
    if response
      record = response.body
      gene_start = record.match(/chromosome:\S+/).to_s.split(':')[3]
      gene_finish = record.match(/chromosome:\S+/).to_s.split(':')[4]
      gene_length = gene_finish.to_i - gene_start.to_i + 1
      sequence = Bio::EMBL.new(record).to_biosequence
      cttctt_exons = 0
      sequence.features.each do |feature|
        if feature.feature == "exon"
          exon_region = feature.position.match(/\d+\.\.\d+/).to_s
          exon = Bio::Feature.new('exon',exon_region)
          exon.append(Bio::Feature::Qualifier.new('gene', some_gene))
          feature.qualifiers.each do |qualifier|
            exon_ID = qualifier.value.match(/(exon_id=((.*?)exon\d))/)[2].to_s
            agi = exon_ID.split('.')[0]
            if agi.to_s == some_gene
              exon.append(Bio::Feature::Qualifier.new('number', exon_ID))
              if not feature.position.match(/complement/)
                exon.append(Bio::Feature::Qualifier.new('strand', '+'))
                exon_region_limit1 = exon_region.split('..')[0]
                exon_region_limit2 = exon_region.split('..')[1]
                exon_sequence = sequence.subseq(exon_region_limit1.to_i, exon_region_limit2.to_i)
                exon.append(Bio::Feature::Qualifier.new('sequence', exon_sequence))
                exon.qualifiers.each do |x|
                  if x.qualifier == "sequence" and not x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.begin(0)}.empty?
                    match_positions = x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.begin(0)}
                    match_begin = match_positions.map(&:succ)
                    match_end = x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.end(0)}
                    i = 0
                    all_match = Array.new
                    while i < match_begin.length
                      pos1 = match_begin[i].to_i + exon_region_limit1.to_i - 1
                      pos2 = match_end[i].to_i + exon_region_limit1.to_i - 1
                      chr1 = gene_start.to_i + pos1 - 1
                      chr2 = gene_start.to_i + pos2 - 1
                      match = Bio::Feature.new('match', pos1..pos2)
                      match.append(Bio::Feature::Qualifier.new('sequid', some_gene))
                      match.append(Bio::Feature::Qualifier.new('chromosome_position', chr1..chr2))
                      match.append(Bio::Feature::Qualifier.new('strand', '+'))
                      match.append(Bio::Feature::Qualifier.new('attribute2', exon_ID))
                      all_match << match
                      i = i +1
                      cttctt_exons += 1
                    end
                  write_gff1(all_match, file2)
                  write_gff2(all_match, file3)
                  end
                end
              else
                exon.append(Bio::Feature::Qualifier.new('strand', '-'))
                exon_region_limit1 = exon_region.split('..')[0]
                exon_region_limit2 = exon_region.split('..')[1]
                exon_lenght = exon_region_limit2.to_i - exon_region_limit1.to_i
                exon_sequence = sequence.subseq(exon_region_limit1.to_i, exon_region_limit2.to_i).complement
                exon.append(Bio::Feature::Qualifier.new('sequence', exon_sequence))
                exon.qualifiers.each do |x|
                  if x.qualifier == "sequence" and not x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.begin(0)}.empty?
                    match_positions = x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.begin(0)}
                    match_begin = match_positions.map(&:succ)
                    match_end = x.value.gsub(/ctt(ctt)+/).map{Regexp.last_match.end(0)}
                    i = 0
                    all_match = Array.new
                    while i < match_begin.length
                      pos1 = exon_region_limit1.to_i + exon_lenght - match_end[i].to_i + 1
                      pos2 = exon_region_limit1.to_i + exon_lenght - match_begin[i].to_i + 1
                      chr1 = gene_start.to_i + pos1 - 1
                      chr2 = gene_start.to_i + pos2 - 1
                      match = Bio::Feature.new('match', pos1..pos2)
                      match.append(Bio::Feature::Qualifier.new('sequid', some_gene))
                      match.append(Bio::Feature::Qualifier.new('chromosome_position', chr1..chr2))
                      match.append(Bio::Feature::Qualifier.new('strand', '-'))
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
       write_no_cttctt(some_gene, file1)
      end
    end
  end