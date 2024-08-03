defmodule LiveFlop.Query do
  import Ecto.Query

  def named_binding(schema, binds, opts \\ []) do
    query = from(s in schema, as: :base)

    preloads = Enum.reduce(binds, [], &reduce_binding_preload/2)

    binds
    |> Enum.reduce(query, &reduce_binding_join(&1, &2, :base))
    |> then(
      &Enum.reduce(opts, &1, fn
        {:order_by, {bind, field}}, q -> order_by(q, [{^bind, x}], field(x, ^field))
        _, q -> q
      end)
    )
    |> preload(^preloads)
    |> dbg
  end

  defp reduce_binding_join(bind, query, parent) when is_atom(bind) do
    join(query, :left, [{^parent, i}], b in assoc(i, ^bind), as: ^bind)
  end

  defp reduce_binding_join({bind, binds}, query, parent) when is_atom(bind) do
    query = reduce_binding_join(bind, query, parent)
    Enum.reduce(binds, query, &reduce_binding_join(&1, &2, bind))
  end

  defp reduce_binding_preload(bind, acc) when is_atom(bind) do
    acc ++ [{bind, dynamic([{^bind, b}], b)}]
  end

  defp reduce_binding_preload({bind, binds}, acc) when is_atom(bind) do
    sub_binds = Enum.reduce(binds, [], &reduce_binding_preload/2)
    acc ++ [{bind, {dynamic([{^bind, b}], b), sub_binds}}]
  end
end
