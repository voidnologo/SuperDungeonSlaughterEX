defmodule SuperDungeonSlaughterExWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use SuperDungeonSlaughterExWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8">
      <div class="flex-1">
        <a href="/" class="flex-1 flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex flex-column px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="btn btn-ghost">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="btn btn-ghost">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="btn btn-primary">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides theme selector for multiple visual themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-ghost btn-sm">
        <.icon name="hero-swatch" class="size-5" />
        <span class="hidden sm:inline">Theme</span>
      </label>
      <ul
        tabindex="0"
        class="dropdown-content z-[1] menu p-2 shadow-lg bg-base-200 rounded-box w-52 border-2 border-base-300"
      >
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="system"
            class="[[data-theme=system]_&]:bg-base-300 [[data-theme=system]_&]:font-bold"
          >
            <.icon name="hero-computer-desktop-micro" class="size-4" /> System Default
          </button>
        </li>
        <li class="menu-title">
          <span>Light Themes</span>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="light"
            class="[[data-theme=light]_&]:bg-base-300 [[data-theme=light]_&]:font-bold"
          >
            <.icon name="hero-sun-micro" class="size-4" /> Light
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="ink"
            class="[[data-theme=ink]_&]:bg-base-300 [[data-theme=ink]_&]:font-bold"
          >
            <.icon name="hero-pencil-square-micro" class="size-4" /> Ink & Brush
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="parchment"
            class="[[data-theme=parchment]_&]:bg-base-300 [[data-theme=parchment]_&]:font-bold"
          >
            <.icon name="hero-document-text-micro" class="size-4" /> Parchment
          </button>
        </li>
        <li class="menu-title">
          <span>Dark Themes</span>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="dark"
            class="[[data-theme=dark]_&]:bg-base-300 [[data-theme=dark]_&]:font-bold"
          >
            <.icon name="hero-moon-micro" class="size-4" /> Dark
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="arcade"
            class="[[data-theme=arcade]_&]:bg-base-300 [[data-theme=arcade]_&]:font-bold"
          >
            <.icon name="hero-play-micro" class="size-4" /> Arcade
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="fantasy"
            class="[[data-theme=fantasy]_&]:bg-base-300 [[data-theme=fantasy]_&]:font-bold"
          >
            <.icon name="hero-sparkles-micro" class="size-4" /> High Fantasy
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="terminal"
            class="[[data-theme=terminal]_&]:bg-base-300 [[data-theme=terminal]_&]:font-bold"
          >
            <.icon name="hero-command-line-micro" class="size-4" /> Terminal
          </button>
        </li>
        <li>
          <button
            phx-click={JS.dispatch("phx:set-theme")}
            data-phx-theme="cyberpunk"
            class="[[data-theme=cyberpunk]_&]:bg-base-300 [[data-theme=cyberpunk]_&]:font-bold"
          >
            <.icon name="hero-bolt-micro" class="size-4" /> Cyberpunk
          </button>
        </li>
      </ul>
    </div>
    """
  end
end
