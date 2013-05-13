#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'json'
#require 'bcrypt'
require './lib/netapp.rb'

@@fileraddr = "192.168.55.10"
@@fileruser = "root"
@@filerpwd = "rootr00t"

@@authuser = "admin"
@@authpwd = "testpwd"


def conn_filer
	# implement something generic over here
	Filer.new(@@fileraddr, @@fileruser, @@filerpwd)
end

helpers do  
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [@@authuser, @@authpwd]
  end
end

get '/' do
	"nope."
end

put '/add/user/:username' do
	protected!
	conn_filer
	begin
		volumename = params[:username]
		volumepath = "/vol/#{volumename}/"
		Volume.create(params[:aggregate], volumename, params[:volumesize])
		Quota.create(volumename, volumepath, params[:quotasize], type="user")
	rescue => e
		status 409 and raise
		return e
	else
		status 201
	end 
end

