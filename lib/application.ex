defmodule SimpleMC.Application do
  use Application
  require IEx
  def start(_type, _args) do
    SimpleMC.MC.launch()
    Supervisor.start_link([], [strategy: :one_for_one])
  end
end
