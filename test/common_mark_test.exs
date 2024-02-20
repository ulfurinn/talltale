defmodule Tailmark.CommonMarkTest do
  use ExUnit.Case
  import Tailmark.Parser
  import Tailmark.Writer

  setup_all %{} do
    {:ok, pid} = Agent.start_link(fn -> %{} end)
    on_exit(fn -> print_report(pid) end)
    %{collector: pid}
  end

  setup %{collector: pid, section: section} do
    register_example(pid, section)
    :ok
  end

  ["test/spec.json", "test/obsidian.json"]
  |> Enum.map(fn file ->
    file
    |> File.read!()
    |> Jason.decode!()
  end)
  |> List.flatten()
  |> Enum.group_by(&Map.get(&1, "section"))
  |> Enum.each(fn {section, examples} ->
    describe section do
      examples
      |> Enum.each(fn example ->
        @tag :commonmark
        @tag section: example["section"]
        @tag example: example["example"]
        @tag data: example
        # @tag skip: true
        test example["example"], %{
          data: data,
          collector: pid,
          section: section,
          example: example
        } do
          trace? = System.get_env("TRACE") == "1"

          if trace? do
            :dbg.start()
            :dbg.tracer()
            :dbg.tpl(Tailmark.Parser, [])
            :dbg.p(:all, :c)
            on_exit(&:dbg.stop/0)
          end

          output =
            [data["markdown"] |> document(frontmatter: false) |> to_html()]
            |> IO.iodata_to_binary()

          if System.get_env("ASSERT", "1") != "0" ||
               String.starts_with?(to_string(example), "ext") do
            assert data["html"] == output
          end

          register_success(pid, section)
        end
      end)
    end
  end)

  defp register_example(pid, section) do
    Agent.update(pid, fn state ->
      state
      |> Map.put_new(section, %{total: 0, passed: 0})
      |> Map.update!(section, fn counter -> %{counter | total: counter.total + 1} end)
    end)
  end

  defp register_success(pid, section) do
    Agent.update(pid, fn state ->
      Map.update!(state, section, fn counter -> %{counter | passed: counter.passed + 1} end)
    end)
  end

  defp print_report(pid) do
    state = Agent.get(pid, & &1)

    f = File.open!("commonmark_report.txt", [:write])

    IO.puts(f, "| Section | Total | Passed |")
    IO.puts(f, "| ------- | ----- | ------ |")

    state
    |> Enum.each(fn {section, counter} ->
      percentage = Float.round(100.0 * counter.passed / counter.total, 1)

      percentage_report =
        if percentage > 90 do
          "**#{percentage} %**"
        else
          "#{percentage} %"
        end

      IO.puts(
        f,
        "| #{section} | #{counter.total} | #{counter.passed} (#{percentage_report}) |"
      )
    end)

    sum =
      Enum.reduce(state, %{total: 0, passed: 0}, fn {_, counter}, acc ->
        %{total: acc.total + counter.total, passed: acc.passed + counter.passed}
      end)

    percentage = Float.round(100.0 * sum.passed / sum.total, 1)

    percentage_report =
      if percentage > 90 do
        "**#{percentage} %**"
      else
        "#{percentage} %"
      end

    IO.puts(
      f,
      "| **TOTAL** | #{sum.total} | #{sum.passed} (#{percentage_report}) |"
    )

    File.close(f)
  end
end
