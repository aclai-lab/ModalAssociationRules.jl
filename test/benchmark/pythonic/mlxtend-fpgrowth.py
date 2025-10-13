from mlxtend.frequent_patterns import fpgrowth
from mlxtend.preprocessing import TransactionEncoder
import time

# Load data as list of transactions
with open("./sample.txt", "r") as f:
    transactions = [line.strip().split(' ') for line in f]

print(transactions)

# Convert transactions to one-hot encoded DataFrame
te = TransactionEncoder()
te_ary = te.fit(transactions).transform(transactions)
import pandas as pd
df = pd.DataFrame(te_ary, columns=te.columns_)

start_time = time.time()

# Run FPGrowth
frequent_itemsets = fpgrowth(df, min_support=0.2, use_colnames=True)

end_time = time.time()
elapsed_time = end_time - start_time

print(f"Mining completed in {elapsed_time:.2f} seconds.")

# Print the results
# print(frequent_itemsets)
