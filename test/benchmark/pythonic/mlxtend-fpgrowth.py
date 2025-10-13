import json
import time
import numpy as np
import pandas as pd
from mlxtend.frequent_patterns import fpgrowth
from mlxtend.preprocessing import TransactionEncoder

# load the configuration settings, shared with the Julia driver
with open("config.json", "r") as f:
    config = json.load(f)

data_file = config["data_file"]
min_supports = config["min_supports"]
num_runs = config["num_runs"]

# load data and transform it into a one-hot encoded DataFrame,
# see https://rasbt.github.io/mlxtend/user_guide/frequent_patterns/fpgrowth/
with open(data_file, "r") as f:
    transactions = [line.strip().split(' ') for line in f]

te = TransactionEncoder()
te_ary = te.fit(transactions).transform(transactions)
df = pd.DataFrame(te_ary, columns=te.columns_)

# mean time for each measurement set
mean_times = []

# also keep track of the individual measurements for each set;
# this is useful for plotting a whiskers plot 
all_runtimes = []

for min_support in min_supports:
    _current_all_runtimes = []

    for i in range(num_runs):
        print(f"Run #{i} for min_support={min_support}")

        start_time = time.time()
        
        frequent_itemsets = fpgrowth(df, min_support=0.2, use_colnames=True)
        
        end_time = time.time()
        _current_all_runtimes.append(end_time - start_time)

    # aggregate statistics

    all_runtimes.append(_current_all_runtimes)
    mean_times.append(np.mean(_current_all_runtimes))

print(mean_times)
print(all_runtimes)