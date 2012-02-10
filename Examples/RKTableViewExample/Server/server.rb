#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'

configure do
  set :logging, true
  set :dump_errors, true
  set :public, Proc.new { root }
end
