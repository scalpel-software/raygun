defmodule Raygun.Util do
  @moduledoc """
  This module contains utility functions for formatting particular pieces
  of stacktrace data into strings.
  """

  @default_environment_name Mix.env()

  @doc """
  Determines whether we will actually send an event to Raygun
  """
  def environment? do
    environment_name() in included_environments()
  end

  def msg_valid?(msg) do
    Enum.any?(get_env(:raygun, :excluded_messages, []), fn regex ->
      String.match?(msg, regex)
    end)
  end

  @doc """
  Headers are a list of Tuples. Convert them to a map
  """
  def format_headers(headers) do
    Enum.reduce(headers, %{}, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  @doc """
  Return the module name as a string (binary).
  """
  def mod_for(module) when is_atom(module), do: Atom.to_string(module)
  def mod_for(module) when is_binary(module), do: module

  @doc """
  Given stacktrace information, get the line number.
  """
  def line_from([]), do: "unknown"
  def line_from(file: _file, line: line), do: line

  @doc """
  Given stacktrace information, get the file name.
  """
  def file_from([]), do: "unknown"
  def file_from(file: file, line: _line), do: List.to_string(file)

  @doc """
  Like Application.get_env only for get_key function.
  """
  def get_key(app, key, default \\ nil) do
    case :application.get_key(app, key) do
      {:ok, val} -> val
      {^key, val} -> val
      _ -> default
    end
  end

  @doc """
  So in a release this seems to return {:key, value} instead of {:ok, value}
  for some reason. So we accept that form as well....
  """
  def get_env(app, key, default \\ nil) do
    app
    |> Application.get_env(key, default)
    |> read_from_system(default)
  end

  defp read_from_system({:system, env}, default), do: System.get_env(env) || default
  defp read_from_system(value, _default), do: value

  defp environment_name do
    get_env(:raygun, :environment_name, @default_environment_name)
  end

  defp included_environments do
    get_env(:raygun, :included_environments, [:prod])
  end
end
