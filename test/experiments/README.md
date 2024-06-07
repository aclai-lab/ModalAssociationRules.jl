# Experiments report
This file intends to summarise the results of experiments reproducible by executing the following command (from the root folder of this project):
```julia
julia --project=. test/experiments/natops-experiments.jl
```

In particular, this is a summary of the most interesting results. To know more about how experiments are organized, and details about the experiments not listed here, see ```natops-experiments.jl```. You can ```CTRL+F``` and search for the ```Data Observation``` section, or ```Experiment #N``` where $N$ is the experiment number you are interested in.

The experiments are organized as follows.
Initially, a target class is chosen.
Frequent itemsets related to the target class are extracted, and association rules are generated.
This process is driven by a parameterization composed of initial items, meaningfulness measures thresholds and modal relations. In addition, the association rules generation process is deliberately not complete: rules where the antecedent only contains modal literals, and those where the same variable is considered both in antecedent and consequent, are discarded (see ```anchor_rulecheck``` and ```non_selfabsorbed_rulecheck``` in ```src/utils/arulemining-utils.jl```).

Each experiment generates 2 files in ```results``` folder.
Each filename is organized following the pattern
```eNN```-```tc-N```-```tc string```-```variables```-```relations``` [```.exp``` or ```-comparison.exp```]
where all the pieces are, respectively, the number of the experiment, the target class id, the target class as string, the variables which are considered and finally the relations.
If the filename ends with ```-comparison```, then this means that the file contains a comparison matrix between the best rules extracted from the target class, and all the other class.
Otherwise, the file only contains only a list of extracted association rules.

# 1 - Right hand in "I have command"

### Parameterization
- Target class is "I have command" (1st class).
- Only right hand is considered. In particular, the propositional literals expresses the following things:
    * ```min[X[Hand tip r]] ≥ 1``` : hand is far from the body (forward)
    * ```min[X[Hand tip r]] ≥ 1.8``` : the entire arm is stretched frontally
    * ```min[Y[Hand tip r]] ≥ 0``` : hand is up (shoulders)
    * ```min[Y[Hand tip r]] ≥ 1``` : hand is up (head)
    * ```min[Z[Hand tip r]] ≥ -0.5``` : hand is sideways (right) from the hips
- B, E, D, O relations. No inverses. 2 box and 2 diamonds.
- At the time of writing this report, supports are both set to $0.1$, and global confidence is set to be $0.3$, while local confidence is ignored.
- To know more, run the experiments and check the files "e05-tc-1-have-command-rhand-BEDO" and "e05-tc-1-have-command-rhand-BEDO-comparison.exp".

### Results
The following rules unambiguously describe the class "I have command".
Confidence is 1.0, while it is 0.0 in the other classes.
In other words, $1-Entropy(rules confidences)$ is 1.0.

The following rules are similar to each other (actually, more combinations are generated, but are not listed here).

- ```(min[X[Hand tip r]] ≥ 1) ∧ (⟨O⟩min[Y[Hand tip r]] ≥ 1) => ([B]min[Z[Hand tip r]] ≥ -0.5)```

- ```(min[X[Hand tip r]] ≥ 1) ∧ (⟨O⟩min[Y[Hand tip r]] ≥ 1) => ([D]min[Z[Hand tip r]] ≥ -0.5)```

- ```(min[X[Hand tip r]] ≥ 1) ∧ (⟨E⟩min[Y[Hand tip r]] ≥ 1) => (⟨E⟩min[Z[Hand tip r]] ≥ -0.5)```

- ```(min[X[Hand tip r]] ≥ 1) ∧ (⟨O⟩min[Y[Hand tip r]] ≥ 1) => (⟨O⟩min[Z[Hand tip r]] ≥ -0.5)```

- ```(min[X[Hand tip r]] ≥ 1) ∧ ([D]min[Y[Hand tip r]] ≥ 1) => ([B]min[Z[Hand tip r]] ≥ -0.5)```

The following three rules are representative for "I have command" (confidence is between $0.8$ and $0.68$). They are also, to a small extent, representative for the class "Lock wings" (here, confidence swings around $0.2$ for both the rules below). Considering the other classes, confidence is exactly $0.0$.

- ```(min[Z[Hand tip r]] ≥ -0.5) => (⟨O⟩min[Y[Hand tip r]] ≥ 1)```
- ```(min[Z[Hand tip r]] ≥ -0.5) => (⟨E⟩min[Y[Hand tip r]] ≥ 1)```
- ```(min[Z[Hand tip r]] ≥ -0.5) => ([D]min[Y[Hand tip r]] ≥ 1)```

The following rule has confidence $0.6$ on the target class, but is also more representative than the previous ones w.r.t. "Lock wings" class. This is due to the fact that the rule expresses the entire vertical movement of the right hand: this is common between "I have command" and "Lock wings" classes, while is not peculiar of the other movements. 

- ```(min[Z[Hand tip r]] ≥ -0.5) ∧ (⟨E⟩min[X[Hand tip r]] ≥ 1) => ([D]min[Y[Hand tip r]] ≥ 0)```

In the following rule, confidence is $1.0$ for both "I have command" and "Lock wings" classes, while is $0.0$ on the rest.

- ```(min[Y[Hand tip r]] ≥ 1) => ([B]min[Z[Hand tip r]] ≥ -0.5)```

# 2 - Both hands and elbows in "Lock wings" movement.

### Parameterization
- Target class is "Lock wings" (6th class).
- Some of the propositional literals are:
    * ```min[Y[Hand tip l]] ≥ -1.0``` : left hand is up (between ankles and belly)
    * ```min[Y[Hand tip r]] ≥ 0.2``` : right hand is up (shoulders)
    * ```min[Y[Hand tip r]] ≥ 0.5``` : right hand is up (chin, ears)
    * ```max[Z[Elbow l]] ≤ -0.25``` : left elbow is tightened in the body (navel)
    * ```min[Y[Elbow r]] ≥ -0.5``` : right elbow is  up (shoulders)
- O relation, using diamond.
- At the time of writing this report, supports are both set to $0.2$, and global confidence is set to be $0.1$

### Results

The following rules are good for discerning "Lock wings" from all the other classes. Each one is followed by a comment.

- ```(max[Z[Elbow l]] ≤ -0.25) ∧ (⟨O⟩min[Y[Hand tip l]] ≥ -1.0) ∧ (⟨O⟩min[Y[Elbow r]] ≥ -0.5) ∧ (⟨O⟩max[Z[Elbow r]] ≥ -0.3) => (⟨O⟩min[Y[Hand tip r]] ≥ 0.5)```; this rule and its fragments (that is, those sharing the same consequent but only a subset of the antecedent) always have confidence $\geq 0.7$, while is $0.0952$ at most in the other classes.

- ```(max[Z[Elbow r]] ≥ -0.3) ∧ (⟨O⟩min[Y[Hand tip l]] ≥ -1.0) ∧ (⟨O⟩min[X[Elbow r]] ≥ 0.7) ∧ (⟨O⟩min[Y[Elbow r]] ≥ -0.5) ∧ (⟨O⟩max[Z[Elbow l]] ≤ -0.25) => (⟨O⟩min[Y[Hand tip r]] ≥ 0.2)```; this is similar to the one before, but is slightly less pure. Confidence is $0.85$, but it is also $0.47$ on "Spread wings" and $0.36$ on "Fold wings".

- ```(max[Z[Elbow l]] ≤ -0.25) ∧ (⟨O⟩min[X[Elbow r]] ≥ 0.7) ∧ (⟨O⟩min[Y[Elbow r]] ≥ -0.5) ∧ (⟨O⟩max[Z[Elbow r]] ≥ -0.3) => (⟨O⟩min[Y[Hand tip r]] ≥ 0.5)```; this might be similar to the one before, but has some important differences (see z on right elbow and the consequent threshold). This rule has confidence $1.0$ for "Lock wings", but also $0.93$ for "I have command": the insight between this similarity, is that both movement lead to having the right hand very high.

- ```(min[Y[Hand tip l]] ≥ -1.0) => (max[Z[Elbow l]] ≤ -0.25)```; this short rule has confidence $0.85$ on our target class, but also respectively $0.76$ and $0.73$ on "Spread wings" and "Fold wings". It is however interesting because it is minimal and is capable to instantly filter out the other classes (e.g., during a classification task).

# 3 - Right hand and thumb in "Not clear" movement.

This experiment did not bring considerable results, as "Not clear" movement seems almost identical to "All clear".

This can be visualized by plotting

```
plot(
    map(i->plot(collect(X_df[i,22:24]), labels=nothing,title=y[i]), 1:30:180)...,
    layout = (2, 3),
    size = (1500,400)
)
```

for each possible triple (X,Y,Z) of variables, and comparing the two classes. Some instances are slightly different, but the vast majority of the times the two cases are indistiguishable to the eye.