defmodule Exddnss.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Exddnss.DdnssUpdater, %{poll_intervall: 60_0000,
			       # Put in your update key and host
			       # update_key: "ae48b5f1c26b7fa5bb3f1bc028ce17e6",
			       # update_host: "example.ddnss.de"
			      }
			     }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exddnss.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
