defmodule Kaqibot.Command do
	
	def mmr_command(url) do
		{:ok, {_, _, body}} = :httpc.request(url)
		player_info = Poison.decode!(body)
		player_rank = player_info["rank_tier"]
		reply = find_medal(player_rank)
		{:ok, reply}
	end
	
	def prev_command(url) do
		{:ok, {_, _, body}} = :httpc.request(url)
		[match_info] = Poison.decode!(body)
		match_id = match_info["match_id"]
		reply = "https://www.dotabuff.com/matches/#{match_id}"
		{:ok, reply}
	end
	
	def wl_command(urls, headers) do
		[url_1, url_2] = urls
		[header_1, _] = headers
		{:ok, {_, _, body}} = :httpc.request(:get, {url_1, header_1}, [], [])
		stream_info = Poison.decode!(body)
		
		if stream_info["data"] == [] do
			reply = "Stream not live"
			{:ok, reply}
		else
			[stream_data] = stream_info["data"]
			started_at = stream_data["started_at"]
			{:ok, date, 0} = DateTime.from_iso8601(started_at)
			date = DateTime.to_unix(date)
			
			{:ok, {_, _, body}} = :httpc.request(url_2)
			matches_info = Poison.decode!(body)
			{w, l} = find_wl_count(matches_info, date, {0, 0})
			reply = "W #{w} - L #{l}"
			{:ok, reply}
		end
	end
	
	def find_wl_count(matches_list, started_at, accumulator) do
		[match_info | tail] = matches_list 
		
		if match_info["start_time"] + match_info["duration"] > started_at do
			{w, l} = accumulator
			accumulator = 
			cond do
				match_info["player_slot"] < 100 and match_info["radiant_win"] == true -> 
					{w+1, l}
				match_info["player_slot"] < 100 and match_info["radiant_win"] == false -> 
					{w, l+1}
				match_info["player_slot"] > 100 and match_info["radiant_win"] == true -> 
					{w, l+1}
				match_info["player_slot"] > 100 and match_info["radiant_win"] == false -> 
					{w+1, l}
			end
			
			if tail == [] do
				accumulator
			else
				find_wl_count(tail, started_at, accumulator)
			end
		else
			accumulator
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
	
end	