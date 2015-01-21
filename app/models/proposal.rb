require 'open-uri'
class Proposal
  include ActiveModel::Model
  attr_accessor :title, :description, :votes, :reddit_url, :reddit_id
    
  def self.base_url
    "http://api.reddit.com"
  end
    
  def self.reddit_proposal(id)
    url = "#{base_url}/by_id/#{id}"
    parse(url).first
  end

  def self.reddit_proposals(filter='hot')
    url = "#{base_url}/r/Podemos/search?q=flair%3APropuestas&sort=#{filter}&restrict_sr=on&t=all&limit=10"
    parse(url)
  end

  def self.parse(url)
    json = JSON.load(open(url))["data"]["children"]
    json.collect {|proposal| 
      data = proposal["data"]
      proposal = Proposal.new(title:       data["title"],
                   description: data["selftext"],
                   votes:       data["ups"],
                   reddit_url:  data["url"],
                   reddit_id:   data["name"]) 
      proposal if proposal.reddit_required_votes?
    }.compact
  end

  def approval
    votes.percent_of(confirmed_users)
  end

  #For testing purpose, temporarily using 300,000 as the number of confirmed users in the Census
  def confirmed_users
    300000
  end

  #For testing purpose, temporarily using 0 as the number of endorsements
  def remaining_endorsements_for_approval
    (monthly_email_required_votes - 0).to_i
  end

  #Assuming a Census of 300,000 registered users,
  #approximately 600 votes are required,
  #to achieve a 0.2% acceptance,
  #and thus move the proposal from Plaza Podemos to participa.podemos.info
  def reddit_required_votes
    (0.2).percent * confirmed_users
  end

  #Assuming a Census of 300,000 registered users,
  #approximately 6000 votes are required,
  #to achieve a 2% acceptance,
  #and thus send an email to all members of the Census in participa.podemos.info informing them about the proposal
  def monthly_email_required_votes
    2.percent * confirmed_users
  end

  #Assuming a Census of 300,000 registered users,
  #approximately 30,000 votes are required,
  #to achieve a 10% acceptance,
  #and thus move the proposal from participa.podemos.info to AgoraVoting
  def agoravoting_required_votes
    10.percent * confirmed_users
  end

  # Set status in DB once threshold reached (just in case census increases)
  def reddit_required_votes?
    votes >= reddit_required_votes
  end

  # Set status in DB once threshold reached (just in case census increases)
  def agoravoting_required_votes?
    votes >= agoravoting_required_votes
  end

end

class Numeric
  def percent
    self.to_f / 100.0
  end

  def percent_of(n)
    self.to_f / n.to_f * 100.0
  end
end