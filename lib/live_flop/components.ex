defmodule LiveFlop.Components do
  @moduledoc """
  Base components for flop functionality.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  attr(:name, :string, required: true)
  attr(:class, :string, default: nil)

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  attr(:rows, :list, required: true)
  attr(:row_id, :any, default: nil, doc: "the function for generating the row id")
  attr(:row_click, :any, default: nil, doc: "the function for handling phx-click on each row")
  attr(:flop, :map, default: nil)
  attr(:gettext, :any, default: &Function.identity/1, doc: "the function gettext function")

  attr(:row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"
  )

  attr(:search_text, :string, default: "Search")
  attr(:filters_text, :string, default: "Filters")
  attr(:add_text, :string, default: "Add")
  attr(:showing_text, :string, default: "Showing")
  attr(:of_text, :string, default: "of")

  slot :col, required: true do
    attr(:label, :string)
    attr(:align_right, :boolean)
    attr(:sort, :atom)
  end

  slot :top_action do
    attr(:href, :any, required: true)
    attr(:text, :string)
    attr(:icon, :string)
  end

  slot(:extra_filter, doc: "the slot extra filters")
  slot(:menu_action, doc: "the slot for showing user actions inside menu")
  slot(:action, doc: "the slot for showing user actions in the last table column")

  def flop_table(assigns) do
    assigns = assign(assigns, query: LiveFlop.flop_query(assigns.flop))

    ~H"""
    <div class="px-4 lg:px-12">
      <div class="bg-white relative shadow-md sm:rounded-lg overflow-hidden">
        <div class="flex flex-col mx-4 py-4">
          <div class="flex flex-col md:flex-row items-stretch md:items-center md:space-x-3 space-y-3 md:space-y-0 justify-between">
            <div class="w-full md:w-1/2">
              <form class="flex items-center gap-4" phx-change="search">
                <label for="simple-search" class="sr-only"><%= @search_text %></label>
                <div class="relative w-full">
                  <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                    <.icon
                      name="hero-magnifying-glass"
                      class="w-5 h-5 text-gray-500 dark:text-gray-400"
                    />
                  </div>
                  <input
                    phx-debounce="200"
                    type="text"
                    name="search_input"
                    id="simple-search"
                    placeholder={@search_text}
                    required=""
                    value={@query}
                    class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-primary-500 focus:border-primary-500 block w-full pl-10 p-2 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-primary-500 dark:focus:border-primary-500"
                  />
                </div>
                <button
                  :if={not Enum.empty?(@extra_filter)}
                  class="w-full md:w-auto flex gap-1 items-center justify-center py-2 px-4 text-sm font-medium text-gray-900 focus:outline-none bg-white rounded-lg border border-gray-200 hover:bg-gray-100 hover:text-primary-700 focus:z-10 focus:ring-4 focus:ring-gray-200 dark:focus:ring-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:border-gray-600 dark:hover:text-white dark:hover:bg-gray-700"
                  type="button"
                  phx-click={JS.toggle(to: "#searchable-filters")}
                >
                  <.icon name="hero-funnel" /> <%= @filters_text %>
                </button>
              </form>
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
                <%= Map.get(top_action, :text, @add_text) %>
              </.link>
            </div>
          </div>
          <div :if={not Enum.empty?(@extra_filter)} class="pt-4 w-1/2" id="searchable-filters">
            <div :for={extra_filter <- @extra_filter}><%= render_slot(extra_filter) %></div>
          </div>
        </div>
        <div class="overflow-x-auto">
          <table class="w-full text-sm text-left text-gray-500 dark:text-gray-400">
            <thead class="text-xs text-gray-700 uppercase bg-gray-50 dark:bg-gray-700 dark:text-gray-400">
              <tr>
                <.column_header :for={col <- @col} col={col} flop={@flop} />
                <th scope="col" class="p-4">
                  <span class="sr-only">>actions</span>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                :for={row <- @rows}
                id={"row-#{row.id}"}
                class={[
                  "hover:bg-gray-100 dark:hover:bg-gray-700",
                  @row_click && "hover:cursor-pointer"
                ]}
              >
                <td :for={col <- @col} phx-click={@row_click && @row_click.(row)} class="px-4 py-3">
                  <div class={["flex items-center mr-3", Map.get(col, :align_right) && "justify-end"]}>
                    <%= render_slot(col, @row_item.(row)) %>
                  </div>
                </td>

                <td class="px-4 py-3 flex items-center justify-end">
                  <%= for action <- @action do %>
                    <%= render_slot(action, @row_item.(row)) %>
                  <% end %>
                  <button
                    :if={@menu_action != []}
                    id={"row-#{row.id}-dropdown-button"}
                    phx-hook="FlowbiteOnMount"
                    data-dropdown-toggle={"row-#{row.id}-dropdown"}
                    class="inline-flex items-center text-sm font-medium hover:bg-gray-100 dark:hover:bg-gray-700 p-1.5 dark:hover-bg-gray-800 text-center text-gray-500 hover:text-gray-800 rounded-lg focus:outline-none dark:text-gray-400 dark:hover:text-gray-100"
                    type="button"
                  >
                    <.icon name="hero-ellipsis-vertical" class="w-5 h-5" />
                  </button>
                  <div
                    id={"row-#{row.id}-dropdown"}
                    class="hidden z-10 w-44 bg-white rounded divide-y divide-gray-100 shadow dark:bg-gray-700 dark:divide-gray-600"
                  >
                    <ul class="py-1 text-sm" aria-labelledby={"row-#{row.id}-dropdown-button"}>
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
        <.flop_pagination :if={@flop} flop={@flop} showing_text={@showing_text} of_text={@of_text}/>
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
        class="p-4 flex justify-center items-center gap-1 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-600"
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
      <div class="p-4 flex justify-center items-center">
        <%= @col.label %>
      </div>
    </th>
    """
  end

  attr(:text, :string, default: "")
  attr(:icon, :string, default: nil)
  attr(:red, :boolean, default: false)
  attr(:rest, :global, include: ~w(patch phx-click data-confirm))

  def flop_table_action(assigns) do
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

  attr(:flop, :map, required: true)
  attr(:showing_text, :string, default: "Showing")
  attr(:of_text, :string, default: "of")

  def flop_pagination(assigns) do
    meta = assigns.flop
    flop = Map.get(meta, :flop)

    page = (Map.get(flop, :page) || 1) - 1
    size = Map.get(flop, :page_size) || 1
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
    <div class="relative overflow-hidden bg-white rounded-b-lg shadow-md dark:bg-gray-800">
      <nav
        class="flex flex-col items-start justify-between p-4 space-y-3 md:flex-row md:items-center md:space-y-0"
        aria-label="Table navigation"
      >
        <span class="text-sm font-normal text-gray-500 dark:text-gray-400">
          <%= @showing_text %>
          <span class="font-semibold text-gray-900 dark:text-white">
            <%= @min_item %>-<%= @max_item %>
          </span>
          <%= @of_text %>
          <span class="font-semibold text-gray-900 dark:text-white"><%= @total_items %></span>
        </span>
        <ul :if={@has_pages} class="inline-flex items-stretch -space-x-px">
          <li>
            <a
              :if={@has_previous}
              phx-click="paginate"
              phx-value-page={:prev}
              href="#"
              class="flex items-center justify-center h-full py-1.5 px-3 ml-0 text-gray-500 bg-white rounded-l-lg border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <span class="sr-only">Previous</span>
              <svg
                class="w-5 h-5"
                aria-hidden="true"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </a>
          </li>
          <li :if={@has_previous}>
            <a
              phx-click="paginate"
              phx-value-page={1}
              class="flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              1
            </a>
          </li>
          <li :if={@has_prev_ellipsis}>
            <span class="select-none flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400">
              ...
            </span>
          </li>
          <li :if={@previous_page}>
            <a
              phx-click="paginate"
              phx-value-page={@previous_page}
              class="flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <%= @previous_page %>
            </a>
          </li>
          <li>
            <span
              aria-current="page"
              class="select-none z-10 flex items-center justify-center px-3 py-2 text-sm leading-tight border text-primary-600 bg-primary-50 border-primary-300 hover:bg-primary-100 hover:text-primary-700 dark:border-gray-700 dark:bg-gray-700 dark:text-white"
            >
              <%= @page %>
            </span>
          </li>
          <li :if={@next_page}>
            <a
              phx-click="paginate"
              phx-value-page={@next_page}
              class="flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <%= @next_page %>
            </a>
          </li>
          <li :if={@has_next_ellipsis}>
            <span class="select-none flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400">
              ...
            </span>
          </li>
          <li :if={@has_next}>
            <a
              phx-click="paginate"
              phx-value-page={@page_count}
              class="flex items-center justify-center px-3 py-2 text-sm leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <%= @page_count %>
            </a>
          </li>
          <li>
            <a
              :if={@has_next}
              phx-click="paginate"
              phx-value-page={:next}
              class="flex items-center justify-center h-full py-1.5 px-3 leading-tight text-gray-500 bg-white rounded-r-lg border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white"
            >
              <span class="sr-only">Next</span>
              <svg
                class="w-5 h-5"
                aria-hidden="true"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </a>
          </li>
        </ul>
      </nav>
    </div>
    """
  end
end
