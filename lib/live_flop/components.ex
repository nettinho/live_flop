defmodule LiveFlop.Components do
  @moduledoc """
  Base components for flop functionality.
  """
  use Phoenix.Component

  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:data_accordion_icon, :string, default: nil)

  defp icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} data-accordion-icon={@data_accordion_icon} />
    """
  end

  defp icon(%{name: "svg-" <> file} = assigns) do
    assigns = assign(assigns, :file, file)

    ~H"""
    <img
      src={"/images/#{@file}.svg"}
      class={["inline", @class]}
      data-accordion-icon={@data_accordion_icon}
    />
    """
  end

  attr(:flop, :map, required: true)
  attr(:id, :string, default: "search_bar")
  attr(:label, :string, default: "Search")

  def search_bar(assigns) do
    assigns = assign(assigns, query: LiveFlop.flop_query(assigns.flop))

    ~H"""
    <form class="flex items-center gap-4 p-2" phx-change="search">
      <label for="simple-search" class="sr-only"><%= @label %></label>
      <div class="relative w-full">
        <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
          <.icon name="hero-magnifying-glass" class="w-5 h-5 text-gray-500 dark:text-gray-400" />
        </div>
        <input
          phx-debounce="200"
          type="text"
          name="search_input"
          id="simple-search"
          placeholder={@label}
          required=""
          value={@query}
          class="bg-white border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full pl-10 p-2 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
        />
      </div>
    </form>
    """
  end

  attr(:id, :string, required: true)
  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")
  attr(:new_item_click, :any, default: nil)
  attr(:flop, :map, default: nil)
  attr(:sorting, :map, default: %{col: nil, dir: :desc})
  attr(:search_label, :string)

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  slot :col, required: true do
    attr(:label, :string)
    attr(:align, :atom)
    attr(:responsive_font, :boolean)
    attr(:no_wrap, :boolean)
    attr(:sort, :atom)
  end

  slot :top_action do
    attr(:href, :any, required: true)
    attr(:text, :string)
    attr(:icon, :string)
  end

  slot(:menu_action, doc: "the slot for showing user actions inside menu")
  slot(:action, doc: "the slot for showing user actions in the last table column")

  def flop_table(assigns) do
    assigns =
      case assigns do
        %{rows: %Phoenix.LiveView.LiveStream{}} ->
          assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)

        _ ->
          assign(assigns, row_id: assigns.row_id || fn item -> "#{item.id}" end)
      end

    ~H"""
    <div class="px-0 lg:px-12">
      <div class="bg-white dark:bg-gray-800 relative shadow-md rounded-lg overflow-hidden">
        <div class="flex flex-col mx-4 py-4">
          <div class="flex flex-col md:flex-row items-stretch md:items-center md:space-x-3 space-y-3 md:space-y-0 justify-between">
            <div class="w-full md:w-1/2">
              <.search_bar :if={@flop} id={@id} flop={@flop} label={@search_label} />
            </div>
            <div class="w-full md:w-auto flex flex-col md:flex-row space-y-2 md:space-y-0 items-stretch md:items-center justify-end md:space-x-3 flex-shrink-0">
              <.link
                :for={top_action <- @top_action}
                patch={top_action.href}
                class="flex items-center justify-center text-white bg-primary-700 hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 font-medium rounded-lg text-sm px-4 py-2 dark:bg-primary-600 dark:hover:bg-primary-700 focus:outline-none dark:focus:ring-primary-800"
              >
                <.icon
                  name={Map.get(top_action, :icon, "hero-plus")}
                  class="h-3.5 w-3.5 mr-1.5 -ml-1"
                />
                <%= Map.get(top_action, :text, "Add") %>
              </.link>
            </div>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm text-left text-gray-500 dark:text-gray-400">
            <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                <.column_header :for={col <- @col} col={col} flop={@flop} />
                <th :if={@menu_action != []} scope="col" class="p-2 sm:p-4"></th>
              </tr>
            </thead>
            <tbody id={@id} phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}>
              <tr
                :for={row <- @rows}
                id={@row_id && @row_id.(row)}
                class={[
                  "hover:bg-gray-100 dark:hover:bg-gray-700",
                  @row_click && "hover:cursor-pointer"
                ]}
              >
                <td
                  :for={{col, _i} <- Enum.with_index(@col)}
                  phx-click={@row_click && @row_click.(row)}
                  class="p-2 sm:px-4 sm:py-3"
                >
                  <div class={[
                    "flex items-center sm:mr-3",
                    Map.get(col, :align) == :right && "justify-end",
                    Map.get(col, :align) == :center && "justify-center",
                    Map.get(col, :responsive_font, false) && "text-xs sm:text-sm",
                    Map.get(col, :no_wrap, false) && "whitespace-nowrap"
                  ]}>
                    <%= render_slot(col, @row_item.(row)) %>
                  </div>
                </td>

                <td class="p-2 sm:px-4 sm:py-3 flex items-center justify-end">
                  <%= for action <- @action do %>
                    <%= render_slot(action, @row_item.(row)) %>
                  <% end %>
                  <button
                    :if={@menu_action != []}
                    id={"#{@row_id.(row)}-dropdown-button"}
                    data-dropdown-toggle={"#{@row_id.(row)}-dropdown"}
                    class="inline-flex items-center text-sm font-medium hover:bg-gray-100 dark:hover:bg-gray-700 p-1.5 dark:hover-bg-gray-800 text-center text-gray-500 hover:text-gray-800 rounded-lg focus:outline-none dark:text-gray-400 dark:hover:text-gray-100"
                    type="button"
                  >
                    <.icon name="hero-ellipsis-vertical" class="w-5 h-5" />
                  </button>
                  <div
                    id={"#{@row_id.(row)}-dropdown"}
                    class="hidden z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700 dark:divide-gray-600"
                  >
                    <ul class="py-1 text-sm" aria-labelledby={"#{@row_id.(row)}-dropdown-button"}>
                      <li :for={action <- @menu_action}>
                        <%= render_slot(action, @row_item.(row)) %>
                      </li>
                    </ul>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <.pagination :if={@flop} flop={@flop} />
      </div>
    </div>
    """
  end

  def column_header(%{flop: %Flop.Meta{} = flop, col: %{sort: sort}} = assigns)
      when not is_nil(sort) do
    {column, direction} = LiveFlop.flop_order(flop)

    asc = column == sort && direction == :asc
    desc = column == sort && direction == :desc

    assigns =
      assigns
      |> assign(sort_inactive?: !asc && !desc)
      |> assign(sort_asc?: asc)
      |> assign(sort_desc?: desc)

    ~H"""
    <th scope="col">
      <div
        class="p-2 sm:p-4 flex justify-center items-center gap-1 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600"
        phx-click="sort"
        phx-value-col={@col.sort}
      >
        <span class={["font-bold"]}><%= @col.label %></span>
        <.icon :if={@sort_inactive?} name="hero-chevron-up-down" />
        <.icon :if={@sort_asc?} name="hero-chevron-up" />
        <.icon :if={@sort_desc?} name="hero-chevron-down" />
      </div>
    </th>
    """
  end

  def column_header(assigns) do
    ~H"""
    <th scope="col">
      <div class="p-2 sm:p-4 flex justify-center items-center">
        <%= @col.label %>
      </div>
    </th>
    """
  end

  attr(:flop, :map, required: true)
  attr(:label_showing, :string, default: "Showing")
  attr(:label_of, :string, default: "of")

  def pagination(assigns) do
    meta = assigns.flop
    default_size = Map.get(meta, :page_size) || 1
    flop = Map.get(meta, :flop)

    page = (Map.get(flop, :page) || 1) - 1
    size = Map.get(flop, :page_size) || default_size
    total_items = Map.get(meta, :total_count, 0)

    page_count = Map.get(meta, :total_pages, 0)

    assigns =
      assigns
      |> assign(min_item: min(page * size + 1, total_items))
      |> assign(max_item: min((page + 1) * size, total_items))
      |> assign(total_items: total_items)
      |> assign(has_pages: total_items > size)
      |> assign(has_previous: page > 0)
      |> assign(has_next: page_count > page + 1)
      |> assign(has_prev_ellipsis: page > 2)
      |> assign(has_next_ellipsis: page_count > page + 3)
      |> assign(previous_page: page > 1 && page)
      |> assign(next_page: page_count > page + 2 && page + 2)
      |> assign(page: page + 1)
      |> assign(page_count: page_count)

    ~H"""
    <div class="relative overflow-hidden bg-gray-100 rounded-lg dark:bg-gray-800">
      <nav
        class="flex flex-col items-start justify-between p-2 space-y-3 md:flex-row md:items-center md:space-y-0"
        aria-label="Table navigation"
      >
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
          <%= @label_showing %>
          <span class="font-semibold text-gray-900 dark:text-white">
            <%= @min_item %>-<%= @max_item %>
          </span>
          <%= @label_of %>
          <span class="font-semibold text-gray-900 dark:text-white"><%= @total_items %></span>
        </span>
        <ul :if={@has_pages} class="inline-flex items-stretch -space-x-px">
          <.pagination_previous disabled={not @has_previous} />
          <.pagination_button :if={@has_previous} value={1} />
          <.pagination_ellipsis :if={@has_prev_ellipsis} />
          <.pagination_button :if={@previous_page} value={@previous_page} />
          <li>
            <span aria-current="page" class={~w(
                flex items-center justify-center px-3 py-1
                h-full
                select-none z-10 leading-tight
                border border-gray-300 dark:border-gray-600
                bg-sky-100 dark:bg-sky-700/40
                text-sm text-gray-900 dark:text-white
              )}>
              <%= @page %>
            </span>
          </li>
          <.pagination_button :if={@next_page} value={@next_page} />
          <.pagination_ellipsis :if={@has_next_ellipsis} />
          <.pagination_button :if={@has_next} value={@page_count} />
          <.pagination_next disabled={not @has_next} />
        </ul>
      </nav>
    </div>
    """
  end

  def pagination_previous(assigns) do
    ~H"""
    <li>
      <button disabled={@disabled} phx-click="paginate" phx-value-page={:prev} class={~w(
                flex items-center justify-center cursor-pointer
                py-1 px-3 h-full
                text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-white
                bg-white hover:bg-sky-50 dark:bg-gray-700 dark:hover:bg-sky-300/20
                rounded-l-lg border border-gray-300 dark:border-gray-600
                disabled:bg-gray-50 disabled:dark:bg-gray-800 disabled:cursor-default
                disabled:hover:bg-gray-50 disabled:dark:hover:bg-gray-800
                disabled:text-gray-300 disabled:dark:text-gray-600
                disabled:hover:text-gray-300 disabled:hover:dark:text-gray-600
              )}>
        <span class="sr-only">Previous</span>
        <.icon name="hero-chevron-left" class="w-5 h-5" />
      </button>
    </li>
    """
  end

  def pagination_next(assigns) do
    ~H"""
    <li>
      <button disabled={@disabled} phx-click="paginate" phx-value-page={:next} class={~w(
                flex items-center justify-center cursor-pointer
                py-1 px-3 h-full
                text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-white
                bg-white hover:bg-sky-50 dark:bg-gray-700 dark:hover:bg-sky-300/20
                rounded-r-lg border border-gray-300 dark:border-gray-600
                disabled:bg-gray-50 disabled:dark:bg-gray-800 disabled:cursor-default
                disabled:hover:bg-gray-50 disabled:dark:hover:bg-gray-800
                disabled:text-gray-300 disabled:dark:text-gray-600
                disabled:hover:text-gray-300 disabled:hover:dark:text-gray-600
              )}>
        <span class="sr-only">Previous</span>
        <.icon name="hero-chevron-right" class="w-5 h-5" />
      </button>
    </li>
    """
  end

  def pagination_button(assigns) do
    ~H"""
    <li>
      <a phx-click="paginate" phx-value-page={@value} class={~w(
                flex items-center justify-center
                px-3 py-1 h-full leading-tight  cursor-pointer
                text-sm text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-white
                bg-white hover:bg-sky-50 dark:bg-gray-700 dark:hover:bg-sky-300/20
                border border-gray-300 dark:border-gray-600
              )}>
        <%= @value %>
      </a>
    </li>
    """
  end

  def pagination_ellipsis(assigns) do
    ~H"""
    <li>
      <span class="select-none flex items-center justify-center px-1 py-1 h-full  text-sm leading-tight text-gray-500 bg-white border border-gray-300 dark:bg-gray-700 dark:border-gray-600 dark:text-gray-400">
        ...
      </span>
    </li>
    """
  end

  attr(:text, :string, default: "")
  attr(:icon, :string, default: nil)
  attr(:red, :boolean, default: false)
  attr(:rest, :global, include: ~w(patch phx-click data-confirm))

  def menu_action(assigns) do
    ~H"""
    <.link {@rest}>
      <button class={[
        "flex w-full items-center py-2 px-4 hover:bg-gray-100 dark:hover:bg-gray-600",
        not @red && "dark:hover:text-white text-gray-700 dark:text-gray-200",
        @red && "text-red-500 dark:hover:text-red-400"
      ]}>
        <.icon :if={@icon} name={@icon} class="w-4 h-4 mr-2" /><%= @text %>
      </button>
    </.link>
    """
  end
end
