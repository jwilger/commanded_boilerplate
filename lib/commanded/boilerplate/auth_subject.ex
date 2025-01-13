defmodule Commanded.Boilerplate.AuthSubject do
  @moduledoc """
  Represents an actor that is attempting to execute a command or a query
  """

  require Logger

  use TypedStruct
  use Commanded.Boilerplate.StructValidation

  @typedoc "The original entity that was cast to an AuthSubject"
  @type source :: String.t()

  @typedoc "The unique identifier of the entity that was cast to an AuthSubject"
  @type id :: binary()

  @typedoc "A permission that can be granted to an AuthSubject"
  @type permission :: String.t()

  @typedoc "List of permissions that have been granted to the auth subject"
  @type permissions :: list(permission() | permissions())

  @typedoc "Map representation of an AuthSubject"
  @type as_map() :: %{source: source(), id: id(), permissions: permissions()}

  @system_user %{
    source: "SYSTEM",
    id: "SYSTEM",
    permissions: ~w(superuser)
  }

  @derive Jason.Encoder
  typedstruct do
    field(:source, source(), enforce: true)
    field(:id, id(), enforce: true)
    field(:permissions, permissions(), default: [])
  end

  validates(:source, string: true)
  validates(:id, string: true)
  validates(:permissions, by: &__MODULE__.validate_permissions/1)

  defdelegate convert(data), to: __MODULE__.Conversion

  @doc """
  Returns the list of all valid permissions that have been defined.
  """
  @spec valid_permissions() :: list(String.t())
  def valid_permissions,
    do: Application.get_env(:commanded_boilerplate, :valid_permissions, []) ++ ["superuser"]

  @doc """
  Creates a new AuthSubject from the given data.

  Returns {:ok, auth_subject} if the data is valid, otherwise {:error, message}.
  """
  @spec new(source :: __MODULE__.Conversion.t()) ::
          {:ok, t()} | {:error, {:invalid_auth_subject, keyword(keyword(String.t()))}}
  def new(source) do
    case source
         |> __MODULE__.Conversion.convert()
         |> validate() do
      {:ok, auth_subject} -> {:ok, auth_subject}
      {:error, errors} -> {:error, {:invalid_auth_subject, errors}}
    end
  end

  @doc """
  Creates a new AuthSubject from the given data.

  Raises ArgumentError if the data is invalid.
  """
  @spec new!(__MODULE__.Conversion.t()) :: t()
  def new!(attributes) do
    case new(attributes) do
      {:ok, auth_subject} ->
        auth_subject
    end
  end

  @spec validate_permissions(term()) :: :ok | {:error, String.t()}
  def validate_permissions(permissions)
      when is_list(permissions) do
    if Enum.all?(permissions, &is_binary/1) do
      invalid_permissions = Enum.reject(permissions, &(&1 in valid_permissions()))

      if Enum.any?(invalid_permissions) do
        Logger.debug(fn ->
          "Invalid permissions used in AuthSubject, #{inspect(invalid_permissions)}."
        end)
      end

      :ok
    else
      {:error, "must be a list of valid permissions"}
    end
  end

  def validate_permissions(_invalid_value), do: {:error, "must be a list of valid permissions"}

  @doc """
  Check if the AuthSubject satisfies the given permission set

  A permission set can consist of one or more permissions with the following formats:

  * `"permission_a"` - the AuthSubject must have permission_a

  * `["permission_a", "permission_b"]` - the AuthSubject must have *either*
    permission_a or permission_b
    
  * `[["permission_a", "permission_b"]]` - the AuthSubject must have *both*
    permission_a and permission_b
    
  * `[["permission_a", "permission_b"], "permission_c"]` - the AuthSubject must
    have *either* permission_c *or* both permission_a and permission_b
  """
  @spec has_permission?(any(), atom() | permission() | list(permission())) :: boolean()
  def has_permission?(auth_subject, permissions) when is_list(permissions) do
    has_any_permission?(auth_subject, permissions)
  end

  def has_permission?(auth_subject, permission) do
    permission = to_string(permission)
    %{permissions: permissions} = __MODULE__.Conversion.convert(auth_subject)

    unless permission in valid_permissions() do
      Logger.warning("Invalid permission used in has_permission? check, #{permission}.")
    end

    "superuser" in permissions || permission in permissions
  end

  @doc """
  Returns the "system user" to be used by internal processes that are ot triggered by a specific user.
  """
  @spec system_user() :: t()
  def system_user, do: struct!(__MODULE__, @system_user)

  @doc """
  Returns an AuthSubject that represents an anonymous user
  """
  @spec anonymous_user() :: t()
  def anonymous_user do
    %__MODULE__{
      source: "ANONYMOUS",
      id: "ANONYMOUS",
      permissions: []
    }
  end

  @doc """
  Compares two datum to see if they convert to the same AuthSubject
  """
  @spec same?(__MODULE__.Conversion.t(), __MODULE__.Conversion.t()) :: boolean()
  def same?(term_1, term_2) do
    term_1 = __MODULE__.Conversion.convert(term_1)
    term_2 = __MODULE__.Conversion.convert(term_2)

    term_1.source == term_2.source && term_1.id == term_2.id
  end

  @doc """
  Is the given value convertible to an AuthSubject?
  """
  @spec auth_subject?(any()) :: boolean()
  def auth_subject?(%__MODULE__{}), do: true

  def auth_subject?(value) do
    __MODULE__.Conversion.convert(value)
    true
  rescue
    Protocol.UndefinedError -> false
  end

  defp has_any_permission?(auth_subject, permissions) when is_list(permissions) do
    Enum.any?(permissions, fn permission_set ->
      has_all_permissions?(auth_subject, permission_set)
    end)
  end

  defp has_all_permissions?(auth_subject, permissions) when is_list(permissions) do
    Enum.all?(permissions, &has_permission?(auth_subject, &1))
  end

  defp has_all_permissions?(auth_subject, permission),
    do: has_permission?(auth_subject, permission)

  defprotocol Conversion do
    @moduledoc """
    Protocol for converting an entity to an AuthSubject
    """

    @doc """
    Implement this function to convert an entity to an AuthSubject
    """
    @spec convert(term()) :: Commanded.Boilerplate.AuthSubject.t()
    def convert(auth_subject)
  end

  defimpl Conversion do
    @impl Commanded.Boilerplate.AuthSubject.Conversion
    def convert(auth_subject), do: auth_subject
  end
end

defimpl Commanded.Boilerplate.AuthSubject.Conversion, for: Map do
  @impl Commanded.Boilerplate.AuthSubject.Conversion
  def convert(%{source: source, id: id, permissions: permissions}) do
    id = Newt.maybe_unwrap(id)

    %Commanded.Boilerplate.AuthSubject{
      source: source,
      id: id,
      permissions: permissions
    }
  end

  def convert(_value), do: raise(Protocol.UndefinedError)
end

defimpl Commanded.Boilerplate.AuthSubject.Conversion, for: List do
  @impl Commanded.Boilerplate.AuthSubject.Conversion
  def convert(convertable) do
    convertable =
      try do
        Enum.into(convertable, %{})
      rescue
        ArgumentError -> reraise(Protocol.UndefinedError, __STACKTRACE__)
      end

    Commanded.Boilerplate.AuthSubject.Conversion.convert(convertable)
  end
end

defimpl Commanded.Boilerplate.AuthSubject.Conversion, for: Atom do
  @impl Commanded.Boilerplate.AuthSubject.Conversion
  def convert(:system), do: Commanded.Boilerplate.AuthSubject.system_user()

  def convert(value),
    do:
      raise(
        Protocol.UndefinedError.exception(
          protocol: Commanded.Boilerplate.AuthSubject.Conversion,
          value: value
        )
      )
end
