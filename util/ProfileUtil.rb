class ProfileUtil
  class << self
    def profile(profile_name="profile")
      RubyProf.start
      yield if block_given?
      result = RubyProf.stop
      
      html_printer = RubyProf::GraphHtmlPrinter.new(result)
      html_printer.print(File.new("#{profile_name}.html", "w+"))
      
      calltree_printer = RubyProf::CallTreePrinter
      calltree_printer.print(File.new("#{profile_name}.calltree", "w+"))
    end
  end
end