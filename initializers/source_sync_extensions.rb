module Rhosync
  class SourceSync
    def push_object_updates(objects,timeout=10,raise_on_expire=false)
      rejected_creates = []
      @source.lock(:md,timeout,raise_on_expire) do |s|
        doc = @source.get_data(:md)
        orig_doc_size = doc.size
        objects.each do |id,obj|
          unless doc[id].nil?
            doc[id].merge!(obj)
          else
            rejected_creates.push(id)
          end
        end
        diff_count = doc.size - orig_doc_size
        @source.put_data(:md,doc)
        @source.update_count(:md_size,diff_count)
      end
      rejected_creates
    end
  end
end