defmodule Commanded.Boilerplate.Command.ValidationMiddlewareTest do
  alias Commanded.Boilerplate.AuthSubject
  alias Commanded.Boilerplate.Command.ValidationMiddleware

  use Commanded.Boilerplate.TestCase, async: true

  describe "before_dispatch/1" do
    test "returns the pipeline unchanged when the command is valid" do
      command = %Commanded.Boilerplate.TestCommand{
        id: "1",
        some_required_key: "some value",
        auth_subject: AuthSubject.system_user()
      }

      pipeline = %Commanded.Middleware.Pipeline{command: command}
      assert ValidationMiddleware.before_dispatch(pipeline) == pipeline
    end
  end
end
