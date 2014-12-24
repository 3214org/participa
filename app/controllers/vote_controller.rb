class VoteController < ApplicationController
  layout "full"
  before_action :authenticate_user! 
  
  def create

    election = Election.find params[:election_id]
    if election.is_actived? 
      if election.has_valid_location_for? current_user
        @scoped_agora_election_id = election.scoped_agora_election_id current_user
      else
        redirect_to root_url, flash: {error: I18n.t('podemos.election.no_location') }
      end
    else
      redirect_to root_url, flash: {error: I18n.t('podemos.election.close_message') }
    end
  end

  def create_token
    election = Election.find params[:election_id]
    if election.is_actived?
      if election.has_valid_location_for? current_user
        vote = current_user.get_or_create_vote(election.id)
        message = vote.generate_message
        render :content_type => 'text/plain', :status => :ok, :text => "#{vote.generate_hash message}/#{message}"
      else
        flash[:error] = I18n.t('podemos.election.no_location')
        render :content_type => 'text/plain', :status => :gone, :text => root_url
      end
    else
      flash[:error] = I18n.t('podemos.election.close_message')
      render :content_type => 'text/plain', :status => :gone, :text => root_url
    end
  end
end
