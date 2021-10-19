array = ARGV
stock = []
# Convert the file into an array
require 'csv'
CSV.open(array[1],"r", {col_sep:"\t"}).each do |stock1|
stock << stock1
end
# Creating and defining the class "Stock"
class Stock

  attr_accessor :seed_ID  
  attr_accessor :mutant_ID
  attr_accessor :last_planted
  attr_accessor :storage
  attr_accessor :grams
  
  def initialize (params = {})
    @seed_ID = params.fetch(:seed_ID, "00000")
    @mutant_ID = params.fetch(:mutant_ID, "000000000")
    @last_planted = params.fetch(:last_planted, "00/00/0000")
    @storage = params.fetch(:storage, 'unknown place')
    @grams = params.fetch(:grams, "0")
  
  end
    # Defining the function to plant 7 grams of seeds and update the date and the grams of stock into a new file
    def planting_seeds(grams_of_seed)
      before_planting = grams
    if before_planting == 0
       puts "There is no stock of #{seed_ID}"
    else
      last_planted = Date.today
      remain = grams.to_i - grams_of_seed
            if remain <= 0
        remain = 0
        puts "WARNING: We planted #{before_planting} grams of #{seed_ID}, but we have run out of stock!"
      else 
      end
    end
  File.open("new_stock_file.tsv", "a"){
    |f| f.write("\r\n#{seed_ID}\t#{mutant_ID}\t#{last_planted}\t#{storage}\t#{remain}\t")
    }
  end
end
# Writing the headers of the updated database file
File.write("new_stock_file.tsv", 
  ["Seed_Stock", "Mutant_Gene_ID", "Last_Planted", "Storage", "Grams_Remaining"].join("\t"))
# Definig the values of the Stock class and runing the function planting seeds
for i in (1..5)
  plants = Stock.new(
    :seed_ID => stock[i][0], 
    :mutant_ID => stock[i][1], 
    :last_planted => stock[i][2], 
    :storage => stock[i][3], 
    :grams => stock[i][4]
    )
  puts plants.planting_seeds(7)
end
cross = []
require 'csv'
CSV.open(array[2],"r", {col_sep:"\t"}).each do |cross1|
cross << cross1
end
# Convert the file into an array
gene = []
require 'csv'
CSV.open(array[0],"r", {col_sep:"\t"}).each do |gene1|
gene << gene1
end
# Creating and defining the Cross class
class Cross < Stock

  attr_accessor :parent1  
  attr_accessor :parent2
  attr_accessor :f2_wild
  attr_accessor :f2_p1
  attr_accessor :f2_p2
  attr_accessor :f2_p1p2
  
  
  def initialize (params = {})
    super(params)
    @parent1 = params.fetch(:parent1, "00000")
    @parent2 = params.fetch(:parent2, "00000")
    @f2_wild = params.fetch(:f2_wild, "0")
    @f2_p1 = params.fetch(:f2_p1, "0")
    @f2_p2 = params.fetch(:f2_p2, "0")
    @f2_p1p2 = params.fetch(:f2_p1p2, "0")
    
  end
  
  def chisq (gene_name, gene2)
     super f2_wild, f2_p1, f2_p2, f2_p1p2, gene_name, gene2
  end
    
  # Defining the function chisquare to check if the genes are linked or not 
  def chisq gene_name = 0, gene2 = 0
    total = f2_wild.to_f + f2_p1.to_f + f2_p2.to_f + f2_p1p2.to_f
    wild_exp = total*9/16
    p1_exp = total*3/16
    p2_exp = total*3/16
    p1p2_exp = total*1/16
    sum = ((f2_wild.to_f - wild_exp.to_f)**2/wild_exp.to_f) + ((f2_p1.to_f - p1_exp.to_f)**2/p1_exp.to_f) +((f2_p2.to_f - p2_exp.to_f)**2/p2_exp.to_f) + ((f2_p1p2.to_f - p1p2_exp.to_f)**2/p1p2_exp.to_f)
    if sum <= 7.815
    else 
      puts "The genes #{gene_name} and #{gene2} are linked with a chisquare score of #{sum}"
      puts "#{gene_name} is linked to #{gene2}"
      puts "#{gene2} is linked to #{gene_name}"
      
    end
    end
  end
class Gene < Cross

  attr_accessor :gene_ID  
  attr_accessor :gene_name
  attr_accessor :phenotype
  
  def initialize (params = {})
    super(params)
    @gene_ID = params.fetch(:gene_ID, "000000000")
    @gene_name = params.fetch(:gene_name, "000")
    @phenotype = params.fetch(:phenotype, 'Some phenotype')
  end
  def chisq 
    super gene_name
  end
  end
# Defining the values of the diferent properties of the class and runnig the chisquare function 
for i in (1..5)
  hibrid = Cross.new(
    :parent1 => cross[i][0], 
    :parent2 => cross[i][1], 
    :f2_wild => cross[i][2], 
    :f2_p1 => cross[i][3], 
    :f2_p2 => cross[i][4],
    :f2_p1p2 => cross[i][5]
    )
  
  gene_info = Gene.new(
    :gene_ID => gene[i][0],
    :gene_name => gene[i][1],
    :phenotype => gene[i][2]
    )
  

  if i != 6
    gene2 = gene[1][1]
  else
    gene2 = gene[i][1]
    i = i + 1
    puts gene_info.gene_name
    puts gene2
  end
  
  hibrid.chisq(gene_info.gene_name, gene2)
  
end
# I adapted the way of bulding and linking the classes from the user "andreaalvarezp" in GitHub, because I tried different ways, but did not work.

