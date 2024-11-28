import Config

config :mix_test_interactive,
  clear: true

if Mix.env() == :test do
  config :commanded_boilerplate, :valid_permissions, ["create_customer"]
end
