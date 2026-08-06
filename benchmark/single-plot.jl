# Usage example
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname fpgrowth_threads_1.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname fpgrowth_threads_2.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname fpgrowth_threads_4.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname fpgrowth_threads_8.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname fpgrowth_threads_16.json
#
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname eclat_threads_1.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname eclat_threads_2.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname eclat_threads_4.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname eclat_threads_8.json
# julia +1.11 --project=. benchmark/single-plot.jl --settingsname eclat_threads_16.json

using ArgParse

using ModalAssociationRules
using JSON
using Plots
using PGFPlotsX
pgfplotsx()

RESULTS_REPOSITORY = joinpath(@__DIR__, "results")

function parse_commandline()
    settings = ArgParseSettings(; description="Generate a transformation base")

    ArgParse.@add_arg_table settings begin
        "--settingsname"
        help = "Name of the file containing the results."
        arg_type = String
    end

    return parse_args(settings)
end

configuration = parse_commandline()

# --- Hardcode the single results file to plot here ---------------------------
FILENAME = configuration["settingsname"]
LABEL = "$(FILENAME)"
COLOR = :red
# -------------------------------------------------------------------------------

_data = JSON.parsefile(joinpath(RESULTS_REPOSITORY, FILENAME))

xaxis = reverse(_data["lsupports"]) # e.g. 0.0 : 0.05 : 1.00

# Some runs at very low support don't get a recorded time/memory value
# (they were skipped because they'd take/allocate an enormous amount).
# If meantimes/memories are shorter than lsupports, pad the low-support
# end (start of the reversed axis) with NaN so the arrays line up for plotting.
function pad_to_axis!(mls::Vector, values::Vector)
    mls = copy(mls)
    values = copy(values)
    reverse!(mls)
    reverse!(values)
    while length(values) < length(mls)
        push!(values, NaN)
    end
    reverse!(mls)
    reverse!(values)
    return mls, values
end

_mls_times, _meantimes = pad_to_axis!(_data["lsupports"], _data["meantimes"])
_mls_mem, _memories = pad_to_axis!(_data["lsupports"], _data["memories"])

# --- Time plot -----------------------------------------------------------------
p_times = plot(;
    title="Time execution of $(LABEL)",
    xlabel="Minimum lsupp threshold",
    ylabel="CPU time [s]",
    legend=:topleft,
    size=(600, 300),
);
plot!(p_times, reverse(_mls_times), _meantimes ./ 1e9; label=LABEL, lw=1, color=COLOR)

savefig(p_times, joinpath(RESULTS_REPOSITORY, "$(splitext(FILENAME)[1])_times.tex"))
savefig(p_times, joinpath(RESULTS_REPOSITORY, "$(splitext(FILENAME)[1])_times.png"))

# --- Memory plot -----------------------------------------------------------------
p_memory = plot(;
    title="Allocations of $(LABEL)",
    xlabel="Minimum lsupp threshold",
    ylabel="Memory [MBs]",
    legend=:topleft,
    size=(600, 300),
);
plot!(p_memory, reverse(_mls_mem), _memories ./ 10e6; label=LABEL, lw=1, color=COLOR)

savefig(p_memory, joinpath(RESULTS_REPOSITORY, "$(splitext(FILENAME)[1])_memory.tex"))
savefig(p_memory, joinpath(RESULTS_REPOSITORY, "$(splitext(FILENAME)[1])_memory.png"))
