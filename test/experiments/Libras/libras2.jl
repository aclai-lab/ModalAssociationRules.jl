# isolate "Circle" class
CRC = reduce(vcat, [X[133:144, :], X[313:324, :]])

logiset = scalarlogiset(CRC, variabledistances)

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

println("Running Libras' Circle experiment")
experiment!(miner, "Libras", "v2_circle.txt")
