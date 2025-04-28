CSW = reduce(vcat, [X[1:12, :], X[180:192, :]])

logiset = scalarlogiset(CSW, variabledistances)

miner = Miner(
    logiset,
    miningalgo,
    _items,
    _itemsetmeasures,
    _rulemeasures;
    itemset_mining_policies=Function[
        isanchored_itemset(ignoreuntillength=2),
        isdimensionally_coherent_itemset()
    ],
    arule_mining_policies=Function[
        islimited_length_arule(
            consequent_maxlength=3
        ),
        isanchored_arule(),
        # isheterogeneous_arule(),
    ]
)

println("Running Libras' Curved Swing experiment")
experiment!(miner, "Libras", "v1_curved_swing.txt")
