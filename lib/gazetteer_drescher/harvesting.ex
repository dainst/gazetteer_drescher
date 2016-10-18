defmodule GazetteerDrescher.Harvesting do
  require Logger
  import GazetteerDrescher.Writing, only: [write_place: 3]
  @user_agent [{"User-agent", "Elixir GazetteerDrescher"}]
  @gazetteer_base_url Application.get_env(:gazetteer_drescher, :gazetteer_base_url)

  def start(batchSize) do
    query = "#{@gazetteer_base_url}/search?limit=#{batchSize}&offset=0&q=*"

    Logger.info "Fetching first batch: #{query}"
    {:ok, response} =
      query
      |> start_query
      |> handle_response

    total = response["total"]
    Logger.info "#{total} places overall."

    task_first_batch = Task.async fn ->
      fetch_places({:ok, response})
    end

    Stream.unfold(batchSize, fn n when n >= total -> nil; n -> {n, n + batchSize} end)
    |> Stream.map(fn(x) ->
        url = "#{@gazetteer_base_url}/search?limit=#{batchSize}&offset#{x}"
        Logger.info "Fetching next batch: #{url}"
        url
       end)
    |> Stream.map(&Task.async(fn -> start_query(&1) end ))
    |> Stream.map(&Task.await(&1, :infinity))
    |> Stream.map(&handle_response(&1))
    |> Enum.map(&Task.async(fn -> fetch_places(&1) end ))
    |> Enum.map(&Task.await(&1, :infinity))

    Logger.info "Please stand by while the places are being processed."

    Task.await(task_first_batch, :infinity)

  end

  defp fetch_places({:ok, body}) do
    { output_type, output_file } = Agent.get(RequestInfo, &(&1))

    # use ~s sigil instead of double quotes to allow the use of double quotes in interpolation
    body["result"]
    |> Stream.map(fn x -> ~s(#{@gazetteer_base_url}/doc/#{x["gazId"]}.json) end)
    |> Stream.map(&Task.async(fn -> start_query(&1) end ))
    |> Stream.map(&Task.await(&1, 10000))
    |> Stream.map(&handle_response(&1))
    |> Enum.map(&write_place(&1, output_type, output_file))

  end

  defp handle_response({ :ok, %HTTPoison.Response{ status_code: 200, body: body} } ) do
    { :ok, Poison.decode!(body) }
  end

  defp handle_response({ :ok, %HTTPoison.Response{
      status_code: 404,
      body: body,
      headers: headers} } ) do
    Logger.error "Error code 404 in response."
    Logger.error "Headers:"
    IO.inspect headers
    Logger.error "Body:"
    IO.inspect body

    { :error, 404 }
  end

  defp handle_response({ :ok, %HTTPoison.Response{
      status_code: 500,
      body: body,
      headers: headers} } ) do
    Logger.error "Error code 500 in response."
    Logger.error "Headers:"
    IO.inspect headers
    Logger.error "Body:"
    IO.inspect body

    System.halt(0)
  end

  defp handle_response({:error, %HTTPoison.Error{reason: reason}} ) do
    Logger.error "HTTPoison error."
    IO.inspect reason

    System.halt(0)
  end

  defp start_query(url) do
    url
    |> HTTPoison.get([{"Accept", "application/json"}], [recv_timeout: :infinity])
  end
end
