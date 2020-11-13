defmodule Kaqibot.Application do	
	use Application
	
	def start(_type, _args) do
		{:ok, client} = ExIRC.start_link!()
		Process.register(client, :twitchirc)
		config = Application.get_env(:kaqibot, :bot)
		config = Map.put(config, :token, System.get_env("TWITCH_ACCESS_TOKEN"))
			
		children = [
		  {Kaqibot.Connection, [:twitchirc, config]},
		  Kaqibot.ChannelSupervisor,
		  {Plug.Cowboy, scheme: :http, plug: Kaqibot.Endpoint, options: [port: 4000]}
		]
		Supervisor.start_link(children, strategy: :one_for_one)
	end
end	