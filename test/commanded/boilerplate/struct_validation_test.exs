defmodule Commanded.Boilerplate.StructValidationTest do
  alias Commanded.Boilerplate.StructValidation.ValidationError

  use Commanded.Boilerplate.TestCase, async: true

  describe "new/2" do
    test "returns {:ok, struct} for valid attributes" do
      attrs = %{name: "John Doe", age: 30}
      assert {:ok, %SampleStruct{name: "John Doe", age: 30}} = SampleStruct.new(attrs)
    end

    test "returns {:error, ValidationError.t()} for invalid attributes" do
      attrs = %{name: nil, age: -1}
      assert {:error, %ValidationError{errors: errors}} = SampleStruct.new(attrs)

      assert errors == [
               {:name, [presence: "must be present"]},
               {:age, [number: "must be a number greater than 0"]}
             ]
    end
  end

  describe "ValidationError message" do
    test "formats the error message correctly" do
      errors = [
        {:name, [presence: "must be present"]},
        {:age, [numericality: "must be greater than 0"]}
      ]

      exception = %ValidationError{errors: errors}

      expected_message = """
      Validation failed with the following error(s):
      - name:
        - must be present
      - age:
        - must be greater than 0
      """

      assert ValidationError.message(exception) == String.trim(expected_message)
    end
  end
end
