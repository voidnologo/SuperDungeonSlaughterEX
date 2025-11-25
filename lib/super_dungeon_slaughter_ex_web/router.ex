defmodule SuperDungeonSlaughterExWeb.Router do
  use SuperDungeonSlaughterExWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SuperDungeonSlaughterExWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SuperDungeonSlaughterExWeb do
    pipe_through :browser

    live "/", GameLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", SuperDungeonSlaughterExWeb do
  #   pipe_through :api
  # end
end
