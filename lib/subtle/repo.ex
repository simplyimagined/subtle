defmodule Subtle.Repo do
  use Ecto.Repo,
    otp_app: :subtle,
    adapter: Ecto.Adapters.Postgres
end
