# Test double boundaries: Elixir, Mox and ExUnit

## Behaviour plus Mox at external boundaries

Define a behaviour for each external system. Production config points at the real adapter, the
test config points at a Mox mock. Stub the mock in the test:

```elixir
expect(MyApp.HttpClientMock, :get, fn _url -> {:ok, %{status: 200, body: "{}"}} end)
```

If a fake transport under a module that you own works, do not mock the module.

## Expectations in other processes

- Mox expectations belong to the test process. A spawned process needs
  `Mox.allow(MyMock, self(), pid)`, or the test runs in global mode (`set_mox_global`), which
  forces `async: false`.
- `on_exit` callbacks run in a separate process that owns no expectations. In `on_exit`, call
  the concrete modules, not wrappers that read the mock from config.

## Park a fake leaf collaborator

```elixir
defmodule ParkedModel do
  # Notifies the test, then blocks until released or a timeout expires.
  def call(%{test_pid: pid}, _messages, _tools) do
    send(pid, {:llm_called, self()})

    receive do
      :release -> {:ok, []}
    after
      5_000 -> {:error, :parked_timeout}
    end
  end
end

# in the test
assert_receive {:llm_called, task_pid}   # the run is provably in flight
ref = Process.monitor(task_pid)
cancel(run)
assert_receive {:DOWN, ^ref, :process, ^task_pid, _reason}
```

## Fake the transport under it

If the code builds a client from user configuration, park at the HTTP layer:

```elixir
Req.default_options(plug: fn conn -> park(conn) end)
on_exit(fn -> Req.default_options([]) end)
```

## Take a supervisor child down for real

```elixir
use ExUnit.Case, async: false   # every async module runs before any sync one

setup do
  :ok = Supervisor.terminate_child(MyApp.Supervisor, Some.Supervisor)
  on_exit(fn -> {:ok, _} = Supervisor.restart_child(MyApp.Supervisor, Some.Supervisor) end)
  refute Some.Registry.available?()   # assert the precondition
  :ok
end
```

## Database sandbox

A process that the test spawns needs shared sandbox mode or `Ecto.Adapters.SQL.Sandbox.allow/3`.
Read the error first: a sandbox ownership error is not a behaviour failure.
