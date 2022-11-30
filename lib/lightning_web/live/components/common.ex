defmodule LightningWeb.Components.Common do
  @moduledoc false
  use LightningWeb, :component

  alias Phoenix.LiveView.JS

  def button(assigns) do
    class =
      button_classes(
        state: if(assigns[:disabled], do: :inactive, else: :active),
        color: assigns[:color] || "primary"
      )

    extra = assigns_to_attributes(assigns, [:disabled, :text])

    assigns =
      assign_new(assigns, :disabled, fn -> false end)
      |> assign_new(:onclick, fn -> nil end)
      |> assign_new(:title, fn -> nil end)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <button
      type="button"
      class={@class}
      disabled={@disabled}
      onclick={@onclick}
      title={@title}
      {@extra}
    >
      <%= if assigns[:inner_block], do: render_slot(@inner_block), else: @text %>
    </button>
    """
  end

  def button_white(assigns) do
    class = ~w[
      inline-flex items-center justify-center px-4 py-2 border
      border-gray-300 rounded-md shadow-sm
      text-sm font-medium text-gray-700
      bg-white hover:bg-gray-50
      focus:outline-none
      focus:ring-2
      focus:ring-offset-2
      focus:ring-indigo-500
    ]

    extra = assigns_to_attributes(assigns, [:disabled, :text])

    assigns =
      assign_new(assigns, :disabled, fn -> false end)
      |> assign_new(:onclick, fn -> nil end)
      |> assign_new(:title, fn -> nil end)
      |> assign(:class, class)
      |> assign(:extra, extra)

    ~H"""
    <button type="button" class={@class} onclick={@onclick} title={@title} {@extra}>
      <%= if assigns[:inner_block], do: render_slot(@inner_block), else: @text %>
    </button>
    """
  end

  defp button_classes(state: state, color: color) do
    base_classes = ~w[
      inline-flex
      justify-center
      py-2
      px-4
      border
      border-transparent
      shadow-sm
      text-sm
      font-medium
      rounded-md
      text-white
      focus:outline-none
      focus:ring-2
      focus:ring-offset-2
    ]

    case {state, color} do
      {:active, "primary"} ->
        ~w[focus:ring-primary-500 bg-primary-600 hover:bg-primary-700] ++
          base_classes

      {:inactive, "primary"} ->
        ~w[focus:ring-primary-500 bg-primary-300] ++ base_classes

      {:active, "red"} ->
        ~w[focus:ring-red-500 bg-red-600 hover:bg-red-700] ++
          base_classes

      {:inactive, "red"} ->
        ~w[focus:ring-red-500 bg-red-300] ++ base_classes

      {:active, "green"} ->
        ~w[focus:ring-green-500 bg-green-600 hover:bg-green-700] ++ base_classes

      {:inactive, "green"} ->
        ~w[focus:ring-green-500 bg-green-400] ++ base_classes
    end
  end

  def item_bar(assigns) do
    base_classes = ~w[
      w-full rounded-md drop-shadow-sm
      outline-2 outline-blue-300
      bg-white flex mb-4
      hover:outline hover:drop-shadow-none
    ]

    assigns = Map.merge(%{id: nil, class: base_classes}, assigns)

    ~H"""
    <div class={@class} id={@id}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  def flash(%{kind: :error} = assigns) do
    ~H"""
    <div
      :if={msg = live_flash(@flash, @kind)}
      id="flash"
      class="rounded-md bg-red-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={
        JS.push("lv:clear-flash")
        |> JS.remove_class("fade-in-scale", to: "#flash")
        |> hide("#flash")
      }
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-red-700">
        <.icon name={:exclamation_circle} class="w-5 w-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-red-50 rounded-md p-1.5 text-red-500 hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-red-50 focus:ring-red-600"
        >
          <.icon name={:x} class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  def flash(%{kind: :info} = assigns) do
    ~H"""
    <div
      :if={msg = live_flash(@flash, @kind)}
      id="flash"
      class="rounded-md bg-green-50 p-4 fixed top-1 right-1 w-96 fade-in-scale z-50"
      phx-click={
        JS.push("lv:clear-flash")
        |> JS.remove_class("fade-in-scale")
        |> hide("#flash")
      }
      phx-value-key="info"
      phx-hook="Flash"
    >
      <div class="flex justify-between items-center space-x-3 text-green-700">
        <.icon name={:check_circle} class="w-5 h-5" />
        <p class="flex-1 text-sm font-medium" role="alert">
          <%= msg %>
        </p>
        <button
          type="button"
          class="inline-flex bg-green-50 rounded-md p-1.5 text-green-500 hover:bg-green-100 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-green-50 focus:ring-green-600"
        >
          <.icon name={:x} class="w-4 h-4" />
        </button>
      </div>
    </div>
    """
  end

  defp hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 300,
      transition:
        {"transition ease-in duration-300", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    )
  end

  defp icon(assigns) do
    assigns =
      assign_new(assigns, :"aria-hidden", fn ->
        !Map.has_key?(assigns, :"aria-label")
      end)

    ~H"""
    <%= if @outlined do %>
      <%= apply(Heroicons.Outline, @name, [Map.to_list(@rest)]) %>
    <% else %>
      <%= apply(Heroicons.Solid, @name, [Map.to_list(@rest)]) %>
    <% end %>
    """
  end
end
