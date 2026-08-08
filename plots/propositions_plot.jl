# julia +1.11 --project=.  plots/propositions_plot.jl

using ModalAssociationRules
using JSON

RESULTS_REPOSITORY = joinpath(@__DIR__, "..", "benchmark", "results")

OUTPUT_REPOSITORY = joinpath(@__DIR__)

# CHANGE THIS
name = "eclat"

output_name = "$(name)_npropositions.tex"
algo_name = "Modal$(name)"
_x_label = "Number of propositions"
_y_label = "Time [s]"

_data = [
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_1.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_2.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_3.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_4.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_5.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_6.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_7.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_8.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_9.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_10.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_11.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_12.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_13.json")),
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16_npropositions_14.json")),
]

latexfile = nothing
latexfile = """
\\documentclass{article}

\\usepackage{xcolor}

\\usepackage{pgfplots}
\\pgfplotsset{compat=1.18}


\\definecolor{blueIce}{HTML}{7986CB}       
\\definecolor{bluePowder}{HTML}{0066FF}    
\\definecolor{blueSky}{HTML}{00BFFF}       
\\definecolor{blueVivid}{HTML}{00B0FF}     
\\definecolor{blueCornflower}{HTML}{00F0FF}
\\definecolor{bluePeriwinkle}{HTML}{4D8FAC}

\\begin{document}

\\begin{tikzpicture}
\\centering
\\begin{axis}[
title={Scalability of $(algo_name)},
xlabel={$(_x_label)},
ylabel={{$(_y_label)}},
legend pos=north west,
% xtick distance=0.1,
legend pos=north west,
ymajorgrids=true,
grid style=dashed,
% width=15cm
]

% Apriori 1 thread 
\\addplot[
color=blueIce,
mark=square*,
% mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
y filter/.expression={y*1e-9}
] coordinates {
(100, $(_data[1]["meantimes"][1]))
(200,  $(_data[2]["meantimes"][1]))
(300, $(_data[3]["meantimes"][1]))
(400,  $(_data[4]["meantimes"][1]))
(500,  $(_data[5]["meantimes"][1]))
(600,  $(_data[6]["meantimes"][1]))
(700,  $(_data[7]["meantimes"][1]))
(800,  $(_data[8]["meantimes"][1]))
(900,  $(_data[9]["meantimes"][1]))
(1000,  $(_data[10]["meantimes"][1]))
(1100,  $(_data[11]["meantimes"][1]))
(1200,  $(_data[12]["meantimes"][1]))
(1300,  $(_data[13]["meantimes"][1]))
};

\\end{axis}
\\end{tikzpicture}

\\end{document}
"""

open(joinpath(OUTPUT_REPOSITORY, output_name), "w") do io
    println(io, latexfile)
end
