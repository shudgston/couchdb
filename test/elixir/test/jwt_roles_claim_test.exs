defmodule JwtRolesClaimTest do
  use CouchTestCase

  @global_server_config [
    %{
      :section => "chttpd",
      :key => "authentication_handlers",
      :value => [
                  "{chttpd_auth, jwt_authentication_handler}, ",
                  "{chttpd_auth, cookie_authentication_handler}, ",
                  "{chttpd_auth, default_authentication_handler})"
                ] |> Enum.join
    },
    %{
      :section => "jwt_keys",
      :key => "hmac:myjwttestkey",
      :value => ~w(
        NTNv7j0TuYARvmNMmWXo6fKvM4o6nv/aUi9ryX38ZH+L1bkrnD1ObOQ8JAUmHCBq7
        Iy7otZcyAagBLHVKvvYaIpmMuxmARQ97jUVG16Jkpkp1wXOPsrF9zwew6TpczyH
        kHgX5EuLg2MeBuiT/qJACs1J0apruOOJCg/gOtkjB4c=) |> Enum.join()
    }
  ]

  test "case: roles_claim_name (undefined) / roles_claim_path (undefined)" do
    server_config = @global_server_config

    run_on_modified_server(server_config, fn ->
      test_roles(["_couchdb.roles_1", "_couchdb.roles_2"])
    end)
  end

  test "case: roles_claim_name (defined) / roles_claim_path (undefined)" do
    server_config =
      [
        %{
          :section => "jwt_auth",
          :key => "roles_claim_name",
          :value => "my._couchdb.roles"
        }
      ] ++ @global_server_config

    run_on_modified_server(server_config, fn ->
      test_roles(["my._couchdb.roles_1", "my._couchdb.roles_2"])
    end)
  end

  test "case: roles_claim_name (undefined) / roles_claim_path (defined)" do
    server_config =
      [
        %{
          :section => "jwt_auth",
          :key => "roles_claim_path",
          :value => "foo.bar\\.zonk.baz\\.buu.baa.baa\\.bee.roles"
        }
      ] ++ @global_server_config

    run_on_modified_server(server_config, fn ->
      test_roles(["my_nested_role_1", "my_nested_role_2"])
    end)
  end

  test "case: roles_claim_name (defined) / roles_claim_path (defined)" do
    server_config =
      [
        %{
          :section => "jwt_auth",
          :key => "roles_claim_name",
          :value => "my._couchdb.roles"
        },
        %{
          :section => "jwt_auth",
          :key => "roles_claim_path",
          :value => "foo.bar\\.zonk.baz\\.buu.baa.baa\\.bee.roles"
        }
      ] ++ @global_server_config

    run_on_modified_server(server_config, fn ->
      test_roles(["my_nested_role_1", "my_nested_role_2"])
    end)
  end

  def test_roles(roles) do
    token = ~w(
      eyJ0eXAiOiJKV1QiLCJraWQiOiJteWp3dHRlc3RrZXkiLCJhbGciOiJIUzI1NiJ9.
      eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRyd
      WUsImlhdCI6MTY1NTI5NTgxMCwiZXhwIjoxNzU1Mjk5NDEwLCJteSI6eyJuZXN0ZW
      QiOnsiX2NvdWNoZGIucm9sZXMiOlsibXlfbmVzdGVkX2NvdWNoZGIucm9sZXNfMSI
      sIm15X25lc3RlZF9jb3VjaGRiLnJvbGVzXzEiXX19LCJfY291Y2hkYi5yb2xlcyI6
      WyJfY291Y2hkYi5yb2xlc18xIiwiX2NvdWNoZGIucm9sZXNfMiJdLCJteS5fY291Y
      2hkYi5yb2xlcyI6WyJteS5fY291Y2hkYi5yb2xlc18xIiwibXkuX2NvdWNoZGIucm
      9sZXNfMiJdLCJmb28iOnsiYmFyLnpvbmsiOnsiYmF6LmJ1dSI6eyJiYWEiOnsiYmF
      hLmJlZSI6eyJyb2xlcyI6WyJteV9uZXN0ZWRfcm9sZV8xIiwibXlfbmVzdGVkX3Jv
      bGVfMiJdfX19fX19.F6kQK-FK0z1kP01bTyw-moXfy2klWfubgF7x7Xitd-0) |> Enum.join()

    resp =
      Couch.get("/_session",
        headers: [authorization: "Bearer #{token}"]
      )

    assert resp.body["userCtx"]["name"] == "1234567890"
    assert resp.body["userCtx"]["roles"] == roles
    assert resp.body["info"]["authenticated"] == "jwt"
  end

end
