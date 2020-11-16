defmodule Kaqibot.Channel do	
	use GenServer
	
	defmodule State do
		defstruct 	client: nil,
					channel: "",
					twitch_id: "",
					token: "",
					dota: nil
	end
	
	def start_link({client, channel, twitch_id, token}) do
		state = %State{client: client, channel: channel, twitch_id: twitch_id, token: token} 
		GenServer.start_link(__MODULE__, state)
	end
	
	def init(state) do
		ExIRC.Client.add_handler(state.client, self())
		ExIRC.Client.join(state.client, state.channel)
		state = %State{state | dota: Application.get_env(:kaqibot, :dota_related)}
		
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
	
	def handle_info({_ref, {:ok, msg}}, state) do
		ExIRC.Client.msg(state.client, :privmsg, state.channel, msg)
		{:noreply, state}
	end
	
	def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do
		# Task exited normally
		{:noreply, state}
	end
	
	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
	def match_message({"!mmr", _sender, _channel}, state) do
		url = state.dota[:opendota_players_url] ++ state.dota[:pendejos_id]
		Task.async(Kaqibot.Command, :mmr_command, [url])
	end
	
	def match_message({"!prev", _sender, _channel}, state) do
		url = state.dota[:opendota_players_url] ++ state.dota[:pendejos_id] ++ '/matches?limit=1'
		Task.async(Kaqibot.Command, :prev_command, [url])
	end
	
	def match_message({"!wl", _sender, _channel}, state) do
		url_1 = state.dota[:twitch_api_url] ++ 'streams?user_login=pendejosbattis'
		url_2 = state.dota[:opendota_players_url] ++ state.dota[:pendejos_id] ++ '/matches?limit=15'
		urls = [url_1, url_2]
		
		header_1 = [get_oauth_header(state), get_twitch_id_header(state)]
		headers = [header_1, []]
		
		Task.async(Kaqibot.Command, :wl_command, [urls, headers])
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