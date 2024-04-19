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
int handleMA;
double bufferRSI[];
double bufferMA[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0; // Declaration of OpenTimeSell
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
   ArraySetAsSeries(bufferMA,true);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //---release indicator handleRSI
   if(handleRSI!=INVALID_HANDLE){IndicatorRelease(handleRSI);}
   if(handleMA!=INVALID_HANDLE){IndicatorRelease(handleMA);}
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- check if current tick is a new bar open tick
   if(!IsNewBar()){return;}
   
   //get current tick
   if(!SymbolInfoTick(_Symbol,currentTick)){Print("Failed to get current tick"); return;}
   
   // get rsi values
   int values = CopyBuffer(handleRSI,0,0,2,bufferRSI);
   if(values!=2) {
      Print("Failed to get rsi values");
      return;
   }
   
   // get ma values
   int maValues = CopyBuffer(handleMA,0,0,2,bufferMA); // Changed 'values' to 'maValues' to avoid redeclaration
   if(maValues!=1) {
      Print("Failed to get ma values");
      return;
   }
   
   Comment("bufferRSI[0]:",bufferRSI[0],
           "bufferRSI[0]:",bufferRSI[1],
           "\nbufferMA[]:",bufferMA[0]);
         
   //count open positions
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy,cntSell)){return;}
   
   //check for buy position
   if(cntBuy==0 && bufferRSI[1]>=(100-InpRSILevel) && bufferRSI[0]<(100-InpRSILevel) && currentTick.ask>bufferMA[0]) {
      //openTimeBuy = iTime(_Symbol,PERIOD_CURRENT,0);
      if(InpCloseSignal){if(!ClosePositions(2)){return;}}
      double sl = InpStopLoss == 0 ? 0 : currentTick.bid + InpStopLoss * _Point; //SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tp = InpTakeProfit == 0 ? 0 : currentTick.bid - InpTakeProfit * _Point; //SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
 
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "RSI MA filter EA");
   }
   
   //check for sell position
   if(cntSell==0 && bufferRSI[1]<=InpRSILevel && bufferRSI[0]>InpRSILevel && currentTick.bid<bufferMA[0]) { // Removed extra ')' from the condition
      openTimeSell = iTime(_Symbol,PERIOD_CURRENT,0); // Changed 'OpenTimeSell' to 'openTimeSell'
      if(InpCloseSignal){if(!ClosePositions(2)){return;}}
      double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point; //SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point; //SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(tp)){return;}
 
      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "RSI MA filter EA");
   }
}

//+------------------------------------------------------------------+
//| Custom function                                             |
//+------------------------------------------------------------------+

// check if we have a bar open tick
bool IsNewBar() {
    static datetime previousTime = 0;
    datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    if (previousTime != currentTime) {
        previousTime = currentTime;
        return true;
    }
    return false;
}

// count open positions
bool CountOpenPositions(int &cntBuy, int &cntSell){

    cntBuy = 0;
    cntSell = 0;
    int total = PositionsTotal();
    for(int i = total - 1; i >= 0; i--){
        ulong ticket = PositionGetTicket(i);
        if(ticket <= 0) {
            Print("Failed to get position ticket");
            return false;
        }
        if(!PositionSelectByTicket(ticket)) {
            Print("Failed to select postion");
            return false;
        }
        long magic;
        if(!PositionGetInteger(POSITION_MAGIC, magic)) {
            Print("Failed to get position magicnumber");
            return false;
        }
        if(magic == InpMagicnumber){
            long type;
            if(!PositionGetInteger(POSITION_TYPE, type)) {
                Print("Failed to get position type");
                return false;
            }
            if(type == POSITION_TYPE_BUY){
                cntBuy++;
            }
            if(type == POSITION_TYPE_SELL){
                cntSell++;
            }
        }
    }
    return true;
}

//normalize price
bool NormalizePrice(double &price) {

   double tickSize=0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE,tickSize)) {
      Print("Failed to get tick size");
      return false;
     
    }
    price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   
    return true;
   
}

//close positions
bool ClosePositions(int all_buy_sell){

   int total = PositionsTotal() ;
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<0){Print("Failed to get position ticket"); return false;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position"); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC, magic)) {Print("Failed to select position"); return false;}
      if(magic==InpMagicnumber) {
         long type;
         if(!PositionGetInteger(POSITION_TYPE, type)) {Print("Failed to get position type"); return false;}
         if(all_buy_sell==1 && type==POSITION_TYPE_SELL){continue;}
         if(all_buy_sell==2 && type==POSITION_TYPE_BUY){continue;}
         trade.PositionClose(ticket);
         if(trade.ResultRetcode()!=TRADE_RETCODE_DONE){
            Print("Failed to close position. ticket:",
                  (string)ticket," result:",(string)trade.ResultRetcode(),":",trade.CheckResultRetcode());
         }
   
      }
   
   
   }
   
   return true;
}