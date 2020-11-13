defmodule Kaqibot.Channel do	
	use GenServer
	
	defmodule State do
		defstruct 	client: nil,
					channel: "",
					request_ids: %{}
		
	end
	
	@pendejos_id 106080212
	@dotabuff_matches_url "https://www.dotabuff.com/matches/"
	@opendota_players_url 'https://api.opendota.com/api/players/'
	
	def start_link({client, channel}) do
		state = %State{client: client, channel: channel} 
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
		:ok = handle_command(command, result, state)
		
		{:noreply, state}
	end
	
	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
	def match_message({"!mmr", _sender, _channel}, state) do
		{:ok, request_id} = :httpc.request(
			:get, 
			{'#{@opendota_players_url}#{@pendejos_id}', []},
			[],
			[{:sync, false}]
		)
		
		request_ids = Map.put(state.request_ids, request_id, :mmr)
		{:ok, %State{state | request_ids: request_ids }}
	end
	
	def match_message({"!prev", _sender, _channel}, state) do
		{:ok, request_id} = :httpc.request(
			:get, 
			{'#{@opendota_players_url}#{@pendejos_id}/matches?limit=1', []},
			[],
			[{:sync, false}]
		)
		
		request_ids = Map.put(state.request_ids, request_id, :prev)
		{:ok, %State{state | request_ids: request_ids }}
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
		:ok
	end
	
	def handle_command(:prev, result, state) do
		{_, _, body} = result
		[match_info] = Poison.decode!(body)
		match_id = match_info["match_id"]
		reply = "#{@dotabuff_matches_url}#{match_id}"
		ExIRC.Client.msg(state.client, :privmsg, state.channel, reply)
		:ok
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
	
end	