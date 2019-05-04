defmodule Exddnss.DdnssUpdater do
  use GenServer
  require Logger

  # Client API

  @doc """
  Starts the ddnss updater

  The example config below would poll every minute for the current ip and compares it
  to the ip address that was used during the last update.
  If these are different, an update is triggered.

  The first update is performed after the first poll_intervall.

  ## Parameters

  - config: The configuration for the ddnss updater, must be something like
                %{poll_intervall: 60 * 1000,
		  update_key: "238579df35793ab745974",
		  update_host: "example.ddnss.de"}

  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, %{config: config,
				       state: %{dns_ip: ""}})
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    schedule_work(state)
    {:ok, state}
  end

  @impl true
  def handle_info(:verify_ip, state) do
    new_ip = verify_ip(state)
    schedule_work(state)

    {:noreply, put_in(state, [:state, :dns_ip], new_ip)}
  end

  defp schedule_work(state) do
    # In one minute
    Process.send_after(self(), :verify_ip, state.config.poll_intervall)
  end

  defp verify_ip(state) do
    dns_ip = state.state.dns_ip
    case get_own_ip() do
      {:ok, ip} ->
	Logger.info "My IP is #{ip}"
	if ip != dns_ip do
	  update_ip!(state.config)
	end
	ip
      {:error, reason} ->
	Logger.warn "Error getting IP: #{reason}"
	dns_ip
    end
  end

  defp ip_from_body(body) do
    case Regex.run(~r/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/, body) do
      [ip] -> {:ok, ip}
      _ -> {:error, :no_ip_addr_match}
    end
  end
  
  defp get_own_ip() do
    case HTTPoison.get("http://www.ddnss.de/meineip.php") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
	ip_from_body(body)
      {:ok, %HTTPoison.Response{status_code: code}} ->
	{:error, code}
      {:error, %HTTPoison.Error{reason: reason}} ->
	{:error, reason}
    end
  end

  defp update_ip!(config) do
    Logger.info "Updating ip"
    {:ok, %HTTPoison.Response{status_code: 200, body: _}} = HTTPoison.get("https://www.ddnss.de/upd.php?key=#{config.update_key}&host=#{config.update_host}")
  end

end
