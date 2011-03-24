require 'ap'

class NoteMapper < Mapper
  # "annotationid":"41354137-e454-e011-93bf-0050569c7cfe",
  #  "subject":"Note created on 3/22/2011 7:25 PM by James Burkett",
  #  "notetext":"Test note #1",
  #  "objectid":
  #    {
  #      "type":null,
  #      "name":null,
  #      "id":"07526ecc-1f54-e011-93bf-0050569c7cfe"},
  #      "createdon":"03/22/2011 07:26:38 PM",
  #      "modifiedon":"03/22/2011 07:26:38 PM",
  #      "objecttypecode":"opportunity"
  #    }]
  
  def map_from_source_hash(notes_array)
    notes_array.map! do |note| 
      object_props = note['objectid'] 
      note.merge!({'parent_id' => object_props['id'], 'parent_type' => note['objecttypecode']}) unless object_props.blank?
      note.reject!{|k,v| k == 'objectid' || k == 'objecttypecode'}
      note
    end

    notes_array.reduce({}) { |sum, note| sum[note["annotationid"]] = note if note; sum }
  end 
  
  def self.map_data_from_client(data)
    # data.merge!({
    #     'subject' => 'test', 
    #     'regardingobjectid' => {
    #         'type' => data['parent_type'],
    #         'id' => data['parent_id']
    #       }
    #     })
    #   data.reject!{|k,v| ['parent_id', 'parent_type'].include?(k)}
  end
end