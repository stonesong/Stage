require 'rubygems'
require 'thor'

class TraceTools
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

  def get_hist(rev1, vers, f)
    `git --git-dir #{@folder}/.git --work-tree=#{@folder}/ log #{rev1}..#{vers} -M --summary --stat=1000,1000 --format=format:"%H" --reverse --follow #{@folder}/#{f}`.split("\n").map
  end

  def get_test(rev1, rev2, files)
    htrace = Hash.new()
    files.each do |f|
      log = Array(get_hist(rev1, rev2, f))
      log.map{|line| line.strip!}
      c = 0
      while c < log.count do
        line = String.new(log[c])
        if line.match("rename ") && line.match("=>") && line.match("%")
          lineF=String.new(line.gsub(/(.*)( )(.*)( => )(.*)( )(.*)/, '\3\4\5'))
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
          if htrace.include?(file1)
            htab = htrace[file1].clone
            htrace.merge!({file2 => htab.merge!({file1 => file2})})
            #htrace.delete(file1)
          else
            htrace.merge!({file2 => {file1 => file2}})
          end             
        end      
        c=c+1
      end
    end
    htrace
  end
  
  def get_trace(log, files)
    htrace = Hash.new()
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
      
        if htrace.include?(file1)
          htab = htrace[file1].clone
          htrace.merge!({file2 => htab.merge!({file1 => file2})})
          #htrace.delete(file1)
          
        else
          htrace.merge!({file2 => {file1 => file2}})
        end          
      end      
      cpt=cpt+1
    end 
    c = htrace.clone
    htrace.each do |key, value|
      if !files.include?(key)
        htrace.delete(key)
      end
    end
    htrace
  end
  
end

class GitTrace < Thor 
  desc "Returns json format", "Returns json format for trace renamed files on git repository between revisions"
  def trace(folder, rev1, rev2)
    tool = TraceTools.new(folder, rev1, rev2)  
   
    files = Array(tool.get_files())
    files.map{|line| line.strip!}
    
    logR = Array(tool.get_logR())
    logR.map{|line| line.strip!}

    trace = tool.get_trace(logR, files)
    puts "trace:"
    trace.each do |f, h|
      #print f," :   "
      trace[f].each do |h, v|
        #print h,"=>",v,", " 
      end
      #puts ""
    end

    trace["railties/lib/rails/generators/rails/scaffold_controller/templates/controller.rb"].each do |f1, f2|
      print f1,"=>",f2,", "
    end
    
    puts ""
    test = tool.get_test(rev1, rev2, files)
    puts "test:"
    test.each do |f, h|
      #print f," :   "
      test[f].each do |h, v|
        #print h,"=>",v,", "
      end
      #puts ""
    end

    puts ""
    puts "diff:"
    test.each do |f, h|
      if !trace.include?(f)
        print f," :   "
        test[f].each do |f1, f2|
          print f1,"=>",f2,", "
        end
        puts ""
      end
    end

    
    
  end
  
end

GitTrace.start(ARGV)
