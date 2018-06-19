defmodule Identicon.Image do
  @enforce_keys [:hex_values]
  defstruct [
    :hex_values,
    color: nil,
    colored_indices: nil,
    binary: nil
  ]
end
