defmodule Lightning.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lightning.Jobs.Trigger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "jobs" do
    field(:body, :string)
    field(:enabled, :boolean, default: false)
    field(:name, :string)
    has_one(:trigger, Trigger)

    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:name, :body, :enabled])
    |> cast_assoc(:trigger, with: &Trigger.changeset/2)
    |> validate_required([:name, :body, :enabled])
  end
end