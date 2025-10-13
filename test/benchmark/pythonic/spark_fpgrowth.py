from pyspark.mllib.fpm import FPGrowth
from pyspark import SparkContext
import time
from contextlib import contextmanager

@contextmanager
def timer(name: str):
    start = time.time()
    yield
    end = time.time()
    print(f"{name} completed in {end - start:.2f} seconds.")

sc = SparkContext(appName="FPGrowth")

data = sc.textFile("./sample.txt")
transactions = data.map(lambda line: line.strip().split(' '))

with timer("Mining"):
    model = FPGrowth.train(
        transactions, 
        minSupport=0.2, 
        numPartitions=12
    )

with timer("Collection"):
    result = model.freqItemsets().collect()

# for fi in result:
#     print(fi)
