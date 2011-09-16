require 'client'

class TumblrmapController < ApplicationController
    def index
    end

    def map
        nodes = User.get_all_primaries
        links = User.get_all_links nodes
        @map_data = {:nodes => nodes, :links => links}
        puts @map_data
        render :json => @map_data
    end

    def register
        request_token = tumblrclient.request_token(:oauth_callback => 'http://localhost/confirm')
        session[:request_token] = request_token
        redirect_to request_token.authorize_url
    end

    def confirm
        access_token = tumblrclient.authorize(
                session[:request_token].token,
                session[:request_token].secret,
                :oauth_verifier => params[:oauth_verifier]
            )
        #Snag the data
        resp = access_token.post('http://api.tumblr.com/v2/user/info')
        tumblr_user = JSON.parse(resp.body)['response']['user']
        primary_blog = tumblr_user['blogs'].reject{|blog| blog['primary'] != true }[0]
        
        avatar = JSON.parse(access_token.get("http://api.tumblr.com/v2/blog/#{URI.parse(primary_blog['url']).host}/avatar").body)['response']['avatar_url']
        #Gather all the followers
        val = 0
        puts tumblr_user['following']
        tumblr_flwing = []
        while val < tumblr_user['following']
            response = JSON.parse(access_token.post("http://api.tumblr.com/v2/user/following?offset=#{val}").body)['response']['blogs'].collect{ |blog| blog['name'] }
            tumblr_flwing << response
            val += response.length
        end
        connection = tumblr_flwing.flatten.reject{|follower| User.where(:primary => follower).first == nil }

        user = User.new
        user.token = access_token.token
        user.secret = access_token.secret
        user.avatar = avatar
        user.primary = primary_blog['name']
        user.following = connection 
        user.save

        tumblr_followers = []
        val = 0
        total_followers = JSON.parse(access_token.get("http://api.tumblr.com/v2/blog/#{URI.parse(primary_blog['url']).host}/followers").body)['response']['total_users']
        while val < total_followers.to_i
            response = JSON.parse(access_token.get("http://api.tumblr.com/v2/blog/#{URI.parse(primary_blog['url']).host}/followers?offset=#{val}").body)['response']['users'].collect{ |user| user['name'] }
            tumblr_followers << response
            val += response.length
        end
        
        tumblr_flwing.flatten.each{|follower| 
            following_user = User.where(:primary => follower).first
            if !following_user.nil?
                following_user.following << user.primary
                following_user.save
            end
        }
        
        redirect_to "/"
    end

    private
    def tumblrclient
        client = TumblrOAuth::Client.new({
        })
        client
    end
end
