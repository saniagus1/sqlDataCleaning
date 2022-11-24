# Coming soon

### Raw data sources
1. [bmkg data source](https://github.com/kekavigi/repo-gempa/blob/main/katalog_gempa.csv)
2. [usgs asean data source](https://github.com/nugrahazikry/EDA-Indonesia-Earthquake/tree/main/Dataset/Raw)

### Data Cleaning Process
1. USGS
- Finding duplicate
- checking null for important parameters only
- Separate 'place' column into place and region
- Separate 'time' column into data, time, and hour-only
- Delete column (if necessary)

  For detailed method, check its sql file

2. BMKG
