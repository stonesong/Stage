require 'rubygems'
require 'thor'

class Quadruple
  attr_accessor :one, :two, :three, :four
  def initialize(one, two, three, four)
    @one = one
    @two = two
    @three = three
    @four = four
  end
end

class RandRenamesTools 

  def initialize(folder, file)
    @folder = folder
    @file = file
  end 

  def get_files(proj, vers)
    `git --git-dir #{@folder}/#{proj}/.git ls-tree -r --name-only #{vers}`.split("\n").map  
  end

  def get_logR(proj, vers1, vers2)
    `git --git-dir #{@folder}/#{proj}/.git log -M --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers1}..#{vers2}`.split("\n").map
  end

    def get_branchLogR(proj, vers)
      `git --git-dir #{@folder}/#{proj}/.git log -M --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers} --not master`.split("\n").map
  end

  def get_initLogR(proj, vers)
    `git --git-dir #{@folder}/#{proj}/.git log -M --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers}`.split("\n").map
  end
  
  def get_majorReleases(proj)
    `cat #{@folder}/#{proj}/#{@file}`.split("\n").map
  end

  def get_branches(proj)
    `git --git-dir #{@folder}/#{proj}/.git branch -r | sed '/->/d' | sed -e 's/^ *//g'`.split("\n").map
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

  def get_rand(array, num)
    r = (0..array.count-1).to_a.shuffle
    res = Array.new()
    i = 0
    while i < num do
      new = r.pop
      res.concat([array[new].clone])
      i = i+1
    end
    res
  end

  def get_renames(log, files, proj)
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
        tr = Quadruple.new(sha1, lineF, file2, proj)
        renamesT.concat([tr.clone])
        renamesT.each do |t|
          if t.three == file1
            t.three = file2.clone
          end
        end
      end      
      cpt=cpt+1
    end
    c = renamesT.clone
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
  def randRenames(folder, file)
    tool = RandRenamesTools.new(folder, file)
    proj = ["phpunit", "jquery", "rails", "jenkins", "pyramid"]
    allRenamesT = Array.new()
    num = 100

    proj.each do |p|
      
      branches = Array(tool.get_branches(p))
      branches.map!{|line| line.strip}
      releases = Array(tool.get_majorReleases(p))
      releases.map!{|line| line.strip}

      branches.each do |br|
        if br == "origin/master"
          ###before first tag
          vers = releases[0]
          files = Array(tool.get_files(p, vers))
          files.map!{|line| line.strip}
          exfiles = files.clone
          files = tool.get_regexp(exfiles, p)
          logR = Array(tool.get_initLogR(p, vers))
          logR.map!{|line| line.strip}
          renamesT = tool.get_renames(logR, files, p)
          allRenamesT.concat(renamesT.clone)

          ###first tag to last tag
          i = 0
          while i < releases.count-1 do
            vers1 = releases[i]
            vers2 = releases[i+1]
            files = Array(tool.get_files(p, vers2))
            files.map!{|line| line.strip}
            exfiles = files.clone
            files = tool.get_regexp(exfiles, p)
            logR = Array(tool.get_logR(p, vers1, vers2))
            logR.map!{|line| line.strip}
            renamesT = tool.get_renames(logR, files, p)
            allRenamesT.concat(renamesT.clone)
            i=i+1
          end

          ##last tag to branch head
          vers1 = releases[releases.count-1]
          vers2 = br
          files = Array(tool.get_files(p, vers2))
          files.map!{|line| line.strip}
          exfiles = files.clone
          files = tool.get_regexp(exfiles, p)
          logR = Array(tool.get_logR(p, vers1, vers2))
          logR.map!{|line| line.strip}
          renamesT = tool.get_renames(logR, files, p)
          allRenamesT.concat(renamesT.clone)
          
        else ###maintenance branch
          files = Array(tool.get_files(p, br))
          files.map!{|line| line.strip}
          exfiles = files.clone
          files = tool.get_regexp(exfiles, p)
          logR = Array(tool.get_branchLogR(p, br))
          logR.map!{|line| line.strip}
          renamesT = tool.get_renames(logR, files, p)
          allRenamesT.concat(renamesT.clone)
        end
      end
    end

    randRenamesT = tool.get_rand(allRenamesT, num)
    
    print "project,commit,rename,last name"
    puts ""
    randRenamesT.each do |r|
      print r.four,",",r.one,",",r.two,",",r.three
      puts ""
    end  
    
  end
end

GitRandRenames.start(ARGV)

