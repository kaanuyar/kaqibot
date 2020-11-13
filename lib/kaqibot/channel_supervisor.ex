defmodule Kaqibot.ChannelSupervisor do	
	use DynamicSupervisor
	
	def start_link(_) do
		DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
	end
	
	@impl DynamicSupervisor
	def init(_) do
		DynamicSupervisor.init(strategy: :one_for_one)
	end
	
	def start_child(arg = {_client, _channel, _twitch_id, _token}) do
		DynamicSupervisor.start_child(__MODULE__, {Kaqibot.Channel, arg})
	end
end	