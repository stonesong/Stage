require 'rubygems'
require 'thor'

class NbCommitsTools
  def initialize(folder, rev1, rev2)
    @folder = folder
    @rev1 = rev1
    @rev2 = rev2
  end 
  
  def get_files()
    `git --git-dir #{@folder}/.git ls-tree -r --name-only #{@rev2}`.split("\n").map  
  end

  def get_logR()
    `git --git-dir #{@folder}/.git log -M --summary --stat=1000,1000 --format=format:"%H" --reverse #{@rev1}..#{@rev2}`.split("\n").map
  end

  def get_log()
    `git --git-dir #{@folder}/.git log --summary --stat=1000,1000 --format=format:"%H" --reverse #{@rev1}..#{@rev2}`.split("\n").map
  end

  def get_commits(log, files)
    hcommits = Hash.new()
    cpt=0
    sha1 = nil
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/[0-9a-f]{40}/)
        sha1 = String.new(line).strip
      end
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        hcommits.merge!({file => [sha1]}){|key, v1, v2| v1.concat(v2)}
      end
      cpt=cpt+1
    end 
    hcommits.each do |key, value|
      hcommits[key].uniq!
    end
    c = hcommits.clone
    c.each do |key, value|
      if !files.include?(key)
        hcommits.delete(key)
      end
    end
    hcommits
  end

  def get_commitsR(log, files)
    hcommitsR = Hash.new()
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
          if lineF.match(/=> \}/)
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
        if hcommitsR.include?(file1)
          tabF1 = Array(hcommitsR[file1])
          hcommitsR.merge!({file2 => [sha1].concat(tabF1)})
          #hcommitsR.delete(file1)
          hcommitsR[file1] = hcommitsR[file2]
        else
          hcommitsR.merge!({file2 => [sha1]})
        end
      end      
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        hcommitsR.merge!({file => [sha1]}){|key, v1, v2| v1.concat(v2)}
      end
      cpt=cpt+1
    end 
    hcommitsR.each do |key, value|
      hcommitsR[key].uniq!
    end
    c = hcommitsR.clone
    c.each do |key, value|
      if !files.include?(key)
        hcommitsR.delete(key)
      end
    end
    hcommitsR
  end
  
end

class GitNbCommits < Thor 
  desc "Returns nb Commits", "Returns nb Commits calculated on git repository between revisions"
  def nbCommits(folder, rev1, rev2)
    tool = NbCommitsTools.new(folder, rev1, rev2)  
   
    files = Array(tool.get_files())
    files.map{|line| line.strip!}
    
    log = Array(tool.get_log())
    log.map{|line| line.strip!}
    
    hcommits = tool.get_commits(log, files)
    #puts hcommits
    
    logR = Array(tool.get_logR())
    logR.map{|line| line.strip!}

    hcommitsR = tool.get_commitsR(logR, files)
    #puts hcommitsR
    print "fileName,active,#commits,#commitsWithRename,diff(#commitsWR-#commits)"
    puts ""

    res = Hash.new()
    hcommits.each do |key1, v1|
      hcommitsR.each do |key2, v2|       
        if key1 == key2
          value1=v1.count
          value2=v2.count
          #print key1,",",value1,",",value2,",",value2-value1
          #puts ""
          res.merge!({key1 => [1, value1,  value2, value2-value1]})
        end
      end
    end

    files.each do |key|
      if !hcommits.include?(key)
        #print key,",0,0,0"
        #puts ""
        res.merge!({key => [0, 0, 0, 0]})
      end
    end

    res2 = res.sort_by{ |m, v1, v2, v3, v4| m.downcase}
    res2.each do |key, value|
      print key,",",value[0],",",value[1],",",value[2],",",value[3]
      puts "" 
    end

  end
  
end

GitNbCommits.start(ARGV)
