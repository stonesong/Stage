require 'rubygems'
require 'thor'

class NbDevsTools
  def initialize(folder, rev1, rev2, project)
    @folder = folder
    @rev1 = rev1
    @rev2 = rev2
    @project = project
  end 
  
  def get_files()
    `git --git-dir #{@folder}/.git ls-tree -r --name-only #{@rev2}`.split("\n").map  
  end

  def get_logR()
    `git --git-dir #{@folder}/.git log -M --summary --stat=1000,1000 --format=format:"%aN" --reverse #{@rev1}..#{@rev2}`.split("\n").map
  end

  def get_log()
    `git --git-dir #{@folder}/.git log --summary --stat=1000,1000 --format=format:"%aN" --reverse #{@rev1}..#{@rev2}`.split("\n").map
  end


  def get_regexp(tab)
    c = tab.clone
    case @project
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

  def get_devs(log, files)
    hdevs = Hash.new()
    cpt=0
    auth = nil
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/[a-zA-Z]/) && !line.match(/[0-9]/)
        auth = String.new(line).strip
      end
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        hdevs.merge!({file => [auth]}){|key, v1, v2| v1.concat(v2)}
      end
      cpt=cpt+1
    end 
    hdevs.each do |key, value|
      hdevs[key].uniq!
    end
    c = hdevs.clone
    c.each do |key, value|
      if !files.include?(key)
        hdevs.delete(key)
      end
    end
    hdevs
  end

  def get_devsR(log, files)
    hdevsR = Hash.new()
    cpt=0
    auth = nil
    while cpt < log.count do
      line = String.new(log[cpt])
      if line.match(/[a-zA-Z]/) && !line.match(/[0-9]/)
        if line.match(/ \+ /)
          auth1=String.new(line.gsub(/(.*)( \+ )(.*)(,)/, '\1')).strip
          auth2=String.new(line.gsub(/(.*)( \+ )(.*)(,)/, '\3')).strip
          auth=[auth1].concat([auth2])
        elsif  line.match(" and ")
          auth1=String.new(line.gsub(/(.*)( and )(.*)(,)/, '\1')).strip
          auth2=String.new(line.gsub(/(.*)( and )(.*)(,)/, '\3')).strip
          auth=[auth1].concat([auth2])
        else
          a = String.new(line).strip
          auth = Array[a]
        end
      end
      if line.match("action_controller") && line.match("base.rb") && !line.match("abstract") && line.match(/\|/) && line.match("=>")
        puts line
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
        if hdevsR.include?(file1)
          tabF1 = Array(hdevsR[file1])
          hdevsR.merge!({file2 => auth.concat(tabF1)})
          #hdevsR.delete(file1)
          #hdevsR[file1] = hdevsR[file2]
          hdevsR.merge!({file1 => auth}){|key, v1, v2| v1.concat(v2)}

        else
          hdevsR.merge!({file2 => auth})
        end

      if line.match("action_controller") && line.match("base.rb") && !line.match("abstract")
        print "table ",file2," !"
        puts ""
        hdevsR[file2].uniq!
        hdevsR[file2].each do |d|
            print d,", "
          puts ""
          end
        puts ""
        print "table ",file1," !"
        puts ""
        hdevsR[file1].uniq!
        hdevsR[file1].each do |d|
            print d,", "
            puts ""
          end
      end
    end      
      if line.match(/\|/) && !line.match("=>")
        file = String.new(line.split("|")[0])
        file.strip!
        hdevsR.merge!({file => auth}){|key, v1, v2| v1.concat(v2)}
      end
      cpt=cpt+1
    end 
    hdevsR.each do |key, value|
      hdevsR[key].uniq!
    end
    c = hdevsR.clone
    c.each do |key, value|
      if !files.include?(key)
        hdevsR.delete(key)
      end
    end
    hdevsR
  end
  
end

class GitNbDevs < Thor 
  desc "Returns nb Devs", "Returns nb devs calculated on git repository between revisions"
  def nbDevs(folder, rev1, rev2)
    proj = String.new(folder.gsub(/(.*)(\/)(.*)/, '\3'))
    tool = NbDevsTools.new(folder, rev1, rev2, proj)  
   
    files = Array(tool.get_files())
    files.map{|line| line.strip!}
    exfiles = files.clone
    files = tool.get_regexp(exfiles)
    
    log = Array(tool.get_log())
    log.map{|line| line.strip!}
    
    hdevs = tool.get_devs(log, files)
    #puts hdevs
    
    logR = Array(tool.get_logR())
    logR.map{|line| line.strip!}

    hdevsR = tool.get_devsR(logR, files)
    #puts hdevsR
    print "fileName,active,#devs,#devsWithRename,diff(#devsWR-#devs)"
    puts ""
    
    res = Hash.new()

    hdevs.each do |key1, v1|
      hdevsR.each do |key2, v2|       
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
      if !hdevs.include?(key)
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

GitNbDevs.start(ARGV)
