defmodule SampleStruct do
  alias Commanded.Boilerplate.StructValidation

  use StructValidation

  defstruct [:name, :age]

  validates(:name, presence: true)
  validates(:age, number: [greater_than: 0])
end
