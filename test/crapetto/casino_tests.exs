defmodule Crapetto.CasinoTest do
  use ExUnit.Case, async: true

  alias Crapetto.Casino

  setup do
    casino = start_supervised!(Crapetto.Casino)
    %{casino: casino}
  end

  test "basic Casino tests", %{casino: casino} do
    assert Casino.lookup(casino, "id_game") == :error

    {:ok, id_game} = Casino.create(casino, "some_data")
    assert {:ok, "some_data"} = Casino.lookup(casino, id_game)
  end
end
