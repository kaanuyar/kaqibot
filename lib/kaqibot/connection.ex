defmodule Kaqibot.Connection do	
	use GenServer
	
	defmodule State do
		defstruct 	host: "",
					port: 0,
					nick: "",
					user: "",
					name: "",
					token: "",
					client: nil,
					channel: ""
		
	end
	
	def start_link([client, config]) do
		state = %State{client: client, channel: config.channel, host: config.host, token: config.token,
				port: config.port, nick: config.nick, user: config.user, name: config.name}
		GenServer.start_link(__MODULE__, state, name: __MODULE__)
	end
	
	def init(state) do
		IO.inspect(state)
		ExIRC.Client.add_handler(state.client, self())
		:ok = ExIRC.Client.connect!(state.client, state.host, state.port)
		
		{:ok, state}
	end
	
	
	def handle_info({:connected, server, port}, state) do
		IO.puts("Connected to #{server}:#{port}")
		:ok = ExIRC.Client.logon(state.client, state.token, state.nick, state.user, state.name)
		
		{:noreply, state}
	end
	
	def handle_info(:logged_in, state) do
		IO.puts("Logged in")
		Kaqibot.ChannelSupervisor.start_child({state.client, state.channel})
		
		{:noreply, state}
	end
	
	def handle_info(_msg, state) do
		{:noreply, state}
	end
	
end	