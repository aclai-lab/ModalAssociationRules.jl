# julia +1.11 --project=.  plots/threads_plot.jl

using ModalAssociationRules
using JSON

RESULTS_REPOSITORY = joinpath(@__DIR__, "..", "benchmark", "results")

OUTPUT_REPOSITORY = joinpath(@__DIR__)

# CHANGE THIS
name = "apriori" 

output_name = "$(name)_threads.tex"
algo_name = "Modal$(name)"
_x_label = "Minimum lsupp threshold"
_y_label = "Time [s]"

_data = [
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_1.json"))
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_2.json"))
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_4.json"))
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_8.json"))
    JSON.parsefile(joinpath(RESULTS_REPOSITORY, "$(name)_threads_16.json"))
]

# println("times: $(_data[1]["meantimes"][20]) - $(_data[5]["meantimes"][20])")

latexfile = nothing
if name == "apriori"
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
			xmin=0.05, xmax=1.0,
            legend pos=north west,
			x dir=reverse,
			xtick distance=0.1,
			legend pos=north west,
			ymajorgrids=true,
			grid style=dashed,
			% width=15cm
		]

		% Apriori 1 thread 
		\\addplot[
			color=blueIce,
			mark=square*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {
        (0.05, nan)
        (0.10,  nan)
        (0.15, nan)
            (0.2,  $(_data[1]["meantimes"][4-3]))
            (0.25,  $(_data[1]["meantimes"][5-3]))
            (0.3,  $(_data[1]["meantimes"][6-3]))
            (0.35,  $(_data[1]["meantimes"][7-3]))
            (0.4,  $(_data[1]["meantimes"][8-3]))
            (0.45,  $(_data[1]["meantimes"][9-3]))
            (0.5,  $(_data[1]["meantimes"][10-3]))
            (0.55,  $(_data[1]["meantimes"][11-3]))
            (0.6,  $(_data[1]["meantimes"][12-3]))
            (0.65,  $(_data[1]["meantimes"][13-3]))
            (0.7,  $(_data[1]["meantimes"][14-3]))
            (0.75,  $(_data[1]["meantimes"][15-3]))
            (0.8,  $(_data[1]["meantimes"][16-3]))
            (0.85,  $(_data[1]["meantimes"][17-3]))
            (0.9,  $(_data[1]["meantimes"][18-3]))
            (0.95,  $(_data[1]["meantimes"][19-3]))
            (1.0,  $(_data[1]["meantimes"][20-3]))
			};

		% Apriori 2 threads
		\\addplot[
			color=bluePowder,
			mark=*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {
        (0.05, nan)
        (0.10,  nan)
        (0.15, nan)
            (0.2,  $(_data[2]["meantimes"][4-3]))
            (0.25,  $(_data[2]["meantimes"][5-3]))
            (0.3,  $(_data[2]["meantimes"][6-3]))
            (0.35,  $(_data[2]["meantimes"][7-3]))
            (0.4,  $(_data[2]["meantimes"][8-3]))
            (0.45,  $(_data[2]["meantimes"][9-3]))
            (0.5,  $(_data[2]["meantimes"][10-3]))
            (0.55,  $(_data[2]["meantimes"][11-3]))
            (0.6,  $(_data[2]["meantimes"][12-3]))
            (0.65,  $(_data[2]["meantimes"][13-3]))
            (0.7,  $(_data[2]["meantimes"][14-3]))
            (0.75,  $(_data[2]["meantimes"][15-3]))
            (0.8,  $(_data[2]["meantimes"][16-3]))
            (0.85,  $(_data[2]["meantimes"][17-3]))
            (0.9,  $(_data[2]["meantimes"][18-3]))
            (0.95,  $(_data[2]["meantimes"][19-3]))
            (1.0,  $(_data[2]["meantimes"][20-3]))

			};

		% Apriori 4 threads
		\\addplot[
			color=blueSky,
			mark=triangle*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

        (0.05, nan)
        (0.10,  nan)
        (0.15, nan)
            (0.2,  $(_data[3]["meantimes"][4-3]))
            (0.25,  $(_data[3]["meantimes"][5-3]))
            (0.3,  $(_data[3]["meantimes"][6-3]))
            (0.35,  $(_data[3]["meantimes"][7-3]))
            (0.4,  $(_data[3]["meantimes"][8-3]))
            (0.45,  $(_data[3]["meantimes"][9-3]))
            (0.5,  $(_data[3]["meantimes"][10-3]))
            (0.55,  $(_data[3]["meantimes"][11-3]))
            (0.6,  $(_data[3]["meantimes"][12-3]))
            (0.65,  $(_data[3]["meantimes"][13-3]))
            (0.7,  $(_data[3]["meantimes"][14-3]))
            (0.75,  $(_data[3]["meantimes"][15-3]))
            (0.8,  $(_data[3]["meantimes"][16-3]))
            (0.85,  $(_data[3]["meantimes"][17-3]))
            (0.9,  $(_data[3]["meantimes"][18-3]))
            (0.95,  $(_data[3]["meantimes"][19-3]))
            (1.0,  $(_data[3]["meantimes"][20-3]))
			};

		% Apriori 8 threads
		\\addplot[
			color=blueVivid,
			mark=diamond*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

        (0.05, nan)
        (0.10,  nan)
        (0.15, nan)
            (0.2,  $(_data[4]["meantimes"][4-3]))
            (0.25,  $(_data[4]["meantimes"][5-3]))
            (0.3,  $(_data[4]["meantimes"][6-3]))
            (0.35,  $(_data[4]["meantimes"][7-3]))
            (0.4,  $(_data[4]["meantimes"][8-3]))
            (0.45,  $(_data[4]["meantimes"][9-3]))
            (0.5,  $(_data[4]["meantimes"][10-3]))
            (0.55,  $(_data[4]["meantimes"][11-3]))
            (0.6,  $(_data[4]["meantimes"][12-3]))
            (0.65,  $(_data[4]["meantimes"][13-3]))
            (0.7,  $(_data[4]["meantimes"][14-3]))
            (0.75,  $(_data[4]["meantimes"][15-3]))
            (0.8,  $(_data[4]["meantimes"][16-3]))
            (0.85,  $(_data[4]["meantimes"][17-3]))
            (0.9,  $(_data[4]["meantimes"][18-3]))
            (0.95,  $(_data[4]["meantimes"][19-3]))
            (1.0,  $(_data[4]["meantimes"][20-3]))
			};


		% Apriori 16 threads
		\\addplot[
			color=blueCornflower,
			mark=pentagon*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

        (0.05, nan)
        (0.10,  nan)
        (0.15, nan)
            (0.2,  $(_data[5]["meantimes"][4-3]))
            (0.25,  $(_data[5]["meantimes"][5-3]))
            (0.3,  $(_data[5]["meantimes"][6-3]))
            (0.35,  $(_data[5]["meantimes"][7-3]))
            (0.4,  $(_data[5]["meantimes"][8-3]))
            (0.45,  $(_data[5]["meantimes"][9-3]))
            (0.5,  $(_data[5]["meantimes"][10-3]))
            (0.55,  $(_data[5]["meantimes"][11-3]))
            (0.6,  $(_data[5]["meantimes"][12-3]))
            (0.65,  $(_data[5]["meantimes"][13-3]))
            (0.7,  $(_data[5]["meantimes"][14-3]))
            (0.75,  $(_data[5]["meantimes"][15-3]))
            (0.8,  $(_data[5]["meantimes"][16-3]))
            (0.85,  $(_data[5]["meantimes"][17-3]))
            (0.9,  $(_data[5]["meantimes"][18-3]))
            (0.95,  $(_data[5]["meantimes"][19-3]))
            (1.0,  $(_data[5]["meantimes"][20-3]))


			};

	\\end{axis}
\\end{tikzpicture}

\\end{document}
"""
else
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
			xmin=0.05, xmax=1.0,
            legend pos=north west,
			x dir=reverse,
			xtick distance=0.1,
			legend pos=north west,
			ymajorgrids=true,
			grid style=dashed,
			% width=15cm
		]

		% Apriori 1 thread 
		\\addplot[
			color=blueIce,
			mark=square*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {
            (0.05, $(_data[1]["meantimes"][1]))
            (0.10,  $(_data[1]["meantimes"][2]))
            (0.15, $(_data[1]["meantimes"][3]))
            (0.2,  $(_data[1]["meantimes"][4]))
            (0.25,  $(_data[1]["meantimes"][5]))
            (0.3,  $(_data[1]["meantimes"][6]))
            (0.35,  $(_data[1]["meantimes"][7]))
            (0.4,  $(_data[1]["meantimes"][8]))
            (0.45,  $(_data[1]["meantimes"][9]))
            (0.5,  $(_data[1]["meantimes"][10]))
            (0.55,  $(_data[1]["meantimes"][11]))
            (0.6,  $(_data[1]["meantimes"][12]))
            (0.65,  $(_data[1]["meantimes"][13]))
            (0.7,  $(_data[1]["meantimes"][14]))
            (0.75,  $(_data[1]["meantimes"][15]))
            (0.8,  $(_data[1]["meantimes"][16]))
            (0.85,  $(_data[1]["meantimes"][17]))
            (0.9,  $(_data[1]["meantimes"][18]))
            (0.95,  $(_data[1]["meantimes"][19]))
            (1.0,  $(_data[1]["meantimes"][20]))
			};

		% Apriori 2 threads
		\\addplot[
			color=bluePowder,
			mark=*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {
            (0.05, $(_data[2]["meantimes"][1]))
            (0.10,  $(_data[2]["meantimes"][2]))
            (0.15, $(_data[2]["meantimes"][3]))
            (0.2,  $(_data[2]["meantimes"][4]))
            (0.25,  $(_data[2]["meantimes"][5]))
            (0.3,  $(_data[2]["meantimes"][6]))
            (0.35,  $(_data[2]["meantimes"][7]))
            (0.4,  $(_data[2]["meantimes"][8]))
            (0.45,  $(_data[2]["meantimes"][9]))
            (0.5,  $(_data[2]["meantimes"][10]))
            (0.55,  $(_data[2]["meantimes"][11]))
            (0.6,  $(_data[2]["meantimes"][12]))
            (0.65,  $(_data[2]["meantimes"][13]))
            (0.7,  $(_data[2]["meantimes"][14]))
            (0.75,  $(_data[2]["meantimes"][15]))
            (0.8,  $(_data[2]["meantimes"][16]))
            (0.85,  $(_data[2]["meantimes"][17]))
            (0.9,  $(_data[2]["meantimes"][18]))
            (0.95,  $(_data[2]["meantimes"][19]))
            (1.0,  $(_data[2]["meantimes"][20]))

			};

		% Apriori 4 threads
		\\addplot[
			color=blueSky,
			mark=triangle*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

            (0.05, $(_data[3]["meantimes"][1]))
            (0.10,  $(_data[3]["meantimes"][2]))
            (0.15, $(_data[3]["meantimes"][3]))
            (0.2,  $(_data[3]["meantimes"][4]))
            (0.25,  $(_data[3]["meantimes"][5]))
            (0.3,  $(_data[3]["meantimes"][6]))
            (0.35,  $(_data[3]["meantimes"][7]))
            (0.4,  $(_data[3]["meantimes"][8]))
            (0.45,  $(_data[3]["meantimes"][9]))
            (0.5,  $(_data[3]["meantimes"][10]))
            (0.55,  $(_data[3]["meantimes"][11]))
            (0.6,  $(_data[3]["meantimes"][12]))
            (0.65,  $(_data[3]["meantimes"][13]))
            (0.7,  $(_data[3]["meantimes"][14]))
            (0.75,  $(_data[3]["meantimes"][15]))
            (0.8,  $(_data[3]["meantimes"][16]))
            (0.85,  $(_data[3]["meantimes"][17]))
            (0.9,  $(_data[3]["meantimes"][18]))
            (0.95,  $(_data[3]["meantimes"][19]))
            (1.0,  $(_data[3]["meantimes"][20]))
			};

		% Apriori 8 threads
		\\addplot[
			color=blueVivid,
			mark=diamond*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

            (0.05, $(_data[4]["meantimes"][1]))
            (0.10,  $(_data[4]["meantimes"][2]))
            (0.15, $(_data[4]["meantimes"][3]))
            (0.2,  $(_data[4]["meantimes"][4]))
            (0.25,  $(_data[4]["meantimes"][5]))
            (0.3,  $(_data[4]["meantimes"][6]))
            (0.35,  $(_data[4]["meantimes"][7]))
            (0.4,  $(_data[4]["meantimes"][8]))
            (0.45,  $(_data[4]["meantimes"][9]))
            (0.5,  $(_data[4]["meantimes"][10]))
            (0.55,  $(_data[4]["meantimes"][11]))
            (0.6,  $(_data[4]["meantimes"][12]))
            (0.65,  $(_data[4]["meantimes"][13]))
            (0.7,  $(_data[4]["meantimes"][14]))
            (0.75,  $(_data[4]["meantimes"][15]))
            (0.8,  $(_data[4]["meantimes"][16]))
            (0.85,  $(_data[4]["meantimes"][17]))
            (0.9,  $(_data[4]["meantimes"][18]))
            (0.95,  $(_data[4]["meantimes"][19]))
            (1.0,  $(_data[4]["meantimes"][20]))
			};


		% Apriori 16 threads
		\\addplot[
			color=blueCornflower,
			mark=pentagon*,
			mark indices={1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			y filter/.expression={y*1e-9}
		] coordinates {

            (0.05, $(_data[5]["meantimes"][1]))
            (0.10,  $(_data[5]["meantimes"][2]))
            (0.15, $(_data[5]["meantimes"][3]))
            (0.2,  $(_data[5]["meantimes"][4]))
            (0.25,  $(_data[5]["meantimes"][5]))
            (0.3,  $(_data[5]["meantimes"][6]))
            (0.35,  $(_data[5]["meantimes"][7]))
            (0.4,  $(_data[5]["meantimes"][8]))
            (0.45,  $(_data[5]["meantimes"][9]))
            (0.5,  $(_data[5]["meantimes"][10]))
            (0.55,  $(_data[5]["meantimes"][11]))
            (0.6,  $(_data[5]["meantimes"][12]))
            (0.65,  $(_data[5]["meantimes"][13]))
            (0.7,  $(_data[5]["meantimes"][14]))
            (0.75,  $(_data[5]["meantimes"][15]))
            (0.8,  $(_data[5]["meantimes"][16]))
            (0.85,  $(_data[5]["meantimes"][17]))
            (0.9,  $(_data[5]["meantimes"][18]))
            (0.95,  $(_data[5]["meantimes"][19]))
            (1.0,  $(_data[5]["meantimes"][20]))


			};

	\\end{axis}
\\end{tikzpicture}

\\end{document}
"""
end

open(joinpath(OUTPUT_REPOSITORY, output_name), "w") do io
    println(io, latexfile)
end

