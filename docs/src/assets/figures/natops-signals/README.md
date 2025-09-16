This folder contains a raw and structured dissection of a signal typical of the movement "I have command", of the dataset NATOPS.

More specifically, it is the right hand Y signal of the first instance.

Both `raw` and `structured` signals are generated starting with this julia preamble:

```julia
using Plots
using ModalAssociationRules

X_df, y = load_NATOPS();
X = X_df[1:30, :]
```

The `raw` signals are generated with the following julia code:

```julia
windows = [ 
    [(s:s+9) for s in 1:10:41]..., 
    [(s:s+19) for s in 1:10:31]...,  
    [(s:s+29) for s in 1:10:21]...,  
    [(s:s+39) for s in 1:10:11]...,  
    [(s:s+49) for s in 1:10:1]..., 
]

for i in windows
    x = collect(i)
    y = @view X[1,5][x]

    p = plot(x, y;
        label=false,            # remove legend
        linecolor=:blue,
        linewidth=2,
        size=(10 * length(i), 250),
        ylims=(-2, 1.9),
        xticks=false,           # remove x-axis ticks
        yticks=false,           # remove y-axis ticks
        xlabel="",              # remove x label
        ylabel="",              # remove y label
        framestyle=:none,       # remove frame/axes completely
        background_color=:transparent
    )

    _first = i |> first
    _last = i |> last
    
    savefig(p,  "$(_first)-to-$(_last).png")
end
```

while the `structured` signals are generated with:

```julia
windows = [(s:s+9) for s in 1:10:41]
for i in windows
    x = collect(i)
    y = @view X[1,5][x]

    p = plot(x, y; 
        label="Right hand", linecolor=:blue, linewidth=2, 
        size=(500,250), ylims=(-2,1.9), 
        xticks=collect(1:50), xlabel="Time", ylabel="Position on y axis"
    )
    
    savefig(p, string <| i[1])
end
```