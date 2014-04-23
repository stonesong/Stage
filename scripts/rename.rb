require 'rubygems'
require 'thor'

class Couple
  attr_accessor :one, :two
  
  def initialize(one, two)
    @one = one
    @two = two
  end
end

class GitRenameDetector #Class for tool function
  
  def initialize(folder, file)
    @folder = folder
    @file = file
  end
  
  def get_rellog(vers1, vers2)
    `git --git-dir #{@folder}/.git log -C --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers1}..#{vers2}`.split("\n").map
  end

  def get_branchRellog(vers)
    `git --git-dir #{@folder}/.git log -C --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers} --not master`.split("\n").map
  end

  def get_initRellog(vers)
    `git --git-dir #{@folder}/.git log -C --summary --stat=1000,1000 --format=format:"%H" --reverse #{vers}`.split("\n").map
  end
  
  def get_nbCommits(vers1, vers2)
    `git --git-dir #{@folder}/.git log --format=oneline #{vers1}..#{vers2} | wc -l`.strip!.to_i
  end
  
  def get_nbBranchCommits(branch)
    `git --git-dir #{@folder}/.git log --format=oneline #{branch} --not master | wc -l`.strip!.to_i
  end
  
  def get_files(vers)
    `git --git-dir #{@folder}/.git ls-tree -r --name-only #{vers}`.split("\n").map  
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

  def get_nbModifiedFiles(log_array)
    log_array.grep(/\|/)
  end
   
  def get_renames(log_array)
    log_array.grep(/=>/).grep(/\|/)
  end
  
  def get_percentage(a, b)
    if b > 0
      a*10000/b/100.to_f
    else
      0
    end
  end


  def getn(vers, f)
    `git --git-dir #{@folder}/.git --work-tree=#{@folder}/ log #{vers} -M --summary --stat=1000,1000 --format=format:"%H" --follow #{@folder}/#{f}`.split("\n").map
  end
  
  def get_renameCount(vers)
    list = Array(get_files(vers))
    list.map{|line| line.strip!}
    ren = Array.new()
    i = 0
    while i < list.count do
      f = list[i]
      n = Array(getn(vers, f))
      n.map{|line| line.strip!}
      b=0
      j=0
      while j < n.count do
        if n[j].match("rename")
          if !ren.include?(f)
            ren.concat([f])
          end
        end
        if n[j].match("copy")
          break
        end
        j=j+1
      end
      i=i+1
    end
    ren
  end

  def get_prRenamed(log_array, active_array)
    hrenamed = Array.new()
    hmodified = Array.new()

    cpt=0
    while cpt < log_array.count do
      line = String.new(log_array[cpt])
      if (line.match("rename ") || line.match("copy ")) && line.match("=>") && line.match("%")
        line.strip!
        lineC=String.new(line)
        line.gsub!(/(.*)( )(.*)( => )(.*)( )(.*)/, '\3\4\5')
        if line.match(/\{/)
          if line.match(/=> \}/)
            file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
            file2=line.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\4')
          elsif line.match(/\{ =>/)
            file1=line.gsub(/(\{)(.*)( => )(.*)(\})(\/)/, '\2')
            file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
          else
            file1=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\2')
            file2=line.gsub(/(\{)(.*)( => )(.*)(\})/, '\4')
          end
        else
          file1=line.gsub(/(.*)( => )(.*)/, '\1')
          file2=line.gsub(/(.*)( => )(.*)/, '\3')
        end
        if lineC.match("rename ")
          if hrenamed.include?(file1)
            hrenamed.delete(file1)
          end
          hrenamed.concat([file2])
          hmodified.concat([file2])
          hmodified.delete(file1)
        else
          hmodified.concat([file2])
        end
      end
      if line.match(/\|/) && !line.match("=>")
        line = line.split("|")[0]
        line.strip!
        file = line
        if !hmodified.include?(file)
          hmodified.concat([file])
        end
      end
      #end
      #if line.match("delete")
      # file = line.gsub(/(.*)( )(.*)/, '\3')
      # hrenamed.delete(file)
      # hmodified.delete(file)
      #end
      cpt=cpt+1
    end
    hmodified = hmodified.uniq
    hrenamed = hrenamed.uniq
    i=0
    tmp = Array.new(hmodified)
    while i < tmp.count do
      if !active_array.include?(tmp[i])
        hmodified.delete(tmp[i])
        hrenamed.delete(tmp[i])
      end
      i=i+1
    end
    Couple.new(hrenamed, hmodified)
  end
  
end


class GitRename < Thor
  
  desc "Returns CSV", "Returns a CSV for every maintenance branch and for the commits between tags"
  def csv(folder, file)
    detector = GitRenameDetector.new(folder, file)
    
    puts "Name,Type,# of files,# of active files,% of active files,# of modifications,# of renames,% of renames,% of files renamed,% of active files renamed,"
    branches = Array(detector.get_branches)
    branches.map{|line| line.strip!}
    releases = Array(detector.get_majorReleases)
    releases.map{|line| line.strip!}
    #firstCommit = detector.get_firstCommit

    #files = Array(detector.get_files("origin/master"))
    #files.map{|line| line.strip!}
    #puts "verif: nb ren detected"
    #log = Array(detector.get_initRellog("origin/master"))
    #log.map{|line| line.strip!}
    #ar1 = Couple.new(0, 0)
    #ar1 = detector.get_prRenamed(log, files)
    #hren = ar1.one
    #puts hren.count
    #puts "nb rn total"
    #ar2 = Array(detector.get_renameCount("origin/master"))
    
   # puts ar2.count
   # puts ""
   # c=0
   # while c < ar2.count do
   #   if !hren.include?(ar2[c])
   #     puts ar2[c]
   #   end
   #   c=c+1
   # end

    cpt = 0
    while cpt < branches.count do
      current_branch = branches[cpt]
      if current_branch == "origin/master"        
        
        ###before first tag
        vers = releases[0]
	
        log_init = Array(detector.get_initRellog(vers))
        log_init.map{|line| line.strip!}
        
        files = Array(detector.get_files(vers))
        files.map{|line| line.strip!}
        nbFiles = files.count
        
        nbModif = detector.get_nbModifiedFiles(log_init).count
        nbRen = detector.get_renames(log_init).count
        prOfRenames = detector.get_percentage(nbRen, nbModif)
        
        if nbModif > 0
          tables = Couple.new(0, 0)
          tables = detector.get_prRenamed(log_init, files)
          hren = tables.one
          hmod = tables.two
          prActRenamed = hren.count*10000/hmod.count/100.to_f
          prRenamed = hren.count*10000/nbFiles/100.to_f
          nbActFiles = hmod.count
          prActFiles = detector.get_percentage(nbActFiles, nbFiles)
        else
          nbActFiles = 0
          prActRenamed = 0
          prRenamed = 0
          prActFiles = 0
        end

        print "before first release tag,INIT,",nbFiles,",",nbActFiles,",",prActFiles,",",nbModif,",",nbRen,",",prOfRenames,",",prRenamed,",",prActRenamed,","
        puts "" 

        c=0
        n=0
        while c < files.count do
          if !hmod.include?(files[c])
            #puts files[c]
            n=n+1
          end
          c=c+1
        end
        
        ###first tag to last tag
        i=0
        while i < releases.count-1 do
          vers1 = releases[i]
          vers2 = releases[i+1]
          
          log = Array(detector.get_rellog(vers1, vers2))
          log.map{|line| line.strip!}
          
          files = Array(detector.get_files(vers2))
          files.map{|line| line.strip!}
          nbFiles = files.count
          
          nbModif = detector.get_nbModifiedFiles(log).count
          nbRen = detector.get_renames(log).count
          prOfRenames = detector.get_percentage(nbRen, nbModif)
           
          if nbModif > 0                
            tables = Couple.new(0,0)
            tables = detector.get_prRenamed(log, files)
            hren = tables.one
            hmod = tables.two
            prActRenamed = hren.count*10000/hmod.count/100.to_f
            prRenamed = hren.count*10000/nbFiles/100.to_f
            nbActFiles = hmod.count
            prActFiles = detector.get_percentage(nbActFiles, nbFiles)
          else
            nbActFiles = 0
            prActRenamed = 0
            prRenamed = 0
            prActFiles = 0
          end

          print vers1,",DEV,",nbFiles,",",nbActFiles,",",prActFiles,",",nbModif,",",nbRen,",",prOfRenames,",",prRenamed,",",prActRenamed,","
          puts ""
          
          i=i+1
        end
       
        ##last tag to branch head
        vers1 = releases[releases.count-1]
        vers2 = current_branch
        
        log = Array(detector.get_rellog(vers1, vers2))
        log.map{|line| line.strip!}
        
        files = Array(detector.get_files(vers2))
        files.map{|line| line.strip!}
        nbFiles = files.count
         
        nbModif = detector.get_nbModifiedFiles(log).count
        nbRen = detector.get_renames(log).count
        prOfRenames = detector.get_percentage(nbRen, nbModif)
        
        if nbModif > 0
          tables = Couple.new(0,0)
          tables = detector.get_prRenamed(log, files)
          hren = tables.one
          hmod = tables.two
          prActRenamed = hren.count*10000/hmod.count/100.to_f
          prRenamed = hren.count*10000/nbFiles/100.to_f
          nbActFiles = hmod.count
          prActFiles = detector.get_percentage(nbActFiles, nbFiles)
        else
          nbActFiles = 0
          prActRenamed = 0
          prRenamed = 0
          prActFiles = 0
        end

        print vers1,"(last release !),DEV,",nbFiles,",",nbActFiles,",",prActFiles,",",nbModif,",",nbRen,",",prOfRenames,",",prRenamed,",",prActRenamed,","
        puts ""
     
      else ###maintenance branch
        
        log = Array(detector.get_branchRellog(current_branch))
        log.map{|line| line.strip!}      
        
        files = Array(detector.get_files(current_branch))
        files.map{|line| line.strip!}
        nbFiles = files.count
        
        nbModif = detector.get_nbModifiedFiles(log).count
        nbRen = detector.get_renames(log).count
        prOfRenames = detector.get_percentage(nbRen, nbModif)
             
        if nbModif > 0
          tables = Couple.new(0,0)
          tables = detector.get_prRenamed(log, files)
          hren = tables.one
          hmod = tables.two
          prActRenamed = hren.count*10000/hmod.count/100.to_f
          prRenamed = hren.count*10000/nbFiles/100.to_f
          nbActFiles = hmod.count
          prActFiles = detector.get_percentage(nbActFiles, nbFiles)
        else
          nbActFiles = 0
          prActRenamed = 0
          prRenamed = 0
          prActFiles = 0
        end
        
        print current_branch,",MAINT,",nbFiles,",",nbActFiles,",",prActFiles,",",nbModif,",",nbRen,",",prOfRenames,",",prRenamed,",",prActRenamed,","
        puts ""
    
      end
      cpt=cpt+1
    end 

  end
end

GitRename.start(ARGV)
