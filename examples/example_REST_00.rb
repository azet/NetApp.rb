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

get '/aggregate' do
	protected!
	conn_filer
	body(Aggregate.list).to_json
end

get '/volume' do
	protected!
	conn_filer
	body(Volume.list).to_json
end

put '/volume' do
	protected!
	conn_filer
	status 201 if Volume.create(params[:aggregate], params[:volumename], params[:size])
end

delete '/volume' do
	protected!
	conn_filer
	status 200 if Volume.offline(params[:volumename]) and Volume.purge(params[:volumename])
end

get '/quota' do
	protected!
	conn_filer
	body(Quota.list).to_json
end

put '/quota' do
	protected!
	conn_filer
	volumepath = "/vol/${params[:volumename}/"
	status 201 if Quota.create(params[:volumename], volumepath, params[:quotasize], params[:type])
end

delete '/quota' do
	protected!
	conn_filer
	status 200 if Quota.purge(params[:quotaname], params[:volumename], params[:path], params[:type])
end

