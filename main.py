import argparse

import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


def main():
    # Set appropriate variables (e.g. num_samples) to a lower value to reduce the computational cost of the draft (fast) version document.
    parser = argparse.ArgumentParser()
    parser.add_argument('--full', default=False, action='store_true')
    args = parser.parse_args()
    if args.full:
        num_samples = 200
    else:
        num_samples = 20

    # Set random seeds for reproducibility.
    np.random.seed(0)

    # Create and save an image as a pdf file.
    data = np.random.randn(num_samples)
    plt.figure(constrained_layout=True, figsize=(6, 2))
    plt.plot(data)
    plt.grid(True)
    plt.autoscale(enable=True, axis='x', tight=True)
    plt.title('Random data')
    plt.savefig('tmp/image.png')
    plt.close()

    # Create and save a table as a tex file.
    num_rows = 5
    num_columns = 8
    table = np.random.randn(num_rows, num_columns)
    dataframe = pd.DataFrame(table)
    max_per_column_list = dataframe.max(0)
    formatters = [lambda x, max_per_column=max_per_column: fr'\textbf{{{x:.2f}}}' if (x == max_per_column) else f'{x:.2f}' for max_per_column in max_per_column_list]
    dataframe.to_latex('tmp/table.tex', formatters=formatters, bold_rows=True, escape=False)

    # Create and save variables as a csv file.
    dataframe = pd.DataFrame({'key': ['num_samples', 'num_rows', 'num_columns'], 'value': [num_samples, num_rows, num_columns]})
    dataframe.to_csv('tmp/keys-values.csv', index=False, float_format='%.1f')


if __name__ == '__main__':
    main()
