defmodule Kaqibot.Endpoint do	

	def init(option) do
		option
	end
	
	def call(conn, _opts) do
		conn
		|> Plug.Conn.put_resp_content_type("text/plain")
		|> Plug.Conn.send_resp(200, "Kaqibot World!\n")
	end
end	