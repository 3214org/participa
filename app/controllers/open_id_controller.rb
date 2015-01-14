require 'pathname'

require "openid"
require "openid/consumer/discovery"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

class OpenIdController < ApplicationController
  include OpenID::Server
  layout nil

  protect_from_forgery except: :index

  SERVER_APPROVALS = []

  before_action :authenticate_user!, except: [:create, :idp_xrds, :user_page, :user_xrds]

  def idp_xrds
    types = [
             OpenID::OPENID_IDP_2_0_TYPE,
            ]

    render_xrds(types)
  end

  def create
    begin
      oidreq = server.decode_request(params)
    rescue ProtocolError => e
      # invalid openid request, so just display a page with an error message
      render :text => e.to_s, :status => 500
      return
    end

    # no openid.mode was given
    unless oidreq
      render :text => "This is an OpenID server endpoint."
      return
    end

    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif current_user.nil?
          # The user hasn't logged in.
          redirect_to root_path, notice: "Please sign in."
          return
        else
          # Else, set the identity to the one the user is using.
          identity = self.url_for_user
        end
      end

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)

        # add the sreg response if requested
        add_sreg(oidreq, oidresp)
        # ditto pape
        add_pape(oidreq, oidresp)

      else
        server_url = "http://62.83.118.207"+open_id_create_path
        oidresp = oidreq.answer(false, server_url)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    self.render_response(oidresp)
  end

  def index
    begin
      oidreq = server.decode_request(params)
    rescue ProtocolError => e
      # invalid openid request, so just display a page with an error message
      render :text => e.to_s, :status => 500
      return
    end

    # no openid.mode was given
    unless oidreq
      render :text => "This is an OpenID server endpoint."
      return
    end

    oidresp = nil

    if oidreq.kind_of?(CheckIDRequest)

      identity = oidreq.identity

      if oidreq.id_select
        if oidreq.immediate
          oidresp = oidreq.answer(false)
        elsif current_user.nil?
          # The user hasn't logged in.
          redirect_to root_path, notice: "Please sign in."
          return
        else
          # Else, set the identity to the one the user is using.
          identity = self.url_for_user
        end
      end

      if oidresp
        nil
      elsif self.is_authorized(identity, oidreq.trust_root)
        oidresp = oidreq.answer(true, nil, identity)

        # add the sreg response if requested
        add_sreg(oidreq, oidresp)
        # ditto pape
        add_pape(oidreq, oidresp)

      else
        server_url = "http://62.83.118.207"+open_id_create_path
        oidresp = oidreq.answer(false, server_url)
      end

    else
      oidresp = server.handle_request(oidreq)
    end

    self.render_response(oidresp)
  end

  
  def user_xrds
    types = [
             OpenID::OPENID_2_0_TYPE,
             OpenID::OPENID_1_0_TYPE,
             OpenID::SREG_URI,
            ]

    render_xrds(types)
  end

  def user_page
    # Yadis content-negotiation: we want to return the xrds if asked for.
    accept = request.env['HTTP_ACCEPT']
    # This is not technically correct, and should eventually be updated
    # to do real Accept header parsing and logic. Though I expect it will work
    # 99% of the time.
    if accept and accept.include?('application/xrds+xml')
      user_xrds
      return
    end
    # content negotiation failed, so just render the user page
    xrds_url = open_id_user_xrds_path(user: current_user.document_vatid)
    identity_page = <<EOS
      <html><head>
      <meta http-equiv="X-XRDS-Location" content="#{xrds_url}" />
      <link rel="openid.server" href="#{open_id_create_path}" />
      </head><body><p>OpenID identity page for #{current_user.document_vatid}</p>
      </body></html>
EOS
    # Also add the Yadis location header, so that they don't have
    # to parse the html unless absolutely necessary.
    response.headers['X-XRDS-Location'] = xrds_url
    render :text => identity_page
  end

  protected

  def url_for_user
    "http://62.83.118.207"+open_id_user_page_path(user: current_user.document_vatid)
    #"http://62.83.118.207#{edit_user_registration_path}?#{current_user.document_vatid}"
    #"http://62.83.118.207/users/#{current_user.document_vatid}"
  end

  def server
    if @server.nil?
      dir = Rails.root.join('db').join('openid-store')
      store = OpenID::Store::Filesystem.new(dir)
      @server = Server.new(store, "http://62.83.118.207"+open_id_create_path)
    end
    return @server
  end

  def approved(trust_root)
    true
    #return SERVER_APPROVALS.member?(trust_root)
  end

  def is_authorized(identity_url, trust_root)
    return (current_user and (identity_url == self.url_for_user) and self.approved(trust_root))
  end

  def render_xrds(types)
    type_str = ""

    types.each { |uri|
      type_str += "<Type>#{uri}</Type>\n      "
    }

    yadis = <<EOS
<?xml version="1.0" encoding="UTF-8"?>
<xrds:XRDS
    xmlns:xrds="xri://$xrds"
    xmlns="xri://$xrd*($v*2.0)">
  <XRD>
    <Service priority="0">
      #{type_str}
      <URI>http://62.83.118.207#{open_id_create_path}</URI>
    </Service>
  </XRD>
</xrds:XRDS>
EOS

    render :text => yadis, :content_type => 'application/xrds+xml'
  end

  def add_sreg(oidreq, oidresp)
    # check for Simple Registration arguments and respond
    sregreq = OpenID::SReg::Request.from_openid_request(oidreq)

    return if sregreq.nil?

    sreg_data = { 'email' => current_user.email }
    sregresp = OpenID::SReg::Response.extract_response(sregreq, sreg_data)
    oidresp.add_extension(sregresp)
  end

  def add_pape(oidreq, oidresp)
    papereq = OpenID::PAPE::Request.from_openid_request(oidreq)
    return if papereq.nil?
    paperesp = OpenID::PAPE::Response.new
    paperesp.nist_auth_level = 0 # we don't even do auth at all!
    oidresp.add_extension(paperesp)
  end

  def render_response(oidresp)
    if oidresp.needs_signing
      signed_response = server.signatory.sign(oidresp)
    end
    web_response = server.encode_response(oidresp)

    case web_response.code
    when HTTP_OK
      render :text => web_response.body, :status => 200

    when HTTP_REDIRECT
      redirect_to web_response.headers['location']

    else
      render :text => web_response.body, :status => 400
    end
  end

end
