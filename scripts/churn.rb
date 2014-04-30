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
        if !line.match("Bin") && !line.match("bytes")
          nchurn = line.gsub(/(.*)(\| )(.*)( )(.*)/, '\3').to_i
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
        if !line.match("Bin") && !line.match("bytes")
          nchurn = line.gsub(/(.*)(\| )(.*)( )(.*)/, '\3').to_i
          if hchurnR.include?(file1)
            nchurnOld = hchurnR[file1]
            hchurnR.merge!({file2 => nchurnOld + nchurn})
            hchurnR.delete(file1)
          else
            hchurnR.merge!({file2 => nchurn})
          end
        end  
      end
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        if !line.match("Bin") && !line.match("bytes")
          nchurn = line.gsub(/(.*)(\| )(.*)( )(.*)/, '\3').to_i
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
    
    hchurn = tool.get_churn(log, files)
    
    logR = Array(tool.get_logR())
    logR.map{|line| line.strip!}


    hchurnR = tool.get_churnR(logR, files)
    print "fileName,active,churn,churnWithRename,diff(churnWR-churn)"
    puts ""
        
    res = Hash.new()

    hchurn.each do |key1, value1|
      hchurnR.each do |key2, value2|
        if key1 == key2
          res.merge!({key1 => [1, value1,  value2, value2-value1]})
        end
      end
    end
    
    files.each do |key|
      if !hchurn.include?(key)
        res.merge!({key => [0, 0, 0, 0]})
      end
    end

    res2 = Hash.new(res)
    res2 = res.sort_by{|m, v| m.downcase}
    res2.each do |key, value|
      print key,",",value[0],",",value[1],",",value[2],",",value[3]
      puts "" 
    end

    res3 = res2.sort_by{ |m, v| v[1]}.reverse
    
    #puts "top 10 churn order"
    c=0
    res3.each do |key, value|
      #print key,",",value[0],",",value[1],",",value[2],",",value[3]
      #puts "" 
      c=c+1
      if c == 9
        break
      end
    end
    
    res4 = res2.sort_by {|k, v| v[2]}.reverse

    #puts ""
    #puts "top 10 churn with rename order"
    c=0
    res4.each do |key, value|
      #print key,",",value[0],",",value[1],",",value[2],",",value[3]
      #puts "" 
      c=c+1
      if c == 9
        break
      end
    end
    
    
  end
  
end

GitChurn.start(ARGV)
