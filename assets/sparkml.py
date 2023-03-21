from pyspark.context import SparkContext
from pyspark.ml.linalg import Vectors
from pyspark.ml.regression import LinearRegression
from pyspark.sql.session import SparkSession
# The imports, above, allow us to access SparkML features specific to linear
# regression as well as the Vectors types.


# Define a function that collects the features of interest
# (mother_age, father_age, and gestation_weeks) into a vector.
# Package the vector in a tuple containing the label (`weight_pounds`) for that
# row.
def vector_from_inputs(r):
  return (r["order_number_of_items"], Vectors.dense(str(r["user_age"]),
                                            str(r["user_gender"]),
                                            str(r["user_state"]),
                                            str(r["user_city"]),
                                            str(r["user_country"]),
                                            str(r["user_traffic_source"])))

sc = SparkContext()
spark = SparkSession(sc)
spark.conf.set("viewsEnabled","true")
# Read the data from BigQuery as a Spark Dataframe.
ecommerce_data = spark.read.format("bigquery").option(
    "table", "ft.vw_ecommerce_table").load()
# Create a view so that Spark SQL queries can be run against the data.
ecommerce_data.createOrReplaceTempView("ecommerce")

# As a precaution, run a query in Spark SQL to ensure no NULL values exist.
sql_query = """

            select * from ecommerce            
            
            """
clean_data = spark.sql(sql_query)

# Create an input DataFrame for Spark ML using the above function.
training_data = clean_data.rdd.map(vector_from_inputs).toDF(["label",
                                                             "features"])
training_data.cache()

# Construct a new LinearRegression object and fit the training data.
lr = LinearRegression(maxIter=5, regParam=0.2, solver="normal")
model = lr.fit(training_data)
# Print the model summary.
print("Coefficients:" + str(model.coefficients))
print("Intercept:" + str(model.intercept))
print("R^2:" + str(model.summary.r2))
model.summary.residuals.show()

