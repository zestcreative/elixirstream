defmodule Utility.GenDiff.Generator do
  use Ecto.Schema
  import Ecto.Changeset
  alias Utility.GenDiff.Data
  @derive {Jason.Encoder, except: [:flags]}

  @primary_key false
  embedded_schema do
    # Populated by user
    field :project, :string
    field :command, :string

    field :from_version
    field :to_version

    field :from_flags, {:array, :string}
    field :to_flags, {:array, :string}

    # Populated by Data
    field :id, :string
    field :url, :string
    field :docs_url, :string
    field :default_flags, {:array, :string}
    field :flags, {:array, :string}
    field :help, :string
    field :since, :string
    field :source, :string
  end

  @required ~w[command project from_version to_version]a
  @optional ~w[from_flags to_flags since]a
  def changeset(struct_or_changeset \\ %__MODULE__{}, attrs) do
    struct_or_changeset
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_project()
    |> put_defaults_for_project()
    |> validate_command()
    |> put_defaults_for_command()
    |> validate_flags()
    |> validate_not_same()
    |> validate_flags_for_command()
    |> put_id()
  end

  def apply(%{} = params) do
    %__MODULE__{}
    |> changeset(params)
    |> apply_action(:insert)
  end

  def build_id(%Ecto.Changeset{} = changeset) do
    command = get_field(changeset, :command)
    from = get_field(changeset, :from_version)
    from_flags = get_field(changeset, :from_flags)
    to = get_field(changeset, :to_version)
    to_flags = get_field(changeset, :to_flags)
    build_id(command, from, to, from_flags, to_flags)
  end

  def build_id(command, from, main, from_flags, to_flags) when main in ["master", "main"] do
    build_id(command, from, "9999.999.99", from_flags, to_flags) <> "|" <> main
  end

  def build_id(command, from, to, from_flags, to_flags) do
    :md5
    |> :crypto.hash(Enum.join([command, from, to, from_flags, to_flags]))
    |> Base.encode16()
  end

  def validate_project(changeset) do
    validate_inclusion(changeset, :project, Data.projects())
  end

  def validate_command(changeset) do
    valid_commands = changeset |> get_field(:project) |> Data.commands_for_project()
    validate_inclusion(changeset, :command, valid_commands)
  end

  def validate_flags_for_command(changeset) do
    validate_flags_for_command(
      changeset,
      get_field(changeset, :project),
      get_field(changeset, :command)
    )
  end

  def validate_flags_for_command(changeset, "phx_new", "phx.gen.auth") do
    from_version = get_field(changeset, :from_version)
    from_flags = get_field(changeset, :from_flags) || []
    to_version = get_field(changeset, :to_version)
    to_flags = get_field(changeset, :to_flags) || []

    Enum.reduce(
      [{:from_version, from_version, from_flags}, {:to_version, to_version, to_flags}],
      changeset,
      fn
        {_field, empty, _flags}, acc_changeset when empty in [nil, false] ->
          acc_changeset

        {field, "main", flags}, acc_changeset ->
          if "--live" not in flags and "--no-live" not in flags do
            add_error(acc_changeset, field, "must specify either --live or --no-live flag")
          else
            acc_changeset
          end

        {field, version, flags}, acc_changeset ->
          if Version.compare(version, "1.6.16") == :gt do
            ensure_live_flag(acc_changeset, field, flags)
          else
            acc_changeset
          end
      end
    )
  end

  def validate_flags_for_command(changeset, _, _), do: changeset

  defp ensure_live_flag(changeset, field, flags) do
    if "--live" not in flags and "--no-live" not in flags do
      add_error(changeset, field, "must specify either --live or --no-live flag")
    else
      changeset
    end
  end

  def validate_not_same(%{valid?: false} = changeset), do: changeset

  def validate_not_same(changeset) do
    from_version = get_field(changeset, :from_version)
    from_flags = (changeset |> get_field(:from_flags) || []) |> Enum.sort()
    to_version = get_field(changeset, :to_version)
    to_flags = (changeset |> get_field(:to_flags) || []) |> Enum.sort()

    if {from_version, from_flags} == {to_version, to_flags} do
      add_error(changeset, :to_version, "cannot be same as from_version with same flags")
    else
      changeset
    end
  end

  def put_id(%{valid?: true} = changeset), do: changeset |> put_change(:id, build_id(changeset))
  def put_id(changeset), do: changeset

  def put_defaults_for_command(changeset) do
    if command = get_field(changeset, :command) do
      project = get_field(changeset, :project)

      changeset
      |> put_change(:default_flags, Data.default_flags_for_command(project, command))
      |> put_change(:flags, Data.flags_for_command(project, command))
      |> put_change(:help, Data.help_for_command(project, command))
      |> put_change(:docs_url, Data.docs_url_for_command(project, command))
    else
      changeset
      |> put_change(:default_flags, [])
      |> put_change(:flags, [])
    end
  end

  def put_defaults_for_project(changeset) do
    if project = get_field(changeset, :project) do
      changeset
      |> put_change(:url, Data.url_for_project(project))
      |> put_change(:source, Data.source_for_project(project))
    else
      put_change(changeset, :url, nil)
    end
  end

  def validate_flags(changeset) do
    valid_flags = get_field(changeset, :flags)

    changeset
    |> validate_subset(:to_flags, valid_flags)
    |> validate_subset(:from_flags, valid_flags)
  end
end
