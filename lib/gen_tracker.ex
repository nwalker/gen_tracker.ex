defmodule GenTracker do
  defmodule Spec do

    def child(name, mod, args) do
      worker(name, mod, args, [function: :start_child])
    end

    def worker(name, mod, args, options \\ []) do
      alias Supervisor.Spec, as: S
      defaults = [
        type: :worker,
        shutdown: 200,
        restart: :temporary
      ]
      options = Keyword.merge defaults, options
      S.worker(mod, args, Keyword.merge(options, [id: name]))
    end
  end

  defmacro __using__(options) do
    caller = __CALLER__.module
    zone = Keyword.get options, :zone, caller

    quote location: :keep do
      @__zone unquote zone
      @__caller unquote caller

      def start_link() do
        :gen_tracker.start_link(@__zone)
      end

      def childspec(name, args) do
        Spec.child name, @__caller, [name, args]
      end

      def start_child(name, args) do
        d = %{name: name, args: args}
        throw "default start_child called w. #{ inspect d }"
      end

      def find(name), do: :gen_tracker.find @__zone, name

      def find_or_open(childspec), do: do_find_or_open childspec
      def find_or_open(name, args), do: do_find_or_open name, args

      defp do_find_or_open(name, args), do: do_find_or_open childspec name, args
      defp do_find_or_open(childspec), do: :gen_tracker.find_or_open @__zone, childspec

      def zone(), do: @__zone

      def info(name), do: :gen_tracker.info @__zone, name
      def info(name, keys), do: :gen_tracker.info @__zone, name, keys

      def list(), do: :gen_tracker.list @__zone
      def list(keys), do: :gen_tracker.list @__zone, keys

      def which_children(), do: :gen_tracker.which_children @__zone
      def add_existing_child(name, pid, type, mods \\ []) do
        :gen_tracker.add_existing_child name, pid, type, mods
      end

      def get_attr(name, key, default \\ nil, timeout \\ nil) do
        if is_integer(timeout) do
          :gen_tracker.getattr(@__zone, name, key, timeout)
        else
          :gen_tracker.getattr(@__zone, name, key)
        end |> norm_attr(default)
      end

      def set_attr(name, attrs), do: :gen_tracker.setattr @__zone, name, attrs
      def set_attr(name, key, value), do: :gen_tracker.setattr @__zone, name, key, value

      def wait(), do: :gen_tracker.wait @__zone

      defoverridable [childspec: 2, start_child: 2, find_or_open: 2]

      defp norm_attr({:ok, val}, _), do: val
      defp norm_attr(:undefined, default), do: default
      defp norm_attr(els, _), do: els
    end
  end
end
