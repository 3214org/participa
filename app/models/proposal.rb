require 'numeric'
class Proposal < ActiveRecord::Base

  scope :reddit, -> { where(reddit_threshold: true) }
  
  before_save :update_threshold

  def update_threshold
    self.reddit_threshold = true if reddit_required_votes?
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