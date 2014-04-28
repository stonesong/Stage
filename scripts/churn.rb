require 'rubygems'
require 'thor'

class ChurnTools
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

  def get_churn(log, files)
    hchurn = Hash.new()
    cpt=0
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        nchurn = line.gsub(/(.*)(\| )(.*)( )(.*)/, '\3').to_i
        if nchurn > 0
          hchurn.merge!({file => nchurn}){ |key, v1, v2| v1+v2 }
        end
      end
      cpt=cpt+1
    end
    hchurn.each do |key, value|
      if !files.include?(key)
        hchurn.delete(key)
      end
    end
    hchurn
  end
  
  def get_churnR(log, files)
    hchurnR = Hash.new()
    cpt=0
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/\|/) && line.match("=>")
        line.strip!
        lineF=String.new(line.gsub(/(.*)(\|)(.*)/, '\1'))
        if line.match(/\{/)
          if line.match('/=> \}/')
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
      end
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        nchurn = line.gsub(/(.*)(\| )(.*)( )(.*)/, '\3').to_i
        if nchurn > 0
          hchurnR.merge!({file => nchurn}){ |key, v1, v2| v1+v2 }
        end
      end
      cpt=cpt+1
    end
    hchurnR.each do |key, value|
      if !files.include?(key)
        hchurnR.delete(key)
      end
    end
    hchurnR
  end
  

end

class GitChurn < Thor 
  desc "Returns churn", "Returns churn calculated on git repository between revisions"
  def churn(folder, rev1, rev2)
    tool = ChurnTools.new(folder, rev1, rev2)
    
    files = Array(tool.get_files())
    files.map{|line| line.strip!}
    
    log = Array(tool.get_log())
    log.map{|line| line.strip!}
    
    hchurn = Hash(tool.get_churn(log, files))
    print "file,churn"
    puts ""
    hchurn.each do |key, value|
      print key,",",value
      puts ""
    end
  end
  
end

GitChurn.start(ARGV)
