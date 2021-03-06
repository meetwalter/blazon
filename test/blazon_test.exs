defmodule Blazon.Tests do
  use ExUnit.Case, async: true

  test "options have to be atoms" do
    assert_raise Blazon.OptionsError, ~r/^Expected a list of atoms\.$/, fn ->
      Blazon.Options.fields_to_extract([], only: ~w(not_an_atom))
    end
  end

  @basics %{
    nil: nil,
    atom: :foo,
    truthy: true,
    falsey: false,
    integer: 1,
    float: 1.0,
    string: "foo",
    charlist: 'foo',
    list: [1, 2, 3],
    map: %{foo: :bar}
  }

  defmodule BasicsSerializer do
    use Blazon.Serializable

    field :nil
    field :atom
    field :truthy
    field :falsey
    field :integer
    field :float
    field :string
    field :charlist
    field :list
    field :map
  end

  test "serialization of basic types" do
    assert Blazon.map(BasicsSerializer, @basics) == @basics
  end

  defmodule DouglasAdamsSerializer do
    use Blazon.Serializable
    field :meaning_of_life
  end

  @the_answer_to_the_ultimate_question %{meaning_of_life: 42}

  test "only" do
   assert Blazon.map(DouglasAdamsSerializer, @the_answer_to_the_ultimate_question, only: []) == %{}
   assert Blazon.map(DouglasAdamsSerializer, @the_answer_to_the_ultimate_question, only: ~w(meaning_of_life)a) == @the_answer_to_the_ultimate_question
  end

  test "except" do
    assert Blazon.map(DouglasAdamsSerializer, @the_answer_to_the_ultimate_question, except: ~w(meaning_of_life)a) == %{}
    assert Blazon.map(DouglasAdamsSerializer, @the_answer_to_the_ultimate_question, except: []) == @the_answer_to_the_ultimate_question
  end

  test "only and except are mutually exclusive" do
    assert_raise Blazon.OptionsError, fn ->
      Blazon.map(DouglasAdamsSerializer, %{}, only: ~w(meaning_of_life)a, except: ~w(meaning_of_life)a)
    end
  end

  defmodule EmbeddedSerializer do
    use Blazon.Serializable
    embed :basics, BasicsSerializer
    embed :collection, [BasicsSerializer]
  end

  test "embedding" do
    assert Blazon.map(EmbeddedSerializer, %{basics: @basics, collection: [@basics]}) == %{basics: @basics, collection: [@basics]}
  end

  test "json" do
    assert Blazon.json(BasicsSerializer, @basics) == Poison.encode!(@basics)
  end

  defmodule HooksSerializer do
    use Blazon.Serializable

    hook :before do
      %{before: true}
    end

    hook :after do
      Map.merge(model, %{after: true})
    end

    field :before
    field :after
  end

  test "hooks" do
    assert Blazon.map(HooksSerializer, %{}) == %{before: true, after: true}
  end

  defmodule GeneratorsSerializer do
    use Blazon.Serializable

    field :stabby, via: fn _ -> true end
    field :short, via: &(is_map(&1))
  end

  test "generators" do
    assert Blazon.map(GeneratorsSerializer, %{}) == %{stabby: true, short: true}
  end
end
