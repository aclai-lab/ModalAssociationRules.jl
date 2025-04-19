# README: see experiments-driver.jl and experiments-libras.jl

# isolate "Vertical zig-zag" class
VZZ = reduce(vcat, [X[13:24, :], X[193:204, :]])

logiset = scalarlogiset(VZZ, variabledistances)

miner = Miner(
    logiset,
    miningalgo,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=Function[
        isanchored_itemset(),
        # isdimensionally_coherent_itemset()
    ],
    arule_mining_policies=Function[
        islimited_length_arule(
            consequent_maxlength=3
        ),
        isanchored_arule(),
        # isheterogeneous_arule(),
    ]
)
