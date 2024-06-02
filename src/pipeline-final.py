import argparse
import logging

import pandas as pd
from azureml.core import Workspace, Dataset, Experiment, Environment
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split


logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

workspace = Workspace.from_config()
env = Environment.get(workspace=workspace, name="AzureML-ACPT-pytorch-1.13-py38-cuda11.7-gpu")
# Define experiment
experiment = Experiment(workspace=workspace, name='terrafrorm-pipeline')

parser = argparse.ArgumentParser(description='Process input dataset for pipeline')
parser.add_argument('--input-dataset', type=str, help='URI of the input dataset')
args = parser.parse_args()


datasets = Dataset.get_all(workspace)
for name, ds in datasets.items():
    if name == 'diabetes_dataset':
        logging.info(f"Found registered dataset: {name}, ID: {ds.id}")
        break
else:
    logging.info("Registered dataset not found")

    # Create the dataset
    url_path = 'https://pdpstoragegroup14c.blob.core.windows.net/pdpstoragecontainerc/diabetes.csv'
    dataset = Dataset.Tabular.from_delimited_files(path=url_path)

    logging.info("Dataset registered: ", dataset.id)
    # Register the dataset
    dataset = dataset.register(workspace=workspace,
                               name='diabetes_dataset',
                               description='Diabetes data',
                               create_new_version=True)

# Load the dataset
loaded_dataset = Dataset.get_by_name(workspace, name='diabetes_dataset')
df = loaded_dataset.to_pandas_dataframe()
logging.info("Loaded dataset from workspace")

# Display the first few rows of the loaded dataset
logging.info(df.head())


X = df.drop(columns=['Outcome'])  # Features
y = df['Outcome']  # Target variable

# Split the data into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the logistic regression model
model = LogisticRegression()

# Train the model
model.fit(X_train, y_train)

# Predict on the test set
y_pred = model.predict(X_test)

# Calculate accuracy
accuracy = accuracy_score(y_test, y_pred)
print("Accuracy:", accuracy)
