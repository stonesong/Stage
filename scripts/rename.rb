require 'rubygems'
require 'thor'

class GitRenameDetector #Class for tool function
  
  def initialize(folder, file)
    @folder = folder
    @file = file
  end
  
  def get_rellog(vers1, vers2)
    `git --git-dir #{@folder}/.git log -M --stat=1000,1000 --format=format:"%H" #{vers1}..#{vers2} | grep "|"`.split("\n").map{|line| line.split("|")[0].strip!}
  end

  def get_branchRellog(vers)
    `git --git-dir #{@folder}/.git log -M --stat=1000,1000 --format=format:"%H" #{vers} --not master | grep "|"`.split("\n").map{|line| line.split("|")[0].strip!}
  end
  
  def get_masterRellog()
    `git --git-dir #{@folder}/.git log -M --stat=1000,1000 --format=format:"%H" origin/master | grep "|"`.split("\n").map{|line| line.split("|")[0].strip!}
  end
  
  def get_nbCommits(vers1, vers2)
    `git --git-dir #{@folder}/.git log --format=oneline #{vers1}..#{vers2} | wc -l`.strip!.to_i
  end
  
  def get_nbMasterCommits()
    `git --git-dir #{@folder}/.git log --format=oneline origin/master | wc -l`.strip!.to_i
  end
  
  def get_nbFiles(vers)
    `git --git-dir #{@folder}/.git ls-tree -r --name-only #{vers} | wc -l`.strip!.to_i  
  end
  
  def get_branches()
    `git --git-dir #{@folder}/.git branch -r | sed '/->/d' | sed -e 's/^ *//g'`.split("\n").map
  end
  
  def get_majorReleases()
    `cat #{@folder}/#{@file}`.split("\n").map
  end
  
  def get_firstCommit()
    `git --git-dir #{@folder}/.git log --format=oneline --reverse origin/master | head -1`.split(" ")[0]
  end
  
  def get_renames(log_array)
    log_array.grep(/=>/)
end

def get_percentage(a, b)
  a*10000/b/100.to_f
end

def get_prRenamed(log_array, nbModifiedFiles)
  if nbModifiedFiles > 1 
    hrenamed = Array.new()
    hmodified = Array.new()
    cpt=0
    c=0
    while cpt < nbModifiedFiles
      line = log_array[cpt]
      if line.match("=>") != nil
        c=c+1
        file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
        file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
        if hrenamed.include?(file1)
          hrenamed.delete(file1)
          hmodified.delete(file1)
        end
        hrenamed.concat([file2])
        hmodified.concat([file2])
      else
        file = line
        if !hmodified.include?(file)
          hmodified.concat([file])
        end
      end
      cpt=cpt+1
    end
    puts c
    puts hrenamed.count
    puts hmodified.count
    hrenamed.count*10000/hmodified.count/100.to_f
  else
    0
  end
end


end


class GitRename < Thor
  
  desc "Returns CSV", "Returns a CSV for every maintenance branch and for the commits between tags"
  def csv(folder, file)
    detector = GitRenameDetector.new(folder, file)
    
    puts "#Name,#Type,#nb of commits,#nb of renames,#nb of files,#% of renames among active modifications,#% of active files renamed,"
    branches = Array(detector.get_branches)
    cpt = 0
    while cpt < branches.count do
      current_branch = branches[cpt]
      if current_branch == "origin/master"        
        releases = Array(detector.get_majorReleases)
       	#log_master = Array(detector.get_masterRellog)
        firstCommit = detector.get_firstCommit
        
        ###before first tag
        nbCommits = detector.get_nbCommits(firstCommit, releases[0])
	log_init = Array(detector.get_rellog(firstCommit, releases[0]))
        renames = detector.get_renames(log_init)
        nbFiles = detector.get_nbFiles(releases[0])
        nbModifiedFiles = log_init.count
        prChanceOfRenames = detector.get_percentage(renames.count, nbModifiedFiles)
        prRenamed = detector.get_prRenamed(log_init, nbModifiedFiles)
	print "before first release tag,INIT,",nbCommits,",",renames.count,",",nbFiles,",",prChanceOfRenames,",",prRenamed,","
        puts ""        
      end
      
      cpt += 1
    end
    
  end
end

GitRename.start(ARGV)
