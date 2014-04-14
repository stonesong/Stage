require 'rubygems'
require 'thor'

class GitRenameDetector #Class for algo
  def initialize(file)
    @file = file
  end
  
  def get_log()
    `cat #{@file}`.split("\n").map
  end
  
  def get_prActRenamed(log, nbModifiedfiles)
    if nbModifiedfiles > 1
      hrenamed = Array.new()
      hmodified = Array.new()
      cpt=0
      nbren=0
      nbrenok=0
      nbrennon=0
      nbmod=0
      nbmodok=0
      nbmodnon=0
      nbdel=0
      while cpt < log.count
        line = log[cpt]
        puts log[cpt]
        if line.match(/\|/)
          line = line.split("|")[0]
          line.strip!
          if line.match("=>")
            if !line.match("rename")
              puts "ren"
              nbren=nbren+1
              file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
              file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
              if hrenamed.include?(file1)
                puts "renok"
                nbrenok=nbrenok+1
                hrenamed.delete(file1)
              else
                puts "rennon"
                nbrennon=nbrennon+1
              end
              hrenamed.concat([file2])
              hmodified.concat([file2])
              hmodified.delete(file1)
            end
          else
            puts "mod"
            nbmod=nbmod+1
            file = line
            #puts file
            #puts hmodified
            if !hmodified.include?(file)
              puts "modnon"
              nbmodnon=nbmodnon+1
              hmodified.concat([file])
            else
              puts "modok"
              nbmodok=nbmodok+1
            end
          end
        end
        if line.match("delete")
          puts "del"
          nbdel=nbdel+1
          file = line.gsub(/(.*)( )(.*)/, '\3')
          puts "avant !",hrenamed
          hrenamed.delete(file)
          puts "apres !",hrenamed
          hmodified.delete(file)
        end
        cpt=cpt+1
      end
      puts "nbren",nbren
      puts "nbrenok",nbrenok
      puts "nbrennon",nbrennon
      puts "nbmod",nbmod
      puts "nbmodok",nbmodok
      puts "nbmodnon",nbmodnon
      puts "nbdel",nbdel
      puts "hmodified :",hmodified
      puts "hrenamed :",hrenamed
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
    nb = log.count
    prActRenamed = detector.get_prActRenamed(log, nb)
    puts "prActRen",prActRenamed
    
  end
end

GitRename.start(ARGV)
