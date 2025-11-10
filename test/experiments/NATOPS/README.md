This folder contains all the necessary files to run the experiments related to NATOPS dataset.

Please, follow the `natops.ipynb` notebook.

The `serialized` folder contains a set of triplets for any class considered (e.g., *ICC* for *I have command*). Each piece is the serialization of something useful to create a proposition wrapping a motif, that is, an object shaped as $\text{distance}(V, \text{motif}) \leq \text{threshold}$ where $V$ is an array of the same size as $\text{motif}$.

`motifs-plotter.jl` is an utility script needed for plotting all 