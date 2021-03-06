defmodule GazetteerDrescher.Harvesting do
  @moduledoc """
  This module implements the core harvesting functions.
  """
  require Logger
  import GazetteerDrescher.Writing, only: [write_place: 1]
  @user_agent {"User-agent", "Elixir GazetteerDrescher"}
  @gazetteer_base_url Application.get_env(:gazetteer_drescher, :gazetteer_base_url)
  @cache_config Application.get_env(:gazetteer_drescher, :cached_place_types)

  @doc """
  Starts harvesting with a given search query string and batch size.

  Example: `start("q=*", 100)`

  Returns: `:ok`
  """
  def start(q, batch_size) do
    query = "#{@gazetteer_base_url}/search.json?limit=#{batch_size}&offset=0&#{q}"

    Logger.info "Fetching first batch: #{query}"
    {:ok, response} =
      query
      |> start_query(3)
      |> handle_response

    total = response["total"]

    Logger.info "#{total} places overall."

    task_first_batch = Task.async fn ->
      fetch_places({:ok, response})
    end

    Logger.info "Please stand by while the places are being processed."

    Stream.unfold(batch_size, fn
      offset when offset >= total -> nil;
      offset -> {offset, offset + batch_size}
      end)
    |> Stream.map(fn(x) ->
        url = "#{@gazetteer_base_url}/search.json?limit=#{batch_size}&offset=#{x}&#{q}"
        Logger.info "Fetching next batch: #{url}"
        url
       end)
    |> Stream.map(&start_query(&1, 3))
    |> Stream.map(&handle_response(&1))
    |> Enum.map(&Task.async(fn -> fetch_places(&1) end ))
    |> Enum.map(&Task.await(&1, :infinity))


    Task.await(task_first_batch, :infinity)

  end

  defp fetch_places({:ok, body}) do
    # Logger.debug "fetch_places called"

    # use ~s sigil instead of double quotes to allow the use of double quotes in interpolation
    body["result"]
    |> Stream.map(fn x ->
        ~s(#{@gazetteer_base_url}/doc/#{x["gazId"]}.json)
      end)
    |> Enum.map(&Task.async(fn -> start_query(&1, 3) end ))
    |> Enum.map(&Task.await(&1, :infinity))
    |> Stream.map(&handle_response(&1))
    |> Stream.map(&add_to_cache(&1))
    |> Stream.map(fn({:ok, place}) -> place end)
    |> Enum.map(&write_place(&1))

  end

  @doc """
  Fetches a single iDAI.gazetteer place, specified by URI.

  Example: `fetch_place("https://gazetteer.dainst.org/doc/2312125.json")`

  Returns: The place's JSON data parsed by :poison, as an Elixir Map.
  """
  def fetch_place(url) do
    url
    |> start_query(3)
    |> handle_response
    |> add_to_cache
  end

  defp start_query(url, retries) do
    response =
      url
      |> HTTPoison.get([{"Accept", "application/json"}, @user_agent],
        [recv_timeout: 60000, follow_redirect: true])

    [ response, retries, url ]
  end

  defp handle_response([{ :ok, %HTTPoison.Response{ status_code: 200, body: body} },
    _retries, _url] ) do
    { :ok, Poison.decode!(body) }
  end

  defp handle_response([{ :ok, %HTTPoison.Response{
      status_code: 404,
      body: _body,
      headers: _headers} }, _retries, _url] ) do
    { :error, 404 }
  end

  defp handle_response([{:ok, %HTTPoison.Response{
      status_code: 403,
      body: _body,
      headers: _headers} }, _retries, _url] ) do
    { :error, 403 }
  end

  defp handle_response([{ :ok, %HTTPoison.Response{
      status_code: 500,
      body: body,
      headers: headers} }, retries, url] ) do
    Logger.error "Status code 500 in response."
    Logger.error "Headers: #{inspect headers}"
    Logger.error "Body: #{inspect body}"
    if retries > 0 do
      Logger.error "Retrying.."
      url
      |> start_query(retries - 1)
      |> handle_response
    else
      Logger.error "Stopping script..."
      System.halt()
    end
  end

  defp handle_response([{:error, %HTTPoison.Error{reason: :timeout} = error_msg},
    retries, url]) do

    if retries > 0 do
      url
      |> start_query(retries - 1)
      |> handle_response
    else
      Logger.error "HTTPoison error."
      Logger.error "#{inspect error_msg}"
      Logger.error "#{inspect url}"
    end
  end

  defp handle_response([{:error, error_msg }, _retries,  url]) do
    Logger.error "HTTPoison error."
    IO.inspect error_msg
    IO.inspect url

    System.halt(0)
  end

  defp add_to_cache({:ok, place}) do

    if Map.has_key?(place, "types") do
      add? =
        place["types"]
        |> Enum.map(&Enum.member?(@cache_config, &1))
        |> Enum.any?

      if add? == true do
        _inserted = :ets.insert_new(:cached_places, { place["@id"], place })
      end
    end

    # Also cache "Welt" (world), the overall root.
    if place["gazId"] == "2042600" do
      _inserted = :ets.insert_new(:cached_places, { place["@id"], place })
    end
    {:ok, place}
  end

  defp add_to_cache({error, reason}) do
    {error, reason}
  end
end
