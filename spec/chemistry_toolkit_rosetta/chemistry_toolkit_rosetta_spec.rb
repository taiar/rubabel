require 'spec_helper'

# http://ctr.wikia.com/wiki/Chemistry_Toolkit_Rosetta_Wiki


# these are written as if the user is starting the project from scratch in the
# style of the wiki.  We put the test files in the same folder as our specs so
# that the code can be copied directly into the wiki

# the code that should be copied is within the capture_stdout blocks

module Kernel
  def wiki_code(&block)
    block.call
  end

  alias_method :wiki_code_capture_stdout, :capture_stdout
end

def unlink(file)
  File.delete(file) if File.exist?(file)
end

describe 'Chemistry Toolkit Rosetta Wiki' do

  before(:each) do
    @orig_dir = Dir.pwd
    @wiki_spec_dir = File.dirname(__FILE__)
    Dir.chdir(@wiki_spec_dir)
    @keydir =  @wiki_spec_dir + "/key"
  end

  after(:each) do 
    Dir.chdir(@orig_dir)
  end

  it 'gets Heavy atom counts from an SD file' do
    #http://ctr.wikia.com/wiki/Heavy_atom_counts_from_an_SD_file
    output = wiki_code_capture_stdout do
      require 'rubabel'
      Rubabel.foreach("benzodiazepine.sdf.gz") {|mol| puts mol.ob.num_hvy_atoms }
    end
    output.should == IO.read( @keydir + "/" + "benzodiazepine_heavy_atom_counts.output.10.txt" )
  end

  it 'gets Ring counts in a SMILES file' do
    # http://ctr.wikia.com/wiki/Ring_counts_in_a_SMILES_file
    output = wiki_code_capture_stdout do
      require 'rubabel'
      Rubabel.foreach("benzodiazepine.sdf.gz") {|mol| puts mol.ob_sssr.size }
    end
    output.should == IO.read( @keydir + '/' + "benzodiazepine_ring_counts.output.10.txt" )
  end

  it 'Converts a SMILES string to canonical SMILES' do
    # http://ctr.wikia.com/wiki/Convert_a_SMILES_string_to_canonical_SMILES
    wiki_code do
      require 'rubabel'
      smiles = %w{CN2C(=O)N(C)C(=O)C1=C2N=CN1C CN1C=NC2=C1C(=O)N(C)C(=O)N2C}
      cans = smiles.map {|smile| Rubabel::Molecule.from_string(smile) }
      fail unless cans.reduce(:==)
    end
  end

  it 'Works with SD tag data' do
    # http://ctr.wikia.com/wiki/Working_with_SD_tag_data
    wiki_code do
      require 'rubabel'
      File.open("RULE5.sdf", 'w') do |out|
        Rubabel.foreach("benzodiazepine.sdf.gz") do |mol|
          mol.data["RULE5"] = 
            if mol.data.key?('PUBCHEM_XLOGP3')
              num_true = [
                mol.data["PUBCHEM_CACTVS_HBOND_DONOR"].to_i <= 5,
                mol.data["PUBCHEM_CACTVS_HBOND_ACCEPTOR"].to_i <= 10,
                mol.data["PUBCHEM_MOLECULAR_WEIGHT"].to_f <= 500,
                mol.data["PUBCHEM_XLOGP3"].to_f <= 5 
              ].count(true)
              if num_true >= 3 then "1" 
              else "0"
              end
            else
              "no logP"
            end
          out.print mol.write(:sdf)
        end
      end
      # NOTE for wiki: This updates the #2 line of each molfile to mention "OpenBabel" and the current timestamp, as it ought to.
    end
    (lines_got, lines_exp) = ["RULE5.sdf", @keydir + "/rule5.10.sdf"].map do |file|
      lines = IO.readlines(file).reject {|line| line =~ /OpenBabel/ }
    end
    lines_got[0,10].should == lines_exp[0,10]
    unlink "RULE5.sdf"
  end

  it 'Detects and reports SMILES and SDF parsing errors' do
    # http://ctr.wikia.com/wiki/Detect_and_report_SMILES_and_SDF_parsing_errors
    wiki_code do
      require 'rubabel'
      File.open("log.txt", 'w') do |out|
        %w(Q C1C).each do |smile|
          Rubabel::Molecule.from_string(smile) rescue out.puts "bad smiles #{smile}"
        end
      end
      # note: error catching can only be performed with the from_string
      # method at the moment.
    end
    IO.read("log.txt").should == "bad smiles Q\nbad smiles C1C\n"
    puts "^^^^^ (ignore the above warning, part of spec) ^^^^^"
    # TODO: implement error catching in file reading
    # TODO: muffle the warning that Open Babel spits out on unmatched ring
    # bonds.  Tried to capture stdout and stderr to no avail.
    unlink("log.txt")
  end

  it 'Reports how many SD file records are within a certain molecular weight range' do
    # http://ctr.wikia.com/wiki/Report_how_many_SD_file_records_are_within_a_certain_molecular_weight_range
    output = wiki_code_capture_stdout do
      require 'rubabel'
      puts Rubabel.foreach("benzodiazepine.sdf.gz").count {|mol| (300..400) === mol.mol_wt }
    end
    output.should == "7\n"
    # checked with large file and it came out to 3916, which is correct
  end

  it 'Converts SMILES file to SD file' do
    wiki_code do
      require 'rubabel'
      File.open("benzodiazepine.smi.sdf", 'w') do |out|
        Rubabel.foreach("benzodiazepine.smi.gz") do |mol|
          mol.make_3d!
          out.print mol.write_string(:sdf)
        end
      end
      # note: OpenBabel gets most stereochemistry correct.  When it cannot
      # the particular atoms are noted in a message to stderr
      # note: A minimal amount of optimization is performed in this routine
      # (following pybel's make3D routine) so that the molecule doesn't make
      # chemists reel.
    end
    unlink "benzodiazepine.smi.sdf"
  end

  it 'Reports the similarity between two structures' do
    output = wiki_code_capture_stdout do
      require 'rubabel'
      (mol1, mol2) = %w{CC(C)C=CCCCCC(=O)NCc1ccc(c(c1)OC)O COC1=C(C=CC(=C1)C=O)O}.map do |smile| 
        Rubabel::Molecule.from_string(smile) 
      end
      puts mol1.tanimoto(mol2)
    end
    output.should == "0.36046511627906974\n"
    # notes: reports similarity of 0.36046511627906974
  end

  it 'Finds the 10 nearest neighbors in a data set' do
    output = wiki_code_capture_stdout do
      require 'rubabel'
      mol_iter = Rubabel.foreach("benzodiazepine.sdf.gz")
      mol_iter.next
    end
  end


end


=begin
  p OpenBabel::OBOp.methods - Object.methods
  pgen = OpenBabel::OBOp.find_type("gen3D")
  p pgen.methods - Object.new.methods
  pgen.do(mol.ob)
  out.print mol.write_string(:sdf)
=end
