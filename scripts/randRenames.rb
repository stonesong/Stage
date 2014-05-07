require 'rubygems'
require 'thor'

class Triple
  attr_accessor :one, :two, :three
  def initialize(one, two, three)
    @one = one
    @two = two
    @three = three
  end
end

class RandRenamesTools 

  def initialize(folder)
    @folder = folder
  end 

  def get_files(proj)
    `git --git-dir #{@folder}/#{proj}/.git ls-tree -r --name-only origin/master`.split("\n").map  
  end

  def get_logR(proj)
    `git --git-dir #{@folder}/#{proj}/.git log -M --summary --stat=1000,1000 --format=format:"%H" --reverse origin/master`.split("\n").map
  end

  def get_regexp(tab, proj)
    c = tab.clone
    case proj
    when "rails"
      tab.each do |f|
        if !f.match(/^((?!test)(?!vendor)(?!examples).)*\.rb$/)
          c.delete(f)
        end
      end
    when "phpunit"
      tab.each do |f|
        if !f.match(/^(?!Tests).*\.php$/) || !f.match(/^(?!tests).*\.php$/)
          c.delete(f)
        end
      end
    when "pyramid" 
      tab.each do |f|
        if !f.match(/pyramid\/((?!test).)*\.py$/)
          c.delete(f)
        end
      end
    when "jquery"
      tab.each do |f|
        if !f.match(/^src\/.*/)
          c.delete(f)
        end
      end
    when "jenkins"
      tab.each do |f|
        if !f.match(/^((?!test).)*\.java$/)
          c.delete(f)
        end
      end
    end
    c
  end

  def get_rand(array)
  end

  def get_renames(log, files)
    renamesT = Array.new()
    cpt=0
    sha1 = nil
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/[0-9a-f]{40}/)
        sha1 = String.new(line).strip
      end       
      if line.match(/\|/) && line.match("=>")
        lineF=String.new(line.split("|")[0])
        lineF.strip!
        if lineF.match(/\{/)
          if lineF.match('/=> \}/')
            file1=lineF.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
            file2=lineF.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\4')
          elsif lineF.match(/\{ =>/)
            file1=lineF.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\2')
            file2=lineF.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
          else
            file1=lineF.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
            file2=lineF.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
          end
        else
          file1=lineF.gsub(/(.*)( => )(.*)/, '\1')
          file2=lineF.gsub(/(.*)( => )(.*)/, '\3')
        end
        tr = Triple.new(sha1, lineF, file2)
        renamesT.concat([tr.clone])
        renamesT.each do |t|
          if t.three == file1
            t.three = file2.clone
          end
        end
      end      
      cpt=cpt+1
    end
    c = renamesT
    c.each do |t|
      if !files.include?(t.three)
        renamesT.delete(t)
      end
    end
    renamesT
  end

end

class GitRandRenames < Thor 
  desc "Returns rand renames", "Returns 100 random renames in commits detected on 5 projects"
  def randRenames(folder)
    tool = RandRenamesTools.new(folder)
    proj = ["phpunit"]
    allRenamesT = Array.new()
    num = 100

    proj.each do |p|
      files = Array(tool.get_files(p))
      files.map!{|line| line.strip}
      exfiles = files.clone
      files = tool.get_regexp(exfiles, p)
      
      logR = Array(tool.get_logR(p))
      logR.map!{|line| line.strip}
      
      renamesT = tool.get_renames(logR, p)
      allRenamesT.concat(renamesT.clone)
    end

    randRenamesT = tool.get_rand(allRenamesT, num)
    
    
      
      
      
      
  end
end

GitRandRenames.start(ARGV)

