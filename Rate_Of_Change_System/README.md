# TradingSystem_validaiton

This repository consist of the AFL code (for backtesting the strategy) and .docx file.

The word file containing information for the basic idea of the system as well as validation procedure for profitability and reliability.

mq5 file is used for live trading in MT5 platform


Trading rules:

BUY:

Lowest Low Value for the past N days
Rate of change parameter for the past N days is greater than a predefined number 
Closing price is > 200 days moving average
Market universe: SP500

SELL:

Closing price > Highest High Closing price for the past N days


Trading delay - buy next day open (after signal) and sell next day open
