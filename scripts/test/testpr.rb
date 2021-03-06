require 'rubygems'
require 'thor'

class GitRenameDetector #Class for algo
  def initialize(file)
    @file = file
  end
  
  def get_log()
    `cat #{@file}`.split("\n").map
  end 

  def get_renames(log_array)
    log_array.grep(/=>/).grep(/\|/)
  end
  
  def get_prActRenamed(log_array, nbRenames, flag)
    if nbRenames > 0 
      hrenamed = Array.new()
      hmodified = Array.new()
      cpt=0
      while cpt < log_array.count do
        line = log_array[cpt]
        if line.match(/\|/)
          line = line.split("|")[0]
          line.strip!
          if line.match("=>")
            puts line
            if line.match("=> }")
              file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
              file2=line.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\4')
            elsif line.match("{ =>")
              file1=line.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\2')
              file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
            else
              file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
              file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
            end
            puts file1
            puts file2
            if hrenamed.include?(file1)
              hrenamed.delete(file1)
            end
            hrenamed.concat([file2])
            hmodified.concat([file2])
            hmodified.delete(file1)
          else
            file = line
            if !hmodified.include?(file)
              hmodified.concat([file])
            end
          end
        end
        if flag == 1
          if line.match("delete")
            file = line.gsub(/(.*)( )(.*)/, '\3')
            hrenamed.delete(file)
            hmodified.delete(file)
          end
        end
        cpt=cpt+1
      end
      puts hmodified
      hrenamed.count*10000/hmodified.count/100.to_f
    else
      0
    end
  end
  
end


class GitRename < Thor
  desc "tes", "test for algorithm"
  
  def test(file)
    detector = GitRenameDetector.new(file)
    log = Array(detector.get_log())
    nbRename = detector.get_renames(log).count
    prActRenamed = detector.get_prActRenamed(log, nbRename, 1)
    puts "prActRen :",prActRenamed
    
  end
end

GitRename.start(ARGV)
