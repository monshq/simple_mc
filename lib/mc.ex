defmodule SimpleMC.MC do
  require Logger
  use SMPPEX.MC

  def launch() do
    port = Application.get_env(:simple_mc, :port)
    SMPPEX.MC.start({__MODULE__, []}, [transport_opts: [port: port]])
  end

  def init(_socket, _transport, []) do
    {:ok, 0}
  end

  def handle_pdu(pdu, last_id) do
    Logger.debug("received pdu: #{SMPPEX.Pdu.PP.format pdu}")

    case pdu |> SMPPEX.Pdu.command_id |> SMPPEX.Protocol.CommandNames.name_by_id do
      {:ok, :enquire_link} ->
        SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.enquire_link_resp())
        last_id

      {:ok, :submit_sm} ->
        SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.submit_sm_resp(0, to_string(last_id)))
        last_id + 1

      {:ok, :bind_transmitter} ->
        system_id = SMPPEX.Pdu.field(pdu, :system_id)
        password = SMPPEX.Pdu.field(pdu, :password)

        case {system_id, password} do
          {"login", "password"} ->
            Logger.info("bind request accepted for system_id: #{system_id}, password: #{password}")
            SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.bind_transmitter_resp(0))
          _ ->
            Logger.error("bind request rejected for system_id: #{system_id}, password: #{password}")
            error_code = SMPPEX.Pdu.Errors.code_by_name(:RINVSYSID)
            SMPPEX.MC.reply(self(), pdu, SMPPEX.Pdu.Factory.bind_transmitter_resp(error_code))
        end
        last_id

      _ -> last_id
    end
  end
end
