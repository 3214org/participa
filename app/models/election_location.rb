class ElectionLocation < ActiveRecord::Base
  belongs_to :election
  has_many :election_location_questions

  accepts_nested_attributes_for :election_location_questions, :reject_if => :all_blank, :allow_destroy => true

  LAYOUTS = { "simple" => "Listado de respuestas simple", 
              "accordion" => "Listado de respuestas agrupadas por categoría",
              "pcandidates-election" => "Listado respuestas agrupadas por categoría y pregunta", 
              "2questions-conditional" => "Pregunta inicial con 2 respuestas, si se elige la segunda aparece otra pregunta con hasta 4 respuestas"
            }
  THEMES = [ "podemos" ]

  after_initialize do
    self.agora_version = 0 if self.agora_version.nil?
    self.location = "00" if self.location.blank?
  end

  def territory
    spain = Carmen::Country.coded("ES")
    case election.scope
      when 0 then 
        "Estatal"
      when 1 then 
        autonomy = Podemos::GeoExtra::AUTONOMIES.values.uniq.select {|a| a[0][2..-1]==location } .first
        autonomy[1]
      when 2 then 
        province = spain.subregions[location.to_i-1]
        province.name
      when 3 then
        town = spain.subregions[location[0..1].to_i-1].subregions.coded("m_%s_%s_%s" % [location[0..1], location[2..4], location[5]]) 
        town.name
      when 4 then
        island = Podemos::GeoExtra::ISLANDS.values.uniq.select {|i| i[0][2..-1]==location } .first
        island[1]
      when 5 then 
        "Exterior"
    end + " (#{location})"
  end

  def vote_id
    "#{election.agora_election_id}#{override.blank? ? location : override}#{agora_version}".to_i
  end

  def link
    "#{election.server_url}#/election/#{vote_id}/vote"
  end
end
