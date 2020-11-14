defmodule Kaqibot.Channel do	
	use GenServer
	
	defmodule State do
		defstruct 	client: nil,
					channel: "",
					twitch_id: "",
					token: ""
	end
	
	#@gorgc_id 56939869
	@pendejos_id 106080212
	@opendota_players_url 'https://api.opendota.com/api/players/'
	@twitch_api_url 'https://api.twitch.tv/helix/'
	
	
	def start_link({client, channel, twitch_id, token}) do
		state = %State{client: client, channel: channel, twitch_id: twitch_id, token: token} 
		GenServer.start_link(__MODULE__, state)
	end
	
	def init(state) do
		ExIRC.Client.add_handler(state.client, self())
		ExIRC.Client.join(state.client, state.channel)

		{:ok, state}
	end
	
	def handle_info({:joined, channel}, state) do
		IO.puts("Joined #{channel}")
		{:noreply, state}
	end
	
	def handle_info({:received, message, sender, channel}, state) do
		IO.puts("#{channel} #{sender.nick}: #{message}")
		match_message({message, sender, channel}, state)
		
		{:noreply, state}
	end
	
	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
	def match_message({"!mmr", _sender, _channel}, state) do
		Task.start(Kaqibot.Command, :mmr_command, ['#{@opendota_players_url}#{@pendejos_id}', state])
	end
	
	def match_message({"!prev", _sender, _channel}, state) do
		Task.start(Kaqibot.Command, :prev_command, ['#{@opendota_players_url}#{@pendejos_id}/matches?limit=1', state])
	end
	
	def match_message({"!wl", _sender, _channel}, state) do
		Task.start(
			Kaqibot.Command, 
			:wl_command, 
			[
				{'#{@twitch_api_url}streams?user_login=pendejosbattis', 
				'#{@opendota_players_url}#{@pendejos_id}/matches?limit=15'},
				[get_oauth_header(state), get_twitch_id_header(state)],
				state
			]
		)
	end
	
	def match_message(_, _state) do
	end
	
	def get_oauth_header(state) do
		{'Authorization', 'Bearer #{state.token}'}
	end
	
	def get_twitch_id_header(state) do
		{'Client-Id', '#{state.twitch_id}'}
	end
	
end	