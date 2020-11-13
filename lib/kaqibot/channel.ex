defmodule Kaqibot.Channel do	
	use GenServer
	
	defmodule State do
		defstruct 	client: nil,
					channel: "",
					twitch_id: "",
					token: "",
					started_at: 0,
					request_ids: %{}
	end
	
	@pendejos_id 106080212
	#@gorgc_id 56939869
	@dotabuff_matches_url "https://www.dotabuff.com/matches/"
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
		{:ok, new_state} = match_message({message, sender, channel}, state)
		
		{:noreply, new_state}
	end
	
	def handle_info({:http, {request_id, result}}, state) do	
		command = Map.fetch!(state.request_ids, request_id)
		request_ids = Map.delete(state.request_ids, request_id)
		state = %State{state | request_ids: request_ids}
		{:ok, state} = handle_command(command, result, state)
		
		{:noreply, state}
	end
	
	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
	def match_message({"!mmr", _sender, _channel}, state) do
		state = async_http_request( 
			'#{@opendota_players_url}#{@pendejos_id}', 
			[], 
			:mmr, 
			state
		)
		
		{:ok, state}
	end
	
	def match_message({"!prev", _sender, _channel}, state) do
		state = async_http_request( 
			'#{@opendota_players_url}#{@pendejos_id}/matches?limit=1',
			[],
			:prev, 
			state
		)
		
		{:ok, state}
	end
	
	def match_message({"!wl", _sender, _channel}, state) do
		state = async_http_request( 
			'#{@twitch_api_url}streams?user_login=pendejosbattis', 
			[get_oauth_header(state), get_twitch_id_header(state)], 
			:wl, 
			state
		)
		
		{:ok, state}
	end
	
	def match_message(_, state) do
		{:ok, state}
	end
	
	def handle_command(:mmr, result, state) do
		{_, _, body} = result
		player_info = Poison.decode!(body)
		player_rank = player_info["rank_tier"]
		reply = find_medal(player_rank)
		ExIRC.Client.msg(state.client, :privmsg, state.channel, reply)
		{:ok, state}
	end
	
	def handle_command(:prev, result, state) do
		{_, _, body} = result
		[match_info] = Poison.decode!(body)
		match_id = match_info["match_id"]
		reply = "#{@dotabuff_matches_url}#{match_id}"
		ExIRC.Client.msg(state.client, :privmsg, state.channel, reply)
		{:ok, state}
	end
	
	def handle_command(:wl, result, state) do
		{_, _, body} = result
		stream_info = Poison.decode!(body)
		
		state = 
		if stream_info["data"] == [] do
			reply = "not live"
			ExIRC.Client.msg(state.client, :privmsg, state.channel, reply)
			state
		else
			[stream_data] = stream_info["data"]
			started_at = stream_data["started_at"]
			{:ok, date, 0} = DateTime.from_iso8601(started_at)
			date = DateTime.to_unix(date)
			
			state = %State{state | started_at: date}
			
			async_http_request( 
				'#{@opendota_players_url}#{@pendejos_id}/matches?limit=10',
				[],
				:score, 
				state
			)
		end
		
		{:ok, state}
	end
	
	def handle_command(:score, result, state) do
		{_, _, body} = result
		matches_info = Poison.decode!(body)
		{w, l} = find_wl_count(matches_info, state.started_at, {0, 0})
		reply = "W - #{w} L - #{l}"
		ExIRC.Client.msg(state.client, :privmsg, state.channel, reply)
		
		{:ok, state}
	end
	
	def find_wl_count(matches_list, started_at, acc) do
		[match_info | tail] = matches_list
		match_time = match_info["start_time"]
		
		if match_time > started_at do
			{w, l} = acc
			acc = cond do
				match_info["player_slot"] < 100 and match_info["radiant_win"] == true
					-> {w+1, l}
				match_info["player_slot"] < 100 and match_info["radiant_win"] == false
					-> {w, l+1}
				match_info["player_slot"] > 100 and match_info["radiant_win"] == true
					-> {w, l+1}
				match_info["player_slot"] > 100 and match_info["radiant_win"] == false
					-> {w+1, l}
			end
			find_wl_count(tail, started_at, acc)
		else
			acc
		end
	end
	
	def find_medal(rank_id) do
		rank_id = to_string(rank_id)
		first_id = String.at(rank_id, 0)
		second_id = String.at(rank_id, 1)
		
		medal = case first_id do
			"1" -> "Herald"
			"2" -> "Guardian"
			"3" -> "Crusader"
			"4" -> "Archon"
			"5" -> "Legend"
			"6" -> "Ancient"
			"7" -> "Divine"
			"8" -> "Immortal"
		end
		
		"#{medal} #{second_id}"
	end
	
	def async_http_request(url, header, command, state) do
		{:ok, request_id} = :httpc.request(
			:get, 
			{url, header},
			[],
			[{:sync, false}]
		)
		
		request_ids = Map.put(state.request_ids, request_id, command)
		%State{state | request_ids: request_ids }
	end	
	
	def get_oauth_header(state) do
		{'Authorization', 'Bearer #{state.token}'}
	end
	
	def get_twitch_id_header(state) do
		{'Client-Id', '#{state.twitch_id}'}
	end
	
end	