defmodule LiveFlop do
  @moduledoc """
  Documentation for `LiveFlop`.
  """

  def flop_query(%{flop: %Flop{} = flop}) do
    flop
    |> Flop.unnest_filters([:searchable])
    |> Map.get(:searchable, "")
  end

  def flop_query(_), do: ""

  def flop_filter(%{flop: %Flop{} = flop}, filter, default \\ nil) do
    %{value: value, op: op} =
      flop
      |> Map.get(:filters)
      |> Enum.find(%Flop.Filter{}, &(&1.field == filter))

    {value || default, op}
  end

  def flop_order(%{flop: %Flop{order_by: [column | _], order_directions: [direction | _]}}) do
    {column, direction}
  end

  def flop_order(_), do: {nil, nil}
  def flop_meta(socket), do: Map.get(socket.assigns, :flop_meta, %Flop.Meta{})

  def mount_assigns(route, schema, opts \\ []) do
    {query, opts} = Keyword.pop(opts, :query, schema)
    {filters, opts} = Keyword.pop(opts, :filters, [])
    {query_functions, opts} = Keyword.pop(opts, :query_functions, [])
    {patch_function, opts} = Keyword.pop!(opts, :patch_function)

    [
      items: [],
      flop_meta: %Flop.Meta{
        flop: %Flop{
          filters: filters
        }
      },
      searchable: %{
        route: route,
        schema: schema,
        query: query,
        default_filters: filters,
        query_functions: query_functions,
        patch_function: patch_function,
        opts: opts
      }
    ]
  end

  def fetch_assigns(socket) do
    params = socket.assigns.flop_meta.flop
    fetch_assigns(socket, params)
  end

  def fetch_assigns(socket, params) do
    %{
      schema: schema,
      query: query,
      default_filters: default_filters,
      query_functions: query_functions
    } = socket.assigns.searchable

    flop = Flop.validate!(params, for: schema)

    {items, meta} =
      query_functions
      |> Enum.reduce(query, fn fun, q -> fun.(q, socket.assigns) end)
      |> Flop.run(%{flop | filters: flop.filters ++ default_filters}, for: schema)

    [
      flop_meta: meta,
      items: items
    ]
  end

  def push_filter(socket, filter, value, opts \\ []) do
    %{flop: flop} = meta = flop_meta(socket)
    %{route: route, patch_function: patch_function} = socket.assigns.searchable

    flop =
      flop
      |> Flop.unnest_filters([filter])
      |> Map.put(filter, value)
      |> Flop.nest_filters([filter], opts)
      |> Flop.validate!()
      |> Flop.set_page(1)

    path =
      meta
      |> Map.put(:flop, flop)
      |> then(&Flop.Phoenix.build_path(route, &1))

    patch_function.(socket, to: path)
  end

  defp push_flop_update(socket, func) do
    %{flop: flop} = meta = flop_meta(socket)
    %{route: route, patch_function: patch_function} = socket.assigns.searchable

    meta
    |> Map.put(:flop, func.(flop))
    |> then(&Flop.Phoenix.build_path(route, &1))
    |> then(&patch_function.(socket, to: &1))
  end

  def handle_search(socket, query) do
    push_filter(
      socket,
      :searchable,
      empty_as_nil(query),
      operators: %{searchable: :ilike}
    )
  end

  def handle_paginate(socket, "next") do
    push_flop_update(socket, &to_next_page/1)
  end

  def handle_paginate(socket, "prev") do
    push_flop_update(socket, &Flop.to_previous_page/1)
  end

  def handle_paginate(socket, page) do
    push_flop_update(socket, &Flop.set_page(&1, page))
  end

  def handle_sort(socket, col) do
    push_flop_update(socket, &Flop.push_order(&1, col))
  end

  defp empty_as_nil(""), do: nil
  defp empty_as_nil(value), do: value

  defp to_next_page(%Flop{page: nil} = flop), do: %{flop | page: 2}
  defp to_next_page(flop), do: Flop.to_next_page(flop)

  defmacro __using__(_opts) do
    quote do
      def handle_event("search", %{"search_input" => query}, socket),
        do: {:noreply, LiveFlop.handle_search(socket, query)}

      def handle_event("paginate", %{"page" => page}, socket),
        do: {:noreply, LiveFlop.handle_paginate(socket, page)}

      def handle_event("sort", %{"col" => col}, socket),
        do: {:noreply, LiveFlop.handle_sort(socket, col)}
    end
  end
end
