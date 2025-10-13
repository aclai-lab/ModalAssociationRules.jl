from pyspark.mllib.fpm import FPGrowth
from pyspark import SparkContext

if __name__ == "__main__":
    sc = SparkContext(appName="FPGrowth")

    data = sc.textFile("./sample.txt")
    transactions = data.map(lambda line: line.strip().split(' '))

    # numPartitions=#cores since data is small enough to fit in memory;
    # an higher value could introduce unnecessary overhead.
    model = FPGrowth.train(transactions, minSupport=0.2, numPartitions=12)

    result = model.freqItemsets().collect()
    for fi in result:
        print(fi)
