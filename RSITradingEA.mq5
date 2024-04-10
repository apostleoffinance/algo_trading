//+------------------------------------------------------------------+
//|                                                 RSITradingEA.mq5 |
//|                                               Apostle of finance |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyrigt 2024, Apostle of finance"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
// Include                                                 |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
// Inputs Variables                                                |
//+------------------------------------------------------------------+
static input long       InpMagicnumber = 546812;   //magic number
static input double     InpLotSize     = 0.01;     //lot size
input int               InpRSIPeriod   = 21;       //rsi period
input int               InpRSILevel    = 70;       //rsi level (upper)
input int               InpMAPeriod    = 21;       // ma period
input ENUM_TIMEFRAMES   InpMATimeframe = PERIOD_H1;// ma timeframe
input int               InpStopLoss    = 200;      // stop loss in profit (0=off)
input int               InpTakeProfit  = 100;      // take profit in points (0=off)
input int               InpCloseSignal = false;    // close trades by opposite signal
//+------------------------------------------------------------------+
// Global Variables                                                |
//+------------------------------------------------------------------+
int handleRSI;
int handleeMA;
double bufferRSI[];
double bufferMA[];
MqlTick currentTick;
CTrade trade;
//datetime openTimeBuy = 0;
//datetime openTimeSell = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
     // check user inputs
     if(InpMagicnumber<=0){
         Alert("Magicnumber <= 0");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpLotSize<=0 || InpLotSize>10){
         Alert("Lot Size <= 0 or > 10");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpRSIPeriod<=0){
         Alert("RSI Period <= ");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpRSILevel>=100 || InpRSILevel<=50){
         Alert("RSI level >= 100 or <= 50");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpMAPeriod<=1){
         Alert("MA Period <= 1");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpStopLoss<0){
         Alert("Stop Loss < 0");
         return INIT_PARAMETERS_INCORRECT;
      }
      if(InpTakeProfit<0){
         Alert("Take Profit < 0");
         return INIT_PARAMETERS_INCORRECT;
      }
     
      // set magic number to trade object
      trade.SetExpertMagicNumber(InpMagicnumber);
     
      //create indicator handles
      handleRSI = iRSI(_Symbol,PERIOD_CURRENT,InpRSIPeriod,PRICE_OPEN);
      if(handleRSI == INVALID_HANDLE){
          Alert("Failed to create indicator handleMA");
          return INIT_FAILED;
     }
     
     // set bufferRSI as series
     ArraySetAsSeries(bufferRSI,true);
     
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
