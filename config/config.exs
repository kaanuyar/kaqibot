use Mix.Config

config :kaqibot, 
credentials: 
	%{:host => "irc.twitch.tv", :port => 6667,
    :nick => "kaqibot", :user => "kaqibot", :name => "kaqibot",
    :channel => "#kaqimon"},
	
dota_related:
	%{:opendota_players_url => 'https://api.opendota.com/api/players/',
	:twitch_api_url => 'https://api.twitch.tv/helix/', 
	:gorgc_id => '56939869', :wagamama_id => '32995405',
	:pendejos_id => '106080212'}
