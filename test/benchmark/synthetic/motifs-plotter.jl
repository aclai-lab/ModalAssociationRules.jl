using ModalAssociationRules
using Serialization

using Plots
using PGFPlotsX
pgfplotsx() # to export plots in .tex

# folder in which plots are saved
PLOT_FOLDER_PATH = joinpath(@__DIR__, "test", "benchmark", "synthetic", "plots")

# folder in which the extracted motifs are serialized
SERIALIZED_FILES_PATH = joinpath(@__DIR__, "test", "experiments", "NATOPS", "serialized")

# logic for deserialization
function load_motifs(filepath, save_filename_prefix)
    ids = [id for id in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-ids"))];
    motifs = [m for m in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-motifs"))];
    featurenames = [f for f in deserialize(
        joinpath(filepath, "$(save_filename_prefix)-featurenames"))];

    return ids, motifs, featurenames
end


ids, motifs, featurenames = load_motifs(serialized_path, "NATOPS-IHCC")

for (i, motif) in enumerate(motifs)
    # we plot the normalized version of the motif, since it is always used with
    # z-euclidean distance
    motif = motif |> first
    motif_min = minimum(motif)
    motif_max = maximum(motif)
    motif_norm = (motif .- motif_min) ./ (motif_max - motif_min)

    p = plot(
        motif_norm,
        size=(300, 100),
        # title=featurenames[i],
        color=:blue,
        legend=false,
        framestyle=:none,
        grid=:false,
        linewidth=2
    )

    # Save plot to file
    filename = "motif_$(featurenames[i])_V$(ids[i])"

    save_path_tex = joinpath(PLOT_FOLDER_PATH, "$filename.tex")
    savefig(p, save_path_tex)

    # save_path_png = joinpath(PLOT_FOLDER_PATH, "$filename.png")
    # savefig(p, save_path_png)
end
