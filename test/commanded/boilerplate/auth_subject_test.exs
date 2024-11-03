defmodule Commanded.Boilerplate.AuthSubjectTest do
  alias Commanded.Boilerplate.AuthSubject

  use Commanded.Boilerplate.TestCase

  describe "valid_permissions/0" do
    test "returns the list of valid permissions" do
      assert AuthSubject.valid_permissions() == ~w(create_customer superuser)
    end
  end

  describe "validate_permissions/1" do
    property "validates a list of valid permissions" do
      check all(permissions <- list_of(member_of(AuthSubject.valid_permissions()))) do
        assert AuthSubject.validate_permissions(permissions) == :ok
      end
    end

    property "returns an error for invalid permissions" do
      check all(permissions <- list_of(string(:alphanumeric, min_length: 1))) do
        if Enum.any?(permissions, &(&1 not in AuthSubject.valid_permissions())) do
          assert AuthSubject.validate_permissions(permissions) ==
                   {:error, "must be a list of valid permissions"}
        end
      end
    end
  end

  describe "struct validation" do
    property "validates the source field" do
      check all(
              source <- term(),
              id <- string(:alphanumeric, min_length: 1),
              permissions <- list_of(member_of(AuthSubject.valid_permissions()))
            ) do
        if not is_binary(source) do
          assert {:error, _} =
                   AuthSubject.new(%{source: source, id: id, permissions: permissions})
        end
      end
    end

    property "validates the id field" do
      check all(
              source <- string(:alphanumeric, min_length: 1),
              id <- term(),
              permissions <- list_of(member_of(AuthSubject.valid_permissions()))
            ) do
        if not is_binary(id) do
          assert {:error, _} =
                   AuthSubject.new(%{source: source, id: id, permissions: permissions})
        end
      end
    end

    property "validates the permissions field" do
      check all(
              source <- string(:alphanumeric, min_length: 1),
              id <- string(:alphanumeric, min_length: 1),
              permissions <- list_of(string(:alphanumeric, min_length: 1))
            ) do
        if Enum.any?(permissions, &(&1 not in AuthSubject.valid_permissions())) do
          assert {:error, _} =
                   AuthSubject.new(%{source: source, id: id, permissions: permissions})
        end
      end
    end

    property "creates a valid AuthSubject struct" do
      check all(
              source <- string(:alphanumeric, min_length: 1),
              id <- string(:alphanumeric, min_length: 1),
              permissions <- list_of(member_of(AuthSubject.valid_permissions()))
            ) do
        assert {:ok, _} = AuthSubject.new(%{source: source, id: id, permissions: permissions})
      end
    end
  end

  describe "new/1 and new!/1" do
    test "creates a valid AuthSubject struct" do
      data = %{source: "test", id: "123", permissions: ["create_customer"]}
      assert {:ok, _} = AuthSubject.new(data)
      assert %AuthSubject{} = AuthSubject.new!(data)
    end

    test "returns an error for invalid data" do
      data = %{source: 123, id: "123", permissions: ["create_customer"]}
      assert {:error, _} = AuthSubject.new(data)
    end
  end

  describe "has_permission?/2" do
    test "checks if the AuthSubject has a specific permission" do
      auth_subject = %AuthSubject{source: "test", id: "123", permissions: ["create_customer"]}
      assert AuthSubject.has_permission?(auth_subject, "create_customer")
      refute AuthSubject.has_permission?(auth_subject, "superuser")
    end

    test "checks if the AuthSubject has any of the given permissions" do
      auth_subject = %AuthSubject{source: "test", id: "123", permissions: ["create_customer"]}
      assert AuthSubject.has_permission?(auth_subject, ["create_customer"])
      refute AuthSubject.has_permission?(auth_subject, ["superuser"])
    end
  end

  describe "system_user/0 and anonymous_user/0" do
    test "returns the system user" do
      assert %AuthSubject{source: "SYSTEM", id: "SYSTEM", permissions: ["superuser"]} =
               AuthSubject.system_user()
    end

    test "returns the anonymous user" do
      assert %AuthSubject{source: "ANONYMOUS", id: "ANONYMOUS", permissions: []} =
               AuthSubject.anonymous_user()
    end
  end

  describe "same?/2 and auth_subject?/1" do
    test "compares two AuthSubjects" do
      auth_subject_1 = %AuthSubject{source: "test", id: "123", permissions: ["create_customer"]}
      auth_subject_2 = %AuthSubject{source: "test", id: "123", permissions: ["create_customer"]}
      assert AuthSubject.same?(auth_subject_1, auth_subject_2)
    end

    test "validates if a value is an AuthSubject" do
      auth_subject = %AuthSubject{source: "test", id: "123", permissions: ["create_customer"]}
      assert AuthSubject.auth_subject?(auth_subject)
      refute AuthSubject.auth_subject?(%{})
    end
  end
end
