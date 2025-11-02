# for each previously trained miner, we want to print the resulting rules in the
# results folder, also reporting the meaningfulness measures
function printreport(
    _miner::Miner,
    i::Int,
    rules::Vector{ARule};
    reportprefix::String="results_"
)
    # we expect the experiment to consider global confidence and global lift
    rulecollection = [
        (
            rule,
            round(
                globalmemo(_miner, (:gsupport, antecedent(rule))), digits=2
                ),
            round(
                globalmemo(_miner, (:gsupport, Itemset(rule))), digits=2
            ),
            round(
                globalmemo(_miner, (:gconfidence, rule)), digits=2
            ),
            round(
                globalmemo(_miner, (:glift, rule)), digits=2
            ),
        )
        for rule in rules
    ]

    # rules are ordered decreasingly by global lift
    sort!(rulecollection, by=x->x[5], rev=true);

    reportname = joinpath(RESULTS_REPOSITORY, "$(reportprefix)$(i)")

    println("Writing to: $(reportname)")

    open(reportname, "w") do io
        println(io, "The alphabet is: $(items(_miner))")

        println(io, "Columns are: rule, ant support, ant+cons support,  confidence, lift")

        padding = maximum(length.(_miner |> freqitems))
        for (rule, antgsupp, consgsupp, conf, lift) in rulecollection
            println(io,
                rpad(rule, 30 * padding) * " " * rpad(string(antgsupp), 10) * " " *
                rpad(string(consgsupp), 10) * " " * rpad(string(conf), 10) * " " *
                string(lift)
            )
        end
    end
end
