
class NoteMapper < Mapper  
  def map_from_source_hash(notes_array)
    notes_array.map! do |note| 
      object_props = note['objectid'] 
      note.merge!({'parent_id' => object_props['id'], 'parent_type' => Mapper.convert_crm_type(note['objecttypecode'])}) unless object_props.blank?
      note.reject!{|k,v| k == 'objectid' || k == 'objecttypecode'}
      note
    end

    notes_array.reduce({}) { |sum, note| sum[note["annotationid"]] = note if note; sum }
  end 
  
  def map_data_from_client(data, mapper_context={})
    data.merge!({
      'objecttypecode' => Mapper.convert_mobile_type(data['parent_type']),
      'objectid' => {
          'id' => data['parent_id']
        }
      })
    data.reject!{|k,v| ['modifiedon', 'createdon','parent_id', 'parent_type', 'temp_id'].include?(k)}
  end
end