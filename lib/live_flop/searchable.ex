defmodule LiveFlop.Query do
  import Ecto.Query

  def named_binding(schema, binds) do
    query = from(s in schema, as: :base)

    binds
    |> Enum.reduce(query, &reduce_binding(&1, &2, :base))
    |> preload(^binds)
  end

  defp reduce_binding(bind, query, parent) when is_atom(bind) do
    join(query, :left, [{^parent, i}], b in assoc(i, ^bind), as: ^bind)
  end

  defp reduce_binding({bind, binds}, query, parent) when is_atom(bind) do
    query = reduce_binding(bind, query, parent)
    Enum.reduce(binds, query, &reduce_binding(&1, &2, bind))
  end
end
