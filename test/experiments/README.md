# ModalAssociationRules.jl experiments

This file is intended to give a general overview of the most remarkable results obtained by extracting association rules from some dataset.
Currently, only [NATOPS](https://github.com/yalesong/natops/tree/master) dataset is being analysed.

The following results are a small part of all the extracted rules, and are made by manually picking the literals from which itemsets are extracted.
To know more about experiments setup, see `<dataset-name>-experiements.jl`.

## NATOPS

### I have command
- The operator tends to rotate his right palm in front of him, when his arms are approaching the highest point of the arc of movement.

    `(min[X[Hand tip r]] ≤ 1) ∧ (min[Z[Hand tip r]] ≥ 0) => (min[Y[Hand tip r]] ≥ -0.5)`

    global confidence: $0.92$

