class ProfileUtil
  class << self
    def profile(profile_name="profile", report_type='html')
      RubyProf.start
      yield if block_given?
      result = RubyProf.stop
      
      case report_type
      when 'html'
        printer = RubyProf::GraphHtmlPrinter.new(result)
      when 'calltree'
        printer = RubyProf::CallTreePrinter.new(result)
      end
      
      printer.print(File.new("#{profile_name}.#{report_type}", "w+"))
    end
  end
end