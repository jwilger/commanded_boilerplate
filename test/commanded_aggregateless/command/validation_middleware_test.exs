defmodule CommandedAggregateless.Command.ValidationMiddlewareTest do
  alias CommandedAggregateless.AuthSubject
  alias CommandedAggregateless.Command.ValidationMiddleware

  use CommandedAggregateless.TestCase, async: true

  describe "before_dispatch/1" do
    test "returns the pipeline unchanged when the command is valid" do
      command = %CommandedAggregateless.TestCommand{
        id: "1",
        some_required_key: "some value",
        auth_subject: AuthSubject.system_user()
      }

      pipeline = %Commanded.Middleware.Pipeline{command: command}
      assert ValidationMiddleware.before_dispatch(pipeline) == pipeline
    end
  end
end
