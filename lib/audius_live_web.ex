defmodule AudiusLiveWeb do
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: AudiusLiveWeb,
        formats: [:html, :json],
        layouts: [html: AudiusLiveWeb.Layouts]

      import Plug.Conn
      import AudiusLiveWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view(opts \\ []) do
    quote do
      @opts Keyword.merge(
              [
                layout: {AudiusLiveWeb.Layouts, :live},
                container: {:div, class: "relative h-screen flex overflow-hidden bg-white"}
              ],
              unquote(opts)
            )
      use Phoenix.LiveView,
                layout: {AudiusLiveWeb.Layouts, :live},
                container: {:div, []}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import AudiusLiveWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      use Phoenix.HTML
      import Phoenix.Component
      # Core UI components and translation
      import AudiusLiveWeb.CoreComponents
      import AudiusLiveWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: AudiusLiveWeb.Endpoint,
        router: AudiusLiveWeb.Router,
        statics: AudiusLiveWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
